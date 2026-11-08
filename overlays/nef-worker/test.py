#!/usr/bin/env python3
# SLOP
"""Exercises every nef-worker command: test.py WORKER NEF LEGACY_NEF NRW JPEG RECIPES

NEF should be from a recent body, and LEGACY_NEF from one that predates Picture Control, e.g. a D70.
RECIPES is a directory of .NP3 files that has BleachBypass_01a, e.g. the nikon-recipes flake input.
Uses /dev/shm; set XDG_CACHE_HOME to try a fresh wine prefix.
"""

import array
import glob
import itertools
import json
import os
import queue
import statistics
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import ANY

WORKER, NEF, LEGACY_NEF, NRW, JPEG, RECIPES = sys.argv[1:7]

OK, INVALID_PARAM, FILE_IO = 0, 4, 9
FORMAT_JPEG, FORMAT_NEF, FORMAT_NRW = 0x20, 0x100000, 0x200000
COLOR_RGB = 0x20
ORIENTATION_CW90 = 8
TAG_TYPE_LONG, TAG_TYPE_STRING = 4, 2
TAG_MODEL, TAG_DATE_TIME = 0x110, 0x132
WB_INCANDESCENT = 0x100
PICTURE_CONTROL_STANDARD, PICTURE_CONTROL_MONOCHROME = 2, 5
PICTURE_CONTROL_FLEXIBLE_COLOR = 0x20
PICTURE_CONTROL_SEPIA = 0x14
PARAMETER_SET_LAST_SAVE = 2
WARN_EDIT_STATE_NOT_EXIST = 0x102
COLOR_MODE_I = 2
COLOR_PROCESS_LATEST, COLOR_PROCESS_IN_CAMERA = 0, 1
DEVELOP_COLOR_MODE_SRGB, DEVELOP_COLOR_MODE_ADOBE = 1, 2
PROFILES = r"C:\Program Files\Common Files\Nikon\Profiles"

RAW_PARAMETER_SET = 0x1
RAW_QUALITY = 0x2
EXP_COMP = 0x4
WB_ADJUSTMENT = 0x8
TINT = 0x10
NR = 0x20
PICTURE_CONTROL = 0x40
COLOR_MODE = 0x80
SHARPNESS = 0x100
TONE_COMP = 0x200
SATURATION = 0x400
HUE_ADJUSTMENT = 0x800
FILTER_EFFECT = 0x1000
ACTIVE_D_LIGHTING = 0x2000
SKIN_SOFTENING = 0x4000
PORTRAIT_IMPRESSION_BALANCE = 0x8000
PICTURE_CONTROL_AS_SHOT = 0x10000
PIXEL_SHIFT_NR = 0x20000
DEHAZE = 0x40000
FILM_GRAIN = 0x80000
RAW_PARAMS = [1 << bit for bit in range(20) if 1 << bit != PICTURE_CONTROL_AS_SHOT]

COMMANDS = {
    "OpenSession",
    "CloseSession",
    "GetFileInfo",
    "GetOutputProfile",
    "SetOutputProfile",
    "GetOutputDeviceProfile",
    "SetOutputDeviceProfile",
    "GetImageInfo",
    "SetImageInfo",
    "GetOriginalInfo",
    "GetImageData",
    "GetRawDevelopmentInfo",
    "RawDevelopment",
    "GetRawDevelopmentParam",
    "GetRawDevelopmentRange",
    "GetColorTempRange",
    "GetThumbnailCount",
    "GetThumbnailInfo",
    "SetThumbnailInfo",
    "GetThumbnailData",
    "GetTagInfo",
    "GetTagData",
    "GetTagStringInfo",
    "GetTagString",
    "GetEditState",
    "GetColorProcess",
    "SetColorProcess",
    "GetPictureControlList",
    "GetPictureControlVersion",
    "GetDevelopColorMode",
    "SetDevelopColorMode",
    "GetDynamicRange",
    "SetDynamicRange",
    "GetWBGain",
    "ApplyRecipe",
}


class Worker:
    def __init__(self):
        self.process = subprocess.Popen(
            [WORKER],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            bufsize=1,
        )
        assert json.loads(self.process.stdout.readline()) == {"ready": True}
        self.ids = itertools.count(1)
        self.lock = threading.Lock()
        self.responses = {}
        self.progress = {}
        self.called = set()
        threading.Thread(target=self.read, daemon=True).start()

    def read(self):
        for line in self.process.stdout:
            message = json.loads(line)
            if "ulDone" in message:
                self.progress.setdefault(message["id"], []).append(message)
            else:
                self.response_queue(message["id"]).put(message)

    def response_queue(self, id):
        with self.lock:
            return self.responses.setdefault(id, queue.Queue())

    def send(self, cmd, **fields):
        self.called.add(cmd)
        id = next(self.ids)
        self.write(json.dumps({"id": id, "cmd": cmd, **fields}))
        return id

    def write(self, line):
        self.process.stdin.write(line + "\n")
        self.process.stdin.flush()

    def wait(self, id):
        return self.response_queue(id).get(timeout=120)

    def __call__(self, cmd, **fields):
        return self.wait(self.send(cmd, **fields))

    def stop(self):
        self.process.stdin.close()
        return self.process.wait(timeout=30)


class Session:
    def __init__(self, path=NEF, **fields):
        self.response = worker("OpenSession", path=path, **fields)
        self.id = self.response["ulSessionID"]

    def __enter__(self):
        return self

    def __exit__(self, *_):
        assert worker("CloseSession", ulSessionID=self.id)["code"] == OK

    def __call__(self, cmd, **fields):
        return worker(cmd, ulSessionID=self.id, **fields)

    def scale(self, divisor=4, depth=2):
        original = self("GetOriginalInfo")
        response = self(
            "SetImageInfo",
            ulWidth=original["ulWidth"] // divisor,
            ulHeight=original["ulHeight"] // divisor,
            ulByteDepth=depth,
            ulOrientation=original["ulOrientation"],
        )
        assert response["code"] == OK, response

    def develop(self, **fields):
        path = f"{shm.name}/{next(names)}"
        response = self("GetImageData", path=path, **fields)
        assert response["code"] == OK, response
        return response, read_samples(path, response["ulByteDepth"])

    def set_profile(self, name):
        self("SetOutputProfile", OutputProfile=rf"{PROFILES}\{name}.icm")

    def camera_profile(self):
        path = f"{shm.name}/{next(names)}"
        self.develop(profile=path)
        with open(path, "rb") as file:
            data = file.read()
        os.unlink(path)
        return data


def failed(code):
    return code and not code & 0xF00


def read_samples(path, depth):
    samples = array.array("H" if depth == 2 else "B")
    with open(path, "rb") as file:
        samples.frombytes(file.read())
    os.unlink(path)
    return samples


class Sessions(unittest.TestCase):
    def test_formats(self):
        for path, expected in (
            (NEF, FORMAT_NEF),
            (LEGACY_NEF, FORMAT_NEF),
            (NRW, FORMAT_NRW),
            (JPEG, FORMAT_JPEG),
        ):
            with Session(path) as session:
                self.assertEqual(session("GetFileInfo")["ulFormat"], expected)

    def test_missing_file(self):
        response = worker("OpenSession", path=f"{shm.name}/missing.nef")
        self.assertEqual(response["code"], FILE_IO)

    def test_paths_with_spaces_and_non_ascii_characters(self):
        path = f"{shm.name}/ニコン テスト.nef"
        os.symlink(NEF, path)
        with Session(path) as session:
            session.scale()
            session.set_profile("NKsRGB")
            session.develop()
        os.unlink(path)

    def test_load_skip(self):
        with Session(bImageLoadSkip=True) as session:
            self.assertEqual(session("GetFileInfo")["ulFormat"], FORMAT_NEF)

    def test_memory_matches_file(self):
        images = []
        for fields in ({}, {"memory": True}):
            with Session(**fields) as session:
                session.scale()
                session.set_profile("NKsRGB")
                images.append(session.develop()[1])
        self.assertEqual(images[0], images[1])

    def test_memory_missing_file(self):
        response = worker("OpenSession", path=f"{shm.name}/missing.nef", memory=True)
        self.assertEqual(response["code"], INVALID_PARAM)
        self.assertIn("missing.nef", response["message"])


class Images(unittest.TestCase):
    def test_info(self):
        with Session() as session:
            original = session("GetOriginalInfo")
            self.assertEqual(session("GetImageInfo")["ulWidth"], original["ulWidth"])
            self.assertEqual(original["ulColor"], COLOR_RGB)
            session.scale(4, 1)
            info = session("GetImageInfo")
            self.assertEqual(info["ulWidth"], original["ulWidth"] // 4)
            self.assertEqual(info["ulByteDepth"], 1)
            self.assertEqual(session("GetOriginalInfo")["ulWidth"], original["ulWidth"])

    def test_data_size(self):
        with Session() as session:
            session.scale(4, 1)
            response, samples = session.develop()
            size = response["ulWidth"] * response["ulHeight"] * 3
            self.assertEqual(response["ulDataSize"], size)
            self.assertEqual(len(samples), size)
            self.assertGreater(max(samples), 0)

    def test_rotation(self):
        with Session() as session:
            original = session("GetOriginalInfo")
            session(
                "SetImageInfo",
                ulWidth=original["ulWidth"] // 4,
                ulHeight=original["ulHeight"] // 4,
                ulByteDepth=2,
                ulOrientation=ORIENTATION_CW90,
            )
            response, _ = session.develop()
            self.assertEqual(response["ulHeight"], original["ulWidth"] // 4)

    def test_crop_matches_whole_image(self):
        with Session() as session:
            session.scale()
            whole_response, whole = session.develop()
            width = whole_response["ulWidth"]
            left, top, right, bottom = 100, 50, 164, 90
            rect = {"left": left, "top": top, "right": right, "bottom": bottom}
            response, crop = session.develop(rectArea=rect)
            self.assertEqual(len(crop), (right - left) * (bottom - top) * 3)
            row = whole[(top * width + left) * 3 : (top * width + right) * 3]
            self.assertEqual(crop[: len(row)], row)

    def test_bad_output_directory(self):
        with Session() as session:
            response = session("GetImageData", path="/nonexistent/image")
            self.assertEqual(response["code"], FILE_IO)

    def test_jpeg(self):
        with Session(JPEG) as session:
            session.scale(4, 1)
            self.assertGreater(max(session.develop()[1]), 0)

    def test_nrw(self):
        with Session(NRW) as session:
            session.scale(4, 2)
            self.assertGreater(max(session.develop()[1]), 0)

    def test_profiles_change_the_image(self):
        with Session() as session:
            session.scale()
            session.set_profile("NKsRGB")
            profile = session("GetOutputProfile")["OutputProfile"]
            self.assertTrue(profile.endswith("NKsRGB.icm"), profile)
            srgb = session.develop()[1]
            session.set_profile("NKAdobe")
            self.assertNotEqual(session.develop()[1], srgb)

    def test_unix_profile_path(self):
        with Session() as session:
            path = f"{shm.name}/profile.icm"
            with open(path, "wb"):
                pass
            session("SetOutputProfile", OutputProfile=path)
            profile = session("GetOutputProfile")["OutputProfile"]
            self.assertTrue(profile.startswith("Z:"), profile)
            os.unlink(path)

    def test_device_profile(self):
        with Session() as session:
            self.assertEqual(session("GetOutputDeviceProfile")["code"], OK)
            session("SetOutputDeviceProfile", OutputDeviceProfile="HLG")
            response = session("GetOutputDeviceProfile")
            self.assertEqual(response["OutputDeviceProfile"], "HLG")


def icc_tags(profile):
    count = int.from_bytes(profile[128:132], "big")
    return {profile[132 + i * 12 : 136 + i * 12] for i in range(count)}


def camera_profile(path=NEF, setup=lambda session: None):
    """From a session of its own, after setup."""
    with RecipeSession(path) as session:
        session.scale(8)
        setup(session)
        return session.camera_profile()


def monochrome(session):
    response = session(
        "RawDevelopment",
        ulRawDevelopment=PICTURE_CONTROL,
        ulPictureControl=PICTURE_CONTROL_MONOCHROME,
    )
    assert response["code"] == OK, response


class CameraProfiles(unittest.TestCase):
    def test_raw_files_have_one(self):
        for path in NEF, LEGACY_NEF, NRW:
            profile = camera_profile(path)
            self.assertEqual(int.from_bytes(profile[:4], "big"), len(profile), path)
            self.assertEqual(profile[36:40], b"acsp", path)
            self.assertEqual(profile[12:24], b"scnrRGB Lab ", path)
            self.assertIn(b"A2B0", icc_tags(profile), path)

    def test_recent_body(self):
        self.assertRegex(camera_profile(), rb"Nikon ID\d+ for NEF Mode\d")

    def test_same_settings_same_profile(self):
        with Session() as session:
            session.scale(8)
            first = session.camera_profile()
            # the session reuses its engine, and a new one can get it from the SDK's cache
            self.assertEqual(session.camera_profile(), first)
        self.assertEqual(camera_profile(), first)

    def test_settings_change_it(self):
        with Session() as session:
            session.scale(8)
            standard = session.camera_profile()
            monochrome(session)
            changed = session.camera_profile()
        self.assertNotEqual(changed, standard)
        self.assertEqual(changed, camera_profile(setup=monochrome))

    def test_output_size_leaves_it(self):
        def larger(session):
            session.scale(4)

        self.assertEqual(camera_profile(setup=larger), camera_profile())

    def test_recipes_change_it(self):
        def bleach_bypass(session):
            session.apply(recipe(BLEACH_BYPASS))

        def saturated(session):
            flexible = session.picture_control()["flc_dbParams"]
            response = session.edit(flc_dbParams={**flexible, "dbSaturation": 50})
            assert response["code"] == OK, response

        def edited(session):
            bleach_bypass(session)
            saturated(session)

        # one session through all three, each against a session of its own
        with RecipeSession() as session:
            session.scale(8)
            plain = session.camera_profile()
            bleach_bypass(session)
            recipe_profile = session.camera_profile()
            saturated(session)
            edited_profile = session.camera_profile()
        self.assertEqual(len({plain, recipe_profile, edited_profile}), 3)
        self.assertEqual(camera_profile(), plain)
        self.assertEqual(camera_profile(setup=bleach_bypass), recipe_profile)
        self.assertEqual(camera_profile(setup=edited), edited_profile)

    def test_curve_recipe(self):
        def curved(session):
            session.apply(recipe(CURVED))

        def straight(session):
            curved(session)
            assert session.edit(bUserDefinedCurve=False)["code"] == OK

        self.assertNotEqual(
            camera_profile(setup=curved), camera_profile(setup=straight)
        )

    def test_sessions_side_by_side_get_their_own(self):
        expected = [camera_profile(), camera_profile(setup=monochrome)]
        with Session() as first, Session() as second:
            for session in first, second:
                session.scale(8)
            monochrome(second)
            paths = [f"{shm.name}/{next(names)}" for _ in range(4)]
            ids = [
                worker.send(
                    "GetImageData", ulSessionID=session.id, path=image, profile=profile
                )
                for session, image, profile in zip(
                    (first, second), paths[::2], paths[1::2]
                )
            ]
            self.assertEqual([worker.wait(id)["code"] for id in ids], [OK, OK])
            profiles = []
            for path in paths:
                with open(path, "rb") as file:
                    profiles.append(file.read())
                os.unlink(path)
        self.assertEqual(profiles[1::2], expected)

    def test_jpeg_has_none(self):
        with Session(JPEG) as session:
            session.scale(4, 1)
            path = f"{shm.name}/{next(names)}"
            response = session("GetImageData", path=path, profile=f"{path}.icc")
            os.unlink(path)
            self.assertEqual(response["code"], INVALID_PARAM)
            self.assertIn("profile", response["message"])
            self.assertFalse(os.path.exists(f"{path}.icc"))

    def test_bad_profile_path(self):
        with Session() as session:
            session.scale(8)
            path = f"{shm.name}/{next(names)}"
            response = session("GetImageData", path=path, profile="/nonexistent/x.icc")
            os.unlink(path)
            self.assertEqual(response["code"], INVALID_PARAM)
            self.assertIn("/nonexistent/x.icc", response["message"])


class Thumbnails(unittest.TestCase):
    def test_all(self):
        with Session() as session:
            count = session("GetThumbnailCount")["ulImageID"]
            self.assertGreater(count, 0)
            for id in range(1, count + 1):
                info = session("GetThumbnailInfo", ulImageID=id)
                self.assertEqual(info["code"], OK)
                self.assertGreater(info["ulWidth"], 0)
                path = f"{shm.name}/{next(names)}"
                response = session("GetThumbnailData", ulImageID=id, path=path)
                self.assertEqual(response["code"], OK)
                samples = read_samples(path, response["ulByteDepth"])
                self.assertEqual(len(samples), info["ulWidth"] * info["ulHeight"] * 3)
                self.assertGreater(max(samples), 0)

    def test_resize(self):
        with Session() as session:
            info = session("GetThumbnailInfo", ulImageID=1)
            response = session(
                "SetThumbnailInfo",
                ulImageID=1,
                ulWidth=info["ulWidth"] // 2,
                ulHeight=info["ulHeight"] // 2,
                ulByteDepth=info["ulByteDepth"],
                ulOrientation=info["ulOrientation"],
            )
            self.assertEqual(response["code"], OK)
            resized = session("GetThumbnailInfo", ulImageID=1)
            self.assertEqual(resized["ulWidth"], info["ulWidth"] // 2)


class RawDevelopment(unittest.TestCase):
    def test_every_parameter_reads(self):
        for path in (NEF, LEGACY_NEF, NRW):
            with Session(path) as session:
                for flag in RAW_PARAMS:
                    response = session("GetRawDevelopmentParam", ulRawDevelopment=flag)
                    self.assertEqual(response["code"], OK, (path, flag))

    def test_every_parameter_is_writable_or_rejected_by_the_sdk(self):
        for path in (NEF, LEGACY_NEF, NRW):
            with Session(path) as session:
                info = session("GetRawDevelopmentInfo")["ulRawDevelopmentInfo"]
                for flag in RAW_PARAMS:
                    response = session("RawDevelopment", ulRawDevelopment=flag)
                    self.assertNotIn("message", response, (path, flag))
                    # the SDK lists some that it then rejects, e.g. RawQuality for NRW
                    if info & flag and path != NRW:
                        self.assertFalse(
                            failed(response["code"]), (path, flag, response)
                        )

    def test_undocumented_parameter_stays_out(self):
        with Session() as session:
            response = session(
                "RawDevelopment", ulRawDevelopment=PICTURE_CONTROL_AS_SHOT
            )
            self.assertEqual(response["code"], INVALID_PARAM)

    def test_exposure_compensation_brightens(self):
        with Session() as session:
            session.scale()
            session.set_profile("NKsRGB")
            base = statistics.fmean(session.develop()[1])
            response = session("RawDevelopment", ulRawDevelopment=EXP_COMP, dbExpComp=1)
            self.assertEqual(response["code"], OK)
            self.assertGreater(statistics.fmean(session.develop()[1]), base * 1.1)
            value = session("GetRawDevelopmentParam", ulRawDevelopment=EXP_COMP)
            self.assertEqual(value["dbExpComp"], 1)

    def test_monochrome_equalizes_channels(self):
        with Session() as session:
            session.scale()
            session.set_profile("NKsRGB")
            session(
                "RawDevelopment",
                ulRawDevelopment=PICTURE_CONTROL,
                ulPictureControl=PICTURE_CONTROL_MONOCHROME,
            )
            _, samples = session.develop()
            red, green, blue = samples[0::3], samples[1::3], samples[2::3]
            difference = max(abs(r - g) for r, g in zip(red, green))
            difference = max(difference, max(abs(g - b) for g, b in zip(green, blue)))
            self.assertLess(difference, 512)

    def test_change_keeps_other_fields(self):
        with Session() as session:
            session(
                "RawDevelopment",
                ulRawDevelopment=PICTURE_CONTROL,
                ulPictureControl=PICTURE_CONTROL_STANDARD,
            )
            before = session("GetRawDevelopmentParam", ulRawDevelopment=PICTURE_CONTROL)
            session("RawDevelopment", ulRawDevelopment=PICTURE_CONTROL, dbSaturation=2)
            after = session("GetRawDevelopmentParam", ulRawDevelopment=PICTURE_CONTROL)
            self.assertEqual(after["dbSaturation"], 2)
            self.assertEqual(after["ulPictureControl"], PICTURE_CONTROL_STANDARD)
            self.assertEqual(after["dbSharpness"], before["dbSharpness"])

    def test_flexible_color(self):
        with Session() as session:
            session.scale()
            session.set_profile("NKsRGB")
            controls = session("GetPictureControlList")["pulListItems"]
            self.assertIn(PICTURE_CONTROL_FLEXIBLE_COLOR, controls)
            session(
                "RawDevelopment",
                ulRawDevelopment=PICTURE_CONTROL,
                ulPictureControl=PICTURE_CONTROL_FLEXIBLE_COLOR,
            )
            base = session.develop()[1]
            params = session("GetRawDevelopmentParam", ulRawDevelopment=PICTURE_CONTROL)
            grading = params["flc_dbParams"]["dbColorGrading"]
            self.assertEqual([len(row) for row in grading], [3, 3, 3])
            blender = params["flc_dbParams"]["dbColorBlender"]
            blender[1][0] = 50
            response = session(
                "RawDevelopment",
                ulRawDevelopment=PICTURE_CONTROL,
                flc_dbParams={"dbColorBlender": blender},
            )
            self.assertEqual(response["flc_dbParams"]["dbColorBlender"][1][0], 50)
            self.assertEqual(response["code"], OK)
            self.assertNotEqual(session.develop()[1], base)

    def test_white_balance(self):
        with Session() as session:
            session.scale()
            session.set_profile("NKsRGB")
            base = session.develop()[1]
            response = session(
                "RawDevelopment", ulRawDevelopment=WB_ADJUSTMENT, ulMWB=WB_INCANDESCENT
            )
            self.assertEqual(response["code"], OK)
            self.assertNotEqual(session.develop()[1], base)

    def test_color_mode_needs_a_legacy_file(self):
        with Session(LEGACY_NEF) as session:
            session.scale(2)
            session.set_profile("NKsRGB")
            base = session.develop()[1]
            response = session(
                "RawDevelopment", ulRawDevelopment=COLOR_MODE, ulColorMode=COLOR_MODE_I
            )
            self.assertEqual(response["code"], OK, response)
            self.assertNotEqual(session.develop()[1], base)

    def test_last_save_setting_warns_on_unedited_files(self):
        with Session() as session:
            response = session(
                "RawDevelopment",
                ulRawDevelopment=RAW_PARAMETER_SET,
                ulParamterSet=PARAMETER_SET_LAST_SAVE,
            )
            self.assertEqual(response["code"], WARN_EDIT_STATE_NOT_EXIST)

    def test_non_raw_is_rejected(self):
        with Session(JPEG) as session:
            response = session("RawDevelopment", ulRawDevelopment=EXP_COMP, dbExpComp=1)
            self.assertNotEqual(response["code"], OK)

    def test_ranges(self):
        with Session() as session:
            response = session("GetRawDevelopmentRange")
            self.assertEqual(response["code"], OK)
            self.assertLess(response["dbMinContrast"], response["dbMaxContrast"])
            self.assertGreater(response["dbStepContrast"], 0)
            colors = response["flc_dbRanges"]
            self.assertEqual(len(colors["dbMaxFlexibleColorBlender"]), 8)
            response = session("GetColorTempRange", ulMWB=WB_INCANDESCENT)
            self.assertEqual(response["code"], OK)
            self.assertLess(response["ulMinColorTemp"], response["ulMaxColorTemp"])

    def test_picture_controls(self):
        with Session() as session:
            controls = session("GetPictureControlList")
            self.assertEqual(controls["code"], OK)
            self.assertIn(PICTURE_CONTROL_SEPIA, controls["pulListItems"])
            version = session("GetPictureControlVersion")
            self.assertEqual(version["code"], OK)
            self.assertGreater(version["ulLatestVersion"], 0)

    def test_session_states(self):
        with Session() as session:
            self.assertEqual(session("GetEditState")["code"], OK)
            for process in (COLOR_PROCESS_LATEST, COLOR_PROCESS_IN_CAMERA):
                session("SetColorProcess", ulColorProcess=process)
                self.assertEqual(session("GetColorProcess")["ulColorProcess"], process)
            self.assertEqual(session("GetDynamicRange")["code"], OK)
            self.assertNotIn("message", session("SetDynamicRange", ulDynamicRange=0))

    def test_develop_color_mode(self):
        for mode in (DEVELOP_COLOR_MODE_SRGB, DEVELOP_COLOR_MODE_ADOBE):
            self.assertEqual(
                worker("SetDevelopColorMode", lDevelopColorMode=mode)["code"], OK
            )
            self.assertEqual(worker("GetDevelopColorMode")["lDevelopColorMode"], mode)


class Tags(unittest.TestCase):
    def test_every_tag_decodes(self):
        with Session() as session:
            info = session("GetTagInfo")
            self.assertEqual(info["code"], OK)
            self.assertGreater(len(info["pulTagList"]), 10)
            for tag in info["pulTagList"]:
                response = session("GetTagData", ulTagID=tag)
                self.assertEqual(response["code"], OK, tag)
                self.assertIn("pData", response, tag)

    def test_known_tags(self):
        with Session() as session:
            model = session("GetTagData", ulTagID=TAG_MODEL)
            self.assertEqual(model["ulTagType"], TAG_TYPE_STRING)
            self.assertTrue(model["pData"].startswith("NIKON"), model)
            date = session("GetTagData", ulTagID=TAG_DATE_TIME)["pData"]
            self.assertGreater(date["ulYear"], 2000)

    def test_shooting_info(self):
        with Session() as session:
            info = session("GetTagStringInfo")
            self.assertEqual(info["code"], OK)
            cells = [
                session("GetTagString", ulLines=line, ulColumns=column)
                for line in range(info["ulLines"])
                for column in range(info["ulColumns"])
            ]
            self.assertTrue(all(cell["code"] == OK for cell in cells))
            self.assertTrue(any(cell["pData"].strip() for cell in cells))


class WhiteBalanceGains(unittest.TestCase):
    def test_nef(self):
        response = worker("GetWBGain", path=NEF)
        self.assertEqual(response["code"], OK)
        self.assertGreater(response["RGain"], 0)
        self.assertGreater(response["BGain"], 0)
        self.assertEqual(response["AppliedRGain"], 1)

    def test_not_raw(self):
        self.assertNotEqual(worker("GetWBGain", path=JPEG)["code"], OK)

    def test_missing_file(self):
        self.assertEqual(
            worker("GetWBGain", path="/nonexistent")["code"], INVALID_PARAM
        )


class Concurrency(unittest.TestCase):
    def test_progress(self):
        with Session() as session:
            session.scale()
            path = f"{shm.name}/{next(names)}"
            id = worker.send(
                "GetImageData", ulSessionID=session.id, path=path, progress=True
            )
            self.assertEqual(worker.wait(id)["code"], OK)
            os.unlink(path)
            ticks = worker.progress[id]
            self.assertGreater(len(ticks), 2)
            self.assertTrue(all(tick["ulDone"] <= tick["ulTotal"] for tick in ticks))
            self.assertTrue(any(tick["ulDone"] for tick in ticks))

    def test_no_progress_unless_asked(self):
        with Session() as session:
            session.scale()
            path = f"{shm.name}/{next(names)}"
            id = worker.send("GetImageData", ulSessionID=session.id, path=path)
            self.assertEqual(worker.wait(id)["code"], OK)
            os.unlink(path)
            self.assertNotIn(id, worker.progress)

    def test_sessions_run_side_by_side(self):
        with Session() as first, Session(LEGACY_NEF) as second:
            first.scale()
            second.scale()
            paths = [f"{shm.name}/{next(names)}" for _ in range(2)]
            ids = [
                worker.send("GetImageData", ulSessionID=session.id, path=path)
                for session, path in zip((first, second), paths)
            ]
            responses = [worker.wait(id) for id in ids]
            self.assertEqual([r["code"] for r in responses], [OK, OK])
            for path in paths:
                os.unlink(path)


class Protocol(unittest.TestCase):
    def malformed(self, line):
        worker.write(line)
        return worker.response_queue(None).get(timeout=10)

    def test_bad_json(self):
        response = self.malformed("not json")
        self.assertEqual(response["code"], INVALID_PARAM)
        self.assertIn("message", response)

    def test_not_an_object(self):
        self.assertEqual(self.malformed("1")["code"], INVALID_PARAM)

    def test_unknown_command(self):
        self.assertEqual(worker("Nonsense")["code"], INVALID_PARAM)

    def test_missing_field(self):
        response = worker("OpenSession")
        self.assertEqual(response["code"], INVALID_PARAM)
        self.assertIn("path", response["message"])

    def test_unknown_raw_parameter(self):
        with Session() as session:
            response = session("RawDevelopment", ulRawDevelopment=1 << 30)
            self.assertEqual(response["code"], INVALID_PARAM)

    def test_wrong_type(self):
        response = worker("GetImageInfo", ulSessionID="one")
        self.assertEqual(response["code"], INVALID_PARAM)

    def test_unknown_session(self):
        self.assertNotEqual(worker("GetImageInfo", ulSessionID=9999)["code"], OK)


def recipe_records(path):
    with open(path, "rb") as file:
        data = file.read()
    records, at = {}, 4
    while tag := int.from_bytes(data[at : at + 4], "big"):
        size = int.from_bytes(data[at + 4 : at + 8], "big")
        records[tag] = data[at + 8 : at + 8 + size]
        at += 8 + size
    return records


def recipe_value(value, divisor, unset):
    return unset if value in (0, 1, 0xFF) else (value - 0x80) / divisor


def expected_recipe(records):
    blender, grading = records[0x1F00], records[0x2000]
    sliders = [
        recipe_value(records[tag][0], records[tag][1], 0)
        for tag in range(0x1900, 0x1F00, 0x100)
    ]
    return {
        "dbContrast": sliders[0],
        "dbHighlight": sliders[1],
        "dbShadow": sliders[2],
        "dbWhiteLevel": sliders[3],
        "dbBlackLevel": sliders[4],
        "dbSaturation": sliders[5],
        "dbColorBlender": [
            [
                recipe_value(blender[color * 3 + value], blender[24 + value], 0)
                for value in range(3)
            ]
            for color in range(8)
        ],
        "dbColorGrading": [
            [
                int.from_bytes(grading[zone * 4 : zone * 4 + 2], "big") - 0x8000,
                recipe_value(grading[zone * 4 + 2], grading[13], 0),
                recipe_value(grading[zone * 4 + 3], grading[14], 0),
            ]
            for zone in range(3)
        ],
        "dbBlending": recipe_value(grading[16], grading[17], 50),
        "dbBalance": recipe_value(grading[18], grading[19], 0),
    }


AS_SHOT = 1


class RecipeSession(Session):
    def setup(self):
        self.scale()
        self.set_profile("NKsRGB")
        return self

    def apply(self, path):
        response = self("ApplyRecipe", path=path)
        assert response["code"] == OK, response
        return response

    def picture_control(self):
        return self("GetRawDevelopmentParam", ulRawDevelopment=PICTURE_CONTROL)

    def edit(self, **fields):
        return self("RawDevelopment", ulRawDevelopment=PICTURE_CONTROL, **fields)


def recipe(name):
    return next(path for path in glob.glob(f"{RECIPES}/**/{name}.NP3", recursive=True))


BLEACH_BYPASS, CURVED, KODACHROME = "BleachBypass_01a", "24Look_24Frames", "Kodachrome"
RICH_TONE = next(
    os.path.basename(path)[:-4]
    for path in sorted(glob.glob(f"{RECIPES}/**/*.NP3", recursive=True))
    if recipe_records(path)[0x300] == b"\x04\x93"
)


def render(name, setup=lambda session: None, **fields):
    """A session's first development: later ones can differ a little."""
    with RecipeSession(**fields) as session:
        session.setup()
        if name:
            session.apply(recipe(name))
        setup(session)
        return session.develop()[1]


class Recipes(unittest.TestCase):
    def test_known_recipe(self):
        with RecipeSession() as session:
            response = session.apply(recipe(BLEACH_BYPASS))
            value = session.picture_control()
            self.assertEqual(response["dbSharpness"], 2)
            self.assertEqual(value["ulPictureControl"], AS_SHOT)
            self.assertEqual(value["dbSharpness"], 2)
            self.assertEqual(value["dbClarity"], 0.5)
            self.assertEqual(value["dbMiddleRangeSharp"], 1)
            self.assertFalse(value["bUserDefinedCurve"])
            flexible = value["flc_dbParams"]
            self.assertEqual(flexible["dbContrast"], 40)
            self.assertEqual(flexible["dbHighlight"], -20)
            self.assertEqual(flexible["dbShadow"], -55)
            self.assertEqual(flexible["dbWhiteLevel"], 0)
            self.assertEqual(flexible["dbBlackLevel"], -10)
            self.assertEqual(flexible["dbSaturation"], -50)
            self.assertEqual(flexible["dbColorBlender"][0], [2, -2, -15])
            self.assertEqual(
                flexible["dbColorGrading"], [[0, 0, -5], [0, 0, -30], [0, 0, 0]]
            )
            self.assertEqual(flexible["dbBlending"], 50)
            self.assertEqual(flexible["dbBalance"], 0)

    def test_every_recipe(self):
        paths = glob.glob(f"{RECIPES}/**/*.NP3", recursive=True)
        self.assertGreater(len(paths), 0)
        with RecipeSession() as session:
            for path in paths:
                records = recipe_records(path)
                response = session("ApplyRecipe", path=path)
                self.assertEqual(response["code"], OK, path)
                self.assertEqual(response["bUserDefinedCurve"], 2 in records, path)
                for field, tag in (
                    ("dbSharpness", 0x600),
                    ("dbClarity", 0x700),
                    ("dbMiddleRangeSharp", 0x1600),
                ):
                    self.assertEqual(
                        response[field], recipe_value(*records[tag], None), path
                    )
                if records[0x300] == PICTURE_CONTROL_FLEXIBLE_COLOR.to_bytes(2, "big"):
                    flexible, expected = response["flc_dbParams"], expected_recipe(
                        records
                    )
                    self.assertEqual(
                        {key: flexible[key] for key in expected}, expected, path
                    )

    def test_flexible_color_matches_the_sdk(self):
        def by_hand(session):
            records = recipe_records(recipe(BLEACH_BYPASS))
            session.edit(ulPictureControl=PICTURE_CONTROL_FLEXIBLE_COLOR)
            session.edit(
                dbSharpness=2,
                dbClarity=0.5,
                dbMiddleRangeSharp=1,
                flc_dbParams=expected_recipe(records),
            )

        self.assertEqual(render(BLEACH_BYPASS), render(None, by_hand))

    def test_curve_changes_the_image(self):
        self.assertNotEqual(render(CURVED), render(None))

    def test_recipes_replace_each_other(self):
        def twice(session):
            session.apply(recipe(CURVED))
            session.apply(recipe(BLEACH_BYPASS))

        self.assertEqual(render(BLEACH_BYPASS), render(None, twice))

    def test_curve_goes_with_its_recipe(self):
        with RecipeSession() as session:
            self.assertTrue(session.apply(recipe(CURVED))["bUserDefinedCurve"])
            self.assertFalse(session.apply(recipe(BLEACH_BYPASS))["bUserDefinedCurve"])
            session.apply(recipe(CURVED))
            self.assertFalse(session.apply(recipe(KODACHROME))["bUserDefinedCurve"])

    def test_memory_session(self):
        self.assertEqual(render(BLEACH_BYPASS), render(BLEACH_BYPASS, memory=True))

    def test_session_survives(self):
        with RecipeSession() as session:
            session("RawDevelopment", ulRawDevelopment=EXP_COMP, dbExpComp=1)
            width = session("GetImageInfo")["ulWidth"]
            profile = session("GetOutputProfile")["OutputProfile"]
            response = session("ApplyRecipe", path=recipe(CURVED))
            self.assertEqual(response["code"], OK)
            session.edit(dbSharpness=4)
            self.assertEqual(session("GetImageInfo")["ulWidth"], width)
            self.assertEqual(session("GetOutputProfile")["OutputProfile"], profile)
            value = session("GetRawDevelopmentParam", ulRawDevelopment=EXP_COMP)
            self.assertEqual(value["dbExpComp"], 1)

    def test_settings_apply_on_top(self):
        def brighter(session):
            session("RawDevelopment", ulRawDevelopment=EXP_COMP, dbExpComp=1)

        base = render(CURVED)
        self.assertGreater(
            statistics.fmean(render(CURVED, brighter)), statistics.fmean(base)
        )

    def test_bad_files(self):
        with Session() as session:
            missing = session("ApplyRecipe", path="/nonexistent/recipe.NP3")
            self.assertEqual(missing["code"], INVALID_PARAM)
            self.assertIn("recipe.NP3", missing["message"])
            path = f"{shm.name}/{next(names)}"
            with open(recipe(BLEACH_BYPASS), "rb") as source, open(path, "wb") as file:
                file.write(source.read()[:200])
            truncated = session("ApplyRecipe", path=path)
            self.assertEqual(truncated["code"], INVALID_PARAM)
            with open(path, "wb") as file:
                file.write(b"junk")
            junk = session("ApplyRecipe", path=path)
            self.assertEqual(junk["code"], INVALID_PARAM)
            self.assertIn("recipe", junk["message"])
            os.unlink(path)
            self.assertEqual(session("GetFileInfo")["ulFormat"], FORMAT_NEF)

    def test_unsupported_files(self):
        for path in (LEGACY_NEF, JPEG):
            with Session(path) as session:
                response = session("ApplyRecipe", path=recipe(BLEACH_BYPASS))
                self.assertEqual(response["code"], INVALID_PARAM, path)
                self.assertIn("message", response)


class RecipeEdits(unittest.TestCase):
    EDIT = {
        "dbSharpness": 3.25,
        "dbClarity": -1.5,
        "dbMiddleRangeSharp": 2.5,
    }
    COLORS = {
        "dbContrast": 12,
        "dbHighlight": -33,
        "dbShadow": 21,
        "dbWhiteLevel": 7,
        "dbBlackLevel": -14,
        "dbSaturation": -8,
        "dbBlending": 70,
        "dbBalance": 15,
        "dbColorBlender": [[index - 4, 2 * index, -index] for index in range(8)],
        "dbColorGrading": [[120, 30, -5], [240, 15, 10], [0, 0, 20]],
    }

    def test_edits_match_the_sdk(self):
        def edited(session):
            response = session.edit(**self.EDIT, flc_dbParams=self.COLORS)
            self.assertEqual(response["code"], OK)

        def by_hand(session):
            session.edit(ulPictureControl=PICTURE_CONTROL_FLEXIBLE_COLOR)
            session.edit(bApplyQuickSharp=False, **self.EDIT, flc_dbParams=self.COLORS)

        self.assertEqual(render(BLEACH_BYPASS, edited), render(None, by_hand))

    def test_edits_read_back(self):
        with RecipeSession() as session:
            session.apply(recipe(BLEACH_BYPASS))
            response = session.edit(**self.EDIT, flc_dbParams=self.COLORS)
            self.assertEqual(response["code"], OK)
            value = session.picture_control()
            self.assertEqual(value["ulPictureControl"], AS_SHOT)
            for field, expected in self.EDIT.items():
                self.assertEqual(value[field], expected)
            for field, expected in self.COLORS.items():
                self.assertEqual(value["flc_dbParams"][field], expected, field)

    def test_each_edit_builds_on_the_last(self):
        with RecipeSession() as session:
            session.apply(recipe(BLEACH_BYPASS))
            session.edit(dbSharpness=4)
            session.edit(flc_dbParams={"dbSaturation": 20})
            session.edit(dbClarity=1)
            value = session.picture_control()
            self.assertEqual(value["dbSharpness"], 4)
            self.assertEqual(value["dbClarity"], 1)
            self.assertEqual(value["flc_dbParams"]["dbSaturation"], 20)
            self.assertEqual(value["flc_dbParams"]["dbContrast"], 40)

    def test_curve_survives_edits(self):
        def edited(session):
            session.edit(dbSharpness=5, flc_dbParams={"dbSaturation": -60})
            value = session.picture_control()
            self.assertTrue(value["bUserDefinedCurve"])
            self.assertEqual(value["dbSharpness"], 5)
            self.assertEqual(value["flc_dbParams"]["dbSaturation"], -60)

        def without_curve(session):
            session.edit(bUserDefinedCurve=False, flc_dbParams={"dbSaturation": -60})

        image = render(CURVED, edited)
        self.assertNotEqual(image, render(CURVED))
        self.assertNotEqual(image, render(CURVED, without_curve))

    def test_curve_replaces_sliders(self):
        with RecipeSession() as session:
            session.apply(recipe(CURVED))
            refused = session.edit(flc_dbParams={"dbContrast": 10})
            self.assertEqual(refused["code"], INVALID_PARAM)
            self.assertIn("curve", refused["message"])
            self.assertTrue(session.picture_control()["bUserDefinedCurve"])
            response = session.edit(
                bUserDefinedCurve=False, flc_dbParams={"dbContrast": 10}
            )
            self.assertEqual(response["code"], OK)
            self.assertFalse(response["bUserDefinedCurve"])
            self.assertEqual(response["flc_dbParams"]["dbContrast"], 10)

    def test_curve_turns_off_and_on(self):
        def off(session):
            session.edit(bUserDefinedCurve=False)

        def off_and_on(session):
            off(session)
            self.assertTrue(session.edit(bUserDefinedCurve=True)["bUserDefinedCurve"])

        self.assertNotEqual(render(CURVED, off), render(CURVED))
        self.assertEqual(render(CURVED, off_and_on), render(CURVED))

    def test_no_curve_to_turn_on(self):
        with RecipeSession() as session:
            session.apply(recipe(BLEACH_BYPASS))
            response = session.edit(bUserDefinedCurve=True)
            self.assertEqual(response["code"], INVALID_PARAM)

    def test_non_flexible_recipe(self):
        with RecipeSession() as session:
            session.apply(recipe(KODACHROME))
            value = session.edit(
                dbApplyLevel=50, dbSharpness=5, dbSaturation=1, dbHue=-1
            )
            self.assertEqual(value["code"], OK)
            for field, expected in (
                ("dbApplyLevel", 50),
                ("dbSharpness", 5),
                ("dbSaturation", 1),
                ("dbHue", -1),
            ):
                self.assertEqual(value[field], expected, field)

    def test_non_flexible_recipe_with_a_curve(self):
        with RecipeSession() as session:
            self.assertTrue(session.apply(recipe(RICH_TONE))["bUserDefinedCurve"])
            value = session.edit(dbSharpness=5, dbHighlight=1, dbShadow=-1)
            self.assertEqual(value["code"], OK)
            self.assertTrue(value["bUserDefinedCurve"])
            self.assertEqual((value["dbHighlight"], value["dbShadow"]), (1, -1))
            refused = session.edit(dbContrast=1)
            self.assertEqual(refused["code"], INVALID_PARAM)
            self.assertEqual(
                session.edit(bUserDefinedCurve=False, dbContrast=1)["dbContrast"], 1
            )

    def test_fixed_fields(self):
        with RecipeSession() as session:
            session.apply(recipe(BLEACH_BYPASS))
            for field in (
                {"dbQuickSharp": 1},
                {"bSharpessAuto": True},
                {"lFilter": 3},
                {"bApplyQuickAdjust": True},
            ):
                response = session.edit(**field)
                self.assertEqual(response["code"], INVALID_PARAM, field)
                self.assertIn(next(iter(field)), response["message"])

    def test_out_of_range(self):
        with RecipeSession() as session:
            session.apply(recipe(BLEACH_BYPASS))
            response = session.edit(flc_dbParams={"dbSaturation": 500})
            self.assertEqual(response["code"], INVALID_PARAM)
            self.assertEqual(
                session.picture_control()["flc_dbParams"]["dbSaturation"], -50
            )

    def test_refused_edit_changes_nothing(self):
        with RecipeSession() as session:
            session.apply(recipe(CURVED))
            before = session.picture_control()
            session.edit(dbSharpness=7, flc_dbParams={"dbContrast": 10})
            self.assertEqual(session.picture_control(), {**before, "id": ANY})

    def test_other_picture_control_leaves_the_recipe(self):
        with RecipeSession() as session:
            session_sharpness = session.apply(recipe(CURVED))["dbSharpness"]
            standard = session.edit(ulPictureControl=PICTURE_CONTROL_STANDARD)
            self.assertEqual(standard["code"], OK)
            self.assertEqual(standard["ulPictureControl"], PICTURE_CONTROL_STANDARD)
            self.assertNotEqual(standard["dbSharpness"], session_sharpness)
            edited = session.edit(bApplyQuickSharp=False, dbSharpness=6)
            self.assertEqual(
                (edited["ulPictureControl"], edited["dbSharpness"]),
                (PICTURE_CONTROL_STANDARD, 6),
            )
            back = session.edit(ulPictureControl=AS_SHOT)
            self.assertEqual(back["code"], OK)
            self.assertTrue(session.picture_control()["bUserDefinedCurve"])
            self.assertEqual(session.edit(dbSharpness=4)["dbSharpness"], 4)
            self.assertTrue(session.picture_control()["bUserDefinedCurve"])

    def test_plain_sessions_are_untouched(self):
        with RecipeSession() as session:
            response = session.edit(
                ulPictureControl=PICTURE_CONTROL_STANDARD, dbSharpness=5
            )
            self.assertEqual(response["code"], OK)
            self.assertEqual(
                session.picture_control()["ulPictureControl"], PICTURE_CONTROL_STANDARD
            )


def test_all_commands_called():
    missing = COMMANDS - worker.called
    assert not missing, f"not exercised: {missing}"


if __name__ == "__main__":
    shm = tempfile.TemporaryDirectory(dir="/dev/shm")
    names = map(str, itertools.count())
    worker = Worker()
    result = unittest.main(argv=sys.argv[:1], exit=False, verbosity=1).result
    test_all_commands_called()
    assert worker.stop() == 0
    sys.exit(not result.wasSuccessful())

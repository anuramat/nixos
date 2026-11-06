#!/usr/bin/env python3
# SLOP
"""Exercises every nef-worker command: test.py WORKER NEF LEGACY_NEF NRW JPEG

NEF should be from a recent body, and LEGACY_NEF from one that predates Picture Control, e.g. a D70.
Uses /dev/shm; set XDG_CACHE_HOME to try a fresh wine prefix.
"""

import array
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

WORKER, NEF, LEGACY_NEF, NRW, JPEG = sys.argv[1:6]

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

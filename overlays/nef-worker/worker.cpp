// SLOP
// Exposes Nikon's Image SDK to clients on Linux; a Windows program, run under wine by the wrapper.
// Its one argument is the SDK's memory limit in MB, ulVMMemorySize.
//
// JSON on stdin and stdout, one object per line. {"ready":true} means that the SDK is up, and EOF on
// stdin stops the worker. Requests run concurrently: wait for the response to one before sending
// another that depends on it, and tell responses apart by the optional "id" they echo:
//   -> {"id":1,"cmd":"GetImageInfo","ulSessionID":1}
//   <- {"id":1,"code":0,"ulSessionID":1,"ulWidth":8256,...}
// "code" is an eNkflCode, with the 0x01xx ones being warnings; a malformed request gets
// kNkfl_Code_Err_InvalidParam and a "message".
//
// Commands are the SDK's kNkfl_Cmd_ ones, and fields those of their structures, as Nikon documents
// them. Structure sizes are filled in, missing fields are zero, and pointers hold what they point to,
// e.g. "pulTagList" is an array. The rest differs as follows, with paths being Unix ones in UTF-8:
// - OpenSession {path, memory, bImageLoadSkip} loads the file first if "memory" is set
// - GetImageData, GetThumbnailData {ulSessionID, ulImageID, path, rectArea, progress} write the samples
//   to path, which should be on a tmpfs for clients to mmap, interleaved and little-endian;
//   the response has the image's info as well, and rectArea defaults to the whole image
// - with "progress" set, GetImageData also sends {ulDone, ulTotal} lines, with its "id", every percent;
//   they're the SDK's numbers: ulDone restarts from 0 at each processing stage, and ulTotal differs
//   between the first development of a session and the later ones
// - RawDevelopment {ulSessionID, ulRawDevelopment, ...} takes the fields of the structure for that
//   ulRawDevelopment, and keeps the current values of those it's not given
// - GetRawDevelopmentParam {ulSessionID, ulRawDevelopment} answers with these fields, and so does
//   RawDevelopment, with the values that the SDK ended up with
// - profile commands use the _UTF8 flavours, and take Unix paths, Windows ones (see the wrapper for
//   where the SDK's profiles are), or the SDK's special values, e.g. "HLG"
// - GetTagData answers with "pData": a number, string, boolean, structure, or hex for raw bytes
// - GetWBGain {path} is new: it's MiniSDK's NkWBGetWBGain, with an eNkwbResultValues "code"
// - ApplyRecipe {ulSessionID, path} is new: it applies a .NP3 Picture Control recipe, custom tone curve
//   included, and answers like GetRawDevelopmentParam. The SDK has no such command, and it forgets a
//   curve when the Picture Control changes, so this writes the recipe into a copy of the NEF in memory,
//   where cameras record it, and reopens the session behind the same ulSessionID, with its settings.
//   The SDK then calls the recipe kNkfl_PictureControl_AsShot. RawDevelopment edits it the same way,
//   so each edit starts a fresh development; choosing another Picture Control leaves the recipe, and
//   AsShot returns to it. A curve replaces some sliders, which take edits once bUserDefinedCurve is
//   off. The sliders always count, whatever bApplyQuickSharp says, and the fields that can't be edited
//   this way, dbQuickSharp, the Auto ones, filters and toning, get a kNkfl_Code_Err_InvalidParam.
// Missing on purpose: kNkfl_RawDevelopment_PictureControlAsShot, undocumented, which the SDK rejects
// whatever the structure's size. Nothing cancels a development, since contrary to its documentation
// the SDK ignores what the progress callback returns: to abort, kill the worker, and start a new one.
#define NOMINMAX
#include <windows.h>
#include <fcntl.h>
#include <io.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <algorithm>
#include <atomic>
#include <cmath>
#include <iostream>
#include <map>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <nlohmann/json.hpp>
#include "Nkfl_Interface.h"
#include "Nkwb_Interface.h"

using nlohmann::json;

#define FIELDS NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE

FIELDS(RECT, left, top, right, bottom)
FIELDS(NkflFileInfoParam, ulSessionID, ulFormat)
FIELDS(NkflImageInfoParam, ulSessionID, ulImageID, ulWidth, ulHeight, ulByteDepth, ulColor, ulOrientation, dbResolution)
FIELDS(NkflImageParam, ulSessionID, ulImageID, rectArea, ulDataSize)
FIELDS(NkflTagStringInfoParam, ulSessionID, ulLines, ulColumns)
FIELDS(NkflColorTempRangeParam, ulSessionID, ulMWB, ulDefalut, ulMinColorTemp, ulMaxColorTemp)
FIELDS(NkflRawDevelopmentInfo, ulSessionID, ulRawDevelopmentInfo)
FIELDS(NkflDynamicRange, ulSessionID, ulDynamicRange)
FIELDS(NkflEditState, ulSessionID, ulEditState)
FIELDS(NkflColorProcess, ulSessionID, ulColorProcess)
FIELDS(NkflPictureControlVersion, ulSessionID, ulLatestVersion, ulModifiedVersion, ulRecordedVersion)
FIELDS(NkflDevelopColorMode, lDevelopColorMode)

FIELDS(NkflRawDevelopment_RawParameterSet, ulParamterSet)
FIELDS(NkflRawDevelopment_RawQuality, ulQuality)
FIELDS(NkflRawDevelopment_ExpComp, dbExpComp)
FIELDS(NkflRGB, ulR, ulG, ulB)
FIELDS(NkflRawDevelopment_WBAdj, ulMWB, lColorTemp, rgb)
FIELDS(NkflRawDevelopment_Tint, lfTint)
FIELDS(NkflRawDevelopment_NR, ulNRType)
FIELDS(NkflRawDevelopment_ColorMode, ulColorMode)
FIELDS(NkflRawDevelopment_Sharpness, ulSharpness)
FIELDS(NkflRawDevelopment_ToneComp, ulToneComp)
FIELDS(NkflRawDevelopment_Saturation, ulSaturation)
FIELDS(NkflRawDevelopment_HueAdj, ulHueAdj)
FIELDS(NkflRawDevelopment_FilterEffect, ulFilterEffect)
FIELDS(NkflFlexibleColorParams, dbContrast, dbHighlight, dbShadow, dbWhiteLevel, dbBlackLevel, dbSaturation, dbColorBlender, dbColorGrading, dbBlending, dbBalance)
FIELDS(NkflRawDevelopment_PictureControl, ulPictureControl, bApplyQuickAdjust, dbQuickAdjust, bSharpessAuto, dbSharpness, bClarityAuto, dbClarity, bUserDefinedCurve, bContrastAuto, dbContrast, dbBrightness, dbHighlight, dbShadow, bSaturationAuto, dbSaturation, dbHue, lFilter, lToning, dbToningIntensity, dbApplyLevel, bApplyQuickSharp, bQuickSharpAuto, dbQuickSharp, dbMiddleRangeSharp, flc_dbParams)
FIELDS(NkflRawDevelopment_ActiveDLighting, ulActiveDLighting)
FIELDS(NkflRawDevelopment_SkinSoftening, ulSkinSoftening)
FIELDS(NkflRawDevelopment_PortraitImpressionBalance, dbHue, dbBrightness)
FIELDS(NkflRawDevelopment_PixelShiftNoiseReduction, bResolutionPriority)
FIELDS(NkflRawDevelopment_Dehaze, ulDehaze)
FIELDS(NkflRawDevelopment_FilmGrain, ulFilmGrainIntensity, ulFilmGrainSize)

FIELDS(NkflFlexibleColorRange, dbMinFlexibleColorContrast, dbMaxFlexibleColorContrast, dbStepFlexibleColorContrast, dbMinFlexibleColorHighlight, dbMaxFlexibleColorHighlight, dbStepFlexibleColorHighlight, dbMinFlexibleColorShadow, dbMaxFlexibleColorShadow, dbStepFlexibleColorShadow, dbMinFlexibleColorWhiteLevel, dbMaxFlexibleColorWhiteLevel, dbStepFlexibleColorWhiteLevel, dbMinFlexibleColorBlackLevel, dbMaxFlexibleColorBlackLevel, dbStepFlexibleColorBlackLevel, dbMinFlexibleColorSaturation, dbMaxFlexibleColorSaturation, dbStepFlexibleColorSaturation, dbMinFlexibleColorBlender, dbMaxFlexibleColorBlender, dbStepFlexibleColorBlender, dbMinFlexibleColorGrading, dbMaxFlexibleColorGrading, dbStepFlexibleColorGrading, dbMinFlexibleColorBlending, dbMaxFlexibleColorBlending, dbStepFlexibleColorBlending, dbMinFlexibleColorBalance, dbMaxFlexibleColorBalance, dbStepFlexibleColorBalance)
FIELDS(NkflRawDevelopmentRange, ulSessionID, dbMinQuickAdjust, dbMaxQuickAdjust, dbStepQuickAdjust, dbMinSharpening, dbMaxSharpening, dbStepSharpening, dbMinClarity, dbMaxClarity, dbStepClarity, dbMinContrast, dbMaxContrast, dbStepContrast, dbMinBrightness, dbMaxBrightness, dbStepBrightness, dbMinHighlight, dbMaxHighlight, dbStepHighlight, dbMinShadow, dbMaxShadow, dbStepShadow, dbMinSaturation, dbMaxSaturation, dbStepSaturation, dbMinHue, dbMaxHue, dbStepHue, dbMinToningIntensity, dbMaxToningIntensity, dbStepToningIntensity, dbMinApplyLevel, dbMaxApplyLevel, dbStepApplyLevel, dbMinQuickSharp, dbMaxQuickSharp, dbStepQuickSharp, dbMinMiddleRangeSharp, dbMaxMiddleRangeSharp, dbStepMiddleRangeSharp, flc_dbRanges)

FIELDS(NkflTagParam_DateTime, ulYear, ulMonth, ulDay, ulHour, ulMinute, dbSecond)
FIELDS(NkflLensInfo, ulWideLength, ulTeleLength, dbWideMaxAperture, dbTeleMaxAperture)
FIELDS(NkflTagParam_GPSPosition, dbDegrees, dbMinutes, dbSeconds)
FIELDS(NkflTagParam_GPSTimeStamp, ulHours, ulMinutes, ulSeconds)
FIELDS(NkflLensType, bIsCPU, bIsActiveDType, bIsDType, bIsGLense, bIsAntiVibration, bIsVLense, bIsFMountAdapter, bIsELense, bIsSTMLense)
FIELDS(NkflTagParam_WBMode, ulWBMode, ulColorTemperature)
FIELDS(NkflTagParam_BitsPerSample, ulBitsPerSample)
FIELDS(NkflTagParam_SkinSoftening, ulSkinSoftening)
FIELDS(NkflTagParam_PortraitImpressionBalance, ulHue, ulBrightness)
FIELDS(NkflTagParam_FilmGrain, ulFilmGrainIntensity, ulFilmGrainSize)

// what NkMiniLib, built with MSVC, expects from its runtime
extern "C" {
uintptr_t __security_cookie = 0x2B992DDFA232;
void __security_check_cookie(uintptr_t cookie) {
	if (cookie != __security_cookie) abort();
}
int _fltused = 0;
int __isa_available = 0;
EXCEPTION_DISPOSITION __GSHandlerCheck(PEXCEPTION_RECORD, void *, PCONTEXT, void *) { return ExceptionContinueSearch; }
}

static Nkfl_EntryProcPtr sdk;

// a client's session; recipes replace the SDK's one underneath
struct Session {
	unsigned long sdkId = 0;
	std::string path;
	bool imageLoadSkip = false;
	std::vector<char> file; // what the SDK reads, if it's reading from memory
	bool recipe = false;
	bool recipeHasCurve = false;
	std::vector<json> settings; // the requests to send again after reopening
};

static std::mutex mutex; // guards stdout and the sessions
static std::map<unsigned long, Session> sessions; // by the IDs clients know
static unsigned long lastSession;

// the 0x01xx codes are warnings
static bool failed(unsigned long code) { return code && !(code & 0x0F00); }

// wine maps Z: to the Unix root
static std::string dos(std::string path) {
	for (char &c : path)
		if (c == '/') c = '\\';
	return "Z:" + path;
}

static std::wstring wide(const std::string &utf8) {
	std::wstring s(MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, NULL, 0), 0);
	MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, s.data(), s.size());
	return s;
}

static std::vector<char> read(const std::string &path, DWORD limit = MAXDWORD) {
	HANDLE file = CreateFileW(wide(dos(path)).c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
	if (file == INVALID_HANDLE_VALUE) throw std::runtime_error("can't open " + path);
	std::vector<char> data(std::min(GetFileSize(file, NULL), limit));
	DWORD done;
	ReadFile(file, data.data(), data.size(), &done, NULL);
	CloseHandle(file);
	return data;
}

// only Unix paths need translating
static void setProfile(unsigned char (&field)[MAX_PATH], const std::string &value) {
	strncpy((char *)field, (value[0] == '/' ? dos(value) : value).c_str(), MAX_PATH - 1);
}

static void to_json(json &j, const NkflOutputProfileParam &p) {
	j = {{"ulSessionID", p.ulSessionID}, {"ulRenderingIntent", p.ulRenderingIntent}, {"OutputProfile", (const char *)p.OutputProfile}};
}
static void from_json(const json &j, NkflOutputProfileParam &p) {
	p.ulSessionID = j.at("ulSessionID");
	p.ulRenderingIntent = j.at("ulRenderingIntent");
	setProfile(p.OutputProfile, j.at("OutputProfile"));
}
static void to_json(json &j, const NkflOutputDeviceProfile &p) {
	j = {{"ulSessionID", p.ulSessionID}, {"OutputDeviceProfile", (const char *)p.OutputDeviceProfile}};
}
static void from_json(const json &j, NkflOutputDeviceProfile &p) {
	p.ulSessionID = j.at("ulSessionID");
	setProfile(p.OutputDeviceProfile, j.at("OutputDeviceProfile"));
}

template <class T> static T merged(const T &base, const json &patch) {
	json j = base;
	j.merge_patch(patch);
	return j.get<T>();
}

template <class T> static T param(const json &req) {
	T p{};
	p.ulSize = sizeof p;
	p.ulSessionID = req.at("ulSessionID");
	return p;
}

// a command with a plain structure
template <class T, unsigned long command> static json plain(const json &req) {
	T p = merged(T{}, req);
	p.ulSize = sizeof p;
	unsigned long code = sdk(command, &p);
	json res = p;
	res["code"] = code;
	return res;
}

static Session &sessionOf(const json &req) {
	std::lock_guard lock(mutex);
	return sessions.at(req.at("session"));
}

static unsigned long openSdkSession(Session &session) {
	std::string path = dos(session.path);
	NkflSessionParam s{};
	s.ulSize = sizeof s;
	s.bImageLoadSkip = session.imageLoadSkip;
	if (session.file.empty()) {
		s.ulType = kNkfl_Source_FileName_UTF8;
		s.pFileInfo = path.data();
	} else {
		s.ulType = kNkfl_Source_Memory;
		s.pFileInfo = session.file.data();
		s.ulFileSize = session.file.size();
	}
	unsigned long code = sdk(kNkfl_Cmd_OpenSession, &s);
	session.sdkId = s.ulSessionID;
	return code;
}

static json openSession(const json &req) {
	Session session;
	session.path = req.at("path");
	session.imageLoadSkip = req.value("bImageLoadSkip", false);
	if (req.value("memory", false)) session.file = read(session.path);
	unsigned long code = openSdkSession(session);
	if (failed(code)) return {{"code", code}};
	std::lock_guard lock(mutex);
	sessions[++lastSession] = std::move(session);
	return {{"code", code}, {"ulSessionID", lastSession}};
}

static json closeSession(const json &req) {
	auto s = param<NkflSessionParam>(req);
	unsigned long code = sdk(kNkfl_Cmd_CloseSession, &s);
	std::lock_guard lock(mutex);
	sessions.erase(req.at("session").get<unsigned long>());
	return {{"code", code}};
}

static void send(json line, const json &req) {
	line["id"] = req.value("id", json());
	puts(line.dump(-1, ' ', false, json::error_handler_t::replace).c_str());
}

struct Progress {
	const json &req;
	unsigned long percent;
};

static unsigned long WINAPI progress(unsigned long done, unsigned long total, void *param) {
	auto &p = *(Progress *)param;
	std::lock_guard lock(mutex);
	unsigned long percent = total ? done * 100ULL / total : 0;
	if (percent != p.percent) {
		p.percent = percent;
		send({{"ulDone", done}, {"ulTotal", total}}, p.req);
	}
	return kNkfl_Code_None;
}

static unsigned long channels(unsigned long color) {
	if (color == kNkfl_Color_Gray) return 1;
	return color == kNkfl_Color_CMYK || color == kNkfl_Color_CMYK_Gray ? 4 : 3;
}

// writes the samples to the file, through a mapping the client can share
static unsigned long writeImage(unsigned long command, NkflImageParam &image, unsigned long long size, const std::string &path) {
	HANDLE file = CreateFileW(wide(dos(path)).c_str(), GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, 0, NULL);
	// on an invalid handle, CreateFileMapping would succeed with memory no client can see
	HANDLE mapping = file == INVALID_HANDLE_VALUE ? NULL : CreateFileMappingW(file, NULL, PAGE_READWRITE, size >> 32, (DWORD)size, NULL);
	image.pData = MapViewOfFile(mapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
	image.ulDataSize = size;
	unsigned long code = image.pData ? sdk(command, &image) : kNkfl_Code_Err_FileIO;
	UnmapViewOfFile(image.pData);
	CloseHandle(mapping);
	CloseHandle(file);
	return code;
}

template <unsigned long infoCommand, unsigned long dataCommand> static json imageData(const json &req) {
	auto info = merged(NkflImageInfoParam{}, req);
	info.ulSize = sizeof info;
	unsigned long code = sdk(infoCommand, &info);
	if (failed(code)) return {{"code", code}};
	auto image = merged(NkflImageParam{}, req);
	image.ulSize = sizeof image;
	if (!req.contains("rectArea")) image.rectArea = {0, 0, (LONG)info.ulWidth, (LONG)info.ulHeight};
	Progress state{req, ~0UL};
	if (req.value("progress", false)) {
		image.pFunc = progress;
		image.pProgressParam = &state;
	}
	RECT &r = image.rectArea;
	unsigned long long size = 1ULL * (r.right - r.left) * (r.bottom - r.top) * channels(info.ulColor) * info.ulByteDepth;
	code = writeImage(dataCommand, image, size, req.at("path"));
	json res = info;
	res.update(json(image));
	res["code"] = code;
	return res;
}

// reads the current value, so that a change only needs the fields it touches
template <class T> static json rawParam(const json &req, bool change) {
	T value{};
	value.ulSize = sizeof value;
	auto p = param<NkflRawDevelopmentParam>(req);
	p.ulRawDevelopment = req.at("ulRawDevelopment");
	p.pData = &value;
	unsigned long code = sdk(kNkfl_Cmd_GetRawDevelopmentParam, &p);
	if (change) {
		value = merged(value, req);
		value.ulSize = sizeof value;
		code = sdk(kNkfl_Cmd_RawDevelopment, &p);
		// the SDK derives some fields, and changing the Picture Control resets the others
		if (!failed(code)) sdk(kNkfl_Cmd_GetRawDevelopmentParam, &p);
	}
	json res = value;
	res["code"] = code;
	return res;
}

static const std::map<unsigned long, json (*)(const json &, bool)> rawParams = {
	{kNkfl_RawDevelopment_RawParameterSet, rawParam<NkflRawDevelopment_RawParameterSet>},
	{kNkfl_RawDevelopment_RawQuality, rawParam<NkflRawDevelopment_RawQuality>},
	{kNkfl_RawDevelopment_ExpComp, rawParam<NkflRawDevelopment_ExpComp>},
	{kNkfl_RawDevelopment_WBAdjustment, rawParam<NkflRawDevelopment_WBAdj>},
	{kNkfl_RawDevelopment_Tint, rawParam<NkflRawDevelopment_Tint>},
	{kNkfl_RawDevelopment_NR, rawParam<NkflRawDevelopment_NR>},
	{kNkfl_RawDevelopment_PictureControl, rawParam<NkflRawDevelopment_PictureControl>},
	{kNkfl_RawDevelopment_ColorMode, rawParam<NkflRawDevelopment_ColorMode>},
	{kNkfl_RawDevelopment_Sharpness, rawParam<NkflRawDevelopment_Sharpness>},
	{kNkfl_RawDevelopment_ToneComp, rawParam<NkflRawDevelopment_ToneComp>},
	{kNkfl_RawDevelopment_Saturation, rawParam<NkflRawDevelopment_Saturation>},
	{kNkfl_RawDevelopment_HueAdjustment, rawParam<NkflRawDevelopment_HueAdj>},
	{kNkfl_RawDevelopment_FilterEffect, rawParam<NkflRawDevelopment_FilterEffect>},
	{kNkfl_RawDevelopment_ActiveDLighting, rawParam<NkflRawDevelopment_ActiveDLighting>},
	{kNkfl_RawDevelopment_SkinSoftening, rawParam<NkflRawDevelopment_SkinSoftening>},
	{kNkfl_RawDevelopment_PortraitImpressionBalance, rawParam<NkflRawDevelopment_PortraitImpressionBalance>},
	{kNkfl_RawDevelopment_PixelShiftNoiseReduction, rawParam<NkflRawDevelopment_PixelShiftNoiseReduction>},
	{kNkfl_RawDevelopment_Dehaze, rawParam<NkflRawDevelopment_Dehaze>},
	{kNkfl_RawDevelopment_FilmGrain, rawParam<NkflRawDevelopment_FilmGrain>},
};

static json getTagInfo(const json &req) {
	auto p = param<NkflTagInfoParam>(req);
	unsigned long code = sdk(kNkfl_Cmd_GetTagInfo, &p);
	if (failed(code)) return {{"code", code}};
	std::vector<unsigned long> tags(p.ulCount);
	p.pulTagList = tags.data();
	code = sdk(kNkfl_Cmd_GetTagInfo, &p);
	tags.resize(p.ulCount);
	return {{"code", code}, {"pulTagList", tags}};
}

template <class T> static json tagStructure(const char *data) { return *(const T *)data; }

static const std::map<unsigned long, json (*)(const char *)> tagStructures = {
	{kNkfl_TagType_DateTime, tagStructure<NkflTagParam_DateTime>},
	{kNkfl_TagType_LensInfo, tagStructure<NkflLensInfo>},
	{kNkfl_TagType_GPSPosition, tagStructure<NkflTagParam_GPSPosition>},
	{kNkfl_TagType_GPSTimeStamp, tagStructure<NkflTagParam_GPSTimeStamp>},
	{kNkfl_TagType_LensType, tagStructure<NkflLensType>},
	{kNkfl_TagType_WBMode, tagStructure<NkflTagParam_WBMode>},
	{kNkfl_TagType_BitsPerSample, tagStructure<NkflTagParam_BitsPerSample>},
	{kNkfl_TagType_SkinSoftening, tagStructure<NkflTagParam_SkinSoftening>},
	{kNkfl_TagType_PortraitImpressionBalance, tagStructure<NkflTagParam_PortraitImpressionBalance>},
	{kNkfl_TagType_FilmGrain, tagStructure<NkflTagParam_FilmGrain>},
};

static std::string hex(const std::vector<char> &data, size_t size) {
	std::string s;
	char byte[3];
	for (size_t i = 0; i < size; i++) {
		snprintf(byte, sizeof byte, "%02x", (unsigned char)data[i]);
		s += byte;
	}
	return s;
}

static json getTagData(const json &req) {
	auto p = param<NkflTagDataParam>(req);
	p.ulTagID = req.at("ulTagID");
	unsigned long code = sdk(kNkfl_Cmd_GetTagData, &p);
	json res = {{"code", code}, {"ulTagID", p.ulTagID}, {"ulTagType", p.ulTagType}, {"ulTagLength", p.ulTagLength}};
	if (failed(code)) return res;
	if (p.ulTagType == kNkfl_TagType_Long) res["pData"] = p.ulTagValue;
	if (p.ulTagType == kNkfl_TagType_SLong) res["pData"] = (long)p.ulTagValue;
	if (p.ulTagType == kNkfl_TagType_Long || p.ulTagType == kNkfl_TagType_SLong) return res;
	// zeroes make up for tags shorter than their structures
	std::vector<char> data(std::max(p.ulTagLength, 1024UL));
	p.pData = data.data();
	res["code"] = code = sdk(kNkfl_Cmd_GetTagData, &p);
	if (failed(code)) return res;
	auto structure = tagStructures.find(p.ulTagType);
	if (structure != tagStructures.end()) res["pData"] = structure->second(data.data());
	else if (p.ulTagType == kNkfl_TagType_String) res["pData"] = std::string(data.data(), strnlen(data.data(), p.ulTagLength));
	else if (p.ulTagType == kNkfl_TagType_Double) res["pData"] = *(double *)data.data();
	else if (p.ulTagType == kNkfl_TagType_Boolean) res["pData"] = *(bool *)data.data();
	else res["pData"] = hex(data, p.ulTagLength);
	return res;
}

static json getTagString(const json &req) {
	auto p = param<NkflTagStringParam>(req);
	p.ulLines = req.at("ulLines");
	p.ulColumns = req.at("ulColumns");
	unsigned long code = sdk(kNkfl_Cmd_GetTagString, &p);
	if (failed(code)) return {{"code", code}};
	std::vector<char> text(p.ulStringLength + 1);
	p.pData = text.data();
	code = sdk(kNkfl_Cmd_GetTagString, &p);
	return {{"code", code}, {"ulLayoutLength", p.ulLayoutLength}, {"pData", std::string(text.data())}};
}

static json getPictureControlList(const json &req) {
	auto p = param<NkflPictureControlList>(req);
	unsigned long code = sdk(kNkfl_Cmd_GetPictureControlList, &p);
	if (failed(code)) return {{"code", code}};
	std::vector<NkflPicConListItem> items(p.ulListCount);
	p.pulListItems = items.data();
	code = sdk(kNkfl_Cmd_GetPictureControlList, &p);
	std::vector<unsigned long> ids;
	for (const auto &item : items) ids.push_back(item.ulID);
	return {{"code", code}, {"pulListItems", ids}};
}

// A NEF's maker note is a TIFF of its own. The SDK only looks for the note's directory where cameras
// put it, so it can't move or grow: a new tag has to take over the entry of one the SDK never reads.
class MakerNote {
public:
	explicit MakerNote(std::vector<char> &file) : file(file) {
		if (file.size() < 8 || (file[0] != 'M' && file[0] != 'I')) throw std::runtime_error("not a NEF");
		bool big = file[0] == 'M';
		size_t exif = u32(entry(u32(4, big), 0x8769, big) + 8, big);
		base = u32(entry(exif, 0x927C, big) + 8, big) + 10;
		if (file.at(base) != 'I') throw std::runtime_error("unsupported maker note");
		directory = base + u32(base + 4, false);
	}
	size_t size(unsigned tag) const {
		size_t at = entry(directory, tag, false);
		return at ? u32(at + 4, false) : 0;
	}
	std::string get(unsigned tag) const {
		size_t size = this->size(tag);
		return size ? std::string(file.data() + base + u32(entry(directory, tag, false) + 8, false), size) : "";
	}
	void put(unsigned tag, const std::string &data) {
		size_t at = base + u32(entry(directory, tag, false) + 8, false);
		std::copy(data.begin(), data.end(), file.begin() + at);
	}
	bool canAdd(unsigned spare) const { return entry(directory, spare, false); }
	void add(unsigned tag, unsigned spare, const std::string &data) {
		size_t at = entry(directory, spare, false), offset = file.size() - base;
		file.insert(file.end(), data.begin(), data.end());
		set(at, tag, 2);
		set(at + 2, 7, 2); // undefined bytes
		set(at + 4, data.size(), 4);
		set(at + 8, offset, 4);
	}

private:
	std::vector<char> &file;
	size_t base, directory;

	unsigned read(size_t at, int size, bool big) const {
		unsigned value = 0;
		for (int i = 0; i < size; i++) value |= (unsigned)(unsigned char)file.at(at + i) << 8 * (big ? size - 1 - i : i);
		return value;
	}
	size_t u32(size_t at, bool big) const { return read(at, 4, big); }
	void set(size_t at, unsigned value, int size) {
		for (int i = 0; i < size; i++) file.at(at + i) = value >> 8 * i;
	}
	size_t entry(size_t ifd, unsigned tag, bool big) const {
		unsigned count = read(ifd, 2, big);
		for (unsigned i = 0; i < count; i++)
			if (read(ifd + 2 + i * 12, 2, big) == tag) return ifd + 2 + i * 12;
		return 0;
	}
};

static const unsigned kPictureControlTag = 0x23, kCurveTag = 0x8C, kFlexibleColorTag = 0x5C, kSpareTag = 0x4D;
static const size_t kPictureControlSize = 0x6C, kCurveSize = 0x242;

// where NP3 records go in the Picture Control tag, as 2 bytes: a value offset by 0x80, and its divisor
static const std::pair<unsigned long, size_t> kRecipeValues[] = {
	{0x1400, 0x35}, {0x1500, 0x37}, {0x600, 0x39}, {0x1600, 0x3B}, {0x700, 0x3D}, {0x800, 0x3F}, {0x900, 0x41}, {0xA00, 0x43}, {0xB00, 0x45},
	{0xE00, 0x49}, {0x1700, 0x4B}, {0x1800, 0x4D}, {0xF00, 0x5A}, {0x1300, 0x5C}, {0x1000, 0x5E}, {0x1100, 0x60}, {0x1200, 0x62},
};

// A recipe file is a 4-byte ID, then records of a big-endian 32-bit tag and size, up to a zero tag.
// The layout comes from the SDK's own reader, CPictureControlData::Import, which it only uses internally.
static std::map<unsigned long, std::string> recipeRecords(const std::vector<char> &file) {
	std::map<unsigned long, std::string> records;
	auto u32 = [&](size_t at) {
		auto *p = (const unsigned char *)file.data() + at;
		return (unsigned long)p[0] << 24 | p[1] << 16 | p[2] << 8 | p[3];
	};
	for (size_t at = 4; at + 8 <= file.size() && u32(at);) {
		unsigned long size = u32(at + 4);
		if (at + 8 + size > file.size()) throw std::runtime_error("truncated recipe");
		records[u32(at)].assign(file.data() + at + 8, size);
		at += 8 + size;
	}
	return records;
}

static unsigned baseControl(const std::string &id) { return (unsigned char)id.at(0) << 8 | (unsigned char)id.at(1); }

static std::string recipeControl(std::string block, std::map<unsigned long, std::string> &records) {
	auto text = [&](size_t at, std::string value) {
		value.resize(20);
		block.replace(at, 20, value);
	};
	unsigned base = baseControl(records.at(0x300));
	block.replace(0, 8, "03100310");
	text(8, records.at(0x200));
	text(28, base == kNkfl_PictureControl_FlexibleColor ? "FLEXIBLE COLOR" : records.at(0x200));
	block[0x30] = base;
	block[0x31] = base >> 8;
	block[0x32] = 0;
	block[0x34] = records.at(0x400).at(0);
	for (auto [tag, at] : kRecipeValues) block.replace(at, 2, records.at(tag), 0, 2);
	block[0x47] = records.at(0xC00).at(0);
	block[0x48] = records.at(0xD00).at(0);
	return block;
}

static std::string flexibleColorHeader() { return std::string("0100") + "0310" + "0310"; }

// the settings of a recipe based on another Picture Control: no leftovers from an earlier one
static std::string neutralFlexibleColor() {
	std::string block = flexibleColorHeader();
	for (int i = 0; i < 6; i++) block += "\xFF\x01";
	block += std::string(24, '\xFF') + std::string("\x01\x01\x01", 3) + '\0';
	block += std::string(12, '\xFF') + std::string("\x01\x01\x01", 3) + '\0' + "\xFF\x01\xFF\x01";
	block.resize(0x58);
	return block;
}

static std::string recipeFlexibleColor(std::map<unsigned long, std::string> &records) {
	std::string block = flexibleColorHeader();
	for (unsigned long tag = 0x1900; tag <= 0x1E00; tag += 0x100) block += records.at(tag).substr(0, 2);
	block += records.at(0x1F00).substr(0, 28);
	const std::string &grading = records.at(0x2000);
	// the hues are big-endian in the recipe, and little-endian here
	for (size_t zone = 0; zone < 3; zone++) block += {grading.at(zone * 4 + 1), grading.at(zone * 4), grading.at(zone * 4 + 2), grading.at(zone * 4 + 3)};
	block += grading.substr(12, 8);
	block.resize(0x58);
	return block;
}

// sends a session's settings to a new SDK session
static json dispatch(const json &req);

// the SDK session goes first: it may be reading the file
static void reopen(Session &session, const std::string &control, const std::string &flexible, const std::string &curve) {
	NkflSessionParam old{};
	old.ulSize = sizeof old;
	old.ulSessionID = session.sdkId;
	sdk(kNkfl_Cmd_CloseSession, &old);
	MakerNote note(session.file);
	note.put(kPictureControlTag, control);
	if (!curve.empty()) note.put(kCurveTag, curve);
	if (note.size(kFlexibleColorTag)) note.put(kFlexibleColorTag, flexible);
	else note.add(kFlexibleColorTag, kSpareTag, flexible);
	unsigned long code = openSdkSession(session);
	if (failed(code)) throw std::runtime_error("the SDK can't open the patched file");
	for (json request : session.settings) {
		request["ulSessionID"] = session.sdkId;
		dispatch(request);
	}
}

static json pictureControlOf(const Session &session) {
	return rawParam<NkflRawDevelopment_PictureControl>({{"ulSessionID", session.sdkId}, {"ulRawDevelopment", kNkfl_RawDevelopment_PictureControl}}, false);
}

static json applyRecipe(const json &req) {
	auto records = recipeRecords(read(req.at("path")));
	auto version = records.find(0x100);
	if (version == records.end() || version->second != "0310") throw std::runtime_error("not a version 3.10 recipe");
	Session &session = sessionOf(req);
	if (session.file.empty()) session.file = read(session.path);
	MakerNote note(session.file);
	auto curve = records.find(2);
	if (note.size(kPictureControlTag) != kPictureControlSize || (curve != records.end() && (note.size(kCurveTag) != kCurveSize || curve->second.size() != kCurveSize)) || (!note.size(kFlexibleColorTag) && !note.canAdd(kSpareTag)))
		throw std::runtime_error("files from this camera can't take recipes");
	bool flexible = baseControl(records.at(0x300)) == kNkfl_PictureControl_FlexibleColor;
	if (flexible) {
		json list = getPictureControlList(req)["pulListItems"];
		if (std::find(list.begin(), list.end(), kNkfl_PictureControl_FlexibleColor) == list.end())
			throw std::runtime_error("this camera has no Flexible Color");
	}
	reopen(session, recipeControl(note.get(kPictureControlTag), records), flexible ? recipeFlexibleColor(records) : neutralFlexibleColor(), curve == records.end() ? "" : curve->second);
	session.recipe = true;
	session.recipeHasCurve = curve != records.end();
	return pictureControlOf(session);
}

static void setRecipeValue(std::string &block, size_t at, size_t divisorAt, unsigned char divisor, double value) {
	if (unsigned char kept = block.at(divisorAt)) divisor = kept;
	long raw = lround(value * divisor) + 0x80;
	if (raw < 2 || raw > 0xFE) throw std::runtime_error("value out of range");
	block.at(at) = raw;
	block.at(divisorAt) = divisor;
}

static const struct {
	const char *field;
	size_t at;
	unsigned char divisor;
	double scale;
} kEditableFields[] = {
	{"dbApplyLevel", 0x37, 10, 0.01}, {"dbSharpness", 0x39, 4, 1}, {"dbMiddleRangeSharp", 0x3B, 4, 1},
	{"dbClarity", 0x3D, 4, 1}, {"dbContrast", 0x3F, 4, 1}, {"dbBrightness", 0x41, 4, 1}, {"dbSaturation", 0x43, 4, 1}, {"dbHue", 0x45, 4, 1},
	{"dbToningIntensity", 0x49, 4, 1}, {"dbHighlight", 0x4B, 4, 1}, {"dbShadow", 0x4D, 4, 1},
};
// Quick Sharp isn't among the above since the image follows the sliders, and the SDK's steps aren't even
static const char *const kFixedFields[] = {"dbQuickSharp", "bQuickSharpAuto", "bApplyQuickAdjust", "dbQuickAdjust", "bSharpessAuto", "bClarityAuto", "bContrastAuto", "bSaturationAuto", "lFilter", "lToning"};
// a Flexible Color curve takes the place of the first five
static const char *const kFlexibleSliders[] = {"dbContrast", "dbHighlight", "dbShadow", "dbWhiteLevel", "dbBlackLevel", "dbSaturation"};

static json editRecipe(Session &session, const json &req, const json &current) {
	json edited = current;
	edited.merge_patch(req);
	MakerNote note(session.file);
	std::string control = note.get(kPictureControlTag), flexible = note.get(kFlexibleColorTag);
	bool isFlexible = ((unsigned char)control.at(0x30) | (unsigned char)control.at(0x31) << 8) == kNkfl_PictureControl_FlexibleColor;
	for (const char *field : kFixedFields)
		if (edited[field] != current[field]) throw std::runtime_error(std::string(field) + " can't be edited on a recipe");

	bool curve = edited["bUserDefinedCurve"];
	if (curve && !session.recipeHasCurve) throw std::runtime_error("this recipe has no custom curve");
	if (curve != current["bUserDefinedCurve"].get<bool>()) {
		if (isFlexible)
			for (size_t at = 12; at < 22; at += 2) {
				flexible.at(at) = curve ? 1 : 0x80;
				flexible.at(at + 1) = 1;
			}
		else control.at(0x3F) = curve ? 1 : 0x80;
	}
	auto replacedByCurve = [&](const std::string &field) {
		if (curve) throw std::runtime_error(field + " can't be edited with a custom curve on");
	};

	for (const auto &f : kEditableFields) {
		if (edited[f.field] == current[f.field]) continue;
		if (!isFlexible && (!strcmp(f.field, "dbContrast") || !strcmp(f.field, "dbBrightness"))) replacedByCurve(f.field);
		setRecipeValue(control, f.at, f.at + 1, f.divisor, edited[f.field].get<double>() * f.scale);
	}

	json &colors = edited["flc_dbParams"], &oldColors = const_cast<json &>(current)["flc_dbParams"];
	for (size_t i = 0; i < 6; i++) {
		const char *field = kFlexibleSliders[i];
		if (colors[field] == oldColors[field]) continue;
		if (i < 5) replacedByCurve(field);
		setRecipeValue(flexible, 12 + i * 2, 13 + i * 2, 1, colors[field]);
	}
	for (size_t color = 0; color < 8; color++)
		for (size_t value = 0; value < 3; value++)
			if (colors["dbColorBlender"][color][value] != oldColors["dbColorBlender"][color][value])
				setRecipeValue(flexible, 24 + color * 3 + value, 48 + value, 1, colors["dbColorBlender"][color][value]);
	for (size_t zone = 0; zone < 3; zone++) {
		const json &zones = colors["dbColorGrading"][zone];
		if (zones[0] != oldColors["dbColorGrading"][zone][0]) {
			int hue = 0x8000 + lround(zones[0].get<double>());
			flexible.at(52 + zone * 4) = hue;
			flexible.at(53 + zone * 4) = hue >> 8;
		}
		for (size_t value = 1; value < 3; value++)
			if (zones[value] != oldColors["dbColorGrading"][zone][value])
				setRecipeValue(flexible, 53 + zone * 4 + value, 64 + value, 1, zones[value]);
	}
	if (colors["dbBlending"] != oldColors["dbBlending"]) setRecipeValue(flexible, 68, 69, 1, colors["dbBlending"]);
	if (colors["dbBalance"] != oldColors["dbBalance"]) setRecipeValue(flexible, 70, 71, 1, colors["dbBalance"]);

	reopen(session, control, flexible, "");
	return pictureControlOf(session);
}

static json rawDevelopment(const json &req) {
	unsigned long what = req.at("ulRawDevelopment");
	if (what == kNkfl_RawDevelopment_PictureControl) {
		Session &session = sessionOf(req);
		json current = pictureControlOf(session);
		bool asShot = current["ulPictureControl"] == kNkfl_PictureControl_AsShot;
		if (session.recipe && asShot && req.value("ulPictureControl", (unsigned long)kNkfl_PictureControl_AsShot) == kNkfl_PictureControl_AsShot)
			return editRecipe(session, req, current);
	}
	return rawParams.at(what)(req, true);
}

static json getRawDevelopmentParam(const json &req) { return rawParams.at(req.at("ulRawDevelopment"))(req, false); }

static json getWBGain(const json &req) {
	auto header = read(req.at("path"), 1 << 20); // Nikon asks for 150 kB or more
	double r, b, gr, gb, appliedR, appliedB, appliedGr, appliedGb;
	unsigned long code = NkWBGetWBGain(header.data(), header.size(), &r, &b, &gr, &gb, &appliedR, &appliedB, &appliedGr, &appliedGb);
	if (code) return {{"code", code}};
	return {{"code", code}, {"RGain", r}, {"BGain", b}, {"GrGain", gr}, {"GbGain", gb}, {"AppliedRGain", appliedR}, {"AppliedBGain", appliedB}, {"AppliedGrGain", appliedGr}, {"AppliedGbGain", appliedGb}};
}

#define PLAIN(name, type) {#name, plain<type, kNkfl_Cmd_##name>}

static const std::map<std::string, json (*)(const json &)> commands = {
	{"OpenSession", openSession},
	{"CloseSession", closeSession},
	PLAIN(GetFileInfo, NkflFileInfoParam),
	{"GetOutputProfile", plain<NkflOutputProfileParam, kNkfl_Cmd_GetOutputProfile_UTF8>},
	{"SetOutputProfile", plain<NkflOutputProfileParam, kNkfl_Cmd_SetOutputProfile_UTF8>},
	PLAIN(GetOutputDeviceProfile, NkflOutputDeviceProfile),
	PLAIN(SetOutputDeviceProfile, NkflOutputDeviceProfile),
	PLAIN(GetImageInfo, NkflImageInfoParam),
	PLAIN(SetImageInfo, NkflImageInfoParam),
	PLAIN(GetOriginalInfo, NkflImageInfoParam),
	{"GetImageData", imageData<kNkfl_Cmd_GetImageInfo, kNkfl_Cmd_GetImageData>},
	PLAIN(GetRawDevelopmentInfo, NkflRawDevelopmentInfo),
	{"RawDevelopment", rawDevelopment},
	{"GetRawDevelopmentParam", getRawDevelopmentParam},
	{"ApplyRecipe", applyRecipe},
	PLAIN(GetRawDevelopmentRange, NkflRawDevelopmentRange),
	PLAIN(GetColorTempRange, NkflColorTempRangeParam),
	PLAIN(GetThumbnailCount, NkflImageInfoParam),
	PLAIN(GetThumbnailInfo, NkflImageInfoParam),
	PLAIN(SetThumbnailInfo, NkflImageInfoParam),
	{"GetThumbnailData", imageData<kNkfl_Cmd_GetThumbnailInfo, kNkfl_Cmd_GetThumbnailData>},
	{"GetTagInfo", getTagInfo},
	{"GetTagData", getTagData},
	PLAIN(GetTagStringInfo, NkflTagStringInfoParam),
	{"GetTagString", getTagString},
	PLAIN(GetEditState, NkflEditState),
	PLAIN(GetColorProcess, NkflColorProcess),
	PLAIN(SetColorProcess, NkflColorProcess),
	{"GetPictureControlList", getPictureControlList},
	PLAIN(GetPictureControlVersion, NkflPictureControlVersion),
	PLAIN(GetDevelopColorMode, NkflDevelopColorMode),
	PLAIN(SetDevelopColorMode, NkflDevelopColorMode),
	PLAIN(GetDynamicRange, NkflDynamicRange),
	PLAIN(SetDynamicRange, NkflDynamicRange),
	{"GetWBGain", getWBGain},
};

static json dispatch(const json &req) { return commands.at(req.at("cmd"))(req); }

// what a new SDK session would forget: Picture Controls are the recipe's business
static void remember(const json &req, const json &res) {
	static const char *const settings[] = {"SetImageInfo", "SetThumbnailInfo", "SetOutputProfile", "SetOutputDeviceProfile", "SetColorProcess", "SetDynamicRange", "RawDevelopment"};
	const std::string cmd = req.at("cmd");
	if (std::none_of(std::begin(settings), std::end(settings), [&](const char *name) { return cmd == name; })) return;
	const char *key = cmd == "RawDevelopment" ? "ulRawDevelopment" : "ulImageID";
	if (req.value(key, 0UL) == kNkfl_RawDevelopment_PictureControl && cmd == "RawDevelopment") return;
	json saved = req;
	saved.update(res);
	saved[key] = req.value(key, 0UL);
	auto &remembered = sessionOf(req).settings;
	std::lock_guard lock(mutex);
	remembered.erase(std::remove_if(remembered.begin(), remembered.end(), [&](const json &old) { return old["cmd"] == cmd && old[key] == saved[key]; }), remembered.end());
	remembered.push_back(saved);
}

static void handle(const std::string &line) {
	json req, res;
	try {
		req = json::parse(line);
		json inner = req;
		if (req.contains("ulSessionID")) {
			inner["session"] = req["ulSessionID"];
			inner["ulSessionID"] = sessionOf(inner).sdkId;
		}
		res = dispatch(inner);
		if (req.contains("ulSessionID")) {
			if (req.at("cmd") != "CloseSession" && !failed(res.at("code"))) remember(inner, res);
			if (res.contains("ulSessionID")) res["ulSessionID"] = req["ulSessionID"];
		}
	} catch (const std::exception &e) {
		res = {{"code", kNkfl_Code_Err_InvalidParam}, {"message", e.what()}};
	}
	std::lock_guard lock(mutex);
	send(res, req.is_object() ? req : json::object());
}

int main(int argc, char **argv) {
	_setmode(_fileno(stdout), _O_BINARY);
	setvbuf(stdout, NULL, _IONBF, 0);
	sdk = (Nkfl_EntryProcPtr)GetProcAddress(LoadLibraryA("NkImgSDK.dll"), "Nkfl_Entry");
	char temp[MAX_PATH];
	GetTempPathA(MAX_PATH, temp);
	NkflLibraryParam library{};
	library.ulSize = sizeof library;
	library.ulVersion = 0x01000000;
	library.ulVMMemorySize = argc > 1 ? atol(argv[1]) : 8192;
	snprintf((char *)library.VMFileInfo, MAX_PATH, "%snef-worker-%lu.tmp", temp, GetCurrentProcessId());
	strcpy((char *)library.DefProfPath, temp);
	if (unsigned long code = sdk(kNkfl_Cmd_OpenLibrary, &library)) {
		printf("{\"code\":%lu}\n", code);
		return 1;
	}
	puts("{\"ready\":true}");
	static std::atomic<int> running;
	std::string line;
	while (std::getline(std::cin, line)) {
		running++;
		std::thread([line] {
			handle(line);
			running--;
		}).detach();
	}
	while (running) Sleep(10);
	sdk(kNkfl_Cmd_CloseLibrary, NULL);
}

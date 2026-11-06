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
// - GetRawDevelopmentParam {ulSessionID, ulRawDevelopment} answers with these fields
// - profile commands use the _UTF8 flavours, and take Unix paths, Windows ones (see the wrapper for
//   where the SDK's profiles are), or the SDK's special values, e.g. "HLG"
// - GetTagData answers with "pData": a number, string, boolean, structure, or hex for raw bytes
// - GetWBGain {path} is new: it's MiniSDK's NkWBGetWBGain, with an eNkwbResultValues "code"
// - ApplyRecipe {ulSessionID, path} is new: it applies a Flexible Color .NP3 Picture Control recipe, and
//   answers like RawDevelopment; the SDK has no such command, and can't take custom tone curves,
//   so recipes with one are refused, as are those based on other Picture Controls
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
#include <iostream>
#include <map>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
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

static std::mutex mutex; // guards stdout and the map below
static std::map<unsigned long, std::vector<char>> memoryFiles; // by session, for the SDK to read

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

static json openSession(const json &req) {
	std::string path = dos(req.at("path"));
	std::vector<char> file;
	NkflSessionParam s{};
	s.ulSize = sizeof s;
	s.bImageLoadSkip = req.value("bImageLoadSkip", false);
	if (req.value("memory", false)) {
		file = read(req.at("path"));
		s.ulType = kNkfl_Source_Memory;
		s.pFileInfo = file.data();
		s.ulFileSize = file.size();
	} else {
		s.ulType = kNkfl_Source_FileName_UTF8;
		s.pFileInfo = path.data();
	}
	unsigned long code = sdk(kNkfl_Cmd_OpenSession, &s);
	if (!failed(code) && !file.empty()) {
		std::lock_guard lock(mutex);
		memoryFiles[s.ulSessionID] = std::move(file);
	}
	return {{"code", code}, {"ulSessionID", s.ulSessionID}};
}

static json closeSession(const json &req) {
	auto s = param<NkflSessionParam>(req);
	unsigned long code = sdk(kNkfl_Cmd_CloseSession, &s);
	std::lock_guard lock(mutex);
	memoryFiles.erase(s.ulSessionID);
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

static json rawDevelopment(const json &req) { return rawParams.at(req.at("ulRawDevelopment"))(req, true); }
static json getRawDevelopmentParam(const json &req) { return rawParams.at(req.at("ulRawDevelopment"))(req, false); }

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

static unsigned char recipeByte(const std::string &record, size_t at) { return record.at(at); }

// 0, 1 and 0xFF mean that the value is unset
static bool recipeValueIsSet(const std::string &record, size_t at) {
	unsigned char value = recipeByte(record, at);
	return value > 1 && value != 0xFF;
}

static double recipeValue(const std::string &record, size_t at, size_t divisorAt, double unset) {
	if (!recipeValueIsSet(record, at)) return unset;
	return (recipeByte(record, at) - 0x80) / (double)recipeByte(record, divisorAt);
}

static json applyRecipe(const json &req) {
	auto records = recipeRecords(read(req.at("path")));
	auto version = records.find(0x100);
	if (version == records.end() || version->second != "0310") throw std::runtime_error("not a version 3.10 recipe");
	if (records.count(1) || records.count(2)) throw std::runtime_error("custom tone curves aren't supported");
	const std::string &base = records.at(0x300);
	if (recipeByte(base, 0) || recipeByte(base, 1) != kNkfl_PictureControl_FlexibleColor)
		throw std::runtime_error("only Flexible Color recipes are supported");

	// changing the Picture Control resets the other fields, so it needs a request of its own
	json change = {{"ulSessionID", req.at("ulSessionID")}, {"ulRawDevelopment", kNkfl_RawDevelopment_PictureControl}, {"ulPictureControl", kNkfl_PictureControl_FlexibleColor}};
	json defaults = rawParam<NkflRawDevelopment_PictureControl>(change, true);
	if (failed(defaults["code"])) return defaults;

	auto slider = [&](json &target, const json &unset, const char *field, unsigned long tag) {
		target[field] = recipeValue(records.at(tag), 0, 1, unset[field]);
	};
	slider(change, defaults, "dbSharpness", 0x600);
	slider(change, defaults, "dbClarity", 0x700);
	slider(change, defaults, "dbMiddleRangeSharp", 0x1600);
	// when it's set, the SDK derives the three above from it, as the recipe did
	change["bApplyQuickSharp"] = recipeValueIsSet(records.at(0x1400), 0);
	slider(change, defaults, "dbQuickSharp", 0x1400);

	json flexible;
	const json &unset = defaults["flc_dbParams"];
	slider(flexible, unset, "dbContrast", 0x1900);
	slider(flexible, unset, "dbHighlight", 0x1A00);
	slider(flexible, unset, "dbShadow", 0x1B00);
	slider(flexible, unset, "dbWhiteLevel", 0x1C00);
	slider(flexible, unset, "dbBlackLevel", 0x1D00);
	slider(flexible, unset, "dbSaturation", 0x1E00);

	// 8 colors of hue, chroma and brightness, then the divisors of these
	const std::string &blender = records.at(0x1F00);
	double colors[8][3] = {};
	for (size_t color = 0; color < 8; color++)
		for (size_t value = 0; value < 3; value++)
			colors[color][value] = recipeValue(blender, color * 3 + value, 24 + value, 0);
	flexible["dbColorBlender"] = colors;

	// 3 zones of a 16-bit hue, chroma and brightness, the divisors of these, then blending and balance
	const std::string &grading = records.at(0x2000);
	double zones[3][3] = {};
	for (size_t zone = 0; zone < 3; zone++) {
		unsigned hue = recipeByte(grading, zone * 4) << 8 | recipeByte(grading, zone * 4 + 1);
		zones[zone][0] = hue == 0xFFFF ? 0 : ((int)hue - 0x8000) / (double)recipeByte(grading, 12);
		zones[zone][1] = recipeValue(grading, zone * 4 + 2, 13, 0);
		zones[zone][2] = recipeValue(grading, zone * 4 + 3, 14, 0);
	}
	flexible["dbColorGrading"] = zones;
	flexible["dbBlending"] = recipeValue(grading, 16, 17, unset["dbBlending"]);
	flexible["dbBalance"] = recipeValue(grading, 18, 19, unset["dbBalance"]);

	change["flc_dbParams"] = flexible;
	return rawParam<NkflRawDevelopment_PictureControl>(change, true);
}

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

static void handle(const std::string &line) {
	json req, res;
	try {
		req = json::parse(line);
		res = commands.at(req.at("cmd"))(req);
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

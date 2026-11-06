// Develops NEF/NRW files with Nikon's Image SDK; a Windows program, for clients on Linux.
//
// Prints {"ready":true} once the SDK is up, then takes requests on stdin, one per line:
//   render<TAB>NEF<TAB>OUT
// with Unix paths in UTF-8, and answers each with one line on stdout:
//   {"width":W,"height":H,"depth":BYTES_PER_SAMPLE}, or {"error":eNkflCode}
// OUT gets interleaved sRGB samples, little-endian; put it on a tmpfs to mmap it.
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include "Nkfl_Interface.h"

static const unsigned long kMemoryLimitMB = 8192;
static const char kProfile[] = "C:\\Program Files\\Common Files\\Nikon\\Profiles\\NKsRGB.icm";

static Nkfl_EntryProcPtr sdk;

template <class T> static T param(unsigned long session = 0) {
	T p{};
	p.ulSize = sizeof p;
	p.ulSessionID = session;
	return p;
}

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

static unsigned long develop(unsigned long session, const NkflImageInfoParam &info, const std::string &out) {
	unsigned long long size = 3ULL * info.ulWidth * info.ulHeight * info.ulByteDepth;
	HANDLE file = CreateFileW(wide(dos(out)).c_str(), GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, 0, NULL);
	// on an invalid handle, CreateFileMapping would succeed with memory no client can see
	HANDLE mapping = file == INVALID_HANDLE_VALUE ? NULL : CreateFileMappingW(file, NULL, PAGE_READWRITE, size >> 32, (DWORD)size, NULL);
	void *view = MapViewOfFile(mapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
	auto image = param<NkflImageParam>(session);
	image.rectArea.right = info.ulWidth;
	image.rectArea.bottom = info.ulHeight;
	image.ulDataSize = size;
	image.pData = view;
	unsigned long code = view ? sdk(kNkfl_Cmd_GetImageData, &image) : kNkfl_Code_Err_FileIO;
	UnmapViewOfFile(view);
	CloseHandle(mapping);
	CloseHandle(file);
	return code;
}

static unsigned long render(const std::string &nef, const std::string &out, NkflImageInfoParam &info) {
	std::string path = dos(nef);
	auto session = param<NkflSessionParam>();
	session.ulType = kNkfl_Source_FileName_UTF8;
	session.pFileInfo = path.data();
	unsigned long code = sdk(kNkfl_Cmd_OpenSession, &session);
	if (failed(code)) return code;
	auto profile = param<NkflOutputProfileParam>(session.ulSessionID);
	strcpy((char *)profile.OutputProfile, kProfile);
	info.ulSessionID = session.ulSessionID;
	if (!failed(code = sdk(kNkfl_Cmd_SetOutputProfile, &profile)) && !failed(code = sdk(kNkfl_Cmd_GetImageInfo, &info)))
		code = develop(session.ulSessionID, info, out);
	sdk(kNkfl_Cmd_CloseSession, &session);
	return code;
}

int main() {
	setvbuf(stdout, NULL, _IONBF, 0);
	sdk = (Nkfl_EntryProcPtr)GetProcAddress(LoadLibraryA("NkImgSDK.dll"), "Nkfl_Entry");
	char temp[MAX_PATH];
	GetTempPathA(MAX_PATH, temp);
	NkflLibraryParam library{};
	library.ulSize = sizeof library;
	library.ulVersion = 0x01000000;
	library.ulVMMemorySize = kMemoryLimitMB;
	snprintf((char *)library.VMFileInfo, MAX_PATH, "%snef-worker-%lu.tmp", temp, GetCurrentProcessId());
	strcpy((char *)library.DefProfPath, temp);
	if (unsigned long code = sdk(kNkfl_Cmd_OpenLibrary, &library)) {
		printf("{\"error\":%lu}\n", code);
		return 1;
	}
	puts("{\"ready\":true}");
	static char line[8192], nef[4096], out[4096];
	while (fgets(line, sizeof line, stdin)) {
		auto info = param<NkflImageInfoParam>();
		unsigned long code = sscanf(line, "render\t%4095[^\t]\t%4095[^\n]", nef, out) == 2 ? render(nef, out, info) : kNkfl_Code_Err_InvalidParam;
		if (failed(code))
			printf("{\"error\":%lu}\n", code);
		else
			printf("{\"width\":%lu,\"height\":%lu,\"depth\":%lu}\n", info.ulWidth, info.ulHeight, info.ulByteDepth);
	}
	sdk(kNkfl_Cmd_CloseLibrary, NULL);
}

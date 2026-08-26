--[[
    Config Import Utility
    ====================================================================
    Ensure that your configuration files (e.g., .txt files) from 
    C:\Users\rifk\Desktop\neverlose_csgo\configs are placed into the 
    Neverlose configs directory for this script to function correctly:
    
    C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\nl\configs
    (or wherever your specific CS:GO path is \nl\configs)
    
    Once placed there, you can select and load them directly through 
    the Lua's menu interface.
    ====================================================================
]]

local a = require("neverlose/base64")
local b = require("neverlose/clipboard")
local c = {}
do
	ffi.cdef([[
        typedef unsigned long DWORD;
        typedef int BOOL;
        typedef const char* LPCSTR;
        typedef void* HANDLE;
    ]])
	pcall(function()
		ffi.cdef([[
            typedef struct _WIN32_FIND_DATAA {
                DWORD dwFileAttributes;
                unsigned long ftCreationTime[2];
                unsigned long ftLastAccessTime[2];
                unsigned long ftLastWriteTime[2];
                DWORD nFileSizeHigh;
                DWORD nFileSizeLow;
                DWORD dwReserved0;
                DWORD dwReserved1;
                char  cFileName[260];
                char  cAlternateFileName[14];
            } WIN32_FIND_DATAA;
        ]])
	end)
	local d = ffi.cast("void*", -1)
	local e = 0xFFFFFFFF
	local f = 0x80000000
	local g = 0x40000000
	local h = 2
	local i = 3
	local j = 0x10
	local k = 0x80
	ffi.cdef([[
        HANDLE FindFirstFileA(LPCSTR lpFileName, struct _WIN32_FIND_DATAA* lpFindFileData);
        BOOL FindNextFileA(HANDLE hFindFile, struct _WIN32_FIND_DATAA* lpFindFileData);
        BOOL FindClose(HANDLE hFindFile);
        DWORD GetFileAttributesA(LPCSTR lpFileName);
        BOOL CreateDirectoryA(LPCSTR lpPathName, void* lpSecurityAttributes);
        HANDLE CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode,void* lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
        BOOL WriteFile(HANDLE hFile, const void* lpBuffer, DWORD nNumberOfBytesToWrite, DWORD* lpNumberOfBytesWritten, void* lpOverlapped);
        BOOL ReadFile(HANDLE hFile, void* lpBuffer, DWORD nNumberOfBytesToRead, DWORD* lpNumberOfBytesRead, void* lpOverlapped);
        BOOL CloseHandle(HANDLE hObject);
        BOOL DeleteFileA(LPCSTR lpFileName);
    ]])
	local function l(m, n)
		local o = ffi.C.CreateFileA(m, g, 0, nil, h, k, nil)
		if o == d then
			error(string.format("Failed to open file @ %s", m))
		end
		local p = ffi.new("DWORD[1]")
		ffi.C.WriteFile(o, n, #n, p, nil)
		ffi.C.CloseHandle(o)
		return true
	end
	local function q(m)
		local o = ffi.C.CreateFileA(m, f, 0, nil, i, k, nil)
		if o == d then
			error(string.format("File not found @ %s", m))
		end
		local r = ffi.C.GetFileAttributesA(m)
		if r == e then
			ffi.C.CloseHandle(o)
			error(string.format("Failed to get filesize of file @ %s", m))
		end
		local s = ffi.new("char[?]", 65536)
		local t = ffi.new("DWORD[1]")
		local u = {}
		while ffi.C.ReadFile(o, s, 65536, t, nil) ~= 0 and t[0] > 0 do
			table.insert(u, ffi.string(s, t[0]))
		end
		ffi.C.CloseHandle(o)
		return table.concat(u)
	end
	local function v(m)
		local r = ffi.C.GetFileAttributesA(m)
		if r == e then
			return false
		end
		return true
	end
	local function w(m)
		local x = ffi.C.CreateDirectoryA(m, nil)
		if x == 0 then
			error(string.format("CreateDirectoryA @ %s", m))
		end
	end
	local function y(z)
		local A = z .. "\\*"
		local B = ffi.new("WIN32_FIND_DATAA[1]")
		local o = ffi.C.FindFirstFileA(A, B)
		local C = {}
		if o == d then
			error(string.format("file.list - INVALID_HANDLE_VALUE [folder not found: %s]", z))
		end
		repeat
			local D = ffi.string(B[0].cFileName)
			local r = B[0].dwFileAttributes
			if D ~= "." and D ~= ".." then
				if bit.band(r, j) == 0 then
					table.insert(C, D)
				end
			end
		until ffi.C.FindNextFileA(o, B) == 0
		ffi.C.FindClose(o)
		return C
	end
	local function E(m)
		if not v(m) then
			return
		end
		local r = ffi.C.GetFileAttributesA(m)
		if r == e then
			error(string.format("file.delete - INVALID_FILE_ATTRIBUTES [file: %s]", m))
		end
		if bit.band(r, j) ~= 0 then
			return
		end
		local x
		x = ffi.C.DeleteFileA(m)
		if x == 0 then
			error(string.format("file.delete - DeleteFileA [file: %s]", m))
		end
	end
	c.write = l
	c.read = q
	c.exists = v
	c.create_folder = w
	c.list = y
	c.delete = E
	c.MASTER_PATH = ".\\nl\\configs"
	if not v(c.MASTER_PATH) then
		w(c.MASTER_PATH)
	end
end
local F = {
	["Ragebot"] = ui.find("Aimbot", "Ragebot"),
	["Anti Aim"] = ui.find("Aimbot", "Anti Aim"),
	["Legitbot"] = ui.find("Aimbot", "Legitbot"),
	["Players"] = ui.find("Visuals", "Players"),
	["World"] = ui.find("Visuals", "World"),
	["Inventory"] = ui.find("Visuals", "Inventory"),
	["Main"] = ui.find("Miscellaneous", "Main"),
}
local G = { "Ragebot", "Anti Aim", "Legitbot", "Players", "World", "Inventory", "Main" }
local H = {}
do
	H.merge = function(...)
		local I = ""
		for J = 1, select("#", ...) do
			I = I .. select(J, ...)
		end
		return I
	end
	H.sanitize = function(I)
		if not I then
			return ""
		end
		I = I:gsub("[^%w_%-% ]", "")
		return I
	end
end
local K = {}
do
	K.string = {}
	K.string.capital = function(I)
		return H.merge(I:sub(1, 1):upper(), I:sub(2))
	end
end
local L = new_class()
	:struct("groups")({
	main = (function()
		return {
			config = ui.create("\n", "\nConfigs", 1),
			config_desc = ui.create("\n", "\nConfig Info", 1),
			tab_selector = ui.create("\n", "\nTab Selector", 2),
			tab_desc = ui.create("\n", "\nTab Info", 2),
		}
	end)(),
})
	:struct("elements")({})
L.elements.create = (function(self)
	self.config = {
		name = self.groups.main.config:input("\nNAME"),
		configs_list = self.groups.main.config:list("##CONFIGS", c.list(c.MASTER_PATH)),
		actions = (function()
			local M = {}
			M.delete = self.groups.main.config:button(
				H.merge("\aE74C3CFF", ui.get_icon("trash-xmark")),
				function() end,
				true
			)
			M.create = self.groups.main.config:button(
				H.merge("\a2ECC71FF", ui.get_icon("circle-plus")),
				function() end,
				true
			)
			M.load = self.groups.main.config:button(
				H.merge("\a2980B9FF", ui.get_icon("file-check")),
				function() end,
				true
			)
			M.save = self.groups.main.config:button(
				H.merge("\a8E44ADFF", ui.get_icon("floppy-disk")),
				function() end,
				true
			)
			return M
		end)(),
	}
	self.tabs = {
		tab_list = self.groups.main.tab_selector:listable(
			"\nTabs",
			{ "Ragebot", "Anti Aim", "Legitbot", "Players", "World", "Inventory", "Main" }
		),
		actions = (function()
			local M = {}
			M.import = self.groups.main.tab_selector:button(
				H.merge("\aFFFFFFFF", ui.get_icon("file-import"), " Import"),
				function() end
			)
			M.import:tooltip("Import tab config from clipboard")
			M.export = self.groups.main.tab_selector:button(
				H.merge("\aFFFFFFFF", ui.get_icon("file-export"), " Export"),
				function() end
			)
			M.export:tooltip("Export selected tab config to clipboard")
			return M
		end)(),
	}
	for N, O in pairs(self.config.actions) do
		O:tooltip(string.format("%s Preset", K.string.capital(N)))
	end
end)(L.elements)
local P
do
	local Q = a.encode(json.stringify({}))
	local R = L.elements.config.configs_list
	R:set_callback(function(self)
		self:update(c.list(c.MASTER_PATH))
		L.elements.config.name:set(self:list()[self:get()] or "")
	end, true)
	L.elements.config.name:set_callback(function(self)
		L.elements.config.name:set(H.sanitize(self:get()))
	end)
	L.elements.config.actions.delete:set_callback(function()
		if L.elements.config.name:get() ~= "" then
			c.delete(string.format("%s\\%s", c.MASTER_PATH, H.sanitize(L.elements.config.name:get())))
		end
		R:update(c.list(c.MASTER_PATH))
		L.elements.config.name:set(R:list()[R:get()] or "")
	end)
	L.elements.config.actions.create:set_callback(function()
		if
			L.elements.config.name:get() ~= ""
			and not c.exists(string.format("%s\\%s", c.MASTER_PATH, H.sanitize(L.elements.config.name:get())))
		then
			c.write(string.format("%s\\%s", c.MASTER_PATH, H.sanitize(L.elements.config.name:get())), Q)
		end
		R:update(c.list(c.MASTER_PATH))
		L.elements.config.name:set(R:list()[R:get()] or "")
	end)
	L.elements.config.actions.load:set_callback(function()
		local S
		if L.elements.config.name:get() ~= "" then
			S = c.read(string.format("%s\\%s", c.MASTER_PATH, H.sanitize(L.elements.config.name:get())))
		end
		local n = json.parse(a.decode(S))
		for T, U in pairs(n) do
			local V = F[T]
			V:import(U)
		end
	end)
	L.elements.config.actions.save:set_callback(function()
		local n = {}
		for W, U in pairs(G) do
			n[U] = F[U]:export()
		end
		if L.elements.config.name:get() ~= "" then
			c.write(
				string.format("%s\\%s", c.MASTER_PATH, H.sanitize(L.elements.config.name:get())),
				a.encode(json.stringify(n))
			)
		end
	end)
	L.elements.tabs.actions.import:set_callback(function()
		local S
		if L.elements.config.name:get() ~= "" then
			S = b.get()
		end
		local n = json.parse(a.decode(S))
		for T, U in pairs(n) do
			local X = F[T]
			for J = 1, #G do
				if G[L.elements.tabs.tab_list:get()[J]] == T then
					X:import(U)
				end
			end
		end
	end)
	L.elements.tabs.actions.export:set_callback(function()
		local n = {}
		for J = 1, #G do
			local Y = G[L.elements.tabs.tab_list:get()[J]]
			n[Y] = F[Y]:export()
		end
		b.set(a.encode(json.stringify(n)))
	end)
end
-- Inline descriptions — bottom of each column
do
	local cd = L.groups.main.config_desc
	cd:label("\aAAAAAFFF Name a config and press Create.")
	cd:label("\aAAAAAFFF Select from the list, then Load or Save.")
	cd:label("\aAAAAAFFF Delete removes it from disk permanently.")

	local td = L.groups.main.tab_desc
	td:label("\aAAAAAFFF Tick the tabs you want, then Export or Import.")
	td:label("\aAAAAAFFF Export copies base64 config to your clipboard.")
	td:label("\aAAAAAFFF Import reads from clipboard into the selected tabs.")
end
ui.sidebar("\a{Link Active}Configs", "gear")

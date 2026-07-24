-- Hitsound Fix Lua for Neverlose CS:GO (increase sound limit)
local ffi = require("ffi")

ffi.cdef[[
    typedef void* HANDLE;
    typedef int BOOL;
    HANDLE CreateFileA(const char* lpFileName, unsigned long dwDesiredAccess, unsigned long dwShareMode, void* lpSecurityAttributes, unsigned long dwCreationDisposition, unsigned long dwFlagsAndAttributes, HANDLE hTemplateFile);
    BOOL ReadFile(HANDLE hFile, void* lpBuffer, unsigned long nNumberOfBytesToRead, unsigned long* lpNumberOfBytesRead, void* lpOverlapped);
    BOOL CloseHandle(HANDLE hObject);
    unsigned long GetFileSize(HANDLE hFile, unsigned long* lpFileSizeHigh);
    typedef void* HMODULE;
    BOOL PlaySoundA(const char* pszSound, HMODULE hmod, unsigned long fdwSound);
]]

local kernel32, winmm = ffi.load("kernel32"), ffi.load("winmm")
local function unpack_u16(str, pos) return (str:byte(pos) or 0) + (str:byte(pos + 1) or 0) * 256 end
local function unpack_u32(str, pos) return (str:byte(pos) or 0) + (str:byte(pos + 1) or 0) * 256 + (str:byte(pos + 2) or 0) * 65536 + (str:byte(pos + 3) or 0) * 16777216 end
local function round(v) return v >= 0 and math.floor(v + 0.5) or math.ceil(v - 0.5) end

-- Try to find menu items with case-insensitive fallback
local function find_menu_item(cat, tab, group, item, sub)
    local p = {cat, tab, group, item}
    if sub then table.insert(p, sub) end
    return ui.find(unpack(p)) or ui.find(cat, tab, group:upper(), item, sub) or ui.find(cat, tab, group:lower(), item, sub)
end

-- Read binary file using Win32 API to bypass sandbox
local function read_file_win32(path)
    local handle = kernel32.CreateFileA(path, 0x80000000, 1, nil, 3, 0x80, nil)
    if handle == nil or ffi.cast("intptr_t", handle) == ffi.cast("intptr_t", -1) then return nil end
    local size = kernel32.GetFileSize(handle, nil)
    local buf = ffi.new("char[?]", size)
    local bytes_read = ffi.new("unsigned long[1]")
    local success = kernel32.ReadFile(handle, buf, size, bytes_read, nil)
    kernel32.CloseHandle(handle)
    return (success ~= 0 and bytes_read[0] > 0) and ffi.string(buf, bytes_read[0]) or nil
end

-- Volume scaling for 16-bit and 8-bit PCM WAV data
local function scale_wav(data, volume_pct)
    if volume_pct == 100 then return data end
    if volume_pct <= 0 then return "" end
    
    local fmt_pos = data:find("fmt ")
    local data_pos = data:find("data")
    if not fmt_pos or not data_pos then return data end
    
    local audio_format = unpack_u16(data, fmt_pos + 8)
    local bits = unpack_u16(data, fmt_pos + 22)
    if audio_format ~= 1 then return data end -- PCM only
    
    local header = data:sub(1, data_pos + 7)
    local pcm = data:sub(data_pos + 8)
    local factor = volume_pct / 100
    
    if bits == 16 then
        local count = math.floor(#pcm / 2)
        local buf = ffi.new("int16_t[?]", count)
        ffi.copy(buf, pcm, count * 2)
        for i = 0, count - 1 do
            local val = round(buf[i] * factor)
            buf[i] = val > 32767 and 32767 or (val < -32768 and -32768 or val)
        end
        return header .. ffi.string(buf, count * 2)
    elseif bits == 8 then
        local count = #pcm
        local buf = ffi.new("uint8_t[?]", count)
        ffi.copy(buf, pcm, count)
        for i = 0, count - 1 do
            local val = round((buf[i] - 128) * factor + 128)
            buf[i] = val > 255 and 255 or (val < 0 and 0 or val)
        end
        return header .. ffi.string(buf, count)
    end
    return data
end

local function load_and_scale_sound(filename, volume)
    if not filename or filename == "None" or volume <= 0 then return nil end
    local path = "csgo\\sound\\hitsounds\\" .. filename
    if not path:match("%.wav$") then path = path .. ".wav" end
    local data = read_file_win32(path) or read_file_win32("C:\\Program Files (x86)\\Steam\\steamapps\\common\\Counter-Strike Global Offensive\\" .. path)
    return data and scale_wav(data, volume) or nil
end

local active_buffer = nil
local function play_sound_data(cached_data)
    if not cached_data or cached_data == "" then return end
    active_buffer = ffi.new("char[?]", #cached_data)
    ffi.copy(active_buffer, cached_data, #cached_data)
    winmm.PlaySoundA(nil, nil, 0)
    winmm.PlaySoundA(active_buffer, nil, 0x0007) -- SND_ASYNC | SND_MEMORY | SND_NODEFAULT
end

-- UI Integration
local hit_marker_sound = find_menu_item("Visuals", "World", "Other", "Hit Marker Sound")
local headshot_combo = find_menu_item("Visuals", "World", "Other", "Hit Marker Sound", "Head Shot")
local bodyshot_combo = find_menu_item("Visuals", "World", "Other", "Hit Marker Sound", "Body Shot")
local kill_combo = find_menu_item("Visuals", "World", "Other", "Hit Marker Sound", "Kill Sound")
local default_volume_slider = find_menu_item("Visuals", "World", "Other", "Hit Marker Sound", "Volume")

if default_volume_slider then default_volume_slider:visibility(false) end

local volume_slider = hit_marker_sound:create():slider("Volume", 0, 200, 100)
local headshot_cache, bodyshot_cache, kill_cache

local function update_sound_caches()
    local vol = volume_slider:get()
    headshot_cache = load_and_scale_sound(headshot_combo and headshot_combo:get(), vol)
    bodyshot_cache = load_and_scale_sound(bodyshot_combo and bodyshot_combo:get(), vol)
    kill_cache = load_and_scale_sound(kill_combo and kill_combo:get(), vol)
end

local function on_setting_changed() update_sound_caches() end
if headshot_combo then headshot_combo:set_callback(on_setting_changed) end
if bodyshot_combo then bodyshot_combo:set_callback(on_setting_changed) end
if kill_combo then kill_combo:set_callback(on_setting_changed) end
volume_slider:set_callback(on_setting_changed)

update_sound_caches()

events.shutdown:set(function()
    if default_volume_slider then default_volume_slider:visibility(true) end
end)

-- Game Event Hook
events.player_hurt:set(function(e)
    if not hit_marker_sound or not hit_marker_sound:get() then return end
    local me = entity.get_local_player()
    if not me or entity.get(e.attacker, true) ~= me then return end
    
    local victim = entity.get(e.userid, true)
    if not victim or not victim:is_enemy() then return end
    
    local cache = (e.health <= 0) and kill_cache or (e.hitgroup == 1 and headshot_cache or bodyshot_cache)
    play_sound_data(cache)
end)

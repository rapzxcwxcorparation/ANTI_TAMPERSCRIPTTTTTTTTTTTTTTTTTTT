
local _AUTH = _G._DAEMON_AUTH
if type(_AUTH) ~= "table" or type(_AUTH.key) ~= "string" or _AUTH.key == "" then
    warn("[daemons] unauthorized: please use the loader.")
    return
end

if _G.servent then
    warn("[daemons] already running - blocked duplicate execution.")
    return 
end
_G.servent = true

setfpscap(9999)
repeat task.wait() until game:IsLoaded()

cloneref = cloneref or function(x) return x end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
local Debris = cloneref(game:GetService("Debris"))
local Stats = cloneref(game:GetService("Stats"))
local LocalPlayer = Players.LocalPlayer

-- ========================================
-- CONFIG (persisted to disk)
-- ========================================
_G.config = {
    auto_parry = nil, accuracy = nil, auto_adaptive = nil, adaptive_mode = nil, random_target = nil, curve_method = '', random_curve = nil,
    random_curve_type = nil, curve_keybind = nil, curve_notify = nil, auto_spam = nil, spam_threshold = nil, manual_spam = nil,
    manual_spam_min_speed = nil, manual_notify = nil, m_ManualSpamCPS = nil, m_ManualSpamCPSMode = nil, m_ManualSpamAnimationFix = nil,
    m_ManualSpamBoost = nil, m_AbilityExploitToggle = nil, m_ThunderDashToggle = nil, m_SuperJumpToggle = nil, m_DashNoCooldownToggle = nil,
    m_CooldownProtectionToggle = nil, skin_changer = nil, names = '', unlock_all = nil, ability_esp = nil, ball_debug = nil, show_ping = nil,
    hit_sound_volume = nil, music_volume = nil, music_loop = nil, atmosphere_enabled = nil, atmosphere_density = nil, brightness = nil, contrast = nil,
    v_WinstreakValue = nil, anti_phantom = nil, d_AdvDribbleDetection = nil, d_AdvPullDetection = nil, d_AdvPulseDetection = nil,
    d_AdvTornadoDetection = nil, d_AdvHellHookDetection = nil, d_AdvWiringToggle = nil, fflag_profile = nil, fflag_json = nil, fflag_auto_load = nil,
    avatar_changer = nil, avatar_name = '', headless_enabled = nil, korblox_enabled = nil, no_render = nil, force_mat = nil, force_mat_type = nil,
    anti_cooldown = nil, triggerbot_notify = nil, thunder_dash_no_cooldown = nil, ping_fix = nil, move_compensation = nil,
    grief_enabled = nil, grief_mode = nil, grief_chance = nil, grief_prox_range = nil, grief_ball_range = nil, auto_pre_click = nil,
}

if not isfolder("daemon/configs") then makefolder("daemon/configs") end
local CONFIG_PATH = "daemon/configs/blade_ball.json"

local function save_cfg() writefile(CONFIG_PATH, HttpService:JSONEncode(_G.config)) end
local function load_cfg()
    if isfile(CONFIG_PATH) then 
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do _G.config[k] = v end
        end
    end
end
load_cfg()

local function isTrue(val) return val == true or (val ~= false and val ~= nil) end

local function _parseHexColor(s)
    if type(s) ~= "string" then return nil end
    local hex = s:gsub("#", "")
    if #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if r and g and b then return Color3.fromRGB(r, g, b) end
    end
    return nil
end

local function _c3tohex(c)
    if typeof(c) ~= "Color3" then return "#FFFFFF" end
    return string.format("#%02X%02X%02X",
        math.floor(math.clamp(c.R, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.G, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.B, 0, 1) * 255 + 0.5))
end

getgenv()._parseHexColor = _parseHexColor
getgenv()._c3tohex = _c3tohex

task.spawn(function()
    repeat save_cfg(); task.wait(1) until not _G.servent
end)

-- ========================================
-- LOAD DOD UI LIBRARY
-- ========================================
local LIB_URL = "https://raw.githubusercontent.com/rapzxcwxcorparation/DemonOfDarknessUI/refs/heads/main/DOD.luau"
local _dod_ok, Library = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
if not _dod_ok or not Library then
    warn("[daemon] DoD UI failed to load.")
    return
end

local UI = Library({
    Title             = "daemon.wtf | Blade Ball",
    Version           = "",
    Author            = "@rapptezetzee",
    TitleIcon         = "drama",
    Theme             = "Monochrome",
    TabPosition       = "Side",
    CategoryAlign     = "Center",
    ToggleKey         = Enum.KeyCode.LeftControl,
    Acrylic           = true,
    AcrylicBlur       = 24,
    Weather           = { Enabled = true, Type = "Snow", Intensity = 50 },
    Size              = UDim2.fromOffset(800, 580),
    Wallpaper         = "https://raw.githubusercontent.com/rapzxcwxcorparation/DemonOfDarknessUI/refs/heads/main/wallpaperdod/kawaii-cat-girl-3840x2160-26545.png",
    WallpaperTransparency = 0.35,
    SoundsEnabled       = true,
    SoundVolume         = 0.8,
    ReducedMotion       = false,
    LayoutDensity       = "Normal",
    SectionTransparency = 0.15,
    NotificationPosition = "TopRight",
    Tooltip             = true,
    TooltipTransparency = 0.15,
    ThemeAutoLoad       = false,
    AutoTheme           = false,
})

-- ========================================
-- STANDALONE TABS (FLAT, NO CATEGORIES)
-- ========================================
UI:CreateStandaloneTab("Dashboard", "house")
UI:CreateStandaloneTab("Main", "shield")
UI:CreateStandaloneTab("Visuals", "eye")
UI:CreateStandaloneTab("Detections", "monitor")
UI:CreateStandaloneTab("Auto Play", "play")
UI:CreateStandaloneTab("FFlags", "file")
UI:CreateStandaloneTab("Utility", "wrench")

-- ========================================
-- UI BUILDING (DASHBOARD)
-- ========================================
UI:CreateDashboardBanner("Dashboard")
UI:CreateQuickDashboard("Dashboard", "Right")
UI:CreatePerformanceDashboard("Dashboard", "Left")

local sWelcome = UI:CreateSection("Dashboard", "Welcome", "daemon.wtf Dashboard", true, "Left", "info")
UI:AddParagraph(sWelcome, "Welcome to daemon.wtf", "This is an advanced **Auto Parry** script specifically designed for **Blade Ball**. It features highly configurable parry mechanics, dynamic accuracy tuning, auto-spam, and numerous visual enhancements to give you the ultimate competitive edge.")
UI:AddParagraph(sWelcome, "Quick Tips", "Use the sidebar on the left to navigate between different modules. Press **LeftControl** to toggle the UI. You can **right-click** any control to add it to your favorites, and click the ⭐ icon in the search bar to view them.")

-- ========================================
-- UI BUILDING (MAIN - MERGED: Parry + Combat + Pre Click + Ability)
-- ========================================
local sParryL = UI:CreateSection("Main", "Parry Settings", "Core auto parry options", true, "Left", "sword")
UI:AddToggle(sParryL, "Auto Parry", isTrue(_G.config.auto_parry), function(v)
    _G.config.auto_parry = v
    if getgenv().OnAutoParryToggle then getgenv().OnAutoParryToggle(v) end
end)

local accIndex = 4
local accMap = {"200", "170", "140", "100", "90", "80", "65"}
for i, v in ipairs(accMap) do if tostring(_G.config.accuracy or 100) == v then accIndex = i end end
UI:AddDropdown(sParryL, "Accuracy", accMap, accIndex, function(idx, val)
    _G.config.accuracy = tonumber(val)
    if getgenv().OnAccuracyChange then getgenv().OnAccuracyChange(val) end
end)

UI:AddToggle(sParryL, "Random Target", isTrue(_G.config.random_target), function(v)
    _G.config.random_target = v
    if getgenv().OnRandomTargetToggle then getgenv().OnRandomTargetToggle(v) end
end)

UI:AddToggle(sParryL, "Auto Adaptive Accuracy", isTrue(_G.config.auto_adaptive), function(v)
    _G.config.auto_adaptive = v
    if getgenv().OnAdaptiveToggle then getgenv().OnAdaptiveToggle(v) end
end)

local _adaptModeIdx = 1
if tostring(_G.config.adaptive_mode or "Accuracy Only") == "Accuracy + Range" then _adaptModeIdx = 2 end
UI:AddDropdown(sParryL, "Adaptive Mode", {"Accuracy Only", "Accuracy + Range"}, _adaptModeIdx, function(idx, val)
    _G.config.adaptive_mode = val
    getgenv()._adaptiveMode = val
    getgenv()._adaptiveRangeSmooth = tonumber(_G.config.parry_range) or 2
    pcall(function() UI:Notify("Adaptive Mode", val, "info") end)
end)
getgenv()._adaptiveMode = tostring(_G.config.adaptive_mode or "Accuracy Only")

UI:AddSlider(sParryL, "Parry Range", 0, 10, tonumber(_G.config.parry_range) or 2, 0, function(v)
    _G.config.parry_range = v
    getgenv().ParryRange = v
end)
getgenv().ParryRange = tonumber(_G.config.parry_range) or 2

local sCombatL = UI:CreateSection("Main", "Curve Settings", "Parry curves", true, "Left", "activity")
local curves = {"camera","random","accelerated","backwards","slow","high","normal","speed","down","left","right","dot","slowball","fastball","straight","high right","high left"}
local curveIdx = 1
for i, v in ipairs(curves) do if v == (_G.config.curve_method or "camera") then curveIdx = i end end

UI:AddDropdown(sCombatL, "Curve Method", curves, curveIdx, function(idx, val)
    _G.config.curve_method = val
    if getgenv().OnCurveChange then getgenv().OnCurveChange(val) end
end)
UI:AddToggle(sCombatL, "Random Curve", isTrue(_G.config.random_curve), function(v)
    _G.config.random_curve = v
    getgenv().RandomCurveEnabled = v
end)
local _rcTypeIdx = 1
local _rcTypeSaved = tostring(_G.config.random_curve_type or "random")
if _rcTypeSaved == "pro player" then _rcTypeIdx = 2
elseif _rcTypeSaved == "pro player classic" then _rcTypeIdx = 3 end
UI:AddDropdown(sCombatL, "Random Curve Type", {"random", "pro player", "pro player classic"}, _rcTypeIdx, function(idx, val)
    _G.config.random_curve_type = val
    getgenv().RandomCurveType = val
end)
UI:AddToggle(sCombatL, "Hotkey Curve", isTrue(_G.config.curve_keybind), function(v) _G.config.curve_keybind = v end)
UI:AddToggle(sCombatL, "Hotkey Notify", isTrue(_G.config.curve_notify), function(v) _G.config.curve_notify = v end)

UI:AddToggle(sCombatL, "Legit Screen Motion", isTrue(_G.config.legit_screen_movement), function(v)
    _G.config.legit_screen_movement = v
    if getgenv().SetLegitScreenMovement then pcall(getgenv().SetLegitScreenMovement, v) end
end)
UI:AddSlider(sCombatL, "Cam Max Angle", 10, 180, tonumber(_G.config.legit_cam_angle) or 55, 0, function(v)
    _G.config.legit_cam_angle = v
    getgenv()._legitCamAngle = v
end)
UI:AddSlider(sCombatL, "Cam Jitter", 0, 30, tonumber(_G.config.legit_cam_jitter) or 2, 1, function(v)
    _G.config.legit_cam_jitter = v
    getgenv()._legitCamJitter = v
end)
UI:AddSlider(sCombatL, "Cam Cooldown", 0, 3000, tonumber(_G.config.legit_cam_cooldown) or 200, 0, function(v)
    _G.config.legit_cam_cooldown = v
    getgenv()._legitCamCooldown = v
end)
UI:AddSlider(sCombatL, "Cam Speed", 0.1, 10, tonumber(_G.config.legit_cam_speed) or 1.0, 1, function(v)
    _G.config.legit_cam_speed = v
    getgenv()._legitCamSpeed = v
end)

local sCombatR = UI:CreateSection("Main", "Trigger & Spam", "Auto fire logic", true, "Right", "crosshair")

getgenv()._triggerbotKeybind = {
    SetValue = function(_, val)
        _G.triggerbot = val
        if getgenv().OnTriggerbotToggle then getgenv().OnTriggerbotToggle(val) end
    end
}
UI:AddToggle(sCombatR, "Triggerbot", false, function(v)
    getgenv()._triggerbotKeybind:SetValue(v)
end)
UI:AddKeybind(sCombatR, "Triggerbot Key", Enum.KeyCode.T, function()
    getgenv()._triggerbotKeybind:SetValue(not _G.triggerbot)
end)

UI:AddToggle(sCombatR, "Auto Spam", isTrue(_G.config.auto_spam), function(v)
    _G.config.auto_spam = v
    if getgenv().OnAutoSpamToggle then getgenv().OnAutoSpamToggle(v) end
end)

UI:AddSlider(sCombatR, "Spam Threshold", 1, 3, tonumber(_G.config.spam_threshold) or 3, 0, function(v)
    _G.config.spam_threshold = v
end)

getgenv()._manualSpamKeybind = {
    SetValue = function(_, val)
        _G.manual_spam = val
        if getgenv().OnManualSpamToggle then getgenv().OnManualSpamToggle(val) end
    end
}
UI:AddToggle(sCombatR, "Manual Spam", isTrue(_G.config.manual_spam), function(v)
    getgenv()._manualSpamKeybind:SetValue(v)
end)
UI:AddKeybind(sCombatR, "Manual Spam Key", Enum.KeyCode.E, function()
    getgenv()._manualSpamKeybind:SetValue(not _G.manual_spam)
end)

UI:AddSlider(sCombatR, "Manual Min Speed", 0, 50, tonumber(_G.config.manual_spam_min_speed) or 5, 0, function(v) _G.config.manual_spam_min_speed = v end)
UI:AddSlider(sCombatR, "Manual Spam CPS", 1, 2000, tonumber(_G.config.m_ManualSpamCPS) or 500, 0, function(v) _G.config.m_ManualSpamCPS = v end)
UI:AddToggle(sCombatR, "Manual CPS Mode", _G.config.m_ManualSpamCPSMode ~= false, function(v) _G.config.m_ManualSpamCPSMode = v end)
UI:AddToggle(sCombatR, "Animation Fix", _G.config.m_ManualSpamAnimationFix == true, function(v) _G.config.m_ManualSpamAnimationFix = v end)
UI:AddToggle(sCombatR, "Spam Boost", _G.config.m_ManualSpamBoost == true, function(v) getgenv().SpamBoost = v; _G.config.m_ManualSpamBoost = v end)
UI:AddToggle(sCombatR, "Manual Notify", isTrue(_G.config.manual_notify), function(v) _G.config.manual_notify = v end)
UI:AddToggle(sCombatR, "Floating Trigger", isTrue(_G.config.floating_trigger_button), function(v)
    _G.config.floating_trigger_button = v
    if getgenv().OnFloatingTriggerToggle then pcall(getgenv().OnFloatingTriggerToggle, v) end
end)
UI:AddToggle(sCombatR, "Floating Spam", isTrue(_G.config.floating_spam_button), function(v)
    _G.config.floating_spam_button = v
    if getgenv().OnFloatingSpamToggle then pcall(getgenv().OnFloatingSpamToggle, v) end
end)

local sPreL = UI:CreateSection("Main", "Grief Pre Click", "Auto click grief target", true, "Left", "mouse-pointer")
local _gpcModeIdx = 1
if tostring(_G.config.grief_mode or "Keybind") == "Near" then _gpcModeIdx = 2 end

UI:AddToggle(sPreL, "Grief Pre Click", isTrue(_G.config.grief_enabled), function(v)
    _G.config.grief_enabled = v
    if getgenv().GPC then
        getgenv().GPC.enabled = v
        if v then getgenv().GPC:Start() else getgenv().GPC:Stop() end
    end
end)
UI:AddDropdown(sPreL, "Grief Mode", {"Keybind", "Near"}, _gpcModeIdx, function(idx, val)
    _G.config.grief_mode = val
    if getgenv().GPC then getgenv().GPC.mode = val end
end)
UI:AddSlider(sPreL, "Grief Chance", 0, 100, tonumber(_G.config.grief_chance) or 40, 0, function(v)
    _G.config.grief_chance = v
    if getgenv().GPC then getgenv().GPC.chance = v end
end)
UI:AddSlider(sPreL, "Follow Range", 10, 80, tonumber(_G.config.grief_prox_range) or 25, 0, function(v)
    _G.config.grief_prox_range = v
    if getgenv().GPC then getgenv().GPC.proxRange = v end
end)
UI:AddSlider(sPreL, "Ball Trigger Range", 8, 50, tonumber(_G.config.grief_ball_range) or 22, 0, function(v)
    _G.config.grief_ball_range = v
    if getgenv().GPC then getgenv().GPC.ballRange = v end
end)

local sPreR = UI:CreateSection("Main", "Auto Pre Click", "Post-fastball logic", true, "Right", "zap")
UI:AddToggle(sPreR, "Auto Pre Click", isTrue(_G.config.auto_pre_click), function(v)
    _G.config.auto_pre_click = v
    if getgenv().AutoPreClick then getgenv().AutoPreClick.enabled = v end
end)

local sAbil = UI:CreateSection("Main", "Exploits", "No cooldown & Auto ability", true, "Left", "zap")
UI:AddToggle(sAbil, "Ability Exploit", isTrue(_G.config.m_AbilityExploitToggle), function(v) getgenv().AbilityExploit = v; if getgenv().OnAbilMaster then getgenv().OnAbilMaster(v) end end)
UI:AddToggle(sAbil, "Thunder Dash", isTrue(_G.config.m_ThunderDashToggle), function(v) getgenv().ThunderDashNoCooldown = v end)
UI:AddToggle(sAbil, "Super Jump", isTrue(_G.config.m_SuperJumpToggle), function(v) getgenv().SuperJumpNoCooldown = v end)
UI:AddToggle(sAbil, "Dash", isTrue(_G.config.m_DashNoCooldownToggle), function(v) getgenv().DashNoCooldown = v end)
UI:AddToggle(sAbil, "Cooldown Protection", isTrue(_G.config.m_CooldownProtectionToggle), function(v) getgenv().CooldownProtection = v end)

local sAbil2 = UI:CreateSection("Main", "Auto Ability", "Auto fire on close ball", true, "Right", "target")
UI:AddToggle(sAbil2, "Auto Ability", false, function(v) getgenv().AutoAbility = v end)
UI:AddSlider(sAbil2, "Ability Range", 8, 60, 20, 0, function(v) getgenv().AutoAbilityRange = v end)
UI:AddSlider(sAbil2, "Ability Min Speed", 0, 500, 100, 0, function(v) getgenv().AutoAbilityMinSpeed = v end)

-- ========================================
-- UI BUILDING (VISUALS - MERGED: Sword & ESP + Audio & FX)
-- ========================================
local sVis1 = UI:CreateSection("Visuals", "Sword Changer", "Skins and unlocker", true, "Left", "sword")
UI:AddToggle(sVis1, "Skin Changer", isTrue(_G.config.skin_changer), function(v)
    getgenv().skinChanger = v; getgenv().skinChangerEnabled = v; _G.config.skin_changer = v
    if v and getgenv().swordModel ~= "" and getgenv().updateSword then pcall(getgenv().updateSword) end
end)
UI:AddTextbox(sVis1, "Sword Name", "Enter sword name...", function(txt)
    getgenv().swordModel = txt; getgenv().swordAnimations = txt; getgenv().swordFX = txt
    if getgenv().skinChanger and txt ~= "" and getgenv().updateSword then pcall(getgenv().updateSword) end
end)
UI:AddToggle(sVis1, "Save Last Sword", true, function(v) getgenv().autoLoadLastSword = v end)
UI:AddToggle(sVis1, "Unlock All", isTrue(_G.config.unlock_all), function(v)
    _G.config.unlock_all = v; if getgenv().UnlockAll then pcall(function() getgenv().UnlockAll:set_enabled(v) end) end
end)

local sVis2 = UI:CreateSection("Visuals", "ESP & Debug", "Ability ESP & stats", true, "Right", "eye")
UI:AddToggle(sVis2, "Ability ESP", isTrue(_G.config.ability_esp), function(v)
    _G.config.ability_esp = v
    if getgenv().AbilityESP_API then
        if v then getgenv().AbilityESP_API.Start() else getgenv().AbilityESP_API.Stop() end
    end
end)
UI:AddToggle(sVis2, "Ball Stats", isTrue(_G.config.ball_debug), function(v)
    _G.config.ball_debug = v
    if getgenv().OnBallStatsToggle then getgenv().OnBallStatsToggle(v) end
end)
UI:AddToggle(sVis2, "Show Real Ping", isTrue(_G.config.show_ping), function(v)
    _G.config.show_ping = v
    if getgenv().OnPingToggle then getgenv().OnPingToggle(v) end
end)

local sAud1 = UI:CreateSection("Visuals", "Audio", "Sounds & Music", true, "Left", "volume-2")
UI:AddToggle(sAud1, "Hit Sound", true, function(v) getgenv().HitSoundEnabled = v end)
UI:AddDropdown(sAud1, "Sound Type", {"Medal","Fatality","Skeet","Switches","Rust Headshot","Neverlose Sound","Bubble","Laser","Steve","Call of Duty","Bat","TF2 Critical","Saber","Bameware"}, 10, function(idx, val) if getgenv().ChangeHitSound then getgenv().ChangeHitSound(val) end end)
UI:AddToggle(sAud1, "Background Music", false, function(v) if getgenv().ToggleMusic then getgenv().ToggleMusic(v) end end)
UI:AddDropdown(sAud1, "Music Track", {"Eeyuh","Sweep","Bounce","Everybody Wants To Rule The World","Missing Money","Sour Grapes","Erwachen","Grasp the Light","Beyond the Shadows","Rise to the Horizon","Echoes of the Candy Kingdom","Speed","Lo-fi Chill A","Lo-fi Ambient","Tears in the Rain"}, 1, function(idx, val) if getgenv().ChangeMusic then getgenv().ChangeMusic(val) end end)
UI:AddSlider(sAud1, "Hit Volume", 0, 20, tonumber(_G.config.hit_sound_volume) or 6, 0, function(v) _G.config.hit_sound_volume = v; if getgenv().ChangeHitVolume then getgenv().ChangeHitVolume(v) end end)
UI:AddSlider(sAud1, "Music Volume", 0, 10, tonumber(_G.config.music_volume) or 3, 1, function(v) _G.config.music_volume = v; if getgenv().ChangeMusicVolume then getgenv().ChangeMusicVolume(v) end end)
UI:AddToggle(sAud1, "Music Loop", _G.config.music_loop == true, function(v) _G.config.music_loop = v; if getgenv().ToggleMusicLoop then getgenv().ToggleMusicLoop(v) end end)
UI:AddToggle(sAud1, "Atmosphere", _G.config.atmosphere_enabled ~= false, function(v) _G.config.atmosphere_enabled = v; if getgenv().ToggleAtmosphere then getgenv().ToggleAtmosphere(v) end end)
UI:AddSlider(sAud1, "Atmosphere Density", 0, 1, tonumber(_G.config.atmosphere_density) or 0.3, 2, function(v) _G.config.atmosphere_density = v; if getgenv().ChangeAtmosphereDensity then getgenv().ChangeAtmosphereDensity(v) end end)

local sAud2 = UI:CreateSection("Visuals", "Color & Effects", "Visual tuning", true, "Right", "palette")
UI:AddSlider(sAud2, "Brightness", -1, 1, tonumber(_G.config.brightness) or 0, 2, function(v)
    _G.config.brightness = v; if getgenv().ApplyColorCorrection then getgenv().ApplyColorCorrection() end
end)
UI:AddSlider(sAud2, "Contrast", -1, 1, tonumber(_G.config.contrast) or 0, 2, function(v)
    _G.config.contrast = v; if getgenv().ApplyColorCorrection then getgenv().ApplyColorCorrection() end
end)

-- ========================================
-- UI BUILDING (DETECTIONS - MERGED: Basic + Advanced)
-- ========================================
local sFX = UI:CreateSection("Visuals", "Ball FX", "Indicator, trail, slash, shield", true, "Right", "zap")

UI:AddToggle(sFX, "Ball Indicator", isTrue(_G.config.ball_indicator), function(v)
    _G.config.ball_indicator = v
    if getgenv().OnBallIndicatorToggle then pcall(getgenv().OnBallIndicatorToggle, v) end
end)
local _biHex = type(_G.config.ball_indicator_color) == "string" and _G.config.ball_indicator_color or "#FFFFFF"
local _biColor = _parseHexColor(_biHex) or Color3.fromRGB(255, 255, 255)
UI:AddColorPicker(sFX, "Indicator Color", _biColor, function(a, b)
    local c = typeof(a) == "Color3" and a or b
    if typeof(c) ~= "Color3" then return end
    _G.config.ball_indicator_color = _c3tohex(c)
    if getgenv().OnBallIndicatorColorChange then pcall(getgenv().OnBallIndicatorColorChange, c) end
end)
UI:AddToggle(sFX, "Ball Trail", isTrue(_G.config.ball_trail), function(v)
    _G.config.ball_trail = v
    if getgenv().OnBallTrailToggle then pcall(getgenv().OnBallTrailToggle, v) end
end)
local _btHex = type(_G.config.ball_trail_color) == "string" and _G.config.ball_trail_color or "#00FFFF"
local _btColor = _parseHexColor(_btHex) or Color3.fromRGB(0, 255, 255)
UI:AddColorPicker(sFX, "Trail Color", _btColor, function(a, b)
    local c = typeof(a) == "Color3" and a or b
    if typeof(c) ~= "Color3" then return end
    _G.config.ball_trail_color = _c3tohex(c)
    if getgenv().OnBallTrailColorChange then pcall(getgenv().OnBallTrailColorChange, c) end
end)
UI:AddSlider(sFX, "Ball Trail Count", 1, 20, tonumber(_G.config.ball_trail_count) or 8, 0, function(v)
    _G.config.ball_trail_count = v
    if getgenv().OnBallTrailCountChange then pcall(getgenv().OnBallTrailCountChange, v) end
end)
UI:AddToggle(sFX, "Slash Changer", isTrue(_G.config.slash_changer), function(v)
    _G.config.slash_changer = v
    if getgenv().OnSlashChangerToggle then pcall(getgenv().OnSlashChangerToggle, v) end
end)
local _slHex = type(_G.config.slash_color) == "string" and _G.config.slash_color or "#FF0000"
local _slColor = _parseHexColor(_slHex) or Color3.fromRGB(255, 0, 0)
UI:AddColorPicker(sFX, "Slash Color", _slColor, function(a, b)
    local c = typeof(a) == "Color3" and a or b
    if typeof(c) ~= "Color3" then return end
    _G.config.slash_color = _c3tohex(c)
    if getgenv().OnSlashChangerColor then pcall(getgenv().OnSlashChangerColor, c) end
end)
UI:AddToggle(sFX, "Shield Changer", isTrue(_G.config.shield_changer), function(v)
    _G.config.shield_changer = v
    if getgenv().OnShieldChangerToggle then pcall(getgenv().OnShieldChangerToggle, v) end
end)
local _shHex = type(_G.config.shield_color) == "string" and _G.config.shield_color or "#FF0000"
local _shColor = _parseHexColor(_shHex) or Color3.fromRGB(255, 0, 0)
UI:AddColorPicker(sFX, "Shield Color", _shColor, function(a, b)
    local c = typeof(a) == "Color3" and a or b
    if typeof(c) ~= "Color3" then return end
    _G.config.shield_color = _c3tohex(c)
    if getgenv().OnShieldChangerColor then pcall(getgenv().OnShieldChangerColor, c) end
end)
local sPlush = UI:CreateSection("Visuals", "Plushies", "Companion plushies", true, "Left", "star")

UI:AddToggle(sPlush, "Plushies", isTrue(_G.config.plushies), function(v)
    _G.config.plushies = v
    if getgenv().OnPlushiesToggle then pcall(getgenv().OnPlushiesToggle, v) end
end)
local _plushSet = {}
if type(_G.config.plushies_types) == "string" then
    for name in _G.config.plushies_types:gmatch("[^,]+") do
        local trimmed = name:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then _plushSet[trimmed] = true end
    end
end
local function _plushToggle(name)
    return function(v)
        if v then _plushSet[name] = true else _plushSet[name] = nil end
        local parts = {}
        for k in pairs(_plushSet) do table.insert(parts, k) end
        table.sort(parts)
        _G.config.plushies_types = table.concat(parts, ",")
        if getgenv().OnPlushiesTypesChange then pcall(getgenv().OnPlushiesTypesChange, _G.config.plushies_types) end
    end
end
UI:AddToggle(sPlush, "Reimu", _plushSet.Reimu == true, _plushToggle("Reimu"))
UI:AddToggle(sPlush, "Youmou", _plushSet.Youmou == true, _plushToggle("Youmou"))
UI:AddToggle(sPlush, "Shion", _plushSet.Shion == true, _plushToggle("Shion"))
UI:AddToggle(sPlush, "Yuuka", _plushSet.Yuuka == true, _plushToggle("Yuuka"))
UI:AddToggle(sPlush, "Flandre", _plushSet.Flandre == true, _plushToggle("Flandre"))
UI:AddToggle(sPlush, "Ayanami", _plushSet.Ayanami == true, _plushToggle("Ayanami"))
UI:AddToggle(sPlush, "Padoru", _plushSet.Padoru == true, _plushToggle("Padoru"))
local sImmortal = UI:CreateSection("Visuals", "Immortal", "Desync orbit", true, "Left", "shield")

UI:AddToggle(sImmortal, "Immortal", isTrue(_G.config.daemons_immortal), function(v)
    _G.config.daemons_immortal = v
    if getgenv().OnImmortalToggle then pcall(getgenv().OnImmortalToggle, v) end
end)

local sDetL = UI:CreateSection("Detections", "Detections", "Game ability detections", true, "Left", "shield")
UI:AddToggle(sDetL, "Infinity Detection", false, function(v) _G.Detect.infinity = v end)
UI:AddToggle(sDetL, "Death Slash Detection", false, function(v) _G.Detect.deathslash = v end)
UI:AddToggle(sDetL, "Time Hole Detection", false, function(v) _G.Detect.timehole = v end)
UI:AddToggle(sDetL, "Slashes of Fury", false, function(v) _G.Detect.slashesoffury = v end)
UI:AddToggle(sDetL, "Forcefield Detection", false, function(v) _G.Detect.forcefield = v end)
UI:AddToggle(sDetL, "Singularity Detection", false, function(v) _G.Detect.singularity = v end)

local sDetR = UI:CreateSection("Detections", "Counters", "Reactive modules", true, "Right", "shield-check")
UI:AddToggle(sDetR, "Anti Phantom", isTrue(_G.config.anti_phantom), function(v) _G.config.anti_phantom = v; if getgenv().OnAntiPhantomToggle then getgenv().OnAntiPhantomToggle(v) end end)
UI:AddToggle(sDetR, "Anti Blindness", false, function(v) if _G.Quasar then _G.Quasar.antiBlindness = v end end)
UI:AddToggle(sDetR, "Anti Disorientate", false, function(v) if _G.Quasar then _G.Quasar.antiDisorientate = v end end)
UI:AddToggle(sDetR, "Auto Rematch", false, function(v) if getgenv().SetAutoRematch then getgenv().SetAutoRematch(v) end end)
UI:AddToggle(sDetR, "Staff Detection", isTrue(_G.config.det_staff), function(v)
    _G.config.det_staff = v
    if getgenv().SetStaffDetection then pcall(getgenv().SetStaffDetection, v) end
end)
local _staffActionIdx = 1
if tostring(_G.config.det_staff_action or "Notification") == "Kick" then _staffActionIdx = 2 end
UI:AddDropdown(sDetR, "Staff Action", {"Notification", "Kick"}, _staffActionIdx, function(idx, val)
    _G.config.det_staff_action = val
    getgenv()._staffAction = val
end)

local sSpoofR = UI:CreateSection("Detections", "Spoofers", "Value & device spoofers", true, "Right", "eye-off")

UI:AddToggle(sSpoofR, "Winstreak Spoofer", isTrue(_G.config.winstreak_spoofer), function(v)
    _G.config.winstreak_spoofer = v
    if getgenv().OnWinstreakSpooferToggle then pcall(getgenv().OnWinstreakSpooferToggle, v) end
end)
UI:AddTextbox(sSpoofR, "Winstreak Value", tostring(_G.config.v_WinstreakValue or 100), function(txt)
    _G.config.v_WinstreakValue = tonumber(txt) or 100
    if getgenv().OnWinstreakValueChange then pcall(getgenv().OnWinstreakValueChange, _G.config.v_WinstreakValue) end
end)
UI:AddToggle(sSpoofR, "ELO Spoofer", isTrue(_G.config.elo_spoofer), function(v)
    _G.config.elo_spoofer = v
    if getgenv().OnEloSpooferToggle then pcall(getgenv().OnEloSpooferToggle, v) end
end)
UI:AddTextbox(sSpoofR, "ELO Value", tostring(_G.config.elo_value or 8000), function(txt)
    _G.config.elo_value = tonumber(txt) or 8000
    if getgenv().OnEloValueChange then pcall(getgenv().OnEloValueChange, _G.config.elo_value) end
end)
UI:AddToggle(sSpoofR, "Currency Spoofer", isTrue(_G.config.currency_spoofer), function(v)
    _G.config.currency_spoofer = v
    if getgenv().OnCurrencySpooferToggle then pcall(getgenv().OnCurrencySpooferToggle, v) end
end)
UI:AddTextbox(sSpoofR, "Currency Value", tostring(_G.config.currency_value or 999999), function(txt)
    _G.config.currency_value = tonumber(txt) or 999999
    if getgenv().OnCurrencyValueChange then pcall(getgenv().OnCurrencyValueChange, _G.config.currency_value) end
end)
UI:AddTextbox(sSpoofR, "Token Value", tostring(_G.config.token_value or 999999), function(txt)
    _G.config.token_value = tonumber(txt) or 999999
    if getgenv().OnTokenValueChange then pcall(getgenv().OnTokenValueChange, _G.config.token_value) end
end)

local _devTypes = {"PC", "Mobile", "Console"}
local _devIdx = 1
local _savedDev = tostring(_G.config.device_spoof_type or "PC")
for i, name in ipairs(_devTypes) do if name == _savedDev then _devIdx = i end end
UI:AddDropdown(sSpoofR, "Device Type", _devTypes, _devIdx, function(idx, val)
    _G.config.device_spoof_type = val
    if getgenv().OnDeviceSpoofTypeChange then pcall(getgenv().OnDeviceSpoofTypeChange, val) end
end)
UI:AddButton(sSpoofR, "Apply Device & Rejoin", function()
    if getgenv().ApplyDeviceSpoof then pcall(getgenv().ApplyDeviceSpoof) end
end)

local sAdv = UI:CreateSection("Detections", "Adv Detections", "Status trackers", true, "Left", "radar")
UI:AddToggle(sAdv, "Dribble", false, function(v) _G.AdvDetect.Dribble = v end)
UI:AddToggle(sAdv, "Pull", false, function(v) _G.AdvDetect.Pull = v end)
UI:AddToggle(sAdv, "Pulse", false, function(v) _G.AdvDetect.Pulse = v end)
UI:AddToggle(sAdv, "Tornado", false, function(v) _G.AdvDetect.Tornado = v end)
UI:AddToggle(sAdv, "Hell Hook", false, function(v) _G.AdvDetect.HellHook = v end)
UI:AddToggle(sAdv, "Respect Detections in Auto", false, function(v) getgenv()._advWiringEnabled = v end)

-- ========================================
-- UI BUILDING (AUTO PLAY - MERGED: Movement)
-- ========================================
local sApL = UI:CreateSection("Auto Play", "Auto Play", "Human-like movement", true, "Left", "move")
UI:AddToggle(sApL, "Auto Play", false, function(v) if getgenv().AutoPlay then getgenv().AutoPlay.Enable(v) end end)
UI:AddSlider(sApL, "Distance", 5, 60, 18, 0, function(v) getgenv().AutoPlayDistance = v end)
UI:AddSlider(sApL, "Speed Scale", 10, 200, 45, 0, function(v) getgenv().AutoPlayMultiplierThreshold = v end)
UI:AddSlider(sApL, "Transversing", 0, 30, 6, 1, function(v) getgenv().AutoPlayTransversing = v end)
UI:AddDropdown(sApL, "Direction", {"behind ball", "in front of ball"}, 1, function(idx, val) getgenv().AutoPlayDirection = (val == "in front of ball") and -1 or 1 end)

local sApR = UI:CreateSection("Auto Play", "Jumping & Utility", "Jump logic", true, "Right", "arrow-up")
UI:AddToggle(sApR, "Jumping", true, function(v) getgenv().AutoPlayJumpingEnabled = v end)
UI:AddSlider(sApR, "Jump Chance", 0, 100, 15, 0, function(v) getgenv().AutoPlayJumpPercentage = v end)
UI:AddSlider(sApR, "Double Jump Chance", 0, 100, 8, 0, function(v) getgenv().AutoPlayDoubleJumpPercentage = v end)
UI:AddSlider(sApR, "Jump Cooldown", 0.3, 5, 1.0, 1, function(v) getgenv().AutoPlayJumpCooldown = v end)
UI:AddToggle(sApR, "Anti AFK", false, function(v) if getgenv().AutoPlay then getgenv().AutoPlay.SetAntiAFK(v) end end)

-- ========================================
-- UI BUILDING (FFLAGS - MERGED: Profiles)
-- ========================================
local sFfL = UI:CreateSection("FFlags", "Profile Manager", "Save/Load FFlags", true, "Left", "save")
UI:AddTextbox(sFfL, "Profile Name", "default", function(v) _G.config.fflag_profile = v end)
UI:AddToggle(sFfL, "Auto Load", isTrue(_G.config.fflag_auto_load), function(v) _G.config.fflag_auto_load = v end)
UI:AddButton(sFfL, "Save Profile", function() if getgenv().FFlagSave then getgenv().FFlagSave(_G.config.fflag_profile) end end)
UI:AddButton(sFfL, "Load Profile", function() if getgenv().FFlagLoad then getgenv().FFlagLoad(_G.config.fflag_profile) end end)

local sFfR = UI:CreateSection("FFlags", "JSON Editor", "Manual JSON injection", true, "Right", "code")
UI:AddTextbox(sFfR, "FFlags JSON", '{"FFlagName":"value"}', function(v) _G.config.fflag_json = v end)
UI:AddButton(sFfR, "Apply JSON", function() if getgenv().FFlagApply then getgenv().FFlagApply(_G.config.fflag_json) end end)

-- ========================================
-- UI BUILDING (UTILITY - MERGED: Hide & Misc + Avatar + Theme)
-- ========================================
local sUtilL = UI:CreateSection("Utility", "Hide Effects", "Visual clutter removal", true, "Left", "eye-off")
UI:AddToggle(sUtilL, "Hide All", false, function(v) if getgenv().HideAll then getgenv().HideAll(v) end end)
UI:AddToggle(sUtilL, "Hide Accessories", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideAcc", v) end end)
UI:AddToggle(sUtilL, "Hide Clothes", true, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideClo", v) end end)
UI:AddToggle(sUtilL, "Hide Nametag", true, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideName", v) end end)
UI:AddToggle(sUtilL, "Hide Animations", true, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideAnim", v) end end)
UI:AddToggle(sUtilL, "Hide Particles", true, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideParticles", v) end end)
UI:AddToggle(sUtilL, "Hide BillboardGui", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideBill", v) end end)
UI:AddToggle(sUtilL, "Hide SurfaceGui", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideSurf", v) end end)
UI:AddToggle(sUtilL, "Hide Decals", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideDec", v) end end)
UI:AddToggle(sUtilL, "Hide Beams & Trails", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideBeams", v) end end)
UI:AddToggle(sUtilL, "Hide Lights", false, function(v) if getgenv().SetHideState then getgenv().SetHideState("hideLights", v) end end)
UI:AddToggle(sUtilL, "Hide All FX", false, function(v) if getgenv().HideAllEffects then getgenv().HideAllEffects(v) end end)

local sUtilR = UI:CreateSection("Utility", "Movement & Camera", "Speed, Jump, FOV", true, "Right", "settings")
UI:AddToggle(sUtilR, "Speed & Jump", true, function(v) if getgenv().ToggleSpeedJump then getgenv().ToggleSpeedJump(v) end end)
UI:AddSlider(sUtilR, "WalkSpeed", 16, 400, 44, 0, function(v) getgenv().WalkSpeed = v end)
UI:AddSlider(sUtilR, "JumpPower", 50, 450, 50, 0, function(v) getgenv().JumpPower = v end)
UI:AddToggle(sUtilR, "FOV Changer", false, function(v) if getgenv().ToggleFOV then getgenv().ToggleFOV(v) end end)
UI:AddSlider(sUtilR, "FOV", 40, 120, 120, 0, function(v) getgenv().FOVValue = v end)
UI:AddToggle(sUtilR, "Gravity", false, function(v) if getgenv().ToggleGravity then getgenv().ToggleGravity(v) end end)
UI:AddSlider(sUtilR, "Gravity Value", 0, 500, 100, 0, function(v) getgenv().GravityValue = v end)

local sAva = UI:CreateSection("Utility", "Avatar Changer", "Copy appearances", true, "Left", "user")
UI:AddToggle(sAva, "Avatar Changer", isTrue(_G.config.avatar_changer), function(v) _G.config.avatar_changer = v; if getgenv()._daemonAvatarChanger then getgenv()._daemonAvatarChanger.set(v, _G.config.avatar_name or "") end end)
UI:AddTextbox(sAva, "Target User/ID", "Username or UserId...", function(txt) _G.config.avatar_name = txt; if _G.config.avatar_changer and getgenv()._daemonAvatarChanger then getgenv()._daemonAvatarChanger.apply(txt) end end)
UI:AddToggle(sAva, "Headless", isTrue(_G.config.headless_enabled), function(v) _G.config.headless_enabled = v; if LocalPlayer.Character and _G._daemonHeadless then if v then pcall(_G._daemonHeadless, LocalPlayer.Character) else pcall(_G._daemonRestoreHead, LocalPlayer.Character) end end end)
UI:AddToggle(sAva, "Korblox", isTrue(_G.config.korblox_enabled), function(v) _G.config.korblox_enabled = v; if LocalPlayer.Character and _G._daemonKorblox then if v then pcall(_G._daemonKorblox, LocalPlayer.Character) else pcall(_G._daemonRestoreLeg, LocalPlayer.Character) end end end)

UI:CreateThemeCustomizer("Utility")

-- ============================================================
-- [1] CORE STATE
-- ============================================================
local Connections = {}

local BallHelper = {}
BallHelper.ball = {
    properties = {
        aerodynamic_time = tick(),
        last_warping = tick(),
        lerp_radians = 0,
        curving = tick(),
    }
}

local CurrentAnimTrack
local CurrentTarget

-- ============================================================
-- [2] REMOTE DETECTION + SIGNAL FALLBACK
-- ============================================================
local replicated_storage = ReplicatedStorage
local _token
if getgc and debug and debug.info and debug.getupvalues then
    for _, Function in getgc(true) do
        if type(Function) ~= "function" or not debug.info(Function, "s"):find("PRY", 1, true) then
            continue
        end
        for _, value in debug.getupvalues(Function) do
            if type(value) == "function" then _token = value; break end
        end
        if _token then break end
    end
end

local function _tokenize(_remote_uid)
    if type(_token) ~= "function" or type(_remote_uid) ~= "string" then return nil end
    local time = tostring(math.floor(workspace:GetServerTimeNow() * 100))
    local key = _token(_remote_uid, "TIME")
    if type(key) ~= "string" or #key == 0 then return nil end
    local characters = table.create(#time)
    for index = 1, #time do
        characters[index] = string.char(bit32.bxor(
            (string.byte(time, index) + index) % 256,
            string.byte(key, (index - 1) % #key + 1)
        ))
    end
    return table.concat(characters)
end

local _reverted = {}
local _original = {}

local _remoteStatusGui = Instance.new("ScreenGui")
_remoteStatusGui.Name = "daemon_RemoteStatus"
_remoteStatusGui.ResetOnSpawn = false
_remoteStatusGui.IgnoreGuiInset = true
_remoteStatusGui.DisplayOrder = 9999
do
    local _parent = nil
    pcall(function() if gethui then _parent = gethui() end end)
    if not _parent then pcall(function() _parent = game:GetService("CoreGui") end) end
    if not _parent then _parent = LocalPlayer:WaitForChild("PlayerGui") end
    _remoteStatusGui.Parent = _parent
end

local _remoteStatusLabel = Instance.new("TextLabel")
_remoteStatusLabel.Size = UDim2.new(0, 440, 0, 22)
_remoteStatusLabel.Position = UDim2.new(0, 12, 1, -42)
_remoteStatusLabel.BackgroundTransparency = 1
_remoteStatusLabel.Font = Enum.Font.GothamMedium
_remoteStatusLabel.TextSize = 13
_remoteStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
_remoteStatusLabel.TextYAlignment = Enum.TextYAlignment.Center
_remoteStatusLabel.TextStrokeTransparency = 0.7
_remoteStatusLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
_remoteStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
_remoteStatusLabel.TextWrapped = false
_remoteStatusLabel.ClipsDescendants = true
_remoteStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
_remoteStatusLabel.Text = "signal: loading..."
_remoteStatusLabel.ZIndex = 9999
_remoteStatusLabel.Parent = _remoteStatusGui

local _remoteCapturedOnce = false
local function _setRemoteStatus(text, color)
    if not _remoteStatusLabel then return end
    _remoteStatusLabel.Text = text
    if color then _remoteStatusLabel.TextColor3 = color end
end

local function _is_valid(args)
    return #args == 8
        and type(args[2]) == "string" and type(args[3]) == "string"
        and type(args[4]) == "number" and typeof(args[5]) == "CFrame"
        and type(args[6]) == "table" and type(args[7]) == "table"
        and type(args[8]) == "boolean"
end

local function _hook(remote)
    if _reverted[remote] then return end
    local meta = getrawmetatable(remote)
    if not meta or _original[meta] then return end
    _original[meta] = true
    setreadonly(meta, false)
    local oldIndex = meta.__index
    meta.__index = function(self, key)
        if (key == "FireServer" and self:IsA("RemoteEvent"))
            or (key == "InvokeServer" and self:IsA("RemoteFunction")) then
            return function(_, ...)
                local arguments = { ... }
                if _is_valid(arguments) and not _reverted[self] then
                    _reverted[self] = arguments
                    _remoteCapturedOnce = true
                end
                return oldIndex(self, key)(_, table.unpack(arguments))
            end
        end
        return oldIndex(self, key)
    end
    setreadonly(meta, true)
end

if getrawmetatable and setreadonly then
    for _, remote in ipairs(replicated_storage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then _hook(remote) end
    end
end

task.wait(1)

local function getScrieieRemote()
    for remote, originalArgs in pairs(_reverted) do
        if remote and remote.Parent and remote:IsA("RemoteEvent") and type(originalArgs) == "table" then
            return remote, originalArgs
        end
    end
end

local _signalReady = false
local _signalObj = nil

task.spawn(function()
    pcall(function()
        local ctrl = ReplicatedStorage:FindFirstChild("Controllers")
        for _ = 1, 30 do
            if ctrl then break end
            task.wait(1)
            ctrl = ReplicatedStorage:FindFirstChild("Controllers")
        end
        if not ctrl then return end
        local targetCtrl = nil
        for _, c in ipairs(ctrl:GetChildren()) do
            if c.Name:find("SwordsController", 1, true) == 1 then targetCtrl = c; break end
        end
        if not targetCtrl then return end
        local pry = targetCtrl:FindFirstChild("PRY")
        if not pry then return end
        local ok, fn = pcall(require, pry)
        if not ok or type(fn) ~= "function" then return end
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        local sig = pkg and pkg:FindFirstChild("Signal")
        if not sig then return end
        local okSig, Signal = pcall(require, sig)
        if not okSig or not Signal or type(Signal.new) ~= "function" then return end
        local s = Signal.new()
        s:Connect(fn)
        _signalObj = s
        _signalReady = true
        pcall(function() _setRemoteStatus("signal: ready", Color3.fromRGB(120, 255, 140)) end)
    end)
end)

task.spawn(function()
    task.wait(35)
    if not _signalReady then
        pcall(function() _setRemoteStatus("signal: failed", Color3.fromRGB(255, 90, 90)) end)
    end
end)

-- ============================================================
-- [3] TARGET SELECTION
-- ============================================================
local recentlyPickedTargets = {}

local function pick_random_target()
    local livingPlayers = {}
    for _, char in workspace.Alive:GetChildren() do
        if char.Name ~= LocalPlayer.Name and char.PrimaryPart then
            table.insert(livingPlayers, char)
        end
    end
    if #livingPlayers == 0 then CurrentTarget = nil; return end
    if #livingPlayers == 1 then CurrentTarget = livingPlayers[1]; return end
    local candidates = {}
    for _, char in livingPlayers do
        if not recentlyPickedTargets[char.Name] then table.insert(candidates, char) end
    end
    if #candidates == 0 then
        recentlyPickedTargets = {}
        for _, char in livingPlayers do
            if not CurrentTarget or char.Name ~= CurrentTarget.Name then
                table.insert(candidates, char)
            end
        end
        if #candidates == 0 then candidates = livingPlayers end
    end
    local picked = candidates[math.random(1, #candidates)]
    recentlyPickedTargets[picked.Name] = true
    CurrentTarget = picked
end

workspace.Balls.ChildAdded:Connect(function(ball)
    if _G.config.random_target then pick_random_target() end
end)

workspace.Balls.ChildAdded:Connect(function(ball)
    task.spawn(function()
        if not ball:GetAttribute("realBall") then
            local zoomies = ball:WaitForChild("zoomies", 3)
            if not zoomies then return end
        end
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _G.config.random_target then pick_random_target() end
        end)
    end)
end)

for _, ball in workspace.Balls:GetChildren() do
    task.spawn(function()
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _G.config.random_target then pick_random_target() end
        end)
    end)
end

local function linear_predict(a, b, t) return a + (b - a) * t end

-- ============================================================
-- [4] BALL HELPER + CURVE
-- ============================================================
local function _isPlayerAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local alive = workspace:FindFirstChild("Alive")
    return alive ~= nil and alive:FindFirstChild(LocalPlayer.Name) ~= nil
end

function BallHelper.get_ball()
    for _, ball in workspace.Balls:GetChildren() do
        if ball:GetAttribute("realBall") then return ball end
    end
end

function BallHelper.get_balls()
    local balls = {}
    for _, ball in workspace.Balls:GetChildren() do
        if ball:GetAttribute("realBall") then table.insert(balls, ball) end
    end
    return balls
end

local _ballPositions = setmetatable({}, {__mode = "k"})
local _ballReplicator = nil
do
    local pkgs = ReplicatedStorage:FindFirstChild("Packages")
    local idx = pkgs and pkgs:FindFirstChild("_Index")
    local netPkg = idx and idx:FindFirstChild("sleitnick_net@0.1.0")
    local net = netPkg and netPkg:FindFirstChild("net")
    if net then
        for _, rem in ipairs(net:GetChildren()) do
            if rem:IsA("UnreliableRemoteEvent") and rem.Name ~= "URE/ReplicateBallPosition" then
                _ballReplicator = rem; break
            end
        end
    end
end
if _ballReplicator then
    _ballReplicator.OnClientEvent:Connect(function(ball, pos)
        if ball and ball.Parent == workspace.Balls and ball:GetAttribute("realBall") == true and typeof(pos) == "Vector3" then
            _ballPositions[ball] = pos
        end
    end)
end
function BallHelper.ball_position(ball)
    if not ball then return Vector3.zero end
    return _ballPositions[ball] or ball.Position
end

local function select_target_by_mouse()
    local livingPlayers = {}
    for _, char in workspace.Alive:GetChildren() do
        if char.Name ~= LocalPlayer.Name and char.PrimaryPart then
            table.insert(livingPlayers, char)
        end
    end
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    local rayDir = ray.Direction
    local bestTarget, bestDot = nil, -math.huge
    for _, char in livingPlayers do
        local toChar = (char.PrimaryPart.Position - camera.CFrame.Position).Unit
        local dot = rayDir:Dot(toChar)
        if dot > bestDot then bestDot = dot; bestTarget = char end
    end
    CurrentTarget = bestTarget
    return bestTarget
end

function BallHelper.closest_player_by_mouse()
    if _G.config.random_target then
        if not CurrentTarget then pick_random_target() end
        return CurrentTarget
    end
    return select_target_by_mouse()
end

getgenv()._CURVE_NAMES = {"camera","random","accelerated","backwards","slow","high","normal","speed","down","left","right","dot","slowball","fastball","straight","high right","high left"}
getgenv()._CURVE_INDEX = {}
for i, n in ipairs(getgenv()._CURVE_NAMES) do getgenv()._CURVE_INDEX[n] = i end
getgenv()._SelectedCurve = _G.config.curve_method or "camera"
if not getgenv()._CURVE_INDEX[getgenv()._SelectedCurve] then getgenv()._SelectedCurve = "camera" end
local _FRCurveCtx = {}

local _FRCurveFns = {
    [1]=function(ctx) return ctx.camera.CFrame end,
    [2]=function(ctx)
        local toTarget = -(ctx.target_pos - ctx.root.Position).Unit
        local right = ctx.camera.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)
        local side = math.random(0, 1) == 0 and -1 or 1
        local off = toTarget * math.random(7000, 12000)
            + right * (side * math.random(2000, 5000))
            + up * math.random(3000, 6000)
        return CFrame.new(ctx.root.Position, ctx.target_pos + off)
    end,
    [3]=function(ctx) return CFrame.new(ctx.root.Position, ctx.target_pos + Vector3.new(0, 5, 0)) end,
    [4]=function(ctx)
        local dir = (ctx.root.Position - ctx.target_pos).Unit
        return CFrame.new(ctx.camera.CFrame.Position, ctx.root.Position + dir * 10000 + Vector3.new(0, 1000, 0))
    end,
    [5]=function(ctx) return CFrame.new(ctx.root.Position, ctx.target_pos + Vector3.new(0, -9e18, 0)) end,
    [6]=function(ctx) return CFrame.new(ctx.root.Position, ctx.target_pos + Vector3.new(0, 9e18, 0)) end,
    [7]=function(ctx) return CFrame.new(ctx.root.Position, ctx.root.Position + ctx.root.CFrame.LookVector) end,
    [8]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position + ctx.camera.CFrame.UpVector * 5) end,
    [9]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position + ctx.camera.CFrame.UpVector * -9e9) end,
    [10]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position - ctx.camera.CFrame.RightVector * 9e9) end,
    [11]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position + ctx.camera.CFrame.RightVector * 9e9) end,
    [12]=function(ctx) return CFrame.lookAt(ctx.root.Position, ctx.target_pos) end,
    [13]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position + Vector3.new(0,-1,0)*99999) end,
    [14]=function(ctx) return CFrame.new(ctx.camera.CFrame.Position, ctx.camera.CFrame.Position + ctx.camera.CFrame.LookVector*10 + Vector3.new(0,7,0)) end,
    [15]=function(ctx)
        local best, bestDist = nil, math.huge
        local alive = workspace:FindFirstChild("Alive")
        if not alive then return ctx.camera.CFrame end
        local cursorPos = Vector2.new(ctx.camera.ViewportSize.X/2, ctx.camera.ViewportSize.Y/2)
        local ok, mouse = pcall(UserInputService.GetMouseLocation, UserInputService)
        if ok and mouse then cursorPos = Vector2.new(mouse.X, mouse.Y) end
        for _, e in ipairs(alive:GetChildren()) do
            if e ~= LocalPlayer.Character and e.PrimaryPart then
                local sp, on = ctx.camera:WorldToScreenPoint(e.PrimaryPart.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - cursorPos).Magnitude
                    if d < bestDist then bestDist = d; best = e end
                end
            end
        end
        if best then return CFrame.new(ctx.root.Position, best.PrimaryPart.Position) end
        return CFrame.new(ctx.root.Position, ctx.target_pos)
    end,
    [16]=function(ctx)
        local right = ctx.camera.CFrame.RightVector
        return CFrame.new(ctx.root.Position, ctx.target_pos + Vector3.new(0, 5e18, 0) + right * 5e18)
    end,
    [17]=function(ctx)
        local right = ctx.camera.CFrame.RightVector
        return CFrame.new(ctx.root.Position, ctx.target_pos + Vector3.new(0, 5e18, 0) - right * 5e18)
    end,
}

function BallHelper.getCurveCFrame()
    local camera = workspace.CurrentCamera
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return camera.CFrame end
    local target = CurrentTarget
    local targetPos = (target and target.PrimaryPart and target.PrimaryPart.Position)
        or (hrp.Position + camera.CFrame.LookVector * 1000)
    _FRCurveCtx.camera = camera
    _FRCurveCtx.root = hrp
    _FRCurveCtx.target_pos = targetPos
    local idx = getgenv()._CURVE_INDEX[getgenv()._SelectedCurve] or 1
    local fn = _FRCurveFns[idx] or _FRCurveFns[1]
    return fn(_FRCurveCtx)
end

getgenv()._pickRandomCurve = function()
    if not getgenv().RandomCurveEnabled then return end
    local pool
    local type_ = getgenv().RandomCurveType or "random"
    if type_ == "pro player" then
        local ballSpeed = 0
        pcall(function()
            local ball = BallHelper.get_ball()
            if ball then
                local z = ball:FindFirstChild("zoomies")
                if z then ballSpeed = z.VectorVelocity.Magnitude end
            end
        end)
        if ballSpeed < 200 then pool = {"fastball","speed","right","left","normal"}
        elseif ballSpeed < 350 then pool = {"fastball","speed","right","left","accelerated","high"}
        else pool = {"high","right","left","backwards","high right","high left"} end
    elseif type_ == "pro player classic" then
        pool = {"high","right","backwards","speed","accelerated","left","down"}
    else
        pool = getgenv()._CURVE_NAMES
    end
    getgenv()._SelectedCurve = pool[math.random(#pool)]
end

-- ============================================================
-- [5] PARRY ANIMATION + EXECUTION
-- ============================================================
local _animResolveCache = {}
local _animTrackCache = setmetatable({}, {__mode = "k"})
local _animLastSpam = 0
local _animCancelDelay = 0.12

local function _animFindIn(container)
    if not container then return nil end
    local a = container:FindFirstChild("GrabParry") or container:FindFirstChild("Parry") or container:FindFirstChild("Grab")
    if a then return a end
    local base = container:FindFirstChild("Base")
    if base then return base:FindFirstChild("GrabParry") or base:FindFirstChild("Parry") or base:FindFirstChild("Grab") end
    return nil
end

local function _resolveParryAnim(swordName)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local sa = shared and shared:FindFirstChild("SwordAPI")
    local coll = sa and sa:FindFirstChild("Collection")
    if not swordName or swordName == "" then
        local def = coll and coll:FindFirstChild("Default")
        return def and _animFindIn(def)
    end
    if _animResolveCache[swordName] and _animResolveCache[swordName].Parent then
        return _animResolveCache[swordName]
    end
    local swordsInst = shared and shared:FindFirstChild("ReplicatedInstances")
    swordsInst = swordsInst and swordsInst:FindFirstChild("Swords")
    local getSword = swordsInst and swordsInst:FindFirstChild("GetSword")
    local data = nil
    if getSword then pcall(function() data = getSword:Invoke(swordName) end) end
    local animType = data and data.AnimationType or "Single"
    local container = coll and coll:FindFirstChild(animType)
    local found = _animFindIn(container) or _animFindIn(coll and coll:FindFirstChild("Default"))
    if found then _animResolveCache[swordName] = found end
    return found
end

local function _playParryAnim()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    local swordName
    if getgenv().skinChanger and getgenv().swordAnimations and getgenv().swordAnimations ~= "" then
        swordName = getgenv().swordAnimations
    else
        swordName = char:GetAttribute("CurrentlyEquippedSword")
    end
    local anim = _resolveParryAnim(swordName)
    if not anim then return end
    local cache = _animTrackCache[animator]
    if not cache then cache = {}; _animTrackCache[animator] = cache end
    local track = cache[anim]
    if not track then
        local ok, t = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not t then return end
        pcall(function()
            for k, v in pairs(anim:GetAttributes()) do t:SetAttribute(k, v) end
            t:SetAttribute("GrabParry", true)
        end)
        pcall(function() t.Priority = Enum.AnimationPriority.Action4 end)
        cache[anim] = t
        track = t
    end
    local now = tick()
    if (now - _animLastSpam) < _animCancelDelay and track.IsPlaying then
        pcall(function()
            char:SetAttribute("ParryTime", math.max(char:GetAttribute("ParryTime") or 0, track.Length > 0 and track.Length or 1))
        end)
        return
    end
    _animLastSpam = now
    for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
        if t:GetAttribute("GrabParry") or t:GetAttribute("Parry") or t:GetAttribute("SuccessParry") then
            pcall(function() t:Stop(t:GetAttribute("StopFadeTime") or 0.05) end)
        end
    end
    local fade = anim:GetAttribute("PlayFadeTime") or 0.05
    local weight = anim:GetAttribute("PlayWeight") or 1
    local speed = anim:GetAttribute("PlaySpeed") or 1
    pcall(function()
        track.TimePosition = 0
        track:Play(fade, weight, speed)
    end)
end

BallHelper._playParryAnim = _playParryAnim

local parryBallCooldown = setmetatable({}, {__mode = "k"})
local parryCount = 0
function BallHelper.parry(bypassDebounce, ball)
    local _nowP = tick()
    if not bypassDebounce and _nowP - (getgenv()._lastParryFireAt or 0) < 0.15 then return false end
    getgenv()._lastParryFireAt = _nowP
    pcall(getgenv()._pickRandomCurve)
    pcall(_playParryAnim)

    local overrideTarget = nil
    if ball then
        local tName = ball:GetAttribute("target")
        if tName and tName ~= "" and tName ~= LocalPlayer.Name then
            local alive = workspace:FindFirstChild("Alive")
            if alive then overrideTarget = alive:FindFirstChild(tName) end
        end
    end

    if not overrideTarget and not _G.config.random_target then select_target_by_mouse() end
    local effectiveTarget = overrideTarget or CurrentTarget

    local curveCFrame = BallHelper.getCurveCFrame(effectiveTarget)
    if getgenv()._doLegitCameraMove then pcall(getgenv()._doLegitCameraMove, curveCFrame) end

    local mouseLoc
    if effectiveTarget and effectiveTarget.PrimaryPart then
        local viewportPt = workspace.CurrentCamera:WorldToViewportPoint(effectiveTarget.PrimaryPart.Position)
        mouseLoc = { viewportPt.X, viewportPt.Y }
    else
        local mp = UserInputService:GetMouseLocation()
        mouseLoc = { mp.X, mp.Y }
    end
    local screenPositions = {}
    for _, char in workspace.Alive:GetChildren() do
        if char.PrimaryPart then
            local ok, screenPt = pcall(function()
                return workspace.CurrentCamera:WorldToScreenPoint(char.PrimaryPart.Position)
            end)
            if ok and screenPt and screenPt.Z > 0 then screenPositions[char.Name] = screenPt end
        end
    end
    if not _signalReady or not _signalObj then return false end
    local ok = pcall(function() _signalObj:Fire(0.5, curveCFrame, screenPositions, mouseLoc, false) end)
    if not ok then return false end
    if parryCount > 20 then return false end
    parryCount += 1
    task.delay(0.5, function() if parryCount > 0 then parryCount -= 1 end end)
    return true
end

-- ============================================================
-- [6] BALL ANALYSIS
-- ============================================================
BallHelper._flipState = BallHelper._flipState or setmetatable({}, {__mode = "k"})

function BallHelper.ball_curved(specificBall)
    local ball = specificBall or BallHelper.get_ball()
    if not ball then return false, false, nil end
    local parent = ball.Parent
    if parent and parent.Name == "TrainingBalls" then return false, false, nil end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return false, false, nil end
    local char = LocalPlayer.Character
    local root = char and char.PrimaryPart
    if not root then return false, false, nil end

    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    if speed < 1 then return false, false, nil end

    local ballPos = BallHelper.ball_position(ball)
    local delta = root.Position - ballPos
    local dist = delta.Magnitude
    if dist < 0.001 then return false, false, nil end
    if dist < 5 then return false, false, nil end

    local invSpeed = 1 / speed
    local velUnit = velocity * invSpeed
    local dirUnit = delta.Unit
    local dot = dirUnit:Dot(velUnit)
    local backwards = dot < 0
    local now = tick()
    local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local pingSec = pingMs * 0.001
    local approachThreshold = 0.2 + math.min(pingSec * 0.5, 0.15)

    local data = BallHelper._flipState[ball]
    if not data then
        data = {
            velHist = {},
            lerp = 0,
            last_dot = nil,
            flips = 0,
            flip_time = 0,
            flipIntervals = {},
            lastVelUnit = nil,
            lastVelUnitTime = nil,
            lastVelDirAngle = 0,
            angleHist = {},
            angleAvg = 0,
            flipAvg = 0,
            flipCV = 0,
        }
        BallHelper._flipState[ball] = data
    end

    table.insert(data.velHist, { vel = velocity, t = now })
    while #data.velHist > 6 do table.remove(data.velHist, 1) end
    local n = #data.velHist

    local angleRad = math.acos(math.clamp(dot, -1, 1))
    data.lerp = data.lerp + (angleRad - data.lerp) * 0.3

    local curveRate = 0
    if n >= 2 then
        local oldest = data.velHist[1]
        local dt = now - oldest.t
        if dt > 0.005 and oldest.vel.Magnitude > 1 then
            local dotOld = dirUnit:Dot(oldest.vel.Unit)
            curveRate = (dot - dotOld) / dt
        end
    end

    local lastDot = data.last_dot or dot
    local flipMagnitude = math.abs(dot - lastDot)
    local signChanged = math.sign(dot) ~= math.sign(lastDot)
    local velDirAngle = data.lastVelDirAngle or 0
    if not data.lastVelUnitTime or (now - data.lastVelUnitTime) >= 0.02 then
        local prevVU = data.lastVelUnit or velUnit
        local d = math.clamp(prevVU:Dot(velUnit), -1, 1)
        velDirAngle = math.acos(d)
        data.lastVelUnit = velUnit
        data.lastVelUnitTime = now
        data.angleHist = data.angleHist or {}
        table.insert(data.angleHist, { a = velDirAngle, t = now })
        local cutoff = now - 0.20
        while #data.angleHist > 0 and data.angleHist[1].t < cutoff do
            table.remove(data.angleHist, 1)
        end
        local sumA = 0
        for _, e in ipairs(data.angleHist) do sumA = sumA + e.a end
        if #data.angleHist > 0 then data.angleAvg = sumA / #data.angleHist end
    end
    data.lastVelDirAngle = velDirAngle

    local velTurning = velDirAngle > 0.05
    local magThreshold = 0.10
    if signChanged and (flipMagnitude > magThreshold or (velTurning and flipMagnitude > 0.05)) then
        local sinceLastFlip = now - (data.flip_time or 0)
        if sinceLastFlip < 0.30 then
            data.flips = data.flips + 1
            if sinceLastFlip > 0.01 then
                table.insert(data.flipIntervals, sinceLastFlip)
                if #data.flipIntervals > 6 then table.remove(data.flipIntervals, 1) end
            end
        else
            data.flips = 0
            data.flipIntervals = {}
        end
        data.flip_time = now
    elseif data.flips > 0 and (now - (data.flip_time or 0)) > 0.5 then
        data.flips = 0
        data.flipIntervals = {}
    end
    data.last_dot = dot

    if data.flips >= 5 and #data.flipIntervals >= 2 then
        local sInt = 0
        for _, v in ipairs(data.flipIntervals) do sInt = sInt + v end
        local avg = sInt / #data.flipIntervals
        local var = 0
        for _, v in ipairs(data.flipIntervals) do var = var + (v - avg) ^ 2 end
        var = var / #data.flipIntervals
        local cv = math.sqrt(var) / math.max(avg, 0.01)
        data.flipAvg = avg
        data.flipCV = cv
        if cv > 0.6 then
            data.flips = 0
            data.flipIntervals = {}
        else
            local sinceFlip = now - data.flip_time
            local etaToNextFlip = avg - sinceFlip
            local etaToPeak = math.min(etaToNextFlip, math.max(0, avg - etaToNextFlip))
            if not (etaToPeak < 0.08 and dot > 0.25) then
                data.lastEval = { curved = true, backwards = backwards, dot = dot, curveRate = curveRate, dist = dist, reason = "flip" }
                return true, backwards, data.lastEval
            end
        end
    end

    local curveRateThreshold = -1.5
    if curveRate < curveRateThreshold then
        data.lastEval = { curved = true, backwards = backwards, dot = dot, curveRate = curveRate, dist = dist, reason = "rate" }
        return true, backwards, data.lastEval
    end

    if n >= 2 then
        for i = 1, math.min(2, n - 1) do
            local ref = data.velHist[i]
            if ref and ref.vel.Magnitude > 1 then
                local diff = velUnit - ref.vel.Unit
                if diff.Magnitude > 0.01 then
                    local projDot = dirUnit:Dot(diff.Unit)
                    if dot - projDot < approachThreshold then
                        data.lastEval = { curved = true, backwards = backwards, dot = dot, curveRate = curveRate, dist = dist, reason = "proj" }
                        return true, backwards, data.lastEval
                    end
                end
            end
        end
    end

    local result = dot < approachThreshold
    data.lastEval = { curved = result, backwards = backwards, dot = dot, curveRate = curveRate, dist = dist, reason = "dot" }
    return result, backwards, data.lastEval
end

function BallHelper.ball_curved_any(excludeBall)
    local balls = BallHelper.get_balls()
    if not balls then return false end
    for _, ball in ipairs(balls) do
        if ball ~= excludeBall then
            local curved = BallHelper.ball_curved(ball)
            if curved then return true, ball end
        end
    end
    return false, nil
end

function BallHelper.balls_curved_map()
    local map = {}
    local balls = BallHelper.get_balls()
    if not balls then return map end
    for _, ball in ipairs(balls) do
        if ball and ball.Parent then
            local curved, backwards, info = BallHelper.ball_curved(ball)
            map[ball] = {
                curved = curved == true,
                backwards = backwards == true,
                dot = info and info.dot or 0,
                curveRate = info and info.curveRate or 0,
                dist = info and info.dist or 0,
                reason = info and info.reason or "none",
            }
        end
    end
    return map
end

function BallHelper.get_ball_properties(_)
    local ball = BallHelper.get_ball()
    if not ball then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    local zeroVel = Vector3.zero
    local toMe = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local dot = toMe:Dot(zeroVel.Unit)
    return { Velocity = zeroVel, Direction = toMe, Distance = distance, Dot = dot }
end

function BallHelper.players_properties()
    local target = CurrentTarget
    if not target or not target.PrimaryPart 
        or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return false end
    local velocity = target.PrimaryPart.Velocity
    local direction = (LocalPlayer.Character.PrimaryPart.Position - target.PrimaryPart.Position).Unit
    local distance = (LocalPlayer.Character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
    return { velocity = velocity, direction = direction, distance = distance }
end

local spamAccuracy = 0
function BallHelper.perfom_spam(args)
    local ball = BallHelper.get_ball()
    local target = CurrentTarget
    if not ball then return false end
    if not target or not target.PrimaryPart then return false end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    local velocity = ball.AssemblyLinearVelocity
    local speed = velocity.Magnitude
    local toMe = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = toMe:Dot(velocity.Unit)
    local targetPos = target.PrimaryPart.Position
    local targetDist = LocalPlayer:DistanceFromCharacter(targetPos)
    local maxDist = args.Ping + math.min(speed / 6, 95)
    if args.Entity_Properties.distance > maxDist then return spamAccuracy end
    if args.Ball_Properties.Distance > maxDist then return spamAccuracy end
    if targetDist > maxDist then return spamAccuracy end
    local maxSpeedClamp = 5 - math.min(speed / 5, 5)
    local maxDot = math.clamp(dot, -1, 0) * maxSpeedClamp
    spamAccuracy = maxDist - maxDot
    return spamAccuracy
end

-- ============================================================
-- [7] TARGET SELECT FOR GPC
-- ============================================================
local WT = {}
function WT.Closest_Aim()
    local a = workspace:FindFirstChild("Alive")
    if not a then return nil end
    local ch = LocalPlayer.Character
    if not ch or ch.Parent ~= a then return nil end
    local cam = workspace.CurrentCamera
    local bd, best = -math.huge, nil
    for _, e in ipairs(a:GetChildren()) do
        if e ~= ch and e.PrimaryPart then
            local dir = (e.PrimaryPart.Position - cam.CFrame.Position).Unit
            local dot = cam.CFrame.LookVector:Dot(dir)
            local _, on = cam:WorldToViewportPoint(e.PrimaryPart.Position)
            if on and dot > bd then bd, best = dot, e end
        end
    end
    return best
end
function WT.Select_By_Mouse()
    local a = workspace:FindFirstChild("Alive")
    if not a then return nil end
    local cam = workspace.CurrentCamera
    local m = UserInputService:GetMouseLocation()
    local rd = cam:ScreenPointToRay(m.X, m.Y).Direction
    local bd, best = -math.huge, nil
    for _, e in ipairs(a:GetChildren()) do
        if e ~= LocalPlayer.Character and e.PrimaryPart then
            local dot = rd:Dot((e.PrimaryPart.Position - cam.CFrame.Position).Unit)
            if dot > bd then bd, best = dot, e end
        end
    end
    return best
end
getgenv().TargetSelect = WT

if not getgenv().BallPos_Get then
    getgenv().BallPos_Get = function(ball)
        if not ball then return Vector3.zero end
        return ball.Position
    end
end

-- ============================================================
-- [8] PRE CLICK: GPC
-- ============================================================
local GPC = {
    enabled = false, mode = "Keybind", target = nil, chance = 40,
    proxRange = 25, ballRange = 22, requireNear = true,
    fired = setmetatable({}, {__mode = "k"}), conn = nil,
}
function GPC:_pick()
    local ch = LocalPlayer.Character
    if not ch or not ch.PrimaryPart then return nil end
    local a = workspace:FindFirstChild("Alive")
    if not a then return nil end
    if self.mode == "Near" then
        local pos = ch.PrimaryPart.Position
        local bd, best = self.proxRange, nil
        for _, e in ipairs(a:GetChildren()) do
            if e ~= ch and e.PrimaryPart then
                local d = (e.PrimaryPart.Position - pos).Magnitude
                if d <= bd then bd, best = d, e.Name end
            end
        end
        return best
    end
    local t = self.target
    if not t or t == "" then return nil end
    if self.requireNear then
        local e = a:FindFirstChild(t)
        if not e or not e.PrimaryPart then return nil end
        if (e.PrimaryPart.Position - ch.PrimaryPart.Position).Magnitude > self.proxRange then return nil end
    end
    return t
end
function GPC:_check(ball, tn)
    if not ball or not tn then return false end
    local t = ball:GetAttribute("target")
    if not t or t == "" or t ~= tn or t == LocalPlayer.Name then return false end
    local ch = LocalPlayer.Character
    if not ch or not ch.PrimaryPart then return false end
    local a = workspace:FindFirstChild("Alive")
    if not a or ch.Parent ~= a then return false end
    if ch.PrimaryPart:FindFirstChild("SingularityCape") then return false end
    local tc = a:FindFirstChild(tn)
    if not tc or not tc.PrimaryPart then return false end
    local bp
    pcall(function() bp = getgenv().BallPos_Get(ball) end)
    if not bp then bp = ball.Position end
    if (bp - tc.PrimaryPart.Position).Magnitude > self.ballRange then return false end
    local c = math.clamp(self.chance, 0, 100)
    if c <= 0 then return false end
    if c >= 100 then return true end
    return math.random(1, 100) <= c
end
function GPC:_fire(ball, tn)
    if self.fired[ball] then return end
    if not self:_check(ball, tn) then return end
    self.fired[ball] = true
    pcall(function() if BallHelper._playParryAnim then BallHelper._playParryAnim() end end)
    pcall(BallHelper.parry)
    task.delay(0.85, function() self.fired[ball] = nil end)
end
function GPC:Start()
    if self.conn then self.conn:Disconnect() end
    self.conn = RunService.PreSimulation:Connect(function()
        if not self.enabled then return end
        local t = self:_pick()
        if not t then return end
        local b = BallHelper.get_ball()
        if not b then return end
        self:_fire(b, t)
    end)
end
function GPC:Stop()
    if self.conn then self.conn:Disconnect(); self.conn = nil end
    self.fired = setmetatable({}, {__mode = "k"})
end
getgenv().GriefPreClick = GPC
getgenv().GPC = GPC

-- ============================================================
-- [9] PRE CLICK: APC
-- ============================================================
local APC = {
    enabled = false,
    hist = setmetatable({}, {__mode = "k"}),
    clicked = {},
    lastAtk = nil,
}
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if not APC.enabled then return end
        local b = BallHelper.get_ball()
        if not b then return end
        local z = b:FindFirstChild("zoomies")
        if not z then return end
        local h = APC.hist[b]
        if not h then h = {}; APC.hist[b] = h end
        table.insert(h, z.VectorVelocity.Magnitude)
        if #h > 15 then table.remove(h, 1) end
        local t = b:GetAttribute("target")
        if t and t ~= "" and t ~= LocalPlayer.Name then APC.lastAtk = t end
    end)
end)
task.spawn(function()
    local a = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive", 10)
    if not a then return end
    a.ChildRemoved:Connect(function(child)
        if not APC.enabled then return end
        local t = APC.lastAtk
        if not t or child.Name ~= t then return end
        if APC.clicked[child.Name] then return end
        local fast = false
        for _, h in pairs(APC.hist) do
            for _, s in ipairs(h) do if s >= 600 then fast = true; break end end
            if fast then break end
        end
        if not fast then return end
        APC.clicked[child.Name] = true
        task.delay(math.random(120, 140) / 1000, function()
            local a2 = workspace:FindFirstChild("Alive")
            if not a2 or not a2:FindFirstChild(LocalPlayer.Name) then APC.clicked[child.Name] = nil; return end
            local b = BallHelper.get_ball()
            if not b then return end
            if b:GetAttribute("target") == LocalPlayer.Name then APC.clicked[child.Name] = nil; return end
            pcall(function() if BallHelper._playParryAnim then BallHelper._playParryAnim() end end)
            pcall(BallHelper.parry)
            APC.clicked[child.Name] = nil
        end)
        APC.lastAtk = nil
    end)
end)
getgenv().AutoPreClick = APC

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= Enum.KeyCode.T then return end
    if not GPC.enabled or GPC.mode ~= "Keybind" then return end
    local WTo = getgenv().TargetSelect
    if not WTo then return end
    local t = WTo.Select_By_Mouse() or WTo.Closest_Aim()
    if t then
        GPC.target = t.Name
        pcall(function() UI:Notify("Grief Target", t.Name, "info") end)
    end
end)

-- ============================================================
-- [10] ACCURACY + ADAPTIVE SYSTEM
-- ============================================================
if not _G.config.curve_method or _G.config.curve_method == "" then _G.config.curve_method = "camera" end
local accuracyMultiplier = 0.5
local AccuracyMap = {
    ["200"] = 2.20, ["170"] = 1.80, ["140"] = 1.80,
    ["100"] = 1.65, ["90"]  = 1.55, ["80"]  = 1.45, ["65"]  = 1.35,
}

getgenv()._lastAutoParry = getgenv()._lastAutoParry or 0
getgenv()._lastTrainingParry = getgenv()._lastTrainingParry or 0
getgenv()._ballParryCooldown = getgenv()._ballParryCooldown or setmetatable({}, {__mode = "k"})
getgenv()._etaBaseWindow = 0.22
getgenv()._etaPredThresh = 18
getgenv()._etaPingSamples = getgenv()._etaPingSamples or {}
getgenv()._etaJitterBuffer = getgenv()._etaJitterBuffer or 0
getgenv()._etaSpeedBuckets = getgenv()._etaSpeedBuckets or {
    slow = { mult = 0.9 }, mid  = { mult = 1.0 }, fast = { mult = 1.2 },
}
getgenv()._ETA_TARGET_MS = getgenv()._ETA_TARGET_MS or 195
getgenv()._ETA_SPREAD_MS = getgenv()._ETA_SPREAD_MS or 35
getgenv()._etaFeedback = getgenv()._etaFeedback or { fires = 0, successes = 0 }
getgenv()._etaFeedback.ftMax = getgenv()._ETA_TARGET_MS / 1000
getgenv()._etaFeedback.ftMin = getgenv()._etaFeedback.ftMax - (getgenv()._ETA_SPREAD_MS / 1000)
print(string.format(
    "[daemon] ETA locked: window %d-%dms (target %dms). Override: set getgenv()._ETA_TARGET_MS before re-inject.",
    getgenv()._ETA_TARGET_MS - getgenv()._ETA_SPREAD_MS,
    getgenv()._ETA_TARGET_MS,
    getgenv()._ETA_TARGET_MS
))
getgenv()._tsunamiFeedback = getgenv()._tsunamiFeedback or {
    fires = 0, successes = 0,
    windowMax = 0.35, windowMin = 0.18,
    marginBase = 10, marginSpeedScale = 0.04,
}
getgenv()._lastParryPath = getgenv()._lastParryPath or "distance"
getgenv()._spike = getgenv()._spike or {
    active_until = 0, last = setmetatable({}, {__mode = "k"}),
    fires = 0, successes = 0, win = 0.20, lastFireAt = 0,
}

pcall(function()
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if getgenv()._lastParryPath == "spike" and getgenv()._spike and (tick() - getgenv()._spike.lastFireAt) < 0.4 then
            getgenv()._spike.successes = getgenv()._spike.successes + 1
        elseif getgenv()._lastParryPath == "tsunami" and getgenv()._tsunamiFeedback then
            getgenv()._tsunamiFeedback.successes = getgenv()._tsunamiFeedback.successes + 1
        elseif getgenv()._etaFeedback then
            getgenv()._etaFeedback.successes = getgenv()._etaFeedback.successes + 1
        end
    end)
end)

task.spawn(function()
    while task.wait(5) do
        local fb = getgenv()._etaFeedback
        local ts = getgenv()._tsunamiFeedback
        if not fb then break end
        local _otherActive = _G.triggerbot or _G.manual_spam or _G.config.auto_spam
            or (getgenv().GriefPreClick and getgenv().GriefPreClick.enabled)
            or (getgenv().AutoPreClick and getgenv().AutoPreClick.enabled)
        if fb.fires >= 15 then
            if _otherActive then
                fb.fires = 0; fb.successes = 0
            else
                local rate = math.min(fb.successes / math.max(fb.fires, 1), 1.0)
                local oldMax = fb.ftMax
                if rate < 0.6 then fb.ftMax = math.min(fb.ftMax + 0.02, 0.28)
                elseif rate < 0.75 then fb.ftMax = math.min(fb.ftMax + 0.01, 0.26)
                elseif rate > 0.95 then fb.ftMax = math.max(fb.ftMax - 0.005, 0.18) end
                fb.ftMin = fb.ftMax - 0.04
                fb.fires = 0; fb.successes = 0
                if fb.ftMax ~= oldMax then
                    pcall(function()
                        UI:Notify("eta tune", string.format("window: %.0f-%.0fms", fb.ftMin * 1000, fb.ftMax * 1000), "info")
                    end)
                end
            end
        end
        if ts and ts.fires >= 10 then
            if _otherActive then
                ts.fires = 0; ts.successes = 0
            else
                local rate = math.min(ts.successes / math.max(ts.fires, 1), 1.0)
                local oldWin = ts.windowMax
                local oldMargin = ts.marginBase
                if rate < 0.55 then
                    ts.windowMax = math.min(ts.windowMax + 0.03, 0.55)
                    ts.marginBase = math.min(ts.marginBase + 1.5, 20)
                elseif rate < 0.75 then
                    ts.windowMax = math.min(ts.windowMax + 0.015, 0.50)
                    ts.marginBase = math.min(ts.marginBase + 0.8, 16)
                elseif rate > 0.95 then
                    ts.windowMax = math.max(ts.windowMax - 0.01, 0.15)
                    ts.marginBase = math.max(ts.marginBase - 0.5, 8)
                end
                ts.fires = 0; ts.successes = 0
                if ts.windowMax ~= oldWin or ts.marginBase ~= oldMargin then
                    pcall(function()
                        UI:Notify("tsunami tune", string.format("etaMax: %.2fs | margin: %.0f", ts.windowMax, ts.marginBase), "info")
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(8) do
        local spk = getgenv()._spike
        if not spk then break end
        if spk.fires >= 5 then
            local rate = math.min(spk.successes / math.max(spk.fires, 1), 1.0)
            local oldWin = spk.win
            if rate < 0.55 then spk.win = math.min(spk.win + 0.025, 0.30)
            elseif rate < 0.75 then spk.win = math.min(spk.win + 0.01, 0.26)
            elseif rate > 0.85 then spk.win = math.max(spk.win - 0.01, 0.12) end
            spk.fires = 0; spk.successes = 0
            if spk.win ~= oldWin then
                pcall(function()
                    UI:Notify("spike tune", string.format("win: %.0fms", spk.win * 1000), "info")
                end)
            end
        end
    end
end)

local savedAcc = tostring(_G.config.accuracy or 100)
if not AccuracyMap[savedAcc] then savedAcc = "100" end
accuracyMultiplier = AccuracyMap[savedAcc]

getgenv()._adaptiveEnabled = _G.config.auto_adaptive or false
getgenv()._adaptiveSmooth = 100
getgenv()._adaptiveFps = 60

task.spawn(function()
    local count = 0
    local last = tick()
    RunService.RenderStepped:Connect(function()
        count = count + 1
        local now = tick()
        if now - last >= 0.5 then
            getgenv()._adaptiveFps = math.floor(count / (now - last) + 0.5)
            count = 0; last = now
        end
    end)
end)

local function _mapAccToMult(acc)
    if acc >= 200 then return 2.20 end
    if acc >= 170 then return 1.80 end
    if acc >= 140 then return 1.80 end
    if acc >= 100 then return 1.65 end
    if acc >= 90 then return 1.55 end
    if acc >= 80 then return 1.45 end
    return 1.35
end

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv()._adaptiveEnabled then
            local ping = 50
            pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            local fps = getgenv()._adaptiveFps or 60
            if fps <= 0 then fps = 60 end
            if ping <= 0 then ping = 50 end
            local pingScore = math.clamp(ping / 100, 0, 2)
            local fpsScore = math.clamp((120 - fps) / 100, 0, 1.5)
            local score = math.clamp(pingScore * 1.5 + fpsScore * 1.0, 0, 3)
            local target = math.floor(200 - score * 45 + 0.5)
            target = math.clamp(target, 65, 200)
            local smooth = getgenv()._adaptiveSmooth or 100
            smooth = smooth + (target - smooth) * 0.35
            getgenv()._adaptiveSmooth = smooth
            local finalAcc = math.clamp(math.floor(smooth + 0.5), 65, 200)
            accuracyMultiplier = _mapAccToMult(finalAcc)
            getgenv()._adaptiveAcc = finalAcc

            local mode = getgenv()._adaptiveMode or "Accuracy Only"
            if mode == "Accuracy + Range" then
                local ball = BallHelper.get_ball()
                local speed = 0
                local dist = 0
                if ball then
                    local z = ball:FindFirstChild("zoomies")
                    if z then speed = z.VectorVelocity.Magnitude end
                    local char = LocalPlayer.Character
                    if char and char.PrimaryPart then
                        dist = (char.PrimaryPart.Position - ball.Position).Magnitude
                    end
                end
                local speedBucket = speed < 150 and 0 or (speed < 350 and 1.5 or 3.5)
                local distBucket = dist > 50 and 1.5 or (dist > 30 and 1.0 or 0.5)
                local baseRange = tonumber(_G.config.parry_range) or 2
                local targetRange = math.clamp(baseRange + speedBucket + distBucket, baseRange, 10)
                local smoothR = getgenv()._adaptiveRangeSmooth or baseRange
                smoothR = smoothR + (targetRange - smoothR) * 0.35
                getgenv()._adaptiveRangeSmooth = smoothR
                local finalRange = math.clamp(math.floor(smoothR + 0.5), baseRange, 10)
                getgenv().ParryRange = finalRange
                getgenv()._adaptiveRange = finalRange
                getgenv()._adaptiveSpeed = speed
                getgenv()._adaptiveDist = dist
            else
                getgenv()._adaptiveRange = nil
                getgenv()._adaptiveSpeed = nil
                getgenv()._adaptiveDist = nil
                getgenv().ParryRange = tonumber(_G.config.parry_range) or 2
            end
        else
            getgenv()._adaptiveAcc = _G.config.accuracy or 100
            getgenv().ParryRange = tonumber(_G.config.parry_range) or 2
            getgenv()._adaptiveRange = nil
            getgenv()._adaptiveSpeed = nil
            getgenv()._adaptiveDist = nil
        end
    end
end)

getgenv().OnAccuracyChange = function(val)
    local mult = AccuracyMap[val]
    if mult then accuracyMultiplier = mult; _G.config.accuracy = tonumber(val) end
end

getgenv().OnAdaptiveToggle = function(enabled)
    getgenv()._adaptiveEnabled = enabled
    _G.config.auto_adaptive = enabled
    if enabled then
        getgenv()._adaptiveSmooth = 100
        getgenv()._adaptiveRangeSmooth = tonumber(_G.config.parry_range) or 2
    end
    pcall(function() UI:Notify("Adaptive", enabled and "ON" or "OFF", "info") end)
end

getgenv().OnRandomTargetToggle = function(enabled)
    _G.config.random_target = enabled
    CurrentTarget = nil
    recentlyPickedTargets = {}
    if enabled then pick_random_target() end
end

getgenv().OnCurveChange = function(value)
    _G.config.curve_method = value
    getgenv()._SelectedCurve = value
end

-- ============================================================
-- [11] CHAIN PARRY
-- ============================================================
ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, parrier)
    if _G.singularity_active then return end
    if parrier.Parent and parrier.Parent ~= LocalPlayer.Character then
        if parrier.Parent.Parent ~= workspace.Alive then return end
    end
    local ball = BallHelper.get_ball()
    if not ball then return end
    if ball.Parent and ball.Parent.Name == "TrainingBalls" then return end
    if not CurrentTarget or not CurrentTarget.PrimaryPart then return end
    local now = tick()
    getgenv()._lastChainParry = getgenv()._lastChainParry or 0
    if now - getgenv()._lastChainParry < 0.4 then return end
    local distToTarget = (LocalPlayer.Character.PrimaryPart.Position - CurrentTarget.PrimaryPart.Position).Magnitude
    local distToBall = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local toBall = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = toBall:Dot(ball.AssemblyLinearVelocity.Unit)
    local isCurving = BallHelper.ball_curved()
    if distToTarget < 15 and distToBall < 15 and dot > -0.25 then
        if isCurving then
            getgenv()._lastChainParry = now
            BallHelper.parry(_G.config.curve_method)
        end
    end
    if not CurrentAnimTrack then return end
    CurrentAnimTrack:Stop()
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if LocalPlayer.Character.Parent ~= workspace.Alive then return end
    if not CurrentAnimTrack then return end
    CurrentAnimTrack:Stop()
end)

workspace.Balls.ChildRemoved:Connect(function(_)
    parryCount = 0
    CurrentTarget = nil
    recentlyPickedTargets = {}
    if Connections.target_change then
        Connections.target_change:Disconnect()
        Connections.target_change = nil
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, parrier)
    if _G.singularity_active then return end
    local myHrp = LocalPlayer.Character.PrimaryPart
    local ball = BallHelper.get_ball()
    if not ball then return end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return end
    local speed = zoomies.VectorVelocity.Magnitude
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local velocity = zoomies.VectorVelocity
    local velUnit = velocity.Unit
    local toMe = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    toMe:Dot(velUnit)
    local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local speedFactor = math.min(speed / 100, 40)
    local timeToImpact = distance / speed - (pingMs / 1000)
    local isFast = speed > 100
    local minDistance = 15 - math.min(distance / 1000, 15) + speedFactor
    if isFast and timeToImpact > pingMs / 10 then minDistance = math.max(minDistance - 15, 15) end
    if parrier ~= myHrp and distance > minDistance then
        BallHelper.ball.properties.curving = tick()
    end
end)

-- ============================================================
-- [12] ABILITY ESP
-- ========================w====================================
local _ESP = {
    enabled = false, data = {}, icon_cache = {}, cooldowns = {},
    uses = {}, char_conns = {}, heartbeat = nil, player_added = nil,
    last_update = 0, abilities_mod = nil,
}

do
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if shared then
        local ab = shared:FindFirstChild("Abilities")
        if ab then
            local ok, mod = pcall(require, ab)
            if ok then _ESP.abilities_mod = mod end
        end
    end
end

local function _esp_get_ability(player)
    return player:GetAttribute("CurrentlyEquippedAbility") or player:GetAttribute("EquippedAbility") or ""
end
local function _esp_get_cooldown(player, ability)
    if not _ESP.abilities_mod or not ability or ability == "" then return nil end
    local ok, cd = pcall(_ESP.abilities_mod.getAbilityCooldown, player, ability)
    if ok and type(cd) == "number" and cd > 0 then return cd end
    return nil
end
local function _esp_get_icon(ability)
    if not ability or ability == "" then return "" end
    if _ESP.icon_cache[ability] ~= nil then return _ESP.icon_cache[ability] end
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local abilities = shared and shared:FindFirstChild("Abilities")
    local m = abilities and abilities:FindFirstChild(ability)
    if not m then _ESP.icon_cache[ability] = ""; return "" end
    local ok, mod = pcall(require, m)
    local icon = (ok and mod and type(mod.iconId) == "string") and mod.iconId or ""
    _ESP.icon_cache[ability] = icon
    return icon
end
local function _esp_get_max_uses(player, ability)
    if not ability or ability == "" then return nil end
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local abilities = shared and shared:FindFirstChild("Abilities")
    local m = abilities and abilities:FindFirstChild(ability)
    if not m then return nil end
    local ok, mod = pcall(require, m)
    if not ok or not mod then return nil end
    for _, key in ipairs({ "maxUses", "uses", "maxUsesPerRound", "usesPerRound", "maxCharges", "charges" }) do
        local v = mod[key]
        if type(v) == "number" and v >= 1 then return v end
    end
    if _ESP.abilities_mod then
        for _, fn in ipairs({ "getAbilityUses", "getAbilityCharges", "getAbilityMaxUses" }) do
            local f = _ESP.abilities_mod[fn]
            if type(f) == "function" then
                local ok2, res = pcall(f, player, ability)
                if ok2 and type(res) == "number" and res >= 1 then return res end
            end
        end
    end
    return nil
end
local function _esp_set_nametag(char, visible)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = visible and Enum.HumanoidDisplayDistanceType.Viewer or Enum.HumanoidDisplayDistanceType.None
    end
end

local function _esp_create(player)
    task.spawn(function()
        local char = player.Character
        while not char or not char.Parent do
            task.wait()
            if not _ESP.enabled then return end
            char = player.Character
        end
        if not _ESP.enabled then return end
        local head = char:WaitForChild("Head", 10)
        if not head or not _ESP.enabled then return end
        if _ESP.data[player] then
            pcall(function() _ESP.data[player].bill:Destroy() end)
            if _ESP.data[player].cd_conn then pcall(function() _ESP.data[player].cd_conn:Disconnect() end) end
            _ESP.data[player] = nil
        end
        _esp_set_nametag(char, false)
        local bill = Instance.new("BillboardGui")
        bill.Name = "daemon_AbilityESP"
        bill.Adornee = head
        bill.Size = UDim2.fromOffset(160, 44)
        bill.StudsOffset = Vector3.new(0, 3.0, 0)
        bill.AlwaysOnTop = true
        bill.ResetOnSpawn = false
        local p = nil
        pcall(function() if gethui then p = gethui() end end)
        if not p then pcall(function() p = game:GetService("CoreGui") end) end
        if not p then p = player:WaitForChild("PlayerGui") end
        bill.Parent = p
        local icon = Instance.new("ImageLabel")
        icon.Name = "AbilityIcon"
        icon.Size = UDim2.fromOffset(26, 26)
        icon.Position = UDim2.new(0, 4, 0.5, -13)
        icon.BackgroundTransparency = 1
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Image = _esp_get_icon(_esp_get_ability(player))
        icon.Parent = bill
        if icon.Image == "" then
            icon.ImageTransparency = 1
            icon.BackgroundTransparency = 0.55
            icon.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            local ic = Instance.new("UICorner")
            ic.CornerRadius = UDim.new(1, 0); ic.Parent = icon
            local il = Instance.new("TextLabel")
            il.Name = "FallbackGlyph"
            il.Size = UDim2.fromScale(1, 1)
            il.BackgroundTransparency = 1
            il.Font = Enum.Font.GothamBold
            il.TextSize = 11
            il.TextColor3 = Color3.fromRGB(200, 200, 210)
            il.Text = "?"
            il.Parent = icon
        end
        local info = Instance.new("Frame")
        info.Name = "Info"
        info.Position = UDim2.new(0, 34, 0, 0)
        info.Size = UDim2.new(1, -38, 1, 0)
        info.BackgroundTransparency = 1
        info.Parent = bill
        local name = Instance.new("TextLabel")
        name.Name = "PlayerName"
        name.Size = UDim2.new(1, 0, 0, 14)
        name.Position = UDim2.new(0, 0, 0, 2)
        name.BackgroundTransparency = 1
        name.Font = Enum.Font.GothamMedium
        name.TextSize = 11
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.TextStrokeTransparency = 0.5
        name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Text = player.DisplayName
        name.Parent = info
        local statusRow = Instance.new("Frame")
        statusRow.Name = "StatusRow"
        statusRow.Size = UDim2.new(1, 0, 0, 16)
        statusRow.Position = UDim2.new(0, 0, 0, 18)
        statusRow.BackgroundTransparency = 1
        statusRow.Parent = info
        local statusLayout = Instance.new("UIListLayout")
        statusLayout.FillDirection = Enum.FillDirection.Horizontal
        statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        statusLayout.Padding = UDim.new(0, 5)
        statusLayout.Parent = statusRow
        local badge = Instance.new("TextLabel")
        badge.Name = "Badge"
        badge.AutomaticSize = Enum.AutomaticSize.X
        badge.Size = UDim2.fromOffset(0, 14)
        badge.BackgroundColor3 = Color3.fromRGB(65, 200, 90)
        badge.BackgroundTransparency = 0.25
        badge.BorderSizePixel = 0
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.TextColor3 = Color3.fromRGB(255, 255, 255)
        badge.Text = "Ready!"
        badge.Parent = statusRow
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = badge
        local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 6); bp.PaddingRight = UDim.new(0, 6); bp.Parent = badge
        local timer = Instance.new("TextLabel")
        timer.Name = "Timer"
        timer.AutomaticSize = Enum.AutomaticSize.X
        timer.Size = UDim2.fromOffset(0, 14)
        timer.BackgroundTransparency = 1
        timer.Font = Enum.Font.GothamMedium
        timer.TextSize = 10
        timer.TextColor3 = Color3.fromRGB(230, 230, 230)
        timer.TextStrokeTransparency = 0.7
        timer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        timer.RichText = true
        timer.Text = ""
        timer.Parent = statusRow
        local last_trigger = 0
        local cd_conn = char.AttributeChanged:Connect(function(attr)
            if attr == "CooldownExpiration" then
                local val = char:GetAttribute("CooldownExpiration")
                if (val == 0 or val == nil) and tick() - last_trigger > 0.5 then
                    local ab = _esp_get_ability(player)
                    local dur = _esp_get_cooldown(player, ab)
                    if dur then
                        last_trigger = tick()
                        _ESP.cooldowns[player] = { expiry = tick() + dur }
                        local u = _ESP.uses[player]
                        if u and u.left > 0 then u.left = u.left - 1 end
                    end
                end
            elseif attr == "AbilityActive" then
                local active = char:GetAttribute("AbilityActive")
                if active == true and tick() - last_trigger > 0.5 then
                    local ab = _esp_get_ability(player)
                    local dur = _esp_get_cooldown(player, ab)
                    if dur then
                        last_trigger = tick()
                        _ESP.cooldowns[player] = { expiry = tick() + dur }
                        local u = _ESP.uses[player]
                        if u and u.left > 0 then u.left = u.left - 1 end
                    end
                end
            end
        end)
        local ab = _esp_get_ability(player)
        local cdur = _esp_get_cooldown(player, ab)
        local is_passive = cdur == nil
        local mu = _esp_get_max_uses(player, ab)
        if mu and not _ESP.uses[player] then _ESP.uses[player] = { max = mu, left = mu } end
        _ESP.data[player] = {
            bill = bill, name = name, icon = icon, badge = badge, timer = timer,
            cd_conn = cd_conn, is_passive = is_passive, last_ability = ab,
        }
    end)
end

local function _esp_add_player(player)
    if player == LocalPlayer then return end
    if _ESP.char_conns[player] then return end
    local c1 = player.CharacterAdded:Connect(function(char)
        _ESP.cooldowns[player] = nil
        _esp_set_nametag(char, false)
        _esp_create(player)
    end)
    local c2 = player.CharacterRemoving:Connect(function() _ESP.cooldowns[player] = nil end)
    _ESP.char_conns[player] = { c1, c2 }
    if player.Character then
        _esp_set_nametag(player.Character, false)
        _esp_create(player)
    end
end

local function _esp_start()
    if _ESP.enabled then return end
    _ESP.enabled = true
    getgenv().AbilityESP = true
    if not _ESP.heartbeat then
        _ESP.heartbeat = RunService.Heartbeat:Connect(function()
            if not _ESP.enabled then return end
            local now = tick()
            if now - _ESP.last_update < 0.1 then return end
            _ESP.last_update = now
            for player, d in pairs(_ESP.data) do
                if not (player and player.Parent) or not d.bill.Parent then
                    pcall(function() d.bill:Destroy() end)
                    if d.cd_conn then pcall(function() d.cd_conn:Disconnect() end) end
                    _ESP.data[player] = nil
                    _ESP.cooldowns[player] = nil
                    continue
                end
                if d.name.Text ~= player.DisplayName then d.name.Text = player.DisplayName end
                local ab = _esp_get_ability(player)
                if d.last_ability ~= ab then
                    d.last_ability = ab
                    local new_icon = _esp_get_icon(ab)
                    d.icon.Image = new_icon
                    if new_icon == "" then
                        d.icon.ImageTransparency = 1
                        d.icon.BackgroundTransparency = 0.55
                        d.icon.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                        if not d.icon:FindFirstChildOfClass("UICorner") then
                            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = d.icon
                        end
                        if not d.icon:FindFirstChild("FallbackGlyph") then
                            local l = Instance.new("TextLabel")
                            l.Name = "FallbackGlyph"; l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1
                            l.Font = Enum.Font.GothamBold; l.TextSize = 11; l.TextColor3 = Color3.fromRGB(200, 200, 210)
                            l.Text = "?"; l.Parent = d.icon
                        end
                    else
                        d.icon.ImageTransparency = 0
                        d.icon.BackgroundTransparency = 1
                        local fg = d.icon:FindFirstChild("FallbackGlyph"); if fg then fg:Destroy() end
                    end
                    local dur = _esp_get_cooldown(player, ab)
                    d.is_passive = dur == nil
                    _ESP.cooldowns[player] = nil
                    local mu = _esp_get_max_uses(player, ab)
                    if mu then _ESP.uses[player] = { max = mu, left = mu } else _ESP.uses[player] = nil end
                end
                local cd = _ESP.cooldowns[player]
                local u = _ESP.uses[player]
                local usesSuffix = u and string.format(" <font color='#50DCFF'>x%d</font>", u.left) or ""
                local badgeText, badgeColor, timerText
                if cd and now < cd.expiry then
                    badgeText = "Wait"; badgeColor = Color3.fromRGB(255, 140, 60)
                    timerText = string.format("⏱ %.1fs", cd.expiry - now) .. usesSuffix
                elseif d.is_passive then
                    badgeText = "Passive"; badgeColor = Color3.fromRGB(120, 120, 130)
                    timerText = u and string.format("<font color='#50DCFF'>x%d</font>", u.left) or ""
                else
                    if cd then _ESP.cooldowns[player] = nil end
                    badgeText = "Ready!"; badgeColor = Color3.fromRGB(65, 200, 90)
                    timerText = u and string.format("<font color='#50DCFF'>x%d</font>", u.left) or ""
                end
                if d.badge.Text ~= badgeText then d.badge.Text = badgeText end
                if d.badge.BackgroundColor3 ~= badgeColor then d.badge.BackgroundColor3 = badgeColor end
                if d.timer.Text ~= timerText then d.timer.Text = timerText end
            end
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do _esp_add_player(p) end
    if not _ESP.player_added then
        _ESP.player_added = Players.PlayerAdded:Connect(function(p) if _ESP.enabled then _esp_add_player(p) end end)
    end
end

local function _esp_stop()
    if not _ESP.enabled then return end
    _ESP.enabled = false
    getgenv().AbilityESP = false
    if _ESP.heartbeat then _ESP.heartbeat:Disconnect(); _ESP.heartbeat = nil end
    if _ESP.player_added then pcall(function() _ESP.player_added:Disconnect() end); _ESP.player_added = nil end
    for _, conns in pairs(_ESP.char_conns) do for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end end
    table.clear(_ESP.char_conns)
    for _, d in pairs(_ESP.data) do
        pcall(function() d.bill:Destroy() end)
        if d.cd_conn then pcall(function() d.cd_conn:Disconnect() end) end
    end
    table.clear(_ESP.data); table.clear(_ESP.cooldowns); table.clear(_ESP.uses)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then _esp_set_nametag(p.Character, true) end
    end
end

getgenv().AbilityESP_API = {
    Start = _esp_start, Stop = _esp_stop,
    Toggle = function() if _ESP.enabled then _esp_stop() else _esp_start() end end,
    IsEnabled = function() return _ESP.enabled end,
}

if _G.config.ability_esp then
    task.defer(function() pcall(function() getgenv().AbilityESP_API.Start() end) end)
end

-- ============================================================
-- [13] SKIN CHANGER
-- ============================================================
local SKIN_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedSword"
local AUTO_CONFIG_FILE = "LeviHubX/auto_config.json"

local function readLeviHubAutoConfig()
    local data = {}
    pcall(function()
        if isfile and isfile(AUTO_CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE))
            if type(decoded) == "table" then data = decoded end
        end
    end)
    return data
end
local function writeLeviHubAutoConfig(data)
    pcall(function()
        if isfolder and makefolder and not isfolder("LeviHubX") then makefolder("LeviHubX") end
        if writefile then writefile(AUTO_CONFIG_FILE, HttpService:JSONEncode(data or {})) end
    end)
end
local function loadLastEquippedSword()
    local data = readLeviHubAutoConfig()
    local saved = data[SKIN_LAST_EQUIPPED_CONFIG_KEY]
    return type(saved) == "string" and saved or ""
end

getgenv().saveLastEquippedSword = function(swordName)
    if type(swordName) ~= "string" or swordName == "" then return end
    local data = readLeviHubAutoConfig()
    data[SKIN_LAST_EQUIPPED_CONFIG_KEY] = swordName
    writeLeviHubAutoConfig(data)
end

do
    local savedLastSword = loadLastEquippedSword()
    getgenv().skinChanger = getgenv().skinChanger or savedLastSword ~= ""
    getgenv().swordModel = type(getgenv().swordModel) == "string" and getgenv().swordModel ~= "" and getgenv().swordModel or savedLastSword
    getgenv().swordAnimations = type(getgenv().swordAnimations) == "string" and getgenv().swordAnimations ~= "" and getgenv().swordAnimations or savedLastSword
    getgenv().swordFX = type(getgenv().swordFX) == "string" and getgenv().swordFX ~= "" and getgenv().swordFX or savedLastSword
end

task.spawn(function()
    local rs = game:GetService("ReplicatedStorage")
    local swordInstancesInstance = rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
    local swordInstances = require(swordInstancesInstance)
    local swordsController
    task.spawn(function()
        while task.wait(0.25) and not swordsController do
            local ok, conns = pcall(getconnections, rs.Remotes.FireSwordInfo.OnClientEvent)
            if ok and conns then
                for _, v in ipairs(conns) do
                    if v.Function and islclosure and islclosure(v.Function) then
                        local ok2, up = pcall(getupvalues, v.Function)
                        if ok2 and #up == 1 and type(up[1]) == "table" then
                            swordsController = up[1]; break
                        end
                    end
                end
            end
        end
    end)
    local function getSlashName(swordName)
        local ok, sln = pcall(function() return swordInstances:GetSword(swordName) end)
        return (ok and sln and sln.SlashName) or "SlashEffect"
    end
    local function refreshSlashName()
        local fxName = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
        if fxName ~= "" then getgenv().slashName = getSlashName(fxName) else getgenv().slashName = "SlashEffect" end
    end
    refreshSlashName()
    local function setSword()
        if not getgenv().skinChanger then return end
        if not LocalPlayer.Character then return end
        pcall(function()
            local f = rawget(swordInstances, "EquipSwordTo")
            if type(f) == "function" then
                local ups = getupvalues(f)
                for i = 1, #ups do
                    if type(ups[i]) == "boolean" then setupvalue(f, i, false); break end
                end
            end
        end)
        pcall(function() swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel) end)
        task.spawn(function()
            local attempts = 0
            while not swordsController and attempts < 20 do task.wait(0.5); attempts = attempts + 1 end
            if not swordsController then return end
            pcall(function()
                if swordsController.SetSword then
                    swordsController:SetSword(getgenv().swordAnimations ~= "" and getgenv().swordAnimations or getgenv().swordModel)
                end
            end)
            pcall(function()
                local targetSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                if rs.Remotes:FindFirstChild("FireSwordInfo") then rs.Remotes.FireSwordInfo:FireServer(targetSword) end
                if swordsController.currentSword ~= nil then pcall(function() swordsController.currentSword = targetSword end) end
                if swordsController.SwordFX ~= nil then pcall(function() swordsController.SwordFX = targetSword end) end
            end)
        end)
    end
    local hookedFuncs = {}
    task.spawn(function()
        local remotesToHook = {"ParrySuccessAll", "ParryAttempt", "ParrySuccess", "PlaySound", "PlayVisuals"}
        while task.wait(1) do
            for _, remoteName in ipairs(remotesToHook) do
                local remote = rs.Remotes:FindFirstChild(remoteName)
                if remote and remote:IsA("RemoteEvent") then
                    local ok, conns = pcall(getconnections, remote.OnClientEvent)
                    if ok and type(conns) == "table" then
                        for _, v in ipairs(conns) do
                            local func = v.Function
                            if func and not hookedFuncs[func] then
                                hookedFuncs[func] = true
                                v:Disable()
                                local targetFunc = func
                                local ourFunc
                                ourFunc = function(...)
                                    local args = { ... }
                                    local isLocal = false
                                    for _, arg in ipairs(args) do
                                        if tostring(arg) == LocalPlayer.Name or (typeof(arg) == "Instance" and (arg == LocalPlayer.Character or arg == LocalPlayer)) then
                                            isLocal = true; break
                                        end
                                    end
                                    if isLocal and getgenv().skinChanger then
                                        local fxSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                                        refreshSlashName()
                                        local swordFound = false
                                        local slashFound = false
                                        for i, arg in ipairs(args) do
                                            if type(arg) == "string" then
                                                if fxSword ~= "" and not slashFound and (arg:match("Slash") or arg == "Default" or arg:match("Effect")) then
                                                    args[i] = getgenv().slashName
                                                    slashFound = true
                                                elseif fxSword ~= "" and not swordFound then
                                                    local isSword = false
                                                    pcall(function()
                                                        if rs.Shared.ReplicatedInstances.Swords:FindFirstChild(arg) then isSword = true end
                                                    end)
                                                    if isSword or arg == LocalPlayer:GetAttribute("CurrentlyEquippedSword") then
                                                        args[i] = fxSword; swordFound = true
                                                    end
                                                end
                                            end
                                        end
                                        if fxSword ~= "" and not slashFound and type(args[1]) == "string" then args[1] = getgenv().slashName end
                                        if fxSword ~= "" and not swordFound and type(args[3]) == "string" then args[3] = fxSword end
                                    end
                                    if setthreadidentity then pcall(setthreadidentity, 2) end
                                    pcall(targetFunc, unpack(args))
                                end
                                hookedFuncs[ourFunc] = true
                                remote.OnClientEvent:Connect(ourFunc)
                            end
                        end
                    end
                end
            end
        end
    end)
    getgenv().updateSword = function()
        refreshSlashName()
        if getgenv().skinChanger and getgenv().swordModel ~= "" and getgenv().saveLastEquippedSword then
            getgenv().saveLastEquippedSword(getgenv().swordModel)
        end
        setSword()
    end
    task.spawn(function()
        while task.wait(1) do
            if getgenv().skinChanger and getgenv().swordModel ~= "" then
                local char = LocalPlayer.Character
                if char then
                    if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then setSword() end
                    if not char:FindFirstChild(getgenv().swordModel) then setSword() end
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("Model") and v.Name ~= getgenv().swordModel then v:Destroy() end
                        task.wait()
                    end
                end
            end
        end
    end)
    LocalPlayer.CharacterAdded:Connect(function()
        if getgenv().skinChanger then
            getgenv().skinChanger = false
            task.wait(2)
            getgenv().skinChanger = true
            task.wait(0.5)
            pcall(function() getgenv().updateSword() end)
        end
    end)
end)

-- ============================================================
-- [14] UNLOCK ALL
-- ============================================================
local UnlockAll = {
    enabled = false, ready = false, shop_controller = nil, shop_api = nil,
    shop = nil, swords = nil, sword_fn = (getgenv()._daemon and getgenv()._daemon.sword_fn) or nil,
    selected_sword = nil, original_sword = nil, explosion_module = nil,
    explosion_original = nil, explosion_hooked = false, selected_explosion = nil,
}
UnlockAll.unlock_originals   = setmetatable({}, { __mode = "k" })
UnlockAll.modern_originals   = setmetatable({}, { __mode = "k" })
UnlockAll.shadow_connections = setmetatable({}, { __mode = "k" })
UnlockAll.unlocked           = {}
UnlockAll.page_connections   = {}
UnlockAll.refresh_generation = {}
UnlockAll.modern_tag         = "daemon_unlock_all"
UnlockAll.original_set_equipped = nil
UnlockAll.original_buy_fns   = {}
UnlockAll.parry_connections  = (getgenv()._daemon and getgenv()._daemon.parry_connections) or {}
UnlockAll.fire_connections   = (getgenv()._daemon and getgenv()._daemon.fire_sword_connections) or {}
UnlockAll.play_parry         = (getgenv()._daemon and getgenv()._daemon.play_parry) or function() end
UnlockAll.chroma_bound       = false
UnlockAll.character_connection = nil
UnlockAll.added_connection   = nil
UnlockAll.sword_attr_connection = nil

local UALocalPlayer = game:GetService("Players").LocalPlayer
local UAReplicatedStorage = game:GetService("ReplicatedStorage")
local UAUserInputService = game:GetService("UserInputService")

local UAConfig = {
    favorite_swords = {}, deleted_swords = {}, favorite_explosions = {}, deleted_explosions = {},
    last_equipped_sword = "", last_equipped_explosion = "",
}
local UA_CONFIG_FILE = "daemon/unlock_all.json"
UAConfig.save = function()
    pcall(function()
        if isfolder and not isfolder("daemon") then makefolder("daemon") end
        local data = {
            favorite_swords = UAConfig.favorite_swords or {}, deleted_swords = UAConfig.deleted_swords or {},
            favorite_explosions = UAConfig.favorite_explosions or {}, deleted_explosions = UAConfig.deleted_explosions or {},
            last_equipped_sword = UAConfig.last_equipped_sword or "", last_equipped_explosion = UAConfig.last_equipped_explosion or "",
        }
        if writefile then writefile(UA_CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data)) end
    end)
end
pcall(function()
    if isfile and isfile(UA_CONFIG_FILE) then
        local raw = readfile(UA_CONFIG_FILE)
        if raw and raw ~= "" then
            local decoded = game:GetService("HttpService"):JSONDecode(raw)
            if type(decoded) == "table" then
                UAConfig.favorite_swords = decoded.favorite_swords or {}
                UAConfig.deleted_swords = decoded.deleted_swords or {}
                UAConfig.favorite_explosions = decoded.favorite_explosions or {}
                UAConfig.deleted_explosions = decoded.deleted_explosions or {}
                UAConfig.last_equipped_sword = decoded.last_equipped_sword or ""
                UAConfig.last_equipped_explosion = decoded.last_equipped_explosion or ""
            end
        end
    end
end)

local function uaToggleConn(conn, enable) pcall(function() if enable then conn:Enable() else conn:Disable() end end) end
function UnlockAll.set_sword_override(arg, on)
    for _, c in ipairs(arg.parry_connections) do uaToggleConn(c, not on) end
    for _, c in ipairs(arg.fire_connections)  do uaToggleConn(c, not on) end
end
function UnlockAll.apply_chroma(arg, swordInst, swordData)
    local colorConfig = swordData.ColorConfig or swordData.TweenColorConfig
    if not colorConfig then
        if swordData.Name:find("Chroma") or swordData.Name:find("Rainbow") then colorConfig = "Chroma" end
    end
    if colorConfig then
        swordInst:SetAttribute("ColorConfig", colorConfig)
        swordInst:AddTag("TweenColor")
    end
end
function UnlockAll.is_fav(arg, itemType, name_)
    if itemType == "Sword" then return UAConfig.favorite_swords and UAConfig.favorite_swords[name_] == true end
    if itemType == "Explosion" then return UAConfig.favorite_explosions and UAConfig.favorite_explosions[name_] == true end
    return false
end
function UnlockAll.is_deleted(arg, itemType, name_)
    if itemType == "Sword" then return UAConfig.deleted_swords and UAConfig.deleted_swords[name_] == true end
    if itemType == "Explosion" then return UAConfig.deleted_explosions and UAConfig.deleted_explosions[name_] == true end
    return false
end
function UnlockAll.native_fav_map(arg)
    if arg.native_map then return arg.native_map end
    if not arg.shop_controller or type(arg.shop_controller._inventoryPages) ~= "table" then return nil end
    for _, page in pairs(arg.shop_controller._inventoryPages) do
        if type(page) == "table" and type(page.MarkDirty) == "function" then
            local ok1, ups1 = pcall(debug.getupvalues, page.MarkDirty)
            if ok1 and type(ups1) == "table" then
                for _, up1 in pairs(ups1) do
                    if type(up1) == "function" then
                        local ok2, ups2 = pcall(debug.getupvalues, up1)
                        if ok2 and type(ups2) == "table" then
                            for _, up2 in pairs(ups2) do
                                if type(up2) == "function" then
                                    local ok3, ups3 = pcall(debug.getupvalues, up2)
                                    if ok3 and type(ups3) == "table" then
                                        for _, up3 in pairs(ups3) do
                                            if type(up3) == "table" and up3.Sword ~= nil and up3.Explosion ~= nil and not up3._virtualItems then
                                                arg.native_map = up3; return up3
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end
function UnlockAll.sync_fav_map(arg, itemType)
    local native = arg:native_fav_map()
    if not native then return end
    local bucket = native[itemType]
    if type(bucket) ~= "table" then return end
    local favs = itemType == "Sword" and UAConfig.favorite_swords or itemType == "Explosion" and UAConfig.favorite_explosions or {}
    for k in pairs(bucket) do if not favs[k] then bucket[k] = nil end end
    for k, v in pairs(favs) do bucket[k] = v and true or nil end
end
function UnlockAll.toggle_fav(arg, itemType, name_)
    if arg:is_deleted(itemType, name_) then return end
    if itemType == "Sword" then
        UAConfig.favorite_swords = UAConfig.favorite_swords or {}
        UAConfig.favorite_swords[name_] = UAConfig.favorite_swords[name_] and nil or true
    elseif itemType == "Explosion" then
        UAConfig.favorite_explosions = UAConfig.favorite_explosions or {}
        UAConfig.favorite_explosions[name_] = UAConfig.favorite_explosions[name_] and nil or true
    end
    pcall(UAConfig.save)
    arg:sync_fav_map(itemType)
    local virt = arg.shop_controller and arg.shop_controller._virtualItems and arg.shop_controller._virtualItems[itemType]
    local pages = arg.shop_controller and arg.shop_controller._inventoryPages and arg.shop_controller._inventoryPages[itemType]
    local isFav = arg:is_fav(itemType, name_)
    if type(virt) == "table" then
        for _, item in ipairs(virt) do
            if item.Name == name_ then
                item.IsFavorited = isFav
                if item.OwnsItem and type(item.OwnsItem.Set) == "function" then pcall(item.OwnsItem.Set, item.OwnsItem, true) end
                local baseOrder = item.OriginalLayoutOrder or item.LayoutOrder or 0
                item.OriginalLayoutOrder = baseOrder
                if isFav then
                    item.LayoutOrder = baseOrder - 1000
                    item.Name_ = "#" .. (item.Name_ or item.Name):gsub("^#", "")
                else
                    item.LayoutOrder = baseOrder
                    item.Name_ = (item.Name_ or item.Name):gsub("^#", "")
                end
                break
            end
        end
    end
    if pages and pages.MarkDirty then pages.MarkDirty(nil, true, true) end
    arg:refresh_selected()
end
function UnlockAll.refresh_shop_item(arg, itemType, name_, owned)
    local virt  = arg.shop_controller and arg.shop_controller._virtualItems[itemType]
    local pages = arg.shop_controller and arg.shop_controller._inventoryPages[itemType]
    if type(virt) == "table" then
        for _, item in ipairs(virt) do
            if item.Name == name_ then
                item.Section = owned and "Owned" or "Unowned"
                if item.OwnsItem and type(item.OwnsItem.Set) == "function" then pcall(item.OwnsItem.Set, item.OwnsItem, owned) end
                if not owned then
                    item.IsFavorited = false
                    item.Name_ = (item.Name_ or item.Name):gsub("^#", "")
                    item.LayoutOrder = item.OriginalLayoutOrder or item.LayoutOrder or 0
                end
                if pages and pages.MarkDirty then pages.MarkDirty(item, false, true) end
                break
            end
        end
    end
    if pages and pages.MarkDirty then pages.MarkDirty(nil, true, true) end
end
function UnlockAll.delete_item(arg, itemType, name_)
    if itemType == "Sword" then
        UAConfig.deleted_swords = UAConfig.deleted_swords or {}
        UAConfig.deleted_swords[name_] = true
        if UAConfig.favorite_swords then UAConfig.favorite_swords[name_] = nil end
        if arg.selected_sword == name_ then arg:restore_sword() end
    elseif itemType == "Explosion" then
        UAConfig.deleted_explosions = UAConfig.deleted_explosions or {}
        UAConfig.deleted_explosions[name_] = true
        if UAConfig.favorite_explosions then UAConfig.favorite_explosions[name_] = nil end
        if arg.selected_explosion == name_ then arg.selected_explosion = nil end
    end
    pcall(UAConfig.save)
    arg:sync_fav_map(itemType)
    if arg.shop_controller then arg:refresh_shop_item(itemType, name_, false) end
    arg:refresh_selected()
end
function UnlockAll.undelete_item(arg, itemType, name_)
    if itemType == "Sword" and UAConfig.deleted_swords then UAConfig.deleted_swords[name_] = nil
    elseif itemType == "Explosion" and UAConfig.deleted_explosions then UAConfig.deleted_explosions[name_] = nil end
    pcall(UAConfig.save)
    arg:sync_fav_map(itemType)
    if arg.shop_controller then arg:refresh_shop_item(itemType, name_, true) end
    arg:refresh_selected()
end
function UnlockAll.equip_sword(arg, name_, restoring)
    if not arg.swords then return false end
    if not restoring and arg:is_deleted("Sword", name_) then arg:undelete_item("Sword", name_) end
    local sword = arg.swords:GetSword(name_)
    if not sword then return false end
    local char = UALocalPlayer.Character
    if not char then return false end
    if not restoring and not arg.original_sword then
        arg.original_sword = UALocalPlayer:GetAttribute("CurrentlyEquippedSword") or char:GetAttribute("CurrentlyEquippedSword")
    end
    if restoring then arg.selected_sword = nil
    else
        arg.selected_sword = sword.Name
        UAConfig.last_equipped_sword = sword.Name
        arg:set_sword_override(true)
    end
    UALocalPlayer:SetAttribute("CurrentlyEquippedSword", sword.Name)
    char:SetAttribute("CurrentlyEquippedSword", sword.Name)
    pcall(function()
        local eq = arg.swords.EquipSwordTo
        for k, v in debug.getupvalues(eq) do
            if v == true then debug.setupvalue(eq, k, false); break end
        end
    end)
    if not pcall(function() arg.swords:EquipSwordTo(char, sword.Name) end) then return false end
    local inst = char:FindFirstChild(sword.Name)
    if inst then arg:apply_chroma(inst, sword) end
    if arg.sword_fn then pcall(arg.sword_fn, sword.Name) end
    return true
end
function UnlockAll.restore_sword(arg)
    if arg.original_sword and arg.original_sword ~= "" then arg:equip_sword(arg.original_sword, true)
    else arg.selected_sword = nil end
    arg.original_sword = nil
    arg:set_sword_override(false)
end
function UnlockAll.ensure_explosion_wrap(arg)
    if arg.explosion_hooked or not arg.explosion_module then return end
    arg.explosion_hooked = true
    arg.explosion_original = arg.explosion_module.PlayExplosion
    arg.explosion_module.PlayExplosion = function(a, b, c, d, e, f, g)
        if UnlockAll.enabled and UnlockAll.selected_explosion and UnlockAll.selected_explosion ~= "" and g and f == UALocalPlayer.Character then
            b = UnlockAll.selected_explosion
        end
        return UnlockAll.explosion_original(a, b, c, d, e, f, g)
    end
end
function UnlockAll.equip_explosion(arg, name_)
    if arg:is_deleted("Explosion", name_) then arg:undelete_item("Explosion", name_) end
    arg.selected_explosion = name_
    UAConfig.last_equipped_explosion = name_
    arg:ensure_explosion_wrap()
    return true
end
function UnlockAll.bind_shadow(arg, itemType, shadow)
    if arg.shadow_connections[shadow] then return end
    local function hide()
        if arg.unlocked[itemType] and shadow.Parent and shadow.Enabled then shadow.Enabled = false end
    end
    arg.shadow_connections[shadow] = shadow:GetPropertyChangedSignal("Enabled"):Connect(hide)
    hide()
end
function UnlockAll.refresh_visuals(arg, itemType)
    if not arg.shop_controller then return end
    local page = arg.shop_controller._inventoryPages[itemType]
    local virt = arg.shop_controller._virtualItems[itemType]
    if not page or not page.Scroll or type(virt) ~= "table" then return end
    if not arg.page_connections[itemType] and page.ScrollingFrame then
        arg.page_connections[itemType] = page.ScrollingFrame.DescendantAdded:Connect(function(desc)
            if desc:IsA("GuiObject") then
                task.defer(function()
                    arg:slot_fav_visual(itemType, desc)
                    local shadow = desc:FindFirstChild("Shadow") or (desc.Name == "Shadow" and desc)
                    if shadow and arg.unlocked[itemType] then arg:bind_shadow(itemType, shadow) end
                end)
            end
        end)
    end
    task.defer(function()
        for _, item in ipairs(virt) do
            local ok, slot = pcall(page.Scroll.GetRenderedSlot, item)
            if ok and slot then
                arg:slot_fav_visual(itemType, slot)
                local shadow = slot:FindFirstChild("Shadow")
                if shadow then
                    if arg.unlocked[itemType] then arg:bind_shadow(itemType, shadow)
                    else shadow.Enabled = not item.OwnsItem:Get() end
                end
            end
        end
    end)
end
function UnlockAll.slot_fav_visual(arg, itemType, slot)
    if not slot or not slot:IsA("GuiObject") then return end
    local name_ = slot:GetAttribute("Name")
    if not name_ or name_ == "" then return end
    local isFav = arg:is_fav(itemType, name_)
    local favIcon = slot:FindFirstChild("Favorited")
    if favIcon and favIcon:IsA("ImageLabel") then
        favIcon.Visible = isFav
        if isFav then favIcon.Image = "rbxassetid://15697987058" end
    end
    local shadow = slot:FindFirstChild("Shadow")
    if shadow and arg.unlocked[itemType] then shadow.Enabled = false end
end
function UnlockAll.set_category_unlock(arg, itemType, on)
    if not arg.shop_controller then return end
    if on then arg:sync_fav_map(itemType) end
    local virt  = arg.shop_controller._virtualItems[itemType]
    local pages = arg.shop_controller._inventoryPages[itemType]
    if type(virt) ~= "table" then return end
    if pages and pages.BeginBatch then pages:BeginBatch() end
    if on then
        arg.unlocked[itemType] = true
        local withKey = {}
        for _, item in ipairs(virt) do if item.InventoryKey then withKey[item.Name] = true end end
        for _, item in ipairs(virt) do
            if not arg.unlock_originals[item] then
                arg.unlock_originals[item] = { Section = item.Section, ForceHide = item.ForceHide, OriginalLayoutOrder = item.OriginalLayoutOrder or item.LayoutOrder }
            end
            local deleted = arg:is_deleted(itemType, item.Name)
            local section = deleted and "Unowned" or "Owned"
            local changed = false
            if item.Section ~= section then item.Section = section; changed = true end
            if item.OwnsItem and type(item.OwnsItem.Set) == "function" then pcall(item.OwnsItem.Set, item.OwnsItem, not deleted) end
            local isFav = not deleted and arg:is_fav(itemType, item.Name)
            item.IsFavorited = isFav
            local baseOrder = item.OriginalLayoutOrder or item.LayoutOrder or 0
            item.OriginalLayoutOrder = baseOrder
            local newOrder = baseOrder - (isFav and 1000 or 0)
            if item.LayoutOrder ~= newOrder then item.LayoutOrder = newOrder; changed = true end
            if isFav then
                local newName = "#" .. (item.Name_ or item.Name):gsub("^#", "")
                if item.Name_ ~= newName then item.OriginalName_ = item.OriginalName_ or item.Name_; item.Name_ = newName; changed = true end
            else
                local newName = (item.Name_ or item.Name):gsub("^#", "")
                if item.Name_ ~= newName then item.Name_ = newName; changed = true end
            end
            local forceHide = (not item.InventoryKey) and withKey[item.Name] or false
            if item.ForceHide ~= forceHide then item.ForceHide = forceHide; changed = true end
            if changed and pages and pages.MarkDirty then pages.MarkDirty(item, false, true) end
        end
    else
        arg.unlocked[itemType] = nil
        for _, item in ipairs(virt) do
            local orig = arg.unlock_originals[item]
            if orig then
                local changed = false
                if item.Section ~= orig.Section then item.Section = orig.Section; changed = true end
                if item.ForceHide ~= orig.ForceHide then item.ForceHide = orig.ForceHide; changed = true end
                if changed and pages and pages.MarkDirty then pages.MarkDirty(item, false, true) end
                arg.unlock_originals[item] = nil
            end
        end
    end
    if pages and pages.MarkDirty then pages.MarkDirty(nil, true, true) end
    if pages and pages.EndBatch then pages:EndBatch() end
    arg:refresh_visuals(itemType)
end
function UnlockAll.expected_size(arg, itemType)
    if itemType == "Sword" and arg.swords then
        local ok, coll = pcall(function() return arg.swords:GetCollection() end)
        if ok and type(coll) == "table" then
            local n = 0; for _ in pairs(coll) do n = n + 1 end; return n
        end
        return 0
    end
    if itemType == "Explosion" then
        local misc = UAReplicatedStorage:FindFirstChild("Misc")
        misc = misc and misc:FindFirstChild("DataExplosions")
        if misc then
            local n = 0
            for _, c in ipairs(misc:GetChildren()) do if not c:GetAttribute("Hidden") then n = n + 1 end end
            return n
        end
    end
    return 0
end
function UnlockAll.schedule_refresh(arg, itemType)
    arg.refresh_generation[itemType] = (arg.refresh_generation[itemType] or 0) + 1
    local gen = arg.refresh_generation[itemType]
    if type(arg.shop_controller._loadInventoryPage) == "function" then pcall(arg.shop_controller._loadInventoryPage, itemType) end
    task.spawn(function()
        local expected = arg:expected_size(itemType)
        local lastCount = -1
        local stableCount = 0
        for _ = 1, 120 do
            game:GetService("RunService").Heartbeat:Wait()
            if not arg.enabled or not arg.unlocked[itemType] or arg.refresh_generation[itemType] ~= gen then return end
            local virt = arg.shop_controller._virtualItems[itemType]
            local count = 0
            if type(virt) == "table" then
                for _, item in ipairs(virt) do if not item.InventoryKey then count = count + 1 end end
            end
            if count == lastCount and count > 0 then stableCount = stableCount + 1
            else stableCount = 0; lastCount = count end
            if (expected > 0 and count >= expected) or (expected == 0 and stableCount >= 5) then
                game:GetService("RunService").Heartbeat:Wait()
                arg:set_category_unlock(itemType, true)
                return
            end
        end
        if arg.enabled and arg.unlocked[itemType] and arg.refresh_generation[itemType] == gen then
            arg:set_category_unlock(itemType, true)
        end
    end)
end
function UnlockAll.refresh_selected(arg)
    if not arg.shop_controller or not arg.shop then return end
    local sel = arg.shop_controller._selectedItem
    if not sel then return end
    local buyBtn = arg.shop.Holder.InfoBG:FindFirstChild("BuyButton")
    local favBtn = arg.shop.Holder:FindFirstChild("Favorite")
    local delBtn = arg.shop.Holder.InfoBG:FindFirstChild("Delete")
    if not (arg.enabled and arg.unlocked[sel.type] and (sel.type == "Sword" or sel.type == "Explosion")) then return end
    local virt = arg.shop_controller._virtualItems and arg.shop_controller._virtualItems[sel.type]
    local entry = virt and virt[sel.key or sel.name]
    local deleted = arg:is_deleted(sel.type, sel.name)
    local isUnowned = entry and entry.Section == "Unowned"
    if deleted or isUnowned then
        if buyBtn then buyBtn.Visible = false end
        if favBtn then favBtn.Visible = false end
        if delBtn then delBtn.Visible = true end
        return
    end
    if buyBtn then
        buyBtn.Visible = true
        if buyBtn:FindFirstChild("PriceTag") then
            local tl = buyBtn.PriceTag:FindFirstChild("TextLabel")
            local pr = buyBtn.PriceTag:FindFirstChild("Price")
            if tl then tl.Visible = true; tl.Text = "Equip" end
            if pr then pr.Visible = false end
        end
    end
    if favBtn then
        favBtn.Visible = true
        local isFav = arg:is_fav(sel.type, sel.name)
        favBtn.Image = isFav and "rbxassetid://15697987058" or "rbxassetid://15697981750"
        favBtn.HoverImage = isFav and "rbxassetid://15697983062" or "rbxassetid://15697987058"
    end
    if delBtn then delBtn.Visible = true end
end
function UnlockAll.set_modern_unlock(arg, itemType, on)
    local api = arg.shop_api
    local ownedBases = api and api.OwnedBases and api.OwnedBases[itemType]
    if type(ownedBases) ~= "table" then return end
    for name_, base in pairs(ownedBases) do
        local ok1, key = pcall(api.ParseItemKey, api, itemType, { Name = name_ })
        key = ok1 and key
        local ownedCopies = nil
        if key then
            local ok2, data = pcall(api.GetItemData, api, itemType, key)
            if ok2 and type(data) == "table" then ownedCopies = data.OwnedCopies end
        end
        local canSet = on and ownedCopies and type(ownedCopies.Get) == "function" and type(ownedCopies.Set) == "function"
        if canSet then
            if not arg.modern_originals[ownedCopies] then
                local ok3, val = pcall(ownedCopies.Get, ownedCopies)
                if ok3 then arg.modern_originals[ownedCopies] = { Value = val } end
            end
            local ok3, val = pcall(ownedCopies.Get, ownedCopies)
            if ok3 and (type(val) ~= "number" or val < 1) then pcall(ownedCopies.Set, ownedCopies, 1) end
        end
        if base and type(base.SetTag) == "function" then pcall(base.SetTag, base, arg.modern_tag, on and true or nil) end
        if not on and ownedCopies then
            local orig = arg.modern_originals[ownedCopies]
            if orig and type(ownedCopies.Set) == "function" then
                local state = base and base.State
                local hasGet = state and type(state.Get) == "function"
                local isEquipped = false
                if hasGet then local ok4, v = pcall(state.Get, state); isEquipped = ok4 and v == true end
                if not isEquipped then pcall(ownedCopies.Set, ownedCopies, orig.Value) end
                arg.modern_originals[ownedCopies] = nil
            end
        end
    end
end
function UnlockAll.hook_modern_shop(arg)
    local api = arg.shop_api
    if not api or arg.original_set_equipped then return end
    if type(api.SetEquipped) ~= "function" then return end
    arg.original_set_equipped = api.SetEquipped
    api.SetEquipped = function(self, ...)
        local args = { ... }
        local itemType = args[1]
        local name_ = args[2]
        if type(itemType) == "table" then name_ = itemType.Name; itemType = itemType.ItemType
        elseif type(name_) == "table" then name_ = name_.Name end
        local bases = api.OwnedBases
        local valid = type(bases) == "table" and bases[itemType]
        local isOwned = type(valid) == "table" and valid[name_] ~= nil
        if UnlockAll.enabled and (isOwned or itemType == "Sword" or itemType == "Explosion") then
            local isSword = itemType == "Sword" or tostring(itemType):lower():find("sword")
            if isSword and UnlockAll:equip_sword(name_, false) then return true end
            local isExplosion = itemType == "Explosion" or tostring(itemType):lower():find("explosion")
            if isExplosion then return UnlockAll:equip_explosion(name_) end
        end
        return UnlockAll.original_set_equipped(self, unpack(args))
    end
end
function UnlockAll.hook_shop(arg)
    local shop = UALocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Shop")
    local holder = shop and shop:FindFirstChild("Holder")
    local infoBG = holder and holder:FindFirstChild("InfoBG")
    local buyBtn = infoBG and infoBG:FindFirstChild("BuyButton")
    if not shop or not buyBtn then return false end
    arg.shop = shop
    for _, c in ipairs(getconnections(buyBtn.Activated)) do
        if c and c.Function then table.insert(arg.original_buy_fns, c.Function); c:Disable() end
    end
    local favBtn = holder:FindFirstChild("Favorite")
    if favBtn then
        for _, c in ipairs(getconnections(favBtn.Activated)) do if c and c.Function then c:Disable() end end
        favBtn.Activated:Connect(function()
            local sel = arg.shop_controller and arg.shop_controller._selectedItem
            if sel and arg.enabled and (sel.type == "Sword" or sel.type == "Explosion") then arg:toggle_fav(sel.type, sel.name) end
        end)
    end
    local delBtn = infoBG:FindFirstChild("Delete")
    if delBtn then
        for _, c in ipairs(getconnections(delBtn.Activated)) do if c and c.Function then c:Disable() end end
        delBtn.Activated:Connect(function()
            local sel = arg.shop_controller and arg.shop_controller._selectedItem
            if not sel or not arg.enabled then return end
            if sel.type ~= "Sword" and sel.type ~= "Explosion" then return end
            if arg:is_deleted(sel.type, sel.name) then arg:undelete_item(sel.type, sel.name)
            else arg:delete_item(sel.type, sel.name) end
        end)
    end
    game:GetService("GuiService"):GetPropertyChangedSignal("SelectedObject"):Connect(function()
        if not arg.enabled or not arg.shop or not arg.shop.Enabled then return end
        task.defer(function() arg:refresh_selected() end)
    end)
    UAUserInputService.InputBegan:Connect(function(input, gp)
        if gp or not arg.enabled or not arg.shop or not arg.shop.Enabled or input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
        local sel = arg.shop_controller and arg.shop_controller._selectedItem
        if not sel then return end
        if input.KeyCode == Enum.KeyCode.ButtonY then
            if sel.type == "Sword" or sel.type == "Explosion" then arg:toggle_fav(sel.type, sel.name) end
        elseif input.KeyCode == Enum.KeyCode.ButtonX then
            if sel.type == "Sword" or sel.type == "Explosion" then
                if arg:is_deleted(sel.type, sel.name) then arg:undelete_item(sel.type, sel.name)
                else arg:delete_item(sel.type, sel.name) end
            end
        elseif input.KeyCode == Enum.KeyCode.ButtonA then
            local ib = arg.shop:FindFirstChild("Holder"); ib = ib and ib:FindFirstChild("InfoBG"); ib = ib and ib:FindFirstChild("BuyButton")
            if sel.type == "Sword" then
                arg:equip_sword(sel.name, false)
                if ib and ib:FindFirstChild("PriceTag") and ib.PriceTag:FindFirstChild("TextLabel") then ib.PriceTag.TextLabel.Text = "Equipped" end
            elseif sel.type == "Explosion" then
                arg:equip_explosion(sel.name)
                if ib and ib:FindFirstChild("PriceTag") and ib.PriceTag:FindFirstChild("TextLabel") then ib.PriceTag.TextLabel.Text = "Equipped" end
            end
        end
    end)
    arg.shop_controller.itemSelected:Connect(function(item)
        if item and arg.unlocked[item.type] then arg:set_category_unlock(item.type, true) end
        task.defer(function() arg:refresh_selected() end)
    end)
    buyBtn.Activated:Connect(function()
        local sel = arg.shop_controller._selectedItem
        if not sel then return end
        if arg.enabled and arg.unlocked[sel.type] then
            if arg:is_deleted(sel.type, sel.name) then arg:undelete_item(sel.type, sel.name) end
            if sel.type == "Sword" then
                if arg:equip_sword(sel.name, false) then buyBtn.PriceTag.TextLabel.Text = "Equipped" end
                return
            elseif sel.type == "Explosion" then
                arg:equip_explosion(sel.name); buyBtn.PriceTag.TextLabel.Text = "Equipped"; return
            end
        end
        for _, fn in ipairs(arg.original_buy_fns) do task.spawn(fn) end
    end)
    local function reapply()
        if not arg.shop.Enabled or not arg.enabled then return end
        for _, t in ipairs({ "Sword", "Explosion" }) do if arg.unlocked[t] then arg:schedule_refresh(t) end end
    end
    arg.shop:GetPropertyChangedSignal("Enabled"):Connect(function() if arg.shop.Enabled then task.defer(reapply) end end)
    if arg.shop.Enabled then task.defer(reapply) end
    return true
end
function UnlockAll.hook_sword_fx(arg)
    local shared = UAReplicatedStorage:FindFirstChild("Shared")
    shared = shared and shared:FindFirstChild("ReplicatedInstances"); shared = shared and shared:FindFirstChild("Swords")
    if shared then local ok, swords = pcall(require, shared); if ok then arg.swords = swords end end
    local rem = UAReplicatedStorage:FindFirstChild("Remotes"); rem = rem and rem:FindFirstChild("ParrySuccessAll")
    if rem then
        rem.OnClientEvent:Connect(function(...)
            if not arg.enabled or not arg.selected_sword or not arg.play_parry then return end
            local args = { ... }
            local sword = arg.swords and arg.swords:GetSword(arg.selected_sword)
            if sword and args[4] and tostring(args[4]) == UALocalPlayer.Name then
                args[1] = sword.SlashName; args[3] = sword.Name
            end
            return arg.play_parry(unpack(args))
        end)
    end
end
function UnlockAll.setup_character(arg, char)
    if arg.character_connection then pcall(function() arg.character_connection:Disconnect() end); arg.character_connection = nil end
    if not char then return end
    if arg.enabled and UAConfig.last_equipped_sword and UAConfig.last_equipped_sword ~= "" then
        task.defer(function() if arg.enabled and UAConfig.last_equipped_sword ~= "" then arg:equip_sword(UAConfig.last_equipped_sword, false) end end)
    end
    local function onChild(child)
        if not arg.enabled or not child:IsA("Model") or not arg.swords or not arg.selected_sword then return end
        local sword = arg.swords:GetSword(child.Name)
        if not sword then return end
        if child.Name ~= arg.selected_sword then
            local want = arg.selected_sword
            task.defer(function() if arg.enabled and arg.selected_sword == want then arg:equip_sword(want, false) end end)
        else
            arg:apply_chroma(child, sword)
            if arg.sword_fn then
                task.defer(function() if arg.enabled and arg.selected_sword == child.Name then pcall(arg.sword_fn, child.Name) end end)
            end
        end
    end
    arg.character_connection = char.ChildAdded:Connect(onChild)
    for _, c in ipairs(char:GetChildren()) do onChild(c) end
end
function UnlockAll.hook_chroma(arg)
    if arg.chroma_bound then return end
    arg.chroma_bound = true
    arg.added_connection = UALocalPlayer.CharacterAdded:Connect(function(c) arg:setup_character(c) end)
    if UALocalPlayer.Character then task.defer(function() arg:setup_character(UALocalPlayer.Character) end) end
    arg.sword_attr_connection = UALocalPlayer:GetAttributeChangedSignal("CurrentlyEquippedSword"):Connect(function()
        local sel = arg.selected_sword
        if not arg.enabled or not sel then return end
        if UALocalPlayer:GetAttribute("CurrentlyEquippedSword") == sel then return end
        UALocalPlayer:SetAttribute("CurrentlyEquippedSword", sel)
        if UALocalPlayer.Character then UALocalPlayer.Character:SetAttribute("CurrentlyEquippedSword", sel) end
        if arg.sword_fn then pcall(arg.sword_fn, sel) end
    end)
end
function UnlockAll.initialize(arg)
    local ui = UAReplicatedStorage.Controllers:FindFirstChild("UI")
    local shopCtrl = ui and ui:FindFirstChild("ShopController")
    local shopApi = ui and ui:FindFirstChild("ShopControllerAPI")
    local ok1, modCtrl = pcall(require, shopCtrl)
    local ok2, modApi = pcall(require, shopApi)
    if not ok1 or type(modCtrl) ~= "table" then modCtrl = nil end
    if not ok2 or type(modApi) ~= "table" then modApi = nil end
    if not modCtrl and not modApi then return end
    arg.shop_controller = modCtrl
    arg.shop_api = modApi
    arg:hook_sword_fx()
    arg:hook_chroma()
    pcall(function() arg.explosion_module = require(UAReplicatedStorage.Controllers.VFXController) end)
    arg:ensure_explosion_wrap()
    if arg.shop_controller then arg:hook_shop() end
    if arg.shop_api then arg:hook_modern_shop() end
    arg.ready = true
    arg:set_enabled(arg.enabled)
    if arg.enabled and UAConfig.last_equipped_sword and UAConfig.last_equipped_sword ~= "" then
        task.defer(function() if arg.enabled and UAConfig.last_equipped_sword ~= "" then arg:equip_sword(UAConfig.last_equipped_sword, false) end end)
    end
    if arg.enabled and UAConfig.last_equipped_explosion and UAConfig.last_equipped_explosion ~= "" then
        task.defer(function() if arg.enabled and UAConfig.last_equipped_explosion ~= "" then arg:equip_explosion(UAConfig.last_equipped_explosion) end end)
    end
end
function UnlockAll.set_enabled(arg, on)
    arg.enabled = on == true
    if not arg.ready then return end
    for _, itemType in ipairs({ "Sword", "Explosion" }) do
        if arg.enabled then
            if arg.shop_controller then arg:set_category_unlock(itemType, true); arg:schedule_refresh(itemType) end
            arg:set_modern_unlock(itemType, true)
        else
            if arg.shop_controller then
                arg.refresh_generation[itemType] = (arg.refresh_generation[itemType] or 0) + 1
                arg:set_category_unlock(itemType, false)
            end
            arg:set_modern_unlock(itemType, false)
        end
    end
    if not arg.enabled then arg:restore_sword(); arg.selected_explosion = nil
    else arg:refresh_selected() end
end
getgenv().UnlockAll = UnlockAll

task.spawn(function()
    repeat task.wait(0.5) until game:IsLoaded()
    task.wait(2)
    pcall(function() UnlockAll:initialize() end)
    if _G.config.unlock_all then pcall(function() UnlockAll:set_enabled(true) end) end
end)

-- ============================================================
-- [15] ABILITY EXPLOITS + COOLDOWN PROTECTION
-- ============================================================
getgenv().AbilityExploit = _G.config.m_AbilityExploitToggle == true
getgenv().ThunderDashNoCooldown = _G.config.m_ThunderDashToggle == true
getgenv().SuperJumpNoCooldown = _G.config.m_SuperJumpToggle == true
getgenv().DashNoCooldown = _G.config.m_DashNoCooldownToggle == true
getgenv().CooldownProtection = _G.config.m_CooldownProtectionToggle == true

local _abil_conns = { thunder = nil, sjump = nil, dash = nil }
local function _abil_apply_zero(name)
    if not getgenv().AbilityExploit then return end
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local abilities = shared and shared:FindFirstChild("Abilities")
    local m = abilities and abilities:FindFirstChild(name)
    if not m then return end
    local ok, mod = pcall(require, m)
    if ok and mod then pcall(function() mod.cooldown = 0; mod.cooldownReductionPerUpgrade = 0 end) end
end
local function _abil_start(key, moduleName, flag)
    if _abil_conns[key] then return end
    _abil_conns[key] = RunService.Heartbeat:Connect(function()
        if getgenv().AbilityExploit and getgenv()[flag] then _abil_apply_zero(moduleName) end
    end)
end
local function _abil_stop(key)
    if _abil_conns[key] then _abil_conns[key]:Disconnect(); _abil_conns[key] = nil end
end
local function _abil_activate_all()
    if getgenv().ThunderDashNoCooldown then _abil_apply_zero("Thunder Dash"); _abil_start("thunder", "Thunder Dash", "ThunderDashNoCooldown") end
    if getgenv().SuperJumpNoCooldown then _abil_apply_zero("Super Jump"); _abil_start("sjump", "Super Jump", "SuperJumpNoCooldown") end
    if getgenv().DashNoCooldown then _abil_apply_zero("Dash"); _abil_start("dash", "Dash", "DashNoCooldown") end
end
local function _abil_deactivate_all() _abil_stop("thunder"); _abil_stop("sjump"); _abil_stop("dash") end

getgenv().OnAbilMaster = function(v)
    getgenv().AbilityExploit = v
    if v then _abil_activate_all() else _abil_deactivate_all() end
end

local _cp_grad = nil
RunService.PreSimulation:Connect(function()
    if not getgenv().CooldownProtection then return end
    local grad = _cp_grad
    if not (grad and grad.Parent) then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hotbar = pg and pg:FindFirstChild("Hotbar")
        local block = hotbar and hotbar:FindFirstChild("Block")
        grad = block and block:FindFirstChild("UIGradient")
        _cp_grad = grad
    end
    if grad and grad.Offset.Y < 0.4 then
        pcall(function() ReplicatedStorage.Remotes.AbilityButtonPress:Fire() end)
    end
end)

task.defer(function() if getgenv().AbilityExploit then pcall(_abil_activate_all) end end)

-- ============================================================
-- [16] AUTO ABILITY
-- ============================================================
getgenv().AutoAbility = false
getgenv().AutoAbilityRange = 20
getgenv().AutoAbilityMinSpeed = 100

task.spawn(function()
    RunService.PreSimulation:Connect(function()
        if not getgenv().AutoAbility then return end
        if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        local ball = BallHelper.get_ball()
        if not ball then return end
        local z = ball:FindFirstChild("zoomies")
        if not z then return end
        local speed = z.VectorVelocity.Magnitude
        if speed < (getgenv().AutoAbilityMinSpeed or 100) then return end
        local dist = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
        if dist > (getgenv().AutoAbilityRange or 20) then return end
        pcall(function() ReplicatedStorage.Remotes.AbilityButtonPress:Fire() end)
    end)
end)

-- ============================================================
-- [17] AUTO PARRY HOOK
-- ============================================================
getgenv().OnAutoParryToggle = function(enabled)
    _G.config.auto_parry = enabled
    if Connections.auto_parry then
        Connections.auto_parry:Disconnect()
        Connections.auto_parry = nil
    end
    if enabled then
        Connections.auto_parry = RunService.PreSimulation:Connect(function()
            if _G.triggerbot then return end
            if _G.singularity_active then parryCount = 0; return end
            if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then parryCount = 0; return end
            if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
            local props = BallHelper.ball.properties
            local realBall = BallHelper.get_ball()
            local allBalls = BallHelper.get_balls()
            for _, ball in allBalls do
                if not ball then return end
                local zoomies = ball:FindFirstChild("zoomies")
                if not zoomies then return end
                ball:GetAttributeChangedSignal("target"):Once(function()
                    parryBallCooldown[ball] = nil
                    if _G.config.random_target then pick_random_target() end
                end)
                if parryBallCooldown[ball] then continue end
                local ballTarget = ball:GetAttribute("target")
                local realBallTarget = realBall and realBall:GetAttribute("target")
                local velocity = zoomies.VectorVelocity
                local _ballPos = BallHelper.ball_position(ball)
                local distance = (LocalPlayer.Character.PrimaryPart.Position - _ballPos).Magnitude
                local rawPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                local pingBase = math.clamp(rawPing / 10, 5, 17)
                local rawSpeed = velocity.Magnitude
                local speedAdjusted = math.min(math.max(rawSpeed - 9.5, 0), 650)
                local speedCoefficient = 2.4 + speedAdjusted * 0.002
                local accuracyFactor = accuracyMultiplier
                local scaledAg = speedCoefficient * accuracyMultiplier
                local baseTargetDistance = pingBase + math.max(rawSpeed / scaledAg, 9.5)
                local _hrp = LocalPlayer.Character.PrimaryPart
                local _toPlayerUnit = (_hrp.Position - _ballPos).Unit
                local _ballClosing = velocity:Dot(_toPlayerUnit)
                local _playerVel = _hrp.AssemblyLinearVelocity or Vector3.zero
                local _playerVelFlat = Vector3.new(_playerVel.X, 0, _playerVel.Z)
                local _playerClosing = -(_playerVelFlat:Dot(_toPlayerUnit))
                local _totalClosing = _ballClosing + _playerClosing
                local _closingForMult = _totalClosing
                if _closingForMult < 0 then _closingForMult = _ballClosing end
                local _velMultRaw = math.clamp(_closingForMult / math.max(rawSpeed, 1), 0.9, 1.5)
                getgenv()._velMultEMA = getgenv()._velMultEMA or setmetatable({}, {__mode = "k"})
                local _vmePrev = getgenv()._velMultEMA[ball] or _velMultRaw
                local _velMult = _vmePrev + (_velMultRaw - _vmePrev) * 0.4
                getgenv()._velMultEMA[ball] = _velMult
                local _pingSamples = getgenv()._etaPingSamples
                if not _pingSamples then _pingSamples = {}; getgenv()._etaPingSamples = _pingSamples end
                table.insert(_pingSamples, rawPing)
                if #_pingSamples > 20 then table.remove(_pingSamples, 1) end
                local _jitter = 0
                if #_pingSamples >= 5 then
                    local _mean = 0
                    for _, p in ipairs(_pingSamples) do _mean = _mean + p end
                    _mean = _mean / #_pingSamples
                    local _var = 0
                    for _, p in ipairs(_pingSamples) do _var = _var + (p - _mean) ^ 2 end
                    _var = _var / #_pingSamples
                    _jitter = math.clamp(math.sqrt(_var), 0, 80)
                end
                getgenv()._etaJitterBuffer = _jitter / 1000
                local _jitterStuds = (_jitter / 1000) * rawSpeed
                local _buckets = getgenv()._etaSpeedBuckets
                if not _buckets then
                    _buckets = { slow = { mult = 0.95 }, mid  = { mult = 1.0 }, fast = { mult = 1.2 } }
                    getgenv()._etaSpeedBuckets = _buckets
                end
                local _bucketName = rawSpeed < 150 and "slow" or (rawSpeed < 350 and "mid" or "fast")
                local _bucketMult = (_buckets[_bucketName] and _buckets[_bucketName].mult) or 1.0
                local targetDistance = (baseTargetDistance * _velMult * _bucketMult) + _jitterStuds
                local _fb = getgenv()._etaFeedback
                local _ftMax = (_fb and _fb.ftMax) or 0.21
                local _ftMin = (_fb and _fb.ftMin) or 0.17
                local _clampBasis = rawSpeed * _velMult
                local _maxDist = _clampBasis * _ftMax
                local _minDist = _clampBasis * _ftMin
                if targetDistance > _maxDist then targetDistance = _maxDist end
                if targetDistance < _minDist then targetDistance = _minDist end
                targetDistance = targetDistance + (tonumber(getgenv().ParryRange) or 0)
                local isCurving = BallHelper.ball_curved(ball)
                if ballTarget == LocalPlayer.Name and isCurving then continue end
                if ball:FindFirstChild("AeroDynamicSlashVFX") then
                    Debris:AddItem(ball.AeroDynamicSlashVFX, 0)
                    props.aerodynamic_time = tick()
                end
                if workspace.Runtime:FindFirstChild("Tornado") then
                    local tornadoTime = workspace.Runtime.Tornado:GetAttribute("TornadoTime") or 1
                    if (tick() - props.aerodynamic_time) < tornadoTime + 0.314159 then return end
                end
                getgenv()._tsunamiState = getgenv()._tsunamiState or { active_until = 0, last = setmetatable({}, {__mode = "k"}) }
                getgenv()._tsunamiFeedback = getgenv()._tsunamiFeedback or { fires = 0, successes = 0, windowMax = 0.35, windowMin = 0.18, marginBase = 10, marginSpeedScale = 0.04 }
                local _ts = getgenv()._tsunamiState
                local _tsfb = getgenv()._tsunamiFeedback
                local _nowTs = tick()
                local _prevTs = _ts.last[ball]
                local _durMult = 1.3
                if rawSpeed >= 950 then
                    _ts.active_until = _nowTs + math.clamp((distance / math.max(rawSpeed, 100)) * _durMult, 0.5, 3.0)
                elseif _prevTs then
                    local _dtTs = _nowTs - _prevTs.at
                    local _dvTs = math.abs(rawSpeed - _prevTs.speed)
                    if _dtTs > 0 and _dtTs < 0.35 and _dvTs >= 400 then
                        _ts.active_until = _nowTs + math.clamp((distance / math.max(rawSpeed, 100)) * _durMult, 0.5, 3.0)
                    end
                end
                _ts.last[ball] = { speed = rawSpeed, at = _nowTs }
                getgenv()._spike = getgenv()._spike or { active_until = 0, last = setmetatable({}, {__mode = "k"}), fires = 0, successes = 0, win = 0.20, lastFireAt = 0 }
                local _spk = getgenv()._spike
                local _spkPrev = _spk.last[ball]
                local _spkDt = _spkPrev and (_nowTs - _spkPrev.at) or 999
                local _spkPrevSpeed = _spkPrev and _spkPrev.speed or 0
                if rawSpeed >= 1000 and _spkPrevSpeed <= 600 and _spkDt < 0.5 then
                    _spk.active_until = _nowTs + math.clamp((distance / math.max(rawSpeed, 100)) + 0.3, 0.6, 3.0)
                end
                _spk.last[ball] = { speed = rawSpeed, at = _nowTs }
                local _tsunamiActive = _nowTs < _ts.active_until
                local _spikeActive = _nowTs < _spk.active_until
                if realBallTarget == LocalPlayer.Name and isCurving and not _tsunamiActive and not _spikeActive then return end
                local _fireOk = false
                local _firePath = "distance"
                if _spikeActive then
                    _firePath = "spike"
                    local _closingSpeed = math.max(_totalClosing, 1)
                    local _etaSpk = math.max(0, distance / _closingSpeed - (rawPing / 1000))
                    local _closingRatio = _totalClosing / math.max(rawSpeed, 1)
                    _fireOk = _etaSpk <= _spk.win and _closingRatio > 0.15
                elseif _tsunamiActive then
                    _firePath = "tsunami"
                    local _closingSpeed = math.max(_totalClosing, 1)
                    local _etaTs = math.max(0, distance / _closingSpeed - (rawPing / 1000))
                    local _closingRatio = _totalClosing / math.max(rawSpeed, 1)
                    local _tsHit = getgenv()._tsunamiHitState and getgenv()._tsunamiHitState[ball]
                    local _tsBoostRel = 0
                    if _tsHit and (tick() - _tsHit.hitAt) < 1.5 then
                        _tsBoostRel = (rawSpeed - _tsHit.preSpeed) / math.max(_tsHit.preSpeed, 1)
                    end
                    local _speedMargin = rawSpeed * _tsfb.marginSpeedScale
                    local _jitterMargin = math.min((_jitter / 1000) * rawSpeed * 0.5, 60)
                    local _totalMargin = _tsfb.marginBase + _speedMargin + _jitterMargin
                    local _fireWindow = _tsfb.windowMax
                    if _tsBoostRel > 0.3 then _fireWindow = _fireWindow + 0.10 end
                    if ballTarget == LocalPlayer.Name and getgenv()._tsunamiForceUntil and tick() < getgenv()._tsunamiForceUntil then
                        _fireWindow = _fireWindow + 0.05
                    end
                    _fireOk = (_etaTs <= _fireWindow and _closingRatio > 0.15) or (distance <= _totalMargin and _closingRatio > 0.15)
                else
                    _fireOk = distance <= targetDistance
                end
                if ballTarget == LocalPlayer.Name and _fireOk and accuracyFactor * 0.8 then
                    getgenv()._lastParryPath = _firePath
                    local _fired = BallHelper.parry(true, ball)
                    if _fired then
                        parryBallCooldown[ball] = true
                        task.delay(0.35, function()
                            if ball and ball.Parent then parryBallCooldown[ball] = nil end
                        end)
                        if _firePath == "spike" then
                            _spk.fires = _spk.fires + 1
                            _spk.lastFireAt = tick()
                        elseif _firePath == "tsunami" then
                            _tsfb.fires = _tsfb.fires + 1
                        elseif getgenv()._etaFeedback then
                            getgenv()._etaFeedback.fires = getgenv()._etaFeedback.fires + 1
                        end
                    end
                end
            end
        end)
    else
        if Connections.auto_parry then Connections.auto_parry:Disconnect(); Connections.auto_parry = nil end
    end
end

-- ============================================================
-- [18] TRIGGERBOT HOOK
-- ============================================================
local triggerActive = false
local function Trigger(ball)
    if triggerActive then return end
    triggerActive = true
    BallHelper.parry()
    ball:GetAttributeChangedSignal("target"):Once(function() triggerActive = false end)
    local startTime = tick()
    task.spawn(function()
        repeat RunService.PreSimulation:Wait() until (tick() - startTime >= 1 or not triggerActive)
        triggerActive = false
    end)
end

getgenv().OnTriggerbotToggle = function(enabled)
    _G.triggerbot = enabled
    if Connections.triggerbot then
        Connections.triggerbot:Disconnect()
        Connections.triggerbot = nil
    end
    if enabled then
        Connections.triggerbot = RunService.PreSimulation:Connect(function()
            if _G.singularity_active then return end
            if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then return end
            local ball = BallHelper.get_ball()
            if not ball then return end
            local target = ball:GetAttribute("target")
            if target == LocalPlayer.Name then Trigger(ball) end
        end)
    else
        if Connections.triggerbot then Connections.triggerbot:Disconnect(); Connections.triggerbot = nil end
    end
end

-- ============================================================
-- [19] AUTO SPAM HOOK
-- ============================================================
local statsService = game:GetService("Stats")
local lastAutoParryFire = 0

getgenv().OnAutoSpamToggle = function(enabled)
    _G.config.auto_spam = enabled
    if Connections.auto_spam then
        Connections.auto_spam:Disconnect()
        Connections.auto_spam = nil
    end
    if enabled then
        Connections.auto_spam = RunService.PreSimulation:Connect(function()
            if _G.singularity_active then return end
            if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then return end
            local ball = BallHelper.get_ball()
            if not ball then return end
            local zoomies = ball:FindFirstChild("zoomies")
            if not zoomies then return end
            local target = CurrentTarget
            if not target or not target.PrimaryPart then return end
            local targetPos = target.PrimaryPart.Position
            if not targetPos then return end
            local pingMs = statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            local fireDelay = pingMs / 1000
            local pingClamped = math.clamp(pingMs / 10, 1, 16)
            local ballTarget = ball:GetAttribute("target")
            local ballProps = BallHelper:get_ball_properties()
            local playerProps = BallHelper:players_properties()
            local maxAccuracy = BallHelper.perfom_spam({ Ball_Properties = ballProps, Entity_Properties = playerProps, Ping = pingClamped })
            maxAccuracy = maxAccuracy + (tonumber(getgenv().ParryRange) or 0)
            local targetDist = LocalPlayer:DistanceFromCharacter(targetPos)
            local toBall = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
            local velUnit = zoomies.VectorVelocity.Unit
            toBall:Dot(velUnit)
            local ballDist = LocalPlayer:DistanceFromCharacter(ball.Position)
            if not ballTarget then return end
            if targetDist > maxAccuracy or ballDist > maxAccuracy then return end
            local pulsed = LocalPlayer.Character:GetAttribute("Pulsed")
            if pulsed then return end
            if ballTarget == LocalPlayer.Name and targetDist > 30 and ballDist > 30 then return end
            local threshold = _G.config.spam_threshold
            if ballDist <= maxAccuracy and parryCount > threshold then
                if tick() - lastAutoParryFire >= fireDelay then
                    lastAutoParryFire = tick()
                    BallHelper.parry()
                end
            end
        end)
    else
        if Connections.auto_spam then Connections.auto_spam:Disconnect(); Connections.auto_spam = nil end
    end
end

-- ============================================================
-- [20] MANUAL SPAM HOOK
-- ============================================================
local _ms = {
    enabled = false, acc = 0,
    cps = tonumber(_G.config.m_ManualSpamCPS) or 500,
    cpsMode = _G.config.m_ManualSpamCPSMode ~= false,
    animationFix = _G.config.m_ManualSpamAnimationFix == true,
}
local _manualSpamAutoOff = false

local function _ms_getInterval()
    if not _ms.cpsMode then
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        return math.max(ping / 1000, 0.05)
    end
    local cps = math.clamp(_ms.cps or 500, 1, 2000)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then cps = math.clamp(cps, 5, 60) end
    return 1 / cps
end
local function _ms_stop()
    _ms.enabled = false
    _G.manual_spam = false
    if Connections.manual_spam then Connections.manual_spam:Disconnect(); Connections.manual_spam = nil end
end
local function _ms_checkMinSpeed()
    local minSpd = tonumber(_G.config.manual_spam_min_speed) or 5
    local mb = BallHelper.get_ball()
    if not mb then return true end
    local z = mb:FindFirstChild("zoomies")
    if not z then return true end
    return z.VectorVelocity.Magnitude >= minSpd
end
local function _ms_loop(_t, delta)
    if not _ms.enabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then return end
    delta = tonumber(delta)
    if not delta or delta <= 0 or delta > 0.5 then delta = 1 / 60 end
    if not _ms_checkMinSpeed() then
        _manualSpamAutoOff = true
        _ms_stop()
        _G.config.manual_spam = false
        if _G.config.manual_notify then pcall(function() UI:Notify("manual spam", "auto-off: ball too slow", "info") end) end
        return
    end
    local interval = _ms_getInterval()
    _ms.acc = _ms.acc + delta
    if _ms.acc < interval then return end
    local count = math.min(math.floor(_ms.acc / interval), 128)
    local budgetEnd = tick() + (getgenv().SpamBoost and 0.012 or 0.006)
    local fired = 0
    for i = 1, count do
        local ok = BallHelper.parry(true)
        if ok then fired = i else break end
        if tick() > budgetEnd then break end
    end
    local consumed = math.max(fired, count)
    _ms.acc = _ms.acc - (consumed * interval)
    if _ms.acc > interval then _ms.acc = interval end
    if _ms.acc < 0 then _ms.acc = 0 end
end
local function _ms_start()
    if _ms.enabled then return end
    _manualSpamAutoOff = false
    _ms.enabled = true
    _ms.acc = 0
    _G.manual_spam = true
    if Connections.manual_spam then Connections.manual_spam:Disconnect() end
    Connections.manual_spam = RunService.PreSimulation:Connect(_ms_loop)
    if _G.config.manual_notify then pcall(function() UI:Notify("manual spam", "on", "info") end) end
end

getgenv().OnManualSpamToggle = function(enabled)
    if enabled then _ms_start() else _ms_stop() end
end

-- ============================================================
-- [21] HIT SOUND
-- ============================================================
do
    local hsIds = {Medal="rbxassetid://6607336718",Fatality="rbxassetid://6607113255",Skeet="rbxassetid://6607204501",Switches="rbxassetid://6607173363",["Rust Headshot"]="rbxassetid://138750331387064",["Neverlose Sound"]="rbxassetid://110168723447153",Bubble="rbxassetid://6534947588",Laser="rbxassetid://7837461331",Steve="rbxassetid://4965083997",["Call of Duty"]="rbxassetid://5952120301",Bat="rbxassetid://3333907347",["TF2 Critical"]="rbxassetid://296102734",Saber="rbxassetid://8415678813",Bameware="rbxassetid://3124331820"}
    local hsFolder = Instance.new("Folder"); hsFolder.Name = "Useful Utility"; hsFolder.Parent = workspace
    local hsObj = Instance.new("Sound"); hsObj.Volume = 6; hsObj.SoundId = hsIds.Medal; hsObj.Parent = hsFolder
    getgenv().HitSoundEnabled = true
    getgenv().ChangeHitSound = function(name)
        if hsIds[name] then hsObj.SoundId = hsIds[name] end
    end
    getgenv().ChangeHitVolume = function(v)
        hsObj.Volume = tonumber(v) or 6
    end
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if getgenv().HitSoundEnabled ~= false and hsObj then hsObj:Play() end
    end)
    pcall(function() hsObj.Volume = tonumber(_G.config.hit_sound_volume) or 6 end)
    getgenv().ChangeHitSound("Call of Duty")
end

-- ============================================================
-- [22] BACKGROUND MUSIC
-- ============================================================
do
    local musLib = {Eeyuh="rbxassetid://16190782181",Sweep="rbxassetid://103508936658553",Bounce="rbxassetid://134818882821660",["Everybody Wants To Rule The World"]="rbxassetid://87209527034670",["Missing Money"]="rbxassetid://134668194128037",["Sour Grapes"]="rbxassetid://117820392172291",Erwachen="rbxassetid://124853612881772",["Grasp the Light"]="rbxassetid://89549155689397",["Beyond the Shadows"]="rbxassetid://120729792529978",["Rise to the Horizon"]="rbxassetid://72573266268313",["Echoes of the Candy Kingdom"]="rbxassetid://103040477333590",Speed="rbxassetid://125550253895893",["Lo-fi Chill A"]="rbxassetid://9043887091",["Lo-fi Ambient"]="rbxassetid://129775776987523",["Tears in the Rain"]="rbxassetid://129710845038263"}
    local musObj = Instance.new("Sound"); musObj.Volume = 3; musObj.Looped = false; musObj.Parent = game:GetService("SoundService")
    local musCurrent = "Eeyuh"
    local musEnabled = false
    local function musPlay(id) musObj:Stop(); musObj.SoundId = id; musObj:Play() end
    getgenv().ToggleMusic = function(v)
        musEnabled = v
        if v then musPlay(musLib[musCurrent]) else musObj:Stop() end
    end
    getgenv().ChangeMusic = function(name)
        if musLib[name] then musCurrent = name; if musEnabled then musPlay(musLib[name]) end end
    end
    getgenv().ChangeMusicVolume = function(v)
        musObj.Volume = tonumber(v) or 3
    end
    getgenv().ToggleMusicLoop = function(v)
        musObj.Looped = v and true or false
    end
    getgenv().ToggleAtmosphere = function(v)
        local l = game:GetService("Lighting")
        if v then
            if not l:FindFirstChild("CustomAtmosphere") then
                local atm = Instance.new("Atmosphere")
                atm.Name = "CustomAtmosphere"
                atm.Density = tonumber(_G.config.atmosphere_density) or 0.3
                atm.Parent = l
            end
        else
            local a = l:FindFirstChild("CustomAtmosphere")
            if a then a:Destroy() end
        end
    end
    getgenv().ChangeAtmosphereDensity = function(v)
        local a = game:GetService("Lighting"):FindFirstChild("CustomAtmosphere")
        if a then a.Density = tonumber(v) or 0.3 end
    end
    pcall(function() musObj.Volume = tonumber(_G.config.music_volume) or 3 end)
    pcall(function() musObj.Looped = _G.config.music_loop == true end)
end

-- ============================================================
-- [23] COLOR CORRECTION
-- ============================================================
do
    local _ccName = "daemon_ColorCorrection"
    local _bright = tonumber(_G.config.brightness) or 0
    local _contrast = tonumber(_G.config.contrast) or 0
    local function _applyColor()
        pcall(function()
            local LT = game:GetService("Lighting")
            local cc = LT:FindFirstChild(_ccName)
            if not cc then
                cc = Instance.new("ColorCorrectionEffect")
                cc.Name = _ccName
                cc.Parent = LT
            end
            cc.Brightness = _bright
            cc.Contrast = _contrast
        end)
    end
    task.spawn(function() task.wait(1); _applyColor() end)
    getgenv().ApplyColorCorrection = _applyColor
end

-- ============================================================
-- [24] DETECTIONS
-- ============================================================
_G.Detect = _G.Detect or { infinity = false, deathslash = false, timehole = false, slashesoffury = false, forcefield = false, singularity = false, sof_combo = false }
_G.infinity_active = false; _G.deathslash_active = false; _G.timehole_active = false
_G.slashesoffury_active = false; _G.forcefield_active = false; _G.singularity_active = false

getgenv()._tsunamiForceUntil = 0
getgenv()._tsunamiHitState = getgenv()._tsunamiHitState or setmetatable({}, {__mode = "k"})
getgenv()._speedEMA = getgenv()._speedEMA or setmetatable({}, {__mode = "k"})
task.spawn(function()
    pcall(function()
        local tsMod = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Abilities"):WaitForChild("Tsunami")
        local tsHit = tsMod:WaitForChild("TsunamiHit")
        if tsHit and tsHit:IsA("RemoteEvent") then
            tsHit.OnClientEvent:Connect(function(...)
                getgenv()._tsunamiForceUntil = tick() + 2.5
                local args = {...}
                local ball = nil
                for _, arg in ipairs(args) do
                    if typeof(arg) == "Instance" and arg:GetAttribute("realBall") == true then
                        ball = arg; break
                    end
                end
                if not ball then ball = BallHelper.get_ball() end
                if ball then
                    local prev = getgenv()._tsunamiState and getgenv()._tsunamiState.last and getgenv()._tsunamiState.last[ball]
                    local speedEMA = getgenv()._speedEMA and getgenv()._speedEMA[ball]
                    local preSpeed = (prev and prev.speed) or speedEMA or 0
                    local state = getgenv()._tsunamiHitState[ball]
                    if not state then
                        state = { hitAt = tick(), preSpeed = preSpeed }
                        getgenv()._tsunamiHitState[ball] = state
                    else
                        state.hitAt = tick()
                        state.preSpeed = preSpeed
                    end
                end
            end)
        end
    end)
end)

pcall(function()
    ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d) _G.deathslash_active = d or false end)
end)
pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b) _G.infinity_active = b or false end)
end)

do
    _G.forcefield_active = false
    local _ffConns = {}
    local function _clearFF() for _, conn in ipairs(_ffConns) do pcall(function() conn:Disconnect() end) end; _ffConns = {} end
    local function _checkFF(c)
        if not c then _G.forcefield_active = false; return end
        local v1 = c:GetAttribute("PassiveLock_ForceField")
        local v2 = c:GetAttribute("Forcefield")
        local v3 = c:GetAttribute("ForceField")
        local childFF = c:FindFirstChildOfClass("ForceField")
        _G.forcefield_active = (v1 == true) or (v2 == true) or (v3 == true) or (childFF ~= nil)
    end
    local function _watchFF(c)
        if not c then return end
        _clearFF(); _checkFF(c)
        table.insert(_ffConns, c.AttributeChanged:Connect(function(attr)
            if attr == "PassiveLock_ForceField" or attr == "Forcefield" or attr == "ForceField" then _checkFF(c) end
        end))
        table.insert(_ffConns, c.ChildAdded:Connect(function(obj) if obj:IsA("ForceField") then _checkFF(c) end end))
        table.insert(_ffConns, c.ChildRemoved:Connect(function(obj) if obj:IsA("ForceField") then _checkFF(c) end end))
    end
    task.spawn(function()
        local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        _watchFF(c)
        LocalPlayer.CharacterAdded:Connect(function(ch) _G.forcefield_active = false; task.wait(0.1); _watchFF(ch) end)
    end)
end

do
    local function _checkSing(c)
        if not c then _G.singularity_active = false; return end
        local hrp = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
        if hrp and hrp:FindFirstChild("SingularityCape") then _G.singularity_active = true; return end
        if c:FindFirstChild("SingularityCape", true) then _G.singularity_active = true; return end
        _G.singularity_active = false
    end
    local function _watchSing(c)
        if not c then return end
        _checkSing(c)
        c.DescendantAdded:Connect(function(obj) if obj.Name == "SingularityCape" then _G.singularity_active = true end end)
        c.DescendantRemoving:Connect(function(obj) if obj.Name == "SingularityCape" then task.defer(function() _checkSing(c) end) end end)
    end
    task.spawn(function()
        local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        _watchSing(c)
        LocalPlayer.CharacterAdded:Connect(function(ch) _G.singularity_active = false; _watchSing(ch) end)
    end)
end

pcall(function()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == LocalPlayer or p == LocalPlayer.Name or (p and p.Name == LocalPlayer.Name) then _G.timehole_active = true end
    end)
    net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function() _G.timehole_active = false end)
    net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == LocalPlayer or p == LocalPlayer.Name or (p and p.Name == LocalPlayer.Name) then _G.slashesoffury_active = true end
    end)
    net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function() _G.slashesoffury_active = false end)
    net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
        task.spawn(function()
            local n = 0
            while _G.slashesoffury_active and n < 36 do
                if _G.Detect.slashesoffury then pcall(BallHelper.parry); n = n + 1; task.wait(0.05)
                else break end
            end
        end)
    end)
end)

task.spawn(function()
    local bf = workspace:WaitForChild("Balls", 30)
    if not bf then return end
    bf.ChildAdded:Connect(function(child)
        child.ChildAdded:Connect(function(child2)
            if _G.Detect.sof_combo and child2.Name == "ComboCounter" then
                local lbl = child2:FindFirstChildOfClass("TextLabel")
                if not lbl then return end
                while lbl and lbl.Parent do
                    local n = tonumber(lbl.Text)
                    if n and n < 1 then pcall(BallHelper.parry) end
                    task.wait(0.12)
                end
            end
        end)
    end)
end)

_G.Quasar = _G.Quasar or { antiBlindness = false, antiDisorientate = false, savedCF = nil }
task.spawn(function()
    local LT = game:GetService("Lighting")
    RunService.Heartbeat:Connect(function()
        if _G.Quasar.antiBlindness then
            local bl = LT:FindFirstChild("Blindness")
            if bl and bl.Enabled then bl.Enabled = false end
            for _, o in ipairs(LT:GetChildren()) do
                if o.Name == "Blindness" and o:IsA("Atmosphere") then o:Destroy() end
            end
        end
        if _G.Quasar.antiDisorientate then
            local ch = LocalPlayer.Character
            local hl = ch and ch:FindFirstChildOfClass("Highlight")
            if hl and hl.FillColor == Color3.new(0, 0, 1) then
                _G.Quasar.savedCF = _G.Quasar.savedCF or workspace.CurrentCamera.CFrame
                workspace.CurrentCamera.CFrame = _G.Quasar.savedCF
            else _G.Quasar.savedCF = nil end
        end
    end)
end)

-- ============================================================
-- [25] ADVANCED DETECTIONS
-- ============================================================
_G.AdvDetect = {
    Dribble  = _G.config.d_AdvDribbleDetection == true,
    Pull     = _G.config.d_AdvPullDetection == true,
    Pulse    = _G.config.d_AdvPulseDetection == true,
    Tornado  = _G.config.d_AdvTornadoDetection == true,
    HellHook = _G.config.d_AdvHellHookDetection == true,
}
_G.AdvFlag = _G.AdvFlag or { Dribble = false, Pull = false, Pulse = false, Tornado = false, HellHook = false }
_G.AdvTornadoTime = _G.AdvTornadoTime or tick()
getgenv()._ZX_PullActive = getgenv()._ZX_PullActive or false
getgenv()._ZX_PullGen = getgenv()._ZX_PullGen or 0

local _advStamps = {}
local _advMaxAge = { Pull = 3, Pulse = 3, HellHook = 8 }
local function _advSetFlag(key, val)
    _G.AdvFlag[key] = val and true or false
    _advStamps[key] = _G.AdvFlag[key] and tick() or nil
end

task.spawn(function()
    while task.wait(0.5) do
        local now = tick()
        for key, maxAge in pairs(_advMaxAge) do
            local stamp = _advStamps[key]
            if stamp and (now - stamp) > maxAge then _G.AdvFlag[key] = false; _advStamps[key] = nil end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not _G.AdvDetect.Dribble then _G.AdvFlag.Dribble = false; continue end
        local found = false
        local balls = workspace:FindFirstChild("Balls")
        if balls then
            for _, ball in pairs(balls:GetChildren()) do
                if not ball then continue end
                local ok = false
                pcall(function()
                    if ball:GetAttribute("dribble") == true or ball:GetAttribute("Dribble") == true then ok = true end
                end)
                if not ok and ball.Name and string.find(ball.Name:lower(), "dribble") then ok = true end
                if not ok and (ball:FindFirstChild("Dribble") or ball:FindFirstChild("Dribbling")) then ok = true end
                if ok then found = true; break end
            end
        end
        _G.AdvFlag.Dribble = found
    end
end)

pcall(function()
    local pkgs = ReplicatedStorage:FindFirstChild("Packages")
    local idx = pkgs and pkgs:FindFirstChild("_Index")
    local netPkg = idx and idx:FindFirstChild("sleitnick_net@0.1.0")
    local net = netPkg and netPkg:FindFirstChild("net")
    local pullRemote = net and net:FindFirstChild("RE/PlrPulled")
    if pullRemote then
        pullRemote.OnClientEvent:Connect(function(a, b)
            if not _G.AdvDetect.Pull then return end
            local isMe = false; local flag = true
            if typeof(a) == "Instance" and a:IsA("Player") then
                isMe = (a == LocalPlayer or a.Name == LocalPlayer.Name)
                if type(b) == "boolean" then flag = b end
            elseif type(a) == "string" then
                isMe = (a == LocalPlayer.Name)
                if type(b) == "boolean" then flag = b end
            elseif type(a) == "boolean" then flag = a; isMe = true
            elseif type(b) == "boolean" then flag = b; isMe = true end
            if not isMe then return end
            getgenv()._ZX_PullGen = getgenv()._ZX_PullGen + 1
            local myGen = getgenv()._ZX_PullGen
            if not flag then getgenv()._ZX_PullActive = false; _advSetFlag("Pull", false); return end
            getgenv()._ZX_PullActive = true
            _advSetFlag("Pull", true)
            task.delay(2, function()
                if getgenv()._ZX_PullGen == myGen then getgenv()._ZX_PullActive = false; _advSetFlag("Pull", false) end
            end)
        end)
    end
end)

for _, remoteName in ipairs({"PlrPulled", "PlrPulsed"}) do
    pcall(function()
        local rem = ReplicatedStorage.Remotes:FindFirstChild(remoteName)
        if not rem then return end
        rem.OnClientEvent:Connect(function(a, b)
            local flag
            if type(a) == "boolean" then flag = a
            elseif type(b) == "boolean" then flag = b
            else flag = true end
            if _G.AdvDetect.Pull then _advSetFlag("Pull", flag) end
            if _G.AdvDetect.Pulse then _advSetFlag("Pulse", flag) end
            if flag and (_G.AdvDetect.Pull or _G.AdvDetect.Pulse) then
                task.delay(1.5, function()
                    if _G.AdvDetect.Pull then _advSetFlag("Pull", false) end
                    if _G.AdvDetect.Pulse then _advSetFlag("Pulse", false) end
                end)
            end
        end)
    end)
end

RunService.PreSimulation:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        if char:GetAttribute("Pulsed") then _G.AdvFlag.Pulse = true end
        if _G.AdvDetect.Pulse then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local hotbar = pg and pg:FindFirstChild("Hotbar")
            local ability = hotbar and hotbar:FindFirstChild("Ability")
            local red = ability and ability:FindFirstChild("Red")
            if red then _G.AdvFlag.Pulse = red.Visible end
        end
    end)
end)

local function _advGetTornado()
    local rt = workspace:FindFirstChild("Runtime")
    return rt and rt:FindFirstChild("Tornado") or nil
end

RunService.PreSimulation:Connect(function()
    pcall(function()
        if not _G.AdvDetect.Tornado then _G.AdvFlag.Tornado = false; return end
        local tornado = _advGetTornado()
        _G.AdvFlag.Tornado = (tornado ~= nil)
        if tornado then
            local balls = workspace:FindFirstChild("Balls")
            if balls then
                for _, ball in ipairs(balls:GetChildren()) do
                    if ball:GetAttribute("realBall") and ball:FindFirstChild("AeroDynamicSlashVFX") then
                        pcall(function() ball.AeroDynamicSlashVFX:Destroy() end)
                        _G.AdvTornadoTime = tick()
                    end
                end
            end
        end
    end)
end)

pcall(function()
    local hookConn, hookPos
    local hookedRem = ReplicatedStorage.Remotes:FindFirstChild("PlrHellHooked")
    local completeRem = ReplicatedStorage.Remotes:FindFirstChild("PlrHellHookCompleted")
    if hookedRem then
        hookedRem.OnClientEvent:Connect(function(a, b)
            if b and b.Name == LocalPlayer.Name and _G.AdvDetect.HellHook then
                _advSetFlag("HellHook", true)
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                hookPos = char.HumanoidRootPart.CFrame
                if hookConn then hookConn:Disconnect() end
                hookConn = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        local c = LocalPlayer.Character
                        if c and c:FindFirstChild("HumanoidRootPart") and hookPos then
                            c.HumanoidRootPart.CFrame = hookPos
                        end
                    end)
                end)
            end
        end)
    end
    if completeRem then
        completeRem.OnClientEvent:Connect(function()
            _advSetFlag("HellHook", false)
            if hookConn then task.wait(1); hookConn:Disconnect(); hookConn = nil; hookPos = nil end
        end)
    end
end)

getgenv().Detections = {
    SetDribble = function(v) _G.AdvDetect.Dribble = v end,
    SetPull = function(v) _G.AdvDetect.Pull = v end,
    SetPulse = function(v) _G.AdvDetect.Pulse = v end,
    SetTornado = function(v) _G.AdvDetect.Tornado = v end,
    SetHellHook = function(v) _G.AdvDetect.HellHook = v end,
    IsDribble = function() return _G.AdvFlag.Dribble end,
    IsPull = function() return _G.AdvFlag.Pull end,
    IsPulse = function() return _G.AdvFlag.Pulse end,
    IsTornado = function() return _G.AdvFlag.Tornado end,
    IsHellHook = function() return _G.AdvFlag.HellHook end,
    GetState = function()
        return { Dribble = _G.AdvFlag.Dribble, Pull = _G.AdvFlag.Pull, Pulse = _G.AdvFlag.Pulse, Tornado = _G.AdvFlag.Tornado, HellHook = _G.AdvFlag.HellHook }
    end,
}

getgenv()._advWiringEnabled = _G.config.d_AdvWiringToggle == true
getgenv()._advParryBlocked = function()
    if not getgenv()._advWiringEnabled then return false end
    local D = getgenv().Detections
    if not D then return false end
    if D.IsPull and D.IsPull() then return true end
    if D.IsPulse and D.IsPulse() then return true end
    if D.IsHellHook and D.IsHellHook() then return true end
    return false
end

-- ============================================================
-- [26] ANTI PHANTOM
-- ============================================================
local antiPhantomActive = false
getgenv().OnAntiPhantomToggle = function(enabled)
    _G.config.anti_phantom = enabled
    if Connections.anti_phantom then
        Connections.anti_phantom:Disconnect()
        Connections.anti_phantom = nil
    end
    antiPhantomActive = false
    if enabled then
        Connections.anti_phantom = workspace.Runtime.ChildAdded:Connect(function(part)
            local character = LocalPlayer.Character
            if not character then return end
            if not (part.Name:lower() == "maxtransmission" or part.Name == "transmissionpart") then return end
            local weld = part:FindFirstChildWhichIsA("WeldConstraint")
            if not weld then return end
            for _, ball in workspace.Balls:GetChildren() do
                if not ball:FindFirstChild("zoomies") then continue end
                if antiPhantomActive then continue end
                antiPhantomActive = true
                local cancelled = false
                task.spawn(function()
                    local startTime = tick()
                    while tick() - startTime < 1 and ball.Parent and not cancelled do
                        task.wait()
                        cloneref(game:GetService("TweenService")):Create(character.HumanoidRootPart, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = ball.CFrame * CFrame.new(0, 0, -3) }):Play()
                    end
                    antiPhantomActive = false
                end)
                ball:GetAttributeChangedSignal("target"):Once(function() cancelled = true; antiPhantomActive = false end)
            end
        end)
    else
        if Connections.anti_phantom then Connections.anti_phantom:Disconnect(); Connections.anti_phantom = nil end
        antiPhantomActive = false
    end
end

-- ============================================================
-- [27] AUTO REMATCH
-- ============================================================
_G.AutoRematch = false
local _remConns = {}
local _remFired = false
local function _remFire(btn)
    local n = 0
    pcall(function() for _, c in ipairs(getconnections(btn.Activated)) do c:Fire(); n = n + 1 end end)
    if n == 0 then pcall(firesignal, btn.Activated) end
end
local function _remCheck(root)
    if not _G.AutoRematch then return end
    local btns = root:FindFirstChild("Buttons"); btns = btns and btns:FindFirstChild("RematchButton")
    if _remFired or not btns or not btns.Visible then return end
    if LocalPlayer:GetAttribute("Rematch") then return end
    _remFired = true
    _remFire(btns)
end
getgenv().SetAutoRematch = function(v)
    _G.AutoRematch = v
    for _, c in ipairs(_remConns) do pcall(function() c:Disconnect() end) end
    _remConns = {}
    if v then
        task.spawn(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui", 10); if not pg then return end
            local duel = pg:WaitForChild("DuelUI", 10); if not duel then return end
            for _, name in ipairs({"WinScreen", "LoseScreen"}) do
                local scr = duel:WaitForChild(name, 5)
                if scr then
                    table.insert(_remConns, scr:GetPropertyChangedSignal("Visible"):Connect(function()
                        if scr.Visible then _remCheck(scr) else _remFired = false end
                    end))
                    if scr.Visible then _remCheck(scr) end
                end
            end
        end)
    else _remFired = false end
end

-- ============================================================
-- [28] HIDE FEATURES
-- ============================================================
do
    local state = {hideAcc=false,hideClo=false,hideName=false,hideAnim=false,hideBill=false,hideSurf=false,hideDec=false,hideParticles=false,hideBeams=false,hideLights=false}
    local bkAcc = setmetatable({}, {__mode="k"})
    local bkClo = setmetatable({}, {__mode="k"})
    local bkNm = setmetatable({}, {__mode="k"})
    local bkBill = setmetatable({}, {__mode="k"})
    local bkSurf = setmetatable({}, {__mode="k"})
    local bkDec = setmetatable({}, {__mode="k"})
    local bkEff = setmetatable({}, {__mode="k"})
    local animConns = {}
    local hookedChars = setmetatable({}, {__mode="k"})
    local function hideChar(c)
        if not c then return end
        if state.hideAcc then
            for _, o in ipairs(c:GetChildren()) do
                if o:IsA("Accessory") or o:IsA("Hat") then
                    for _, d in ipairs(o:GetDescendants()) do
                        if d:IsA("BasePart") then
                            if bkAcc[d] == nil then bkAcc[d] = d.Transparency end
                            d.Transparency = 1
                        end
                    end
                end
            end
        end
        if state.hideClo then
            for _, cn in ipairs({"Shirt","Pants","ShirtGraphic"}) do
                for _, o in ipairs(c:GetChildren()) do
                    if o.ClassName == cn then
                        local pr = cn=="Shirt" and "ShirtTemplate" or cn=="Pants" and "PantsTemplate" or "Graphic"
                        if bkClo[o] == nil then bkClo[o] = o[pr] end
                        pcall(function() o[pr] = "" end)
                    end
                end
            end
        end
        if state.hideName then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                if bkNm[h] == nil then bkNm[h] = h.DisplayDistanceType end
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end
        end
        if state.hideAnim then
            local a = c:FindFirstChildOfClass("Animator")
            if a then
                for _, t in ipairs(a:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
                if not animConns[c] then animConns[c] = a.AnimationPlayed:Connect(function(t) pcall(function() t:Stop(0) end) end) end
            end
        end
    end
    local function restoreChar(c)
        if not c then return end
        for _, o in ipairs(c:GetChildren()) do
            if o:IsA("Accessory") or o:IsA("Hat") then
                for _, d in ipairs(o:GetDescendants()) do
                    if d:IsA("BasePart") and bkAcc[d] then d.Transparency = bkAcc[d]; bkAcc[d] = nil end
                end
            end
        end
        for _, cn in ipairs({"Shirt","Pants","ShirtGraphic"}) do
            for _, o in ipairs(c:GetChildren()) do
                if o.ClassName == cn and bkClo[o] then
                    local pr = cn=="Shirt" and "ShirtTemplate" or cn=="Pants" and "PantsTemplate" or "Graphic"
                    o[pr] = bkClo[o]; bkClo[o] = nil
                end
            end
        end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h and bkNm[h] then h.DisplayDistanceType = bkNm[h]; bkNm[h] = nil end
        if animConns[c] then animConns[c]:Disconnect(); animConns[c] = nil end
    end
    local function hideObj(o)
        if o:IsA("BillboardGui") and state.hideBill then
            if bkBill[o] == nil then bkBill[o] = o.Enabled end; o.Enabled = false
        elseif o:IsA("SurfaceGui") and state.hideSurf then
            if bkSurf[o] == nil then bkSurf[o] = o.Enabled end; o.Enabled = false
        elseif (o:IsA("Decal") or o:IsA("Texture")) and state.hideDec then
            if bkDec[o] == nil then bkDec[o] = o.Transparency end; o.Transparency = 1
        elseif o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")
            or o:IsA("Trail") or o:IsA("Beam") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
            local shouldHide =
                ((o:IsA("Trail") or o:IsA("Beam")) and state.hideBeams)
                or ((o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")) and state.hideParticles)
                or ((o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight")) and state.hideLights)
            if shouldHide then
                if bkEff[o] == nil then bkEff[o] = o.Enabled end; o.Enabled = false
            end
        end
    end
    local _scanPending = false
    local function scanAll()
        if _scanPending then return end
        _scanPending = true
        task.spawn(function()
            task.wait(0.15)
            _scanPending = false
            local n = 0
            for _, o in ipairs(workspace:GetDescendants()) do
                hideObj(o); n = n + 1
                if n % 300 == 0 then task.wait() end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then hideChar(p.Character) end
            end
        end)
    end
    local function restoreAll()
        for o, en in pairs(bkBill) do if o.Parent then pcall(function() o.Enabled = en end) end end
        for o, en in pairs(bkSurf) do if o.Parent then pcall(function() o.Enabled = en end) end end
        for o, t in pairs(bkDec) do if o.Parent then pcall(function() o.Transparency = t end) end end
        for o, en in pairs(bkEff) do if o.Parent then pcall(function() o.Enabled = en end) end end
        table.clear(bkBill); table.clear(bkSurf); table.clear(bkDec); table.clear(bkEff)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then restoreChar(p.Character) end
        end
    end
    workspace.DescendantAdded:Connect(function(o)
        task.defer(function() if o.Parent then hideObj(o) end end)
    end)
    local function hookChar(c)
        if not c or hookedChars[c] then return end
        hookedChars[c] = true
        task.defer(function() if c.Parent then hideChar(c) end end)
        c.DescendantAdded:Connect(function(o)
            if not c.Parent then return end
            if o:IsA("Accessory") or o:IsA("Hat") or o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then
                task.defer(function() if c.Parent then hideChar(c) end end)
            end
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then hookChar(p.Character) end
        p.CharacterAdded:Connect(function(c) task.wait(0.25); hookChar(c) end)
        p.CharacterAppearanceLoaded:Connect(function(c) task.wait(0.1); hideChar(c) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c) task.wait(0.25); hookChar(c) end)
        p.CharacterAppearanceLoaded:Connect(function(c) task.wait(0.1); hideChar(c) end)
    end)
    local function setState(key, val)
        state[key] = val
        if key == "hideAcc" or key == "hideClo" or key == "hideName" or key == "hideAnim" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    if val then hideChar(p.Character) else restoreChar(p.Character) end
                end
            end
        else
            scanAll()
            if not val then restoreAll() end
        end
    end
    local hideAllKeys = {"hideAcc","hideClo","hideName","hideAnim","hideBill","hideSurf","hideDec","hideParticles","hideBeams","hideLights"}
    getgenv().SetHideState = setState
    getgenv().HideAll = function(on)
        for _, k in ipairs(hideAllKeys) do state[k] = on end
        scanAll()
        if not on then restoreAll() end
    end
    local hideAllEffectsConn
    getgenv().HideAllEffects = function(v)
        if v then
            task.spawn(function()
                local n = 0
                for _, o in ipairs(workspace:GetDescendants()) do
                    pcall(function()
                        if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")
                            or o:IsA("Trail") or o:IsA("Beam") then o.Enabled = false
                        elseif o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Enabled = false
                        elseif o:IsA("Explosion") then o:Destroy()
                        elseif o:IsA("Sound") then o.Volume = 0; o:Stop() end
                    end)
                    n = n + 1
                    if n % 300 == 0 then task.wait() end
                end
            end)
            if not hideAllEffectsConn then
                hideAllEffectsConn = workspace.DescendantAdded:Connect(function(o)
                    task.defer(function()
                        pcall(function()
                            if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")
                                or o:IsA("Trail") or o:IsA("Beam") then o.Enabled = false
                            elseif o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Enabled = false
                            elseif o:IsA("Explosion") then o:Destroy()
                            elseif o:IsA("Sound") then o.Volume = 0; o:Stop() end
                        end)
                    end)
                end)
            end
        else
            if hideAllEffectsConn then hideAllEffectsConn:Disconnect(); hideAllEffectsConn = nil end
        end
    end
end

-- ============================================================
-- [29] AVATAR / HEADLESS / KORBLOX
-- ============================================================
do
    local _avGetUserId = function(nameOrId)
        local n = tonumber(nameOrId); if n then return n end
        local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(tostring(nameOrId)) end)
        return ok and id or nil
    end
    local state = { enabled=false, target="", originalDesc=nil, appliedId=nil, applying=false, cache={}, attemptId=0 }
    local _avSaveOriginal = function()
        if state.originalDesc then return end
        task.spawn(function()
            for i = 1, 5 do
                local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(LocalPlayer.UserId) end)
                if ok and desc then state.originalDesc = desc; break end
                task.wait(0.3 * i)
            end
        end)
    end
    local _avGetDescription = function(userId)
        if state.cache[userId] then return state.cache[userId] end
        for i = 1, 5 do
            local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(userId) end)
            if ok and desc then state.cache[userId] = desc; return desc end
            task.wait(0.2 * i)
        end
        return nil
    end
    local _avApplyDescription = function(desc)
        if not desc or state.applying then return end
        state.applying = true
        task.spawn(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if not char then state.applying = false; return end
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
            if not hum then state.applying = false; return end
            pcall(function()
                if hum.ApplyDescriptionClientServer then hum:ApplyDescriptionClientServer(desc)
                else hum:ApplyDescription(desc) end
            end)
            state.applying = false
        end)
    end
    local function apply(nameOrId)
        if state.applying then return end
        state.attemptId = state.attemptId + 1
        local token = state.attemptId
        task.spawn(function()
            if not state.enabled or state.target ~= nameOrId or state.attemptId ~= token then return end
            local id = _avGetUserId(nameOrId); if not id then return end
            if state.appliedId == id then return end
            local desc = _avGetDescription(id); if not desc then return end
            if not state.enabled or state.target ~= nameOrId or state.attemptId ~= token then return end
            state.appliedId = id
            _avApplyDescription(desc)
        end)
    end
    local function restore()
        if not state.originalDesc then return end
        state.appliedId = nil; state.applying = false
        _avApplyDescription(state.originalDesc)
    end
    local function set(enabled, target)
        state.enabled = enabled
        if target then state.target = target end
        if enabled then _avSaveOriginal(); if state.target ~= "" then apply(state.target) end
        elseif state.appliedId then restore() end
    end
    getgenv()._daemonAvatarChanger = { set = set, apply = apply, restore = restore }

    _G._daemonHeadless = function(char)
        if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        head.Transparency = 1
        for _, child in head:GetChildren() do
            if child:IsA("Decal") or child.Name == "face" then child.Transparency = 1
            elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
                if not child:GetAttribute("OriginalScale") then
                    child:SetAttribute("OriginalScale", child.Scale)
                    child.Scale = Vector3.new(0, 0, 0)
                end
            end
        end
    end
    _G._daemonRestoreHead = function(char)
        if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        head.Transparency = 0
        for _, child in head:GetChildren() do
            if child:IsA("Decal") or child.Name == "face" then child.Transparency = 0
            elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
                local orig = child:GetAttribute("OriginalScale")
                if orig then child.Scale = orig; child:SetAttribute("OriginalScale", nil) end
            end
        end
    end
    _G._daemonKorblox = function(char)
        if not char then return end
        local leg = char:FindFirstChild("Right Leg"); if not leg then return end
        if not leg:FindFirstChild("KorbloxMesh") then
            for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
            local m = Instance.new("SpecialMesh")
            m.Name = "KorbloxMesh"; m.MeshId = "rbxassetid://902942096"
            m.TextureId = "rbxassetid://902843398"; m.Offset = Vector3.new(0, 0.7, 0); m.Parent = leg
        end
    end
    _G._daemonRestoreLeg = function(char)
        if not char then return end
        local leg = char:FindFirstChild("Right Leg"); if not leg then return end
        for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
    end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char then
            if _G.config.headless_enabled and _G._daemonHeadless then pcall(_G._daemonHeadless, char) end
            if _G.config.korblox_enabled and _G._daemonKorblox then pcall(_G._daemonKorblox, char) end
        end
    end)
end

-- ============================================================
-- [30] FOV / SPEED+JUMP / GRAVITY / FORCE MATERIAL
-- ============================================================
do
    local fovConn, fovOrig
    local function applyFOV(v)
        local cam = workspace.CurrentCamera; if not cam then return end
        if fovOrig == nil then fovOrig = cam.FieldOfView end
        cam.FieldOfView = v
    end
    getgenv().ToggleFOV = function(state)
        if fovConn then fovConn:Disconnect(); fovConn = nil end
        if state then
            applyFOV(tonumber(getgenv().FOVValue) or 120)
            fovConn = RunService.RenderStepped:Connect(function() applyFOV(tonumber(getgenv().FOVValue) or 120) end)
        else
            if fovOrig then local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = fovOrig end end
        end
    end
    getgenv().FOVValue = 120
end

do
    local sjConn
    getgenv().ToggleSpeedJump = function(state)
        if sjConn then sjConn:Disconnect(); sjConn = nil end
        if state then
            sjConn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character; if not c then return end
                local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
                h.WalkSpeed = tonumber(getgenv().WalkSpeed) or 44
                h.UseJumpPower = true
                h.JumpPower = tonumber(getgenv().JumpPower) or 50
            end)
        else
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = 36; h.JumpPower = 50 end
            end
        end
    end
    getgenv().WalkSpeed = 44; getgenv().JumpPower = 50
end

do
    local gravConn
    local gravOrig = workspace.Gravity
    local function setGrav(on, val)
        if gravConn then gravConn:Disconnect(); gravConn = nil end
        if on then
            local t = tonumber(val) or 100
            gravConn = RunService.Heartbeat:Connect(function() workspace.Gravity = t end)
        else workspace.Gravity = gravOrig end
    end
    getgenv().GravityValue = 100
    getgenv().ToggleGravity = function(v)
        getgenv().GravityEnabled = v
        setGrav(v, getgenv().GravityValue or 100)
    end
end

do
    local matEnabled = false
    local matType = "SmoothPlastic"
    local matBackup = setmetatable({}, {__mode="k"})
    local matConn
    local function isCharPart(o)
        local par = o.Parent
        while par and par ~= workspace do
            if par:IsA("Model") and Players:GetPlayerFromCharacter(par) then return true end
            par = par.Parent
        end
        return false
    end
    local function applyMat(o)
        if not o:IsA("BasePart") or o:IsA("SpawnLocation") then return end
        if isCharPart(o) then return end
        if matBackup[o] == nil then matBackup[o] = o.Material end
        o.Material = matType == "Plastic" and Enum.Material.Plastic or Enum.Material.SmoothPlastic
    end
    local function scanMat()
        task.spawn(function()
            local n = 0
            for _, o in ipairs(workspace:GetDescendants()) do
                applyMat(o); n = n + 1
                if n % 300 == 0 then task.wait() end
            end
        end)
    end
    local function restoreMat()
        for o, m in pairs(matBackup) do if o.Parent then pcall(function() o.Material = m end) end end
        table.clear(matBackup)
    end
    getgenv().ToggleForceMat = function(v)
        matEnabled = v
        if v then
            scanMat()
            if not matConn then
                matConn = workspace.DescendantAdded:Connect(function(o)
                    task.defer(function() if matEnabled then applyMat(o) end end)
                end)
            end
        else
            if matConn then matConn:Disconnect(); matConn = nil end
            restoreMat()
        end
    end
end

-- ============================================================
-- [31] AUTO PLAY
-- ============================================================
local AP_State = {
    enabled = false, step_conn = nil, char_conn = nil, next_decision_at = 0,
    next_jump_at = 0, side_switch_at = 0, hesitation_until = 0, double_jumped = false,
    was_air = false, last_any_jump = 0, ball = nil, floor = nil,
    phase_seed = math.random() * 1000, side = (math.random() < 0.5) and -1 or 1,
}
local function _ap_rand(a, b) return a + math.random() * (b - a) end
local function _ap_chance(pct) return math.random() * 100 <= pct end
local function _ap_get_floor()
    local f = Workspace:FindFirstChild("FLOOR")
    if f and f:IsA("BasePart") then return f end
    if AP_State.floor and AP_State.floor.Parent then return AP_State.floor end
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and p.Size.X > 50 and p.Size.Z > 50 and p.Position.Y < 5 then
            AP_State.floor = p; return p
        end
    end
    return nil
end
local function _ap_get_real_ball()
    local balls = Workspace:FindFirstChild("Balls"); if not balls then return nil end
    for _, b in ipairs(balls:GetChildren()) do if b:GetAttribute("realBall") then return b end end
    return nil
end
local function _ap_compute_target(ball, floor, hrp)
    if not ball or not floor or not hrp then return nil end
    local ball_pos = ball.Position; local my_pos = hrp.Position
    local to_me = Vector3.new(my_pos.X - ball_pos.X, 0, my_pos.Z - ball_pos.Z)
    local dist = to_me.Magnitude
    local dir = (dist > 0.01) and to_me.Unit or Vector3.new(0, 0, 1)
    local perp = Vector3.new(-dir.Z, 0, dir.X) * AP_State.side
    local speed = 0
    local zoomies = ball:FindFirstChild("zoomies")
    if zoomies and zoomies.VectorVelocity then speed = zoomies.VectorVelocity.Magnitude end
    local smooth_t = tick() * 1.25 + AP_State.phase_seed
    local variation = math.sin(smooth_t) * 2.5
    local speed_adj = math.min(speed / 10, getgenv().AutoPlayMultiplierThreshold or 45)
    local base_dist = (getgenv().AutoPlayDistance or 18) + speed_adj + variation
    local jx = (math.random() - 0.5) * 1.5
    local jz = (math.random() - 0.5) * 1.5
    local offset = dir * base_dist * (getgenv().AutoPlayDirection or 1)
    local strafe = perp * math.sin(smooth_t * 0.7) * (getgenv().AutoPlayTransversing or 6)
    return Vector3.new(ball_pos.X + offset.X + strafe.X + jx, floor.Position.Y, ball_pos.Z + offset.Z + strafe.Z + jz)
end
local function _ap_step()
    if not AP_State.enabled then return end
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    local blocked = _G.singularity_active or (getgenv()._advParryBlocked and getgenv()._advParryBlocked())
    if blocked then
        if hum.MoveDirection.Magnitude > 0 then hum:MoveTo(hrp.Position) end
        return
    end
    if hum.FloorMaterial ~= Enum.Material.Air then AP_State.double_jumped = false; AP_State.was_air = false
    else AP_State.was_air = true end
    local ball = _ap_get_real_ball() or AP_State.ball
    if ball and (not ball.Parent or not ball:GetAttribute("realBall")) then ball = nil end
    if ball then AP_State.ball = ball end
    if not ball then return end
    local floor = _ap_get_floor(); if not floor then return end
    local now = tick()
    if now > AP_State.side_switch_at then
        AP_State.side = (math.random() < 0.5) and -1 or 1
        AP_State.side_switch_at = now + _ap_rand(4, 9)
    end
    if now < AP_State.next_decision_at then return end
    AP_State.next_decision_at = now + _ap_rand(0.15, 0.35)
    if AP_State.hesitation_until > now then return end
    if _ap_chance(6) then AP_State.hesitation_until = now + _ap_rand(0.15, 0.45); return end
    local target = _ap_compute_target(ball, floor, hrp)
    if target then
        local zoomies = ball:FindFirstChild("zoomies")
        if zoomies and zoomies.VectorVelocity then
            local bv = zoomies.VectorVelocity
            target = target + Vector3.new(bv.X, 0, bv.Z) * 0.05
        end
        pcall(function() hum:MoveTo(target) end)
    end
    if getgenv().AutoPlayJumpingEnabled and now >= AP_State.next_jump_at then
        local hdist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(ball.Position.X, 0, ball.Position.Z)).Magnitude
        local btarget = ball:GetAttribute("target")
        local should = false
        if btarget == LocalPlayer.Name and hdist < 35 then should = _ap_chance(getgenv().AutoPlayJumpPercentage or 25)
        elseif hdist < 20 then should = _ap_chance((getgenv().AutoPlayJumpPercentage or 25) * 0.5) end
        local _secSinceJump = now - (AP_State.last_any_jump or 0)
        if not should and _secSinceJump > 4 and _ap_chance(35) then should = true end
        if should and hum.FloorMaterial ~= Enum.Material.Air then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            pcall(function() hum.Jump = true end)
            AP_State.last_any_jump = now
            AP_State.next_jump_at = now + (getgenv().AutoPlayJumpCooldown or 1.0)
        elseif hum.FloorMaterial == Enum.Material.Air and not AP_State.double_jumped and _ap_chance(getgenv().AutoPlayDoubleJumpPercentage or 12) then
            pcall(function() hum.Jump = true end)
            AP_State.double_jumped = true
            AP_State.last_any_jump = now
            AP_State.next_jump_at = now + (getgenv().AutoPlayJumpCooldown or 1.0)
        end
    end
end
local function _ap_set_enabled(state)
    AP_State.enabled = state == true
    getgenv().AutoPlayState = AP_State.enabled
    if AP_State.step_conn then AP_State.step_conn:Disconnect(); AP_State.step_conn = nil end
    if AP_State.char_conn then AP_State.char_conn:Disconnect(); AP_State.char_conn = nil end
    if AP_State.enabled then
        AP_State.next_decision_at = 0; AP_State.next_jump_at = 0
        AP_State.side_switch_at = 0; AP_State.hesitation_until = 0
        AP_State.phase_seed = math.random() * 1000
        AP_State.side = (math.random() < 0.5) and -1 or 1
        AP_State.step_conn = RunService.Heartbeat:Connect(_ap_step)
        AP_State.char_conn = LocalPlayer.CharacterAdded:Connect(function()
            AP_State.double_jumped = false; AP_State.was_air = false; AP_State.ball = nil
        end)
    end
end
local function _ap_set_anti_afk(state)
    getgenv().AutoPlayAntiAFK = state
    if getgenv()._autoPlayAntiAFKConn then
        pcall(function() getgenv()._autoPlayAntiAFKConn:Disconnect() end)
        getgenv()._autoPlayAntiAFKConn = nil
    end
    if state then
        getgenv()._autoPlayAntiAFKConn = LocalPlayer.Idled:Connect(function()
            local vu = cloneref and cloneref(game:GetService("VirtualUser")) or game:GetService("VirtualUser")
            vu:CaptureController(); vu:ClickButton2(Vector2.new())
        end)
    end
end

getgenv().AutoPlayDistance = getgenv().AutoPlayDistance or 18
getgenv().AutoPlayMultiplierThreshold = getgenv().AutoPlayMultiplierThreshold or 45
getgenv().AutoPlayTransversing = getgenv().AutoPlayTransversing or 6
getgenv().AutoPlayDirection = getgenv().AutoPlayDirection or 1
getgenv().AutoPlayJumpPercentage = getgenv().AutoPlayJumpPercentage or 15
getgenv().AutoPlayDoubleJumpPercentage = getgenv().AutoPlayDoubleJumpPercentage or 8
getgenv().AutoPlayJumpCooldown = getgenv().AutoPlayJumpCooldown or 1.0
getgenv().AutoPlayJumpingEnabled = getgenv().AutoPlayJumpingEnabled or true

getgenv().AutoPlay = {
    Enable = _ap_set_enabled, Disable = function() _ap_set_enabled(false) end,
    Toggle = function() _ap_set_enabled(not AP_State.enabled) end,
    IsEnabled = function() return AP_State.enabled end,
    SetAntiAFK = _ap_set_anti_afk, GetState = function() return AP_State end,
}

-- ============================================================
-- [32] FFLAGS
-- ============================================================
do
    local config = _G.config
    local FFlag = { folder = "daemon/fflags" }
    local function _ffTrim(s) return tostring(s or ""):match("^%s*(.-)%s*$") end
    local function _ffEnsureFolder()
        if type(makefolder) ~= "function" then return end
        if type(isfolder) == "function" and not isfolder("daemon") then pcall(makefolder, "daemon") end
        if type(isfolder) == "function" and not isfolder(FFlag.folder) then pcall(makefolder, FFlag.folder) end
    end
    local function _ffPath(name)
        local n = _ffTrim(name); if n == "" then return nil, "profile name is empty" end
        local safe = n:gsub("[<>:\"/\\|%?%*%c]", "_"):sub(1, 64)
        return FFlag.folder .. "/" .. safe .. ".json", nil, safe
    end
    local function _ffDecode(json)
        if type(json) ~= "string" or _ffTrim(json) == "" then return nil, "fflags json is empty" end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
        if not ok or type(decoded) ~= "table" then return nil, "invalid fflags json" end
        local clean, count = {}, 0
        for k, v in pairs(decoded) do
            if type(k) ~= "string" or _ffTrim(k) == "" then return nil, "every fflag needs a valid string name" end
            if type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then return nil, "fflag values must be strings, numbers, or booleans" end
            clean[k] = tostring(v); count = count + 1
        end
        if count == 0 then return nil, "fflags json has no flags" end
        return clean, nil, count
    end
    local function _ffApply(json)
        if type(setfflag) ~= "function" then return false, "setfflag is unavailable in this executor" end
        local data, err, count = _ffDecode(json)
        if not data then return false, err end
        local failed = {}
        for k, v in pairs(data) do if not pcall(setfflag, k, v) then table.insert(failed, k) end end
        if #failed > 0 then
            table.sort(failed)
            return false, string.format("failed to apply %d/%d fflags: %s", #failed, count, table.concat(failed, ", "))
        end
        return true, string.format("applied %d fflags", count)
    end
    local function _ffSave(name, json)
        if type(writefile) ~= "function" then return false, "file storage is unavailable" end
        local data, err = _ffDecode(json); if not data then return false, err end
        local path, perr, safe = _ffPath(name); if not path then return false, perr end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok then return false, "could not encode the fflags profile" end
        _ffEnsureFolder()
        if not pcall(writefile, path, encoded) then return false, "could not save the fflags profile" end
        return true, encoded, safe
    end
    local function _ffLoad(name)
        if type(readfile) ~= "function" then return false, "file storage is unavailable" end
        local path, err = _ffPath(name); if not path then return false, err end
        local ok, content = pcall(readfile, path)
        if not ok or type(content) ~= "string" then return false, "fflags profile was not found" end
        local data, derr = _ffDecode(content); if not data then return false, derr end
        return true, content
    end
    getgenv().FFlagApply = _ffApply
    getgenv().FFlagSave = function(name) return _ffSave(name, _G.config.fflag_json) end
    getgenv().FFlagLoad = function(name)
        local ok, content = _ffLoad(name)
        if ok then _G.config.fflag_json = content; pcall(save_cfg) end
        return ok, content
    end
    if config.fflag_auto_load then
        task.defer(function()
            local name = config.fflag_profile
            if not name or name == "" then return end
            local ok, content = _ffLoad(name)
            if ok then _ffApply(content) end
        end)
    end
end

-- ============================================================
-- [33] BALL STATS + PING
-- ============================================================
local ballStatsGui
getgenv().OnBallStatsToggle = function(enabled)
    _G.config.ball_debug = enabled
    if enabled then
        if ballStatsGui then ballStatsGui:Destroy(); ballStatsGui = nil end
        ballStatsGui = Instance.new("ScreenGui")
        ballStatsGui.Name = "daemon_BallStats"
        ballStatsGui.ResetOnSpawn = false
        ballStatsGui.IgnoreGuiInset = true
        ballStatsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ballStatsGui.DisplayOrder = 9998
        pcall(function()
            local p = nil
            pcall(function() if gethui then p = gethui() end end)
            if not p then pcall(function() p = game:GetService("CoreGui") end) end
            if not p then p = LocalPlayer:WaitForChild("PlayerGui") end
            ballStatsGui.Parent = p
        end)

        local label = Instance.new("TextLabel")
        label.Name = "Velocity"
        label.Size = UDim2.new(0.2, 0, 0.05, 0)
        label.Position = UDim2.new(0.7, 0, 0.07, 0)
        label.TextSize = 26
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 0, 0)
        label.Font = Enum.Font.GothamBlack
        label.TextStrokeTransparency = 0.3
        label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "waiting..."
        label.Parent = ballStatsGui

        local targetLabel = Instance.new("TextLabel")
        targetLabel.Name = "Target"
        targetLabel.Size = UDim2.new(0.2, 0, 0.03, 0)
        targetLabel.Position = UDim2.new(0.7, 0, 0.10, 0)
        targetLabel.TextSize = 16
        targetLabel.BackgroundTransparency = 1
        targetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        targetLabel.Font = Enum.Font.Fantasy
        targetLabel.TextXAlignment = Enum.TextXAlignment.Left
        targetLabel.Text = "target: —"
        targetLabel.Parent = ballStatsGui

        local maxPerBall = {}
        Connections.ball_stats = RunService.Heartbeat:Connect(function()
            local balls = BallHelper.get_balls() or {}
            if #balls == 0 then
                label.Text = "waiting..."
                label.TextColor3 = Color3.fromRGB(0, 0, 0)
                targetLabel.Text = "target: —"
                targetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                return
            end
            for ball in pairs(maxPerBall) do
                if not table.find(balls, ball) then maxPerBall[ball] = nil end
            end
            local highestSpeed = 0
            local fastestBall
            for _, ball in ipairs(balls) do
                local zoomies = ball:FindFirstChild("zoomies")
                if zoomies then
                    local speed = zoomies.VectorVelocity.Magnitude
                    local prev = maxPerBall[ball] or 0
                    local new = math.max(prev, speed)
                    maxPerBall[ball] = new
                    if new > highestSpeed then highestSpeed = new; fastestBall = ball end
                end
            end
            if fastestBall then
                local speed = highestSpeed
                local atLimit = speed >= 2200
                local text = ("ball velocity: %.0f"):format(speed)
                if atLimit then text = text .. " (LIMIT!)" end
                label.Text = text
                label.TextColor3 = atLimit and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(0, 0, 0)
                local tName = fastestBall:GetAttribute("target")
                if not tName or tName == "" then
                    targetLabel.Text = "target: —"
                    targetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                elseif tName == LocalPlayer.Name then
                    targetLabel.Text = "target: you"
                    targetLabel.TextColor3 = Color3.fromRGB(80, 255, 74)
                else
                    local p = Players:FindFirstChild(tName)
                    local disp = (p and p.DisplayName) or tName
                    targetLabel.Text = "target: " .. disp
                    targetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                end
            else
                label.Text = "waiting..."
                label.TextColor3 = Color3.fromRGB(0, 0, 0)
                targetLabel.Text = "target: —"
                targetLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end)
    else
        if Connections.ball_stats then Connections.ball_stats:Disconnect(); Connections.ball_stats = nil end
        if ballStatsGui then ballStatsGui:Destroy(); ballStatsGui = nil end
    end
end

local _pingGui, _pingLabel, _fpsLabel, _pingConn, _fpsCounter, _fpsLast, _fpsValue
getgenv().OnPingToggle = function(value)
    _G.config.show_ping = value
    if value then
        if _pingConn then _pingConn:Disconnect(); _pingConn = nil end
        if _pingGui then _pingGui:Destroy(); _pingGui = nil end
        _pingGui = Instance.new("ScreenGui")
        _pingGui.Name = "daemon_PingGui"
        _pingGui.ResetOnSpawn = false
        _pingGui.IgnoreGuiInset = true
        _pingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        _pingGui.DisplayOrder = 9997
        pcall(function()
            local p = nil
            pcall(function() if gethui then p = gethui() end end)
            if not p then pcall(function() p = game:GetService("CoreGui") end) end
            if not p then p = LocalPlayer:WaitForChild("PlayerGui") end
            _pingGui.Parent = p
        end)
        _pingLabel = Instance.new("TextLabel")
        _pingLabel.Size = UDim2.new(0, 340, 0, 28)
        _pingLabel.Position = UDim2.new(0, 12, 0, 50)
        _pingLabel.BackgroundTransparency = 1
        _pingLabel.Font = Enum.Font.Fantasy
        _pingLabel.TextSize = 24
        _pingLabel.TextXAlignment = Enum.TextXAlignment.Left
        _pingLabel.TextStrokeTransparency = 0.4
        _pingLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        _pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        _pingLabel.RichText = true
        _pingLabel.Text = "ping: --"
        _pingLabel.ZIndex = 9999
        _pingLabel.Parent = _pingGui
        _fpsLabel = Instance.new("TextLabel")
        _fpsLabel.Size = UDim2.new(0, 340, 0, 28)
        _fpsLabel.Position = UDim2.new(0, 12, 0, 76)
        _fpsLabel.BackgroundTransparency = 1
        _fpsLabel.Font = Enum.Font.Fantasy
        _fpsLabel.TextSize = 24
        _fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
        _fpsLabel.TextStrokeTransparency = 0.4
        _fpsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        _fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        _fpsLabel.RichText = true
        _fpsLabel.Text = "fps: --"
        _fpsLabel.ZIndex = 9999
        _fpsLabel.Parent = _pingGui
        _fpsCounter = 0; _fpsLast = tick(); _fpsValue = 0
        _pingConn = RunService.RenderStepped:Connect(function()
            _fpsCounter = _fpsCounter + 1
            local now = tick()
            if now - _fpsLast >= 0.5 then
                _fpsValue = math.floor(_fpsCounter / (now - _fpsLast) + 0.5)
                _fpsCounter = 0; _fpsLast = now
                pcall(function()
                    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                    local pc = Color3.fromRGB(120, 255, 140)
                    if ping > 100 then pc = Color3.fromRGB(255, 220, 60) end
                    if ping > 200 then pc = Color3.fromRGB(255, 90, 90) end
                    _pingLabel.Text = string.format("ping: <font color='#%02x%02x%02x'>%dms</font>", math.floor(pc.R * 255), math.floor(pc.G * 255), math.floor(pc.B * 255), math.floor(ping))
                end)
                local fc = Color3.fromRGB(120, 255, 140)
                if _fpsValue < 60 then fc = Color3.fromRGB(255, 220, 60) end
                if _fpsValue < 30 then fc = Color3.fromRGB(255, 90, 90) end
                _fpsLabel.Text = string.format("fps: <font color='#%02x%02x%02x'>%d</font>", math.floor(fc.R * 255), math.floor(fc.G * 255), math.floor(fc.B * 255), _fpsValue)
            end
        end)
    else
        if _pingConn then _pingConn:Disconnect(); _pingConn = nil end
        if _pingGui then _pingGui:Destroy(); _pingGui = nil end
        _pingLabel = nil; _fpsLabel = nil
    end
end

-- ============================================================
-- [35] ADAPTIVE STATUS DISPLAY
-- ============================================================
do
    local paraHandle = nil
    pcall(function() paraHandle = UI:AddParagraph(sParryL, "Adaptive Status", "disabled") end)
    task.spawn(function()
        task.wait(1)
        while true do
            task.wait(1)
            local enabled = getgenv()._adaptiveEnabled == true
            local mode = getgenv()._adaptiveMode or "Accuracy Only"
            local txtT, txtD
            if not enabled then
                txtT = "Adaptive Status"
                txtD = "disabled"
            else
                local acc = math.floor(tonumber(getgenv()._adaptiveAcc) or 0)
                if mode == "Accuracy + Range" then
                    local rng = tonumber(getgenv()._adaptiveRange) or 0
                    local spd = math.floor(tonumber(getgenv()._adaptiveSpeed) or 0)
                    local dst = math.floor(tonumber(getgenv()._adaptiveDist) or 0)
                    txtT = "acc+range"
                    txtD = string.format("acc:%d | range:%.1f | spd:%d | dist:%d", acc, rng, spd, dst)
                else
                    txtT = "acc-only"
                    txtD = string.format("acc:%d", acc)
                end
            end
            if paraHandle and paraHandle.Set then
                pcall(function() paraHandle:Set(txtT, txtD) end)
            end
        end
    end)
end
-- ============================================================
-- [36] NO RENDER (DoD)
-- ============================================================
do
    local noRenderConn
    local function setNoRender(on)
        pcall(function()
            local es = LocalPlayer.PlayerScripts:FindFirstChild("EffectScripts")
            if es then
                local cfx = es:FindFirstChild("ClientFX")
                if cfx then cfx.Disabled = on end
            end
        end)
        if noRenderConn then noRenderConn:Disconnect(); noRenderConn = nil end
        if on then
            local rt = workspace:FindFirstChild("Runtime")
            if rt then
                noRenderConn = rt.ChildAdded:Connect(function(v) Debris:AddItem(v, 0) end)
            end
        end
    end
    getgenv().ToggleNoRender = setNoRender

    local sNoRender = UI:CreateSection("Utility", "No Render", "Kill Runtime spawns", true, "Right", "cpu")
    UI:AddToggle(sNoRender, "No Render", _G.config.no_render ~= false, function(v)
        _G.config.no_render = v
        setNoRender(v)
    end)

    setNoRender(_G.config.no_render ~= false)
end

-- ============================================================
-- [4.4] HEX COLOR PARSER (helper)
-- ============================================================
if not getgenv()._parseHexColor then
    getgenv()._parseHexColor = function(hex)
        if type(hex) ~= "string" then return nil end
        hex = hex:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            if r and g and b then return Color3.fromRGB(r, g, b) end
        end
        return nil
    end
end

-- ============================================================
-- [4.5] LEGIT SCREEN MOVEMENT
-- ============================================================
getgenv()._legitCamAngle = tonumber(_G.config.legit_cam_angle) or 55
getgenv()._legitCamJitter = tonumber(_G.config.legit_cam_jitter) or 2
getgenv()._legitCamCooldown = tonumber(_G.config.legit_cam_cooldown) or 200
getgenv()._legitCamSpeed = tonumber(_G.config.legit_cam_speed) or 1.0

getgenv()._legitCam = {
    enabled = _G.config.legit_screen_movement == true,
    active = false,
    phase = "idle",
    startDir = nil,
    targetDir = nil,
    restDir = nil,
    restSavedAt = 0,
    lastActiveEndAt = 0,
    phaseStart = 0,
    phaseDur = 0,
    lastFireAt = 0,
}

do
    local cam = workspace.CurrentCamera
    if cam then
        getgenv()._legitCam.restDir = cam.CFrame.LookVector
    end
end

getgenv().SetLegitScreenMovement = function(v)
    getgenv()._legitCam.enabled = v == true
    if v then
        local cam = workspace.CurrentCamera
        if cam then
            getgenv()._legitCam.restDir = cam.CFrame.LookVector
            getgenv()._legitCam.restSavedAt = tick()
        end
    else
        getgenv()._legitCam.active = false
        getgenv()._legitCam.phase = "idle"
    end
end

getgenv()._doLegitCameraMove = function(curveCFrame)
    local st = getgenv()._legitCam
    if not st.enabled or st.active then return end
    local cam = workspace.CurrentCamera
    if not cam or not curveCFrame then return end
    local now = tick()
    local cooldownSec = (getgenv()._legitCamCooldown or 200) / 1000
    if now - st.lastFireAt < cooldownSec then return end
    st.lastFireAt = now
    if not st.restDir then st.restDir = cam.CFrame.LookVector end
    local currentDir = cam.CFrame.LookVector
    local targetDir = curveCFrame.LookVector
    local dot = math.clamp(currentDir:Dot(targetDir), -1, 1)
    local angle = math.acos(dot)
    local maxAngle = math.rad(getgenv()._legitCamAngle or 55)
    if angle > maxAngle then
        targetDir = currentDir:Lerp(targetDir, maxAngle / angle).Unit
    end
    local jitterDeg = getgenv()._legitCamJitter or 2
    local jr = (math.random() - 0.5) * math.rad(jitterDeg)
    local ju = (math.random() - 0.5) * math.rad(jitterDeg)
    targetDir = (targetDir + cam.CFrame.RightVector * jr + cam.CFrame.UpVector * ju).Unit
    local speed = getgenv()._legitCamSpeed or 1.0
    st.active = true
    st.phase = "out"
    st.startDir = currentDir
    st.targetDir = targetDir
    st.phaseStart = now
    st.phaseDur = math.random(70, 160) / 1000 / speed
end

RunService.RenderStepped:Connect(function()
    local st = getgenv()._legitCam
    if not st then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local now = tick()
    if not st.active then
        if st.enabled then
            if now - (st.lastActiveEndAt or 0) > 0.4 then
                local cur = cam.CFrame.LookVector
                local r = st.restDir or cur
                st.restDir = (r * 0.85 + cur * 0.15).Unit
                st.restSavedAt = now
            end
        else
            st.restDir = cam.CFrame.LookVector
        end
        return
    end
    local elapsed = now - st.phaseStart
    local alpha = math.clamp(elapsed / st.phaseDur, 0, 1)
    local eased = 1 - (1 - alpha) * (1 - alpha)
    if st.phase == "out" then
        local fromDir = st.startDir or st.restDir or cam.CFrame.LookVector
        local dir = fromDir:Lerp(st.targetDir, eased).Unit
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + dir)
        if alpha >= 1 then
            st.phase = "hold"
            st.phaseStart = now
            st.phaseDur = math.random(20, 70) / 1000 / (getgenv()._legitCamSpeed or 1.0)
        end
    elseif st.phase == "hold" then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + st.targetDir)
        if alpha >= 1 then
            st.phase = "back"
            st.phaseStart = now
            st.phaseDur = math.random(140, 320) / 1000 / (getgenv()._legitCamSpeed or 1.0)
        end
    elseif st.phase == "back" then
        local home = st.restDir or st.startDir or cam.CFrame.LookVector
        local dir = st.targetDir:Lerp(home, eased).Unit
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + dir)
        if alpha >= 1 then
            st.active = false
            st.phase = "idle"
            st.lastActiveEndAt = now
        end
    end
end)

-- ============================================================
-- [26.5] STAFF DETECTION
-- ============================================================
getgenv()._staffAction = _G.config.det_staff_action or "Notification"
local _staffDetected = {}
local _staffConn = nil

local function _checkStaff(plr)
    if plr == LocalPlayer or _staffDetected[plr.UserId] then return end
    local ok, rank = pcall(function() return plr:GetRankInGroup(12836673) end)
    if not ok or rank < 10 then return end
    _staffDetected[plr.UserId] = true
    local action = getgenv()._staffAction or "Notification"
    if action == "Kick" then
        pcall(function() LocalPlayer:Kick("Staff joined the server.") end)
    else
        pcall(function() UI:Notify("Staff Detected", plr.Name .. " joined the server", "info") end)
    end
end

getgenv().SetStaffDetection = function(enabled)
    _G.config.det_staff = enabled
    if _staffConn then
        pcall(function() _staffConn:Disconnect() end)
        _staffConn = nil
    end
    _staffDetected = {}
    if not enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        task.spawn(_checkStaff, plr)
    end
    _staffConn = Players.PlayerAdded:Connect(function(plr)
        if _G.config.det_staff then task.spawn(_checkStaff, plr) end
    end)
end

if isTrue(_G.config.det_staff) then
    task.defer(function() pcall(getgenv().SetStaffDetection, true) end)
end

-- ============================================================
-- [38.8] FLOATING BUTTONS
-- ============================================================
do
    local TweenService = game:GetService("TweenService")

    local function getGuiParent()
        if gethui then
            local ok, hui = pcall(gethui)
            if ok and hui then return hui end
        end
        local cg = nil
        pcall(function() cg = game:GetService("CoreGui") end)
        if cg then
            local probe = Instance.new("ScreenGui")
            probe.Name = "_probe"
            local okSet = pcall(function() probe.Parent = cg end)
            probe:Destroy()
            if okSet then return cg end
        end
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            local pg = lp:FindFirstChildOfClass("PlayerGui")
            if not pg then pcall(function() pg = lp:WaitForChild("PlayerGui", 5) end) end
            if pg then return pg end
        end
        return cg
    end

    local function createFloatingButton(config)
        local name = config.name
        local labelText = config.label
        local accent = config.accent or Color3.fromRGB(120, 200, 255)
        local onStateChanged = config.onStateChanged or function() end
        local startPosition = config.position or UDim2.new(1, -160, 0.5, 0)
        local parent = getGuiParent()

        local old = parent:FindFirstChild(name .. "_Gui")
        if old then old:Destroy() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = name .. "_Gui"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 500
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local okSetParent = pcall(function() screenGui.Parent = parent end)
        if not okSetParent or not screenGui.Parent then
            local lp = game:GetService("Players").LocalPlayer
            if lp then
                pcall(function() screenGui.Parent = lp:WaitForChild("PlayerGui", 5) end)
            end
        end
        if not screenGui.Parent then
            pcall(function() UI:Notify("Floating", "Cannot attach to any GUI parent", "error") end)
            screenGui:Destroy()
            return nil
        end

        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.fromOffset(140, 40)
        button.Position = startPosition
        button.AnchorPoint = Vector2.new(1, 0.5)
        button.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        button.BackgroundTransparency = 0
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.Active = true
        button.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(38, 38, 46)
        stroke.Thickness = 1
        stroke.Transparency = 0.1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = button

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)),
        })
        gradient.Rotation = 90
        gradient.Parent = button

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 14, 0.5, 0)
        dot.Size = UDim2.fromOffset(6, 6)
        dot.BackgroundColor3 = Color3.fromRGB(80, 80, 92)
        dot.BorderSizePixel = 0
        dot.Parent = button

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local dotGlow = Instance.new("UIStroke")
        dotGlow.Color = Color3.fromRGB(80, 80, 92)
        dotGlow.Thickness = 2
        dotGlow.Transparency = 1
        dotGlow.Parent = dot

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.Position = UDim.new(0, 30, 0, 0)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(125, 125, 138)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button

        local isActive = false
        local isDragging = false
        local dragStartPos, buttonStartPos
        local hasMoved = false

        local function tween(obj, props, duration)
            TweenService:Create(
                obj,
                TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                props
            ):Play()
        end

        local function setActive(active)
            isActive = active
            if active then
                tween(dot, { BackgroundColor3 = accent }, 0.18)
                tween(dotGlow, { Color = accent, Transparency = 0.55 }, 0.18)
                tween(label, { TextColor3 = Color3.fromRGB(232, 232, 238) }, 0.18)
                tween(stroke, { Color = accent, Transparency = 0.7 }, 0.18)
            else
                tween(dot, { BackgroundColor3 = Color3.fromRGB(80, 80, 92) }, 0.18)
                tween(dotGlow, { Color = Color3.fromRGB(80, 80, 92), Transparency = 1 }, 0.18)
                tween(label, { TextColor3 = Color3.fromRGB(125, 125, 138) }, 0.18)
                tween(stroke, { Color = Color3.fromRGB(38, 38, 46), Transparency = 0.1 }, 0.18)
            end
        end

        button.MouseEnter:Connect(function()
            if isDragging then return end
            tween(button, { BackgroundColor3 = Color3.fromRGB(22, 22, 28) }, 0.15)
            tween(stroke, { Transparency = 0 }, 0.15)
        end)

        button.MouseLeave:Connect(function()
            if isDragging then return end
            tween(button, { BackgroundColor3 = Color3.fromRGB(14, 14, 18) }, 0.15)
            tween(stroke, { Transparency = isActive and 0.7 or 0.1 }, 0.15)
        end)

        button.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            isDragging = true
            hasMoved = false
            dragStartPos = input.Position
            buttonStartPos = button.Position
            tween(button, { BackgroundColor3 = Color3.fromRGB(24, 24, 30) }, 0.1)
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not isDragging or not screenGui.Parent then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local delta = input.Position - dragStartPos
            if not hasMoved and (math.abs(delta.X) > 3 or math.abs(delta.Y) > 3) then
                hasMoved = true
            end
            button.Position = UDim2.new(
                buttonStartPos.X.Scale,
                buttonStartPos.X.Offset + delta.X,
                buttonStartPos.Y.Scale,
                buttonStartPos.Y.Offset + delta.Y
            )
        end)

        UserInputService.InputEnded:Connect(function(input)
            if not isDragging or not screenGui.Parent then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            isDragging = false
            tween(button, { BackgroundColor3 = Color3.fromRGB(14, 14, 18) }, 0.12)
            if not hasMoved then
                setActive(not isActive)
                pcall(onStateChanged, isActive)
            end
        end)

        return {
            Gui = screenGui,
            Button = button,
            SetActive = setActive,
            IsActive = function() return isActive end,
            Destroy = function()
                if screenGui then screenGui:Destroy() end
            end,
        }
    end

    local TriggerUI = nil
    local SpamUI = nil

    getgenv().OnFloatingTriggerToggle = function(enabled)
        if enabled then
            if TriggerUI and TriggerUI.Gui and TriggerUI.Gui.Parent then return end
            local ok, res = pcall(createFloatingButton, {
                name = "daemon_TriggerButton",
                label = "Trigger",
                accent = Color3.fromRGB(255, 154, 92),
                position = UDim2.new(1, -160, 0.5, -30),
                onStateChanged = function(active)
                    if getgenv().OnTriggerbotToggle then getgenv().OnTriggerbotToggle(active) end
                end,
            })
            if not ok or not res then
                pcall(function() UI:Notify("Floating Trigger", "Create failed: " .. tostring(res), "error") end)
                return
            end
            TriggerUI = res
            if TriggerUI and TriggerUI.SetActive then TriggerUI.SetActive(_G.triggerbot == true) end
            pcall(function() UI:Notify("Floating Trigger", "Created", "success") end)
        else
            if TriggerUI then TriggerUI.Destroy() TriggerUI = nil end
            if getgenv().OnTriggerbotToggle and _G.triggerbot then getgenv().OnTriggerbotToggle(false) end
        end
    end

    getgenv().OnFloatingSpamToggle = function(enabled)
        if enabled then
            if SpamUI and SpamUI.Gui and SpamUI.Gui.Parent then return end
            local ok, res = pcall(createFloatingButton, {
                name = "daemon_SpamButton",
                label = "Spam",
                accent = Color3.fromRGB(110, 211, 192),
                position = UDim2.new(1, -160, 0.5, 30),
                onStateChanged = function(active)
                    if getgenv().OnManualSpamToggle then getgenv().OnManualSpamToggle(active) end
                end,
            })
            if not ok or not res then
                pcall(function() UI:Notify("Floating Spam", "Create failed: " .. tostring(res), "error") end)
                return
            end
            SpamUI = res
            if SpamUI and SpamUI.SetActive then SpamUI.SetActive(_G.manual_spam == true) end
            pcall(function() UI:Notify("Floating Spam", "Created", "success") end)
        else
            if SpamUI then SpamUI.Destroy() SpamUI = nil end
            if getgenv().OnManualSpamToggle and _G.manual_spam then getgenv().OnManualSpamToggle(false) end
        end
    end
end

-- ============================================================
-- [38.10] ELO + CURRENCY SPOOFERS
-- ============================================================
do
    local eloSpoofed = {}
    local curSpoofed = {}
    local ELO_Conn = nil
    local Currency_Conn = nil

    local function spoofTextBucket(bucket, keys, value)
        value = tostring(value or "")
        local function _scan(container)
            if not container then return end
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local n = (obj.Name .. " " .. obj.Text):lower()
                    for _, key in ipairs(keys) do
                        if n:find(key:lower(), 1, true) then
                            if bucket[obj] == nil then bucket[obj] = obj.Text end
                            obj.Text = value
                            break
                        end
                    end
                end
            end
        end
        _scan(LocalPlayer:FindFirstChild("PlayerGui"))
        _scan(workspace)
    end

    local function restoreBucket(bucket)
        for obj, text in pairs(bucket) do
            if obj and obj.Parent then pcall(function() obj.Text = text end) end
        end
        table.clear(bucket)
    end

    local function eloApply()
        local val = tonumber(_G.config.elo_value) or 8000
        spoofTextBucket(eloSpoofed, {"elo", "rating", "rank"}, val)
    end

    local function curApply()
        local coins = tonumber(_G.config.currency_value) or 999999
        local tokens = tonumber(_G.config.token_value) or 999999
        spoofTextBucket(curSpoofed, {"coins"}, coins)
        spoofTextBucket(curSpoofed, {"tokens"}, tokens)
    end

    getgenv().OnEloSpooferToggle = function(v)
        if ELO_Conn then ELO_Conn:Disconnect(); ELO_Conn = nil end
        if v then
            eloApply()
            local _lastScan = 0
            ELO_Conn = RunService.Heartbeat:Connect(function()
                local now = os.clock()
                if now - _lastScan >= 2 then _lastScan = now; eloApply() end
            end)
        else
            restoreBucket(eloSpoofed)
        end
    end

    getgenv().OnEloValueChange = function(v)
        _G.config.elo_value = tonumber(v) or 8000
        if ELO_Conn then eloApply() end
    end

    getgenv().OnCurrencySpooferToggle = function(v)
        if Currency_Conn then Currency_Conn:Disconnect(); Currency_Conn = nil end
        if v then
            curApply()
            local _lastScan = 0
            Currency_Conn = RunService.Heartbeat:Connect(function()
                local now = os.clock()
                if now - _lastScan >= 2 then _lastScan = now; curApply() end
            end)
        else
            restoreBucket(curSpoofed)
        end
    end

    getgenv().OnCurrencyValueChange = function(v)
        _G.config.currency_value = tonumber(v) or 999999
        if Currency_Conn then curApply() end
    end

    getgenv().OnTokenValueChange = function(v)
        _G.config.token_value = tonumber(v) or 999999
        if Currency_Conn then curApply() end
    end
end

-- ============================================================
-- [38.11] DEVICE SPOOFER
-- ============================================================
do
    local TeleportService = game:GetService("TeleportService")
    local globalEnv = type(getgenv) == "function" and getgenv() or _G
    local DeviceApplying = false

    local function getSpoofType()
        local t = _G.config.device_spoof_type
        if t == "Mobile" or t == "Console" then return t end
        return "PC"
    end

    getgenv().OnDeviceSpoofTypeChange = function(value)
        _G.config.device_spoof_type = (value == "Mobile" or value == "Console") and value or "PC"
    end

    getgenv().ApplyDeviceSpoof = function()
        if DeviceApplying then return end
        DeviceApplying = true
        task.defer(function()
            pcall(function()
                local spoofType = getSpoofType()
                local payload = [==[local Source = %q
if not game:IsLoaded() then game.Loaded:Wait() end
if game.GameId ~= ]==] .. tostring(game.GameId) .. [==[ then return end
local Queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local Players = game:GetService('Players')
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Environment = getgenv()
if Environment.AllusiveDeviceSpoofQueue then
    Environment.AllusiveDeviceSpoofQueue:Disconnect()
end
local Queued = false
Environment.AllusiveDeviceSpoofQueue = Player.OnTeleport:Connect(function()
    if not Queued then
        Queue(Source:format(Source))
        Queued = true
    end
end)
local Device = ]==] .. HttpService:JSONEncode(spoofType == "Mobile" and "Phone" or spoofType) .. [==[
if game.GameId ~= ]==] .. tostring(game.GameId) .. [==[ then return end
local Previous = Environment.AllusiveDeviceSpoofRun
if Previous and Previous.JobId == game.JobId and Previous.Device == Device then return end
if Previous and Previous.Restore then Previous.Restore() end
local Run = {Device = Device, JobId = game.JobId}
Environment.AllusiveDeviceSpoofRun = Run
while not workspace:GetAttribute('ClientModulesLoaded') do
    workspace:GetAttributeChangedSignal('ClientModulesLoaded'):Wait()
end
if Environment.AllusiveDeviceSpoofRun ~= Run then return end
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Listener = require(ReplicatedStorage:WaitForChild('ClientGameModules'):WaitForChild('DeviceListener'))
local Observe = Listener.Observe
local function Apply(Callback)
    if Run.Restore then Run.Restore() end
    task.spawn(function()
        local Success, Result = pcall(function()
            Callback(Device)
            Callback(Listener.Device)
        end)
        if not Success then
            Environment.AllusiveDeviceSpoofRun = nil
            error(Result, 0)
        end
        Environment.AllusiveDeviceSpoofApplied = {Device = Device, JobId = game.JobId}
    end)
end
for _, Connection in Listener.OnChange:GetConnections() do
    if debug.info(Connection._fn, 's') == 'ReplicatedStorage.Controllers.PlayerProfileController' then
        Apply(Connection._fn)
        return
    end
end
local function ObserveDevice(Self, Callback)
    if debug.info(Callback, 's') == 'ReplicatedStorage.Controllers.PlayerProfileController' then
        Apply(Callback)
        return Self.OnChange:Connect(Callback)
    end
    return Observe(Self, Callback)
end
Run.Restore = function()
    if Listener.Observe == ObserveDevice then Listener.Observe = Observe end
    Run.Restore = nil
end
Listener.Observe = ObserveDevice
]==]

                local concatenated = payload:format(payload)

                if globalEnv.AllusiveDeviceSpoofQueue then
                    globalEnv.AllusiveDeviceSpoofQueue:Disconnect()
                    globalEnv.AllusiveDeviceSpoofQueue = nil
                end

                local queueFn = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
                if not queueFn then error("queue_on_teleport not available") end
                queueFn(concatenated)

                pcall(function() UI:Notify("Device Spoof", "Rejoining...", "info") end)
                task.wait(0.2)

                if not pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer) then
                    game:GetService("ExperienceService"):LaunchExperience({ placeId = game.PlaceId, gameInstanceId = game.JobId })
                end
            end)
            DeviceApplying = false
        end)
    end
end

-- ============================================================
-- [38.12] BALL FX: INDICATOR + TRAIL
-- ============================================================
local BallIndicator = {
    active = false, gui = nil, img = nil, holder = nil,
    position = Vector2.new(0, 0), rotation = 0,
    connection = nil, color = Color3.fromRGB(255, 255, 255)
}

getgenv().OnBallIndicatorToggle = function(enabled)
    if enabled then
        if BallIndicator.active then return end
        BallIndicator.active = true
        BallIndicator.position = Vector2.new(0, 0)
        BallIndicator.rotation = 0
        local gui = Instance.new("ScreenGui")
        gui.Name = "daemon_BallIndicator"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 999
        pcall(function()
            local p = nil
            pcall(function() if gethui then p = gethui() end end)
            if not p then pcall(function() p = game:GetService("CoreGui") end) end
            if not p then p = LocalPlayer:WaitForChild("PlayerGui") end
            gui.Parent = p
        end)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0, 50, 0, 50)
        holder.Position = UDim2.new(0.5, 0, 0.5, 0)
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.BackgroundTransparency = 1
        holder.Parent = gui
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1, 0, 1, 0)
        img.Position = UDim2.new(0.5, 0, 0.5, 0)
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Image = "rbxassetid://18604510750"
        img.ImageColor3 = BallIndicator.color
        img.ScaleType = Enum.ScaleType.Fit
        img.Parent = holder
        BallIndicator.gui = gui
        BallIndicator.img = img
        BallIndicator.holder = holder
        BallIndicator.connection = RunService.RenderStepped:Connect(function(dt)
            if not BallIndicator.active then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            local char = LocalPlayer.Character
            local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
            local ball = BallHelper.get_ball()
            if not ball or not root then img.Visible = false; return end
            img.Visible = true
            local diff = ball.Position - root.Position
            local mag = diff.Magnitude
            if mag < 0.001 then return end
            local dir = diff.Unit
            local angle = math.atan2(dir:Dot(camera.CFrame.RightVector), dir:Dot(camera.CFrame.LookVector))
            local distance = math.clamp(mag / 50 * 90, 0, 90)
            local target = Vector2.new(math.sin(angle) * distance, -math.cos(angle) * distance)
            BallIndicator.position = BallIndicator.position:Lerp(target, math.min(12 * dt, 1))
            holder.Position = UDim2.new(0.5, BallIndicator.position.X, 0.5, BallIndicator.position.Y)
            local targetRot = math.deg(angle)
            local delta = (targetRot - BallIndicator.rotation + 180) % 360 - 180
            BallIndicator.rotation = BallIndicator.rotation + delta * math.min(8 * dt, 1)
            img.Rotation = BallIndicator.rotation
        end)
    else
        if not BallIndicator.active then return end
        BallIndicator.active = false
        if BallIndicator.connection then BallIndicator.connection:Disconnect(); BallIndicator.connection = nil end
        if BallIndicator.gui then BallIndicator.gui:Destroy(); BallIndicator.gui = nil end
        BallIndicator.img = nil
        BallIndicator.holder = nil
    end
end

getgenv().OnBallIndicatorColorChange = function(val)
    local c = val
    if type(val) == "string" then
        c = getgenv()._parseHexColor(val) or BallIndicator.color
    elseif typeof(val) ~= "Color3" then
        return
    end
    BallIndicator.color = c
    if BallIndicator.img and BallIndicator.img.Parent then
        BallIndicator.img.ImageColor3 = c
    end
end

local BallTrail = {
    active = false, color = Color3.fromRGB(0, 255, 255), num_trails = 8,
    attachments = {}, connection = nil
}

local function _bt_buildColor()
    local r0 = BallTrail.color
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, r0),
        ColorSequenceKeypoint.new(0.5, Color3.new(
            math.min(r0.R * 1.3, 1), math.min(r0.G * 1.3, 1), math.min(r0.B * 1.3, 1)
        )),
        ColorSequenceKeypoint.new(1, r0)
    })
end

local function _bt_detach()
    for _, r2 in ipairs(BallTrail.attachments) do
        if r2.a0 and r2.a0.Parent then r2.a0:Destroy() end
        if r2.a1 and r2.a1.Parent then r2.a1:Destroy() end
        if r2.trail and r2.trail.Parent then r2.trail:Destroy() end
    end
    BallTrail.attachments = {}
end

local function _bt_attach(r0)
    _bt_detach()
    local r9 = BallTrail.num_trails
    for r1 = 1, r9 do
        local r10 = r1 / r9 * math.pi * 2
        local r17 = math.random(150, 250) / 100
        local r3 = math.random(-150, 150) / 100
        local r18 = Instance.new("Attachment")
        r18.Position = Vector3.new(math.cos(r10) * r17, r3, math.sin(r10) * r17)
        r18.Parent = r0
        local r2 = Instance.new("Attachment")
        r2.Position = Vector3.new(
            math.cos(r10 + math.pi * 0.7) * r17 * 1.3, -r3,
            math.sin(r10 + math.pi * 0.7) * r17 * 1.3
        )
        r2.Parent = r0
        local r19 = Instance.new("Trail")
        r19.Attachment0 = r18
        r19.Attachment1 = r2
        r19.Lifetime = 0.6
        r19.FaceCamera = true
        r19.LightEmission = 1
        r19.Texture = "rbxassetid://5029929719"
        r19.Color = _bt_buildColor()
        r19.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.3, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        r19.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.3, 0.25),
            NumberSequenceKeypoint.new(0.7, 0.15),
            NumberSequenceKeypoint.new(1, 0.02)
        })
        r19.Parent = r0
        table.insert(BallTrail.attachments, {
            a0 = r18, a1 = r2, trail = r19,
            baseAngle = r10, angle = 0,
            speed = math.random(15, 30) / 10,
            spiralSpeed = math.random(25, 45) / 10,
            radiusMultiplier = math.random(80, 120) / 100,
            pulseOffset = math.random() * math.pi * 2,
            baseRadius = r17, baseHeight = r3,
            chaosSpeed = math.random(10, 20) / 10
        })
    end
end

getgenv().OnBallTrailToggle = function(enabled)
    if enabled then
        if BallTrail.active then return end
        BallTrail.active = true
        local r0 = BallHelper.get_ball()
        if r0 then _bt_attach(r0) end
        BallTrail.connection = RunService.Heartbeat:Connect(function(dt)
            if not BallTrail.active then return end
            local v2 = BallHelper.get_ball()
            if not v2 then _bt_detach() return end
            if #BallTrail.attachments == 0 then _bt_attach(v2) end
            local v2t = tick()
            for _, v4 in ipairs(BallTrail.attachments) do
                if v4.a0.Parent then
                    v4.angle = v4.angle + v4.speed * dt
                    local v5 = v4.angle * v4.spiralSpeed
                    local v6 = math.sin(v2t * 4 + v4.pulseOffset) * 0.4 + 1
                    local v7 = math.sin(v4.angle * 3) * 0.7
                    local v8 = math.sin(v2t * v4.chaosSpeed + v4.pulseOffset) * 0.5
                    local v9 = v4.baseRadius * v4.radiusMultiplier * v6
                    local v10 = v4.baseRadius * 1.3 * v4.radiusMultiplier * v6
                    v4.a0.Position = Vector3.new(
                        math.cos(v4.baseAngle + v4.angle) * v9 + math.cos(v5) * 0.6,
                        v4.baseHeight + math.sin((v4.baseAngle + v4.angle) * 3) * 0.8 + v7 + v8 + math.sin(v5 * 2) * 0.6,
                        math.sin(v4.baseAngle + v4.angle) * v9 + math.sin(v5) * 0.6
                    )
                    v4.a1.Position = Vector3.new(
                        math.cos(v4.baseAngle + v4.angle + math.pi * 0.7) * v10 + math.sin(v5 * 1.3) * 0.5,
                        -v4.baseHeight + math.cos((v4.baseAngle + v4.angle) * 2.5) * 0.8 - v7 - v8 + math.cos(v5 * 1.7) * 0.5,
                        math.sin(v4.baseAngle + v4.angle + math.pi * 0.7) * v10 + math.cos(v5 * 1.1) * 0.5
                    )
                    v4.trail.LightEmission = math.sin(v2t * 5 + v4.pulseOffset) * 0.4 + 0.6
                end
            end
        end)
    else
        if not BallTrail.active then return end
        BallTrail.active = false
        if BallTrail.connection then BallTrail.connection:Disconnect(); BallTrail.connection = nil end
        _bt_detach()
    end
end

getgenv().OnBallTrailCountChange = function(v)
    BallTrail.num_trails = tonumber(v) or 8
end

getgenv().OnBallTrailColorChange = function(val)
    local c = val
    if type(val) == "string" then
        c = getgenv()._parseHexColor(val) or BallTrail.color
    elseif typeof(val) ~= "Color3" then
        return
    end
    BallTrail.color = c
    for _, r3 in ipairs(BallTrail.attachments) do
        if r3.trail and r3.trail.Parent then r3.trail.Color = _bt_buildColor() end
    end
end

-- ============================================================
-- [38.13] SLASH & SHIELD CHANGER
-- ============================================================
do
    local DEFAULT_COLOR = Color3.fromRGB(255, 0, 0)
    local FOLDER_KIND = {ParticleShine = "shield", ParryFX = "slash"}
    local TINT = {
        ParticleEmitter = {"Color", true}, Beam = {"Color", true}, Trail = {"Color", true},
        Decal = {"Color", false}, Texture = {"Color", false}, Highlight = {"FillColor", false},
        PointLight = {"Color", false}, SpotLight = {"Color", false}, SurfaceLight = {"Color", false},
        ImageLabel = {"ImageColor3", false}, ImageButton = {"ImageColor3", false}
    }
    local Cfgs = {
        shield = {Kind = "shield", Enabled = false, Color = DEFAULT_COLOR, Seq = ColorSequence.new(DEFAULT_COLOR)},
        slash  = {Kind = "slash",  Enabled = false, Color = DEFAULT_COLOR, Seq = ColorSequence.new(DEFAULT_COLOR)}
    }
    local Original = setmetatable({}, {__mode = "k"})
    local Conns = {}
    local BoundChar, Monitoring

    local function Disconnect(name)
        if Conns[name] then Conns[name]:Disconnect() Conns[name] = nil end
    end
    local function BindConn(name, conn)
        Disconnect(name) Conns[name] = conn
    end
    local function GetFXKind(inst)
        local c = inst
        while c and c ~= workspace do
            if FOLDER_KIND[c.Name] then return FOLDER_KIND[c.Name] end
            c = c.Parent
        end
    end
    local function Untrack(i, restore)
        local r = Original[i]
        if not r then return end
        if r.PropConn then r.PropConn:Disconnect() end
        if r.DestroyConn then r.DestroyConn:Disconnect() end
        if restore and i.Parent then pcall(function() i[r.Prop] = r.Value end) end
        Original[i] = nil
    end
    local function UntrackKind(k)
        for i, r in pairs(Original) do if r.Kind == k then Untrack(i, true) end end
    end
    local function ApplyTint(i, rec)
        local cfg = Cfgs[rec.Kind]
        if not (cfg and cfg.Enabled) then return end
        rec.Applying = true
        pcall(function() i[rec.Prop] = rec.IsSeq and cfg.Seq or cfg.Color end)
        rec.Applying = false
    end
    local function Track(i, kind)
        if Original[i] then return end
        local tint = TINT[i.ClassName]
        if not tint then return end
        kind = kind or GetFXKind(i)
        local cfg = kind and Cfgs[kind]
        if not (cfg and cfg.Enabled) then return end
        local prop, isSeq = tint[1], tint[2]
        local ok, orig = pcall(function() return i[prop] end)
        if not ok then return end
        local rec = {Prop = prop, Value = orig, Kind = kind, IsSeq = isSeq, Applying = false}
        Original[i] = rec
        rec.PropConn = i:GetPropertyChangedSignal(prop):Connect(function()
            if not rec.Applying and i.Parent then ApplyTint(i, rec) end
        end)
        rec.DestroyConn = i.Destroying:Connect(function() Untrack(i, false) end)
        ApplyTint(i, rec)
    end
    local function ScanTree(root, forcedKind)
        if not root then return end
        if forcedKind then
            if TINT[root.ClassName] then Track(root, forcedKind) end
            for _, d in root:GetDescendants() do
                if TINT[d.ClassName] then Track(d, forcedKind) end
            end
        else
            if TINT[root.ClassName] then Track(root) end
            for _, d in root:GetDescendants() do
                local k = FOLDER_KIND[d.Name]
                if k then ScanTree(d, k) elseif TINT[d.ClassName] then Track(d) end
            end
        end
    end
    local function CommitColor(cfg, color)
        cfg.Color = color
        cfg.Seq = ColorSequence.new(color)
        if cfg.Enabled then
            for i, rec in pairs(Original) do
                if rec.Kind == cfg.Kind and i.Parent then ApplyTint(i, rec) end
            end
        end
    end
    local function BindChar(char)
        if BoundChar ~= char then
            BoundChar = char
            BindConn("FX_CharDesc", char and char.DescendantAdded:Connect(function(d)
                local k = FOLDER_KIND[d.Name]
                if k then ScanTree(d, k) elseif TINT[d.ClassName] then Track(d) end
            end))
        end
        if char then ScanTree(char) end
    end
    local function BindRuntime()
        if Conns.FX_Runtime then return end
        local runtime = workspace:FindFirstChild("Runtime")
        if not runtime then return end
        BindConn("FX_Runtime", runtime.ChildAdded:Connect(function(c)
            local k = FOLDER_KIND[c.Name]
            if k then ScanTree(c, k) end
        end))
        for _, c in runtime:GetChildren() do
            local k = FOLDER_KIND[c.Name]
            if k then ScanTree(c, k) end
        end
    end
    local function StartMonitor()
        if not Monitoring then
            Monitoring = true
            BindConn("FX_Respawn", LocalPlayer.CharacterAdded:Connect(BindChar))
            BindRuntime()
        end
        BindChar(LocalPlayer.Character)
    end
    local function StopMonitorIfIdle()
        if Cfgs.shield.Enabled or Cfgs.slash.Enabled then return end
        Monitoring = false
        BoundChar = nil
        Disconnect("FX_CharDesc")
        Disconnect("FX_Runtime")
        Disconnect("FX_Respawn")
        for i in pairs(Original) do Untrack(i, true) end
    end
    local function SetEnabled(cfg, state)
        cfg.Enabled = state
        if state then StartMonitor() else UntrackKind(cfg.Kind) StopMonitorIfIdle() end
    end

    if type(_G.config.slash_color) == "string" then
        local c = getgenv()._parseHexColor(_G.config.slash_color)
        if c then Cfgs.slash.Color = c; Cfgs.slash.Seq = ColorSequence.new(c) end
    end
    if type(_G.config.shield_color) == "string" then
        local c = getgenv()._parseHexColor(_G.config.shield_color)
        if c then Cfgs.shield.Color = c; Cfgs.shield.Seq = ColorSequence.new(c) end
    end

    getgenv().OnSlashChangerToggle = function(v) SetEnabled(Cfgs.slash, v == true) end
    getgenv().OnSlashChangerColor  = function(v) CommitColor(Cfgs.slash, v) end
    getgenv().OnShieldChangerToggle = function(v) SetEnabled(Cfgs.shield, v == true) end
    getgenv().OnShieldChangerColor  = function(v) CommitColor(Cfgs.shield, v) end
end

-- ============================================================
-- [38.14] PLUSHIES
-- ============================================================
do
    local Plushies = {
        active = false,
        active_types = {},
        folder = nil,
        connection = nil,
        loaded_models = {},
        models = {
            Reimu = "rbxassetid://17657672380",
            Youmou = "rbxassetid://13242826151",
            Shion = "rbxassetid://12124164278",
            Yuuka = "rbxassetid://12181667428",
            Flandre = "rbxassetid://12136125365",
            Ayanami = "rbxassetid://11965563704",
            Padoru = "rbxassetid://11905337091"
        },
        scales = {Reimu = 1.5, Youmou = 2.3, Shion = 2.3, Yuuka = 1.5, Flandre = 3.3, Ayanami = 1.5, Padoru = 1.5},
        rotations = {
            Reimu = CFrame.Angles(0, math.rad(0), 0),
            Youmou = CFrame.Angles(0, math.rad(-90), 0),
            Shion = CFrame.Angles(math.rad(110), 0, math.rad(90)),
            Yuuka = CFrame.Angles(math.rad(-90), math.rad(180), 0),
            Flandre = CFrame.Angles(0, math.rad(-40), 0),
            Ayanami = CFrame.Angles(0, 0, 0),
            Padoru = CFrame.Angles(0, 0, 0)
        },
        positions = {
            Vector3.new(2.5, 2, 0),
            Vector3.new(-2.5, 2, 0),
            Vector3.new(0, 4, 2.5),
            Vector3.new(0, 4, -2.5),
            Vector3.new(2.5, 2, 2.5),
            Vector3.new(-2.5, 2, 2.5),
            Vector3.new(2.5, 2, -2.5)
        }
    }

    local function createPlushie(name)
        local asset = Plushies.models[name]
        if not asset then return nil end
        if not Plushies.loaded_models[name] then
            local ok, obj = pcall(function() return game:GetObjects(asset)[1] end)
            if not ok or not obj then return nil end
            Plushies.loaded_models[name] = obj
        end
        local clone = Plushies.loaded_models[name]:Clone()
        clone.Name = name
        local scale = Plushies.scales[name] or 1.5
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                part.CanCollide = false
                part.Anchored = false
                part.Size = part.Size * scale
                local mesh = part:FindFirstChildOfClass("SpecialMesh")
                if mesh then mesh.Scale = mesh.Scale * scale end
            end
        end
        local primary = clone:FindFirstChildOfClass("BasePart") or clone:FindFirstChildOfClass("MeshPart")
        if primary then clone.PrimaryPart = primary end
        return clone
    end

    local function updatePlushies()
        if not Plushies.active then return end
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart or not Plushies.folder then return end
        local index = 1
        for name in pairs(Plushies.active_types) do
            local offset = Plushies.positions[(index - 1) % #Plushies.positions + 1]
            local model = Plushies.folder:FindFirstChild(name)
            if not model then
                local newModel = createPlushie(name)
                if newModel then
                    newModel.Parent = Plushies.folder
                    newModel:SetPrimaryPartCFrame(CFrame.new(char.PrimaryPart.Position + offset))
                    model = newModel
                end
            end
            if model and model.PrimaryPart then
                local primary = model.PrimaryPart
                local bob = Vector3.new(0, math.sin(tick() * 2) * 0.3, 0)
                local target = char.PrimaryPart.CFrame * CFrame.new(offset + bob) * (Plushies.rotations[name] or CFrame.new())
                local bp = primary:FindFirstChild("PlushieBP")
                if not bp then
                    bp = Instance.new("BodyPosition")
                    bp.Name = "PlushieBP"
                    bp.MaxForce = Vector3.new(40000, 40000, 40000)
                    bp.P = 10000
                    bp.D = 1000
                    bp.Parent = primary
                end
                bp.Position = target.Position
                primary.CFrame = CFrame.new(primary.Position) * target.Rotation
            end
            index += 1
        end
        for _, child in ipairs(Plushies.folder:GetChildren()) do
            if not Plushies.active_types[child.Name] then child:Destroy() end
        end
    end

    getgenv().OnPlushiesToggle = function(v)
        if v then
            if Plushies.active then return end
            Plushies.active = true
            Plushies.folder = Instance.new("Folder")
            Plushies.folder.Name = "Plushies_Temp"
            Plushies.folder.Parent = workspace
            Plushies.connection = RunService.RenderStepped:Connect(updatePlushies)
        else
            if not Plushies.active then return end
            Plushies.active = false
            if Plushies.connection then Plushies.connection:Disconnect() Plushies.connection = nil end
            if Plushies.folder then Plushies.folder:Destroy() Plushies.folder = nil end
        end
    end

    getgenv().OnPlushiesTypesChange = function(value)
        Plushies.active_types = {}
        if type(value) == "string" then
            for name in value:gmatch("[^,]+") do
                local trimmed = name:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then Plushies.active_types[trimmed] = true end
            end
        elseif type(value) == "table" then
            for _, name in ipairs(value) do Plushies.active_types[name] = true end
        end
    end
end

-- ============================================================
-- [38.15] DAEMONS IMMORTAL
-- ============================================================
do
    local immortalBackgroundOrbitInitialized = false
    local immortalBackgroundOrbitState = { Enabled = false }
    local immortalBackgroundOrbitHRP = nil
    local immortalBackgroundOrbitCharacterConnection = nil

    local function startBackgroundOrbit()
        immortalBackgroundOrbitState.Enabled = true
        if immortalBackgroundOrbitInitialized then return end
        immortalBackgroundOrbitInitialized = true

        local function onCharacter(char)
            immortalBackgroundOrbitHRP = char:WaitForChild("HumanoidRootPart", 5)
        end

        immortalBackgroundOrbitCharacterConnection = LocalPlayer.CharacterAdded:Connect(onCharacter)
        if LocalPlayer.Character then onCharacter(LocalPlayer.Character) end

        local DesyncTypes = {}
        local oldIndexCFrame

        if hookmetamethod and newcclosure and checkcaller then
            oldIndexCFrame = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if not immortalBackgroundOrbitState.Enabled or checkcaller() then
                    return oldIndexCFrame(self, key)
                end
                if key == "CFrame" and immortalBackgroundOrbitHRP and self == immortalBackgroundOrbitHRP then
                    return DesyncTypes[1] or oldIndexCFrame(self, key)
                end
                return oldIndexCFrame(self, key)
            end))
        end

        Connections["Immortal Orbit"] = RunService.Heartbeat:Connect(function()
            if not immortalBackgroundOrbitState.Enabled or not immortalBackgroundOrbitHRP then return end
            if not immortalBackgroundOrbitHRP.Parent then
                immortalBackgroundOrbitHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not immortalBackgroundOrbitHRP then return end
            end

            DesyncTypes[1] = immortalBackgroundOrbitHRP.CFrame
            DesyncTypes[2] = immortalBackgroundOrbitHRP.AssemblyLinearVelocity

            local orbitRadius = 20
            local angleMultiplier = 20
            local rotAngle = tick() * math.pi * 2 * angleMultiplier / 5
            local pos = Vector3.new(
                math.cos(rotAngle) * orbitRadius, 0, math.sin(rotAngle) * orbitRadius
            )
            immortalBackgroundOrbitHRP.CFrame = DesyncTypes[1] + pos
            immortalBackgroundOrbitHRP.AssemblyLinearVelocity = Vector3.zero
            RunService.RenderStepped:Wait()
            if immortalBackgroundOrbitState.Enabled and immortalBackgroundOrbitHRP then
                immortalBackgroundOrbitHRP.CFrame = DesyncTypes[1]
                immortalBackgroundOrbitHRP.AssemblyLinearVelocity = DesyncTypes[2]
            end
        end)

        Connections["Immortal Offset"] = RunService.Heartbeat:Connect(function()
            if not immortalBackgroundOrbitState.Enabled then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.01, 0) end
        end)
    end

    local function stopBackgroundOrbit()
        immortalBackgroundOrbitState.Enabled = false
    end

    getgenv().OnImmortalToggle = function(v)
        if v then startBackgroundOrbit() else stopBackgroundOrbit() end
    end
end

-- ============================================================
-- [38.16] WINSTREAK SPOOFER
-- ============================================================
do
    local _winBucket = {}
    local _winConn = nil
    local _winAddConn = nil
    local _winRescanAt = 0

    local function _winApplyValue(obj)
        local val = tostring(tonumber(_G.config.v_WinstreakValue) or 100)
        if _winBucket[obj] == nil then _winBucket[obj] = obj.Text end
        obj.Text = val
    end

    local function _winCheckWidget(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
        local n = (obj.Name .. " " .. obj.Text):lower()
        if n:find("winstreak", 1, true) or n:find("win streak", 1, true) then
            _winApplyValue(obj)
        end
    end

    local function _winFullScan()
        local function _scan(c)
            if not c then return end
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    _winCheckWidget(obj)
                end
            end
        end
        _scan(LocalPlayer:FindFirstChild("PlayerGui"))
        _scan(workspace)
    end

    local function _winRefreshCached()
        local val = tostring(tonumber(_G.config.v_WinstreakValue) or 100)
        for obj in pairs(_winBucket) do
            if obj and obj.Parent then
                pcall(function() obj.Text = val end)
            else
                _winBucket[obj] = nil
            end
        end
    end

    local function _winRestore()
        for obj, text in pairs(_winBucket) do
            if obj and obj.Parent then pcall(function() obj.Text = text end) end
        end
        table.clear(_winBucket)
    end

    getgenv().OnWinstreakSpooferToggle = function(v)
        if _winConn then _winConn:Disconnect(); _winConn = nil end
        if _winAddConn then _winAddConn:Disconnect(); _winAddConn = nil end
        if v then
            _winFullScan()
            _winAddConn = workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    task.defer(function() _winCheckWidget(obj) end)
                end
            end)
            _winRescanAt = os.clock()
            _winConn = RunService.Heartbeat:Connect(function()
                local now = os.clock()
                if now - _winRescanAt >= 5 then
                    _winRescanAt = now
                    _winRefreshCached()
                end
            end)
        else
            _winRestore()
        end
    end

    getgenv().OnWinstreakValueChange = function(v)
        _G.config.v_WinstreakValue = tonumber(v) or 100
        if _winConn then
            local val = tostring(_G.config.v_WinstreakValue)
            for obj in pairs(_winBucket) do
                if obj and obj.Parent then pcall(function() obj.Text = val end) end
            end
        end
    end
end

-- ============================================================
-- [39] INITIAL CONFIG → RUNTIME SYNC
-- ============================================================
-- Problem: toggle di UI keliatan ON (baca _G.config), tapi runtime
-- hook (Connections.auto_parry, _ESP.enabled, dll) gak dipanggil
-- saat init. Hook cuma kepanggil saat user klik toggle manual.
-- Fix: replay semua hook sekali setelah setup selesai.
task.spawn(function()
    task.wait(2.5)

    local function call(name, val)
        local fn = getgenv()[name]
        if type(fn) == "function" then
            local ok, err = pcall(fn, val)
            if not ok then warn("[sync] " .. name .. " failed: " .. tostring(err)) end
        end
    end

    -- CORE
    getgenv().ParryRange = tonumber(_G.config.parry_range) or 2
    getgenv()._adaptiveMode = tostring(_G.config.adaptive_mode or "Accuracy Only")
    getgenv()._adaptiveRangeSmooth = tonumber(_G.config.parry_range) or 2
    if isTrue(_G.config.auto_parry) then call("OnAutoParryToggle", true) end
    if isTrue(_G.config.random_target) then call("OnRandomTargetToggle", true) end
    if isTrue(_G.config.auto_adaptive) then call("OnAdaptiveToggle", true) end

    -- COMBAT: PRE CLICK
    if isTrue(_G.config.auto_pre_click) and getgenv().AutoPreClick then
        getgenv().AutoPreClick.enabled = true
    end
    if isTrue(_G.config.grief_enabled) and getgenv().GPC then
        local gpc = getgenv().GPC
        if _G.config.grief_mode then gpc.mode = _G.config.grief_mode end
        if _G.config.grief_chance then gpc.chance = tonumber(_G.config.grief_chance) end
        if _G.config.grief_prox_range then gpc.proxRange = tonumber(_G.config.grief_prox_range) end
        if _G.config.grief_ball_range then gpc.ballRange = tonumber(_G.config.grief_ball_range) end
        gpc.enabled = true
        gpc:Start()
    end

    -- COMBAT: CURVE
    getgenv().RandomCurveEnabled = isTrue(_G.config.random_curve)
    getgenv().RandomCurveType = _G.config.random_curve_type or "random"
    getgenv()._SelectedCurve = _G.config.curve_method or "camera"
    if not getgenv()._CURVE_INDEX[getgenv()._SelectedCurve] then
        getgenv()._SelectedCurve = "camera"
    end

    -- COMBAT
    if isTrue(_G.config.auto_spam) then call("OnAutoSpamToggle", true) end
    if isTrue(_G.config.manual_spam) then call("OnManualSpamToggle", true) end
    if _G.config.m_ManualSpamBoost == true then getgenv().SpamBoost = true end

    -- ABILITY (master toggle aktif → semua sub yg ON auto diapply)
    if _G.config.m_AbilityExploitToggle == true then
        call("OnAbilMaster", true)
    end

    -- VISUALS: ESP & DEBUG
    if isTrue(_G.config.ability_esp) then
        pcall(function() getgenv().AbilityESP_API.Start() end)
    end
    if isTrue(_G.config.ball_debug) then call("OnBallStatsToggle", true) end
    if isTrue(_G.config.show_ping) then call("OnPingToggle", true) end

    -- VISUALS: AUDIO
    if _G.config.atmosphere_enabled ~= false then
        call("ToggleAtmosphere", true)
    end
    if getgenv().ChangeHitVolume then
        pcall(getgenv().ChangeHitVolume, tonumber(_G.config.hit_sound_volume) or 6)
    end
    if getgenv().ChangeMusicVolume then
        pcall(getgenv().ChangeMusicVolume, tonumber(_G.config.music_volume) or 3)
    end
    if getgenv().ToggleMusicLoop then
        pcall(getgenv().ToggleMusicLoop, _G.config.music_loop == true)
    end

    -- DETECTIONS
    if isTrue(_G.config.anti_phantom) then call("OnAntiPhantomToggle", true) end
    if _G.config.d_AdvWiringToggle == true then getgenv()._advWiringEnabled = true end

    -- UTILITY: HEADLESS / KORBLOX / AVATAR
    local char = LocalPlayer.Character
    if char then
        if isTrue(_G.config.headless_enabled) and _G._daemonHeadless then
            pcall(_G._daemonHeadless, char)
        end
        if isTrue(_G.config.korblox_enabled) and _G._daemonKorblox then
            pcall(_G._daemonKorblox, char)
        end
    end
    if isTrue(_G.config.avatar_changer) and _G.config.avatar_name and _G.config.avatar_name ~= "" then
        if getgenv()._daemonAvatarChanger then
            pcall(function() getgenv()._daemonAvatarChanger.set(true, _G.config.avatar_name) end)
        end
    end

    -- UTILITY: FORCE MATERIAL
    if _G.config.force_mat == true and getgenv().ToggleForceMat then
        pcall(getgenv().ToggleForceMat, true)
        if _G.config.force_mat_type and getgenv().ChangeForceMatType then
            pcall(getgenv().ChangeForceMatType, _G.config.force_mat_type)
        end
    end

    -- UTILITY: NO RENDER
    if _G.config.no_render ~= false and getgenv().ToggleNoRender then
        pcall(getgenv().ToggleNoRender, true)
    end

    -- BALL FX
    if isTrue(_G.config.ball_indicator) then
        if type(_G.config.ball_indicator_color) == "string" then
            call("OnBallIndicatorColorChange", _G.config.ball_indicator_color)
        end
        call("OnBallIndicatorToggle", true)
    end
    if isTrue(_G.config.ball_trail) then
        if _G.config.ball_trail_count then call("OnBallTrailCountChange", _G.config.ball_trail_count) end
        if type(_G.config.ball_trail_color) == "string" then
            call("OnBallTrailColorChange", _G.config.ball_trail_color)
        end
        call("OnBallTrailToggle", true)
    end

    -- SLASH & SHIELD
    if type(_G.config.slash_color) == "string" then
        local c = getgenv()._parseHexColor(_G.config.slash_color)
        if c then call("OnSlashChangerColor", c) end
    end
    if isTrue(_G.config.slash_changer) then call("OnSlashChangerToggle", true) end
    if type(_G.config.shield_color) == "string" then
        local c = getgenv()._parseHexColor(_G.config.shield_color)
        if c then call("OnShieldChangerColor", c) end
    end
    if isTrue(_G.config.shield_changer) then call("OnShieldChangerToggle", true) end

    -- PLUSHIES
    if type(_G.config.plushies_types) == "string" and _G.config.plushies_types ~= "" then
        call("OnPlushiesTypesChange", _G.config.plushies_types)
    end
    if isTrue(_G.config.plushies) then call("OnPlushiesToggle", true) end

    -- FLOATING BUTTONS
    if isTrue(_G.config.floating_trigger_button) then call("OnFloatingTriggerToggle", true) end
    if isTrue(_G.config.floating_spam_button) then call("OnFloatingSpamToggle", true) end

    -- IMMORTAL
    if isTrue(_G.config.daemons_immortal) then call("OnImmortalToggle", true) end

    -- SPOOFERS
    if isTrue(_G.config.elo_spoofer) then call("OnEloSpooferToggle", true) end
    if isTrue(_G.config.currency_spoofer) then call("OnCurrencySpooferToggle", true) end
    if isTrue(_G.config.winstreak_spoofer) then call("OnWinstreakSpooferToggle", true) end

    -- LEGIT SCREEN MOTION
    if getgenv()._legitCamAngle == nil then getgenv()._legitCamAngle = tonumber(_G.config.legit_cam_angle) or 55 end
    if getgenv()._legitCamJitter == nil then getgenv()._legitCamJitter = tonumber(_G.config.legit_cam_jitter) or 2 end
    if getgenv()._legitCamCooldown == nil then getgenv()._legitCamCooldown = tonumber(_G.config.legit_cam_cooldown) or 200 end
    if getgenv()._legitCamSpeed == nil then getgenv()._legitCamSpeed = tonumber(_G.config.legit_cam_speed) or 1.0 end
    if isTrue(_G.config.legit_screen_movement) and getgenv().SetLegitScreenMovement then
        call("SetLegitScreenMovement", true)
    end

    getgenv()._initialSyncDone = true
end)

task.spawn(function()
    while _G._DAEMON_AUTH do
        task.wait(5)
        if _G._DAEMON_AUTH ~= _AUTH then
            warn("[daemon] auth revoked or expired! Kicking player...")
            
            pcall(function()
                game:GetService("Players").LocalPlayer:Kick("[daemons.wtf] Session expired or invalid. Please re-run the loader.")
            end)
            
            break
        end
    end
end)

UI:Notify("daemon.wtf", "YO WTFF THE SCRIPT LOADED NIGGA", "success")

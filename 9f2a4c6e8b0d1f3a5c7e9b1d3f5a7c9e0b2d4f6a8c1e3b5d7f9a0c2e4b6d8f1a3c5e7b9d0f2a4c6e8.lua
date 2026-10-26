
if _G.servent then return end
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
    accuracy = nil,
    spam_threshold = nil,
    curve_keybind = nil,
    manual_notify = nil,
    curve_notify = nil,
    curve_method = '',
    anti_phantom = nil,
    anti_cooldown = nil,
    skin_changer = nil,
    manual_spam = nil,
    ability_esp = nil,
    auto_parry = nil,
    ball_debug = nil,
    auto_spam = nil,
    triggerbot_notify = nil,
    thunder_dash_no_cooldown = nil,
    ping_fix = nil,
    names = '',
    avatar_changer = nil,
    avatar_name = '',
    random_target = nil,
    show_ping = nil,
    random_curve = nil,
    random_curve_type = nil,
    auto_adaptive = nil,
    brightness = nil,
    contrast = nil,
    headless_enabled = nil,
    korblox_enabled = nil,
    unlock_all = nil,
    move_compensation = nil,
    fflag_profile = nil,
    fflag_json = nil,
    fflag_auto_load = nil,
}

if not isfolder("daemon/configs") then
    makefolder("daemon/configs")
end
local CONFIG_PATH = "daemon/configs/blade_ball.json"

local function save_cfg()
    writefile(CONFIG_PATH, HttpService:JSONEncode(_G.config))
end

local function load_cfg()
    if isfile(CONFIG_PATH) then
        _G.config = HttpService:JSONDecode(readfile(CONFIG_PATH))
    end
end

load_cfg()

-- Auto-save loop (every 1s while script is loaded)
task.spawn(function()
    repeat
        save_cfg()
        task.wait(1)
    until not _G.servent
end)

-- ========================================
-- UI (Fluent library)
-- ========================================
local _fluent_ok, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not _fluent_ok or not Fluent then
    warn("[daemon] Fluent library failed to load - UI will not render. Error: " .. tostring(Fluent))
    return
end
print("[daemon] Fluent loaded OK")

local _daemonMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local Window = Fluent:CreateWindow({
    Title = "daemon.wtf",
    SubTitle = "dsc.gg/rapptezetyee",
    TabWidth = _daemonMobile and 78 or 100,
    Size = _daemonMobile and UDim2.fromOffset(340, 280) or UDim2.fromOffset(560, 400),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl,
})
if not Window then
    warn("[daemon] CreateWindow failed - aborting UI")
    return
end
print("[daemon] window created OK")

local MainTab = Window:AddTab({ Title = "main", Icon = "shield" })
local VisualTab = Window:AddTab({ Title = "visual", Icon = "eye" })
local DetectionTab = Window:AddTab({ Title = "detection", Icon = "monitor" })
local AutoPlayTab = Window:AddTab({ Title = "auto play", Icon = "play" })
local FFlagsTab = Window:AddTab({ Title = "fflags", Icon = "file" })
local UtilTab = Window:AddTab({ Title = "utility", Icon = "wrench" })

do
    local function _wrapUI(obj, prefix)
        if not obj or obj._daemonCfgWrapped then return obj end
        obj._daemonCfgWrapped = true

        local tracked = {}

        local function _attach(opts, key)
            if type(opts) ~= "table" then return end
            if _G.config[key] == nil and opts.Default ~= nil then
                _G.config[key] = opts.Default
            elseif _G.config[key] ~= nil then
                opts.Default = _G.config[key]
            end
            local orig = opts.Callback
            opts.Callback = function(v)
                _G.config[key] = v
                pcall(save_cfg)
                if orig then pcall(orig, v) end
            end
            table.insert(tracked, { def = opts.Default, fn = orig })
        end

        local oT = obj.AddToggle
        if oT then
            obj.AddToggle = function(self, id, opts)
                if type(opts) == "table" then _attach(opts, prefix .. id) end
                return oT(self, id, opts)
            end
        end

        local oS = obj.AddSlider
        if oS then
            obj.AddSlider = function(self, id, a, ...)
                if type(a) == "table" then
                    _attach(a, prefix .. id)
                    return oS(self, id, a, ...)
                end
                return oS(self, id, a, ...)
            end
        end

        local oD = obj.AddDropdown
        if oD then
            obj.AddDropdown = function(self, id, opts)
                if type(opts) == "table" then _attach(opts, prefix .. id) end
                return oD(self, id, opts)
            end
        end

        local oI = obj.AddInput
        if oI then
            obj.AddInput = function(self, id, opts)
                if type(opts) == "table" then _attach(opts, prefix .. id) end
                return oI(self, id, opts)
            end
        end

        local oK = obj.AddKeybind
        if oK then
            obj.AddKeybind = function(self, id, opts)
                if type(opts) == "table" then
                    local kkey = prefix .. id .. "_Key"
                    local stored = _G.config[kkey]
                    if type(stored) == "string" and stored ~= "" then
                        local okE = pcall(function() return Enum.KeyCode[stored] end)
                        if okE then opts.Default = stored end
                    elseif _G.config[kkey] == nil and type(opts.Default) == "string" then
                        _G.config[kkey] = opts.Default
                    end
                    local kb = oK(self, id, opts)
                    if kb and kb.OnChanged then
                        pcall(function()
                            kb:OnChanged(function(key)
                                local kn = (typeof(key) == "EnumItem") and key.Name or tostring(key)
                                _G.config[kkey] = kn
                                pcall(save_cfg)
                            end)
                        end)
                    end
                    return kb
                end
                return oK(self, id, opts)
            end
        end

        local oSec = obj.AddSection
        if oSec then
            obj.AddSection = function(self, title, icon)
                local sec = oSec(self, title, icon)
                _wrapUI(sec, prefix)
                return sec
            end
        end

        task.delay(1, function()
            for _, e in ipairs(tracked) do
                if e.def ~= nil and e.fn then
                    pcall(e.fn, e.def)
                end
            end
        end)

        return obj
    end

    _wrapUI(MainTab, "m_")
    _wrapUI(VisualTab, "v_")
    _wrapUI(DetectionTab, "d_")
    _wrapUI(AutoPlayTab, "ap_")
    _wrapUI(FFlagsTab, "f_")
    _wrapUI(UtilTab, "u_")
end

task.defer(function()
    pcall(function() if Window and Window.SelectTab then Window:SelectTab(1) end end)
end)



-- ========================================
-- BALL HELPER STATE
-- ========================================
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

local CurrentAnimTrack -- unused remnant, kept for compatibility
local CurrentTarget    -- the random/selected target for parry direction

-- ========================================
-- REMOTE DETECTION (scrieie remote)
--
-- Uses the remote/token pipeline from scrieie instead of the old
-- old remote capture system.
-- ========================================
local replicated_storage = ReplicatedStorage

local _token
if getgc and debug and debug.info and debug.getupvalues then
    for _, Function in getgc(true) do
        if type(Function) ~= "function" or not debug.info(Function, "s"):find("PRY", 1, true) then
            continue
        end

        for _, value in debug.getupvalues(Function) do
            if type(value) == "function" then
                _token = value
                break
            end
        end

        if _token then
            break
        end
    end
end

local function _tokenize(_remote_uid)
    if type(_token) ~= "function" or type(_remote_uid) ~= "string" then
        return nil
    end

    local time = tostring(math.floor(workspace:GetServerTimeNow() * 100))
    local key = _token(_remote_uid, "TIME")
    if type(key) ~= "string" or #key == 0 then
        return nil
    end

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
        and type(args[2]) == "string"
        and type(args[3]) == "string"
        and type(args[4]) == "number"
        and typeof(args[5]) == "CFrame"
        and type(args[6]) == "table"
        and type(args[7]) == "table"
        and type(args[8]) == "boolean"
end

local function _hook(remote)
    if _reverted[remote] then
        return
    end

    local meta = getrawmetatable(remote)
    if not meta or _original[meta] then
        return
    end

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
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            _hook(remote)
        end
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

-- ========================================
-- SIGNAL FALLBACK (parry before remote captured, ported from daemon)
-- ========================================
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
            if c.Name:find("SwordsController", 1, true) == 1 then
                targetCtrl = c
                break
            end
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
        pcall(function()
            _setRemoteStatus("signal: ready", Color3.fromRGB(120, 255, 140))
        end)
        pcall(function()
            if Fluent and Fluent.Notify then
                Fluent:Notify({ Title = "daemon", Content = "signal parry ready", Duration = 3 })
            end
        end)
    end)
end)

-- Signal failed fallback check
task.spawn(function()
    task.wait(35)
    if not _signalReady then
        pcall(function()
            _setRemoteStatus("signal: failed", Color3.fromRGB(255, 90, 90))
        end)
        pcall(function()
            if Fluent and Fluent.Notify then
                Fluent:Notify({ Title = "daemon", Content = "signal parry failed to init", Duration = 5 })
            end
        end)
    end
end)

-- ========================================
-- TARGET SELECTION
-- ========================================
local recentlyPickedTargets = {}

local function pick_random_target()
    local livingPlayers = {}
    for _, char in workspace.Alive:GetChildren() do
        if char.Name ~= LocalPlayer.Name and char.PrimaryPart then
            table.insert(livingPlayers, char)
        end
    end
    
    if #livingPlayers == 0 then
        CurrentTarget = nil
        return
    end
    
    if #livingPlayers == 1 then
        CurrentTarget = livingPlayers[1]
        return
    end
    
    -- Build a candidate pool excluding recently picked targets
    local candidates = {}
    for _, char in livingPlayers do
        if not recentlyPickedTargets[char.Name] then
            table.insert(candidates, char)
        end
    end
    
    -- If we've picked everyone recently, reset and exclude only the current
    if #candidates == 0 then
        recentlyPickedTargets = {}
        for _, char in livingPlayers do
            if not CurrentTarget or char.Name ~= CurrentTarget.Name then
                table.insert(candidates, char)
            end
        end
        if #candidates == 0 then
            candidates = livingPlayers
        end
    end
    
    local picked = candidates[math.random(1, #candidates)]
    recentlyPickedTargets[picked.Name] = true
    CurrentTarget = picked
end

-- Re-pick random target whenever a ball is added or its target changes
workspace.Balls.ChildAdded:Connect(function(ball)
    if _G.config.random_target then
        pick_random_target()
    end
end)

workspace.Balls.ChildAdded:Connect(function(ball)
    task.spawn(function()
        if not ball:GetAttribute("realBall") then
            local zoomies = ball:WaitForChild("zoomies", 3)
            if not zoomies then return end
        end
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _G.config.random_target then
                pick_random_target()
            end
        end)
    end)
end)

for _, ball in workspace.Balls:GetChildren() do
    task.spawn(function()
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if _G.config.random_target then
                pick_random_target()
            end
        end)
    end)
end

-- ========================================
-- IDLE BYPASS (prevents being kicked for AFK)
-- ========================================
local function linear_predict(a, b, t)
    return a + (b - a) * t
end


-- ========================================
-- BALL HELPER FUNCTIONS
-- ========================================
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
        if ball:GetAttribute("realBall") then
            return ball
        end
    end
end

function BallHelper.get_balls()
    local balls = {}
    for _, ball in workspace.Balls:GetChildren() do
        if ball:GetAttribute("realBall") then
            table.insert(balls, ball)
        end
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
                _ballReplicator = rem
                break
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
    
    local bestTarget
    local bestDot = -math.huge
    for _, char in livingPlayers do
        local toChar = (char.PrimaryPart.Position - camera.CFrame.Position).Unit
        local dot = rayDir:Dot(toChar)
        if dot > bestDot then
            bestDot = dot
            bestTarget = char
        end
    end
    
    CurrentTarget = bestTarget
    return bestTarget
end

function BallHelper.closest_player_by_mouse()
    if _G.config.random_target then
        if not CurrentTarget then
            pick_random_target()
        end
        return CurrentTarget
    end
    return select_target_by_mouse()
end

-- ========================================
-- CURVE SYSTEM (ported from daemonX)
-- ========================================
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
        if ballSpeed < 200 then
            pool = {"fastball","speed","right","left","normal"}
        elseif ballSpeed < 350 then
            pool = {"fastball","speed","right","left","accelerated","high"}
        else
            pool = {"high","right","left","backwards","high right","high left"}
        end
    elseif type_ == "pro player classic" then
        pool = {"high","right","backwards","speed","accelerated","left","down"}
    else
        pool = getgenv()._CURVE_NAMES
    end
    getgenv()._SelectedCurve = pool[math.random(#pool)]
end

-- ========================================
-- PARRY EXECUTION
-- ========================================
-- ========================================
-- PARRY ANIMATION (cache + spam-opt, ported from daemon)
-- ========================================
local _animResolveCache = {}
local _animTrackCache = setmetatable({}, {__mode = "k"})
local _animLastSpam = 0
local _animCancelDelay = 0.12

local function _animFindIn(container)
    if not container then return nil end
    local a = container:FindFirstChild("GrabParry") or container:FindFirstChild("Parry") or container:FindFirstChild("Grab")
    if a then return a end
    local base = container:FindFirstChild("Base")
    if base then
        return base:FindFirstChild("GrabParry") or base:FindFirstChild("Parry") or base:FindFirstChild("Grab")
    end
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
    if getSword then
        pcall(function() data = getSword:Invoke(swordName) end)
    end
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

local parryActive = false
local parryCount = 0
function BallHelper.parry(bypassDebounce)
    local _nowP = tick()
    if not bypassDebounce and _nowP - (getgenv()._lastParryFireAt or 0) < 0.15 then
        return false
    end
    getgenv()._lastParryFireAt = _nowP
    pcall(getgenv()._pickRandomCurve)
    pcall(_playParryAnim)
    if not _G.config.random_target then
        select_target_by_mouse()
    end

    local curveCFrame = BallHelper.getCurveCFrame()

    local mouseLoc
    if _G.config.random_target and CurrentTarget and CurrentTarget.PrimaryPart then
        local viewportPt = workspace.CurrentCamera:WorldToViewportPoint(CurrentTarget.PrimaryPart.Position)
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
            if ok and screenPt and screenPt.Z > 0 then
                screenPositions[char.Name] = screenPt
            end
        end
    end

    -- Signal-only parry (no remote needed)
    if not _signalReady or not _signalObj then
        return false
    end

    local ok = pcall(function()
        _signalObj:Fire(0.5, curveCFrame, screenPositions, mouseLoc, false)
    end)
    if not ok then
        return false
    end

    if parryCount > 7 then return false end
    parryCount += 1
    task.delay(0.5, function() if parryCount > 0 then parryCount -= 1 end end)
    return true
end

-- ========================================
-- CURVE DETECTION
-- ========================================
function BallHelper.ball_curved(specificBall)
    local props = BallHelper.ball.properties
    local ball = specificBall or BallHelper.get_ball()
    if not ball then return false end
    
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return false end
    
    local now = tick()
    local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    local velUnit = velocity.Unit
    
    local ballPos = BallHelper.ball_position(ball)
    local myPos = LocalPlayer.Character.PrimaryPart.Position
    local toMe = (myPos - ballPos).Unit
    local distance = (myPos - ballPos).Magnitude
    
    local dotProduct = toMe:Dot(velUnit)
    local speedFactor = math.min(speed / 100, 40)
    local accelDir = (velUnit - velocity).Unit
    local crossDot = toMe:Dot(accelDir)
    local dotDifference = dotProduct - crossDot
    
    local pingThreshold = 0.5 - (pingMs / 1000)
    local timeToImpact = distance / speed - (pingMs / 1000)
    local minDistance = 15 - math.min(distance / 1000, 15) + speedFactor
    
    local clampedDot = math.clamp(dotProduct, -1, 1)
    local angleRad = math.rad(math.asin(clampedDot))
    props.lerp_radians = linear_predict(props.lerp_radians, angleRad, 0.8)
    
    if speed > 100 and timeToImpact > pingMs / 10 then
        minDistance = math.max(minDistance - 15, 15)
    end
    
    if distance < minDistance then return false end
    if dotDifference < pingThreshold then return true end
    
    if props.lerp_radians < 0.018 then
        props.last_warping = now
    end
    
    if (now - props.last_warping) < (timeToImpact / 1.5) then return true end
    if (now - props.curving) < (timeToImpact / 1.5) then return true end
    
    return dotProduct < pingThreshold
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
        or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return false
    end
    
    local velocity = target.PrimaryPart.Velocity
    local direction = (LocalPlayer.Character.PrimaryPart.Position - target.PrimaryPart.Position).Unit
    local distance = (LocalPlayer.Character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
    return { velocity = velocity, direction = direction, distance = distance }
end

local spamAccuracy = 0
function BallHelper.perfom_spam(args)
    local props = BallHelper.ball.properties
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

-- ========================================
-- ABILITY ESP (icon + name + cooldown + uses)
-- ========================================
local PlayerESPLabels = {}

local _ESP = {
    enabled = false,
    data = {},
    icon_cache = {},
    cooldowns = {},
    uses = {},
    char_conns = {},
    heartbeat = nil,
    player_added = nil,
    last_update = 0,
    abilities_mod = nil,
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
    if not m then
        _ESP.icon_cache[ability] = ""
        return ""
    end
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
        hum.DisplayDistanceType = visible
            and Enum.HumanoidDisplayDistanceType.Viewer
            or Enum.HumanoidDisplayDistanceType.None
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
            if _ESP.data[player].cd_conn then
                pcall(function() _ESP.data[player].cd_conn:Disconnect() end)
            end
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
            ic.CornerRadius = UDim.new(1, 0)
            ic.Parent = icon
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
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = badge
        
        local badgePad = Instance.new("UIPadding")
        badgePad.PaddingLeft = UDim.new(0, 6)
        badgePad.PaddingRight = UDim.new(0, 6)
        badgePad.Parent = badge
        
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
        if mu and not _ESP.uses[player] then
            _ESP.uses[player] = { max = mu, left = mu }
        end
        
        _ESP.data[player] = {
            bill = bill,
            name = name,
            icon = icon,
            badge = badge,
            timer = timer,
            cd_conn = cd_conn,
            is_passive = is_passive,
            last_ability = ab,
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
    local c2 = player.CharacterRemoving:Connect(function()
        _ESP.cooldowns[player] = nil
    end)
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
                
                if d.name.Text ~= player.DisplayName then
                    d.name.Text = player.DisplayName
                end
                
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
                            local c = Instance.new("UICorner")
                            c.CornerRadius = UDim.new(1, 0)
                            c.Parent = d.icon
                        end
                        if not d.icon:FindFirstChild("FallbackGlyph") then
                            local l = Instance.new("TextLabel")
                            l.Name = "FallbackGlyph"
                            l.Size = UDim2.fromScale(1, 1)
                            l.BackgroundTransparency = 1
                            l.Font = Enum.Font.GothamBold
                            l.TextSize = 11
                            l.TextColor3 = Color3.fromRGB(200, 200, 210)
                            l.Text = "?"
                            l.Parent = d.icon
                        end
                    else
                        d.icon.ImageTransparency = 0
                        d.icon.BackgroundTransparency = 1
                        local fg = d.icon:FindFirstChild("FallbackGlyph")
                        if fg then fg:Destroy() end
                    end
                    local dur = _esp_get_cooldown(player, ab)
                    d.is_passive = dur == nil
                    _ESP.cooldowns[player] = nil
                    local mu = _esp_get_max_uses(player, ab)
                    if mu then _ESP.uses[player] = { max = mu, left = mu }
                    else _ESP.uses[player] = nil end
                end
                
                local cd = _ESP.cooldowns[player]
                local u = _ESP.uses[player]
                local usesSuffix = u and string.format(" <font color='#50DCFF'>x%d</font>", u.left) or ""
                local badgeText, badgeColor, timerText
                
                if cd and now < cd.expiry then
                    badgeText = "Wait"
                    badgeColor = Color3.fromRGB(255, 140, 60)
                    timerText = string.format("⏱ %.1fs", cd.expiry - now) .. usesSuffix
                elseif d.is_passive then
                    badgeText = "Passive"
                    badgeColor = Color3.fromRGB(120, 120, 130)
                    timerText = u and string.format("<font color='#50DCFF'>x%d</font>", u.left) or ""
                else
                    if cd then _ESP.cooldowns[player] = nil end
                    badgeText = "Ready!"
                    badgeColor = Color3.fromRGB(65, 200, 90)
                    timerText = u and string.format("<font color='#50DCFF'>x%d</font>", u.left) or ""
                end
                
                if d.badge.Text ~= badgeText then d.badge.Text = badgeText end
                if d.badge.BackgroundColor3 ~= badgeColor then d.badge.BackgroundColor3 = badgeColor end
                if d.timer.Text ~= timerText then d.timer.Text = timerText end
            end
        end)
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        _esp_add_player(p)
    end
    
    if not _ESP.player_added then
        _ESP.player_added = Players.PlayerAdded:Connect(function(p)
            if _ESP.enabled then _esp_add_player(p) end
        end)
    end
end

local function _esp_stop()
    if not _ESP.enabled then return end
    _ESP.enabled = false
    getgenv().AbilityESP = false
    
    if _ESP.heartbeat then _ESP.heartbeat:Disconnect(); _ESP.heartbeat = nil end
    if _ESP.player_added then pcall(function() _ESP.player_added:Disconnect() end); _ESP.player_added = nil end
    
    for _, conns in pairs(_ESP.char_conns) do
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    table.clear(_ESP.char_conns)
    
    for _, d in pairs(_ESP.data) do
        pcall(function() d.bill:Destroy() end)
        if d.cd_conn then pcall(function() d.cd_conn:Disconnect() end) end
    end
    table.clear(_ESP.data)
    table.clear(_ESP.cooldowns)
    table.clear(_ESP.uses)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            _esp_set_nametag(p.Character, true)
        end
    end
end

getgenv().AbilityESP_API = {
    Start = _esp_start,
    Stop = _esp_stop,
    Toggle = function() if _ESP.enabled then _esp_stop() else _esp_start() end end,
    IsEnabled = function() return _ESP.enabled end,
}

if _G.config.ability_esp then
    task.defer(function()
        pcall(function() getgenv().AbilityESP_API.Start() end)
    end)
end

-- ========== SKIN CHANGER ==========
local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)

local SKIN_LAST_EQUIPPED_CONFIG_KEY = "Skin.LastEquippedSword"
local AUTO_CONFIG_FILE = "LeviHubX/auto_config.json"

local function readLeviHubAutoConfig()
        local data = {}
        pcall(function()
            if isfile and isfile(AUTO_CONFIG_FILE) then
                local decoded = HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE))
                if type(decoded) == "table" then
                    data = decoded
                end
            end
        end)
        return data
end

local function writeLeviHubAutoConfig(data)
        pcall(function()
            if isfolder and makefolder and not isfolder("LeviHubX") then
                makefolder("LeviHubX")
            end
            if writefile then
                writefile(AUTO_CONFIG_FILE, HttpService:JSONEncode(data or {}))
            end
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
                                swordsController = up[1]
                                break
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
            if fxName ~= "" then
                getgenv().slashName = getSlashName(fxName)
            else
                getgenv().slashName = "SlashEffect"
            end
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
                        if type(ups[i]) == "boolean" then
                            setupvalue(f, i, false)
                            break
                        end
                    end
                end
            end)
            pcall(function()
                swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
            end)
            task.spawn(function()
                local attempts = 0
                while not swordsController and attempts < 20 do
                    task.wait(0.5); attempts = attempts + 1
                end
                if not swordsController then return end
                pcall(function()
                    if swordsController.SetSword then
                        swordsController:SetSword(getgenv().swordAnimations ~= "" and getgenv().swordAnimations or getgenv().swordModel)
                    end
                end)
                pcall(function()
                    local targetSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                    if rs.Remotes:FindFirstChild("FireSwordInfo") then
                        rs.Remotes.FireSwordInfo:FireServer(targetSword)
                    end
                    if swordsController.currentSword ~= nil then
                        pcall(function() swordsController.currentSword = targetSword end)
                    end
                    if swordsController.SwordFX ~= nil then
                        pcall(function() swordsController.SwordFX = targetSword end)
                    end
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
                                                isLocal = true
                                                break
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
                                                            if rs.Shared.ReplicatedInstances.Swords:FindFirstChild(arg) then
                                                                isSword = true
                                                            end
                                                        end)
                                                        if isSword or arg == LocalPlayer:GetAttribute("CurrentlyEquippedSword") then
                                                            args[i] = fxSword
                                                            swordFound = true
                                                        end
                                                    end
                                                end
                                            end

                                            if fxSword ~= "" and not slashFound and type(args[1]) == "string" then
                                                args[1] = getgenv().slashName
                                            end
                                            if fxSword ~= "" and not swordFound and type(args[3]) == "string" then
                                                args[3] = fxSword
                                            end
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
                        if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                            setSword()
                        end
                        if not char:FindFirstChild(getgenv().swordModel) then
                            setSword()
                        end
                        for _, v in pairs(char:GetChildren()) do
                            if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                                v:Destroy()
                            end
                            task.wait()
                        end
                    end
                end
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            if getgenv().skinChanger then
                getgenv().skinChanger = false
                if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(false) end
                task.wait(2)
                getgenv().skinChanger = true
                if getgenv().setSkinChangerToggleUI then getgenv().setSkinChangerToggleUI(true) end
                task.wait(0.5)
                pcall(function() getgenv().updateSword() end)
            end
        end)
end)

getgenv().skinChanger=false; getgenv().skinChangerEnabled=false
getgenv().swordModel=""; getgenv().swordAnimations=""; getgenv().swordFX=""
getgenv().slashName="SlashEffect"
getgenv().saveLastEquippedSword=getgenv().saveLastEquippedSword or function() end

local UnlockAll = {
    enabled = false,
    ready = false,
    shop_controller = nil,
    shop_api = nil,
    shop = nil,
    swords = nil,
    sword_fn = (getgenv()._daemon and getgenv()._daemon.sword_fn) or nil,
    selected_sword = nil,
    original_sword = nil,
    explosion_module = nil,
    explosion_original = nil,
    explosion_hooked = false,
    selected_explosion = nil,
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
    favorite_swords = {},
    deleted_swords = {},
    favorite_explosions = {},
    deleted_explosions = {},
    last_equipped_sword = "",
    last_equipped_explosion = "",
}
local UA_CONFIG_FILE = "daemon/unlock_all.json"

UAConfig.save = function()
    pcall(function()
        if isfolder and not isfolder("daemon") then makefolder("daemon") end
        local data = {
            favorite_swords = UAConfig.favorite_swords or {},
            deleted_swords = UAConfig.deleted_swords or {},
            favorite_explosions = UAConfig.favorite_explosions or {},
            deleted_explosions = UAConfig.deleted_explosions or {},
            last_equipped_sword = UAConfig.last_equipped_sword or "",
            last_equipped_explosion = UAConfig.last_equipped_explosion or "",
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

local function uaToggleConn(conn, enable)
    pcall(function() if enable then conn:Enable() else conn:Disable() end end)
end

function UnlockAll.set_sword_override(arg, on)
    for _, c in ipairs(arg.parry_connections) do uaToggleConn(c, not on) end
    for _, c in ipairs(arg.fire_connections)  do uaToggleConn(c, not on) end
end

function UnlockAll.apply_chroma(arg, swordInst, swordData)
    local colorConfig = swordData.ColorConfig or swordData.TweenColorConfig
    if not colorConfig then
        if swordData.Name:find("Chroma") or swordData.Name:find("Rainbow") then
            colorConfig = "Chroma"
        end
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
                                                arg.native_map = up3
                                                return up3
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
    local favs = itemType == "Sword" and UAConfig.favorite_swords
        or itemType == "Explosion" and UAConfig.favorite_explosions or {}
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
        arg.original_sword = UALocalPlayer:GetAttribute("CurrentlyEquippedSword")
            or char:GetAttribute("CurrentlyEquippedSword")
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
        for _, item in ipairs(virt) do
            if item.InventoryKey then withKey[item.Name] = true end
        end
        for _, item in ipairs(virt) do
            if not arg.unlock_originals[item] then
                arg.unlock_originals[item] = {
                    Section = item.Section,
                    ForceHide = item.ForceHide,
                    OriginalLayoutOrder = item.OriginalLayoutOrder or item.LayoutOrder,
                }
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
                if item.Name_ ~= newName then
                    item.OriginalName_ = item.OriginalName_ or item.Name_
                    item.Name_ = newName
                    changed = true
                end
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
            local n = 0
            for _ in pairs(coll) do n = n + 1 end
            return n
        end
        return 0
    end
    if itemType == "Explosion" then
        local misc = UAReplicatedStorage:FindFirstChild("Misc")
        misc = misc and misc:FindFirstChild("DataExplosions")
        if misc then
            local n = 0
            for _, c in ipairs(misc:GetChildren()) do
                if not c:GetAttribute("Hidden") then n = n + 1 end
            end
            return n
        end
    end
    return 0
end

function UnlockAll.schedule_refresh(arg, itemType)
    arg.refresh_generation[itemType] = (arg.refresh_generation[itemType] or 0) + 1
    local gen = arg.refresh_generation[itemType]
    if type(arg.shop_controller._loadInventoryPage) == "function" then
        pcall(arg.shop_controller._loadInventoryPage, itemType)
    end
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
                for _, item in ipairs(virt) do
                    if not item.InventoryKey then count = count + 1 end
                end
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
        if base and type(base.SetTag) == "function" then
            pcall(base.SetTag, base, arg.modern_tag, on and true or nil)
        end
        if not on and ownedCopies then
            local orig = arg.modern_originals[ownedCopies]
            if orig and type(ownedCopies.Set) == "function" then
                local state = base and base.State
                local hasGet = state and type(state.Get) == "function"
                local isEquipped = false
                if hasGet then
                    local ok4, v = pcall(state.Get, state)
                    isEquipped = ok4 and v == true
                end
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
        if c and c.Function then
            table.insert(arg.original_buy_fns, c.Function)
            c:Disable()
        end
    end
    local favBtn = holder:FindFirstChild("Favorite")
    if favBtn then
        for _, c in ipairs(getconnections(favBtn.Activated)) do if c and c.Function then c:Disable() end end
        favBtn.Activated:Connect(function()
            local sel = arg.shop_controller and arg.shop_controller._selectedItem
            if sel and arg.enabled and (sel.type == "Sword" or sel.type == "Explosion") then
                arg:toggle_fav(sel.type, sel.name)
            end
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
            local ib = arg.shop:FindFirstChild("Holder")
            ib = ib and ib:FindFirstChild("InfoBG")
            ib = ib and ib:FindFirstChild("BuyButton")
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
                arg:equip_explosion(sel.name)
                buyBtn.PriceTag.TextLabel.Text = "Equipped"
                return
            end
        end
        for _, fn in ipairs(arg.original_buy_fns) do task.spawn(fn) end
    end)
    local function reapply()
        if not arg.shop.Enabled or not arg.enabled then return end
        for _, t in ipairs({ "Sword", "Explosion" }) do
            if arg.unlocked[t] then arg:schedule_refresh(t) end
        end
    end
    arg.shop:GetPropertyChangedSignal("Enabled"):Connect(function()
        if arg.shop.Enabled then task.defer(reapply) end
    end)
    if arg.shop.Enabled then task.defer(reapply) end
    return true
end

function UnlockAll.hook_sword_fx(arg)
    local shared = UAReplicatedStorage:FindFirstChild("Shared")
    shared = shared and shared:FindFirstChild("ReplicatedInstances")
    shared = shared and shared:FindFirstChild("Swords")
    if shared then
        local ok, swords = pcall(require, shared)
        if ok then arg.swords = swords end
    end
    local rem = UAReplicatedStorage:FindFirstChild("Remotes")
    rem = rem and rem:FindFirstChild("ParrySuccessAll")
    if rem then
        rem.OnClientEvent:Connect(function(...)
            if not arg.enabled or not arg.selected_sword or not arg.play_parry then return end
            local args = { ... }
            local sword = arg.swords and arg.swords:GetSword(arg.selected_sword)
            if sword and args[4] and tostring(args[4]) == UALocalPlayer.Name then
                args[1] = sword.SlashName
                args[3] = sword.Name
            end
            return arg.play_parry(unpack(args))
        end)
    end
end

function UnlockAll.setup_character(arg, char)
    if arg.character_connection then
        pcall(function() arg.character_connection:Disconnect() end)
        arg.character_connection = nil
    end
    if not char then return end
    if arg.enabled and UAConfig.last_equipped_sword and UAConfig.last_equipped_sword ~= "" then
        task.defer(function()
            if arg.enabled and UAConfig.last_equipped_sword ~= "" then arg:equip_sword(UAConfig.last_equipped_sword, false) end
        end)
    end
    local function onChild(child)
        if not arg.enabled or not child:IsA("Model") or not arg.swords or not arg.selected_sword then return end
        local sword = arg.swords:GetSword(child.Name)
        if not sword then return end
        if child.Name ~= arg.selected_sword then
            local want = arg.selected_sword
            task.defer(function()
                if arg.enabled and arg.selected_sword == want then arg:equip_sword(want, false) end
            end)
        else
            arg:apply_chroma(child, sword)
            if arg.sword_fn then
                task.defer(function()
                    if arg.enabled and arg.selected_sword == child.Name then pcall(arg.sword_fn, child.Name) end
                end)
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
        task.defer(function()
            if arg.enabled and UAConfig.last_equipped_sword ~= "" then arg:equip_sword(UAConfig.last_equipped_sword, false) end
        end)
    end
    if arg.enabled and UAConfig.last_equipped_explosion and UAConfig.last_equipped_explosion ~= "" then
        task.defer(function()
            if arg.enabled and UAConfig.last_equipped_explosion ~= "" then arg:equip_explosion(UAConfig.last_equipped_explosion) end
        end)
    end
end

function UnlockAll.set_enabled(arg, on)
    arg.enabled = on == true
    if not arg.ready then return end
    for _, itemType in ipairs({ "Sword", "Explosion" }) do
        if arg.enabled then
            if arg.shop_controller then
                arg:set_category_unlock(itemType, true)
                arg:schedule_refresh(itemType)
            end
            arg:set_modern_unlock(itemType, true)
        else
            if arg.shop_controller then
                arg.refresh_generation[itemType] = (arg.refresh_generation[itemType] or 0) + 1
                arg:set_category_unlock(itemType, false)
            end
            arg:set_modern_unlock(itemType, false)
        end
    end
    if not arg.enabled then
        arg:restore_sword()
        arg.selected_explosion = nil
    else
        arg:refresh_selected()
    end
end

-- ========================================
-- PRE CLICK MODULES (ported from daemonX)
-- ========================================
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
            if not a2 or not a2:FindFirstChild(LocalPlayer.Name) then
                APC.clicked[child.Name] = nil
                return
            end
            local b = BallHelper.get_ball()
            if not b then return end
            if b:GetAttribute("target") == LocalPlayer.Name then
                APC.clicked[child.Name] = nil
                return
            end
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
        pcall(function() Fluent:Notify({Title="Grief Target", Content=t.Name, Duration=2}) end)
    end
end)

-- ========================================
-- AUTO PARRY
-- ========================================
if not _G.config.curve_method or _G.config.curve_method == "" then
    _G.config.curve_method = "camera"
end
local accuracyMultiplier = 0.5

local AccuracyMap = {
    ["200"] = 2.20,
    ["170"] = 1.80,
    ["140"] = 1.80,
    ["100"] = 1.65,
    ["90"]  = 1.55,
    ["80"]  = 1.45,
    ["65"]  = 1.35,
}

getgenv()._lastAutoParry = getgenv()._lastAutoParry or 0
getgenv()._lastTrainingParry = getgenv()._lastTrainingParry or 0
getgenv()._ballParryCooldown = getgenv()._ballParryCooldown or setmetatable({}, {__mode = "k"})

getgenv()._etaBaseWindow = 0.22
getgenv()._etaPredThresh = 18
getgenv()._etaPingSamples = getgenv()._etaPingSamples or {}
getgenv()._etaJitterBuffer = getgenv()._etaJitterBuffer or 0
getgenv()._etaSpeedBuckets = getgenv()._etaSpeedBuckets or {
    slow = { mult = 0.9 },
    mid  = { mult = 1.0 },
    fast = { mult = 1.2 },
}

getgenv()._etaFeedback = getgenv()._etaFeedback or {
    fires = 0,
    successes = 0,
    ftMax = 0.21,
    ftMin = 0.17,
}

pcall(function()
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if getgenv()._etaFeedback then
            getgenv()._etaFeedback.successes = getgenv()._etaFeedback.successes + 1
        end
    end)
end)

task.spawn(function()
    while task.wait(5) do
        local fb = getgenv()._etaFeedback
        if not fb then break end
        if fb.fires >= 15 then
            local _otherActive = _G.triggerbot or _G.manual_spam or _G.config.auto_spam
                or (getgenv().GriefPreClick and getgenv().GriefPreClick.enabled)
                or (getgenv().AutoPreClick and getgenv().AutoPreClick.enabled)
            if _otherActive then
                fb.fires = 0
                fb.successes = 0
            else
                local rate = math.min(fb.successes / math.max(fb.fires, 1), 1.0)
                local oldMax = fb.ftMax
                if rate < 0.6 then
                    fb.ftMax = math.min(fb.ftMax + 0.02, 0.28)
                elseif rate < 0.75 then
                    fb.ftMax = math.min(fb.ftMax + 0.01, 0.26)
                elseif rate > 0.95 then
                    fb.ftMax = math.max(fb.ftMax - 0.005, 0.18)
                end
                fb.ftMin = fb.ftMax - 0.04
                fb.fires = 0
                fb.successes = 0
                if fb.ftMax ~= oldMax then
                    pcall(function()
                        Fluent:Notify({
                            Title = "eta auto-tune",
                            Content = string.format("window: %.0f-%.0fms", fb.ftMin * 1000, fb.ftMax * 1000),
                            Duration = 3,
                        })
                    end)
                end
            end
        end
    end
end)

-- ========================================
-- TargetSelect + BallPos_Get (ported from daemonX)
-- ========================================
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

local sParry = MainTab:AddSection("parry", "sword")
local sCombat = MainTab:AddSection("combat", "crosshair")
sParry:AddToggle("AutoParryToggle", {
    Title = "auto parry",
    Default = _G.config.auto_parry ~= false,
    Callback = function(enabled)
        _G.config.auto_parry = enabled
        if enabled then
            Connections.auto_parry = RunService.PreSimulation:Connect(function()
                if _G.triggerbot then return end
                if _G.singularity_active then
                    parryActive = false
                    parryCount = 0
                    return
                end
                if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then
                    parryActive = false
                    parryCount = 0
                    return
                end
                if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
                
                local props = BallHelper.ball.properties
                local realBall = BallHelper.get_ball()
                local allBalls = BallHelper.get_balls()
                
                for _, ball in allBalls do
                    if not ball then return end
                    
                    local zoomies = ball:FindFirstChild("zoomies")
                    if not zoomies then return end
                    
                    ball:GetAttributeChangedSignal("target"):Once(function()
                        parryActive = false
                        if _G.config.random_target then
                            pick_random_target()
                        end
                    end)
                    
                    if parryActive then return end
                    
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
                    if not _pingSamples then
                        _pingSamples = {}
                        getgenv()._etaPingSamples = _pingSamples
                    end
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
                        _buckets = {
                            slow = { mult = 0.95 },
                            mid  = { mult = 1.0 },
                            fast = { mult = 1.2 },
                        }
                        getgenv()._etaSpeedBuckets = _buckets
                    end
                    local _bucketName = rawSpeed < 150 and "slow" or (rawSpeed < 350 and "mid" or "fast")
                    local _bucketMult = (_buckets[_bucketName] and _buckets[_bucketName].mult) or 1.0
                    local targetDistance = (baseTargetDistance * _velMult * _bucketMult) + _jitterStuds
                    local _fb = getgenv()._etaFeedback
                    local _ftMax = (_fb and _fb.ftMax) or 0.21
                    local _ftMin = (_fb and _fb.ftMin) or 0.17
                    local _maxDist = rawSpeed * _ftMax
                    local _minDist = rawSpeed * _ftMin
                    if targetDistance > _maxDist then targetDistance = _maxDist end
                    if targetDistance < _minDist then targetDistance = _minDist end
                    local isCurving = BallHelper.ball_curved()
                    
                    if ball:FindFirstChild("AeroDynamicSlashVFX") then
                        Debris:AddItem(ball.AeroDynamicSlashVFX, 0)
                        props.aerodynamic_time = tick()
                    end
                    
                    if workspace.Runtime:FindFirstChild("Tornado") then
                        local tornadoTime = workspace.Runtime.Tornado:GetAttribute("TornadoTime") or 1
                        if (tick() - props.aerodynamic_time) < tornadoTime + 0.314159 then
                            return
                        end
                    end
                    
                    getgenv()._tsunamiState = getgenv()._tsunamiState or { active_until = 0, last = setmetatable({}, {__mode = "k"}) }
                    local _ts = getgenv()._tsunamiState
                    local _nowTs = tick()
                    local _prevTs = _ts.last[ball]
                    if rawSpeed >= 1000 then
                        _ts.active_until = _nowTs + 1.5
                    elseif _prevTs then
                        local _dtTs = _nowTs - _prevTs.at
                        local _dvTs = rawSpeed - _prevTs.speed
                        if _dtTs > 0 and _dtTs < 0.3 and _dvTs >= 500 then
                            _ts.active_until = _nowTs + 1.5
                        end
                    end
                    _ts.last[ball] = { speed = rawSpeed, at = _nowTs }
                    local _tsunamiActive = _nowTs < _ts.active_until
                    
                    if realBallTarget == LocalPlayer.Name and isCurving and not _tsunamiActive then return end
                    
                    local _fireOk
                    if _tsunamiActive then
                        local _closingEta = math.max(_totalClosing, 1)
                        local _etaTs = distance / _closingEta
                        local _etaClamp = math.clamp(_etaTs, 0, 0.35)
                        local _predPos = _ballPos + velocity * _etaClamp
                        local _predDist = (LocalPlayer.Character.PrimaryPart.Position - _predPos).Magnitude
                        local _hitRadius = 15
                        local _margin = math.max(rawSpeed * 0.06, 20)
                        _fireOk = _predDist <= (_hitRadius + _margin) and _ballClosing > 0
                    else
                        _fireOk = distance <= targetDistance
                    end
                    
                    if ballTarget == LocalPlayer.Name and _fireOk and accuracyFactor * 0.8 then
                        BallHelper.parry(_G.config.curve_method)
                        parryActive = true
                        if getgenv()._etaFeedback then
                            getgenv()._etaFeedback.fires = getgenv()._etaFeedback.fires + 1
                        end
                    end
                    
                    local startTime = tick()
                    repeat
                        RunService.PreSimulation:Wait()
                    until (tick() - startTime) >= 1 or not parryActive
                    parryActive = false
                end
            end)
        else
            if Connections.auto_parry then
                Connections.auto_parry:Disconnect()
                Connections.auto_parry = nil
            end
        end
    end
})

-- ========================================
-- CHAIN PARRY
-- ========================================
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
    parryActive = false
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
    
    if isFast and timeToImpact > pingMs / 10 then
        minDistance = math.max(minDistance - 15, 15)
    end
    
    if parrier ~= myHrp and distance > minDistance then
        BallHelper.ball.properties.curving = tick()
    end
end)

-- ========================================
-- ACCURACY DROPDOWN
-- ========================================
local savedAcc = tostring(_G.config.accuracy or 100)
if not AccuracyMap[savedAcc] then savedAcc = "100" end
accuracyMultiplier = AccuracyMap[savedAcc]

sParry:AddDropdown("DropdownAccuracy", {
    Title = "accuracy",
    Values = { "200", "170", "140", "100", "90", "80", "65" },
    Multi = false,
    Default = savedAcc,
    Callback = function(value)
        task.spawn(function()
            local mult = AccuracyMap[value]
            if mult then
                accuracyMultiplier = mult
                _G.config.accuracy = tonumber(value)
            end
        end)
    end
})

-- ========================================
-- RANDOM TARGET
-- ========================================
sParry:AddToggle("RandomTargetToggle", {
    Title = "random target",
    Default = _G.config.random_target or false,
    Callback = function(enabled)
        task.spawn(function()
            _G.config.random_target = enabled
            CurrentTarget = nil
            recentlyPickedTargets = {}
            if enabled then
                pick_random_target()
            end
        end)
    end
})

-- ========================================
-- AUTO ADAPTIVE ACCURACY
-- ========================================
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
            count = 0
            last = now
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
            pcall(function()
                ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            local fps = getgenv()._adaptiveFps or 60
            if fps <= 0 then fps = 60 end
            if ping <= 0 then ping = 50 end
            local pingScore = math.clamp(ping / 100, 0, 2)
            local fpsScore = math.clamp((120 - fps) / 100, 0, 1.5)
            local score = math.clamp(pingScore * 1.5 + fpsScore * 1.0, 0, 3)
            local target = math.floor(200 - score * 45 + 0.5)
            target = math.clamp(target, 65, 200)
            local smooth = getgenv()._adaptiveSmooth
            smooth = smooth + (target - smooth) * 0.35
            getgenv()._adaptiveSmooth = smooth
            local finalAcc = math.clamp(math.floor(smooth + 0.5), 65, 200)
            accuracyMultiplier = _mapAccToMult(finalAcc)
            getgenv()._adaptiveAcc = finalAcc
            local _lbl = getgenv()._adaptiveLabel
            if _lbl then
                pcall(function()
                    if type(_lbl.SetTitle) == "function" then
                        _lbl:SetTitle(string.format("adaptive: %d", finalAcc))
                    end
                    if type(_lbl.SetDesc) == "function" then
                        _lbl:SetDesc(string.format("ping: %dms | fps: %d", math.floor(ping), math.floor(fps)))
                    end
                end)
            end
        else
            getgenv()._adaptiveAcc = _G.config.accuracy or 100
            local _lbl = getgenv()._adaptiveLabel
            if _lbl then
                pcall(function()
                    if type(_lbl.SetTitle) == "function" then
                        _lbl:SetTitle("manual: " .. tostring(_G.config.accuracy or 100))
                    end
                    if type(_lbl.SetDesc) == "function" then
                        _lbl:SetDesc("adaptive disabled")
                    end
                end)
            end
        end
    end
end)

local sAdaptive = sParry
sAdaptive:AddToggle("AutoAdaptiveToggle", {
    Title = "auto adaptive accuracy",
    Description = "Auto-tune accuracy from ping + FPS (disables manual)",
    Default = _G.config.auto_adaptive or false,
    Callback = function(enabled)
        getgenv()._adaptiveEnabled = enabled
        _G.config.auto_adaptive = enabled
        if enabled then
            getgenv()._adaptiveSmooth = 100
        end
    end
})
getgenv()._adaptiveLabel = nil
pcall(function()
    getgenv()._adaptiveLabel = sAdaptive:AddParagraph({ Title = "adaptive", Content = "--" })
end)

-- ========================================
-- CURVE METHOD DROPDOWN + HOTKEYS
-- ========================================
local sCurve = sCombat
local curveMethodDropdown = sCurve:AddDropdown("CurveMethod", {
    Title = "curve method",
    Values = getgenv()._CURVE_NAMES,
    Multi = false,
    Default = _G.config.curve_method or "camera",
    Callback = function(value)
        _G.config.curve_method = value
        getgenv()._SelectedCurve = value
    end
})

sCurve:AddToggle("RandomCurveMode", {
    Title = "random curve",
    Description = "pick a random curve each parry",
    Default = _G.config.random_curve or false,
    Callback = function(state)
        getgenv().RandomCurveEnabled = state
        _G.config.random_curve = state
        if not state then
            getgenv()._SelectedCurve = _G.config.curve_method or "camera"
        end
    end
})

sCurve:AddDropdown("RandomCurveType", {
    Title = "random curve type",
    Description = "random = all | pro player = velocity-aware | pro player classic = legacy pool",
    Values = {"random", "pro player", "pro player classic"},
    Default = _G.config.random_curve_type or "random",
    Multi = false,
    Callback = function(v)
        getgenv().RandomCurveType = v
        _G.config.random_curve_type = v
    end
})

getgenv().RandomCurveEnabled = _G.config.random_curve or false
getgenv().RandomCurveType = _G.config.random_curve_type or "random"

local CurveHotkeys = {
    [Enum.KeyCode.One]   = "camera",
    [Enum.KeyCode.Two]   = "random",
    [Enum.KeyCode.Three] = "accelerated",
    [Enum.KeyCode.Four]  = "backwards",
    [Enum.KeyCode.Five]  = "slow",
    [Enum.KeyCode.Six]   = "high",
    [Enum.KeyCode.Seven] = "normal",
    [Enum.KeyCode.Eight] = "speed",
    [Enum.KeyCode.Nine]  = "down",
    [Enum.KeyCode.Zero]  = "left",
}

local lastSetCurveMethod
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not _G.config.curve_keybind then return end
    
    local newMethod = CurveHotkeys[input.KeyCode]
    if not newMethod then return end
    
    if _G.config.curve_method == newMethod then
        if _G.config.curve_notify then
            Fluent:Notify({ Title = "curve method", Content = "already " .. newMethod, Duration = 3 })
        end
        return
    end
    
    _G.config.curve_method = newMethod
    curveMethodDropdown:SetValue(newMethod)
    lastSetCurveMethod = newMethod
    
    if _G.config.curve_notify then
        Fluent:Notify({ Title = "curve method", Content = newMethod, Duration = 3 })
    end
end)

sCurve:AddToggle("HotkeyCurveToggle", {
    Title = "hotkey curve",
    Default = _G.config.curve_keybind or false,
    Callback = function(enabled)
        task.spawn(function()
            _G.config.curve_keybind = enabled
        end)
    end
})

sCurve:AddToggle("HotkeyNotifyToggle", {
    Title = "hotkey notify",
    Default = _G.config.curve_notify or false,
    Callback = function(enabled)
        task.spawn(function()
            _G.config.curve_notify = enabled
        end)
    end
})

-- ========================================
-- THUNDER DASH 0 COOLDOWN (Fallen)
-- ========================================
local thunderDashAbility
local thunderDashOriginalCooldown
local thunderDashOriginalReduction
local thunderDashLoopToken = 0

local function ensureThunderDashAbility()
    if thunderDashAbility then
        return true
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local abilities = shared and shared:FindFirstChild("Abilities")
    local abilityModule = abilities and abilities:FindFirstChild("Thunder Dash")
    if not abilityModule then
        return false
    end

    local ok, result = pcall(require, abilityModule)
    if not ok or not result then
        return false
    end

    thunderDashAbility = result
    thunderDashOriginalCooldown = result.cooldown
    thunderDashOriginalReduction = result.cooldownReductionPerUpgrade
    return true
end

local function applyThunderDashNoCooldown()
    if not ensureThunderDashAbility() then
        return false
    end

    local ok = pcall(function()
        thunderDashAbility.cooldown = 0
        thunderDashAbility.cooldownReductionPerUpgrade = 0
    end)
    return ok
end

local function restoreThunderDashCooldown()
    if not thunderDashAbility then
        return
    end

    pcall(function()
        thunderDashAbility.cooldown = thunderDashOriginalCooldown
        thunderDashAbility.cooldownReductionPerUpgrade = thunderDashOriginalReduction
    end)
end

local function startThunderDashNoCooldown()
    thunderDashLoopToken += 1
    local token = thunderDashLoopToken

    applyThunderDashNoCooldown()
    task.spawn(function()
        while thunderDashLoopToken == token do
            applyThunderDashNoCooldown()
            task.wait(0.5)
        end
    end)
end

local function stopThunderDashNoCooldown()
    thunderDashLoopToken += 1
    restoreThunderDashCooldown()
end

local sAbility = MainTab:AddSection("ability", "zap")

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
    if ok and mod then
        pcall(function()
            mod.cooldown = 0
            mod.cooldownReductionPerUpgrade = 0
        end)
    end
end

local function _abil_start(key, moduleName, flag)
    if _abil_conns[key] then return end
    _abil_conns[key] = RunService.Heartbeat:Connect(function()
        if getgenv().AbilityExploit and getgenv()[flag] then
            _abil_apply_zero(moduleName)
        end
    end)
end

local function _abil_stop(key)
    if _abil_conns[key] then
        _abil_conns[key]:Disconnect()
        _abil_conns[key] = nil
    end
end

local function _abil_activate_all()
    if getgenv().ThunderDashNoCooldown then
        _abil_apply_zero("Thunder Dash")
        _abil_start("thunder", "Thunder Dash", "ThunderDashNoCooldown")
    end
    if getgenv().SuperJumpNoCooldown then
        _abil_apply_zero("Super Jump")
        _abil_start("sjump", "Super Jump", "SuperJumpNoCooldown")
    end
    if getgenv().DashNoCooldown then
        _abil_apply_zero("Dash")
        _abil_start("dash", "Dash", "DashNoCooldown")
    end
end

local function _abil_deactivate_all()
    _abil_stop("thunder")
    _abil_stop("sjump")
    _abil_stop("dash")
end

local function _abil_set_master(v)
    getgenv().AbilityExploit = v
    if v then _abil_activate_all() else _abil_deactivate_all() end
end

local function _abil_set_sub(key, flag, moduleName, v)
    getgenv()[flag] = v
    if v and getgenv().AbilityExploit then
        _abil_apply_zero(moduleName)
        _abil_start(key, moduleName, flag)
    else
        _abil_stop(key)
    end
end

sAbility:AddToggle("AbilityExploitToggle", {
    Title = "ability exploit",
    Description = "master toggle for no-cooldown sub-features",
    Default = getgenv().AbilityExploit,
    Callback = function(v) _abil_set_master(v) end,
})

sAbility:AddToggle("ThunderDashToggle", {
    Title = "thunder dash no cooldown",
    Default = getgenv().ThunderDashNoCooldown,
    Callback = function(v) _abil_set_sub("thunder", "ThunderDashNoCooldown", "Thunder Dash", v) end,
})

sAbility:AddToggle("SuperJumpToggle", {
    Title = "super jump no cooldown",
    Default = getgenv().SuperJumpNoCooldown,
    Callback = function(v) _abil_set_sub("sjump", "SuperJumpNoCooldown", "Super Jump", v) end,
})

sAbility:AddToggle("DashNoCooldownToggle", {
    Title = "dash no cooldown",
    Default = getgenv().DashNoCooldown,
    Callback = function(v) _abil_set_sub("dash", "DashNoCooldown", "Dash", v) end,
})

sAbility:AddToggle("CooldownProtectionToggle", {
    Title = "cooldown protection",
    Description = "auto-press ability button when parry is on cooldown",
    Default = getgenv().CooldownProtection,
    Callback = function(v) getgenv().CooldownProtection = v end,
})

task.defer(function()
    if getgenv().AbilityExploit then pcall(_abil_activate_all) end
end)

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
        pcall(function()
            ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
        end)
    end
end)


-- ========================================
-- TRIGGERBOT
-- ========================================
local triggerActive = false
local function Trigger(ball)
    if triggerActive then return end
    triggerActive = true
    BallHelper.parry()
    
    ball:GetAttributeChangedSignal("target"):Once(function()
        triggerActive = false
    end)
    
    local startTime = tick()
    task.spawn(function()
        repeat
            RunService.PreSimulation:Wait()
        until (tick() - startTime >= 1 or not triggerActive)
        triggerActive = false
    end)
end

local sTrigger = sCombat
getgenv()._triggerbotKeybind = sTrigger:AddKeybind("TriggerbotKeybind", {
    Title = "triggerbot",
    Mode = "Toggle",
    Default = "T",
    Callback = function(enabled)
        _G.triggerbot = enabled
        if enabled then
            Fluent:Notify({ Title = "triggerbot", Content = "on", Duration = 2 })
            Connections.triggerbot = RunService.PreSimulation:Connect(function()
                if _G.singularity_active then return end
                if getgenv()._advParryBlocked and getgenv()._advParryBlocked() then return end
                local ball = BallHelper.get_ball()
                if not ball then return end
                local target = ball:GetAttribute("target")
                if target == LocalPlayer.Name then
                    Trigger(ball)
                end
            end)
        else
            Fluent:Notify({ Title = "triggerbot", Content = "off", Duration = 2 })
            if Connections.triggerbot then
                Connections.triggerbot:Disconnect()
                Connections.triggerbot = nil
            end
        end
    end
})

-- ========================================
-- AUTO SPAM
-- ========================================
local statsService = game:GetService("Stats")
local lastAutoParryFire = 0

local sSpam = sCombat
sSpam:AddToggle("AutoSpamToggle", {
    Title = "auto spam",
    Default = _G.config.auto_spam or false,
    Callback = function(enabled)
        _G.config.auto_spam = enabled
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
                local maxAccuracy = BallHelper.perfom_spam({
                    Ball_Properties = ballProps,
                    Entity_Properties = playerProps,
                    Ping = pingClamped,
                })
                
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
            if Connections.auto_spam then
                Connections.auto_spam:Disconnect()
                Connections.auto_spam = nil
            end
        end
    end
})

sSpam:AddSlider("Slider", {
    Title = "threshold",
    Description = "",
    Default = _G.config.spam_threshold or 3,
    Min = 1,
    Max = 3,
    Rounding = 1,
    Callback = function(value)
        task.spawn(function()
            _G.config.spam_threshold = tonumber(value)
        end)
    end
})

-- ========================================
-- MANUAL SPAM
-- ========================================
sSpam:AddSlider("ManualSpamMinSpeed", {
    Title = "manual spam min speed",
    Description = "Auto-off when ball speed drops below this",
    Default = _G.config.manual_spam_min_speed or 5,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        _G.config.manual_spam_min_speed = tonumber(value)
    end
})

local _ms = {
    enabled = false,
    acc = 0,
    cps = tonumber(_G.config.m_ManualSpamCPS) or 500,
    cpsMode = _G.config.m_ManualSpamCPSMode ~= false,
    animationFix = _G.config.m_ManualSpamAnimationFix == true,
}
local _manualSpamAutoOff = false
local manualSpamKeybind

local function _ms_getInterval()
    if not _ms.cpsMode then
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        return math.max(ping / 1000, 0.05)
    end
    local cps = math.clamp(_ms.cps or 500, 1, 2000)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        cps = math.clamp(cps, 5, 60)
    end
    return 1 / cps
end

local function _ms_stop()
    _ms.enabled = false
    _G.manual_spam = false
    if Connections.manual_spam then
        Connections.manual_spam:Disconnect()
        Connections.manual_spam = nil
    end
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
        if _G.config.manual_notify then
            pcall(function() Fluent:Notify({ Title = "manual spam", Content = "auto-off: ball too slow", Duration = 2 }) end)
        end
        pcall(function()
            if manualSpamKeybind and manualSpamKeybind.SetValue then manualSpamKeybind:SetValue(false) end
        end)
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
    
    if _ms.animationFix and getgenv()._ZX_AnimationFixPF then
        pcall(getgenv()._ZX_AnimationFixPF)
    end
end

local function _ms_start()
    if _ms.enabled then return end
    _manualSpamAutoOff = false
    _ms.enabled = true
    _ms.acc = 0
    _G.manual_spam = true
    if Connections.manual_spam then Connections.manual_spam:Disconnect() end
    Connections.manual_spam = RunService.PreSimulation:Connect(_ms_loop)
    if _G.config.manual_notify then
        pcall(function() Fluent:Notify({ Title = "manual spam", Content = "on", Duration = 2 }) end)
    end
end

manualSpamKeybind = sSpam:AddKeybind("Keybind", {
    Title = "manual spam",
    Mode = "Toggle",
    Default = _G.config.manual_spam or "E",
    Callback = function(enabled)
        if enabled then
            _ms_start()
        else
            _ms_stop()
            if _G.config.manual_notify and not _manualSpamAutoOff then
                pcall(function() Fluent:Notify({ Title = "manual spam", Content = "off", Duration = 2 }) end)
            end
        end
    end
})

getgenv()._manualSpamKeybind = manualSpamKeybind
manualSpamKeybind:OnChanged(function(value)
    _G.config.manual_spam = value
end)

sSpam:AddSlider("ManualSpamCPS", {
    Title = "cps",
    Description = "fires per second (mobile 5-60, pc 1-2000)",
    Default = _G.config.m_ManualSpamCPS or 500,
    Min = 1, Max = 2000, Rounding = 0,
    Callback = function(v)
        _ms.cps = tonumber(v) or 500
        _G.config.m_ManualSpamCPS = _ms.cps
    end
})

sSpam:AddToggle("ManualSpamCPSMode", {
    Title = "cps mode",
    Description = "on = use cps slider, off = ping-based legacy",
    Default = _G.config.m_ManualSpamCPSMode ~= false,
    Callback = function(v)
        _ms.cpsMode = v
        _G.config.m_ManualSpamCPSMode = v
    end
})

sSpam:AddToggle("ManualSpamAnimFix", {
    Title = "animation fix",
    Description = "reset parry anim spam if hook available",
    Default = _G.config.m_ManualSpamAnimationFix == true,
    Callback = function(v)
        _ms.animationFix = v
        _G.config.m_ManualSpamAnimationFix = v
    end
})

sSpam:AddToggle("ManualSpamBoost", {
    Title = "spam boost",
    Description = "wider burst budget (12ms vs 6ms)",
    Default = _G.config.m_ManualSpamBoost == true,
    Callback = function(v)
        getgenv().SpamBoost = v
        _G.config.m_ManualSpamBoost = v
    end
})

sSpam:AddToggle("ManualNotifyToggle", {
    Title = "manual notify",
    Default = _G.config.manual_notify or false,
    Callback = function(enabled)
        _G.config.manual_notify = enabled
    end
})

-- Auto Ability
sAbility:AddToggle("AutoAbilityToggle", {
    Title = "auto ability",
    Description = "Auto-fire ability when ball close & fast",
    Default = false,
    Callback = function(v) getgenv().AutoAbility = v end
})
getgenv().AutoAbility = false

sAbility:AddSlider("AutoAbilityRange", {
    Title = "ability range",
    Description = "Fire ability only when ball within this distance",
    Default = 20, Min = 8, Max = 60, Rounding = 0,
    Callback = function(v) getgenv().AutoAbilityRange = v end
})
getgenv().AutoAbilityRange = 20

sAbility:AddSlider("AutoAbilityMinSpeed", {
    Title = "ability min speed",
    Description = "Ball must be at least this fast",
    Default = 100, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) getgenv().AutoAbilityMinSpeed = v end
})
getgenv().AutoAbilityMinSpeed = 100

-- Grief Pre Click
local sPreClick = MainTab:AddSection("pre click", "mouse-pointer")

sPreClick:AddToggle("GriefPreClickToggle", {
    Title = "grief pre click",
    Description = "Pre-click when ball nears your grief target",
    Default = false,
    Callback = function(v)
        GPC.enabled = v
        if v then GPC:Start() else GPC:Stop() end
    end
})

sPreClick:AddDropdown("GriefPreClickMode", {
    Title = "grief target mode",
    Values = {"Keybind", "Near"},
    Default = "Keybind",
    Multi = false,
    Callback = function(v) GPC.mode = v end
})

sPreClick:AddSlider("GriefPreClickChance", {
    Title = "grief chance %",
    Default = 40, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) GPC.chance = v end
})

sPreClick:AddSlider("GriefPreClickRange", {
    Title = "grief follow range",
    Default = 25, Min = 10, Max = 80, Rounding = 0,
    Callback = function(v) GPC.proxRange = v end
})

sPreClick:AddSlider("GriefPreClickBallRange", {
    Title = "grief ball trigger range",
    Default = 22, Min = 8, Max = 50, Rounding = 0,
    Callback = function(v) GPC.ballRange = v end
})

sPreClick:AddToggle("AutoPreClickToggle", {
    Title = "auto pre click",
    Description = "Pre-click after fast-ball elimination",
    Default = false,
    Callback = function(v) APC.enabled = v end
})

-- ========================================
-- VISUAL TAB - SWORD CHANGER (TOP)
-- Source: paid_lastesap (1).txt
-- Order: Sword Changer -> Sword Name -> Save Last Equipped Sword
-- ========================================
local skinChangerToggle
local savedSwordForUI = loadLastEquippedSword()
if getgenv().swordModel == "" and savedSwordForUI ~= "" then
    getgenv().swordModel = savedSwordForUI
    getgenv().swordAnimations = savedSwordForUI
    getgenv().swordFX = savedSwordForUI
end

local sSword = VisualTab:AddSection("visual", "eye")
local sAudio = VisualTab:AddSection("audio", "volume-2")
local sWinstreak = VisualTab:AddSection("winstreak", "flame")

local _WS_ICON_ORANGE = "rbxassetid://89658127170771"
local _WS_ICON_BLUE = "rbxassetid://75598166115655"

local _ws_state = {
    running = false,
    streak = tostring(_G.config.v_WinstreakValue or "0"),
    char_conn = nil,
    original = {},
    text_conn = nil,
}

local function _ws_parse(s)
    if not s or s == "" then return 0 end
    local cleaned = tostring(s):gsub(",", ""):gsub(" ", "")
    return tonumber(cleaned) or 0
end

local function _ws_apply(display)
    if not display then return end
    local main = display:FindFirstChild("Main")
    if not main then return end
    local icon = main:FindFirstChild("Icon")
    local value = main:FindFirstChild("Value")
    if not icon or not value then return end
    if _ws_state.original.enabled == nil then _ws_state.original.enabled = display.Enabled end
    if _ws_state.original.text == nil then _ws_state.original.text = value.Text end
    if _ws_state.original.icon == nil then _ws_state.original.icon = icon.Image end
    local n = _ws_parse(_ws_state.streak)
    icon.Image = n >= 10 and _WS_ICON_BLUE or _WS_ICON_ORANGE
    local expected = string.format("<b><stroke color='rgb(0,0,0)' thickness='2'>%s</stroke></b>", tostring(_ws_state.streak))
    if value.Text ~= expected then value.Text = expected end
    display.Enabled = true
    if _ws_state.text_conn then pcall(function() _ws_state.text_conn:Disconnect() end) end
    _ws_state.text_conn = value:GetPropertyChangedSignal("Text"):Connect(function()
        if not _ws_state.running then return end
        local n2 = _ws_parse(_ws_state.streak)
        icon.Image = n2 >= 10 and _WS_ICON_BLUE or _WS_ICON_ORANGE
        local exp = string.format("<b><stroke color='rgb(0,0,0)' thickness='2'>%s</stroke></b>", tostring(_ws_state.streak))
        if value.Text ~= exp then value.Text = exp end
    end)
end

local function _ws_update()
    if not _ws_state.running then return end
    local char = LocalPlayer.Character
    if not char then return end
    local display = char:FindFirstChild("WinStreakDisplay")
    if not display then return end
    _ws_apply(display)
end

local function _ws_start()
    if _ws_state.running then return end
    _ws_state.running = true
    _ws_state.original = {}
    _ws_update()
    _ws_state.char_conn = LocalPlayer.CharacterAdded:Connect(function()
        _ws_state.original = {}
        task.wait(1.5)
        pcall(_ws_update)
    end)
    task.spawn(function()
        while _ws_state.running do
            task.wait(1)
            pcall(_ws_update)
        end
    end)
end

local function _ws_stop()
    _ws_state.running = false
    if _ws_state.char_conn then pcall(function() _ws_state.char_conn:Disconnect() end); _ws_state.char_conn = nil end
    if _ws_state.text_conn then pcall(function() _ws_state.text_conn:Disconnect() end); _ws_state.text_conn = nil end
    local char = LocalPlayer.Character
    local display = char and char:FindFirstChild("WinStreakDisplay")
    if display then
        local main = display:FindFirstChild("Main")
        if main then
            local icon = main:FindFirstChild("Icon")
            local value = main:FindFirstChild("Value")
            if icon and _ws_state.original.icon then pcall(function() icon.Image = _ws_state.original.icon end) end
            if value and _ws_state.original.text then pcall(function() value.Text = _ws_state.original.text end) end
        end
        if _ws_state.original.enabled ~= nil then pcall(function() display.Enabled = _ws_state.original.enabled end) end
    end
    _ws_state.original = {}
end

sWinstreak:AddToggle("WinstreakToggle", {
    Title = "winstreak spoofer",
    Description = "modify game's WinStreakDisplay",
    Default = false,
    Callback = function(v) if v then _ws_start() else _ws_stop() end end,
})

sWinstreak:AddInput("WinstreakValue", {
    Title = "winstreak amount",
    Description = "supports comma (19,228) and decimal (1.5)",
    Placeholder = "0",
    Default = tostring(_G.config.v_WinstreakValue or "0"),
    Numeric = false,
    Finished = true,
    Callback = function(v)
        _ws_state.streak = tostring(v or "0")
        if _ws_state.running then pcall(_ws_update) end
    end,
})
skinChangerToggle = sSword:AddToggle("SkinChanger", {
    Title = "sword changer",
    Default = getgenv().skinChanger or false,
    Callback = function(value)
        getgenv().skinChanger = value
        getgenv().skinChangerEnabled = value
        _G.config.skin_changer = value
        task.spawn(function()
            if value and getgenv().swordModel ~= "" then
                if getgenv().updateSword then pcall(getgenv().updateSword) end
            end
        end)
    end
})

getgenv().setSkinChangerToggleUI = function(value)
    getgenv().skinChanger = value
    getgenv().skinChangerEnabled = value
    pcall(function()
        if skinChangerToggle and skinChangerToggle.Value ~= value then
            skinChangerToggle:SetValue(value)
        end
    end)
end

sSword:AddInput("SwordName", {
    Title = "sword name",
    Default = (getgenv().swordModel ~= "" and getgenv().swordModel) or loadLastEquippedSword(),
    Placeholder = "Enter sword name (e.g. DualPrince)...",
    Numeric = false,
    Finished = true,
    Callback = function(value)
        value = tostring(value or "")
        getgenv().swordModel = value
        getgenv().swordAnimations = value
        getgenv().swordFX = value
        _G.config.names = value
        if getgenv().skinChanger and value ~= "" and getgenv().updateSword then
            pcall(getgenv().updateSword)
        end
        if getgenv().autoLoadLastSword ~= false and getgenv().saveLastEquippedSword and value ~= "" then
            pcall(getgenv().saveLastEquippedSword, value)
        end
    end
})

sSword:AddToggle("SaveLastSword", {
    Title = "save last equipped sword",
    Default = true,
    Callback = function(value)
        getgenv().autoLoadLastSword = value
    end
})

sSword:AddToggle("UnlockAllToggle", {
    Title = "unlock all",
    Description = "unlock all swords & explosions in shop",
    Default = _G.config.unlock_all or false,
    Callback = function(v)
        _G.config.unlock_all = v
        if getgenv().UnlockAll then
            pcall(function() getgenv().UnlockAll:set_enabled(v) end)
        end
    end,
})

do
    local _ccName = "daemon_ColorCorrection"
    local _getCC = function()
        local LT = game:GetService("Lighting")
        local cc = LT:FindFirstChild(_ccName)
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = _ccName
            cc.Parent = LT
        end
        return cc
    end
    local _bright = tonumber(_G.config.brightness) or 0
    local _contrast = tonumber(_G.config.contrast) or 0
    local _applyColor = function()
        pcall(function()
            local cc = _getCC()
            cc.Brightness = _bright
            cc.Contrast = _contrast
        end)
    end
    task.spawn(function()
        task.wait(1)
        _applyColor()
    end)
    local sColor = VisualTab:AddSection("color correction", "palette")
    sColor:AddSlider("BrightnessSlider", {
        Title = "brightness",
        Description = "Scene brightness (-1 to 1)",
        Default = _bright,
        Min = -1, Max = 1, Rounding = 2,
        Callback = function(v)
            _bright = v
            _G.config.brightness = v
            _applyColor()
        end
    })
    sColor:AddSlider("ContrastSlider", {
        Title = "contrast",
        Description = "Scene contrast (-1 to 1)",
        Default = _contrast,
        Min = -1, Max = 1, Rounding = 2,
        Callback = function(v)
            _contrast = v
            _G.config.contrast = v
            _applyColor()
        end
    })
end


-- ========================================
-- VISUAL TAB - ABILITY ESP
-- ========================================
local sEsp = sSword
sEsp:AddToggle("AbilityESPToggle", {
    Title = "ability esp",
    Default = _G.config.ability_esp or false,
    Callback = function(enabled)
        _G.config.ability_esp = enabled
        if enabled then
            pcall(function() getgenv().AbilityESP_API.Start() end)
        else
            pcall(function() getgenv().AbilityESP_API.Stop() end)
        end
    end
})

-- ========================================
-- BALL STATS
-- ========================================
local ballStatsGui
local sHud = sSword
sHud:AddToggle("BallStatsToggle", {
    Title = "ball stats",
    Default = _G.config.ball_debug or false,
    Callback = function(enabled)
        _G.config.ball_debug = enabled
        if enabled then
            ballStatsGui = Instance.new("ScreenGui")
            ballStatsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            ballStatsGui.ResetOnSpawn = false
            
            local label = Instance.new("TextLabel")
            label.Parent = ballStatsGui
            label.Size = UDim2.new(0.2, 0, 0.05, 0)
            label.Position = UDim2.new(0.7, 0, 0.05, 0)
            label.TextSize = 26
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.Fantasy
            label.Text = "waiting..."
            
            local maxPerBall = {}
            
            Connections.ball_stats = RunService.Heartbeat:Connect(function()
                local balls = BallHelper.get_balls() or {}
                if #balls == 0 then
                    label.Text = "waiting..."
                    label.TextColor3 = Color3.new(1, 1, 1)
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
                        if new > highestSpeed then
                            highestSpeed = new
                            fastestBall = ball
                        end
                    end
                end
                
                if fastestBall then
                    local speed = highestSpeed
                    local atLimit = speed >= 2200
                    local text = ("ball velocity: %.0f"):format(speed)
                    if atLimit then text = text .. " (LIMIT!)" end
                    label.Text = text
                    label.TextColor3 = atLimit and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
                else
                    label.Text = "waiting..."
                    label.TextColor3 = Color3.new(1, 1, 1)
                end
            end)
        else
            if Connections.ball_stats then
                Connections.ball_stats:Disconnect()
                Connections.ball_stats = nil
            end
            if ballStatsGui then
                ballStatsGui:Destroy()
                ballStatsGui = nil
            end
        end
    end
})

-- ========================================
-- SHOW REAL PING + FPS
-- ========================================
local _pingGui
local _pingLabel
local _fpsLabel
local _pingConn
local _fpsCounter
local _fpsLast
local _fpsValue

sHud:AddToggle("ShowPingToggle", {
    Title = "show real ping",
    Description = "Display current ping + FPS",
    Default = _G.config.show_ping or false,
    Callback = function(value)
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

            _fpsCounter = 0
            _fpsLast = tick()
            _fpsValue = 0

            _pingConn = RunService.RenderStepped:Connect(function()
                _fpsCounter = _fpsCounter + 1
                local now = tick()
                if now - _fpsLast >= 0.5 then
                    _fpsValue = math.floor(_fpsCounter / (now - _fpsLast) + 0.5)
                    _fpsCounter = 0
                    _fpsLast = now

                    pcall(function()
                        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                        local pc = Color3.fromRGB(120, 255, 140)
                        if ping > 100 then pc = Color3.fromRGB(255, 220, 60) end
                        if ping > 200 then pc = Color3.fromRGB(255, 90, 90) end
                        _pingLabel.Text = string.format("ping: <font color=\'#%02x%02x%02x\'>%dms</font>",
                            math.floor(pc.R * 255), math.floor(pc.G * 255), math.floor(pc.B * 255), math.floor(ping))
                    end)

                    local fc = Color3.fromRGB(120, 255, 140)
                    if _fpsValue < 60 then fc = Color3.fromRGB(255, 220, 60) end
                    if _fpsValue < 30 then fc = Color3.fromRGB(255, 90, 90) end
                    _fpsLabel.Text = string.format("fps: <font color=\'#%02x%02x%02x\'>%d</font>",
                        math.floor(fc.R * 255), math.floor(fc.G * 255), math.floor(fc.B * 255), _fpsValue)
                end
            end)
        else
            if _pingConn then _pingConn:Disconnect(); _pingConn = nil end
            if _pingGui then _pingGui:Destroy(); _pingGui = nil end
            _pingLabel = nil
            _fpsLabel = nil
        end
    end
})

-- ========================================
-- DETECTIONS (ported from daemonX)
-- ========================================
_G.Detect = _G.Detect or {
    infinity = false, deathslash = false, timehole = false,
    slashesoffury = false, forcefield = false, singularity = false,
    sof_combo = false,
}
_G.infinity_active = false
_G.deathslash_active = false
_G.timehole_active = false
_G.slashesoffury_active = false
_G.forcefield_active = false
_G.singularity_active = false

pcall(function()
    ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
        _G.deathslash_active = d or false
    end)
end)
pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        _G.infinity_active = b or false
    end)
end)

do
    _G.forcefield_active = false
    local _ffConns = {}
    local function _clearFF()
        for _, conn in ipairs(_ffConns) do pcall(function() conn:Disconnect() end) end
        _ffConns = {}
    end
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
        _clearFF()
        _checkFF(c)
        table.insert(_ffConns, c.AttributeChanged:Connect(function(attr)
            if attr == "PassiveLock_ForceField" or attr == "Forcefield" or attr == "ForceField" then
                _checkFF(c)
            end
        end))
        table.insert(_ffConns, c.ChildAdded:Connect(function(obj)
            if obj:IsA("ForceField") then _checkFF(c) end
        end))
        table.insert(_ffConns, c.ChildRemoved:Connect(function(obj)
            if obj:IsA("ForceField") then _checkFF(c) end
        end))
    end
    task.spawn(function()
        local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        _watchFF(c)
        LocalPlayer.CharacterAdded:Connect(function(ch)
            _G.forcefield_active = false
            task.wait(0.1)
            _watchFF(ch)
        end)
    end)
end

do
    local function _checkSing(c)
        if not c then _G.singularity_active = false; return end
        local hrp = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
        if hrp and hrp:FindFirstChild("SingularityCape") then
            _G.singularity_active = true
            return
        end
        if c:FindFirstChild("SingularityCape", true) then
            _G.singularity_active = true
            return
        end
        _G.singularity_active = false
    end
    local function _watchSing(c)
        if not c then return end
        _checkSing(c)
        c.DescendantAdded:Connect(function(obj)
            if obj.Name == "SingularityCape" then _G.singularity_active = true end
        end)
        c.DescendantRemoving:Connect(function(obj)
            if obj.Name == "SingularityCape" then
                task.defer(function() _checkSing(c) end)
            end
        end)
    end
    task.spawn(function()
        local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        _watchSing(c)
        LocalPlayer.CharacterAdded:Connect(function(ch)
            _G.singularity_active = false
            _watchSing(ch)
        end)
    end)
end

pcall(function()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == LocalPlayer or p == LocalPlayer.Name or (p and p.Name == LocalPlayer.Name) then
            _G.timehole_active = true
        end
    end)
    net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
        _G.timehole_active = false
    end)
    net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == LocalPlayer or p == LocalPlayer.Name or (p and p.Name == LocalPlayer.Name) then
            _G.slashesoffury_active = true
        end
    end)
    net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        _G.slashesoffury_active = false
    end)
    net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
        task.spawn(function()
            local n = 0
            while _G.slashesoffury_active and n < 36 do
                if _G.Detect.slashesoffury then
                    pcall(BallHelper.parry)
                    n = n + 1
                    task.wait(0.05)
                else
                    break
                end
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
                    if n and n < 1 then
                        pcall(BallHelper.parry)
                    end
                    task.wait(0.12)
                end
            end
        end)
    end)
end)

_G.Quasar = _G.Quasar or {antiBlindness = false, antiDisorientate = false, savedCF = nil}
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
            else
                _G.Quasar.savedCF = nil
            end
        end
    end)
end)

_G.AutoRematch = false
local _remConns = {}
local _remFired = false
local function _remFire(btn)
    local n = 0
    pcall(function()
        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire(); n = n + 1 end
    end)
    if n == 0 then pcall(firesignal, btn.Activated) end
end
local function _remCheck(root)
    if not _G.AutoRematch then return end
    local btns = root:FindFirstChild("Buttons")
    btns = btns and btns:FindFirstChild("RematchButton")
    if _remFired or not btns or not btns.Visible then return end
    if LocalPlayer:GetAttribute("Rematch") then return end
    _remFired = true
    _remFire(btns)
end
local function _setAutoRematch(v)
    _G.AutoRematch = v
    for _, c in ipairs(_remConns) do pcall(function() c:Disconnect() end) end
    _remConns = {}
    if v then
        task.spawn(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
            if not pg then return end
            local duel = pg:WaitForChild("DuelUI", 10)
            if not duel then return end
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
    else
        _remFired = false
    end
end

local antiPhantomActive = false

local dt = DetectionTab:AddSection("detections", "shield")
dt:AddToggle("InfinityDetection", {Title="Infinity Detection",Default=false,
    Callback=function(v) _G.Detect.infinity = v end})
dt:AddToggle("DeathSlashDetection", {Title="Death Slash Detection",Default=false,
    Callback=function(v) _G.Detect.deathslash = v end})
dt:AddToggle("TimeHoleDetection", {Title="Time Hole Detection",Default=false,
    Callback=function(v) _G.Detect.timehole = v end})
dt:AddToggle("SlashesOfFuryDetection", {Title="Slashes of Fury Detection",Default=false,
    Callback=function(v) _G.Detect.slashesoffury = v end})
dt:AddToggle("ForcefieldDetection", {Title="Forcefield Detection",Default=false,
    Callback=function(v) _G.Detect.forcefield = v end})
dt:AddToggle("SingularityDetection", {Title="Singularity Detection",Default=false,
    Callback=function(v) _G.Detect.singularity = v end})
dt:AddToggle("SOFComboToggle", {Title="ComboCounter Detection",Description="Watch Slash of Fury ComboCounter",Default=false,
    Callback=function(v) _G.Detect.sof_combo = v end})

local ct = DetectionTab:AddSection("counter", "shield-check")
ct:AddToggle("AntiPhantomToggle", {
    Title = "anti phantom",
    Default = _G.config.anti_phantom or false,
    Callback = function(enabled)
        _G.config.anti_phantom = enabled
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
                            cloneref(game:GetService("TweenService")):Create(
                                character.HumanoidRootPart,
                                TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                                { CFrame = ball.CFrame * CFrame.new(0, 0, -3) }
                            ):Play()
                        end
                        antiPhantomActive = false
                    end)
                    
                    ball:GetAttributeChangedSignal("target"):Once(function()
                        cancelled = true
                        antiPhantomActive = false
                    end)
                end
            end)
        else
            if Connections.anti_phantom then
                Connections.anti_phantom:Disconnect()
                Connections.anti_phantom = nil
            end
            antiPhantomActive = false
        end
    end
})
ct:AddToggle("AntiBlindnessToggle", {Title="Anti Blindness",Description="Block Quasar blindness",Default=false,
    Callback=function(v) if _G.Quasar then _G.Quasar.antiBlindness = v end end})
ct:AddToggle("AntiDisorientateToggle", {Title="Anti Disorientate",Description="Block Quasar camera spin",Default=false,
    Callback=function(v) if _G.Quasar then _G.Quasar.antiDisorientate = v end end})
ct:AddToggle("AutoRematchToggle", {Title="Auto Rematch",Description="Auto click rematch on win/lose",Default=false,
    Callback=function(v) _setAutoRematch(v) end})

-- ========================================
-- ADVANCED DETECTIONS (Dribble / Pull / Pulse / Tornado / HellHook)
-- ========================================
_G.AdvDetect = {
    Dribble  = _G.config.d_AdvDribbleDetection == true,
    Pull     = _G.config.d_AdvPullDetection == true,
    Pulse    = _G.config.d_AdvPulseDetection == true,
    Tornado  = _G.config.d_AdvTornadoDetection == true,
    HellHook = _G.config.d_AdvHellHookDetection == true,
}
_G.AdvFlag = _G.AdvFlag or {
    Dribble  = false,
    Pull     = false,
    Pulse    = false,
    Tornado  = false,
    HellHook = false,
}
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
            if stamp and (now - stamp) > maxAge then
                _G.AdvFlag[key] = false
                _advStamps[key] = nil
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not _G.AdvDetect.Dribble then
            _G.AdvFlag.Dribble = false
            continue
        end
        local found = false
        local balls = workspace:FindFirstChild("Balls")
        if balls then
            for _, ball in pairs(balls:GetChildren()) do
                if not ball then continue end
                local ok = false
                pcall(function()
                    if ball:GetAttribute("dribble") == true or ball:GetAttribute("Dribble") == true then
                        ok = true
                    end
                end)
                if not ok and ball.Name and string.find(ball.Name:lower(), "dribble") then
                    ok = true
                end
                if not ok and (ball:FindFirstChild("Dribble") or ball:FindFirstChild("Dribbling")) then
                    ok = true
                end
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
            local isMe = false
            local flag = true
            if typeof(a) == "Instance" and a:IsA("Player") then
                isMe = (a == LocalPlayer or a.Name == LocalPlayer.Name)
                if type(b) == "boolean" then flag = b end
            elseif type(a) == "string" then
                isMe = (a == LocalPlayer.Name)
                if type(b) == "boolean" then flag = b end
            elseif type(a) == "boolean" then
                flag = a
                isMe = true
            elseif type(b) == "boolean" then
                flag = b
                isMe = true
            end
            if not isMe then return end
            getgenv()._ZX_PullGen = getgenv()._ZX_PullGen + 1
            local myGen = getgenv()._ZX_PullGen
            if not flag then
                getgenv()._ZX_PullActive = false
                _advSetFlag("Pull", false)
                return
            end
            getgenv()._ZX_PullActive = true
            _advSetFlag("Pull", true)
            task.delay(2, function()
                if getgenv()._ZX_PullGen == myGen then
                    getgenv()._ZX_PullActive = false
                    _advSetFlag("Pull", false)
                end
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
        if char:GetAttribute("Pulsed") then
            _G.AdvFlag.Pulse = true
        end
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
        if not _G.AdvDetect.Tornado then
            _G.AdvFlag.Tornado = false
            return
        end
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
    local hookConn
    local hookPos
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
            if hookConn then
                task.wait(1)
                hookConn:Disconnect()
                hookConn = nil
                hookPos = nil
            end
        end)
    end
end)

getgenv().Detections = {
    SetDribble  = function(v) _G.AdvDetect.Dribble = v end,
    SetPull     = function(v) _G.AdvDetect.Pull = v end,
    SetPulse    = function(v) _G.AdvDetect.Pulse = v end,
    SetTornado  = function(v) _G.AdvDetect.Tornado = v end,
    SetHellHook = function(v) _G.AdvDetect.HellHook = v end,
    IsDribble   = function() return _G.AdvFlag.Dribble end,
    IsPull      = function() return _G.AdvFlag.Pull end,
    IsPulse     = function() return _G.AdvFlag.Pulse end,
    IsTornado   = function() return _G.AdvFlag.Tornado end,
    IsHellHook  = function() return _G.AdvFlag.HellHook end,
    IsTornadoBlocking = function(distance, hit_radius)
        local tornado = _advGetTornado()
        if not tornado then return false end
        local tornadoTime = tornado:GetAttribute("TornadoTime") or 1
        if (tick() - _G.AdvTornadoTime) < (tornadoTime + 0.314159) then
            if distance > (hit_radius or 15) then return true end
        end
        return false
    end,
    GetState = function()
        return {
            Dribble  = _G.AdvFlag.Dribble,
            Pull     = _G.AdvFlag.Pull,
            Pulse    = _G.AdvFlag.Pulse,
            Tornado  = _G.AdvFlag.Tornado,
            HellHook = _G.AdvFlag.HellHook,
        }
    end,
}

local _advSection = DetectionTab:AddSection("advanced", "radar")
_advSection:AddToggle("AdvDribbleDetection", {
    Title = "dribble detection",
    Description = "flag when any ball is being dribbled",
    Default = _G.AdvDetect.Dribble,
    Callback = function(v) _G.AdvDetect.Dribble = v end,
})
_advSection:AddToggle("AdvPullDetection", {
    Title = "pull detection",
    Description = "flag when PlrPulled targets you",
    Default = _G.AdvDetect.Pull,
    Callback = function(v) _G.AdvDetect.Pull = v end,
})
_advSection:AddToggle("AdvPulseDetection", {
    Title = "pulse detection",
    Description = "flag when pulse ability is active",
    Default = _G.AdvDetect.Pulse,
    Callback = function(v) _G.AdvDetect.Pulse = v end,
})
_advSection:AddToggle("AdvTornadoDetection", {
    Title = "tornado detection",
    Description = "flag tornado + destroy AeroDynamicSlashVFX",
    Default = _G.AdvDetect.Tornado,
    Callback = function(v) _G.AdvDetect.Tornado = v end,
})
_advSection:AddToggle("AdvHellHookDetection", {
    Title = "anti hell hook",
    Description = "freeze position when hell hooked",
    Default = _G.AdvDetect.HellHook,
    Callback = function(v) _G.AdvDetect.HellHook = v end,
})
local _advFlagLabel = nil
pcall(function()
    _advFlagLabel = _advSection:AddParagraph({
        Title = "live flags",
        Content = "dribble: -- | pull: -- | pulse: -- | tornado: -- | hellhook: --",
    })
end)
task.spawn(function()
    while task.wait(0.5) do
        if _advFlagLabel then
            pcall(function()
                local s = _G.AdvFlag
                _advFlagLabel:SetDesc(string.format(
                    "dribble: %s | pull: %s | pulse: %s | tornado: %s | hellhook: %s",
                    s.Dribble and "Y" or "N",
                    s.Pull and "Y" or "N",
                    s.Pulse and "Y" or "N",
                    s.Tornado and "Y" or "N",
                    s.HellHook and "Y" or "N"
                ))
            end)
        end
    end
end)

getgenv()._advWiringEnabled = _G.config.d_AdvWiringToggle == true
_advSection:AddToggle("AdvWiringToggle", {
    Title = "respect detections in auto",
    Description = "skip parry / triggerbot / auto spam while Pull / Pulse / HellHook active",
    Default = false,
    Callback = function(v) getgenv()._advWiringEnabled = v end,
})
getgenv()._advParryBlocked = function()
    if not getgenv()._advWiringEnabled then return false end
    local D = getgenv().Detections
    if not D then return false end
    if D.IsPull and D.IsPull() then return true end
    if D.IsPulse and D.IsPulse() then return true end
    if D.IsHellHook and D.IsHellHook() then return true end
    return false
end


-- ========================================
-- HIT SOUND CHANGER
-- ========================================
do
    local hsList = {"Medal","Fatality","Skeet","Switches","Rust Headshot","Neverlose Sound","Bubble","Laser","Steve","Call of Duty","Bat","TF2 Critical","Saber","Bameware"}
    local hsIds = {Medal="rbxassetid://6607336718",Fatality="rbxassetid://6607113255",Skeet="rbxassetid://6607204501",Switches="rbxassetid://6607173363",["Rust Headshot"]="rbxassetid://138750331387064",["Neverlose Sound"]="rbxassetid://110168723447153",Bubble="rbxassetid://6534947588",Laser="rbxassetid://7837461331",Steve="rbxassetid://4965083997",["Call of Duty"]="rbxassetid://5952120301",Bat="rbxassetid://3333907347",["TF2 Critical"]="rbxassetid://296102734",Saber="rbxassetid://8415678813",Bameware="rbxassetid://3124331820"}
    local hsFolder = Instance.new("Folder")
    hsFolder.Name = "Useful Utility"
    hsFolder.Parent = workspace
    local hsObj = Instance.new("Sound")
    hsObj.Volume = 6
    hsObj.SoundId = hsIds.Medal
    hsObj.Parent = hsFolder
    local hsEnabled = false
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if hsEnabled and hsObj then hsObj:Play() end
    end)
    local s = sAudio
    s:AddToggle("HitSoundToggle", {Title="Hit Sound Changer",Description="Play custom sound on parry success",Default=true,
        Callback=function(v) hsEnabled = v end})
    s:AddDropdown("HitSoundPick", {Title="Sound",Values=hsList,Default="Call of Duty",Multi=false,
        Callback=function(v) if hsIds[v] then hsObj.SoundId = hsIds[v] end end})
    s:AddSlider("HitSoundVolume", {Title="Volume",Default=6,Min=0,Max=20,Rounding=0,
        Callback=function(v) hsObj.Volume = v end})
end

-- ========================================
-- BACKGROUND MUSIC
-- ========================================
do
    local musLib = {Eeyuh="rbxassetid://16190782181",Sweep="rbxassetid://103508936658553",Bounce="rbxassetid://134818882821660",["Everybody Wants To Rule The World"]="rbxassetid://87209527034670",["Missing Money"]="rbxassetid://134668194128037",["Sour Grapes"]="rbxassetid://117820392172291",Erwachen="rbxassetid://124853612881772",["Grasp the Light"]="rbxassetid://89549155689397",["Beyond the Shadows"]="rbxassetid://120729792529978",["Rise to the Horizon"]="rbxassetid://72573266268313",["Echoes of the Candy Kingdom"]="rbxassetid://103040477333590",Speed="rbxassetid://125550253895893",["Lo-fi Chill A"]="rbxassetid://9043887091",["Lo-fi Ambient"]="rbxassetid://129775776987523",["Tears in the Rain"]="rbxassetid://129710845038263"}
    local musNames = {}
    for k in pairs(musLib) do table.insert(musNames, k) end
    table.sort(musNames)
    local musObj = Instance.new("Sound")
    musObj.Volume = 3
    musObj.Looped = false
    musObj.Parent = game:GetService("SoundService")
    local musCurrent = "Eeyuh"
    local musEnabled = false
    local function musPlay(id) musObj:Stop(); musObj.SoundId = id; musObj:Play() end
    local s = sAudio
    s:AddToggle("MusicToggle", {Title="Background Music",Default=false,
        Callback=function(v) musEnabled = v; if v then musPlay(musLib[musCurrent]) else musObj:Stop() end end})
    s:AddDropdown("MusicPick", {Title="Track",Values=musNames,Default="Eeyuh",Multi=false,
        Callback=function(v) if musLib[v] then musCurrent = v; if musEnabled then musPlay(musLib[v]) end end end})
    s:AddSlider("MusicVolume", {Title="Volume",Default=3,Min=0,Max=10,Rounding=1,
        Callback=function(v) musObj.Volume = v end})
    s:AddToggle("MusicLoop", {Title="Loop",Default=false,
        Callback=function(v) musObj.Looped = v end})
end

-- ========================================
-- ATMOSPHERE
-- ========================================
do
    local atmEnabled = false
    local s = sAudio
    s:AddToggle("FilterAtmToggle", {Title="Atmosphere",Description="Custom atmosphere effect",Default=true,
        Callback=function(v)
            atmEnabled = v
            local l = game:GetService("Lighting")
            if v then
                if not l:FindFirstChild("CustomAtmosphere") then
                    local atm = Instance.new("Atmosphere")
                    atm.Name = "CustomAtmosphere"
                    atm.Parent = l
                end
            else
                local a = l:FindFirstChild("CustomAtmosphere")
                if a then a:Destroy() end
            end
        end})
    s:AddSlider("FilterAtmDensity", {Title="Atmosphere Density",Default=0.3,Min=0,Max=1,Rounding=2,
        Callback=function(v)
            if atmEnabled then
                local a = game:GetService("Lighting"):FindFirstChild("CustomAtmosphere")
                if a then a.Density = v end
            end
        end})
end

-- ========================================
-- HIDE FEATURES
-- ========================================
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
                for _, t in ipairs(a:GetPlayingAnimationTracks()) do
                    pcall(function() t:Stop(0) end)
                end
                if not animConns[c] then
                    animConns[c] = a.AnimationPlayed:Connect(function(t)
                        pcall(function() t:Stop(0) end)
                    end)
                end
            end
        end
    end

    local function restoreChar(c)
        if not c then return end
        for _, o in ipairs(c:GetChildren()) do
            if o:IsA("Accessory") or o:IsA("Hat") then
                for _, d in ipairs(o:GetDescendants()) do
                    if d:IsA("BasePart") and bkAcc[d] then
                        d.Transparency = bkAcc[d]; bkAcc[d] = nil
                    end
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
        if h and bkNm[h] then
            h.DisplayDistanceType = bkNm[h]; bkNm[h] = nil
        end
        if animConns[c] then animConns[c]:Disconnect(); animConns[c] = nil end
    end

    local function hideObj(o)
        if o:IsA("BillboardGui") and state.hideBill then
            if bkBill[o] == nil then bkBill[o] = o.Enabled end
            o.Enabled = false
        elseif o:IsA("SurfaceGui") and state.hideSurf then
            if bkSurf[o] == nil then bkSurf[o] = o.Enabled end
            o.Enabled = false
        elseif (o:IsA("Decal") or o:IsA("Texture")) and state.hideDec then
            if bkDec[o] == nil then bkDec[o] = o.Transparency end
            o.Transparency = 1
        elseif o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")
            or o:IsA("Trail") or o:IsA("Beam") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
            local shouldHide =
                ((o:IsA("Trail") or o:IsA("Beam")) and state.hideBeams)
                or ((o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles")) and state.hideParticles)
                or ((o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight")) and state.hideLights)
            if shouldHide then
                if bkEff[o] == nil then bkEff[o] = o.Enabled end
                o.Enabled = false
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
                hideObj(o)
                n = n + 1
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
        task.defer(function()
            if not o.Parent then return end
            hideObj(o)
        end)
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
    local hideAllEffectsConn_ref = nil
    local function hideAll(on)
        for _, k in ipairs(hideAllKeys) do state[k] = on end
        scanAll()
        if not on then restoreAll() end
    end

    local s = UtilTab:AddSection("hide & effects", "eye-off")
    s:AddToggle("HideAllToggle", {Title="Hide All",Description="Toggle every hide feature at once",Default=false,
        Callback=function(v) hideAll(v) end})
    s:AddToggle("HideAccessories", {Title="Hide Accessories",Default=false,
        Callback=function(v) setState("hideAcc", v) end})
    s:AddToggle("HideClothes", {Title="Hide Clothes",Default=true,
        Callback=function(v) setState("hideClo", v) end})
    s:AddToggle("HideNametag", {Title="Hide Nametag",Default=true,
        Callback=function(v) setState("hideName", v) end})
    s:AddToggle("FreezeAnim", {Title="Freeze Animations",Default=true,
        Callback=function(v) setState("hideAnim", v) end})
    s:AddToggle("HideBillboards", {Title="Hide BillboardGui",Description="Hide 3D-overlay UI",Default=false,
        Callback=function(v) setState("hideBill", v) end})
    s:AddToggle("HideSurfaces", {Title="Hide SurfaceGui",Description="Hide surface UI",Default=true,
        Callback=function(v) setState("hideSurf", v) end})
    s:AddToggle("HideDecals", {Title="Hide Decals",Default=true,
        Callback=function(v) setState("hideDec", v) end})
    s:AddToggle("HideParticles", {Title="Hide Particles",Default=true,
        Callback=function(v) setState("hideParticles", v) end})
    s:AddToggle("HideBeams", {Title="Hide Beams & Trails",Default=true,
        Callback=function(v) setState("hideBeams", v) end})
    s:AddToggle("HideLights", {Title="Hide Lights",Default=true,
        Callback=function(v) setState("hideLights", v) end})

    local hideAllEffectsConn
    s:AddToggle("HideAllEffects", {Title="Hide All Effects (FX)",Description="Kill particles, beams, lights, sounds, explosions",Default=false,
        Callback=function(v)
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
        end})
end

-- ========================================
-- AVATAR CHANGER + HEADLESS + KORBLOX HELPERS
-- ========================================
do
    local _avGetUserId = function(nameOrId)
        local n = tonumber(nameOrId)
        if n then return n end
        local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(tostring(nameOrId)) end)
        return ok and id or nil
    end
    local state = { enabled=false, target="", originalDesc=nil, appliedId=nil, applying=false, cache={}, attemptId=0 }
    local _avSaveOriginal = function()
        if state.originalDesc then return end
        task.spawn(function()
            for i = 1, 5 do
                local ok, desc = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserIdAsync(LocalPlayer.UserId)
                end)
                if ok and desc then state.originalDesc = desc; break end
                task.wait(0.3 * i)
            end
        end)
    end
    local _avGetDescription = function(userId)
        if state.cache[userId] then return state.cache[userId] end
        for i = 1, 5 do
            local ok, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
            end)
            if ok and desc then
                state.cache[userId] = desc
                return desc
            end
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
                if hum.ApplyDescriptionClientServer then
                    hum:ApplyDescriptionClientServer(desc)
                else
                    hum:ApplyDescription(desc)
                end
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
            local id = _avGetUserId(nameOrId)
            if not id then return end
            if state.appliedId == id then return end
            local desc = _avGetDescription(id)
            if not desc then return end
            if not state.enabled or state.target ~= nameOrId or state.attemptId ~= token then return end
            state.appliedId = id
            _avApplyDescription(desc)
        end)
    end
    local function restore()
        if not state.originalDesc then return end
        state.appliedId = nil
        state.applying = false
        _avApplyDescription(state.originalDesc)
    end
    local function set(enabled, target)
        state.enabled = enabled
        if target then state.target = target end
        if enabled then
            _avSaveOriginal()
            if state.target ~= "" then apply(state.target) end
        elseif state.appliedId then
            restore()
        end
    end
    getgenv()._daemonAvatarChanger = { set = set, apply = apply, restore = restore }

    _G._daemonHeadless = function(char)
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        head.Transparency = 1
        for _, child in head:GetChildren() do
            if child:IsA("Decal") or child.Name == "face" then
                child.Transparency = 1
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
        local head = char:FindFirstChild("Head")
        if not head then return end
        head.Transparency = 0
        for _, child in head:GetChildren() do
            if child:IsA("Decal") or child.Name == "face" then
                child.Transparency = 0
            elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
                local orig = child:GetAttribute("OriginalScale")
                if orig then
                    child.Scale = orig
                    child:SetAttribute("OriginalScale", nil)
                end
            end
        end
    end
    _G._daemonKorblox = function(char)
        if not char then return end
        local leg = char:FindFirstChild("Right Leg")
        if not leg then return end
        if not leg:FindFirstChild("KorbloxMesh") then
            for _, v in leg:GetChildren() do
                if v:IsA("SpecialMesh") then v:Destroy() end
            end
            local m = Instance.new("SpecialMesh")
            m.Name = "KorbloxMesh"
            m.MeshId = "rbxassetid://902942096"
            m.TextureId = "rbxassetid://902843398"
            m.Offset = Vector3.new(0, 0.7, 0)
            m.Parent = leg
        end
    end
    _G._daemonRestoreLeg = function(char)
        if not char then return end
        local leg = char:FindFirstChild("Right Leg")
        if not leg then return end
        for _, v in leg:GetChildren() do
            if v:IsA("SpecialMesh") then v:Destroy() end
        end
    end
    local function applyHeadlessKorblox()
        local char = LocalPlayer.Character
        if not char then return end
        if _G.config.headless_enabled and _G._daemonHeadless then pcall(_G._daemonHeadless, char) end
        if _G.config.korblox_enabled and _G._daemonKorblox then pcall(_G._daemonKorblox, char) end
    end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyHeadlessKorblox()
    end)
end

-- ========================================
-- NO RENDER
-- ========================================
do
    local s = UtilTab:AddSection("utility", "settings")
    _G._frxUtilSection = s
    local noRenderConn
    do
        local es = LocalPlayer.PlayerScripts:FindFirstChild("EffectScripts")
        if es then
            local cfx = es:FindFirstChild("ClientFX")
            if cfx then cfx.Disabled = true end
        end
    end
    s:AddToggle("NoRender", {Title="No Render",Description="Kill Runtime spawns",Default=true,
        Callback=function(state)
            local es = LocalPlayer.PlayerScripts:FindFirstChild("EffectScripts")
            if es then
                local cfx = es:FindFirstChild("ClientFX")
                if cfx then cfx.Disabled = state end
            end
            if noRenderConn then noRenderConn:Disconnect(); noRenderConn = nil end
            if state then
                local rt = workspace:FindFirstChild("Runtime")
                if rt then
                    noRenderConn = rt.ChildAdded:Connect(function(v) Debris:AddItem(v, 0) end)
                end
            end
        end})
end

-- ========================================
-- FOV CHANGER
-- ========================================
do
    local fovConn, fovOrig
    local function applyFOV(v)
        local cam = workspace.CurrentCamera
        if not cam then return end
        if fovOrig == nil then fovOrig = cam.FieldOfView end
        cam.FieldOfView = v
    end
    local s = _G._frxUtilSection or UtilTab:AddSection("utility", "settings")
    s:AddToggle("FOVChangerToggle", {Title="Enable FOV Changer",Default=false,
        Callback=function(state)
            if fovConn then fovConn:Disconnect(); fovConn = nil end
            if state then
                applyFOV(tonumber(getgenv().FOVValue) or 120)
                fovConn = RunService.RenderStepped:Connect(function()
                    applyFOV(tonumber(getgenv().FOVValue) or 120)
                end)
            else
                if fovOrig then
                    local cam = workspace.CurrentCamera
                    if cam then cam.FieldOfView = fovOrig end
                end
            end
        end})
    s:AddSlider("FOVValueSlider", {Title="FOV",Default=120,Min=40,Max=120,Rounding=0,
        Callback=function(v)
            getgenv().FOVValue = v
            if fovConn then applyFOV(v) end
        end})
    getgenv().FOVValue = 120
end

-- ========================================
-- SPEED & JUMP
-- ========================================
do
    local sjConn
    local s = _G._frxUtilSection or UtilTab:AddSection("utility", "settings")
    s:AddToggle("SpeedJumpToggle", {Title="Speed & Jump",Description="WalkSpeed + JumpPower",Default=true,
        Callback=function(state)
            if sjConn then sjConn:Disconnect(); sjConn = nil end
            if state then
                sjConn = RunService.Heartbeat:Connect(function()
                    local c = LocalPlayer.Character
                    if not c then return end
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if not h then return end
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
        end})
    s:AddSlider("WalkSpeedSlider", {Title="WalkSpeed",Default=44,Min=16,Max=400,Rounding=0,
        Callback=function(v) getgenv().WalkSpeed = v end})
    s:AddSlider("JumpPowerSlider", {Title="JumpPower",Default=50,Min=50,Max=450,Rounding=0,
        Callback=function(v) getgenv().JumpPower = v end})
    getgenv().WalkSpeed = getgenv().WalkSpeed or 44
    getgenv().JumpPower = getgenv().JumpPower or 50
end

-- ========================================
-- GRAVITY CHANGER
-- ========================================
do
    local gravConn
    local gravOrig = workspace.Gravity
    local function setGrav(on, val)
        if gravConn then gravConn:Disconnect(); gravConn = nil end
        if on then
            local t = tonumber(val) or 100
            gravConn = RunService.Heartbeat:Connect(function() workspace.Gravity = t end)
        else
            workspace.Gravity = gravOrig
        end
    end
    local s = _G._frxUtilSection or UtilTab:AddSection("utility", "settings")
    s:AddToggle("GravityToggle", {Title="Gravity Changer",Default=false,
        Callback=function(v)
            getgenv().GravityEnabled = v
            setGrav(v, getgenv().GravityValue or 100)
        end})
    s:AddSlider("GravitySlider", {Title="Gravity",Default=100,Min=0,Max=500,Rounding=0,
        Callback=function(v)
            getgenv().GravityValue = v
            if getgenv().GravityEnabled then setGrav(true, v) end
        end})
end

-- ========================================
-- FORCE MATERIAL
-- ========================================
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
                applyMat(o)
                n = n + 1
                if n % 300 == 0 then task.wait() end
            end
        end)
    end
    local function restoreMat()
        for o, m in pairs(matBackup) do
            if o.Parent then pcall(function() o.Material = m end) end
        end
        table.clear(matBackup)
    end
    local s = _G._frxUtilSection or UtilTab:AddSection("utility", "settings")
    s:AddToggle("MatForceToggle", {Title="Force Material",Description="Override world parts material",Default=true,
        Callback=function(v)
            matEnabled = v
            if v then
                scanMat()
                if not matConn then
                    matConn = workspace.DescendantAdded:Connect(function(o)
                        task.defer(function()
                            if matEnabled then applyMat(o) end
                        end)
                    end)
                end
            else
                if matConn then matConn:Disconnect(); matConn = nil end
                restoreMat()
            end
        end})
    s:AddDropdown("MatType", {Title="Type",Values={"SmoothPlastic","Plastic"},Default="SmoothPlastic",Multi=false,
        Callback=function(v)
            matType = v
            if matEnabled then scanMat() end
        end})
end


-- ========== MOBILE UI TOGGLE (only shows on mobile devices) ==========
do
    local _isMobileDevice = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
                       or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
    if _isMobileDevice then
        local sMobile = UtilTab:AddSection("mobile", "smartphone")

        local function _spawnUIButton()
            task.spawn(function()
                task.wait(1.5)
                local mk = getgenv().create_floating_button
                if not mk then return end
                if getgenv()._mobileWindowToggleButton and getgenv()._mobileWindowToggleButton.gui then
                    pcall(function() getgenv()._mobileWindowToggleButton.gui:Destroy() end)
                end
                local fb = mk(
                    "MobileUI",
                    "UI",
                    UDim2.new(0, 20, 0, 60),
                    Color3.fromRGB(180, 140, 255),
                    function()
                        pcall(function()
                            if Window and Window.Minimize then
                                Window:Minimize(not Window.Minimized)
                            end
                        end)
                    end
                )
                getgenv()._mobileWindowToggleButton = fb
            end)
        end

        sMobile:AddToggle("MobileUIToggle", {
            Title = "show ui toggle button",
            Description = "Floating UI button to open/close the menu",
            Default = true,
            Callback = function(v)
                getgenv()._mobileUIToggleState = v
                if v then
                    _spawnUIButton()
                else
                    local dk = getgenv().destroy_floating_button
                    if dk then pcall(function() dk("MobileUI") end) end
                    getgenv()._mobileWindowToggleButton = nil
                end
            end
        })

        getgenv()._mobileUIToggleState = true
        _spawnUIButton()

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(2)
            if getgenv()._mobileUIToggleState then _spawnUIButton() end
        end)
    end
end

-- ========== HIT SOUND AUDIO + MUSIC (visual section continues)


-- ========================================
-- AVATAR CHANGER + HEADLESS + KORBLOX UI
-- ========================================
do
    local s = _G._frxUtilSection or UtilTab:AddSection("utility", "settings")

    s:AddToggle("AvatarChangerToggle", {
        Title = "avatar changer",
        Description = "Copy another player's avatar",
        Default = _G.config.avatar_changer or false,
        Callback = function(v)
            _G.config.avatar_changer = v
            if getgenv()._daemonAvatarChanger then
                pcall(function()
                    getgenv()._daemonAvatarChanger.set(v, getgenv()._daemonAvatarTarget or _G.config.avatar_name or "")
                end)
            end
        end
    })

    s:AddInput("AvatarTargetInput", {
        Title = "avatar target",
        Placeholder = "Username or UserId...",
        Default = _G.config.avatar_name or "",
        Callback = function(text)
            getgenv()._daemonAvatarTarget = text
            _G.config.avatar_name = text
            if getgenv()._daemonAvatarChanger and _G.config.avatar_changer then
                pcall(function()
                    getgenv()._daemonAvatarChanger.apply(text)
                end)
            end
        end
    })

    s:AddToggle("HeadlessToggle", {
        Title = "headless",
        Description = "Make your character headless",
        Default = _G.config.headless_enabled or false,
        Callback = function(v)
            _G.config.headless_enabled = v
            local char = LocalPlayer.Character
            if char then
                if v and _G._daemonHeadless then
                    pcall(_G._daemonHeadless, char)
                elseif not v and _G._daemonRestoreHead then
                    pcall(_G._daemonRestoreHead, char)
                end
            end
        end
    })

    s:AddToggle("KorbloxToggle", {
        Title = "korblox",
        Description = "Give your character a Korblox leg",
        Default = _G.config.korblox_enabled or false,
        Callback = function(v)
            _G.config.korblox_enabled = v
            local char = LocalPlayer.Character
            if char then
                if v and _G._daemonKorblox then
                    pcall(_G._daemonKorblox, char)
                elseif not v and _G._daemonRestoreLeg then
                    pcall(_G._daemonRestoreLeg, char)
                end
            end
        end
    })

    task.spawn(function()
        task.wait(2)
        local char = LocalPlayer.Character
        if not char then return end
        if _G.config.headless_enabled and _G._daemonHeadless then pcall(_G._daemonHeadless, char) end
        if _G.config.korblox_enabled and _G._daemonKorblox then pcall(_G._daemonKorblox, char) end
        if _G.config.avatar_changer and _G.config.avatar_name and _G.config.avatar_name ~= "" then
            pcall(function()
                if getgenv()._daemonAvatarChanger then
                    getgenv()._daemonAvatarChanger.set(true, _G.config.avatar_name)
                end
            end)
        end
    end)
end

-- ========================================
-- AUTO PLAY (human-like movement)
-- ========================================
local AP_State = {
    enabled = false,
    step_conn = nil,
    char_conn = nil,
    next_decision_at = 0,
    next_jump_at = 0,
    side_switch_at = 0,
    hesitation_until = 0,
    double_jumped = false,
    was_air = false,
    last_any_jump = 0,
    ball = nil,
    floor = nil,
    phase_seed = math.random() * 1000,
    side = (math.random() < 0.5) and -1 or 1,
}

local function _ap_rand(a, b) return a + math.random() * (b - a) end
local function _ap_chance(pct) return math.random() * 100 <= pct end

local function _ap_get_floor()
    local f = Workspace:FindFirstChild("FLOOR")
    if f and f:IsA("BasePart") then return f end
    if AP_State.floor and AP_State.floor.Parent then return AP_State.floor end
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and p.Size.X > 50 and p.Size.Z > 50 and p.Position.Y < 5 then
            AP_State.floor = p
            return p
        end
    end
    return nil
end

local function _ap_get_real_ball()
    local balls = Workspace:FindFirstChild("Balls")
    if not balls then return nil end
    for _, b in ipairs(balls:GetChildren()) do
        if b:GetAttribute("realBall") then return b end
    end
    return nil
end

local function _ap_compute_target(ball, floor, hrp)
    if not ball or not floor or not hrp then return nil end
    local ball_pos = ball.Position
    local my_pos = hrp.Position
    local to_me = Vector3.new(my_pos.X - ball_pos.X, 0, my_pos.Z - ball_pos.Z)
    local dist = to_me.Magnitude
    local dir = (dist > 0.01) and to_me.Unit or Vector3.new(0, 0, 1)
    local perp = Vector3.new(-dir.Z, 0, dir.X) * AP_State.side
    local speed = 0
    local zoomies = ball:FindFirstChild("zoomies")
    if zoomies and zoomies.VectorVelocity then
        speed = zoomies.VectorVelocity.Magnitude
    end
    local smooth_t = tick() * 1.25 + AP_State.phase_seed
    local variation = math.sin(smooth_t) * 2.5
    local speed_adj = math.min(speed / 10, getgenv().AutoPlayMultiplierThreshold or 45)
    local base_dist = (getgenv().AutoPlayDistance or 18) + speed_adj + variation
    local jx = (math.random() - 0.5) * 1.5
    local jz = (math.random() - 0.5) * 1.5
    local offset = dir * base_dist * (getgenv().AutoPlayDirection or 1)
    local strafe = perp * math.sin(smooth_t * 0.7) * (getgenv().AutoPlayTransversing or 6)
    return Vector3.new(
        ball_pos.X + offset.X + strafe.X + jx,
        floor.Position.Y,
        ball_pos.Z + offset.Z + strafe.Z + jz
    )
end

local function _ap_step()
    if not AP_State.enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    
    local blocked = _G.singularity_active or (getgenv()._advParryBlocked and getgenv()._advParryBlocked())
    if blocked then
        if hum.MoveDirection.Magnitude > 0 then hum:MoveTo(hrp.Position) end
        return
    end
    
    if hum.FloorMaterial ~= Enum.Material.Air then
        AP_State.double_jumped = false
        AP_State.was_air = false
    else
        AP_State.was_air = true
    end
    
    local ball = _ap_get_real_ball() or AP_State.ball
    if ball and (not ball.Parent or not ball:GetAttribute("realBall")) then ball = nil end
    if ball then AP_State.ball = ball end
    if not ball then return end
    local floor = _ap_get_floor()
    if not floor then return end
    
    local now = tick()
    
    if now > AP_State.side_switch_at then
        AP_State.side = (math.random() < 0.5) and -1 or 1
        AP_State.side_switch_at = now + _ap_rand(4, 9)
    end
    
    if now < AP_State.next_decision_at then return end
    AP_State.next_decision_at = now + _ap_rand(0.15, 0.35)
    
    if AP_State.hesitation_until > now then return end
    if _ap_chance(6) then
        AP_State.hesitation_until = now + _ap_rand(0.15, 0.45)
        return
    end
    
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
        if btarget == LocalPlayer.Name and hdist < 35 then
            should = _ap_chance(getgenv().AutoPlayJumpPercentage or 25)
        elseif hdist < 20 then
            should = _ap_chance((getgenv().AutoPlayJumpPercentage or 25) * 0.5)
        end
        local _secSinceJump = now - (AP_State.last_any_jump or 0)
        if not should and _secSinceJump > 4 and _ap_chance(35) then
            should = true
        end
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
        AP_State.next_decision_at = 0
        AP_State.next_jump_at = 0
        AP_State.side_switch_at = 0
        AP_State.hesitation_until = 0
        AP_State.phase_seed = math.random() * 1000
        AP_State.side = (math.random() < 0.5) and -1 or 1
        AP_State.step_conn = RunService.Heartbeat:Connect(_ap_step)
        AP_State.char_conn = LocalPlayer.CharacterAdded:Connect(function()
            AP_State.double_jumped = false
            AP_State.was_air = false
            AP_State.ball = nil
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
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
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
    Enable = _ap_set_enabled,
    Disable = function() _ap_set_enabled(false) end,
    Toggle = function() _ap_set_enabled(not AP_State.enabled) end,
    IsEnabled = function() return AP_State.enabled end,
    SetAntiAFK = _ap_set_anti_afk,
    GetState = function() return AP_State end,
}

local apMove = AutoPlayTab:AddSection("movement", "move")
local apJump = AutoPlayTab:AddSection("jumping", "arrow-up")
local apUtil = AutoPlayTab:AddSection("utility", "settings")

apMove:AddToggle("AutoPlayEnabled", {
    Title = "auto play",
    Description = "human-like movement around the ball",
    Default = false,
    Callback = function(v) _ap_set_enabled(v) end,
})

apMove:AddSlider("AutoPlayDistance", {
    Title = "distance",
    Description = "studs to stay behind the ball",
    Default = 18, Min = 5, Max = 60, Rounding = 0,
    Callback = function(v) getgenv().AutoPlayDistance = v end,
})

apMove:AddSlider("AutoPlaySpeedMult", {
    Title = "speed scale",
    Description = "add distance when ball is fast",
    Default = 45, Min = 10, Max = 200, Rounding = 0,
    Callback = function(v) getgenv().AutoPlayMultiplierThreshold = v end,
})

apMove:AddSlider("AutoPlayTransverse", {
    Title = "transversing",
    Description = "side-to-side sway amount",
    Default = 6, Min = 0, Max = 30, Rounding = 1,
    Callback = function(v) getgenv().AutoPlayTransversing = v end,
})

apMove:AddDropdown("AutoPlayDirection", {
    Title = "direction",
    Values = { "behind ball", "in front of ball" },
    Default = "behind ball",
    Multi = false,
    Callback = function(v) getgenv().AutoPlayDirection = (v == "in front of ball") and -1 or 1 end,
})

apJump:AddToggle("AutoPlayJumping", {
    Title = "jumping",
    Description = "occasionally jump when ball is close",
    Default = true,
    Callback = function(v) getgenv().AutoPlayJumpingEnabled = v end,
})

apJump:AddSlider("AutoPlayJumpChance", {
    Title = "jump chance %",
    Default = 15, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) getgenv().AutoPlayJumpPercentage = v end,
})

apJump:AddSlider("AutoPlayDoubleJumpChance", {
    Title = "double jump chance %",
    Default = 8, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) getgenv().AutoPlayDoubleJumpPercentage = v end,
})

apJump:AddSlider("AutoPlayJumpCooldown", {
    Title = "jump cooldown",
    Description = "min seconds between jumps",
    Default = 1.0, Min = 0.3, Max = 5, Rounding = 1,
    Callback = function(v) getgenv().AutoPlayJumpCooldown = v end,
})

apUtil:AddToggle("AutoPlayAntiAFK", {
    Title = "anti afk",
    Description = "prevent idle kick",
    Default = false,
    Callback = function(v) _ap_set_anti_afk(v) end,
})

local apStatus = nil
pcall(function()
    apStatus = apUtil:AddParagraph({ Title = "status", Content = "off" })
end)
task.spawn(function()
    while task.wait(1) do
        if apStatus then
            pcall(function()
                apStatus:SetTitle(AP_State.enabled and "auto play: on" or "auto play: off")
                if AP_State.enabled then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local ball = _ap_get_real_ball()
                    local d = "?"
                    if hrp and ball then
                        d = string.format("%.0f", (hrp.Position - ball.Position).Magnitude)
                    end
                    apStatus:SetDesc(string.format("side: %s | dist: %s", AP_State.side > 0 and "R" or "L", d))
                else
                    apStatus:SetDesc("standby")
                end
            end)
        end
    end
end)

-- ========================================
-- FFLAGS TAB SYSTEM
-- ========================================
do
    local config = _G.config
    local FFlag = { folder = "daemon/fflags" }

    local function _ffTrim(s)
        return tostring(s or ""):match("^%s*(.-)%s*$")
    end

    local function _ffEnsureFolder()
        if type(makefolder) ~= "function" then return end
        if type(isfolder) == "function" and not isfolder("daemon") then pcall(makefolder, "daemon") end
        if type(isfolder) == "function" and not isfolder(FFlag.folder) then pcall(makefolder, FFlag.folder) end
    end

    local function _ffPath(name)
        local n = _ffTrim(name)
        if n == "" then return nil, "profile name is empty" end
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
            if type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then
                return nil, "fflag values must be strings, numbers, or booleans"
            end
            clean[k] = tostring(v)
            count = count + 1
        end
        if count == 0 then return nil, "fflags json has no flags" end
        return clean, nil, count
    end

    local function _ffApply(json)
        if type(setfflag) ~= "function" then return false, "setfflag is unavailable in this executor" end
        local data, err, count = _ffDecode(json)
        if not data then return false, err end
        local failed = {}
        for k, v in pairs(data) do
            if not pcall(setfflag, k, v) then table.insert(failed, k) end
        end
        if #failed > 0 then
            table.sort(failed)
            return false, string.format("failed to apply %d/%d fflags: %s", #failed, count, table.concat(failed, ", "))
        end
        return true, string.format("applied %d fflags", count)
    end

    local function _ffSave(name, json)
        if type(writefile) ~= "function" then return false, "file storage is unavailable" end
        local data, err = _ffDecode(json)
        if not data then return false, err end
        local path, perr, safe = _ffPath(name)
        if not path then return false, perr end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok then return false, "could not encode the fflags profile" end
        _ffEnsureFolder()
        if not pcall(writefile, path, encoded) then return false, "could not save the fflags profile" end
        return true, encoded, safe
    end

    local function _ffLoad(name)
        if type(readfile) ~= "function" then return false, "file storage is unavailable" end
        local path, err = _ffPath(name)
        if not path then return false, err end
        local ok, content = pcall(readfile, path)
        if not ok or type(content) ~= "string" then return false, "fflags profile was not found" end
        local data, derr = _ffDecode(content)
        if not data then return false, derr end
        return true, content
    end

    local function _ffList()
        if type(listfiles) ~= "function" then return nil, "listfiles is unavailable in this executor" end
        _ffEnsureFolder()
        local ok, files = pcall(listfiles, FFlag.folder)
        if not ok or type(files) ~= "table" then return nil, "could not list the fflags profiles" end
        local names, seen = {}, {}
        for _, p in ipairs(files) do
            local m = tostring(p):gsub("\\", "/"):match("([^/]+)%.json$")
            if m and not seen[m] then seen[m] = true; table.insert(names, m) end
        end
        table.sort(names, function(a, b) return a:lower() < b:lower() end)
        return names
    end

    local function _ffDelete(name)
        if type(delfile) ~= "function" then return false, "delfile is unavailable in this executor" end
        local path, err = _ffPath(name)
        if not path then return false, err end
        if not pcall(delfile, path) then return false, "could not delete the fflags profile" end
        return true
    end

    local function _ffNotify(ok, msg)
        pcall(function()
            Fluent:Notify({
                Title = ok and "fflags" or "fflags error",
                Content = tostring(msg),
                Duration = ok and 4 or 6,
            })
        end)
    end

    local function _ffOptions()
        local names, err = _ffList()
        if not names then return { "(profile listing unavailable)" }, err end
        if #names == 0 then return { "(no saved profiles)" } end
        return names
    end

    local function _ffIsRealOption(s)
        return type(s) == "string" and s ~= "(no saved profiles)" and s ~= "(profile listing unavailable)"
    end

    local sProfile = FFlagsTab:AddSection("profile", "save")
    local sJson = FFlagsTab:AddSection("fflags json", "code")

    local nameInput, jsonInput, dropdown, autoLoadToggle

    local function _ffRefreshDropdown(select)
        local opts = _ffOptions()
        if dropdown then
            pcall(function() dropdown:Refresh(opts) end)
            local pick = select or config.fflag_profile
            local found = false
            for _, o in ipairs(opts) do
                if o == pick then
                    pcall(function() dropdown:SetValue(o) end)
                    found = true
                    break
                end
            end
            if not found and opts[1] then
                pcall(function() dropdown:SetValue(opts[1]) end)
            end
        end
    end

    local function _ffLoadIntoEditor(name)
        local ok, contentOrErr = _ffLoad(name)
        if not ok then return false, contentOrErr end
        config.fflag_profile = _ffTrim(name)
        config.fflag_json = contentOrErr
        if nameInput then pcall(function() nameInput:SetValue(config.fflag_profile) end) end
        if jsonInput then pcall(function() jsonInput:SetValue(config.fflag_json) end) end
        pcall(save_cfg)
        return true, config.fflag_profile
    end

    local opts0, optsErr = _ffOptions()
    local defPick = config.fflag_profile
    local valid = false
    for _, o in ipairs(opts0) do
        if o == defPick then valid = true; break end
    end
    if not valid then defPick = opts0[1] end

    nameInput = sProfile:AddInput("FFlagProfileName", {
        Title = "profile name",
        Default = config.fflag_profile or "default",
        Placeholder = "default",
        Numeric = false,
        Finished = true,
        Callback = function(v)
            config.fflag_profile = _ffTrim(v)
            pcall(save_cfg)
        end,
    })

    dropdown = sProfile:AddDropdown("FFLagProfilePick", {
        Title = "saved profiles",
        Values = opts0,
        Default = defPick,
        Multi = false,
        Callback = function(v)
            if not _ffIsRealOption(v) then return end
            local ok, err = _ffLoadIntoEditor(v)
            if not ok then _ffNotify(false, err) end
        end,
    })

    if optsErr then
        task.defer(function() _ffNotify(false, optsErr) end)
    end

    sProfile:AddButton({
        Title = "save profile",
        Description = "save current json as named profile",
        Callback = function()
            local name = nameInput and nameInput.Value or config.fflag_profile
            local json = jsonInput and jsonInput.Value or config.fflag_json
            local ok, res, safe = _ffSave(_ffTrim(name), json or "")
            if ok then
                config.fflag_profile = safe
                config.fflag_json = res
                pcall(save_cfg)
                _ffRefreshDropdown(safe)
                _ffNotify(true, string.format("saved profile '%s'", safe))
            else
                _ffNotify(false, res)
            end
        end,
    })

    sProfile:AddButton({
        Title = "load profile",
        Description = "load saved profile into editor",
        Callback = function()
            local name = nameInput and nameInput.Value or config.fflag_profile
            local ok, res = _ffLoadIntoEditor(_ffTrim(name))
            if ok then
                _ffRefreshDropdown(res)
                _ffNotify(true, string.format("loaded profile '%s'", res))
            else
                _ffNotify(false, res)
            end
        end,
    })

    sProfile:AddButton({
        Title = "delete selected profile",
        Description = "delete the selected saved profile",
        Callback = function()
            local sel = dropdown and dropdown.Value
            if not _ffIsRealOption(sel) then
                _ffNotify(false, "select a saved profile first")
                return
            end
            local ok, err = _ffDelete(sel)
            if not ok then
                _ffNotify(false, err)
                return
            end
            if config.fflag_profile == sel then
                config.fflag_profile = "default"
                config.fflag_json = ""
                if nameInput then pcall(function() nameInput:SetValue("default") end) end
                if jsonInput then pcall(function() jsonInput:SetValue("") end) end
            end
            pcall(save_cfg)
            _ffRefreshDropdown()
            _ffNotify(true, string.format("deleted profile '%s'", sel))
        end,
    })

    autoLoadToggle = sProfile:AddToggle("FFlagAutoLoad", {
        Title = "auto load",
        Description = "auto-load & apply selected profile on script start",
        Default = config.fflag_auto_load or false,
        Callback = function(v)
            config.fflag_auto_load = v
            pcall(save_cfg)
        end,
    })

    sProfile:AddButton({
        Title = "set selected as auto load",
        Description = "load selected profile & enable auto-load",
        Callback = function()
            local sel = dropdown and dropdown.Value
            if not _ffIsRealOption(sel) then
                _ffNotify(false, "select a saved profile first")
                return
            end
            local ok, err = _ffLoadIntoEditor(sel)
            if not ok then _ffNotify(false, err); return end
            config.fflag_auto_load = true
            pcall(save_cfg)
            pcall(function() autoLoadToggle:SetValue(true) end)
            _ffNotify(true, string.format("auto load set to '%s'", sel))
        end,
    })

    jsonInput = sJson:AddInput("FFlagsJson", {
        Title = "fflags json",
        Description = 'format: {"FFlagName":"value"}',
        Default = config.fflag_json or "",
        Placeholder = '{"DFIntTaskSchedulerTargetFps":"240"}',
        Numeric = false,
        Finished = true,
        Callback = function(v)
            config.fflag_json = v
            pcall(save_cfg)
        end,
    })

    sJson:AddButton({
        Title = "apply fflags",
        Description = "apply the json as fflags via setfflag",
        Callback = function()
            local json = jsonInput and jsonInput.Value or config.fflag_json
            config.fflag_json = json
            pcall(save_cfg)
            local ok, msg = _ffApply(json or "")
            _ffNotify(ok, msg)
        end,
    })

    if config.fflag_auto_load then
        task.defer(function()
            local name = config.fflag_profile
            if not name or name == "" then return end
            local ok, content = _ffLoad(name)
            if not ok then _ffNotify(false, content); return end
            local ok2, msg = _ffApply(content)
            _ffNotify(ok2, msg)
        end)
    end
end

-- ========================================
-- MOBILE FLOATING BUTTONS (draggable)
-- ========================================
if _daemonMobile then
    local mbGui = Instance.new("ScreenGui")
    mbGui.Name = "daemon_MobileButtons"
    mbGui.ResetOnSpawn = false
    mbGui.IgnoreGuiInset = true
    mbGui.DisplayOrder = 9996
    local mp = nil
    pcall(function() if gethui then mp = gethui() end end)
    if not mp then pcall(function() mp = game:GetService("CoreGui") end) end
    if not mp then mp = LocalPlayer:WaitForChild("PlayerGui") end
    mbGui.Parent = mp
    
    local _posX = tonumber(_G.config.m_MobileButtonsX) or -12
    local _posY = tonumber(_G.config.m_MobileButtonsY) or -72
    
    local cont = Instance.new("Frame")
    cont.Name = "Container"
    cont.AnchorPoint = Vector2.new(1, 1)
    cont.Position = UDim2.new(1, _posX, 1, _posY)
    cont.Size = UDim2.fromOffset(84, 132)
    cont.BackgroundTransparency = 1
    cont.Parent = mbGui
    
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = cont
    
    local _mdrag = { active = false, moved = false, btn = nil, start = nil, startCont = nil }
    
    local function _msave_pos()
        local p = cont.Position
        _G.config.m_MobileButtonsX = p.X.Offset
        _G.config.m_MobileButtonsY = p.Y.Offset
        pcall(save_cfg)
    end
    
    local function mkb(text, order, fn)
        local b = Instance.new("TextButton")
        b.LayoutOrder = order
        b.Size = UDim2.fromOffset(80, 36)
        b.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        b.BackgroundTransparency = 0.25
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(240, 240, 245)
        b.Text = text
        b.AutoButtonColor = false
        b.Parent = cont
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = b
        local st = Instance.new("UIStroke")
        st.Color = Color3.fromRGB(55, 55, 65)
        st.Thickness = 1
        st.Parent = b
        b.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                _mdrag.active = true
                _mdrag.moved = false
                _mdrag.btn = b
                _mdrag.start = inp.Position
                _mdrag.startCont = cont.Position
            end
        end)
        b.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                if _mdrag.btn == b then
                    if not _mdrag.moved then
                        pcall(fn)
                    else
                        _msave_pos()
                    end
                    _mdrag.active = false
                    _mdrag.btn = nil
                end
            end
        end)
        return b
    end
    
    UserInputService.InputChanged:Connect(function(inp)
        if not _mdrag.active then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch and inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = inp.Position - _mdrag.start
        if d.Magnitude > 6 then _mdrag.moved = true end
        if _mdrag.moved then
            cont.Position = UDim2.new(
                _mdrag.startCont.X.Scale,
                _mdrag.startCont.X.Offset + d.X,
                _mdrag.startCont.Y.Scale,
                _mdrag.startCont.Y.Offset + d.Y
            )
        end
    end)
    
    local _wmin = false
    mkb("menu", 1, function()
        _wmin = not _wmin
        pcall(function() Window:Minimize(_wmin) end)
    end)
    local _bt = mkb("trigger", 2, function()
        if getgenv()._triggerbotKeybind and getgenv()._triggerbotKeybind.SetValue then
            getgenv()._triggerbotKeybind:SetValue(not _G.triggerbot)
        end
    end)
    local _bs = mkb("spam", 3, function()
        if getgenv()._manualSpamKeybind and getgenv()._manualSpamKeybind.SetValue then
            getgenv()._manualSpamKeybind:SetValue(not _G.manual_spam)
        end
    end)
    
    task.spawn(function()
        while mbGui.Parent do
            local onB = Color3.fromRGB(60, 180, 90)
            local offB = Color3.fromRGB(28, 28, 36)
            _bt.BackgroundColor3 = _G.triggerbot and onB or offB
            _bs.BackgroundColor3 = _G.manual_spam and onB or offB
            task.wait(0.2)
        end
    end)
end

task.spawn(function()
    repeat task.wait(0.5) until game:IsLoaded()
    task.wait(2)
    if getgenv().UnlockAll then
        pcall(function() getgenv().UnlockAll:initialize() end)
        if _G.config.unlock_all then
            pcall(function() getgenv().UnlockAll:set_enabled(true) end)
        end
    end
end)

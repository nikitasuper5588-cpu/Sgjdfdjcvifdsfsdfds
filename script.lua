local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- State variables
local currentMode = 0
local connTP = nil
local connScan = nil
local connDodge = nil
local killedList = {}
local killedNum = 0
local totalKills = 0
local sessionKills = 0
local enemyCache = {}
local predictStrength = 0.5  -- prediction multiplier (0 = off, higher = more ahead)
local blasterCD = 0.3       -- Blaster-only cooldown (seconds)
local blasterLastFired = 0  -- last time Blaster was activated
local scanning = false
local showESP = false
local espObjects = {}
local lastScan = 0
local playerChars = {}
local tpRunning = false

-- Auto Dodge state
local autoDodge = false
local dodgeHPThreshold = 1000
local isDodging = false
local dodgeLockPos = nil       -- locked standing position
local dodgeHealing = false    -- currently doing quick heal trip
local dodgeConnLock = nil     -- position lock connection
local dodgeConnHeal = nil     -- heal check connection

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function buildPlayerBlacklist()
    playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            playerChars[p.Character] = true
        end
    end
end

buildPlayerBlacklist()
Players.PlayerAdded:Connect(function() buildPlayerBlacklist() end)
Players.PlayerRemoving:Connect(function() buildPlayerBlacklist() end)

local function isPlayerCharacter(obj)
    if playerChars[obj] then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and (obj == p.Character or obj:IsDescendantOf(p.Character)) then
            return true
        end
    end
    return false
end

local function isValidPosition(pos)
    if not pos then return false end
    local x, y, z = pos.X, pos.Y, pos.Z
    if x ~= x or y ~= y or z ~= z then return false end
    if math.abs(x) > 50000 or math.abs(y) > 50000 or math.abs(z) > 50000 then return false end
    if x == 0 and y == 0 and z == 0 then return false end
    return true
end

local function getChar()
    local c = player.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hrp and hum then return c end
    return nil
end

local function getHRP()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function getSpawnPosition()
    local spawns = Workspace:FindFirstChild("Spawns")
    if spawns then
        for _, s in ipairs(spawns:GetChildren()) do
            if s:IsA("BasePart") then
                return s.Position + Vector3.new(0, 5, 0)
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            return obj.Position + Vector3.new(0, 5, 0)
        end
    end
    if player.Team then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("SpawnLocation") and obj.TeamColor == player.TeamColor then
                return obj.Position + Vector3.new(0, 5, 0)
            end
        end
    end
    return Vector3.new(0, 50, 0)
end

-- === Find the raft/platform ("плот") in the map ===
-- Scans workspace for parts named "плот", "raft", "platform" etc.
local raftCache = nil
local raftCacheTime = 0

local function findRaft()
    -- Cache for 10 seconds
    if raftCache and raftCache.Parent and (tick() - raftCacheTime) < 10 then
        return raftCache
    end
    raftCache = nil
    pcall(function()
        local keywords = {"плот", "raft", "platform", "plat", "dock", "bridge", "floor", "island", "baseplate"}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if n:find(kw) then
                        raftCache = obj
                        raftCacheTime = tick()
                        return
                    end
                end
            end
        end
    end)
    return raftCache
end

local function getRaftPosition()
    local raft = findRaft()
    if raft and raft.Parent then
        return raft.Position + Vector3.new(0, 5, 0)
    end
    -- Fallback: use spawn position
    return getSpawnPosition()
end

-- ============================================================
-- ENEMY DETECTION
-- ============================================================

local function isSkibidiToilet(obj)
    if not obj or not obj:IsA("Model") then return false end
    if playerChars[obj] then return false end
    if obj == player.Character then return false end
    if player.Character and obj:IsDescendantOf(player.Character) then return false end
    if isPlayerCharacter(obj) then return false end

    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local hrp = obj:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not isValidPosition(hrp.Position) then return false end

    if killedList[obj] then return false end

    local n = obj.Name:lower()
    local isToilet = false

    if n:find("toilet") or n:find("skibidi") then
        isToilet = true
    end

    if not isToilet then
        for _, ch in ipairs(obj:GetChildren()) do
            if ch:IsA("BasePart") then
                local cn = ch.Name:lower()
                if cn:find("toilet") or cn:find("skibidi") then
                    isToilet = true
                    break
                end
            end
        end
    end

    if not isToilet then return false end

    if n:find("camera") or n:find("speak") or n:find("tvman")
        or n:find("player") or n:find("ally") or n:find("friend")
        or n:find("shop") or n:find("vendor")
    then
        return false
    end

    return true
end

local function isDead(hum)
    if not hum then return true end
    return hum.Health <= 0
end

-- ============================================================
-- WEAPONS
-- ============================================================

local function getAllWeapons()
    local weapons = {}
    local char = player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(weapons, item)
            end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(weapons, item)
            end
        end
    end
    return weapons
end

-- ============================================================
-- COOLDOWN BYPASS v5 — Smart bypass (no camera/TP break)
--
-- What was wrong in v4:
--   - hookfunction(tick) broke camera interpolation
--   - hookfunction(os.time/os.clock) broke network timing
--   - destroyAllCharScripts() destroyed camera/movement scripts
--   - wait() hook threshold 0.02 broke our own killaura timing
--
-- v5 approach:
--   1. Hook wait/task.wait → CD timers expire instantly
--   2. Use SAVED originals (origWait/origTaskWait) in our own code
--      so our killaura/dodge waits work normally
--   3. Hook task.delay → reduce ability CD delays
--   4. Destroy ONLY CD-keyword scripts (NOT all scripts)
--   5. Block __newindex for CD values (expanded keywords)
--   6. Reset Value objects + attributes every frame
--   7. VirtualInputManager keypress for abilities
--   8. NO tick/os.time/os.clock hooks
-- ============================================================

local cdHookActive = true

-- === Save originals BEFORE hooking — used in our own code ===
local origWait = wait
local origTaskWait = task.wait

-- === METHOD 1: Hook wait() and task.wait() ===
-- CD scripts use wait(cooldownTime) — we make them return instantly
-- BUT our own code uses origWait()/origTaskWait() so timing stays correct

local oldWait
local oldTaskWait

pcall(function()
    oldWait = hookfunction(wait, function(t, ...)
        if cdHookActive and t and t > 0.02 then
            return oldWait(0)  -- bypass all CDs
        end
        return oldWait(t, ...)
    end)
end)

pcall(function()
    oldTaskWait = hookfunction(task.wait, function(t, ...)
        if cdHookActive and t and t > 0.02 then
            return oldTaskWait(0)  -- bypass all CDs
        end
        return oldTaskWait(t, ...)
    end)
end)

-- === METHOD 1b: Hook task.delay() ===
local oldTaskDelay
pcall(function()
    oldTaskDelay = hookfunction(task.delay, function(t, callback, ...)
        if cdHookActive and t and t > 0.02 then
            return oldTaskDelay(0, callback, ...)
        end
        return oldTaskDelay(t, callback, ...)
    end)
end)

-- === METHOD 2: Destroy LocalScripts that manage cooldowns ===
-- ONLY destroy scripts with CD keywords — NOT all scripts (v4 broke this)
local CD_SCRIPT_KEYWORDS = {
    "cooldown", "debounce", "canattack", "attackcd",
    "isattacking", "abilitycd", "skillcd", "specialcd",
    "cancast", "canuse", "canswing", "abilitycooldown",
    "skillcooldown", "combocooldown", "m1cooldown",
}

local function destroyCDScripts()
    local char = player.Character
    if not char then return end

    -- Check if a script source contains CD keywords
    local function hasCDKeyword(src)
        local s = src:lower()
        for _, kw in ipairs(CD_SCRIPT_KEYWORDS) do
            if s:find(kw) then return true end
        end
        return false
    end

    -- Destroy CD scripts inside tools
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                    local src = ""
                    pcall(function() src = child.Source end)
                    if hasCDKeyword(src) then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
    end

    -- Destroy CD scripts directly on character (ability handlers)
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("LocalScript") then
            local src = ""
            pcall(function() src = child.Source end)
            if hasCDKeyword(src) then
                pcall(function() child:Destroy() end)
            end
        end
    end

    -- Also check Backpack tools
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                for _, child in ipairs(item:GetDescendants()) do
                    if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                        local src = ""
                        pcall(function() src = child.Source end)
                        if hasCDKeyword(src) then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end
    end

    -- Check PlayerScripts for ability handlers (but ONLY CD-related ones)
    local ps = player:FindFirstChild("PlayerScripts")
    if ps then
        for _, child in ipairs(ps:GetDescendants()) do
            if child:IsA("LocalScript") then
                local src = ""
                pcall(function() src = child.Source end)
                if hasCDKeyword(src) then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

-- Re-run on character spawn and tool equip
player.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            origWait(0.1)
            destroyCDScripts()
        end
    end)
    char.DescendantAdded:Connect(function(child)
        if child:IsA("LocalScript") then
            origWait(0.05)
            local src = ""
            pcall(function() src = child.Source end)
            local s = src:lower()
            for _, kw in ipairs(CD_SCRIPT_KEYWORDS) do
                if s:find(kw) then
                    pcall(function() child:Destroy() end)
                    break
                end
            end
        end
    end)
    origWait(0.5)
    destroyCDScripts()
end)

-- Also destroy on current character
spawn(function()
    origWait(1)
    destroyCDScripts()
end)

-- === METHOD 3: Hook __newindex to block cooldown value writes ===
local blockedNames = {
    "cooldown", "debounce", "oncooldown", "isoncooldown", "attacking",
    "isattacking", "attackcooldown", "canattack", "canswing",
    "canuse", "canactivate", "cancast", "isreloading",
    "abilitycooldown", "skillcooldown", "busy", "isbusy",
    "actionlock", "locked", "m1cooldown", "combocooldown",
    "abilitycd", "skillcd", "specialcd", "canspecial",
    "canability", "canskill", "onabilitycd", "onskillcd",
    "isability", "usingability", "abilityactive", "skillactive",
    "candash", "canleap", "dashcd", "leapcd",
    "ultcd", "canult", "ultimatecd", "canultimate",
    "eability", "rability", "qability", "fability",
    "eonicd", "ronicd", "qonicd", "fonicd",
}

local function isBlockedName(name)
    local n = name:lower()
    for _, kw in ipairs(blockedNames) do
        if n:find(kw) then return true end
    end
    return false
end

pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(t, k, v)
            if type(k) == "string" and isBlockedName(k) then
                if k:lower():find("can") then
                    if type(v) == "boolean" and v == true then
                        return oldNewIndex(t, k, v)
                    end
                    return
                else
                    if type(v) == "boolean" and v == false then
                        return oldNewIndex(t, k, v)
                    elseif type(v) == "number" and v == 0 then
                        return oldNewIndex(t, k, v)
                    end
                    return
                end
            end
            return oldNewIndex(t, k, v)
        end)
        setreadonly(mt, true)
    end
end)

-- === METHOD 4: Reset Value objects + attributes every frame ===
-- Scans character, humanoid, tools, AND player object
local function resetAllCDValues()
    local char = player.Character
    if not char then return end

    -- Reset on character descendants
    for _, child in ipairs(char:GetDescendants()) do
        if child:IsA("BoolValue") and isBlockedName(child.Name) then
            if child.Name:lower():find("can") then
                child.Value = true
            else
                child.Value = false
            end
        end
        if (child:IsA("NumberValue") or child:IsA("IntValue")) and isBlockedName(child.Name) then
            child.Value = 0
        end
    end

    -- Reset attributes on character, humanoid, and player
    pcall(function()
        local targets = {char, char:FindFirstChildOfClass("Humanoid"), player}
        for _, obj in ipairs(targets) do
            if obj then
                local ok, attrs = pcall(function() return obj:GetAttributes() end)
                if ok and attrs then
                    for attrName, attrVal in pairs(attrs) do
                        if isBlockedName(attrName) then
                            if type(attrVal) == "boolean" then
                                obj:SetAttribute(attrName, attrName:lower():find("can") and true or false)
                            elseif type(attrVal) == "number" then
                                obj:SetAttribute(attrName, 0)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Reset attributes on tools too
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            pcall(function()
                local ok, attrs = pcall(function() return item:GetAttributes() end)
                if ok and attrs then
                    for attrName, attrVal in pairs(attrs) do
                        if isBlockedName(attrName) then
                            if type(attrVal) == "boolean" then
                                item:SetAttribute(attrName, attrName:lower():find("can") and true or false)
                            elseif type(attrVal) == "number" then
                                item:SetAttribute(attrName, 0)
                            end
                        end
                    end
                end
            end)
        end
    end
end

local connBypassCD = RunService.Stepped:Connect(function()
    resetAllCDValues()
end)

-- === METHOD 5: VirtualInputManager — simulate ability key presses ===
-- This triggers the game's own input handling, so ability scripts process the key
-- even if their UI button shows on cooldown
local VIM = game:GetService("VirtualInputManager")

-- Flag to prevent VIM key presses from triggering our own input handlers
-- Use a counter instead of boolean to handle overlapping spawn threads
local vimPressCount = 0
local isVIMPressing = false

local function pressKey(keyCode)
    pcall(function()
        vimPressCount = vimPressCount + 1
        isVIMPressing = true
        VIM:SendKeyEvent(true, keyCode, false, game)
        origTaskWait(0.02)
        VIM:SendKeyEvent(false, keyCode, false, game)
        origTaskWait(0.01)
        vimPressCount = vimPressCount - 1
        if vimPressCount <= 0 then
            vimPressCount = 0
            isVIMPressing = false
        end
    end)
end

-- Ability keys for this game: E, R, Q, F, T
local abilityKeys = {
    Enum.KeyCode.R,
    Enum.KeyCode.Q,
    Enum.KeyCode.F,
    Enum.KeyCode.T,
    Enum.KeyCode.E,
}

-- === Ability keys only fire during killaura combat (inside activateWeapon) ===
-- No background spam — abilities fire faster ONLY when fighting enemies

-- === METHOD 6: Hook FireServer on ability remotes ===
-- When the game tries to fire an ability remote with cooldown args, strip them
local hookedRemotes = {}

local function hookAbilityRemotes()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, rem in ipairs(rs:GetDescendants()) do
            if rem:IsA("RemoteEvent") and not hookedRemotes[rem] then
                local n = rem.Name:lower()
                if n:find("ability") or n:find("skill") or n:find("special")
                    or n:find("cast") or n:find("titan") then
                    hookedRemotes[rem] = true
                    -- We don't hook the remote itself (could break args)
                    -- Instead we just track it for direct firing
                end
            end
        end
    end)
end

-- === Blocked ability names (cause lag / server issues) ===
local blockedAbilityNames = {
    "teleport", "shadow", "tp",
}

local function isBlockedAbility(name)
    local n = name:lower()
    for _, bw in ipairs(blockedAbilityNames) do
        if n:find(bw) then return true end
    end
    return false
end

-- === Destroy blocked abilities from player's inventory ===
-- Only destroys TOOLS named Teleport/Shadow — doesn't touch PlayerGui
-- or character internals that could break movement
local function destroyBlockedAbilities()
    pcall(function()
        -- Only remove tools named after blocked abilities from Backpack
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then
            for _, child in ipairs(bp:GetChildren()) do
                if child:IsA("Tool") and isBlockedAbility(child.Name) then
                    child:Destroy()
                end
            end
        end

        -- Remove from character too (equipped tools only)
        local char = player.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") and isBlockedAbility(child.Name) then
                    child:Destroy()
                end
            end
        end
    end)
end

-- Run cleanup loop every 3 seconds
spawn(function()
    while true do
        destroyBlockedAbilities()
        origWait(3)
    end
end)

-- === Cached ability remotes from ReplicatedStorage ===
-- Scan once, cache results, reuse — avoids heavy GetDescendants every frame
local cachedAbilityRemotes = nil
local cacheTime = 0

local function getAbilityRemotes()
    -- Refresh cache every 5 seconds
    if cachedAbilityRemotes and (tick() - cacheTime) < 5 then
        return cachedAbilityRemotes
    end
    cachedAbilityRemotes = {}
    cacheTime = tick()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, rem in ipairs(rs:GetDescendants()) do
            if rem:IsA("RemoteEvent") then
                local n = rem.Name:lower()
                -- Skip blocked abilities (Teleport, Shadow — cause lag)
                if isBlockedAbility(rem.Name) then continue end
                if n:find("attack") or n:find("hit") or n:find("damage")
                    or n:find("swing") or n:find("punch") or n:find("ability")
                    or n:find("cast") or n:find("use") or n:find("skill")
                    or n:find("special") or n:find("titan") or n:find("ult") then
                    table.insert(cachedAbilityRemotes, rem)
                end
            end
        end
    end)
    return cachedAbilityRemotes
end

-- === ANTI-LAG: Per-remote rate limiter ===
-- Each remote can only be fired once every 0.3s
-- This prevents server overload without changing ability cooldowns
local remoteLastFired = {}
local REMOTE_RATE_LIMIT = 0.3  -- seconds between fires for same remote

local function canFireRemote(remote)
    local id = tostring(remote)
    local now = tick()
    local last = remoteLastFired[id]
    if last and (now - last) < REMOTE_RATE_LIMIT then
        return false
    end
    remoteLastFired[id] = now
    return true
end

-- Clean up old entries every 10s to prevent memory leak
spawn(function()
    while true do
        origWait(10)
        local now = tick()
        local fresh = {}
        for id, t in pairs(remoteLastFired) do
            if (now - t) < 5 then fresh[id] = t end
        end
        remoteLastFired = fresh
    end
end)

-- === ANTI-LAG: VIM keypress rate limiter ===
local lastVIMPulse = 0
local VIM_RATE_LIMIT = 0.5  -- seconds between VIM ability keypresses

-- === Enhanced weapon activation (from working version) ===
-- Fires ALL remotes without rate limiting — that's how Blaster actually shoots
-- Blaster CD is handled at KillAura loop level, not here

local function activateWeapon(tool)
    if not tool then return end

    -- Standard activate
    pcall(function() tool:Activate() end)

    -- Fire ALL remotes inside the tool (direct, no rate limit, no block check)
    pcall(function()
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                if isBlockedAbility(child.Name) then continue end
                pcall(function() child:FireServer() end)
            elseif child:IsA("RemoteFunction") then
                if isBlockedAbility(child.Name) then continue end
                pcall(function() child:InvokeServer() end)
            elseif child:IsA("BindableEvent") then
                pcall(function() child:Fire() end)
            end
        end
    end)

    -- Fire common named remotes in tool (fast FindFirstChild)
    for _, name in ipairs({"AttackEvent", "RemoteEvent", "Swing", "Hit", "Fire", "Shoot",
        "Damage", "Strike", "Cast", "Ability", "Use", "Activate",
        "Punch", "Kick", "Slam", "Smash", "Bite", "Stomp",
        "Ability1", "Ability2", "Ability3", "Special", "Ultimate"}) do
        if not isBlockedAbility(name) then
            local rem = tool:FindFirstChild(name)
            if rem then
                if rem:IsA("RemoteEvent") then pcall(function() rem:FireServer() end) end
                if rem:IsA("RemoteFunction") then pcall(function() rem:InvokeServer() end) end
            end
        end
    end

    -- Fire CACHED ability remotes (no heavy scan every call)
    local remotes = getAbilityRemotes()
    for _, rem in ipairs(remotes) do
        if rem and rem.Parent then
            pcall(function() rem:FireServer() end)
        end
    end

    -- Press ability keys via VirtualInputManager (non-blocking, instant)
    pcall(function()
        vimPressCount = vimPressCount + 1
        isVIMPressing = true
        lastVIMTime = tick()  -- suppress E key toggle for 1s
        for _, key in ipairs(abilityKeys) do
            VIM:SendKeyEvent(true, key, false, game)
            VIM:SendKeyEvent(false, key, false, game)
        end
        vimPressCount = vimPressCount - 1
        if vimPressCount <= 0 then
            vimPressCount = 0
            isVIMPressing = false
        end
    end)
end

local function deactivateWeapon(tool)
    if not tool then return end
    pcall(function() tool:Deactivate() end)
end

-- ============================================================
-- SCANNING
-- ============================================================

local function cleanKilled()
    local fresh = {}
    local num = 0
    for obj, _ in pairs(killedList) do
        if obj and obj.Parent then
            fresh[obj] = true
            num = num + 1
        end
    end
    killedList = fresh
    killedNum = num
end

local function scanEnemies()
    if scanning then return end
    scanning = true
    local fresh = {}
    local ok, descs = pcall(function() return Workspace:GetDescendants() end)
    if ok then
        for _, obj in ipairs(descs) do
            if isSkibidiToilet(obj) then
                fresh[obj] = true
            end
        end
    end
    enemyCache = fresh
    scanning = false
end

-- ============================================================
-- ESP
-- ============================================================

local function clearESP()
    for obj, v in pairs(espObjects) do
        if v and v.Parent then pcall(function() v:Destroy() end) end
    end
    espObjects = {}
end

local function updateESP()
    clearESP()
    for obj, _ in pairs(enemyCache) do
        if obj and obj.Parent then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and not isDead(hum) then
                local ok, hl = pcall(function()
                    local h = Instance.new("Highlight")
                    h.Name = "STF_ESP"
                    h.FillColor = Color3.fromRGB(255, 30, 30)
                    h.FillTransparency = 0.75
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.OutlineTransparency = 0
                    h.Parent = obj
                    return h
                end)
                if ok then espObjects[obj] = hl end
            end
        end
    end
end

-- ============================================================
-- KILL AURA TP
-- TP to toilet, stay until dead, then TP to next
-- Uses origWait/origTaskWait so CD hook doesn't break timing
-- ============================================================

local function startKillAuraTP()
    if connTP then connTP:Disconnect() connTP = nil end
    connTP = RunService.Heartbeat:Connect(function()
        if tpRunning then return end
        tpRunning = true
        spawn(function()
            while tpRunning do
                local char = getChar()
                if not char then break end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local pHum = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not pHum then break end

                local weapons = getAllWeapons()
                if #weapons == 0 then
                    origWait(0.5)
                else
                    local target = nil
                    local targetDist = math.huge

                    for obj, _ in pairs(enemyCache) do
                        if obj and obj.Parent and not killedList[obj] then
                            local hum = obj:FindFirstChildOfClass("Humanoid")
                            if hum and not isDead(hum) then
                                local eHrp = obj:FindFirstChild("HumanoidRootPart")
                                if eHrp and isValidPosition(eHrp.Position) then
                                    local d = (eHrp.Position - hrp.Position).Magnitude
                                    if d < targetDist and d < 3000 then
                                        targetDist = d
                                        target = obj
                                    end
                                end
                            end
                        end
                    end

                    if target then
                        local eHrp = target:FindFirstChild("HumanoidRootPart")
                        if eHrp and isValidPosition(eHrp.Position) then
                            -- TP beside the toilet (with prediction)
                            local eVel = eHrp.Velocity
                            local predictedPos = eHrp.Position + eVel * predictStrength
                            pcall(function() hrp.CFrame = CFrame.new(predictedPos) * CFrame.new(0, 0, 3) end)
                            origWait(0.02)

                            -- Stay and hit until dead
                            while tpRunning do
                                local eHum = target:FindFirstChildOfClass("Humanoid")
                                if not eHum or isDead(eHum) then break end
                                if not target or not target.Parent then break end

                                -- Stay next to the toilet (with prediction)
                                local eHrp2 = target:FindFirstChild("HumanoidRootPart")
                                if eHrp2 and isValidPosition(eHrp2.Position) then
                                    local eVel2 = eHrp2.Velocity
                                    local predPos = eHrp2.Position + eVel2 * predictStrength
                                    pcall(function() hrp.CFrame = CFrame.new(predPos) * CFrame.new(0, 0, 3) end)
                                end

                                -- Attack with ALL weapons in one burst
                                local eHum2 = target:FindFirstChildOfClass("Humanoid")
                                if not eHum2 or isDead(eHum2) then break end

                                for _, weapon in ipairs(weapons) do
                                    if weapon and weapon.Parent then
                                        -- Equip weapon if not equipped
                                        if weapon.Parent ~= char then
                                            pcall(function() weapon.Parent = char end)
                                        end

                                        -- Blaster CD: skip activateWeapon if Blaster on cooldown
                                        local wName = weapon.Name:lower()
                                        if wName:find("blaster") then
                                            local now = tick()
                                            if (now - blasterLastFired) < blasterCD then
                                                -- Blaster on CD, skip this weapon this cycle
                                            else
                                                blasterLastFired = now
                                                activateWeapon(weapon)
                                            end
                                        else
                                            -- Non-Blaster weapons fire every cycle
                                            activateWeapon(weapon)
                                        end
                                    end
                                end

                                -- Deactivate all weapons at once
                                for _, weapon in ipairs(weapons) do
                                    if weapon and weapon.Parent then
                                        deactivateWeapon(weapon)
                                    end
                                end

                                local finalChk = target:FindFirstChildOfClass("Humanoid")
                                if finalChk and isDead(finalChk) then
                                    killedList[target] = true
                                    killedNum = killedNum + 1
                                    totalKills = totalKills + 1
                                    sessionKills = sessionKills + 1
                                    break
                                end

                                origWait(0.1)  -- attack cycle: ~0.1s between hits
                            end
                            -- After kill: loop continues to next target
                        end
                    else
                        origWait(0.3)
                    end

                    if killedNum > 100 then cleanKilled() end
                end
                origWait(0.05)
            end
            tpRunning = false
        end)
    end)
end

-- ============================================================
-- AUTO DODGE v3 — Simple & Working
--
-- How it works:
-- 1. When HP drops below threshold → TP to spawn → heal → TP back
-- 2. Position Lock: while standing (not in combat), don't fall down
-- 3. Killaura works alongside dodge — they don't interfere
--
-- Key fix: dodgeHealing is set BEFORE spawn() so position lock
-- knows immediately not to interfere with the heal trip.
-- ============================================================

local function startAutoDodge()
    -- Clean up old connections
    if dodgeConnLock then dodgeConnLock:Disconnect() dodgeConnLock = nil end
    if dodgeConnHeal then dodgeConnHeal:Disconnect() dodgeConnHeal = nil end

    isDodging = false
    dodgeHealing = false

    -- Set lock position to raft so player doesn't fall into void
    local raftPos = getRaftPosition()
    dodgeLockPos = CFrame.new(raftPos)

    -- === PART 1: Quick Heal (TP to spawn, heal, TP back) ===
    -- Check HP every frame. If low and not already healing, do a heal trip.
    dodgeConnHeal = RunService.Heartbeat:Connect(function()
        -- Already healing? Skip
        if isDodging then return end

        local hum = getHum()
        if not hum then return end
        if hum.Health <= 0 then return end

        -- Trigger heal when HP below threshold
        if hum.Health < dodgeHPThreshold then
            -- Set flags IMMEDIATELY so position lock doesn't interfere
            isDodging = true
            dodgeHealing = true

            -- Save current position BEFORE teleporting
            local savedPos = nil
            local h = getHRP()
            if h then
                savedPos = h.CFrame
            end

            -- TP to raft right now (immediate)
            local healPos = getRaftPosition()
            h = getHRP()
            if h then
                pcall(function() h.CFrame = CFrame.new(healPos) end)
            end

            -- Now heal in a separate thread
            spawn(function()
                -- Keep TP-ing to raft while healing
                local healStart = tick()
                while (tick() - healStart) < 4 do
                    local h2 = getHum()
                    if not h2 then break end
                    -- Healed enough? Go back
                    if h2.Health >= h2.MaxHealth * 0.85 then
                        break
                    end
                    -- Stay on raft
                    local hrp = getHRP()
                    if hrp then
                        pcall(function() hrp.CFrame = CFrame.new(healPos) end)
                    end
                    origWait(0.05)
                end

                -- TP back to saved position
                if savedPos then
                    local hrp2 = getHRP()
                    if hrp2 then
                        pcall(function() hrp2.CFrame = savedPos end)
                    end
                end

                -- Cooldown before next dodge
                origWait(1)
                dodgeHealing = false
                isDodging = false
            end)
        end
    end)

    -- === PART 2: Position Lock (don't fall into void, snap to raft) ===
    -- Only enforce position when NOT healing and NOT in killaura combat
    dodgeConnLock = RunService.Heartbeat:Connect(function()
        -- Don't interfere with healing or killaura TP
        if dodgeHealing then return end
        if isDodging then return end
        if tpRunning and currentMode == 1 then return end

        local h = getHRP()
        if not h then return end

        local currentPos = h.CFrame.Position

        if dodgeLockPos then
            local lockPos = dodgeLockPos.Position
            local yDiff = currentPos.Y - lockPos.Y
            local xzDiff = Vector3.new(currentPos.X - lockPos.X, 0, currentPos.Z - lockPos.Z).Magnitude

            -- If falling down or drifted too far, snap back to lock position
            if yDiff < -2 or xzDiff > 8 then
                pcall(function() h.CFrame = dodgeLockPos end)
            end
        end

        -- Anti-void: if Y is very low (falling into void), TP to raft
        if currentPos.Y < -50 then
            local raftPos = getRaftPosition()
            pcall(function() h.CFrame = CFrame.new(raftPos) end)
            dodgeLockPos = CFrame.new(raftPos)
        end
    end)

    -- === PART 3: Update lock position when standing still on ground ===
    spawn(function()
        while autoDodge do
            origWait(0.5)
            if not dodgeHealing and not isDodging and not (tpRunning and currentMode == 1) then
                local hum = getHum()
                local hrp5 = getHRP()
                if hum and hrp5 and hum.Health > 0 then
                    local vel = hrp5.Velocity
                    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
                    local fallSpeed = math.abs(vel.Y)
                    if speed < 1 and fallSpeed < 5 then
                        dodgeLockPos = hrp5.CFrame
                    end
                end
            end
        end
    end)
end

local function stopAutoDodge()
    if dodgeConnLock then dodgeConnLock:Disconnect() dodgeConnLock = nil end
    if dodgeConnHeal then dodgeConnHeal:Disconnect() dodgeConnHeal = nil end
    isDodging = false
    dodgeHealing = false
    dodgeLockPos = nil
end

-- ============================================================
-- AUTO RESPAWN — REMOVED (doesn't work in this game)
-- ============================================================

-- ============================================================
-- SCANNER
-- ============================================================

local function startScanner()
    if connScan then connScan:Disconnect() connScan = nil end
    connScan = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastScan >= 0.4 then
            lastScan = now
            buildPlayerBlacklist()
            scanEnemies()
            if showESP then updateESP() end
        end
    end)
end

-- ============================================================
-- STOP ALL
-- ============================================================

local function stopAll()
    if connTP then connTP:Disconnect() connTP = nil end
    killedList = {}
    killedNum = 0
    currentMode = 0
    enemyCache = {}
    tpRunning = false
    clearESP()
end

-- ============================================================
-- GUI — Soldatik Nikitka Hub
-- ============================================================

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("SoldatikNikitkaHub")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SoldatikNikitkaHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- === Main Frame ===
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 420)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Active = false  -- must be false or player can't move
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 50, 200)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- === Title Bar ===
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
titleBar.BorderSizePixel = 0
titleBar.Active = false  -- drag uses UserInputService, no need to block game input
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Gradient on title
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 160)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 15, 80)),
})
titleGrad.Rotation = 90
titleGrad.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Soldatik Nikitka Hub"
titleText.TextColor3 = Color3.fromRGB(220, 180, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 15
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Active = false
titleText.Selectable = false
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -62, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

-- === Content Area (scrollable) ===
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -16, 1, -46)
contentFrame.Position = UDim2.new(0, 8, 0, 42)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local y = 0

-- Helper: make styled toggle button
local function makeBtn(name, color, h)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, h)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = contentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    y = y + h + 4
    return btn
end

-- Helper: small description label
local function makeLabel(text, color, sz)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, sz)
    lbl.Position = UDim2.new(0, 6, 0, y - sz - 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 10
    lbl.Parent = contentFrame
end

-- Helper: section separator
local function makeSep()
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 0, y)
    sep.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
    sep.BorderSizePixel = 0
    sep.Parent = contentFrame
    y = y + 6
end

-- === KillAura TP ===
local btnTP = makeBtn("KillAura TP", Color3.fromRGB(25, 70, 25), 30)
makeLabel("TP to toilet + stay until dead + next", Color3.fromRGB(100, 100, 130), 10)
y = y + 2

-- Predict controls
local predictLabel = Instance.new("TextLabel")
predictLabel.Size = UDim2.new(0.55, 0, 0, 22)
predictLabel.Position = UDim2.new(0, 4, 0, y)
predictLabel.BackgroundTransparency = 1
predictLabel.Text = "Predict: 0.5"
predictLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
predictLabel.Font = Enum.Font.Gotham
predictLabel.TextSize = 10
predictLabel.TextXAlignment = Enum.TextXAlignment.Left
predictLabel.Parent = contentFrame

local predictMinus = Instance.new("TextButton")
predictMinus.Size = UDim2.new(0, 34, 0, 22)
predictMinus.Position = UDim2.new(0.56, 0, 0, y)
predictMinus.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
predictMinus.Text = "-"
predictMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
predictMinus.Font = Enum.Font.GothamBold
predictMinus.TextSize = 14
predictMinus.BorderSizePixel = 0
predictMinus.Parent = contentFrame

local pmCorner = Instance.new("UICorner")
pmCorner.CornerRadius = UDim.new(0, 5)
pmCorner.Parent = predictMinus

local predictPlus = Instance.new("TextButton")
predictPlus.Size = UDim2.new(0, 34, 0, 22)
predictPlus.Position = UDim2.new(0.78, 0, 0, y)
predictPlus.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
predictPlus.Text = "+"
predictPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
predictPlus.Font = Enum.Font.GothamBold
predictPlus.TextSize = 14
predictPlus.BorderSizePixel = 0
predictPlus.Parent = contentFrame

local ppCorner = Instance.new("UICorner")
ppCorner.CornerRadius = UDim.new(0, 5)
ppCorner.Parent = predictPlus

y = y + 26

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 4, 0, y)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(140, 120, 180)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame
y = y + 20

-- Kills / Alive
local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0.48, 0, 0, 16)
killLabel.Position = UDim2.new(0, 4, 0, y)
killLabel.BackgroundTransparency = 1
killLabel.Text = "Kills: 0"
killLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
killLabel.Font = Enum.Font.GothamBold
killLabel.TextSize = 11
killLabel.TextXAlignment = Enum.TextXAlignment.Left
killLabel.Parent = contentFrame

local aliveLabel = Instance.new("TextLabel")
aliveLabel.Size = UDim2.new(0.48, 0, 0, 16)
aliveLabel.Position = UDim2.new(0.52, 0, 0, y)
aliveLabel.BackgroundTransparency = 1
aliveLabel.Text = "Toilets: 0"
aliveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
aliveLabel.Font = Enum.Font.GothamBold
aliveLabel.TextSize = 11
aliveLabel.TextXAlignment = Enum.TextXAlignment.Right
aliveLabel.Parent = contentFrame
y = y + 22

-- Separator
makeSep()

-- === Auto Dodge ===
local btnDodge = makeBtn("Auto Dodge", Color3.fromRGB(20, 50, 90), 28)
makeLabel("Position lock + quick heal", Color3.fromRGB(100, 100, 130), 10)

-- Dodge HP controls
local dodgeThreshLabel = Instance.new("TextLabel")
dodgeThreshLabel.Size = UDim2.new(0.55, 0, 0, 22)
dodgeThreshLabel.Position = UDim2.new(0, 4, 0, y)
dodgeThreshLabel.BackgroundTransparency = 1
dodgeThreshLabel.Text = "Dodge HP: 1000"
dodgeThreshLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
dodgeThreshLabel.Font = Enum.Font.Gotham
dodgeThreshLabel.TextSize = 10
dodgeThreshLabel.TextXAlignment = Enum.TextXAlignment.Left
dodgeThreshLabel.Parent = contentFrame

local dodgeMinus = Instance.new("TextButton")
dodgeMinus.Size = UDim2.new(0, 34, 0, 22)
dodgeMinus.Position = UDim2.new(0.56, 0, 0, y)
dodgeMinus.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
dodgeMinus.Text = "-"
dodgeMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
dodgeMinus.Font = Enum.Font.GothamBold
dodgeMinus.TextSize = 14
dodgeMinus.BorderSizePixel = 0
dodgeMinus.Parent = contentFrame

local dmCorner = Instance.new("UICorner")
dmCorner.CornerRadius = UDim.new(0, 5)
dmCorner.Parent = dodgeMinus

local dodgePlus = Instance.new("TextButton")
dodgePlus.Size = UDim2.new(0, 34, 0, 22)
dodgePlus.Position = UDim2.new(0.78, 0, 0, y)
dodgePlus.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
dodgePlus.Text = "+"
dodgePlus.TextColor3 = Color3.fromRGB(255, 255, 255)
dodgePlus.Font = Enum.Font.GothamBold
dodgePlus.TextSize = 14
dodgePlus.BorderSizePixel = 0
dodgePlus.Parent = contentFrame

local dpCorner = Instance.new("UICorner")
dpCorner.CornerRadius = UDim.new(0, 5)
dpCorner.Parent = dodgePlus

y = y + 28

-- Separator
makeSep()

-- === Blaster CD controls ===
local blasterCDLabel = Instance.new("TextLabel")
blasterCDLabel.Size = UDim2.new(0.55, 0, 0, 22)
blasterCDLabel.Position = UDim2.new(0, 4, 0, y)
blasterCDLabel.BackgroundTransparency = 1
blasterCDLabel.Text = "Blaster CD: 0.3s"
blasterCDLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
blasterCDLabel.Font = Enum.Font.Gotham
blasterCDLabel.TextSize = 10
blasterCDLabel.TextXAlignment = Enum.TextXAlignment.Left
blasterCDLabel.Parent = contentFrame

local blasterCDMinus = Instance.new("TextButton")
blasterCDMinus.Size = UDim2.new(0, 34, 0, 22)
blasterCDMinus.Position = UDim2.new(0.56, 0, 0, y)
blasterCDMinus.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
blasterCDMinus.Text = "-"
blasterCDMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
blasterCDMinus.Font = Enum.Font.GothamBold
blasterCDMinus.TextSize = 14
blasterCDMinus.BorderSizePixel = 0
blasterCDMinus.Parent = contentFrame

local bcdmCorner = Instance.new("UICorner")
bcdmCorner.CornerRadius = UDim.new(0, 5)
bcdmCorner.Parent = blasterCDMinus

local blasterCDPlus = Instance.new("TextButton")
blasterCDPlus.Size = UDim2.new(0, 34, 0, 22)
blasterCDPlus.Position = UDim2.new(0.78, 0, 0, y)
blasterCDPlus.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
blasterCDPlus.Text = "+"
blasterCDPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
blasterCDPlus.Font = Enum.Font.GothamBold
blasterCDPlus.TextSize = 14
blasterCDPlus.BorderSizePixel = 0
blasterCDPlus.Parent = contentFrame

local bcdpCorner = Instance.new("UICorner")
bcdpCorner.CornerRadius = UDim.new(0, 5)
bcdpCorner.Parent = blasterCDPlus

y = y + 26

-- Separator
makeSep()

-- === ESP ===
local btnESP = makeBtn("ESP", Color3.fromRGB(40, 35, 50), 28)

y = y + 4

-- Key hint at bottom
local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, 0, 0, 14)
keyHint.Position = UDim2.new(0, 0, 0, y)
keyHint.BackgroundTransparency = 1
keyHint.Text = "[E] toggle  |  drag title to move"
keyHint.TextColor3 = Color3.fromRGB(70, 60, 100)
keyHint.Font = Enum.Font.Gotham
keyHint.TextSize = 9
keyHint.TextXAlignment = Enum.TextXAlignment.Center
keyHint.Parent = contentFrame

-- Resize frame
mainFrame.Size = UDim2.new(0, 260, 0, y + 60)

-- ============================================================
-- BUTTON COLORS / STATE
-- ============================================================

local defaultColors = {
    ["KillAura TP"] = Color3.fromRGB(25, 70, 25),
    ["Auto Dodge"] = Color3.fromRGB(20, 50, 90),
    ["ESP"] = Color3.fromRGB(40, 35, 50),
}

local onColor = Color3.fromRGB(120, 40, 200)

local function setBtn(btn, on)
    if on then
        btn.Text = btn.Name .. ": ON"
        btn.BackgroundColor3 = onColor
    else
        btn.Text = btn.Name .. ": OFF"
        btn.BackgroundColor3 = defaultColors[btn.Name] or Color3.fromRGB(40, 35, 50)
    end
end

-- ============================================================
-- BUTTON EVENTS
-- ============================================================

btnTP.MouseButton1Click:Connect(function()
    if currentMode == 1 then
        stopAll()
        setBtn(btnTP, false)
        statusLabel.Text = "Status: OFF"
    else
        stopAll()
        currentMode = 1
        startKillAuraTP()
        setBtn(btnTP, true)
        statusLabel.Text = "Status: KillAura TP"
    end
end)

btnDodge.MouseButton1Click:Connect(function()
    autoDodge = not autoDodge
    if autoDodge then
        startAutoDodge()
        setBtn(btnDodge, true)
    else
        stopAutoDodge()
        setBtn(btnDodge, false)
    end
end)

dodgeMinus.MouseButton1Click:Connect(function()
    dodgeHPThreshold = math.max(400, dodgeHPThreshold - 200)
    dodgeThreshLabel.Text = "Dodge HP: " .. tostring(dodgeHPThreshold)
end)

dodgePlus.MouseButton1Click:Connect(function()
    dodgeHPThreshold = math.min(5000, dodgeHPThreshold + 200)
    dodgeThreshLabel.Text = "Dodge HP: " .. tostring(dodgeHPThreshold)
end)

predictMinus.MouseButton1Click:Connect(function()
    predictStrength = math.max(0, predictStrength - 0.1)
    predictStrength = math.floor(predictStrength * 10 + 0.5) / 10  -- round to 0.1
    predictLabel.Text = "Predict: " .. tostring(predictStrength)
end)

predictPlus.MouseButton1Click:Connect(function()
    predictStrength = math.min(3, predictStrength + 0.1)
    predictStrength = math.floor(predictStrength * 10 + 0.5) / 10  -- round to 0.1
    predictLabel.Text = "Predict: " .. tostring(predictStrength)
end)

blasterCDMinus.MouseButton1Click:Connect(function()
    blasterCD = math.max(0.05, blasterCD - 0.05)
    blasterCD = math.floor(blasterCD * 100 + 0.5) / 100  -- round to 0.01
    blasterCDLabel.Text = "Blaster CD: " .. string.format("%.2f", blasterCD) .. "s"
end)

blasterCDPlus.MouseButton1Click:Connect(function()
    blasterCD = math.min(2, blasterCD + 0.05)
    blasterCD = math.floor(blasterCD * 100 + 0.5) / 100  -- round to 0.01
    blasterCDLabel.Text = "Blaster CD: " .. string.format("%.2f", blasterCD) .. "s"
end)

btnESP.MouseButton1Click:Connect(function()
    showESP = not showESP
    setBtn(btnESP, showESP)
    if not showESP then clearESP() end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopAll()
    autoDodge = false
    stopAutoDodge()
    cdHookActive = false
    if connScan then connScan:Disconnect() connScan = nil end
    if connBypassCD then connBypassCD:Disconnect() connBypassCD = nil end
    clearESP()
    screenGui:Destroy()
end)

-- ============================================================
-- MINIMIZE
-- ============================================================

local minimized = false
local savedSize = mainFrame.Size

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        savedSize = mainFrame.Size
        mainFrame.Size = UDim2.new(0, 260, 0, 38)
        contentFrame.Visible = false
    else
        mainFrame.Size = savedSize
        contentFrame.Visible = true
    end
end)

-- ============================================================
-- KEYBIND
-- ============================================================

-- Debounce for GUI toggle — prevents rapid open/close flickering
local lastGuiToggle = 0
-- Time-based VIM suppression — VIM E key can trigger toggle after vimPressCount resets
local lastVIMTime = 0
local VIM_SUPPRESS_DURATION = 1.0  -- block keybind for 1s after VIM fires

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.E then
        -- Block E toggle if VIM recently fired keys (E is an ability key)
        local now = tick()
        if (now - lastVIMTime) < VIM_SUPPRESS_DURATION then return end
        -- Debounce: don't allow toggle more than once per 0.5s
        if now - lastGuiToggle < 0.5 then return end
        lastGuiToggle = now
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- ============================================================
-- BACKGROUND LOOP (stats) — uses origWait
-- ============================================================

spawn(function()
    while screenGui and screenGui.Parent do
        origWait(1)
        pcall(function()
            killLabel.Text = "Kills: " .. tostring(totalKills)
            local c = 0
            for _ in pairs(enemyCache) do c = c + 1 end
            aliveLabel.Text = "Toilets: " .. tostring(c)
        end)
    end
end)

-- ============================================================
-- SCANNER START
-- ============================================================

startScanner()

-- ============================================================
-- DRAG — via UserInputService (works with Active=false)
-- Checks if mouse is over titleBar area, then drags
-- ============================================================

local dragging = false
local dragStart = nil
local startPos = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    -- NOTE: we do NOT check gpe here — we need to capture drags even when
    -- the game also processed the click (since Active=false lets clicks through)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local framePos = mainFrame.AbsolutePosition
        local frameSize = mainFrame.AbsoluteSize
        local titleH = 38

        -- Check if click is inside the title bar area
        if mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
            and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + titleH then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("Soldatik Nikitka Hub loaded | [E] toggle")
print("CD Bypass: wait/task.wait/task.delay hook + CD script destroy + __newindex block + value reset")
print("Abilities: faster use in combat (VIM keypress + cached remotes in killaura only)")
print("KillAura: 3x faster attack cycle, burst weapon activation")
print("Auto Dodge v2: Position lock + quick heal")

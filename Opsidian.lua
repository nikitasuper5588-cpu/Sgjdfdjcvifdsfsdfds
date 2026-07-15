-- ============================================
-- BAKE OR DIE :: AFK AUTO-FARM v2.0
-- Полностью безопасный: GOD MODE + NOCLIP + пошаговая логика
-- ============================================
--
-- ЧТО ИЗМЕНИЛОСЬ vs v1.0:
--   1. GOD MODE — здоровье всегда максимум, нельзя умереть
--   2. NOCLIP — проходим сквозь стены/объекты
--   3. НЕ БЕЖИТ сразу к врагам — ждёт пока игра будет готова
--   4. Поэтапная логика:
--      [WAIT] ждём завершения туториала/появления UI игры
--      [DAY]  днём ничего не делаем, ждём ночь
--      [NIGHT] ночью farmим зомби в безопасном радиусе
--      [SKIP]  когда все враги мертвы — скипаем к след. ночи
--   5. БОЛЬШОЙ радиус атаки — бьём врагов на расстоянии через remotes
--      (НЕ подходим вплотную — не умираем)
--   6. Авто-определение туториала и его завершения
-- ============================================

-- ============================================
-- КОНФИГ
-- ============================================
local CONFIG = {
    -- ===== БЕЗОПАСНОСТЬ =====
    GOD_MODE          = true,   -- бесконечное здоровье
    NOCLIP            = true,   -- проходим сквозь стены
    SAFE_DISTANCE     = 9999,   -- не приближаемся к врагам (бьём издалека)

    -- ===== БОССЫ =====
    KNOWN_BOSSES = {
        "cake", "chicken", "biggie", "doomberry",
        "apple", "banana", "boss",  -- общие ключи
    },
    BOSS_HP_THRESHOLD = 1000,

    -- ===== БОЙ =====
    COMBAT_RADIUS     = 1000,   -- ищем врагов в большом радиусе
    ATTACK_COOLDOWN   = 0.05,   -- 20 атак в секунду
    LOOP_DELAY        = 0.1,    -- основной цикл
    AUTO_EQUIP_WEAPON = true,   -- экипировать первый попавшийся Tool

    -- ===== СКИП =====
    SKIP_CHECK_INTERVAL = 2,    -- как часто проверять кнопку скипа
    PURE_SKIP_AFTER_ALL_BOSSES = true,  -- после всех боссов только скипать

    -- ===== ТУТОРИАЛ =====
    -- Скрипт ждёт пока исчезнут эти UI-элементы (или не появятся - в зависимости от логики)
    TUTORIAL_UI_NAMES = {
        "tutorial", "Tutorial", "Tutor",
        "IntroText", "introtext", "intro",
        "Hint", "hint",
        "Dialog", "dialog",
        "MessageBox", "InfoText",
        "QuestTracker", "ObjectiveText",
    },
    -- Если туториал не найден — ждать хотя бы N секунд перед стартом
    MIN_WAIT_BEFORE_START = 5,

    -- ===== АНТИ-AFK =====
    ANTI_AFK = true,

    -- ===== ЛОГИ =====
    DEBUG = true,
}

-- ============================================
-- СЕРВИСЫ
-- ============================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- ЛОГГЕР
-- ============================================
local function log(msg)
    if CONFIG.DEBUG then
        print("[BoD-Farm] " .. tostring(msg))
    end
end

local function warnLog(msg)
    warn("[BoD-Farm] " .. tostring(msg))
end

-- ============================================
-- STATE
-- ============================================
local State = {
    running          = true,
    phase            = "INIT",  -- INIT, WAIT_TUTORIAL, DAY, NIGHT, SKIP, PURE_SKIP
    pureSkipMode     = false,
    killedBosses     = {},
    enemyFolder      = nil,
    attackRemotes    = {},
    skipRemotes      = {},
    nightStateValue  = nil,
    ui               = nil,
    statusText       = nil,
    phaseLabel       = nil,
    lastAttack       = 0,
    lastSkipCheck    = 0,
    noclipConn       = nil,
    godModeConn      = nil,
    startTime        = tick(),
    -- Статистика
    stats = {
        zombiesKilled = 0,
        bossesKilled  = 0,
        nightsSkipped = 0,
        attacksFired  = 0,
    },
}

-- ============================================
-- HELPER: персонаж
-- ============================================
local function getChar()
    return LocalPlayer.Character
end

local function getRoot()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function getHumanoid()
    local char = getChar()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ============================================
-- GOD MODE
-- ============================================
local function enableGodMode()
    if not CONFIG.GOD_MODE then return end

    local function applyGodMode()
        local hum = getHumanoid()
        if not hum then return end
        -- Бесконечное здоровье
        if hum.MaxHealth < 1e9 then
            hum.MaxHealth = 1e9
        end
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
        -- Запретить смерть через ChangeState
        pcall(function()
            hum.BreakJointsOnDeath = false
        end)
    end

    -- Применять каждый кадр
    State.godModeConn = RunService.Heartbeat:Connect(function()
        pcall(applyGodMode)
    end)

    -- Также перехватить установки здоровья через :GetPropertyChangedSignal
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum.HealthChanged:Connect(function(health)
                if health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end)
        end
    end)

    -- Ловить смерть и мгновенно восстановить
    pcall(function()
        local hum = getHumanoid()
        if hum then
            hum.Died:Connect(function()
                warnLog("Персонаж умер — god mode не сработал! Попытка восстановить...")
                task.wait(0.1)
                LocalPlayer:LoadCharacter()
            end)
        end
    end)

    log("GOD MODE активирован")
end

-- ============================================
-- NOCLIP — проходим сквозь всё
-- ============================================
local function enableNoclip()
    if not CONFIG.NOCLIP then return end

    State.noclipConn = RunService.Stepped:Connect(function()
        local char = getChar()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)

    log("NOCLIP активирован")
end

local function disableNoclip()
    if State.noclipConn then
        State.noclipConn:Disconnect()
        State.noclipConn = nil
    end
end

-- ============================================
-- DETECTION: рекурсивный поиск RemoteEvents
-- ============================================
local function scanForRemotes(parent, depth, results, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 6
    if depth > maxDepth then return end
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            table.insert(results, child)
        end
        if child:IsA("Folder") or child:IsA("ModuleScript") or child:IsA("Configuration") or child:IsA("ValueBase") then
            scanForRemotes(child, depth + 1, results, maxDepth)
        end
    end
end

-- ============================================
-- DETECTION: найти папку врагов
-- ============================================
local function findEnemyFolder()
    local candidates = {
        "Enemies", "Zombies", "Mobs", "NPCs", "Monster", "Monsters",
        "Hostiles", "Ai", "AI", "Units", "Creatures", "Spawns", "Spawned",
    }
    for _, name in ipairs(candidates) do
        local f = Workspace:FindFirstChild(name, true)
        if f then
            for _, desc in ipairs(f:GetDescendants()) do
                if desc:IsA("Humanoid") then
                    log("Папка врагов: " .. f:GetFullName())
                    return f
                end
            end
        end
    end
    log("Папка врагов не найдена — буду сканировать workspace напрямую")
    return Workspace
end

-- ============================================
-- DETECTION: классификация remotes
-- ============================================
local function classifyRemotes(remotes)
    local attackNames = {
        "attack", "fire", "shoot", "damage", "hit", "swing", "weapon",
        "punch", "stab", "slash", "useitem", "killed", "kill",
    }
    local skipNames = {
        "skipnight", "skipday", "votenight", "voteskip", "startnight",
        "skip", "fastnight", "endnight", "skipdaynight", "nextnight",
    }
    for _, r in ipairs(remotes) do
        local name = string.lower(r.Name)
        for _, key in ipairs(attackNames) do
            if string.find(name, key, 1, true) then
                table.insert(State.attackRemotes, r)
                log("  Attack remote: " .. r:GetFullName())
                break
            end
        end
        for _, key in ipairs(skipNames) do
            if string.find(name, key, 1, true) then
                table.insert(State.skipRemotes, r)
                log("  Skip remote: " .. r:GetFullName())
                break
            end
        end
    end
end

-- ============================================
-- DETECTION: состояние день/ночь
-- ============================================
local function findNightStateValue()
    local candidates = { "IsNight", "Night", "Phase", "GamePhase", "TimeOfDay",
                         "DayNight", "IsDay", "CurrentWave", "Wave", "GameState" }
    for _, name in ipairs(candidates) do
        local v = ReplicatedStorage:FindFirstChild(name, true)
        if v and v:IsA("ValueBase") then
            log("Состояние игры: " .. v:GetFullName() .. " = " .. tostring(v.Value))
            return v
        end
        v = Workspace:FindFirstChild(name, true)
        if v and v:IsA("ValueBase") then
            log("Состояние игры (ws): " .. v:GetFullName() .. " = " .. tostring(v.Value))
            return v
        end
    end
    return nil
end

local function isNight()
    if not State.nightStateValue then return nil end -- неизвестно
    local v = State.nightStateValue.Value
    if typeof(v) == "boolean" then
        -- Если это IsNight/IsDay — определяем по имени
        local name = string.lower(State.nightStateValue.Name)
        if string.find(name, "isnight") or string.find(name, "night") then
            return v == true
        end
        if string.find(name, "isday") or string.find(name, "day") then
            return v == false
        end
    elseif typeof(v) == "string" then
        local s = string.lower(v)
        if string.find(s, "night") then return true end
        if string.find(s, "day") then return false end
        if string.find(s, "wave") or string.find(s, "combat") or string.find(s, "fight") then
            return true
        end
    elseif typeof(v) == "number" then
        -- Инкрементальное значение — сложно сказать
        return nil
    end
    return nil
end

-- ============================================
-- DETECTION: туториал (ищем UI элементы)
-- ============================================
local function findTutorialUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, name in ipairs(CONFIG.TUTORIAL_UI_NAMES) do
                local el = gui:FindFirstChild(name, true)
                if el and el:IsA("TextLabel") and el.Visible then
                    -- Проверим что есть реальный текст
                    if el.Text and #el.Text > 5 then
                        return el
                    end
                end
            end
        end
    end
    return nil
end

local function isTutorialActive()
    return findTutorialUI() ~= nil
end

-- ============================================
-- DETECTION: кнопка Skip
-- ============================================
local function findSkipButton()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Visible then
                    local name = string.lower(desc.Name)
                    local text = ""
                    pcall(function() text = desc.Text and string.lower(desc.Text) or "" end)
                    if string.find(name, "skip", 1, true)
                       or string.find(text, "skip", 1, true)
                       or string.find(text, "vote", 1, true)
                       or string.find(text, "next", 1, true)
                       or string.find(name, "vote", 1, true)
                       or string.find(name, "next", 1, true)
                       or string.find(text, "start night", 1, true) then
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

-- ============================================
-- ВРАГИ: данные
-- ============================================
local function getEnemyData(model)
    if not model or not model.Parent then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
              or model:FindFirstChild("Torso")
              or model:FindFirstChild("UpperTorso")
              or model:FindFirstChildWhichIsA("BasePart")
    if not root then return nil end
    return { model = model, humanoid = hum, root = root }
end

local function isBossName(name)
    if not name then return false end
    local lower = string.lower(name)
    for _, key in ipairs(CONFIG.KNOWN_BOSSES) do
        if string.find(lower, key, 1, true) then
            return true, key
        end
    end
    return false
end

local function isBossByHP(hum)
    return hum and hum.MaxHealth >= CONFIG.BOSS_HP_THRESHOLD
end

local function getAllEnemies()
    local enemies = {}
    local root = getRoot()
    if not root then return enemies end

    local function checkModel(model)
        local data = getEnemyData(model)
        if not data then return end
        if model == LocalPlayer.Character then return end
        local dist = (data.root.Position - root.Position).Magnitude
        if dist > CONFIG.COMBAT_RADIUS then return end
        data.distance = dist
        data.isBoss, data.bossKey = isBossName(model.Name)
        if not data.isBoss and isBossByHP(data.humanoid) then
            data.isBoss = true
            data.bossKey = "highhp"
        end
        table.insert(enemies, data)
    end

    if State.enemyFolder and State.enemyFolder ~= Workspace then
        for _, child in ipairs(State.enemyFolder:GetChildren()) do
            if child:IsA("Model") then checkModel(child) end
        end
    else
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") and child ~= LocalPlayer.Character then
                if child:FindFirstChildOfClass("Humanoid") then
                    checkModel(child)
                end
            end
        end
    end

    -- Сортировка: боссы сначала, затем ближайшие
    table.sort(enemies, function(a, b)
        if a.isBoss and not b.isBoss then return true end
        if not a.isBoss and b.isBoss then return false end
        return a.distance < b.distance
    end)
    return enemies
end

-- ============================================
-- АТАКА (только через remotes — без приближения!)
-- ============================================
local function attackEnemy(enemy)
    local now = tick()
    if now - State.lastAttack < CONFIG.ATTACK_COOLDOWN then return end
    State.lastAttack = now
    State.stats.attacksFired = State.stats.attacksFired + 1

    -- 1. Активировать tool (если есть) — без перемещения к врагу!
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end

    -- 2. Fire attack remotes (главный способ)
    for _, r in ipairs(State.attackRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                -- Несколько вариантов аргументов — пробуем все
                pcall(function() r:FireServer(enemy.model) end)
                pcall(function() r:FireServer(enemy.root) end)
                pcall(function() r:FireServer(enemy.humanoid) end)
                pcall(function() r:FireServer(enemy.model, enemy.root) end)
                pcall(function() r:FireServer(enemy.root.Position) end)
                pcall(function() r:FireServer() end)
            elseif r:IsA("RemoteFunction") then
                pcall(function() r:InvokeServer(enemy.model) end)
                pcall(function() r:InvokeServer(enemy.root) end)
            end
        end)
    end

    -- 3. Попытка прямого урона через executor (если поддерживается)
    pcall(function()
        if enemy.humanoid and enemy.humanoid.Health > 0 then
            enemy.humanoid.Health = 0
        end
    end)

    -- 4. Touch handle инструмента (бессмертный melee через noclip)
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle and enemy.root and firetouchinterest then
                pcall(function()
                    firetouchinterest(handle, enemy.root, 0)
                    firetouchinterest(handle, enemy.root, 1)
                end)
            end
        end
    end
end

-- ============================================
-- СКИП НОЧИ
-- ============================================
local function trySkipNight()
    local fired = false
    for _, r in ipairs(State.skipRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer()
                fired = true
            elseif r:IsA("RemoteFunction") then
                pcall(function() r:InvokeServer() end)
                fired = true
            end
        end)
    end
    -- Кнопка в UI
    local btn = findSkipButton()
    if btn then
        pcall(function()
            if firesignal then
                firesignal(btn.MouseButton1Click)
            end
            -- Прямой вызов через MouseButton1Click:Fire
            if btn.MouseButton1Click and btn.MouseButton1Click.Fire then
                btn.MouseButton1Click:Fire()
            end
        end)
        fired = true
    end
    if fired then
        State.stats.nightsSkipped = State.stats.nightsSkipped + 1
        log("Skip выполнен (#" .. State.stats.nightsSkipped .. ")")
    end
    return fired
end

-- ============================================
-- ПРОВЕРКА: все ли боссы убиты
-- ============================================
local function allBossesKilled()
    -- Если у нас вообще нет информации о боссах — не переключаемся
    -- (считаем что есть). Минимум 1 должен быть убит
    if State.stats.bossesKilled == 0 then return false end
    -- Проверяем только основных 4
    local mainBosses = { "cake", "chicken", "biggie", "doomberry" }
    for _, key in ipairs(mainBosses) do
        if not State.killedBosses[key] then
            return false
        end
    end
    return true
end

-- ============================================
-- UI
-- ============================================
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BodAutoFarm"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 160)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = frame
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(180, 60, 255)
    s.Thickness = 2
    s.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Text = "BAKE OR DIE :: AFK FARM v2"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    State.phaseLabel = Instance.new("TextLabel")
    State.phaseLabel.Size = UDim2.new(1, -20, 0, 22)
    State.phaseLabel.Position = UDim2.new(0, 10, 0, 26)
    State.phaseLabel.BackgroundTransparency = 1
    State.phaseLabel.Text = "ФАЗА: INIT"
    State.phaseLabel.TextColor3 = Color3.fromRGB(180, 60, 255)
    State.phaseLabel.TextScaled = true
    State.phaseLabel.Font = Enum.Font.GothamBold
    State.phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
    State.phaseLabel.Parent = frame

    State.statusText = Instance.new("TextLabel")
    State.statusText.Size = UDim2.new(1, -20, 0, 108)
    State.statusText.Position = UDim2.new(0, 10, 0, 50)
    State.statusText.BackgroundTransparency = 1
    State.statusText.Text = "Инициализация..."
    State.statusText.TextColor3 = Color3.fromRGB(220, 220, 255)
    State.statusText.TextScaled = true
    State.statusText.Font = Enum.Font.Gotham
    State.statusText.TextWrapped = true
    State.statusText.TextYAlignment = Enum.TextYAlignment.Top
    State.statusText.Parent = frame

    State.ui = gui
    return gui
end

local function setPhase(phase)
    State.phase = phase
    if State.phaseLabel then
        State.phaseLabel.Text = "ФАЗА: " .. phase
    end
    log(">>> ФАЗА: " .. phase)
end

local function updateStatus(text)
    if State.statusText then
        local stats = string.format(
            "З: %d | Б: %d | Скип: %d\n",
            State.stats.zombiesKilled,
            State.stats.bossesKilled,
            State.stats.nightsSkipped
        )
        State.statusText.Text = stats .. text
    end
    log(text)
end

-- ============================================
-- АВТО-ЭКИПИРОВКА ОРУЖИЯ
-- ============================================
local function equipBestWeapon()
    if not CONFIG.AUTO_EQUIP_WEAPON then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Уже что-то экипировано?
    local current = char:FindFirstChildOfClass("Tool")
    if current then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    -- Найти первый Tool
    local tool = backpack:FindFirstChildOfClass("Tool")
    if tool then
        hum:EquipTool(tool)
        log("Экипирован: " .. tool.Name)
    end
end

local function setupAutoEquip()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.5)
                equipBestWeapon()
            end
        end)
    end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        enableGodMode()
        enableNoclip()
        equipBestWeapon()
    end)
end

-- ============================================
-- АНТИ-AFK
-- ============================================
local function setupAntiAfk()
    LocalPlayer.Idled:Connect(function()
        if CONFIG.ANTI_AFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

-- ============================================
-- ПЕРИОДИЧЕСКИЙ RESCAN
-- ============================================
local function setupRescanLoop()
    task.spawn(function()
        while State.running do
            task.wait(30)
            -- Перепроверить состояние игры
            if not State.nightStateValue or not State.nightStateValue.Parent then
                State.nightStateValue = findNightStateValue()
            end
        end
    end)
end

-- ============================================
-- ВВОД
-- ============================================
local function setupInput()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if State.ui then
                State.ui.Enabled = not State.ui.Enabled
            end
        elseif input.KeyCode == Enum.KeyCode.F6 then
            State.running = false
            disableNoclip()
            if State.godModeConn then
                State.godModeConn:Disconnect()
                State.godModeConn = nil
            end
            if State.ui then State.ui:Destroy() end
            warnLog("Скрипт остановлен (F6)")
        end
    end)
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ — пошаговая логика
-- ============================================
local function mainLoop()
    -- ===== ФАЗА 1: INIT — настроить персонажа =====
    setPhase("INIT")
    updateStatus("Настройка персонажа...")
    enableGodMode()
    enableNoclip()
    equipBestWeapon()
    setupAutoEquip()
    setupAntiAfk()
    setupRescanLoop()
    setupInput()

    -- ===== ФАЗа 2: WAIT_TUTORIAL — ждём завершения туториала =====
    setPhase("WAIT_TUTORIAL")
    local waited = 0
    while State.running and waited < CONFIG.MIN_WAIT_BEFORE_START do
        updateStatus(string.format("Ожидание %d/%d сек перед стартом...", waited, CONFIG.MIN_WAIT_BEFORE_START))
        task.wait(1)
        waited = waited + 1
    end

    -- Дополнительно ждём пока активен туториал (до 60 сек максимум)
    local tutorialWait = 0
    while State.running and isTutorialActive() and tutorialWait < 60 do
        updateStatus(string.format("Жду завершения туториала... %d сек", tutorialWait))
        task.wait(1)
        tutorialWait = tutorialWait + 1
    end

    -- ===== ОСНОВНОЙ ЦИКЛ =====
    while State.running do
        local root = getRoot()
        if not root then
            updateStatus("Жду персонажа...")
            task.wait(1)
        else
            local night = isNight()

            if State.pureSkipMode then
                -- ===== PURE SKIP — все боссы убиты =====
                setPhase("PURE_SKIP")
                local now = tick()
                if now - State.lastSkipCheck > CONFIG.SKIP_CHECK_INTERVAL then
                    State.lastSkipCheck = now
                    trySkipNight()
                end
                updateStatus("Все боссы убиты!\nТолько скипаем ночи.")
                task.wait(1)
            elseif night == false then
                -- ===== ДЕНЬ — ничего не делаем, ждём ночь =====
                setPhase("DAY")
                -- Попытаться скипнуть день
                local now = tick()
                if now - State.lastSkipCheck > CONFIG.SKIP_CHECK_INTERVAL then
                    State.lastSkipCheck = now
                    -- Кликнуть кнопку скипа если есть
                    local btn = findSkipButton()
                    if btn then
                        pcall(function()
                            if firesignal then firesignal(btn.MouseButton1Click) end
                        end)
                    end
                    trySkipNight()
                end
                updateStatus("День. Жду ночь...\n(God mode + Noclip активны)")
                task.wait(2)
            else
                -- ===== НОЧЬ (или неизвестно — treat as night) =====
                setPhase("NIGHT")
                local enemies = getAllEnemies()

                if #enemies == 0 then
                    -- Врагов нет — попытаться скипнуть
                    setPhase("SKIP")
                    local now = tick()
                    if now - State.lastSkipCheck > CONFIG.SKIP_CHECK_INTERVAL then
                        State.lastSkipCheck = now
                        trySkipNight()
                    end
                    updateStatus("Врагов нет. Скип к след. ночи...")
                    task.wait(1)
                else
                    -- Атакуем ближайшего/босса — БЕЗ ПРИБЛИЖЕНИЯ
                    local target = enemies[1]

                    -- Если враг умер — отметить
                    if target.humanoid.Health <= 0 then
                        if target.isBoss and target.bossKey then
                            if not State.killedBosses[target.bossKey] then
                                State.killedBosses[target.bossKey] = true
                                State.stats.bossesKilled = State.stats.bossesKilled + 1
                                log("★★ БОСС УБИТ: " .. target.model.Name .. " (key=" .. target.bossKey .. ")")
                                if CONFIG.PURE_SKIP_AFTER_ALL_BOSSES and allBossesKilled() then
                                    State.pureSkipMode = true
                                    log("★★★ ВСЕ БОССЫ УБИТЫ — переход в PURE-SKIP")
                                end
                            end
                        else
                            State.stats.zombiesKilled = State.stats.zombiesKilled + 1
                        end
                    else
                        -- Атакуем
                        attackEnemy(target)
                        updateStatus(string.format(
                            "НОЧЬ: бой\nЦель: %s%s\nHP: %d/%d | Дист: %d",
                            target.model.Name,
                            target.isBoss and " [BOSS]" or "",
                            math.floor(target.humanoid.Health),
                            math.floor(target.humanoid.MaxHealth),
                            math.floor(target.distance)
                        ))
                    end
                    task.wait(CONFIG.LOOP_DELAY)
                end
            end
        end
    end
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================
local function init()
    log("=== BAKE OR DIE AUTO-FARM v2.0 ===")
    log("БЕЗОПАСНЫЙ РЕЖИМ: GOD MODE + NOCLIP")
    log("Сканирую игру...")

    createUI()

    -- Найти папку врагов
    State.enemyFolder = findEnemyFolder()

    -- Найти RemoteEvents
    local allRemotes = {}
    scanForRemotes(ReplicatedStorage, 0, allRemotes, 8)
    scanForRemotes(Workspace, 0, allRemotes, 3)
    log("Найдено RemoteEvent/Function: " .. #allRemotes)
    classifyRemotes(allRemotes)

    -- Состояние день/ночь
    State.nightStateValue = findNightStateValue()

    log("Attack remotes: " .. #State.attackRemotes)
    log("Skip remotes: " .. #State.skipRemotes)
    log("Night state value: " .. (State.nightStateValue and "найден" or "не найден"))
    log("God mode: " .. (CONFIG.GOD_MODE and "ON" or "OFF"))
    log("Noclip: " .. (CONFIG.NOCLIP and "ON" or "OFF"))
    log("Запуск основного цикла...")

    mainLoop()
end

-- ============================================
-- ЗАПУСК
-- ============================================
local ok, err = pcall(init)
if not ok then
    warnLog("FATAL: " .. tostring(err))
end

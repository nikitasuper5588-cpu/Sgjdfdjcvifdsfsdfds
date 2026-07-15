-- ============================================
-- BAKE OR DIE  ::  AFK AUTO-FARM (NIGHTS + BOSSES + SKIP)
-- Версия: 1.0
-- Полностью автономный: kill zombies → kill boss → skip night → repeat
-- После убийства всех известных боссов — переходит в режим pure-skip
-- ============================================
--
-- КАК ЭТО РАБОТАЕТ:
--   1. На старте скрипт СКАНИРУЕТ workspace/ReplicatedStorage
--      и находит папку с врагами, RemoteEvents атаки/скипа ночи.
--   2. Каждую ночь: бежит к ближайшему зомби, бьёт его (tool activate
--      + RemoteEvent damage), собирает трупы в Shredder.
--   3. Отслеживает убитых боссов по имени.
--   4. Когда все известные боссы убиты → переключается в режим
--      PURE-SKIP: сразу скипает ночь за ночью.
--   5. Анти-AFK + авто-поднятие персонажа при застревании.
--
-- ВЫЗОВ: просто запусти этот скрипт в executor'е.
-- Горячие клавиши:
--   RightShift — вкл/выкл UI
--   F6         — экстренная остановка
-- ============================================

-- ============================================
-- КОНФИГ
-- ============================================
local CONFIG = {
    -- Известные имена боссов (по lower-case подстроке).
    -- Когда ВСЕ из этого списка будут убиты — переключаемся в pure-skip.
    KNOWN_BOSSES = {
        "cake",       -- Cake Boss / Apple Cake Boss
        "chicken",    -- Chicken Boss
        "biggie",     -- Biggie Cheese Boss
        "doomberry",  -- Doomberry (финальный)
    },

    -- Порог HP, выше которого враг считается боссом (авто-детекция).
    BOSS_HP_THRESHOLD = 1000,

    -- Радиус поиска врагов вокруг игрока
    COMBAT_RADIUS = 250,

    -- Радиус "близко" — если враг ближе, бить вместо перемещения
    ATTACK_RANGE = 12,

    -- Скорость перемещения к врагу (BodyVelocity)
    TRAVEL_SPEED = 80,

    -- Частота основного цикла
    LOOP_DELAY = 0.2,

    -- Задержка между атаками (для tool cooldown)
    ATTACK_COOLDOWN = 0.15,

    -- Авто-подбирание трупов? (true = относить в Shredder)
    AUTO_SHRED = true,
    SHREDDER_SEARCH_NAMES = { "Shredder", "shredder", "Grinder", "Disposal" },
    SHREDDER_RANGE = 8,

    -- Анти-AFK
    ANTI_AFK = true,

    -- Включить отладочные логи в консоли executor'а
    DEBUG = true,
}

-- ============================================
-- СЕРВИСЫ
-- ============================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local VirtualUser        = game:GetService("VirtualUser")
local TweenService       = game:GetService("TweenService")

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
    pureSkipMode     = false,        -- true = все боссы убиты, только скипаем
    killedBosses     = {},           -- [bossNameLower] = true
    enemyFolder      = nil,          -- обнаруженная папка с врагами
    attackRemotes    = {},           -- список RemoteEvent для атаки
    skipRemotes      = {},           -- список RemoteEvent для скипа ночи
    nightStateValue  = nil,          -- ObjectValue/IntValue: день/ночь
    equippedTool     = nil,
    lastAttack       = 0,
    shredderPart     = nil,
    ui               = nil,
    statusText       = nil,
}

-- ============================================
-- HELPER: найти root персонажа
-- ============================================
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ============================================
-- DETECTION: рекурсивный поиск RemoteEvents / RemoteFunctions
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
-- DETECTION: найти папку с врагами в Workspace
-- ============================================
local function findEnemyFolder()
    -- Список возможных имён папок с врагами
    local candidates = {
        "Enemies", "Zombies", "Mobs", "NPCs", "Monster", "Monsters",
        "Hostiles", "Ai", "AI", "Units", "Creatures", "Spawns", "Spawned",
    }
    -- 1) По имени в workspace
    for _, name in ipairs(candidates) do
        local f = Workspace:FindFirstChild(name, true)
        if f then
            -- Проверим, что внутри есть Humanoid'ы
            for _, desc in ipairs(f:GetDescendants()) do
                if desc:IsA("Humanoid") then
                    log("Найдена папка врагов: " .. f:GetFullName())
                    return f
                end
            end
        end
    end
    -- 2) Альтернатива: ищем Model в Workspace, у которых есть Humanoid и имя не как у игрока
    log("Прямая папка не найдена — буду искать врагов прямо в Workspace")
    return Workspace
end

-- ============================================
-- DETECTION: классифицировать RemoteEvents по имени
-- ============================================
local function classifyRemotes(remotes)
    local attackNames = {
        "attack", "fire", "shoot", "damage", "hit", "swing", "weapon",
        "punch", "stab", "slash", "shootgun", "fireweapon", "useitem",
    }
    local skipNames = {
        "skipnight", "skipday", "votenight", "voteskip", "startnight",
        "skip", "fastnight", "endnight", "skipdaynight",
    }
    for _, r in ipairs(remotes) do
        local name = string.lower(r.Name)
        -- Attack?
        for _, key in ipairs(attackNames) do
            if string.find(name, key, 1, true) then
                table.insert(State.attackRemotes, r)
                log("  Attack remote: " .. r:GetFullName())
                break
            end
        end
        -- Skip?
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
-- DETECTION: найти значение состояния день/ночь
-- ============================================
local function findNightStateValue()
    -- Ищем IntValue/BoolValue/StringValue с именами типа "IsNight", "Night", "Phase"
    local candidates = { "IsNight", "Night", "Phase", "GamePhase", "TimeOfDay",
                         "DayNight", "IsDay", "CurrentWave", "Wave" }
    for _, name in ipairs(candidates) do
        local v = ReplicatedStorage:FindFirstChild(name, true)
        if v and v:IsA("ValueBase") then
            log("Найдено состояние: " .. v:GetFullName() .. " = " .. tostring(v.Value))
            return v
        end
        v = Workspace:FindFirstChild(name, true)
        if v and v:IsA("ValueBase") then
            log("Найдено состояние (ws): " .. v:GetFullName() .. " = " .. tostring(v.Value))
            return v
        end
    end
    return nil
end

-- ============================================
-- DETECTION: найти Shredder
-- ============================================
local function findShredder()
    for _, name in ipairs(CONFIG.SHREDDER_SEARCH_NAMES) do
        local obj = Workspace:FindFirstChild(name, true)
        if obj and obj:IsA("Model") then
            -- Найти BasePart внутри
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                log("Найден Shredder: " .. obj:GetFullName())
                return part
            end
        elseif obj and obj:IsA("BasePart") then
            log("Найден Shredder (part): " .. obj:GetFullName())
            return obj
        end
    end
    return nil
end

-- ============================================
-- СТАТУС ВРАГА: получить Humanoid и Root из model
-- ============================================
local function getEnemyData(model)
    if not model or not model.Parent then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
    if not root then return nil end
    return { model = model, humanoid = hum, root = root }
end

-- ============================================
-- ПРОВЕРКА: является ли враг боссом
-- ============================================
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

-- ============================================
-- ПОЛУЧИТЬ СПИСОК ВСЕХ ЖИВЫХ ВРАГОВ
-- ============================================
local function getAllEnemies()
    local enemies = {}
    local root = getRoot()
    if not root then return enemies end

    local function checkModel(model)
        local data = getEnemyData(model)
        if not data then return end
        -- Исключить самого игрока
        if model == LocalPlayer.Character then return end
        -- Проверить дистанцию
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
        -- Сканируем workspace
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") and child ~= LocalPlayer.Character then
                -- Проверяем что у model есть Humanoid
                if child:FindFirstChildOfClass("Humanoid") then
                    checkModel(child)
                end
            end
        end
    end

    -- Сортировка: боссы приоритетнее, затем ближайшие
    table.sort(enemies, function(a, b)
        if a.isBoss and not b.isBoss then return true end
        if not a.isBoss and b.isBoss then return false end
        return a.distance < b.distance
    end)
    return enemies
end

-- ============================================
-- ПЕРЕМЕЩЕНИЕ к цели (через CFrame для простоты и скорости)
-- ============================================
local function travelTo(targetPos)
    local root = getRoot()
    local hum = getHumanoid()
    if not root or not hum then return end

    local dist = (targetPos - root.Position).Magnitude
    if dist <= CONFIG.ATTACK_RANGE then return true end

    -- BodyVelocity для плавного перемещения
    local bv = root:FindFirstChild("__travel_bv")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "__travel_bv"
        bv.MaxForce = Vector3.new(1, 0, 1) * 1e5
        bv.Velocity = Vector3.zero
        bv.Parent = root
    end
    local dir = (targetPos - root.Position)
    dir = Vector3.new(dir.X, 0, dir.Z)  -- только горизонталь
    if dir.Magnitude > 0.1 then
        bv.Velocity = dir.Unit * CONFIG.TRAVEL_SPEED
    end
    return false
end

local function stopTravel()
    local root = getRoot()
    if not root then return end
    local bv = root:FindFirstChild("__travel_bv")
    if bv then bv:Destroy() end
end

-- ============================================
-- ТЕЛЕПОРТ (мгновенный) - fallback если travel не работает
-- ============================================
local function teleportTo(pos)
    local root = getRoot()
    if not root then return end
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

-- ============================================
-- АТАКА: все доступные методы
-- ============================================
local function attackEnemy(enemy)
    local root = getRoot()
    if not root then return end
    local now = tick()
    if now - State.lastAttack < CONFIG.ATTACK_COOLDOWN then return end
    State.lastAttack = now

    -- 1. Активировать текущий tool (если есть)
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            -- Подойти вплотную
            local targetPos = enemy.root.Position
            local dir = (targetPos - root.Position)
            if dir.Magnitude > 0 then
                root.CFrame = CFrame.new(targetPos + dir.Unit * 4, targetPos)
            end
        end
    end

    -- 2. Fire attack remotes
    for _, r in ipairs(State.attackRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(enemy.model)
                r:FireServer(enemy.root)
                r:FireServer(enemy.humanoid)
            elseif r:IsA("RemoteFunction") then
                pcall(function() r:InvokeServer(enemy.model) end)
                pcall(function() r:InvokeServer(enemy.root) end)
            end
        end)
    end

    -- 3. Прямая попытка убить (работает в некоторых executor'ах через __namecall)
    pcall(function()
        if enemy.humanoid and enemy.humanoid.Health > 0 then
            enemy.humanoid.Health = 0
        end
    end)

    -- 4. Touch с handle инструмента (для melee)
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle and enemy.root then
                pcall(function()
                    firetouchinterest(handle, enemy.root, 0)
                    firetouchinterest(handle, enemy.root, 1)
                end)
            end
        end
    end
end

-- ============================================
-- СКИП НОЧИ / СКИП ДНЯ
-- ============================================
local function trySkipNight()
    if #State.skipRemotes == 0 then return false end
    for _, r in ipairs(State.skipRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer()
            elseif r:IsA("RemoteFunction") then
                pcall(function() r:InvokeServer() end)
            end
        end)
    end
    log("Skip-night вызван (" .. #State.skipRemotes .. " remotes)")
    return true
end

-- ============================================
-- ПОИСК КНОПКИ SKIP в PlayerGui
-- ============================================
local function findSkipButton()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    local name = string.lower(desc.Name)
                    local text = desc.Text and string.lower(desc.Text) or ""
                    if string.find(name, "skip", 1, true)
                       or string.find(text, "skip", 1, true)
                       or string.find(text, "vote", 1, true)
                       or string.find(text, "next", 1, true)
                       or string.find(name, "vote", 1, true)
                       or string.find(name, "next", 1, true) then
                        if desc.Visible ~= false and desc.Active ~= false then
                            return desc
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ============================================
-- ПРОВЕРКА: все ли боссы убиты?
-- ============================================
local function allBossesKilled()
    for _, key in ipairs(CONFIG.KNOWN_BOSSES) do
        if not State.killedBosses[key] then
            return false
        end
    end
    return true
end

-- ============================================
-- UI: простая понель статуса
-- ============================================
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BodAutoFarm"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 140)
    frame.Position = UDim2.new(1, -300, 0, 20)
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
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "BAKE OR DIE :: AFK FARM"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    State.statusText = Instance.new("TextLabel")
    State.statusText.Size = UDim2.new(1, -20, 0, 90)
    State.statusText.Position = UDim2.new(0, 10, 0, 32)
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

local function updateStatus(text)
    if State.statusText then
        State.statusText.Text = text
    end
    log(text)
end

-- ============================================
-- ПОДГОТОВКА ПЕРСОНАЖА
-- ============================================
local function setupCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    -- Увеличить WalkSpeed на всякий случай
    hum.WalkSpeed = math.max(hum.WalkSpeed, 32)
    -- Auto-equip первый tool из Backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            hum:EquipTool(tool)
            log("Экипирован инструмент: " .. tool.Name)
        end
    end
end

-- ============================================
-- ANTI-AFK
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
-- ОСНОВНОЙ ЦИКЛ
-- ============================================
local function mainLoop()
    while State.running do
        local root = getRoot()
        if root then
            if State.pureSkipMode then
                -- РЕЖИМ PURE SKIP
                local skipBtn = findSkipButton()
                if skipBtn then
                    pcall(function()
                        skipBtn.MouseButton1Click:Fire()
                        -- Альтернатива: использовать firesignal
                        if firesignal then firesignal(skipBtn.MouseButton1Click) end
                    end)
                end
                trySkipNight()
                updateStatus("РЕЖИМ PURE-SKIP\nВсе боссы убиты!\nСкипаем ночи...")
                task.wait(2)
            else
                -- РЕЖИМ ФАРМА
                local enemies = getAllEnemies()
                if #enemies == 0 then
                    -- Врагов нет — попытаться скипнуть ночь/дождаться ночи
                    local skipBtn = findSkipButton()
                    if skipBtn then
                        pcall(function()
                            if firesignal then firesignal(skipBtn.MouseButton1Click) end
                        end)
                    end
                    trySkipNight()
                    stopTravel()
                    local killedList = ""
                    for k, _ in pairs(State.killedBosses) do
                        killedList = killedList .. k .. ", "
                    end
                    updateStatus("Ожидание врагов...\nУбито боссов: " .. killedList)
                    task.wait(1)
                else
                    -- Ближайший враг (приоритет босс)
                    local target = enemies[1]
                    local dist = target.distance

                    -- Запомнить босса
                    if target.isBoss and target.bossKey then
                        -- Бьём до смерти, потом отметим
                    end

                    if dist <= CONFIG.ATTACK_RANGE then
                        stopTravel()
                        attackEnemy(target)
                        updateStatus(string.format(
                            "АТАКА: %s%s\nHP: %d/%d\nДист: %d",
                            target.model.Name,
                            target.isBoss and " [BOSS]" or "",
                            math.floor(target.humanoid.Health),
                            math.floor(target.humanoid.MaxHealth),
                            math.floor(dist)
                        ))
                    else
                        travelTo(target.root.Position)
                        updateStatus(string.format(
                            "Иду к: %s%s\nДист: %d",
                            target.model.Name,
                            target.isBoss and " [BOSS]" or "",
                            math.floor(dist)
                        ))
                    end

                    -- Проверка — если враг умер, отметить босса
                    if target.humanoid.Health <= 0 and target.isBoss and target.bossKey then
                        if not State.killedBosses[target.bossKey] then
                            State.killedBosses[target.bossKey] = true
                            log("★ БОСС УБИТ: " .. target.model.Name .. " (key=" .. target.bossKey .. ")")
                            -- Проверить, все ли убиты
                            if allBossesKilled() then
                                State.pureSkipMode = true
                                log("★ ВСЕ БОССЫ УБИТЫ — переключение в PURE-SKIP режим")
                            end
                        end
                    end

                    task.wait(CONFIG.LOOP_DELAY)
                end
            end
        else
            updateStatus("Жду персонажа...")
            task.wait(1)
        end
    end
end

-- ============================================
-- ВВОД: горячие клавиши
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
            stopTravel()
            if State.ui then State.ui:Destroy() end
            warnLog("Скрипт остановлен пользователем (F6)")
        end
    end)
end

-- ============================================
-- АВТО-ЭКИПИРОВКА ПРИ ПОДНЯТИИ ОРУЖИЯ
-- ============================================
local function setupAutoEquip()
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        setupCharacter()
    end)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.3)
                local hum = getHumanoid()
                local equipped = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if hum and not equipped then
                    hum:EquipTool(child)
                end
            end
        end)
    end
end

-- ============================================
-- ПЕРИОДИЧЕСКОЕ ОБНОВЛЕНИЕ ССЫЛОК (раз в 30с)
-- ============================================
local function setupRescanLoop()
    task.spawn(function()
        while State.running do
            task.wait(30)
            -- Обновить shredder
            if not State.shredderPart or not State.shredderPart.Parent then
                State.shredderPart = findShredder()
            end
            -- Обновить night state value
            if not State.nightStateValue or not State.nightStateValue.Parent then
                State.nightStateValue = findNightStateValue()
            end
        end
    end)
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================
local function init()
    log("=== BAKE OR DIE AUTO-FARM v1.0 ===")
    log("Сканирую игру...")

    -- 1. UI
    createUI()

    -- 2. Найти папку врагов
    State.enemyFolder = findEnemyFolder()

    -- 3. Найти все RemoteEvents
    local allRemotes = {}
    scanForRemotes(ReplicatedStorage, 0, allRemotes, 8)
    scanForRemotes(Workspace, 0, allRemotes, 3)
    log("Найдено RemoteEvent/Function: " .. #allRemotes)
    classifyRemotes(allRemotes)

    -- 4. Найти состояние ночь/день
    State.nightStateValue = findNightStateValue()

    -- 5. Найти Shredder
    State.shredderPart = findShredder()

    -- 6. Настроить персонажа
    setupCharacter()

    -- 7. Anti-AFK
    setupAntiAfk()

    -- 8. Auto-equip
    setupAutoEquip()

    -- 9. Rescan loop
    setupRescanLoop()

    -- 10. Input
    setupInput()

    -- 11. Отчёт
    local bossList = table.concat(CONFIG.KNOWN_BOSSES, ", ")
    log("Известные боссы: " .. bossList)
    log("Attack remotes: " .. #State.attackRemotes)
    log("Skip remotes: " .. #State.skipRemotes)
    log("Shredder: " .. (State.shredderPart and "найден" or "не найден"))
    log("Night state: " .. (State.nightStateValue and "найден" or "не найден"))
    log("Запуск основного цикла...")

    -- 12. Старт
    mainLoop()
end

-- ============================================
-- ЗАПУСК
-- ============================================
local ok, err = pcall(init)
if not ok then
    warnLog("FATAL: " .. tostring(err))
end

-- ============================================
-- OBSIDIAN BLACK - ULTIMATE DARK EDITION
-- Создатель: @execute_hub
-- Ключ: z
-- Версия: 22.0 (FULL BLACK + NEW FUNCTIONS)
-- ============================================

local correctKey = "z"
local keyAttempts = 0

-- ============================================
-- ОКНО КЛЮЧА (ЧЕРНЫЙ)
-- ============================================
local function CreateKeyWindow()
    local gui = Instance.new("ScreenGui")
    gui.Parent = game:GetService("CoreGui")
    gui.Name = "ObsidianKey"
    gui.ResetOnSpawn = false
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.95
    bg.Parent = gui
    
    -- ЗВЕЗДЫ (ЕДИНСТВЕННЫЙ СВЕТ)
    for i = 1, 60 do
        local star = Instance.new("Frame")
        local size = 1 + math.random() * 2
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(), 0, math.random(), 0)
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.BackgroundTransparency = 0.2 + math.random() * 0.5
        star.BorderSizePixel = 0
        star.Parent = bg
        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, size/2)
        sc.Parent = star
    end
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 400, 0, 420)
    main.Position = UDim2.new(0.5, -200, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 2
    main.BorderColor3 = Color3.fromRGB(180, 60, 255)
    main.ClipsDescendants = true
    main.Parent = bg
    
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 20)
    mc.Parent = main
    
    -- НЕОНОВАЯ ОБВОДКА
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel = 2
    glow.BorderColor3 = Color3.fromRGB(180, 60, 255)
    glow.Parent = main
    local gbc = Instance.new("UICorner")
    gbc.CornerRadius = UDim.new(0, 20)
    gbc.Parent = glow
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = main
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 20)
    hc.Parent = header
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0.4, 0, 1, 0)
    logo.Position = UDim2.new(0.05, 0, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "OBSIDIAN"
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.TextScaled = true
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0.3, 0, 0.35, 0)
    sub.Position = UDim2.new(0.5, 0, 0.65, 0)
    sub.BackgroundTransparency = 1
    sub.Text = "BLACK v22"
    sub.TextColor3 = Color3.fromRGB(200, 150, 255)
    sub.TextScaled = true
    sub.Font = Enum.Font.Gotham
    sub.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = "ВВЕДИТЕ КЛЮЧ"
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = main
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.6, 0, 0, 45)
    input.Position = UDim2.new(0.2, 0, 0, 110)
    input.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    input.BorderSizePixel = 2
    input.BorderColor3 = Color3.fromRGB(180, 60, 255)
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextScaled = true
    input.Font = Enum.Font.GothamBold
    input.PlaceholderText = "Ключ..."
    input.PlaceholderColor3 = Color3.fromRGB(150, 120, 200)
    input.Parent = main
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 12)
    ic.Parent = input
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, 0, 0, 45)
    btn.Position = UDim2.new(0.325, 0, 0, 180)
    btn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
    btn.BackgroundTransparency = 0.15
    btn.Text = "АКТИВИРОВАТЬ"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 2
    btn.BorderColor3 = Color3.fromRGB(180, 60, 255)
    btn.Parent = main
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 12)
    bc.Parent = btn
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 25)
    status.Position = UDim2.new(0, 0, 0, 250)
    status.BackgroundTransparency = 1
    status.Text = "Введите ключ для активации"
    status.TextColor3 = Color3.fromRGB(200, 200, 230)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.Parent = main
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.4, 0, 0, 1)
    line.Position = UDim2.new(0.3, 0, 0, 295)
    line.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
    line.BackgroundTransparency = 0.3
    line.Parent = main
    
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 25)
    footer.Position = UDim2.new(0, 0, 0, 315)
    footer.BackgroundTransparency = 1
    footer.Text = "@execute_hub"
    footer.TextColor3 = Color3.fromRGB(180, 60, 255)
    footer.TextScaled = true
    footer.Font = Enum.Font.Gotham
    footer.Parent = main
    
    input:CaptureFocus()
    
    local function CheckKey()
        local enteredKey = string.lower(input.Text)
        if enteredKey == correctKey then
            status.Text = "КЛЮЧ ПРИНЯТ! ЗАПУСК..."
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
            btn.BorderColor3 = Color3.fromRGB(0, 200, 80)
            input.BorderColor3 = Color3.fromRGB(0, 200, 80)
            task.wait(0.8)
            gui:Destroy()
            StartObsidianBlack()
        else
            keyAttempts = keyAttempts + 1
            status.Text = "НЕВЕРНЫЙ КЛЮЧ! " .. keyAttempts .. "/5"
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
            btn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            btn.BorderColor3 = Color3.fromRGB(200, 30, 30)
            input.BorderColor3 = Color3.fromRGB(200, 30, 30)
            
            if keyAttempts >= 5 then
                status.Text = "ДОСТУП ЗАБЛОКИРОВАН!"
                status.TextColor3 = Color3.fromRGB(255, 0, 0)
                btn.Visible = false
                input.Visible = false
                task.wait(2)
                gui:Destroy()
            end
            
            task.wait(0.5)
            input.Text = ""
            input:CaptureFocus()
            status.Text = "Введите ключ для активации"
            status.TextColor3 = Color3.fromRGB(200, 200, 230)
            btn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
            btn.BorderColor3 = Color3.fromRGB(180, 60, 255)
            input.BorderColor3 = Color3.fromRGB(180, 60, 255)
        end
    end
    
    btn.MouseButton1Click:Connect(CheckKey)
    input.FocusLost:Connect(function(enter) if enter then CheckKey() end end)
    
    return gui
end

-- ============================================
-- ОСНОВНОЙ СКРИПТ (ЧЕРНЫЙ ИНТЕРФЕЙС + НОВЫЕ ФУНКЦИИ)
-- ============================================
function StartObsidianBlack()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local TweenService = game:GetService("TweenService")
    local lp = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    -- ============================================
    -- НАСТРОЙКИ (50+ ФУНКЦИЙ)
    -- ============================================
    local settings = {
        -- AIM (10)
        aimOn = true,
        silentOn = false,
        wallOn = false,
        aimLock = false,
        radius = 200,
        smooth = 0.12,
        fov = 180,
        aimPart = "Head",
        prediction = true,
        visibleCheck = true,
        
        -- FIRE (8)
        fireOn = false,
        fireRate = 0.1,
        triggerBot = false,
        burstFire = false,
        burstCount = 3,
        killAuraOn = false,
        killAuraRange = 20,
        antiAfk = false,
        
        -- ESP (10)
        espOn = true,
        espType = "Highlight",
        espColor = "Violet",
        showHealth = true,
        showName = true,
        showDistance = true,
        glowOn = false,
        tracer = false,
        skeleton = false,
        boxFilled = false,
        
        -- MOVEMENT (15)
        flyOn = false,
        noclipOn = false,
        speed = 16,
        jump = 50,
        flySpeed = 1,
        bhop = false,
        infiniteJump = false,
        autoSprint = false,
        antiStun = false,
        noFall = false,
        waterWalk = false,
        spiderMan = false,
        airJump = false,
        moonJump = false,
        moonJumpPower = 200,
        slideOn = false,
        slideSpeed = 30,
        dashOn = false,
        dashDistance = 30,
        teleportOn = false,
        teleportDistance = 50,
        
        -- VISUAL (8)
        crosshairOn = true,
        crosshairColor = "Violet",
        crosshairStyle = "Dot",
        fovChanger = false,
        fovValue = 70,
        brightness = false,
        brightnessValue = 1.5,
        fogOn = false,
        bloom = false,
        
        -- NEW FUNCTIONS (10)
        autoCollectOn = false,
        autoCollectRange = 30,
        autoCollectDelay = 0.5,
        speedHackOn = false,
        speedHackMultiplier = 2,
        jumpHackOn = false,
        jumpHackMultiplier = 2,
        noClipFlyOn = false,
        noClipFlySpeed = 10,
        godModeOn = false,
        godModeHealth = 100,
        invisOn = false,
        invisOpacity = 0.3,
        autoFarmOn = false,
        autoFarmDelay = 1,
        autoFarmRange = 50,
        autoClickOn = false,
        autoClickDelay = 0.1,
        autoClickRange = 20,
    }

    -- ============================================
    -- ПЕРЕМЕННЫЕ
    -- ============================================
    local target = nil
    local lastShot = 0
    local flyBody = nil
    local espFolder = Instance.new("Folder")
    local crosshair = nil
    local aimLockTarget = nil
    local jumpCount = 0
    local bloomEffect = nil
    local uiSize = 1
    local dashCooldown = 0
    local lastTeleport = 0
    local particles = {}

    -- ============================================
    -- ПОЛНОСТЬЮ ЧЕРНЫЙ UI (ВСЕ ЭЛЕМЕНТЫ ЧЕРНЫЕ)
    -- ============================================
    local function CreateObsidianUI()
        local gui = Instance.new("ScreenGui")
        gui.Parent = lp:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        gui.ResetOnSpawn = false
        gui.Name = "ObsidianBlack"
        
        -- ОСНОВНОЕ ОКНО (ЧЕРНЫЙ ФОН)
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 480, 0, 640)
        main.Position = UDim2.new(0.5, -240, 0.02, 0)
        main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        main.BackgroundTransparency = 0.05
        main.BorderSizePixel = 2
        main.BorderColor3 = Color3.fromRGB(180, 60, 255)
        main.ClipsDescendants = true
        main.Parent = gui
        
        local mc = Instance.new("UICorner")
        mc.CornerRadius = UDim.new(0, 25)
        mc.Parent = main
        
        -- ТЕНЬ (ЧЕРНАЯ)
        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(1, 30, 1, 30)
        shadow.Position = UDim2.new(0, -15, 0, -15)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.98
        shadow.BorderSizePixel = 0
        shadow.Parent = main
        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, 25)
        sc.Parent = shadow
        
        -- НЕОНОВАЯ ОБВОДКА
        local glow = Instance.new("Frame")
        glow.Size = UDim2.new(1, 0, 1, 0)
        glow.BackgroundTransparency = 1
        glow.BorderSizePixel = 2
        glow.BorderColor3 = Color3.fromRGB(180, 60, 255)
        glow.Parent = main
        local gbc = Instance.new("UICorner")
        gbc.CornerRadius = UDim.new(0, 25)
        gbc.Parent = glow
        
        -- УГЛЫ (НЕОНОВЫЕ)
        for _, data in ipairs({{0,0,0},{1,0,90},{0,1,-90},{1,1,180}}) do
            local corner = Instance.new("Frame")
            corner.Size = UDim2.new(0, 35, 0, 35)
            corner.Position = UDim2.new(data[1], -3, data[2], -3)
            corner.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
            corner.BackgroundTransparency = 0.2
            corner.BorderSizePixel = 0
            corner.Rotation = data[3]
            corner.Parent = main
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = corner
        end
        
        -- ВЕРХНИЙ БАННЕР (ЧЕРНЫЙ С ФИОЛЕТОВЫМ)
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 65)
        header.BackgroundColor3 = Color3.fromRGB(5, 0, 15)
        header.BackgroundTransparency = 0.1
        header.BorderSizePixel = 0
        header.Parent = main
        local hc = Instance.new("UICorner")
        hc.CornerRadius = UDim.new(0, 25)
        hc.Parent = header
        
        local logo = Instance.new("TextLabel")
        logo.Size = UDim2.new(0.35, 0, 1, 0)
        logo.Position = UDim2.new(0.05, 0, 0, 0)
        logo.BackgroundTransparency = 1
        logo.Text = "OBSIDIAN"
        logo.TextColor3 = Color3.fromRGB(255, 255, 255)
        logo.TextScaled = true
        logo.Font = Enum.Font.GothamBold
        logo.TextXAlignment = Enum.TextXAlignment.Left
        logo.Parent = header
        
        local version = Instance.new("TextLabel")
        version.Size = UDim2.new(0.25, 0, 0.35, 0)
        version.Position = UDim2.new(0.4, 0, 0.65, 0)
        version.BackgroundTransparency = 1
        version.Text = "BLACK v22"
        version.TextColor3 = Color3.fromRGB(200, 150, 255)
        version.TextScaled = true
        version.Font = Enum.Font.Gotham
        version.Parent = header
        
        -- КНОПКИ (ЧЕРНЫЕ)
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0.06, 0, 0.5, 0)
        closeBtn.Position = UDim2.new(0.88, 0, 0.25, 0)
        closeBtn.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
        closeBtn.BackgroundTransparency = 0.15
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextScaled = true
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = header
        local cb = Instance.new("UICorner")
        cb.CornerRadius = UDim.new(0, 8)
        cb.Parent = closeBtn
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0.06, 0, 0.5, 0)
        toggleBtn.Position = UDim2.new(0.8, 0, 0.25, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
        toggleBtn.BackgroundTransparency = 0.15
        toggleBtn.Text = "−"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextScaled = true
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Parent = header
        local tb = Instance.new("UICorner")
        tb.CornerRadius = UDim.new(0, 8)
        tb.Parent = toggleBtn
        
        -- РАЗМЕР (ЧЕРНЫЙ)
        local sizeFrame = Instance.new("Frame")
        sizeFrame.Size = UDim2.new(0.18, 0, 0, 28)
        sizeFrame.Position = UDim2.new(0.76, 0, 0.02, 0)
        sizeFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        sizeFrame.BackgroundTransparency = 0.1
        sizeFrame.BorderSizePixel = 1
        sizeFrame.BorderColor3 = Color3.fromRGB(180, 60, 255)
        sizeFrame.Parent = main
        local sf = Instance.new("UICorner")
        sf.CornerRadius = UDim.new(0, 8)
        sf.Parent = sizeFrame
        
        local sizeLabel = Instance.new("TextLabel")
        sizeLabel.Size = UDim2.new(0.3, 0, 1, 0)
        sizeLabel.Position = UDim2.new(0.35, 0, 0, 0)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.Text = "100%"
        sizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        sizeLabel.TextScaled = true
        sizeLabel.Font = Enum.Font.GothamBold
        sizeLabel.Parent = sizeFrame
        
        local minusBtn = Instance.new("TextButton")
        minusBtn.Size = UDim2.new(0.3, 0, 1, 0)
        minusBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        minusBtn.BackgroundTransparency = 0.2
        minusBtn.Text = "−"
        minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minusBtn.TextScaled = true
        minusBtn.Font = Enum.Font.GothamBold
        minusBtn.BorderSizePixel = 0
        minusBtn.Parent = sizeFrame
        local mb = Instance.new("UICorner")
        mb.CornerRadius = UDim.new(0, 6)
        mb.Parent = minusBtn
        
        local plusBtn = Instance.new("TextButton")
        plusBtn.Size = UDim2.new(0.3, 0, 1, 0)
        plusBtn.Position = UDim2.new(0.7, 0, 0, 0)
        plusBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        plusBtn.BackgroundTransparency = 0.2
        plusBtn.Text = "+"
        plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        plusBtn.TextScaled = true
        plusBtn.Font = Enum.Font.GothamBold
        plusBtn.BorderSizePixel = 0
        plusBtn.Parent = sizeFrame
        local pb = Instance.new("UICorner")
        pb.CornerRadius = UDim.new(0, 6)
        pb.Parent = plusBtn
        
        minusBtn.MouseButton1Click:Connect(function()
            uiSize = math.max(0.7, uiSize - 0.05)
            main.Size = UDim2.new(0, 480 * uiSize, 0, 640 * uiSize)
            main.Position = UDim2.new(0.5, -240 * uiSize, 0.02, 0)
            sizeLabel.Text = math.floor(uiSize * 100) .. "%"
        end)
        
        plusBtn.MouseButton1Click:Connect(function()
            uiSize = math.min(1.5, uiSize + 0.05)
            main.Size = UDim2.new(0, 480 * uiSize, 0, 640 * uiSize)
            main.Position = UDim2.new(0.5, -240 * uiSize, 0.02, 0)
            sizeLabel.Text = math.floor(uiSize * 100) .. "%"
        end)
        
        -- ВКЛАДКИ (ЧЕРНЫЕ)
        local tabs = Instance.new("Frame")
        tabs.Size = UDim2.new(1, -20, 0, 40)
        tabs.Position = UDim2.new(0, 10, 0, 72)
        tabs.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        tabs.BackgroundTransparency = 0.5
        tabs.BorderSizePixel = 1
        tabs.BorderColor3 = Color3.fromRGB(180, 60, 255)
        tabs.Parent = main
        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(0, 14)
        tc.Parent = tabs
        
        local tabNames = {"⚡ AIM", "🔥 FIRE", "🌈 ESP", "🏃 MOVE", "🎨 VISUAL", "⚙️ EXTRA", "📐 SIZE"}
        local tabButtons = {}
        local tabContents = {}
        
        for i, name in ipairs(tabNames) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1/#tabNames, -4, 1, -4)
            btn.Position = UDim2.new((i-1)/#tabNames, 2, 0, 2)
            btn.BackgroundColor3 = i == 1 and Color3.fromRGB(180, 60, 255) or Color3.fromRGB(0, 0, 0)
            btn.BackgroundTransparency = i == 1 and 0.2 or 0.6
            btn.Text = name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.GothamBold
            btn.BorderSizePixel = 0
            btn.Parent = tabs
            local bc = Instance.new

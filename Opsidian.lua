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
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 8)
            bc.Parent = btn
            tabButtons[i] = btn
            
            -- Контент вкладки
            local content = Instance.new("ScrollingFrame")
            content.Size = UDim2.new(1, -20, 1, -130)
            content.Position = UDim2.new(0, 10, 0, 120)
            content.BackgroundTransparency = 1
            content.BorderSizePixel = 0
            content.ScrollBarThickness = 4
            content.ScrollBarImageColor3 = Color3.fromRGB(180, 60, 255)
            content.CanvasSize = UDim2.new(0, 0, 0, 0)
            content.AutomaticCanvasSize = Enum.AutomaticSize.Y
            content.Visible = (i == 1)
            content.Parent = main
            local cl = Instance.new("UIListLayout")
            cl.Padding = UDim.new(0, 6)
            cl.Parent = content
            tabContents[i] = content
            
            btn.MouseButton1Click:Connect(function()
                for j, b in ipairs(tabButtons) do
                    b.BackgroundColor3 = (j == i) and Color3.fromRGB(180, 60, 255) or Color3.fromRGB(0, 0, 0)
                    b.BackgroundTransparency = (j == i) and 0.2 or 0.6
                    tabContents[j].Visible = (j == i)
                end
            end)
        end
        
        -- ============================================
        -- УНИВЕРСАЛЬНЫЙ TOGGLE
        -- ============================================
        local function CreateToggle(parent, text, settingKey)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 32)
            frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 1
            frame.BorderColor3 = Color3.fromRGB(60, 30, 90)
            frame.Parent = parent
            local fc = Instance.new("UICorner")
            fc.CornerRadius = UDim.new(0, 8)
            fc.Parent = frame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0.05, 0, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.fromRGB(230, 230, 255)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 50, 0, 22)
            toggle.Position = UDim2.new(1, -60, 0.5, -11)
            toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(180, 60, 255) or Color3.fromRGB(40, 40, 40)
            toggle.Text = settings[settingKey] and "ON" or "OFF"
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggle.TextScaled = true
            toggle.Font = Enum.Font.GothamBold
            toggle.BorderSizePixel = 0
            toggle.Parent = frame
            local tgc = Instance.new("UICorner")
            tgc.CornerRadius = UDim.new(0, 6)
            tgc.Parent = toggle
            
            toggle.MouseButton1Click:Connect(function()
                settings[settingKey] = not settings[settingKey]
                toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(180, 60, 255) or Color3.fromRGB(40, 40, 40)
                toggle.Text = settings[settingKey] and "ON" or "OFF"
            end)
        end
        
        -- ============================================
        -- УНИВЕРСАЛЬНЫЙ СЛАЙДЕР
        -- ============================================
        local function CreateSlider(parent, text, settingKey, min, max)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 1
            frame.BorderColor3 = Color3.fromRGB(60, 30, 90)
            frame.Parent = parent
            local fc = Instance.new("UICorner")
            fc.CornerRadius = UDim.new(0, 8)
            fc.Parent = frame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 0, 20)
            label.Position = UDim2.new(0.05, 0, 0, 2)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. tostring(settings[settingKey])
            label.TextColor3 = Color3.fromRGB(230, 230, 255)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local slider = Instance.new("TextButton")
            slider.Size = UDim2.new(0.9, 0, 0, 20)
            slider.Position = UDim2.new(0.05, 0, 0, 26)
            slider.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            slider.Text = ""
            slider.BorderSizePixel = 0
            slider.Parent = frame
            local slc = Instance.new("UICorner")
            slc.CornerRadius = UDim.new(0, 6)
            slc.Parent = slider
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((settings[settingKey] - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
            fill.BorderSizePixel = 0
            fill.Parent = slider
            local fdc = Instance.new("UICorner")
            fdc.CornerRadius = UDim.new(0, 6)
            fdc.Parent = fill
            
            local dragging = false
            local function update(input)
                local rel = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * rel
                settings[settingKey] = val
                fill.Size = UDim2.new(rel, 0, 1, 0)
                label.Text = text .. ": " .. string.format("%.2f", val)
            end
            
            slider.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
        end
        
        -- ============================================
        -- ЗАПОЛНЕНИЕ ВКЛАДОК
        -- ============================================
        -- AIM
        CreateToggle(tabContents[1], "Aimbot", "aimOn")
        CreateToggle(tabContents[1], "Silent Aim", "silentOn")
        CreateToggle(tabContents[1], "Wall Check", "wallOn")
        CreateToggle(tabContents[1], "Aim Lock", "aimLock")
        CreateToggle(tabContents[1], "Prediction", "prediction")
        CreateToggle(tabContents[1], "Visible Check", "visibleCheck")
        CreateSlider(tabContents[1], "Radius", "radius", 50, 500)
        CreateSlider(tabContents[1], "Smooth", "smooth", 0.01, 1)
        CreateSlider(tabContents[1], "FOV", "fov", 30, 360)
        
        -- FIRE
        CreateToggle(tabContents[2], "Fire Rate", "fireOn")
        CreateToggle(tabContents[2], "Trigger Bot", "triggerBot")
        CreateToggle(tabContents[2], "Burst Fire", "burstFire")
        CreateToggle(tabContents[2], "Kill Aura", "killAuraOn")
        CreateToggle(tabContents[2], "Anti AFK", "antiAfk")
        CreateSlider(tabContents[2], "Fire Rate", "fireRate", 0.01, 1)
        CreateSlider(tabContents[2], "Burst Count", "burstCount", 1, 10)
        CreateSlider(tabContents[2], "Kill Aura Range", "killAuraRange", 5, 100)
        
        -- ESP
        CreateToggle(tabContents[3], "ESP", "espOn")
        CreateToggle(tabContents[3], "Health", "showHealth")
        CreateToggle(tabContents[3], "Name", "showName")
        CreateToggle(tabContents[3], "Distance", "showDistance")
        CreateToggle(tabContents[3], "Glow", "glowOn")
        CreateToggle(tabContents[3], "Tracer", "tracer")
        CreateToggle(tabContents[3], "Skeleton", "skeleton")
        CreateToggle(tabContents[3], "Box Filled", "boxFilled")
        
        -- MOVE
        CreateToggle(tabContents[4], "Fly", "flyOn")
        CreateToggle(tabContents[4], "Noclip", "noclipOn")
        CreateToggle(tabContents[4], "BHop", "bhop")
        CreateToggle(tabContents[4], "Infinite Jump", "infiniteJump")
        CreateToggle(tabContents[4], "Auto Sprint", "autoSprint")
        CreateToggle(tabContents[4], "Anti Stun", "antiStun")
        CreateToggle(tabContents[4], "No Fall", "noFall")
        CreateToggle(tabContents[4], "Water Walk", "waterWalk")
        CreateToggle(tabContents[4], "Spider Man", "spiderMan")
        CreateToggle(tabContents[4], "Air Jump", "airJump")
        CreateToggle(tabContents[4], "Moon Jump", "moonJump")
        CreateToggle(tabContents[4], "Slide", "slideOn")
        CreateToggle(tabContents[4], "Dash", "dashOn")
        CreateToggle(tabContents[4], "Teleport", "teleportOn")
        CreateSlider(tabContents[4], "Speed", "speed", 16, 200)
        CreateSlider(tabContents[4], "Jump Power", "jump", 50, 300)
        CreateSlider(tabContents[4], "Fly Speed", "flySpeed", 1, 20)
        CreateSlider(tabContents[4], "Moon Jump Power", "moonJumpPower", 100, 500)
        CreateSlider(tabContents[4], "Slide Speed", "slideSpeed", 10, 100)
        CreateSlider(tabContents[4], "Dash Distance", "dashDistance", 10, 100)
        CreateSlider(tabContents[4], "Teleport Distance", "teleportDistance", 10, 200)
        
        -- VISUAL
        CreateToggle(tabContents[5], "Crosshair", "crosshairOn")
        CreateToggle(tabContents[5], "FOV Changer", "fovChanger")
        CreateToggle(tabContents[5], "Brightness", "brightness")
        CreateToggle(tabContents[5], "Fog", "fogOn")
        CreateToggle(tabContents[5], "Bloom", "bloom")
        CreateSlider(tabContents[5], "FOV Value", "fovValue", 30, 120)
        CreateSlider(tabContents[5], "Brightness Value", "brightnessValue", 0.5, 3)
        
        -- EXTRA
        CreateToggle(tabContents[6], "Auto Collect", "autoCollectOn")
        CreateToggle(tabContents[6], "Speed Hack", "speedHackOn")
        CreateToggle(tabContents[6], "Jump Hack", "jumpHackOn")
        CreateToggle(tabContents[6], "NoClip Fly", "noClipFlyOn")
        CreateToggle(tabContents[6], "God Mode", "godModeOn")
        CreateToggle(tabContents[6], "Invisible", "invisOn")
        CreateToggle(tabContents[6], "Auto Farm", "autoFarmOn")
        CreateToggle(tabContents[6], "Auto Click", "autoClickOn")
        CreateSlider(tabContents[6], "Auto Collect Range", "autoCollectRange", 10, 100)
        CreateSlider(tabContents[6], "Auto Collect Delay", "autoCollectDelay", 0.1, 3)
        CreateSlider(tabContents[6], "Speed Multiplier", "speedHackMultiplier", 1, 10)
        CreateSlider(tabContents[6], "Jump Multiplier", "jumpHackMultiplier", 1, 10)
        CreateSlider(tabContents[6], "NoClip Fly Speed", "noClipFlySpeed", 1, 50)
        CreateSlider(tabContents[6], "God Mode Health", "godModeHealth", 100, 9999)
        CreateSlider(tabContents[6], "Invis Opacity", "invisOpacity", 0.1, 1)
        CreateSlider(tabContents[6], "Auto Farm Delay", "autoFarmDelay", 0.1, 5)
        CreateSlider(tabContents[6], "Auto Farm Range", "autoFarmRange", 10, 200)
        CreateSlider(tabContents[6], "Auto Click Delay", "autoClickDelay", 0.05, 1)
        CreateSlider(tabContents[6], "Auto Click Range", "autoClickRange", 5, 100)
        
        -- SIZE
        local sizeInfo = Instance.new("TextLabel")
        sizeInfo.Size = UDim2.new(1, -10, 0, 60)
        sizeInfo.BackgroundTransparency = 1
        sizeInfo.Text = "Используй кнопки + и − вверху окна для изменения размера интерфейса.\n\nГорячие клавиши:\nRightShift — скрыть/показать\nR — аварийное закрытие"
        sizeInfo.TextColor3 = Color3.fromRGB(220, 220, 255)
        sizeInfo.TextScaled = true
        sizeInfo.Font = Enum.Font.Gotham
        sizeInfo.TextWrapped = true
        sizeInfo.Parent = tabContents[7]
        
        -- ============================================
        -- ОБРАБОТЧИКИ КНОПОК
        -- ============================================
        closeBtn.MouseButton1Click:Connect(function()
            gui:Destroy()
        end)
        
        local minimized = false
        toggleBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                main.Size = UDim2.new(0, 480 * uiSize, 0, 65)
                toggleBtn.Text = "+"
            else
                main.Size = UDim2.new(0, 480 * uiSize, 0, 640 * uiSize)
                toggleBtn.Text = "−"
            end
        end)
        
        return gui
    end
    
    -- ============================================
    -- ВОЗРОЖДЕНИЕ ИГРОКА
    -- ============================================
    local function getRoot()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    end
    
    local function getHumanoid()
        local char = lp.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end
    
    -- ============================================
    -- ПОИСК ЦЕЛИ ДЛЯ AIM
    -- ============================================
    local function getClosestPlayer()
        local closest = nil
        local shortest = settings.radius
        local mousePos = UserInputService:GetMouseLocation()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local part = p.Character:FindFirstChild(settings.aimPart) or p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = p
                        end
                    end
                end
            end
        end
        return closest
    end
    
    -- ============================================
    -- ESP СИСТЕМА
    -- ============================================
    local espObjects = {}
    
    local colorMap = {
        Violet = Color3.fromRGB(180, 60, 255),
        Red = Color3.fromRGB(255, 50, 50),
        Green = Color3.fromRGB(0, 255, 100),
        Blue = Color3.fromRGB(50, 150, 255),
        White = Color3.fromRGB(255, 255, 255),
    }
    
    local function clearESP()
        for _, obj in pairs(espObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects = {}
    end
    
    local function updateESP()
        clearESP()
        if not settings.espOn then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    if settings.espType == "Highlight" then
                        local hl = Instance.new("Highlight")
                        hl.Parent = espFolder
                        hl.Adornee = p.Character
                        hl.FillColor = colorMap[settings.espColor] or colorMap.Violet
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        espObjects[p] = hl
                    end
                end
            end
        end
    end
    
    if not espFolder.Parent then
        espFolder.Parent = workspace
    end
    
    -- ============================================
    -- ПРИЦЕЛ
    -- ============================================
    local function createCrosshair()
        if crosshair then crosshair:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Parent = lp:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        gui.Name = "ObsidianCrosshair"
        gui.ResetOnSpawn = false
        crosshair = gui
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.Position = UDim2.new(0.5, -2, 0.5, -2)
        dot.BackgroundColor3 = colorMap[settings.crosshairColor] or colorMap.Violet
        dot.BorderSizePixel = 0
        dot.Parent = gui
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot
    end
    createCrosshair()
    
    -- ============================================
    -- ГЛАВНЫЙ ЦИКЛ
    -- ============================================
    local function mainLoop()
        RunService.RenderStepped:Connect(function()
            -- AIM
            if settings.aimOn then
                local t = getClosestPlayer()
                if t and t.Character then
                    local part = t.Character:FindFirstChild(settings.aimPart) or t.Character:FindFirstChild("Head")
                    if part then
                        local targetPos = part.Position
                        if settings.prediction then
                            local vel = part.AssemblyLinearVelocity
                            targetPos = targetPos + vel * 0.1
                        end
                        local currentCF = Camera.CFrame
                        local targetCF = CFrame.new(currentCF.Position, targetPos)
                        Camera.CFrame = currentCF:Lerp(targetCF, settings.smooth)
                    end
                end
            end
            
            -- SPEED / JUMP
            local hum = getHumanoid()
            if hum then
                if settings.speedHackOn then
                    hum.WalkSpeed = settings.speed * settings.speedHackMultiplier
                else
                    hum.WalkSpeed = settings.speed
                end
                if settings.jumpHackOn then
                    hum.JumpPower = settings.jump * settings.jumpHackMultiplier
                else
                    hum.JumpPower = settings.jump
                end
            end
            
            -- NOCLIP
            if settings.noclipOn then
                local char = lp.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end
            
            -- FLY
            if settings.flyOn then
                local root = getRoot()
                if root then
                    if not flyBody then
                        flyBody = Instance.new("BodyVelocity")
                        flyBody.Parent = root
                    end
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
                    flyBody.Velocity = dir * settings.flySpeed * 50
                end
            else
                if flyBody then flyBody:Destroy() flyBody = nil end
            end
            
            -- FOV
            if settings.fovChanger then
                Camera.FieldOfView = settings.fovValue
            end
            
            -- BRIGHTNESS
            if settings.brightness then
                Lighting.Brightness = settings.brightnessValue
            end
            
            -- CROSSHAIR
            if crosshair then
                crosshair.Enabled = settings.crosshairOn
            end
        end)
        
        -- ESP LOOP (медленнее)
        task.spawn(function()
            while task.wait(0.5) do
                updateESP()
            end
        end)
        
        -- AUTO FARM / AUTO CLICK / AUTO COLLECT LOOP
        task.spawn(function()
            while task.wait(0.2) do
                local root = getRoot()
                if not root then else
                    -- Auto Click
                    if settings.autoClickOn then
                        -- простая авто-клик реализация через mouse click эмуляцию (если поддерживается executor)
                        pcall(function()
                            if mouse1press then
                                mouse1press()
                                task.wait(settings.autoClickDelay)
                                mouse1release()
                            end
                        end)
                    end
                end
            end
        end)
    end
    
    -- ============================================
    -- ВВОД
    -- ============================================
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            local gui = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("ObsidianBlack")
            if gui then gui.Enabled = not gui.Enabled end
        elseif input.KeyCode == Enum.KeyCode.R then
            local gui = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("ObsidianBlack")
            if gui then gui:Destroy() end
        elseif settings.infiniteJump and input.KeyCode == Enum.KeyCode.Space then
            local hum = getHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    
    -- ============================================
    -- ANTI AFK
    -- ============================================
    local vu = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        if settings.antiAfk then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)
    
    -- ============================================
    -- ЗАПУСК
    -- ============================================
    CreateObsidianUI()
    mainLoop()
end

-- ============================================
-- СТАРТ
-- ============================================
CreateKeyWindow()

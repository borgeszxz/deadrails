local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Dead Rails",
    SubTitle = "by borges",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    AccentColor = Color3.fromRGB(255, 165, 0),
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Welcome!", Icon = "home" }),
    AimAssist = Window:AddTab({ Title = "Aim Assist", Icon = "crosshair" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "share" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local playerName = game.Players.LocalPlayer.Name 

Tabs.Main:AddParagraph({
    Title = "Welcome, " .. playerName .. "!", 
    Content = "This is the main hub for Dead Rails."
})

local espEnabled = false
local showBox = true
local showHealthBar = true
local showTracer = true
local showName = true
local showDistance = true
local espDistanceLimit = 200

local ignoreList = {
    "Horse",
}

local espObjects = {}

local function ClearESP()
    for npc, esp in pairs(espObjects) do
        if esp then
            for _, drawing in pairs(esp) do
                if drawing.Remove then
                    drawing:Remove()
                end
            end
        end
    end
    espObjects = {}
end

local function CreateESP(npc)
    if not npc or espObjects[npc] then return end

    local esp = {
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        box = Drawing.new("Square"),
        healthbar = Drawing.new("Square"),
        tracer = Drawing.new("Line")
    }

    esp.name.Text = npc.Name
    esp.name.Size = 13
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Color = Color3.new(1, 1, 1)

    esp.distance.Size = 13
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Color = Color3.new(1, 1, 1)

    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Color = Color3.new(1, 1, 1)

    esp.healthbar.Thickness = 1
    esp.healthbar.Filled = true
    esp.healthbar.Color = Color3.new(0, 1, 0)

    esp.tracer.Thickness = 1
    esp.tracer.Color = Color3.new(1, 1, 1)

    espObjects[npc] = esp
end

local function UpdateESP()
    for npc, esp in pairs(espObjects) do
        if not npc.Parent then
            for _, drawing in pairs(esp) do
                if drawing.Remove then
                    drawing:Remove()
                end
            end
            espObjects[npc] = nil 
        else
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local rootPart = npc.HumanoidRootPart
                local head = npc:FindFirstChild("Head")
                local humanoid = npc.Humanoid

                if rootPart and head and humanoid then
                    local playerRootPart = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not playerRootPart then return end
                    
                    local distance = (playerRootPart.Position - rootPart.Position).Magnitude

                    if distance > espDistanceLimit or humanoid.Health <= 0 then
                        esp.name.Visible = false
                        esp.distance.Visible = false
                        esp.box.Visible = false
                        esp.healthbar.Visible = false
                        esp.tracer.Visible = false
                    else
                        local position, onScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)

                        if not onScreen or position.Z <= 0 then
                            esp.name.Visible = false
                            esp.distance.Visible = false
                            esp.box.Visible = false
                            esp.healthbar.Visible = false
                            esp.tracer.Visible = false
                        else
                            local npcSize = npc:GetExtentsSize()
                            local height = npcSize.Y
                            local width = npcSize.X

                            local screenPosTop, onScreenTop = game.Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, height / 2, 0))
                            local screenPosBottom, onScreenBottom = game.Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, height / 2, 0))

                            if onScreenTop and onScreenBottom then
                                local boxHeight = math.abs(screenPosTop.Y - screenPosBottom.Y)
                                local boxWidth = boxHeight / 2
                                local boxSize = Vector2.new(boxWidth, boxHeight)
                                local boxPosition = Vector2.new(position.X - boxSize.X / 2, position.Y - boxSize.Y / 2)

                                -- Name ESP
                                esp.name.Position = Vector2.new(position.X, boxPosition.Y - 20)
                                esp.name.Visible = showName
                                esp.name.Font = 1
                                esp.name.Size = 14

                                -- Distance ESP
                                esp.distance.Text = math.floor(distance) .. " studs"
                                esp.distance.Position = Vector2.new(position.X, boxPosition.Y + boxSize.Y + 5)
                                esp.distance.Visible = showDistance
                                esp.distance.Size = 14
                                esp.distance.Font = 1
                                

                                -- Box ESP
                                esp.box.Size = boxSize
                                esp.box.Position = boxPosition
                                esp.box.Color = Color3.new(1, 0, 0)
                                esp.box.Thickness = 2
                                esp.box.Visible = showBox
                                
                                -- Health Bar ESP
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                esp.healthbar.Size = Vector2.new(2, boxSize.Y * healthPercent)
                                esp.healthbar.Position = Vector2.new(boxPosition.X - 5, boxPosition.Y + (boxSize.Y * (1 - healthPercent)) - 5)
                                esp.healthbar.Visible = showHealthBar

                                -- Tracer ESP
                                esp.tracer.From = Vector2.new(game.Workspace.CurrentCamera.ViewportSize.X / 2, game.Workspace.CurrentCamera.ViewportSize.Y)
                                esp.tracer.To = Vector2.new(position.X, position.Y + boxSize.Y / 2)
                                esp.tracer.Visible = showTracer
                            end
                        end
                    end
                end
            end
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if espEnabled then
        for _, npc in pairs(game.Workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(npc) then
                if not table.find(ignoreList, npc.Name) and npc.Humanoid.Health > 0 then
                    if not espObjects[npc] then
                        CreateESP(npc)
                    end
                end
            end
        end
        UpdateESP()
    end
end)

Tabs.ESP:AddToggle("ESPToggle", {
    Title = "Enable ESP",
    Description = "Toggle entire ESP system",
    Default = false,
    Callback = function(value)
        espEnabled = value
        if not espEnabled then
            ClearESP()
        end
    end
})

Tabs.ESP:AddToggle("BoxESP", {
    Title = "Box ESP",
    Description = "Enable/Disable ESP Box",
    Default = true,
    Callback = function(value)
        showBox = value
    end
})

Tabs.ESP:AddToggle("HealthBarESP", {
    Title = "Health Bar ESP",
    Description = "Enable/Disable Health Bar",
    Default = true,
    Callback = function(value)
        showHealthBar = value
    end
})

Tabs.ESP:AddToggle("TracerESP", {
    Title = "Tracer ESP",
    Description = "Enable/Disable Tracer Line",
    Default = true,
    Callback = function(value)
        showTracer = value
    end
})

Tabs.ESP:AddToggle("NameESP", {
    Title = "Name ESP",
    Description = "Enable/Disable Name Display",
    Default = true,
    Callback = function(value)
        showName = value
    end
})

Tabs.ESP:AddToggle("DistanceESP", {
    Title = "Distance ESP",
    Description = "Enable/Disable Distance Display",
    Default = true,
    Callback = function(value)
        showDistance = value
    end
})

Tabs.ESP:AddSlider("ESPDistanceLimit", {
    Title = "ESP Max Distance",
    Description = "Adjust how far ESP will render (in studs)",
    Default = 200,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        espDistanceLimit = value
    end
})


local aimAssistEnabled = false
local smoothness = 1.0  
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

local maxDistance = 1000 

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.CapsLock then
            aimAssistEnabled = not aimAssistEnabled

            Library:Notify({
                Title = "🎯 Aim Assist",
                Content = aimAssistEnabled and "🔵 Activated! Your aim will now lock onto NPCs." or "🔴 Deactivated! Aim Assist is now off.",
                Duration = 2  
            })
        end
    end
end)


local visibleCheckEnabled = true 


function isNPCVisible(npcHead)
    local origin = camera.CFrame.Position  
    local destination = npcHead.Position 
    local direction = (destination - origin).Unit * (destination - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}  
    raycastParams.IgnoreWater = true

    local result = game.Workspace:Raycast(origin, direction, raycastParams)

    return result == nil or result.Instance:IsDescendantOf(npcHead.Parent)
end

local aimPriority = "Player"


function getScreenDistance(worldPosition)
    local screenPosition, onScreen = camera:WorldToViewportPoint(worldPosition)
    if onScreen then
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        return (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
    end
    return math.huge
end

function getClosestNPC()
    local closestNPC = nil
    local shortestDistance = math.huge  

    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local playerPosition = player.Character.HumanoidRootPart.Position

    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and not game.Players:GetPlayerFromCharacter(model) and obj.Health > 0 and model.Name ~= "Horse" then
                local head = model:FindFirstChild("Head")  
                if head then
                    local worldDistance = (playerPosition - head.Position).Magnitude
                    local screenDistance = getScreenDistance(head.Position)

                    local isVisible = not visibleCheckEnabled or isNPCVisible(head)

                    if aimPriority == "Player" then
                        if worldDistance < shortestDistance and worldDistance <= maxDistance and isVisible then
                            shortestDistance = worldDistance 
                            closestNPC = head
                        end
                    elseif aimPriority == "Crosshair" then
                        if screenDistance < shortestDistance and worldDistance <= maxDistance and isVisible then
                            shortestDistance = screenDistance
                            closestNPC = head
                        end
                    end
                end
            end
        end
    end

    return closestNPC
end






game:GetService("RunService").RenderStepped:Connect(function()
    if aimAssistEnabled then
        local target = getClosestNPC()
        if target then
            local targetPosition = target.Position
            local currentPosition = camera.CFrame.Position
            local newCFrame = CFrame.new(currentPosition, targetPosition)
            
            camera.CFrame = camera.CFrame:Lerp(newCFrame, smoothness * 0.1)
        end
    end
end)

Tabs.AimAssist:AddToggle("AimAssistToggle", {
    Title = "Aim Assist",
    Description = "Enables or disables Aim Assist",
    Default = false,
    Callback = function(value)
        aimAssistEnabled = value
    end
})
Tabs.AimAssist:AddSlider("AimAssistSmoothness", {
    Title = "Smoothness",
    Description = "Set the smoothness of Aim Assist",
    Default = 1.0,
    Min = 0.1,
    Max = 10.0,
    Rounding = 1,
    Callback = function(value)
        smoothness = value
    end
})
Tabs.AimAssist:AddSlider("AimAssistRange", {
    Title = "Maximum Distance",
    Description = "Set the maximum distance for Aim Assist",
    Default = 0,  
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        maxDistance = value 
    end
})
Tabs.AimAssist:AddToggle("VisibleCheckToggle", {
    Title = "Visible Check",
    Description = "Enables or disables visibility check for Aim Assist",
    Default = true,
    Callback = function(value)
        visibleCheckEnabled = value
    end
})
Tabs.AimAssist:AddDropdown("AimPriority", {
    Title = "Aim Priority",
    Description = "Choose between targeting closest to player or closest to crosshair",
    Values = { "Player", "Crosshair" },
    Default = 1,
    Multi = false,
    Callback = function(value)
        aimPriority = value
    end
})

-- Misc 
local espItemsEnabled = false
local espItems = {} 
local maxItemESPDistance = 100 
local runService = game:GetService("RunService")
local antiAFKEnabled = false

local function simulateMovement()
    while antiAFKEnabled do
        local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.new(0, 0, 0.1))
        end
        wait(5)
    end
end

local ignoredItems = {
    "Werewolf",
    "Parts",
    "Vampire",
    "Runner",
    "Walker",
    "Wolf",
    "Horse",
    "RevolverOutlaw",
    "ShotgunOutlaw",
    "BarbedWire",
    "Newspaper",
    "Teapot",
    "Top",
    "Camera",
    "Barrel",
    "Rope",
    "WantedPoster",
    "Tomahawk",
    "Vase",
    "SilverPainting",
    "Wheel",
    "Book",
    "Cavalry Sword",
    "RunnerSoldier",
    "ZombieSwordOfficer",
    "CaptainPrescott",
    "SheetMetal",
    "Sadle"
}

Tabs.Misc:AddToggle("ESPItemsToggle", {
    Title = "Item ESP",
    Description = "Enable/Disable ESP for collectible items",
    Default = false,
    Callback = function(state)
        espItemsEnabled = state
        if state then
            espItemsFunction()
        else
            removeAllItemESP()
        end
    end
})



Tabs.Misc:AddSlider("MaxItemESPDistance", {
    Title = "Max ESP Distance",
    Description = "Set how far (in studs) items will be visible",
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        maxItemESPDistance = value
    end
})

Tabs.Misc:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK",
    Description = "Prevents being kicked for AFK",
    Default = false,
    Callback = function(value)
        antiAFKEnabled = value
        if antiAFKEnabled then
            simulateMovement()
        end
    end
})

function updateESPItems()
    if not espItemsEnabled then return end
    
    local player = game.Players.LocalPlayer
    local character = player and player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return end

    for obj, espData in pairs(espItems) do
        if obj and obj.Parent then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local distance = (part.Position - rootPart.Position).Magnitude

                if distance <= maxItemESPDistance then
                    espData[2].Text = obj.Name .. " (" .. math.floor(distance) .. "m)"
                else
                    removeESP(obj)
                end
            end
        end
    end
end

function espItemsFunction()
    runService.RenderStepped:Connect(updateESPItems) 

    while espItemsEnabled do
        local player = game.Players.LocalPlayer
        local character = player and player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not rootPart then
            wait(0.1)
            continue
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Tool") then
                if obj:IsDescendantOf(workspace:FindFirstChild("RuntimeItems") or workspace:FindFirstChild("GameItems") or workspace:FindFirstChild("Weapons")) 
                and not table.find(ignoredItems, obj.Name) then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")

                    if part then
                        local distance = (part.Position - rootPart.Position).Magnitude

                        if distance <= maxItemESPDistance and not espItems[obj] then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "ItemESP"
                            highlight.FillColor = Color3.fromRGB(255, 255, 0) 
                            highlight.FillTransparency = 0.3
                            highlight.OutlineColor = Color3.fromRGB(0, 0, 0) 
                            highlight.OutlineTransparency = 0
                            highlight.Parent = part
                            
                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = "ItemESP"
                            billboard.Adornee = part
                            billboard.Size = UDim2.new(0, 200, 0, 50)
                            billboard.StudsOffset = Vector3.new(0, 2, 0)
                            billboard.AlwaysOnTop = true
                            billboard.Parent = part
                            
                            local textLabel = Instance.new("TextLabel", billboard)
                            textLabel.Size = UDim2.new(1, 0, 1, 0)
                            textLabel.BackgroundTransparency = 1
                            textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) 
                            textLabel.TextStrokeTransparency = 0.5
                            textLabel.Text = obj.Name .. " (" .. math.floor(distance) .. "m)" 
                            textLabel.TextSize = 14  
                            textLabel.Font = Enum.Font.GothamBold

                            espItems[obj] = { highlight, textLabel }
                        end
                    end
                end
            end
        end
        wait(0.1) 
    end
end

function removeESP(obj)
    if espItems[obj] then
        for _, part in pairs(espItems[obj]) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        espItems[obj] = nil
    end
end

function removeAllItemESP()
    for obj, esp in pairs(espItems) do
        if esp then
            for _, part in pairs(esp) do
                if part and part.Parent then
                    part:Destroy()
                end
            end
        end
    end
    espItems = {} 
end


SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

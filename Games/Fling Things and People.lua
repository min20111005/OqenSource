local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local EXCLUDE_TAG = "NoForceCollide"
local excludeNameContains = {
    "UI",
    "NoCollide"
}
local BATCH_YIELD_INTERVAL = 0.1
local BATCH_SIZE = 500
local function shouldExcludeInstance(inst)
    if CollectionService:HasTag(inst, EXCLUDE_TAG) then
        return true
    end
    if inst.Name then
        for _, substr in ipairs(excludeNameContains) do
            if string.find(inst.Name, substr, 1, true) then
                return true
            end
        end
    end
    return false
end

local function forceEnableCollisionsOnPart(part)
    if not part:IsA("BasePart") then return end
    if shouldExcludeInstance(part) then return end
    pcall(function()
        part.CanCollide = true
    end)
end

local function processAllExistingParts()
    local parts = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            table.insert(parts, inst)
        end
    end

    local count = 0
    for i, part in ipairs(parts) do
        forceEnableCollisionsOnPart(part)
        count = count + 1
        if count % BATCH_SIZE == 0 then
            wait(BATCH_YIELD_INTERVAL)
        end
    end
    return #parts
end

local function connectDescendantAdded()
    Workspace.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") then
            forceEnableCollisionsOnPart(inst)
        elseif inst:IsA("Model") or inst:IsA("Folder") then
            spawn(function()
                for _, d in ipairs(inst:GetDescendants()) do
                    if d:IsA("BasePart") then
                        forceEnableCollisionsOnPart(d)
                    end
                end
            end)
        end
    end)
end

local function revertCollisionsToFalseOnTagged()
    local tagged = CollectionService:GetTagged(EXCLUDE_TAG)
    for _, inst in ipairs(tagged) do
        if inst:IsA("BasePart") then
            pcall(function() inst.CanCollide = false end)
        elseif inst:IsA("Model") then
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("BasePart") then
                    pcall(function() d.CanCollide = false end)
                end
            end
        end
    end
end

local total = processAllExistingParts()
print("[ForceCollide] Changed CanCollide to true on " .. tostring(total) .. " parts.")
connectDescendantAdded()
local Players = game:GetService("Players")
local function onPlayerChatted(player, message)
    local tag = ""
    if player == Players.LocalPlayer then
        tag = "[Me] "
    else
        for _, friend in ipairs(Players.LocalPlayer:GetFriendsOnline()) do
            if tostring(friend.UserId) == tostring(player.UserId) then
                tag = "[Friend] "
                break
            end
        end
    end

    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = tag .. player.Name .. ": " .. message
    })
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        onPlayerChatted(player, msg)
    end)
end)

local function getRandomRGB()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return { R = r, G = g, B = b }
end

local Acolor = getRandomRGB()
local Bcolor = getRandomRGB()
local CONFIGURATION = {
    RANGE = 50
}
local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
ReplicatedStorage.DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
--colors
    ColorSequenceKeypoint.new(0, Color3.fromRGB(Acolor.R, Acolor.G, Acolor.B));
    ColorSequenceKeypoint.new(1, Color3.fromRGB(Bcolor.R, Bcolor.G, Bcolor.B))
}))
Player.CharacterAdded:Connect(function(Character)
    for i = 1, 10 do
        pcall(function() 
            for _, connection in getconnections(ReplicatedStorage.GamepassEvents.FurtherReachBoughtNotifier.OnClientEvent) do
                for i in debug.getupvalues(connection.Function) do
                    debug.setupvalue(connection.Function, i, CONFIGURATION.RANGE)
                end
            end
        end)
        task.wait()
    end
end)
local GrabParts = ReplicatedFirst.GrabParts
GrabParts.BeamPart.GrabBeam.Texture = "rbxassetid://8933355899"

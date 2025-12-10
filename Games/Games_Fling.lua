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
    if not inst then return false end
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
    if not part or not part:IsA("BasePart") then return end
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
            task.wait(BATCH_YIELD_INTERVAL)
        end
    end
    return #parts
end

local function connectDescendantAdded()
    Workspace.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") then
            forceEnableCollisionsOnPart(inst)
        elseif inst:IsA("Model") or inst:IsA("Folder") then
            task.spawn(function()
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
    local tagged = {}
    local ok, res = pcall(function() return CollectionService:GetTagged(EXCLUDE_TAG) end)
    if ok and type(res) == "table" then
        tagged = res
    end
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

-- Watch for tag adds/removes to maintain intended exclusion behavior
do
    -- Call once on startup
    revertCollisionsToFalseOnTagged()

    -- Connect signals (safe guarded)
    local ok, addSignal = pcall(function() return CollectionService.GetInstanceAddedSignal end)
    if ok and type(addSignal) == "function" then
        CollectionService:GetInstanceAddedSignal(EXCLUDE_TAG):Connect(function(inst)
            if inst then
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
        end)
    end

    local ok2, remSignal = pcall(function() return CollectionService.GetInstanceRemovedSignal end)
    if ok2 and type(remSignal) == "function" then
        CollectionService:GetInstanceRemovedSignal(EXCLUDE_TAG):Connect(function(inst)
            -- When tag removed, we may want to re-enable collisions depending on intent.
            -- Here we attempt to set CanCollide = true for parts that had the tag removed.
            if inst then
                if inst:IsA("BasePart") then
                    forceEnableCollisionsOnPart(inst)
                elseif inst:IsA("Model") then
                    for _, d in ipairs(inst:GetDescendants()) do
                        if d:IsA("BasePart") then
                            forceEnableCollisionsOnPart(d)
                        end
                    end
                end
            end
        end)
    end
end

local total = processAllExistingParts()
print("[ForceCollide] Changed CanCollide to true on " .. tostring(total) .. " parts.")
connectDescendantAdded()

-- Unified Players reference
local Players = game:GetService("Players")

-- Chat display hook (client-only). Only run if LocalPlayer exists (i.e. this is a LocalScript).
local localPlayer = Players.LocalPlayer
if localPlayer then
    local StarterGui = game:GetService("StarterGui")
    local function onPlayerChatted(player, message)
        local tag = ""
        if player == localPlayer then
            tag = "[Me] "
        else
            -- GetFriendsOnline may yield a list; be defensive
            local ok, friends = pcall(function() return localPlayer:GetFriendsOnline() end)
            if ok and type(friends) == "table" then
                for _, friend in ipairs(friends) do
                    if friend and friend.UserId and player.UserId and friend.UserId == player.UserId then
                        tag = "[Friend] "
                        break
                    end
                end
            end
        end

        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = tag .. player.Name .. ": " .. message
            })
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(msg)
            onPlayerChatted(player, msg)
        end)
    end)
end

-- Random colors and line color update (client-only)
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

-- Only clients should attempt to FireServer; check LocalPlayer
if localPlayer then
    -- Update line colors if event exists
    if ReplicatedStorage:FindFirstChild("DataEvents") and ReplicatedStorage.DataEvents:FindFirstChild("UpdateLineColorsEvent") then
        pcall(function()
            ReplicatedStorage.DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(Acolor.R, Acolor.G, Acolor.B));
                ColorSequenceKeypoint.new(1, Color3.fromRGB(Bcolor.R, Bcolor.G, Bcolor.B))
            }))
        end)
    end
end

-- CharacterAdded hook (client-only). Note: original attempted to change upvalues via debug API (exploit-only).
-- We attempt this only if those non-official APIs exist, and guard with pcall to avoid errors.
if localPlayer then
    local function tryModifyFurtherReach()
        -- Guard all non-official/exploit APIs
        if not ReplicatedStorage:FindFirstChild("GamepassEvents") then return end
        if not ReplicatedStorage.GamepassEvents:FindFirstChild("FurtherReachBoughtNotifier") then return end
        if type(getconnections) ~= "function" then return end
        if not (debug and type(debug.getupvalues) == "function" and type(debug.setupvalue) == "function") then
            return
        end

        local ok, conns = pcall(function()
            return getconnections(ReplicatedStorage.GamepassEvents.FurtherReachBoughtNotifier.OnClientEvent)
        end)
        if not ok or type(conns) ~= "table" then return end

        for _, connection in ipairs(conns) do
            pcall(function()
                local success, upvals = pcall(function()
                    return debug.getupvalues(connection.Function)
                end)
                if success and type(upvals) == "table" then
                    for idx = 1, #upvals do
                        pcall(function()
                            debug.setupvalue(connection.Function, idx, CONFIGURATION.RANGE)
                        end)
                    end
                end
            end)
        end
    end

    localPlayer.CharacterAdded:Connect(function(Character)
        -- Try a few times after character spawn (original code looped 10 times)
        task.spawn(function()
            for i = 1, 10 do
                pcall(tryModifyFurtherReach)
                task.wait()
            end
        end)
    end)
end

-- Safe assignment of GrabParts Beam texture (guard existence)
do
    local ok, grabParts = pcall(function()
        return ReplicatedFirst:FindFirstChild("GrabParts")
    end)
    if ok and grabParts and grabParts:FindFirstChild("BeamPart") and grabParts.BeamPart:FindFirstChild("GrabBeam") then
        pcall(function()
            grabParts.BeamPart.GrabBeam.Texture = "rbxassetid://8933355899"
        end)
    end
end
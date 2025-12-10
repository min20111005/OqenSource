--A TEAM
local function getRandomRGB()
    local Ar = math.random(0, 255)
    local Ag = math.random(0, 255)
    local Ab = math.random(0, 255)
    return { AR = Ar, AG = Ag, B = Ab }
end

--B TEAM
local function getRandomRGB()
    local Br = math.random(0, 255)
    local Bg = math.random(0, 255)
    local Bb = math.random(0, 255)
    return { BR = Br, BG = Bg, BB = Bb }
end

local color = getRandomRGB()
local CONFIGURATION = {
    RANGE = 50
}
local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

ReplicatedStorage.DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(color.AR, color.AG, color.AB));
    ColorSequenceKeypoint.new(1, Color3.fromRGB(color.BR, color.BG, color.BB))
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

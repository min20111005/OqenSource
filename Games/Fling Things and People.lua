local CONFIGURATION = {
      RANGE = 42;
}

local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

ReplicatedStorage.DataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(117,189,33));
ColorSequenceKeypoint.new(1, Color3.fromRGB(255,199,40));
ColorSequenceKeypoint.new(2, Color3.fromRGB(255,102,28));
ColorSequenceKeypoint.new(3, Color3.fromRGB(207,15,43));
ColorSequenceKeypoint.new(4, Color3.fromRGB(176,28,171));
ColorSequenceKeypoint.new(5, Color3.fromRGB(0,161,222));
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

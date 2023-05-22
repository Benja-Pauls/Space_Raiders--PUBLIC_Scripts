--[[
	FIRST JOIN
	This tutorial triggers when a player first opens the main menu
	It only untriggers once the player has gone through each step of the tutorial
	
]]
local TutorialUtility = require(script.Parent.Parent:WaitForChild('TutorialUtility'))
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local checkTutorialProgressEvent = eventsFolder:WaitForChild('CheckTutorialProgress')

local tutorialScreenGui = script.Parent.Parent

--[[
	Invis all the popups that will be used for this tutorial
]]
local function invisAllPopUps()
	for _,frame in pairs (script.Parent:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end
end

--[[
	Emergency exit of tutorial -- or player wishes to skip the tutorial
	@param strict: True if all pointers and popups should be invised
]]
local function cancelTutorial(strict)
	script.Parent.Visible = false

	if strict then
		invisAllPopUps()
		for _,pointer in pairs (script.Parent.Parent:GetChildren()) do
			if string.match(pointer.Name, "Pointer") then
				pointer:Destroy()
			end
		end
	end

	script.Disabled = true
end
local cancelButton = script.Parent.Parent:WaitForChild('CancelButton')
cancelButton.Activated:Connect(function()
	cancelTutorial(true)
	cancelButton.Visible = false
end)


--[[
	Start the tutorial
]]
local function triggerTutorial()
	print("Triggered FIRST JOIN tutorial")
	local mainMenu = tutorialScreenGui.Parent:WaitForChild('MainMenu'):WaitForChild('MainMenu')
	script.Parent.Visible = true
	
	cancelButton.Visible = true
	TweenService:Create(cancelButton, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0.454, 0, 0.948, 0)}):Play()
	
	invisAllPopUps()
	
	-- Create the first pop up
	wait(2)
	local popUp1 = script.Parent:WaitForChild('PopUp1')
	popUp1.Position = UDim2.new(0.436, 0, -0.2, 0); popUp1.Visible = true
	TweenService:Create(popUp1, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0.436, 0, 0.21, 0)}):Play()
	local newPointer = TutorialUtility.fingerPointer(UDim2.new(0.375, 0, 0.226, 0), -125, "playButtonPointer")
	TutorialUtility.triggerTutorialInvis(script, mainMenu, {newPointer}, {"PlayButton"}, 1)

	-- Get rid of tutorial pop up and save that they completed the tutorial
	mainMenu.PlayButton.Activated:Connect(function()
		script.Parent.Visible = false
		newPointer:Destroy()
		script.Parent.Parent.CancelButton.Visible = false
		checkTutorialProgressEvent:InvokeServer("FirstJoin2", true)
	end)
end
script:WaitForChild('Trigger').Event:Connect(triggerTutorial)

cancelButton.Visible = false
cancelButton.Position = UDim2.new(cancelButton.Position.X.Scale, 0, 1.15, 0)
script.Parent.NumOn.Value = 1
script.Parent.Visible = false

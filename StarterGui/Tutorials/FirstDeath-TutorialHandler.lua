--[[
	FIRST DEATH
	This tutorial triggers when a player first dies
	It only untriggers once the player presses the exit button in the MyShip menu
	
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


local function triggerTutorial6()
	script.Parent.NumOn.Value = 6
	local myShipMenu = tutorialScreenGui.Parent.MyShipMenu:WaitForChild('MyShipMenu')
	local popUp8 = script.Parent:WaitForChild('PopUp8')
	local equipButtonPointer = TutorialUtility.fingerPointer(UDim2.new(0.554, 0, 0.844, 0), -145, "equipButtonPointer")
	
	popUp8.Position = UDim2.new(1.3, 0, popUp8.Position.Y.Scale, 0)
	popUp8.Visible = true
	TweenService:Create(popUp8, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.61, 0, 0.797, 0)}):Play()
	
	TutorialUtility.triggerTutorialInvis(script, myShipMenu.Parent, {equipButtonPointer}, {"EquipButton", 
		"LaserColor", "PrimaryColor", "SecondaryColor", "Tile1", "Tile2", "Tile3", "Tile4", "Tile5", "UpArrow", "DownArrow"}, 6)
	
	myShipMenu.Parent.CustomizeMenu.EquipButton.Activated:Connect(function()
		script.Parent.Visible = false
		equipButtonPointer:Destroy()
		checkTutorialProgressEvent:InvokeServer("FirstDeath", true)
	end)
	
	if not myShipMenu.Visible then
		equipButtonPointer:Destroy()
		script.Parent.Visible = false
		script.Disabled = true
		script.Parent.Parent.CancelButton.Visible = false
	end
end


local function triggerTutorial5()
	script.Parent.NumOn.Value = 5
	local myShipMenu = tutorialScreenGui.Parent.MyShipMenu:WaitForChild('MyShipMenu')
	local popUp7 = script.Parent:WaitForChild('PopUp7')
	local check1Pointer = TutorialUtility.fingerPointer(UDim2.new(0.617, 0, 0.82, 0), -170, "check1Pointer")
	local check2Pointer = TutorialUtility.fingerPointer(UDim2.new(0.692, 0, 0.82, 0), -170, "check2Pointer")
	local check3Pointer = TutorialUtility.fingerPointer(UDim2.new(0.766, 0, 0.82, 0), -170, "check3Pointer")
	
	popUp7.Position = UDim2.new(1.3, 0, popUp7.Position.Y.Scale, 0)
	popUp7.Visible = true
	TweenService:Create(popUp7, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.574, 0, 0.74, 0)}):Play()
	
	TutorialUtility.triggerTutorialInvis(script, myShipMenu.Parent, {check1Pointer, check2Pointer, check3Pointer}, 
	{"LaserColor", "PrimaryColor", "SecondaryColor", "EquipButton"}, 5)
	
	local laserColorButton = myShipMenu.Parent.CustomizeMenu.ColorChoiceDisplay.LaserColor
	local primaryColorButton = myShipMenu.Parent.CustomizeMenu.ColorChoiceDisplay.PrimaryColor
	local secondaryColorButton = myShipMenu.Parent.CustomizeMenu.ColorChoiceDisplay.SecondaryColor
	for _,button in pairs ({laserColorButton, primaryColorButton, secondaryColorButton}) do
		button.Activated:Connect(function()
			if not script.Parent:WaitForChild('PopUp8').Visible then
				popUp7.Visible = false
				check1Pointer:Destroy(); check2Pointer:Destroy(); check3Pointer:Destroy()
				triggerTutorial6()
			end
		end)
	end
	
	if not myShipMenu.Visible then
		popUp7.Visible = false
		check1Pointer:Destroy(); check2Pointer:Destroy(); check3Pointer:Destroy()
		script.Parent.Visible = false
		script.Disabled = true
	end
end

--[[
	Trigger the fourth part of the tutorial
	MyShipMenu: Show player they have colors to select
]]
local function triggerTutorial4()
	script.Parent.NumOn.Value = 4
	wait(1.5)
	local myShipMenu = tutorialScreenGui.Parent.MyShipMenu:WaitForChild('MyShipMenu')
	local popUp6 = script.Parent:WaitForChild('PopUp6')
	
	local tile1Pointer = TutorialUtility.fingerPointer(UDim2.new(0.506, 0, 0.115, 0), -125, "tile1Pointer")
	local tile2Pointer = TutorialUtility.fingerPointer(UDim2.new(0.506, 0, 0.271, 0), -125, "tile2Pointer")
	local tile3Pointer = TutorialUtility.fingerPointer(UDim2.new(0.506, 0, 0.425, 0), -125, "tile3Pointer")
	local tile4Pointer = TutorialUtility.fingerPointer(UDim2.new(0.506, 0, 0.581, 0), -125, "tile4Pointer")
	local tile5Pointer = TutorialUtility.fingerPointer(UDim2.new(0.506, 0, 0.732, 0), -125, "tile5Pointer")
	
	popUp6.Position = UDim2.new(1.3, 0, popUp6.Position.Y.Scale, 0)
	popUp6.Visible = true
	TweenService:Create(popUp6, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.601, 0, 0.716, 0)}):Play()
	
	TutorialUtility.triggerTutorialInvis(script, myShipMenu, {tile1Pointer, tile2Pointer, tile3Pointer, tile4Pointer, tile5Pointer}, 
	{"LaserColor", "PrimaryColor", "SecondaryColor", "EquipButton"}, 4)
	TutorialUtility.triggerTutorialInvis(script, myShipMenu.Parent.Barriers, {tile1Pointer, tile2Pointer, tile3Pointer, tile4Pointer, tile5Pointer}, 
	{"LaserColor", "PrimaryColor", "SecondaryColor", "EquipButton"}, 4)
	
	for _,tile in pairs (myShipMenu.Parent.CustomizeMenu:WaitForChild('Page1'):GetChildren()) do
		if tile:IsA("ImageButton") and string.match(tile.Name, "Tile") then
			tile.Activated:Connect(function()
				
				if not script.Parent:WaitForChild('PopUp7').Visible then
					popUp6.Visible = false
					tile1Pointer:Destroy(); tile2Pointer:Destroy(); tile3Pointer:Destroy()
					tile4Pointer:Destroy(); tile5Pointer:Destroy()
					triggerTutorial5()
				end
			end)
		end
	end
	
	if not myShipMenu.Visible then
		popUp6.Visible = false
		tile1Pointer:Destroy(); tile2Pointer:Destroy(); tile3Pointer:Destroy()
		tile4Pointer:Destroy(); tile5Pointer:Destroy()
		script.Parent.Visible = false
		script.Disabled = true
	end
end

--[[
	Trigger the third part of the tutorial
	MyShipMenu: Show player how they can customize their ship
]]
local function triggerTutorial3()
	script.Parent.NumOn.Value = 3
	wait(4.5)
	local myShipMenu = tutorialScreenGui.Parent.MyShipMenu:WaitForChild('MyShipMenu')
	local popUp5 = script.Parent:WaitForChild('PopUp5')
	local firstPagePointer = TutorialUtility.fingerPointer(UDim2.new(0.362, 0, 0.717, 0), 20, "firstPagePointer")
	
	popUp5.Position = UDim2.new(1.3, 0, popUp5.Position.Y.Scale, 0)
	popUp5.Visible = true
	TweenService:Create(popUp5, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.425, 0, popUp5.Position.Y.Scale, 0)}):Play()
	
	TutorialUtility.triggerTutorialInvis(script, myShipMenu.Parent, {firstPagePointer}, 
	{"ColorsButton", "LaserColor", "PrimaryColor", "SecondaryColor", "EquipButton"}, 3)
	
	myShipMenu.ColorsButton.Activated:Connect(function()
		if not script.Parent:WaitForChild('PopUp6').Visible then
			popUp5.Visible = false
			firstPagePointer:Destroy()
			triggerTutorial4()
		end
	end)
	
	if not myShipMenu.Visible then
		popUp5.Visible = false
		firstPagePointer:Destroy()
		script.Parent.Visible = false
		script.Disabled = true
	end
end

--[[
	Trigger the second part of the tutorial
	Main Menu: Tell player they should go customize their ship
]]
local function triggerTutorial2()
	script.Parent.NumOn.Value = 2
	local mainMenu = tutorialScreenGui.Parent.MainMenu:WaitForChild('MainMenu')
	local popUp4 = script.Parent:WaitForChild('PopUp4')
	local mainMenuPointer = TutorialUtility.fingerPointer(UDim2.new(0.285, 0, 0.446, 0), -110, "mainMenuPointer")
	TutorialUtility.triggerTutorialInvis(script, mainMenu, {mainMenuPointer}, {"ShipButton"}, 2)
	
	popUp4.Position = UDim2.new(popUp4.Position.X.Scale, 0, -.1, 0)
	popUp4.Visible = true
	TweenService:Create(popUp4, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(popUp4.Position.X.Scale, 0, 0.454, 0)}):Play()
	
	mainMenu.ShipButton.Activated:Connect(function()
		popUp4.Visible = false
		mainMenuPointer:Destroy()
		triggerTutorial3()
	end)
	
	if not mainMenu.Visible then
		if not script.Parent:WaitForChild('PopUp5').Visible then
			popUp4.Visible = false
			mainMenuPointer:Destroy()
			script.Parent.Visible = false
			script.Disabled = true
		end
	end
end


--[[
	Start the tutorial
]]
local function triggerTutorial()
	script.Parent.NumOn.Value = 1
	print("Triggered FIRST DEATH tutorial")
	local deathScreen = tutorialScreenGui.Parent.DeathScreen:WaitForChild('DeathScreen')
	
	cancelButton.Visible = true
	TweenService:Create(cancelButton, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0.012, 0, 0.084, 0)}):Play()
	
	invisAllPopUps()
	script.Parent.Visible = true
	
	-- DeathScreen: Let the player know what coins and gems mean --
	local popUp1 = script.Parent:WaitForChild('PopUp1')
	local popUp2 = script.Parent:WaitForChild('PopUp2')
	local popUp3 = script.Parent:WaitForChild('PopUp3')
	popUp1.Position = UDim2.new(popUp1.Position.X.Scale, 0, -.1, 0); popUp1.Visible = true
	popUp2.Position = UDim2.new(popUp2.Position.X.Scale, 0, -.1, 0); popUp2.Visible = true
	popUp3.Position = UDim2.new(-.3, 0, popUp3.Position.Y.Scale, 0); popUp3.Visible = true
	TweenService:Create(popUp1, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(popUp1.Position.X.Scale, 0, 0.287, 0)}):Play()
	TweenService:Create(popUp2, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(popUp2.Position.X.Scale, 0, 0.287, 0)}):Play()
	TweenService:Create(popUp3, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.157, 0, popUp3.Position.Y.Scale, 0)}):Play()
	local deathScreenPointer = TutorialUtility.fingerPointer(UDim2.new(0.393, 0, 0.806, 0), -195, "deathScreenPointer")
	
	deathScreen.MainMenu.Activated:Connect(function()
		popUp1.Visible = false; popUp2.Visible = false; popUp3.Visible = false
		deathScreenPointer:Destroy()
		
		wait(1)
		triggerTutorial2()
	end)

	
end
script:WaitForChild('Trigger').Event:Connect(triggerTutorial)

local myShipMenu = tutorialScreenGui.Parent:WaitForChild('MyShipMenu')
myShipMenu:WaitForChild('Barriers'):WaitForChild('BackButton').Activated:Connect(function()
	invisAllPopUps()
	script.Parent.Visible = false
	script.Disabled = true
end)

cancelButton.Visible = false
cancelButton.Position = UDim2.new(-.2, 0, cancelButton.Position.Y.Scale, 0)
script.Parent.NumOn.Value = 1
script.Parent.Visible = false

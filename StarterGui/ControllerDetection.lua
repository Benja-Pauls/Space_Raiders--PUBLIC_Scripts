local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiUtility = require(player.PlayerGui:WaitForChild("GuiUtility"))

local guiEventsFolder = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('GUI')
local clientDisplayMainMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')
local tutorialScreenDoneEvent = guiEventsFolder:WaitForChild('TutorialScreenDone')

local text = script.Parent:WaitForChild("ControllerPrompt"):WaitForChild("Prompt")
local startSize = text.Size

local pressSound = player.PlayerGui:WaitForChild('ButtonPress')
local hoverSound = player.PlayerGui:WaitForChild("ButtonHover")

local function hideMenu()
	pressSound:Play()
	wait(not script.Parent:WaitForChild('MainMenuReady').Value) -- Wait for event to register
	clientDisplayMainMenuEvent:Fire(true)
	
	TweenService:Create(script.Parent.ControllerPrompt, TweenInfo.new(.7), {Position = UDim2.new(0, 0, -1.1, 0)}):Play()
	wait(.7)
	script.Parent.ControllerPrompt.Visible = false
end

local controllerButton = script.Parent:WaitForChild('ControllerPrompt'):WaitForChild('Controller'):WaitForChild('InnerButton')
controllerButton.Activated:Connect(function()
	script.Parent.UsingController.Value = true
	hideMenu()
end)
controllerButton.MouseEnter:Connect(function()
	hoverSound:Play()
	GuiUtility.resizeButtonEffect(controllerButton.Parent, hoverSound)
end)

local keyboardButton = script.Parent:WaitForChild('ControllerPrompt'):WaitForChild('Keyboard'):WaitForChild('InnerButton')
keyboardButton.Activated:Connect(function()
	hideMenu()
end)
keyboardButton.MouseEnter:Connect(function()
	hoverSound:Play()
	GuiUtility.resizeButtonEffect(keyboardButton.Parent, hoverSound)
end)

tutorialScreenDoneEvent.Event:Connect(function()
	if UserInputService.GamepadEnabled then
		local menu = script.Parent:WaitForChild('ControllerPrompt')
		menu.Position = UDim2.new(0, 0, 1, 0)
		menu.Visible = true
		TweenService:Create(menu, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	else
		if player.PlayerGui:FindFirstChild('TouchGui') then
			ref.Value = true
		end
		hideMenu()
	end
end)
script.Parent:WaitForChild('ControllerPrompt').Visible = false

--[[ Running
local outTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local inTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local outTween = TweenService:Create(text, outTweenInfo, {Size = UDim2.new(startSize.X.Scale, 0, startSize.Y.Scale + .003, 0)})
local inTween = TweenService:Create(text, inTweenInfo, {Size = startSize})
while script.Parent.ControllerPrompt.Visible do
	outTween:Play()
	wait(outTweenInfo.Time+.1)
	inTween:Play()
	wait(inTweenInfo.Time+.1)
end
]]

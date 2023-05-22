local TweenService = game:GetService('TweenService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local createNotificationEvent = guiEventsFolder:WaitForChild('CreateNotification')

local notification = game.ReplicatedStorage:WaitForChild('GuiElements'):WaitForChild('Notification')

--[[
	Hide/Display the notification
	@param notification: Frame of the notification
	@param direction: 1 if it should be down, -1 if up
]]
local function displayNotification(notification, direction)
	-- TweenService into the screen
	local tween = TweenService:Create(
		notification, 
		TweenInfo.new(2, Enum.EasingStyle.Quint),
		{Position = UDim2.new(notification.Position.X.Scale, 0, notification.Position.Y.Scale + .32*direction, 0)}
	)
	tween:Play()
	wait(tween.TweenInfo.Time)
end


--[[
	Display a notification to the player about some message
	@param message: String representing message that will be displayed
	@param primaryColor: Color3 for primary color
	@param secondaryColor: Color3 for secondary color
]]
local function createNotification(message, primaryColor, secondaryColor)
	-- Delete any other notification that may be here
	if #script.Parent:GetChildren() > 1 then
		for _,notification in pairs (script.Parent:GetChildren()) do
			if not notification:IsA('Script') then
				notification:Destroy()
			end
		end
	end
	
	-- Position below screen
	local newNotification = notification:Clone()
	newNotification.Parent = script.Parent
	newNotification.Position = UDim2.new(0.5, 0, 1.15, 0)
	newNotification.TextLabel.TextTransparency = 0
	newNotification.TextLabel.Text = message
	newNotification.TextLabel.TextColor3 = primaryColor
	newNotification.TextLabel.UIStroke.Color = secondaryColor
	
	displayNotification(newNotification, -1)
	wait(4)
	
	-- Delete the notification
	displayNotification(newNotification, 1)
	newNotification:Destroy()
end
createNotificationEvent.OnClientEvent:Connect(createNotification)

local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local CircularLoading = require(script.Parent:WaitForChild('CircularLoading'))
local Tips = require(script.Parent:WaitForChild('Tips'))
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

-- Begin circular-loading animation for the loading screen
local LoadCircle3 = CircularLoading.new({BGColor = Color3.fromRGB(23, 27, 85), Position = UDim2.fromScale(0.04, 0.65)})
LoadCircle3.BGRoundness = 0.1
LoadCircle3.AnchorPoint = Vector2.new(0.5, 0.5) -- By default the anchor point is (0, 1) set it to (0, 0) if you need to
LoadCircle3.Color = Color3.fromRGB(89, 164, 255)
LoadCircle3.Position = UDim2.fromScale(0.5, 0.5)
LoadCircle3:Animate("InfSpin3")

-- Black background for the loading screen
local loadingScreen = script.Parent:WaitForChild("LoadingScreenUI")
local percentageLabel = loadingScreen:WaitForChild("Percentage")
loadingScreen.Parent = playerGui

--[[
	Given the amount of data still being processed, update the loading screen the player sees
	@param starterRequestQueueSize  Amount of data that needed to be completed at the beginning of loading
	@param requestQueueSize  Amount of data still left to be loadeed
]]
local function loadViewUpdate(starterRequestQueueSize, requestQueueSize)
	local percent = 100
	if starterRequestQueueSize > 0 then
		percent = math.floor(((starterRequestQueueSize-requestQueueSize)/starterRequestQueueSize)* 100)
	end
	if percent < 0 then
		percent = 0
	end
	percentageLabel.Text = tostring(percent) .. "%"
end

--[[
	Once game has finished loading, this screen will be hidden from view to display tutorials
]]
local function hideLoadingScreen()
	local GuiUtility = require(player.PlayerGui:WaitForChild('GuiUtility'))
	local done = GuiUtility.blackMenuFade(true, 0.05) -- Wait to finish fade
	loadingScreen:Destroy()
	
	-- Trigger tutorial menu to display
	player.PlayerGui:WaitForChild('Tutorials'):WaitForChild('Background').Visible = true
end
 
-- Custom Loading-screen function
spawn(function()
	local tip = math.random(1, #Tips) -- Determine loading screen tip
	tip = Tips[tip]
	loadingScreen.Tip.Text = "Pro Tip: " .. tip
	
	ContentProvider:PreloadAsync({game:GetService("ReplicatedStorage"), game:GetService("StarterGui")})
	local startRequestQueueSize = ContentProvider.RequestQueueSize
	
	if startRequestQueueSize > 0 then
		while ContentProvider.RequestQueueSize > 0 do
			wait(.25)
			loadViewUpdate(startRequestQueueSize, ContentProvider.RequestQueueSize)
		end
	end
	LoadCircle3:Destroy()
	playerGui.CircularProgress:Destroy()

	wait(1)
	
	-- Extra check to ensure the game has loaded
	if not game:IsLoaded() then -- Wait until the game has loaded
		game.Loaded:Wait()
	end
	loadingScreen.Percentage.Bounce.Disabled = true
	
	hideLoadingScreen()
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) -- Invis all default core-gui
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) -- Make leaderboard still available
StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight

local success = false
local resetPressedEvent = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('GUI'):WaitForChild('ResetPressed')
while not success do
	wait(1)
	success = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", resetPressedEvent) -- Call the resetPressedEvent when the player presses the reset button
	end)
end


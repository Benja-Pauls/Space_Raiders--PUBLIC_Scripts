-- Could use camera to bob to the beat of the music
-- Disabled cause some users may experience motion sickness?

local TweenService = game:GetService("TweenService")

local camera = workspace.CurrentCamera
local gameTitle = game.Players.LocalPlayer.PlayerGui:WaitForChild("MainMenu"):WaitForChild("TitleFrame"):WaitForChild("GameTitle")
local tweenInfo = TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local OUT_SIZE = 1.05
local IN_SIZE = 1
local SIZE_DIFF = OUT_SIZE - IN_SIZE

-- Whenever the song changes, see if the camera should bob along with it
script.Parent.Parent.CurrentSong.Changed:Connect(function()
	if script.Parent.Parent.BobEnabled.Value then
		local currentSong = script.Parent.Parent.CurrentSong.Value
		if currentSong and currentSong:IsA("Sound") then
			while camera and script.Parent.Parent.CurrentSong.Value == currentSong and script.Parent.Parent.BobEnabled.Value do
				local loud = currentSong.PlaybackLoudness
				wait(.05)
				loud /= 275*currentSong.Volume -- Limit
				if loud < .18 then
					loud = 0
				end

				local newSize = IN_SIZE + (SIZE_DIFF * loud)
				if newSize > OUT_SIZE then
					newSize = OUT_SIZE -- Set to max if over limit
				end
				TweenService:Create(gameTitle, tweenInfo, {Size = UDim2.new(1, 0, newSize, 0)}):Play()
			end
		end
	end
end)

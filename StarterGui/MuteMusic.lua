local MusicPlayer = require(script.Parent.Parent:WaitForChild('MusicPlayer'))
local player = game.Players.LocalPlayer

local musicButton = script.Parent
local staticMusicImage = "rbxassetid://10423292988"; local hoverMusicImage = "rbxassetid://10424119482"
local staticMusicOffImage = "rbxassetid://10424277076"; local hoverMusicOffImage = "rbxassetid://10424280680"

local buttonDebounce = false
musicButton.Activated:Connect(function()
	if not buttonDebounce then
		buttonDebounce = true
		script.Parent.Parent.Parent.ButtonPress:Play()
		
		if musicButton.Image == staticMusicImage then
			musicButton.Image = staticMusicOffImage
			musicButton.HoverImage = hoverMusicOffImage
			musicButton.PressedImage = staticMusicImage
			game.ReplicatedStorage.Music.Muted.Value = true
			if script.Parent.Parent:WaitForChild('CurrentSong').Value then
				script.Parent.Parent.CurrentSong.Value:Stop()
			end
			buttonDebounce = false
		else
			musicButton.Image = staticMusicImage
			musicButton.HoverImage = hoverMusicImage
			musicButton.PressedImage = staticMusicOffImage
			game.ReplicatedStorage.Music.Muted.Value = false
			buttonDebounce = false
			
			-- Determine which folder to shuffle depending on setting of player
			if workspace:WaitForChild('Ships'):FindFirstChild(tostring(player.UserId) .. "'s Hitbox") then
				MusicPlayer.shuffle("InGame")
			else
				MusicPlayer.shuffle("MainMenu")
			end
		end
	end
end)
musicButton.MouseEnter:Connect(function()
	script.Parent.Parent.Parent.ButtonHover:Play()
end)
musicButton.Image = staticMusicImage; musicButton.HoverImage = hoverMusicImage

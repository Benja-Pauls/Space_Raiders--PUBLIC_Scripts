local MusicPlayer = {}
local TweenService = game:GetService("TweenService")

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local playSongEvent = eventsFolder:WaitForChild('PlaySong')
local stopMusicEvent = eventsFolder:WaitForChild('StopMusic')

local musicFolder = game.ReplicatedStorage:WaitForChild('Music')
local popUpFolder = game.ReplicatedStorage:WaitForChild('GuiElements'):WaitForChild('PopUps')

-- TODO: Fade out songs as I transition between them
-- Randomly select music within a soundtrack depending on the current state of the player

local function displayMusicPopUp(songName)
	if script.Parent:FindFirstChild("MusicPopUp") then
		script.Parent.MusicPopUp:Destroy()
	end
	
	local popUp = popUpFolder.MusicPopUp:Clone()
	popUp.SongName.Text = songName
	popUp.Parent = script.Parent
	popUp.DisplayScript.Disabled = false
end

--[[
	Fade out/in a particular song
	@param song  Song whose volume is being faded
	@param finalVolume  Volume that will be achieved at the end of the fade
	@param fadeLength  Length of fade (default is 3 seconds)
]]
local DEFAULT_FADE = 3
local function fadeMusic(song, finalVolume, fadeLength)
	if fadeLength == nil then
		fadeLength = DEFAULT_FADE
	end
	if finalVolume > 0 then
		song.Volume = 0
		TweenService:Create(song, TweenInfo.new(fadeLength), {Volume = finalVolume}):Play()
	else
		TweenService:Create(song, TweenInfo.new(fadeLength), {Volume = 0}):Play()
	end
	wait(fadeLength)
end

--[[
	Select a random given that some songs have already been selected
	@param originalFolder  Folder containing all the songs that will be shuffled through
	@param playList  Songs that have already been ordered and are prepared for playing
	@param filteredSong  A particular song that should be ignored (usually the last-played song of previous shuffle)

]]
local function shuffleSelect(originalFolder, playList, filteredSong)
	local songChoices = {}
	for _,song in pairs (originalFolder:GetChildren()) do
		if table.find(playList, tostring(song)) == nil and tostring(song) ~= filteredSong then
			table.insert(songChoices, tostring(song))
		end
	end
	local index = math.random(1,#songChoices)
	return songChoices[index]
end

--[[
	Play a particular folder on shuffle
	@param folderName  Name of the folder (playlist) the music player is playing through
]]
local playList = {}
local inShuffle = false
function MusicPlayer.shuffle(folderName)
	local selectedFolder = musicFolder:FindFirstChild(folderName)
	playList = {} -- Reset the playlist on new shuffle
	inShuffle = true

	-- Fill the playlist
	for i,song in pairs (selectedFolder:GetChildren()) do
		local elem = shuffleSelect(selectedFolder, playList)
		if i < #selectedFolder:GetChildren() then
			elem = shuffleSelect(selectedFolder, playList, tostring(script.Parent.CurrentSong.Value))
		end
		
		table.insert(playList, elem)
	end
	
	coroutine.resume(coroutine.create(function()
		-- Play the created playlist and repeat once song has reached the end
		for i,playedSong in pairs (playList) do
			print("Song " .. tostring(i) .. " of the playlist: " .. tostring(playedSong))
			MusicPlayer.playSong(folderName, playedSong, DEFAULT_FADE, true)
			wait(selectedFolder:FindFirstChild(playedSong).TimeLength-(2*DEFAULT_FADE)) -- Leave enough time for a 3-second fade
			if not inShuffle then
				break -- Some other song must've started playing; end the shuffle
			else
				if i == #playList then -- Last song
					MusicPlayer.shuffle(folderName)
				end
			end
		end
	end))
end


--[[
	Stop the currently-playing music from playing
	@param fade  Amount of time the fade-out should last
]]
function MusicPlayer.stopMusic(fade)
	playList = {}
	for _,folder in pairs (musicFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _,song in pairs (folder:GetChildren()) do
				if song:IsA("Sound") and song.Playing == true then
					if fade ~= nil then
						fadeMusic(song, 0, fade)
					else
						song:Stop()
					end
				end
			end
		end
	end
end

--[[
	Start playing a particular song
	@param folderName  Name of the folder the song is contained in
	@param songName  Name of the song that will be played
	@param fadeInTime  Amount of time the fade-in of the song will last (if specified)
	@param fromShuffle  Signifies if this method was called from a shuffle
	@repeatBool  True if the song should be repeated instead of shuffled when song ends
	@toShuffle  Name of shuffle folder if song should then turn into a shuffle
]]
function MusicPlayer.playSong(folderName, songName, fadeInTime, fromShuffle, repeatBool, toShuffle)
	coroutine.resume(coroutine.create(function()
		if not fromShuffle then
			inShuffle = false
		end

		if musicFolder:FindFirstChild(folderName) then
			local song = musicFolder:FindFirstChild(folderName):FindFirstChild(songName)
			if song and song:IsA("Sound") then
				-- print("Playing new song...  ", songName)

				-- Fade out the currently-playing song if it's playing
				local currentSong = script.Parent.CurrentSong.Value
				if currentSong then
					if currentSong.Playing == true then
						if fadeInTime then	
							fadeMusic(currentSong, 0)
						else
							currentSong:Stop()
						end
					end
				end

				-- Ensure all other songs are not playing
				for _,folder in pairs (musicFolder:GetChildren()) do
					if folder:IsA("Folder") then
						for _,song in pairs (folder:GetChildren()) do
							if song:IsA("Sound") then
								song:Stop()
								song.TimePosition = 0
							end
						end
					end
				end

				-- Play the song we'd like to be played
				script.Parent.CurrentSong.Value = song
				song.TimePosition = 0
				song.Volume = song.PlayingVolume.Value -- Make sure newly-playing song is aubdible
				if not musicFolder.Muted.Value then
					song:Play()
				end
				displayMusicPopUp(tostring(song))
				if fadeInTime then
					fadeMusic(song, song.Volume, fadeInTime)
				end

				-- When the song ends, either repeat it or shuffle the folder it was a part of
				song.Ended:Wait()
				-- print(song, " has ended")
				if script.Parent.CurrentSong.Value == song then
					if repeatBool and toShuffle == nil then
						MusicPlayer.playSong(folderName, songName, nil, repeatBool)
					elseif toShuffle and musicFolder:FindFirstChild(toShuffle) then
						print("Song over, starting shuffle")
						MusicPlayer.shuffle(toShuffle)
					end
				end
			end
		end
	end))
end


return MusicPlayer

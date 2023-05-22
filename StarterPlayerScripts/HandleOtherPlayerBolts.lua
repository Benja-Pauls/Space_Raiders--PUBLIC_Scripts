-- Because LocalController is disabled while MainMenu is open, this script allows other laser bolts to
-- still be visible on this client while they are not in-game

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local player = game.Players.LocalPlayer

local Constants = require(script.Parent.Parent:WaitForChild("Constants"))
local FIRE_DELAY = Constants.FIRE_DELAY
local BOLT_LIFE = Constants.BOLT_LIFE

local eventsFolder = game.ReplicatedStorage.Events
local fireWeaponsEvent = eventsFolder.FireWeapons
local getEquippedInfoEvent = eventsFolder.GetEquippedInfo

--[[
	Replicate visuals of projectile fired by another player
	
	@param startPos starting position of projectile fired
	@param direction rotation of fire projectile
]]
fireWeaponsEvent.OnClientEvent:Connect(function(direction, filteredPlayer)
	if filteredPlayer then
		local playerShip
		local notPlayer = false
		if filteredPlayer:IsA("Player") then
			playerShip = workspace.Ships:FindFirstChild(tostring(filteredPlayer.UserId) .. "'s Ship")
		else -- Sentry, Bot
			if filteredPlayer.Name == "Gun" then
				playerShip = filteredPlayer.Parent
			elseif string.match(filteredPlayer.Name, "Bot") then
				playerShip = filteredPlayer
			end
			notPlayer = true
		end
		
		if playerShip then
			for _,blaster in pairs (playerShip:GetChildren()) do
				coroutine.resume(coroutine.create(function()
					if (blaster.Name == "Blaster" and blaster:IsA("BasePart")) or blaster.Name == 'Gun' then
						local projectile
						if notPlayer then -- Sentry
							projectile = game.ReplicatedStorage.EquipData.Laser.Default:Clone()
							projectile.Color = playerShip.Neon.Color
							
							local particles = game.ReplicatedStorage.EquipData.Trails["Vaporwave Squares"].Laser:Clone()
							particles.Parent = projectile
							particles.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, projectile.Color), ColorSequenceKeypoint.new(1, projectile.Color)}
						else
							local equipData = getEquippedInfoEvent:InvokeServer(filteredPlayer)
							projectile = equipData[2]["Model"]:Clone()
							
							-- Add equipped effects
							local particles = equipData[4]["Folder"].Laser:Clone()
							particles.Parent = projectile
							projectile.Color = equipData[7]["Color"].Color
						end
						projectile.PointLight:Destroy()
						
						-- Provide visual behavior (hit reg is on server)
						projectile.Touched:Connect(function(hit)
							if hit:IsDescendantOf(workspace.Ships) then
								if string.match(hit.Name, "'s Hitbox") ~= nil and hit.Name ~= tostring(filteredPlayer) .. "'s Hitbox" then
									local hitPlayerUserId = string.gsub(hit.Name, "'s Hitbox", "")
									
									local hitPlayer
									if string.match(hit.Name, "Bot") then
										hitPlayer = workspace.Ships:FindFirstChild(hitPlayerUserId)
									else
										hitPlayer = Players:GetPlayerByUserId(hitPlayerUserId)
									end
									
									if hitPlayer and hitPlayer ~= filteredPlayer then
										Constants.boltExplosionEffect(projectile)	
									end
								end
							elseif hit.Name == 'Bounce' or hit.Name == "AsteroidBounce" then
								if not notPlayer or (notPlayer and not hit:IsDescendantOf(playerShip)) then
									Constants.boltExplosionEffect(projectile, true)
								end
							elseif hit.Name == "CrackedBounce" then
								if not notPlayer or (notPlayer and not hit:IsDescendantOf(playerShip)) then
									Constants.boltExplosionEffect(projectile)
								end
							end
						end)
						
						projectile.CanCollide = false
						projectile.Parent = workspace.Projectiles
						projectile.Position = blaster.Position
						SoundService:PlayLocalSound(projectile.Sound)
						projectile.Rotation = direction
						Debris:AddItem(projectile, BOLT_LIFE)

						Constants.speedManipulation(projectile, notPlayer)
					end
				end))
			end
		end
	end
end)

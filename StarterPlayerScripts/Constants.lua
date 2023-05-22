-- Module script for constants and utility functions used throughout Player's starter scripts
local getConstantsEvent = game.ReplicatedStorage.Events.GetConstants
local CONSTANTS = getConstantsEvent:InvokeServer()

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")


--[[
	Acceleration effect on laser bolt fired by player
	@param projectile The projectile being affected
	@param notPlayer True if not fired by a player (fired from sentry)
]]
function CONSTANTS.speedManipulation(projectile, notPlayer)
	if not notPlayer then
		projectile.VectorForce.Force = Vector3.new(0, 0, -5000)

		-- This may have to be tweaked more
		wait(.075)
		if projectile:FindFirstChild("VectorForce") then -- Projectile may no longer exist
			projectile.VectorForce.Force = Vector3.new(0,0,0)
			wait(CONSTANTS.FIRE_DELAY)
		end
	else
		projectile.VectorForce.Force = Vector3.new(0, 0, -3000)
		wait(.075)
		if projectile:FindFirstChild("VectorForce") then -- Projectile may no longer exist
			projectile.VectorForce.Force = Vector3.new(0,0,0)
			wait(CONSTANTS.FIRE_DELAY)
		end
	end
end

--[[
	Produce explosion after bolt has hit something
	@param projectile  The physical projectile object
	@param hitWall: True if the laser hit a wall rather than another player hitbox
]]
function CONSTANTS.boltExplosionEffect(projectile, hitWall)
	local finalBoltPosition = projectile.Position
	
	-- Particle effects
	local explosion = game.ReplicatedStorage.Effects.LaserBoltExplosion:Clone()
	explosion.Position = finalBoltPosition
	explosion.Parent = workspace
	Debris:AddItem(explosion, 1.75)
	local projectileColor = projectile.Color
	explosion.ParticleEmitter.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, projectileColor), ColorSequenceKeypoint.new(1, projectileColor)}
	projectile:Destroy()

	-- Sound Effect
	if hitWall then
		SoundService:PlayLocalSound(explosion.LaserHit)
	else
		SoundService:PlayLocalSound(explosion.LaserCollide)
	end

	wait(.15)
	explosion.ParticleEmitter.Enabled = false
	wait(1.5)
	explosion:Destroy()
end

--[[
	Simplify a number to be displayed in decimal form
	@param num  Number to be simplified
	@return  Simplified text-version of the passed-in number
]]
function CONSTANTS.simplifyNumber(num)
	local x = tostring(num)

	if #x>=10 then
		local important = (#x-9)
		return x:sub(0,(important)).."."..(x:sub(#x-7,(#x-7))).."B"
	elseif #x>=7 then
		local important = (#x-6)
		return x:sub(0,(important)).."."..(x:sub(#x-5,(#x-5))).."M"
	elseif #x>=4 then
		local important = (#x-3)
		return x:sub(0,(important)).."."..(x:sub(#x-2,(#x-2)))..(x:sub(#x-1,(#x-1))) .. "K"
	else
		return num
	end
end

--[[
	Determine if values are within margin of error
]]
function CONSTANTS.withinMargin(value1, value2, margin)
	if value1 + margin >= value2 and value1 - margin <= value2 then
		return true
	else
		return false
	end
end

return CONSTANTS

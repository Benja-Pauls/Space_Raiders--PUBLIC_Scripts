local Debris = game:GetService("Debris")

local gun = script.Parent:WaitForChild("Gun")
local fireWeaponsServerEvent = game.ServerStorage.ServerEvents.FireWeaponsServer

while gun do
	wait(1.25)
	script.Parent.ShootSound:Play()
	
	-- Must send from clients since laggy if fired from server
	for _,player in pairs (game.Players:GetChildren()) do
		fireWeaponsServerEvent:Fire(gun, gun.Position, gun.Rotation)
	end
end










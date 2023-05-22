local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local camera = game.Workspace.CurrentCamera
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local playerShip = game.Workspace.Ships:WaitForChild(tostring(player.UserId) .. "'s Ship")

-- FANCY CAMERA MOVEMENT WITH WEIGHTYNESS, SEEMS TO LAG CAMERA SOMETIMES
--local subject = playerShip.CameraSubject
--local WEIGHT = 1
-- Move what camera points to for "Weighty" camera movement
--RunService:BindToRenderStep('UpdateSubject', Enum.RenderPriority.Camera.Value, function()
	--subject.Position = subject.Position:Lerp(playerShip.Position, 1/WEIGHT)
--end)


-- Set Camera above part
local height
camera.CameraType = "Scriptable"
camera.CameraSubject = playerShip
RunService:BindToRenderStep('Camera', Enum.RenderPriority.Camera.Value, function()
	height = player.CameraDistance.Value

	-- Move camera with object
	local cFrameInfo = CFrame.new(0, height, 0) * playerShip.CFrame*CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))
	camera.CFrame = cFrameInfo
	
	-- Lock Z-Axis camera to not rotate with ship
	local x,y,z = cFrameInfo:ToOrientation()
	camera.CFrame *= CFrame.Angles(0, 0, -y)
end)





-- TODO:
-- Satisfying camera movement (like it tries to keep going another direction)
-- Prevent camera from glitching when object runs into something


-- Camera Manipulation:
-- https://www.bing.com/videos/search?q=how+to+manipulate+the+camera+in+roblox&docid=608051001486674455&mid=2BB0C583AD1AB131E2DD2BB0C583AD1AB131E2DD&view=detail&FORM=VIRE

-- WASD Part
-- https://devforum.roblox.com/t/moving-a-part-with-w-a-s-d/630343

-- Hidden Devs Side Hustle:
-- https://discord.com/invite/hd
-- Have goodish money, don't really need sidehustle, but this could be where I
-- hire/get to know people

-- I need to start smaller and work my way up. I am capable of realeasing an amazing game as my first
-- but I need more experience with releasing games
	







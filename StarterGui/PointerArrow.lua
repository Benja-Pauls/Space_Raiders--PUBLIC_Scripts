local PointerArrow = {}
local pointerArrowsGui = script.Parent.PointerArrows

--[[
	Depending on visibility of X symbol, change visibility of player's pointerArrow
	@param pointerArrow  Physical pointer arrow
	@param button  Button to invis pointer arrow
	@param display  Bool if signifying immediate choice
]]
local function manageArrowVisibility(pointerArrow, button, display)
	if button and button:FindFirstChild("TextButton") then
		local x = button.TextButton.X
		if display == nil then
			display = x.Visible
		end
		if display then
			pointerArrow.PointerArrow.Transparency = 0.2
			x.Visible = false
			pointerArrow.PointerArrow.SurfaceGui.Enabled = true
		else
			pointerArrow.PointerArrow.Transparency = 1
			x.Visible = true
			pointerArrow.PointerArrow.SurfaceGui.Enabled = false
		end
	end
end

--[[
	Make new button for pointer arrow to be toggleable by player
	@param player  Used to access InvisRef of particular arrow
	@param pointerArrow  Pointer arrow that button will deal with
	@param image  Image that will go on button
	@label label  Used to identify button
]]
local function createtArrowButton(player, pointerArrow, image, label)
	local button = game.ReplicatedStorage.GuiElements.PointerButton:Clone()
	local numButtons = #pointerArrowsGui:GetChildren()
	local buttonJump = 0.057
	
	button.Parent = pointerArrowsGui
	button.TextButton.ImageLabel.Image = image
	button.Name = label .. "PointerArrow"
	button.Position = UDim2.new(0.033 + (0.057 * numButtons), 0, 0.94, 0)
	
	-- Determine location based on number of other buttons
	--[[
	if button.Name ~= 'CenterPointerArrow' and pointerArrowsGui:FindFirstChild("CenterPointerArrow") then
		pointerArrowsGui.CenterPointerArrow.Position = UDim2.new(.033, 0, .94, 0)
		button.Position = UDim2.new(.09, 0, .94, 0)
		button.TextButton.TextLabel.Text = 'Best'
	else
		button.Position = UDim2.new(.033, 0, .94, 0)
	end
	]]
	
	button.Activated:Connect(function()
		manageArrowVisibility(pointerArrow, button)
	end)
	button.TextButton.Activated:Connect(function()
		manageArrowVisibility(pointerArrow, button)
	end)
	button.TextButton.X:GetPropertyChangedSignal("Visible"):Connect(function()
		local ref = script:FindFirstChild(label .. "InvisRef")
		if ref then ref.Value = button.TextButton.X.Visible end
	end)
end

--[[
	Instantiate a new PointerArrow object
	@param player  Reference to store InvisRef of new arrows
	@param playerShip  PlayerShip the arrow will be parented onto
	@param label  String representing text that will appear on arrow's text label
	@param color  Color value for arrow
	@param image  Image of arrow that will go on button
]]
function PointerArrow.new(player, playerShip, label, color, image)
	local self = game.ReplicatedStorage.Effects.PointerArrow:Clone()
	self.PointerArrow.Position += Vector3.new(0, 0, -(20+playerShip:WaitForChild("GUI_Display").Distance.Value))
	
	local weld = Instance.new("WeldConstraint", self.PointerArrow)
	weld.Part0 = self.PointerArrow; weld.Part1 = self.Center
	
	self.Parent = playerShip
	self.Name = label .. "PointerArrow"
	self.Center.CFrame = playerShip.CFrame
	self.PointerArrow.SurfaceGui.Frame.TextLabel.Text = label
	self.PointerArrow.Color = color
	self.PointerArrow.Transparency = 0.2
	
	if image then
		createtArrowButton(player, self, image, label)
	end
	if script:FindFirstChild(label .. "InvisRef") then		
		manageArrowVisibility(self, pointerArrowsGui:FindFirstChild(label .. "PointerArrow"), not script:FindFirstChild(label .. "InvisRef").Value)
	else
		local newRef = Instance.new("BoolValue", script)
		newRef.Name = label .. "InvisRef"
	end

	return self
end

--[[
	Destroy the button and physical arrow
	@param arrow  Speicified if only one arrow should be destroyed
	@param label  Label to use to identify arrow
]]
function PointerArrow.destroy(arrow, label)
	if arrow then	
		-- Destroy button and reposition others if possible
		if pointerArrowsGui:FindFirstChild(label .. "PointerArrow") then
			pointerArrowsGui:FindFirstChild(label .. "PointerArrow"):Destroy()
			arrow:Destroy()
		end
	else -- Destroy buttons, ship has been destroyed
		for _,button in pairs (pointerArrowsGui:GetChildren()) do
			button:Destroy()
		end
	end
end


return PointerArrow

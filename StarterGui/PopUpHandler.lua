-- Create this as a wide use-case module script that could be used in other games as well (built off popUpHandler in Testing Server from 2021)

local PopUpHandler = {}
local CurrentPopUpTweens = {}
local TweenService = game:GetService("TweenService")

local popUpsGui = script.Parent

local JUMP_DISTANCE = 0.014
local MOVE_POPUP_TWEENINFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local X_POSITION = 0.99
local Y_POSITION = 0.0975
local DEFAULT_LIFETIME = 5



--[[
	Counts the number of popUps currently in the popUpsGui
]]
local function getPopUpCount()
	local count = 0
	for _,popUp in pairs (popUpsGui:GetChildren()) do
		if string.match(popUp.Name, "PopUp") and popUp:IsA("TextButton") then
			count += 1
		end
	end
	return count
end

--[[
	Creates the lifespan of a popup, moving off screen at the end of its lifetime
	@param popUp  The popUp that we are now beginning to count down
	@param expireTime  Specified if custom amount of time that popUp should last for. Otherwise default amount
]]
local function countDownPopUp(popUp, expireTime)
	local timer = popUp.TimeLeft
	timer.Value = 0 -- reseting
	
	if expireTime == nil then
		expireTime = DEFAULT_LIFETIME
	end
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,expireTime do
			wait(1)
			
			if sec == timer.Value + 1 then -- Still on this "cycle"
				timer.Value = sec
				if sec == expireTime then -- Make this popup disappear
					if popUp.Name ~= "Expired" then
						popUp.Name = "Expired"
						
						-- Hide the popup
						local currentXSize = popUp.Size.X.Scale
						local currentYPos = popUp.Position.Y.Scale
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						local hideTween = TweenService:Create(popUp, tweenInfo, {Position = UDim2.new(1 + currentXSize, 0, currentYPos, 0)})
						hideTween:Play()
						
						-- If any popups are below this popup, move them up
						if popUp.Parent == popUpsGui then
							local popUpNumber = getPopUpCount()
							
							for _,belowPopUp in pairs (popUpsGui:GetChildren()) do
								if belowPopUp:IsA("TextButton") and string.match(belowPopUp.Name, "PopUp") then
									local p = string.gsub(belowPopUp.Name, "PopUp", "")
									p = tonumber(p)

									if p > popUpNumber then
										popUp.Name = "PopUp" .. tostring(p - 1)
										local yPos = belowPopUp.Position.Y.Scale - popUp.Size.Y.Scale - JUMP_DISTANCE
										local moveUpTween = TweenService:Create(belowPopUp, MOVE_POPUP_TWEENINFO, {Position = UDim2.new(X_POSITION, 0, yPos, 0)})
										moveUpTween:Play()
									end
								end
							end
						end
						
						-- Destroy the popup
						wait(0.3)
						popUp:Destroy()
					end
				end
			end
		end
	end))
end

--[[
	Create a new pop up to be displayed to the player
	@param newPopUp  General popup that will be used'
	@param text1  String that will be text for Text1 in popup (if it has Text1 object)
]]
function PopUpHandler.createPopUp(newPopUp, text1)
	if newPopUp:IsA("TextButton") then
		newPopUp = newPopUp:Clone()
		newPopUp.Parent = popUpsGui
		script.NewAchievement:Play()
		
		-- Move all other popups down, renaming them as well
		local popUpCount = getPopUpCount()
		for p = 1,popUpCount do
			local popUp = popUpsGui:FindFirstChild("PopUp" .. tostring(p))
			if popUp then
				popUp.Name = "PopUp" .. tostring(p + 1)
				
				-- Getting sizing for how far this particular popUp has to be from the top of the screen
				local sizeSum = newPopUp.Size.Y.Scale
				if p >= 2 then -- There is no PopUp1 anymore
					for i = 2,p do -- Depending on which popup we're on, put at certain y-distance from top of screen
						local iPopUp = popUpsGui:FindFirstChild("PopUp" .. tostring(i))
						if iPopUp then
							sizeSum += iPopUp.Size.Y.Scale
						end
					end
				end
				TweenService:Create(popUp, MOVE_POPUP_TWEENINFO, {Position = UDim2.new(X_POSITION, 0, sizeSum + JUMP_DISTANCE*p + Y_POSITION, 0)}):Play()
			end
		end
		
		-- Insert the new pop up and begin its lifespan
		newPopUp.Name = "PopUp1"
		newPopUp.Position = UDim2.new(1 + newPopUp.Size.X.Scale, 0, Y_POSITION, 0)
		newPopUp.Text1.Text = text1
		TweenService:Create(newPopUp, MOVE_POPUP_TWEENINFO, {Position = UDim2.new(X_POSITION, 0, Y_POSITION, 0)}):Play()
		countDownPopUp(newPopUp)
		
		-- Advanced popups are then those that you can click and they open a menu (would be in the other games, wouldn't really fit in Space Raiders)
		--**
	end
end




return PopUpHandler

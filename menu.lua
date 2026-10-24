-- VlexWare MM2 (MM2 menu only)

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")

local TweenService = game:GetService("TweenService")

local Workspace = game:GetService("Workspace")

local UserInputService = game:GetService("UserInputService")

local RunService = game:GetService("RunService")

local TeleportService = game:GetService("TeleportService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction created by ServerScriptService.VlexServerHopService.
-- The server fetches the public server list for us (HTTP is server-only).
local serverListRemote = ReplicatedStorage:WaitForChild("VlexServerList", 10)

local function create(className, props, parent)
	local inst = Instance.new(className)
	for prop, value in pairs(props) do
		inst[prop] = value
	end
	inst.Parent = parent
	return inst

end

local function makeDraggable(handle, ...)
	local frames = {...}
	local dragging = false
	local dragStart
	local startPositions = {}
	local DRAG_THRESHOLD = 8
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPositions = {}
			for i, frame in ipairs(frames) do
				startPositions[i] = frame.Position
			end
			end
		end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude < DRAG_THRESHOLD then return end
			for i, frame in ipairs(frames) do
				frame.Position = UDim2.new(
					startPositions[i].X.Scale, startPositions[i].X.Offset + delta.X,
					startPositions[i].Y.Scale, startPositions[i].Y.Offset + delta.Y
				)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

end

local vlexWare = create("ScreenGui", {
	Name = "VlexWare",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

}, playerGui)

local notifyGui = nil
local notifyTween = nil
local function notify(title, message)
	if not notifyGui or not notifyGui.Parent then
		notifyGui = create("TextLabel", {
			Name = "VlexNotify",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(0, 420, 0, 30),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			Font = Enum.Font.SourceSansBold,
			ZIndex = 100,
		}, vlexWare)
		create("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}, notifyGui)
	end
	notifyGui.Text = "[" .. tostring(title) .. "] " .. tostring(message)
	notifyGui.TextTransparency = 0
	notifyGui.BackgroundTransparency = 0.35
	if notifyTween then
		notifyTween:Cancel()
		notifyTween = nil
	end
	notifyTween = TweenService:Create(notifyGui, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.5), {TextTransparency = 1, BackgroundTransparency = 1})
	notifyTween:Play()
end

-- ===== SERVER HOP =====
local PLACE_ID = game.PlaceId

local function serverHop()
	if RunService:IsStudio() then
		notify("MM2", "Server hop only works in a published game")
		return
	end
	-- Ask the server to fetch the public server list (HTTP requests are
	-- server-only, so a LocalScript can never call HttpService:GetAsync itself)
	local candidates = nil
	if serverListRemote then
		local ok, result = pcall(function()
			return serverListRemote:InvokeServer()
		end)
		if ok and type(result) == "table" then
			candidates = result
		end
	end
	if candidates and #candidates > 0 then
		local target = candidates[math.random(#candidates)]
		notify("MM2", "Joining a new server...")
		TeleportService:TeleportToPlaceInstance(PLACE_ID, target.id, localPlayer)
		return
	end
	notify("MM2", "No other servers found - rejoining")
	-- Fallback: rejoin the same place
	TeleportService:Teleport(PLACE_ID, localPlayer)
end

-- ===== AUTO SERVER HOP (when server has less than 4 players) =====
local MIN_PLAYERS = 4
local hopCheckBusy = false
local mm2AutoHop = true
local autoHopButton = nil

task.spawn(function()
	while true do
		task.wait(5)
		if RunService:IsStudio() then continue end
		if hopCheckBusy then continue end
		local playerCount = #Players:GetPlayers()
		if autoHopButton then
			autoHopButton.Text = (mm2AutoHop and "Auto Hop: ON" or "Auto Hop: OFF")
				.. " (" .. playerCount .. " playing)"
		end
		if mm2AutoHop and playerCount < MIN_PLAYERS then
			hopCheckBusy = true
			notify("MM2", "Server has less than " .. MIN_PLAYERS .. " players - hopping")
			serverHop()
			hopCheckBusy = false
		end
	end
end)

-- ===== KICK PROTECTION (best effort rejoin) =====
-- When the client is about to be kicked, immediately teleport back into the
-- game. This races against the kick disconnecting us, so it may not always win.
-- The script re-executes automatically after rejoining because it lives in
-- StarterPlayerScripts, so no external re-execution is needed.
pcall(function()
	localPlayer.OnClientKick:Connect(function()
		TeleportService:Teleport(PLACE_ID, localPlayer)
	end)
end)

local mm2Gui = nil

local mm2Title = nil

local mm2CoinFarming = true

local coinTween = nil

local coinHighlight = nil

local mm2Keybind = nil

local mm2CoinSpeed = 110

local mm2GunFarming = false

local mm2AlwaysEvadeKnife = false

local mm2CoinDelay = 0.5

local gunTween = nil

local gunHighlight = nil

local stopGunFarm 

local function createMM2Gui()
	mm2Title = create("TextLabel", {
		Name = "mm2title",
		Size = UDim2.new(0, 283, 0, 50),
		Position = UDim2.new(0.169663802, 0, 0.195005938, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 2,
		Text = "VlexWare MM2",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
		Active = true,
		Visible = false,
	}, vlexWare)
	create("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}, mm2Title)
	mm2Gui = create("ScrollingFrame", {
		Name = "mm2",
		Size = UDim2.new(0, 283, 0, 230),
		Position = UDim2.new(0.169663802, 0, 0.254458964, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 1.7, 0),
		ScrollBarThickness = 12,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ClipsDescendants = true,
		Visible = false,
	}, vlexWare)
	create("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}, mm2Gui)
	makeDraggable(mm2Title, mm2Title, mm2Gui)
	makeDraggable(mm2Gui, mm2Title, mm2Gui)
	local mm2Close = create("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 25, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "X",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local coinFButton = create("TextButton", {
		Name = "CoinF",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.0755053535, 0),
		BackgroundColor3 = Color3.fromRGB(0, 170, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Stop Coin Farm",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local getGButton = create("TextButton", {
		Name = "GetG",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.252080858, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Get Gun",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local gunEspButton = create("TextButton", {
		Name = "GunESP",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.38, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Role ESP: OFF",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local gunDropButton = create("TextButton", {
		Name = "GunDropESP",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.95, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "GunDrop Highlight: OFF",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local keybindBox = create("TextBox", {
		Name = "Keybind",
		Size = UDim2.new(0, 46, 0, 32),
		Position = UDim2.new(0, 0, 0.49, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		PlaceholderText = "Keybind",
		PlaceholderColor3 = Color3.new(0, 0, 0),
		Text = "",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
		Font = Enum.Font.SourceSans,
		ClearTextOnFocus = true,
	}, mm2Gui)
	local keybindSetButton = create("TextButton", {
		Name = "keybindSet",
		Size = UDim2.new(0, 52, 0, 32),
		Position = UDim2.new(0.183745578, 0, 0.49, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Text = "SET",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local speedLabel = create("TextLabel", {
		Name = "SpeedLabel",
		Size = UDim2.new(0, 100, 0, 32),
		Position = UDim2.new(0, 0, 0.61, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 1,
		Text = "Speed:",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 16,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local speedBox = create("TextBox", {
		Name = "SpeedBox",
		Size = UDim2.new(0, 80, 0, 32),
		Position = UDim2.new(0.38, 0, 0.61, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		PlaceholderText = "30",
		PlaceholderColor3 = Color3.new(0, 0, 0),
		Text = "30",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
		Font = Enum.Font.SourceSans,
		ClearTextOnFocus = false,
	}, mm2Gui)
	speedBox.FocusLost:Connect(function()
		local num = tonumber(string.trim(speedBox.Text))
		if num and num > 0 then
			mm2CoinSpeed = num
			notify("MM2", "Coin speed set to " .. num)
		else
			speedBox.Text = tostring(mm2CoinSpeed)
			notify("MM2", "Invalid speed value")
		end
	end)
	local delayLabel = create("TextLabel", {
		Name = "DelayLabel",
		Size = UDim2.new(0, 100, 0, 32),
		Position = UDim2.new(0, 0, 0.665, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 1,
		Text = "Delay:",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 16,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	local delayBox = create("TextBox", {
		Name = "DelayBox",
		Size = UDim2.new(0, 80, 0, 32),
		Position = UDim2.new(0.38, 0, 0.665, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		PlaceholderText = "0.05",
		PlaceholderColor3 = Color3.new(0, 0, 0),
		Text = "0.05",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
		Font = Enum.Font.SourceSans,
		ClearTextOnFocus = false,
	}, mm2Gui)
	delayBox.FocusLost:Connect(function()
		local num = tonumber(string.trim(delayBox.Text))
		if num and num >= 0 then
			mm2CoinDelay = num
			notify("MM2", "Pickup delay set to " .. num)
		else
			delayBox.Text = tostring(mm2CoinDelay)
			notify("MM2", "Invalid delay value")
		end
	end)
	local alwaysEvadeButton = create("TextButton", {
		Name = "AlwaysEvade",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.72, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Always Evade Knife: OFF",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	alwaysEvadeButton.MouseButton1Click:Connect(function()
		mm2AlwaysEvadeKnife = not mm2AlwaysEvadeKnife
		if mm2AlwaysEvadeKnife then
			alwaysEvadeButton.Text = "Always Evade Knife: ON"
			alwaysEvadeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "Always evading knife")
		else
			alwaysEvadeButton.Text = "Always Evade Knife: OFF"
			alwaysEvadeButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
			notify("MM2", "Role-aware evasion")
		end
	end)
	local autoHopToggleButton = create("TextButton", {
		Name = "AutoHopToggle",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 0.9, 0),
		BackgroundColor3 = Color3.fromRGB(0, 170, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Auto Hop: ON",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	autoHopButton = autoHopToggleButton
	autoHopToggleButton.MouseButton1Click:Connect(function()
		mm2AutoHop = not mm2AutoHop
		if mm2AutoHop then
			autoHopToggleButton.Text = "Auto Hop: ON (" .. #Players:GetPlayers() .. " playing)"
			autoHopToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "Auto server hop enabled (hops below " .. MIN_PLAYERS .. " players)")
		else
			autoHopToggleButton.Text = "Auto Hop: OFF (" .. #Players:GetPlayers() .. " playing)"
			autoHopToggleButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
			notify("MM2", "Auto server hop disabled")
		end
	end)
	local serverHopButton = create("TextButton", {
		Name = "ServerHop",
		Size = UDim2.new(0, 272, 0, 50),
		Position = UDim2.new(0, 0, 1.08, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 1,
		Text = "Server Hop",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.SourceSansBold,
	}, mm2Gui)
	serverHopButton.MouseButton1Click:Connect(serverHop)
	create("TextLabel", {
		Name = "Footer",
		Size = UDim2.new(0, 272, 0, 34),
		Position = UDim2.new(0, 0, 1.32, 0),
		BackgroundColor3 = Color3.fromRGB(85, 0, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = "Thanks for using vlexware :)",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
		Font = Enum.Font.SourceSans,
	}, mm2Gui)
	mm2Close.MouseButton1Click:Connect(function()
		mm2Gui.Visible = false
		mm2Title.Visible = false
	end)
	local coinFarmPlatform = nil
	local platformHeartbeat = nil
	local platformFloorY = nil
	local function stopCoinFarm()
		mm2CoinFarming = false
		if coinTween then
			coinTween:Cancel()
			coinTween = nil
		end
		if coinHighlight then
			coinHighlight:Destroy()
			coinHighlight = nil
		end
		local character = localPlayer.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Anchored = false end
		end
		if platformHeartbeat then
			platformHeartbeat:Disconnect()
			platformHeartbeat = nil
		end
		if coinFarmPlatform and coinFarmPlatform.Parent then
			coinFarmPlatform:Destroy()
		end
		coinFarmPlatform = nil
		coinFButton.Text = "Auto Coin Farm"
		coinFButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
	end
	local visitedCoins = {}
	localPlayer.CharacterAdded:Connect(function()
		if coinTween then
			coinTween:Cancel()
			coinTween = nil
		end
		if coinHighlight then
			coinHighlight:Destroy()
			coinHighlight = nil
		end
		visitedCoins = {}
		platformFloorY = nil
		if coinFarmPlatform and coinFarmPlatform.Parent then
			coinFarmPlatform:Destroy()
		end
		coinFarmPlatform = nil
		if platformHeartbeat then
			platformHeartbeat:Disconnect()
			platformHeartbeat = nil
		end
	end)
	local function playerHasWeapon(player, weaponName)
		local char = player.Character
		if char and char:FindFirstChild(weaponName) then
			return true
		end
		local backpack = player:FindFirstChild("Backpack")
		if backpack and backpack:FindFirstChild(weaponName) then
			return true
		end
		return false
	end
	local function getThreatPosition()
		-- If "always evade knife" is on, always avoid the knife holder (murderer)
		local threatWeapon = "Knife"
		if not mm2AlwaysEvadeKnife then
			local localHasKnife = playerHasWeapon(localPlayer, "Knife")
			threatWeapon = localHasKnife and "Gun" or "Knife"
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				local char = player.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
						if playerHasWeapon(player, threatWeapon) then
							local mHrp = char:FindFirstChild("HumanoidRootPart")
							if mHrp then
								return mHrp.Position
							end
						end
					end
				end
			end
		end
		return nil
	end
	local safeDistance = 50
	-- Tracks how long the map has had no coins while farming
	local NO_COINS_RESET_TIME = 20
	local noCoinsElapsed = 0
	task.spawn(function()
		while true do
			local character = localPlayer.Character
			if not character then
				task.wait(0.5)
				continue
			end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				task.wait(0.5)
				continue
			end
			if mm2CoinFarming then
				if not coinFarmPlatform or not coinFarmPlatform.Parent then
					coinFarmPlatform = Instance.new("Part")
					coinFarmPlatform.Name = "VlexCoinFarmPlatform"
					coinFarmPlatform.Size = Vector3.new(8, 1, 8)
					coinFarmPlatform.Transparency = 1
					coinFarmPlatform.CanCollide = true
					coinFarmPlatform.CanTouch = false
					coinFarmPlatform.CanQuery = false
					coinFarmPlatform.Anchored = true
					coinFarmPlatform.Massless = true
					coinFarmPlatform.Parent = Workspace
					if platformHeartbeat then
						platformHeartbeat:Disconnect()
						end
					local initChar = localPlayer.Character
					local initHrp = initChar and initChar:FindFirstChild("HumanoidRootPart")
					platformFloorY = initHrp and (initHrp.Position.Y - 3.5) or 0
					platformHeartbeat = RunService.Heartbeat:Connect(function()
						if not mm2CoinFarming or not coinFarmPlatform or not coinFarmPlatform.Parent then
								return
						end
							local char = localPlayer.Character
							if char then
								local h = char:FindFirstChild("HumanoidRootPart")
								if h then
									if h.Anchored then
										platformFloorY = h.Position.Y - 3.5
									else
										local targetY = h.Position.Y - 3.5
										if targetY > platformFloorY then
											platformFloorY = targetY
										end
									end
									coinFarmPlatform.CFrame = CFrame.new(h.Position.X, platformFloorY, h.Position.Z)
								end
							end
						end)
				end
			else
				if coinFarmPlatform and coinFarmPlatform.Parent then
					coinFarmPlatform:Destroy()
				end
				coinFarmPlatform = nil
				if platformHeartbeat then
					platformHeartbeat:Disconnect()
					platformHeartbeat = nil
				end
			end
			local allCoins = {}
			for _, descendant in ipairs(Workspace:GetDescendants()) do
				if descendant.Name == "CoinVisual" and (descendant:IsA("BasePart") or descendant:IsA("Model")) then
					table.insert(allCoins, descendant)
				end
			end
			if #allCoins == 0 then
				visitedCoins = {}
				if coinHighlight then
					coinHighlight:Destroy()
					coinHighlight = nil
				end
				-- No coins on the map: count up and reset the character after
				-- NO_COINS_RESET_TIME seconds (round likely ended without new coins)
				if mm2CoinFarming then
					noCoinsElapsed += 0.1
					if noCoinsElapsed >= NO_COINS_RESET_TIME then
						noCoinsElapsed = 0
						notify("MM2", "No coins for " .. NO_COINS_RESET_TIME .. "s - resetting character")
						local char = localPlayer.Character
						local humanoid = char and char:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							humanoid.Health = 0
							humanoid:ChangeState(Enum.HumanoidStateType.Dead)
						end
					end
				else
					noCoinsElapsed = 0
				end
				task.wait(0.1)
				continue
			end
			noCoinsElapsed = 0
			for coin in pairs(visitedCoins) do
				if not coin.Parent then
					visitedCoins[coin] = nil
				end
			end
			if not mm2CoinFarming then
				task.wait(0.2)
				continue
			end
			local murdererPos = getThreatPosition()
			local targetCoin = nil
			local nearestDist = math.huge
			for _, coin in ipairs(allCoins) do
				if not visitedCoins[coin] and coin.Parent then
					local coinPos
					if coin:IsA("BasePart") then
						coinPos = coin.Position
					elseif coin:IsA("Model") then
						coinPos = coin:GetPivot().Position
					end
					if coinPos then
						local isSafe = true
						if murdererPos then
							isSafe = (coinPos - murdererPos).Magnitude > safeDistance
						end
						if isSafe then
							local dist = (coinPos - hrp.Position).Magnitude
							if dist < nearestDist then
								nearestDist = dist
								targetCoin = coin
							end
						end
					end
					end
			end
			if not targetCoin then
				visitedCoins = {}
				for _, coin in ipairs(allCoins) do
					if coin.Parent then
						local coinPos
					if coin:IsA("BasePart") then
							coinPos = coin.Position
						elseif coin:IsA("Model") then
							coinPos = coin:GetPivot().Position
						end
					if coinPos then
							local isSafe = true
							if murdererPos then
								isSafe = (coinPos - murdererPos).Magnitude > safeDistance
							end
							if isSafe then
								local dist = (coinPos - hrp.Position).Magnitude
								if dist < nearestDist then
									nearestDist = dist
									targetCoin = coin
								end
							end
						end
					end
				end
				if not targetCoin then
					task.wait(0.1)
					continue
				end
			end
			if not targetCoin.Parent then
				visitedCoins[targetCoin] = nil
				task.wait()
				continue
			end
			if coinHighlight then
				coinHighlight:Destroy()
			end
			coinHighlight = Instance.new("Highlight")
			coinHighlight.Name = "VlexCoinHighlight"
			coinHighlight.FillColor = Color3.fromRGB(255, 215, 0)
			coinHighlight.FillTransparency = 0.3
			coinHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
			coinHighlight.OutlineTransparency = 0
			coinHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			coinHighlight.Adornee = targetCoin
			coinHighlight.Parent = targetCoin
			local coinCFrame
			if targetCoin:IsA("BasePart") then
				coinCFrame = targetCoin.CFrame
			elseif targetCoin:IsA("Model") then
				coinCFrame = targetCoin:GetPivot()
			else
				if coinHighlight then
					coinHighlight:Destroy()
					coinHighlight = nil
				end
				task.wait(0.5)
				continue
			end
			local targetPos = coinCFrame.Position - Vector3.new(0, 2, 0)
			local _, currentYaw = hrp.CFrame:ToEulerAnglesYXZ()
			local finalCFrame = CFrame.new(targetPos) * CFrame.Angles(0, currentYaw, 0)
			local distance = (hrp.CFrame.Position - targetPos).Magnitude
			if not targetCoin.Parent then
				-- Coin vanished between the scan and the move - skip it
				visitedCoins[targetCoin] = true
				if coinHighlight then
					coinHighlight:Destroy()
					coinHighlight = nil
				end
				task.wait()
				continue
			end
			hrp.Anchored = true
			if distance > 1000 then
				-- Coin is over 1000 studs away: teleport directly to it
				hrp.CFrame = finalCFrame
			else
				local tweenDuration = math.max(0.1, distance / mm2CoinSpeed)
				if coinTween then
						coinTween:Cancel()
					end
				coinTween = TweenService:Create(hrp, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear), {CFrame = finalCFrame})
				coinTween:Play()
				local tweenCompleted = false
				local tweenConn = coinTween.Completed:Connect(function()
					tweenCompleted = true
					end)
				local tweenTimeout = 0
				local tweenMaxWait = tweenDuration + 2
				while not tweenCompleted and mm2CoinFarming and tweenTimeout < tweenMaxWait do
					if not targetCoin.Parent then
						-- Coin disappeared (round ended) - stop tweening to nothing
						if coinTween then
							coinTween:Cancel()
						end
						break
					end
					task.wait()
					tweenTimeout += 0.016
				end
				tweenConn:Disconnect()
			end
			local currentChar = localPlayer.Character
			local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
			if not currentChar or not currentHrp or currentHrp ~= hrp then
				if coinHighlight then
					coinHighlight:Destroy()
					coinHighlight = nil
				end
				task.wait(0.3)
				continue
			end
			if not mm2CoinFarming then
				if coinHighlight then
					coinHighlight:Destroy()
					coinHighlight = nil
				end
				continue
			end
			local mPos = getThreatPosition()
			if mPos and (hrp.Position - mPos).Magnitude < safeDistance then
				visitedCoins[targetCoin] = true
				if coinHighlight then
					coinHighlight:Destroy()
				coinHighlight = nil
				end
				if mm2CoinFarming then
					task.wait()
				end
				continue
			end
			hrp.Anchored = false
			local pickupTimeout = 5
			local elapsed = 0
			local movedUp = false
			while targetCoin.Parent and mm2CoinFarming and elapsed < pickupTimeout do
				local mPos2 = getThreatPosition()
				if mPos2 and (hrp.Position - mPos2).Magnitude < safeDistance then
					break
				end
				task.wait()
				elapsed += 0.016
					if elapsed >= 1.5 and not movedUp then
						movedUp = true
						local nudgeHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
						if nudgeHrp and nudgeHrp.Parent then
							nudgeHrp.CFrame = nudgeHrp.CFrame + Vector3.new(0, 3, 0)
						end
					end
			end
			visitedCoins[targetCoin] = true
			if coinHighlight then
				coinHighlight:Destroy()
				coinHighlight = nil
			end
			if mm2CoinFarming then
				local freezeHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if freezeHrp and freezeHrp.Parent then
						freezeHrp.Anchored = true
					task.wait(mm2CoinDelay)
					freezeHrp.Anchored = false
				end
			end
		end
	end)
	coinFButton.MouseButton1Click:Connect(function()
		if mm2CoinFarming then
			stopCoinFarm()
			notify("MM2", "Coin Farm stopped")
		else
			local character = localPlayer.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			if stopGunFarm then stopGunFarm() end
			mm2CoinFarming = true
			coinFButton.Text = "Stop Coin Farm"
			coinFButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "Coin Farm started")
		end
	end)
	local gunEspActive = false
	local gunHighlights = {}
	local function stopGunEsp()
		gunEspActive = false
		for player, data in pairs(gunHighlights) do
			if data.highlight then data.highlight:Destroy() end
			if data.billboard then data.billboard:Destroy() end
		end
		gunHighlights = {}
		gunEspButton.Text = "Role ESP: OFF"
		gunEspButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
	end
	task.spawn(function()
		while true do
			if not gunEspActive then
				task.wait(0.5)
				continue
			end
			local foundPlayers = {}
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						local hasGun = character:FindFirstChild("Gun")
						local hasKnife = character:FindFirstChild("Knife")
						if not hasGun and not hasKnife then
							local backpack = player:FindFirstChild("Backpack")
							if backpack then
								hasGun = backpack:FindFirstChild("Gun")
								hasKnife = backpack:FindFirstChild("Knife")
							end
						end
						local hasWeapon = hasGun or hasKnife
						if hasWeapon then
							local isGun = hasGun ~= nil
							local espColor = isGun and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
							local labelText = isGun and (player.Name .. " [GUN]") or (player.Name .. " [KNIFE]")
							foundPlayers[player] = true
							local adornPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart")
							if not gunHighlights[player] then
								local highlight = Instance.new("Highlight")
								highlight.Name = "VlexGunESP"
								highlight.FillColor = espColor
								highlight.FillTransparency = 0.5
								highlight.OutlineColor = espColor
								highlight.OutlineTransparency = 0
								highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
								highlight.Adornee = character
								highlight.Parent = character
								local billboard = Instance.new("BillboardGui")
								billboard.Name = "VlexGunESPName"
								billboard.Size = UDim2.new(0, 200, 0, 30)
								billboard.StudsOffset = Vector3.new(0, 3, 0)
								billboard.AlwaysOnTop = true
								billboard.Adornee = adornPart
								billboard.Parent = character
								local nameLabel = Instance.new("TextLabel")
								nameLabel.Size = UDim2.new(1, 0, 1, 0)
								nameLabel.BackgroundTransparency = 1
								nameLabel.Text = labelText
								nameLabel.TextColor3 = espColor
								nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
								nameLabel.TextStrokeTransparency = 0
								nameLabel.TextScaled = true
								nameLabel.Font = Enum.Font.SourceSansBold
								nameLabel.Parent = billboard
								gunHighlights[player] = {highlight = highlight, billboard = billboard}
							else
								local data = gunHighlights[player]
								data.highlight.Adornee = character
								data.highlight.FillColor = espColor
								data.highlight.OutlineColor = espColor
								if data.billboard then
									data.billboard.Adornee = adornPart
									local label = data.billboard:FindFirstChildOfClass("TextLabel")
									if label then
										label.Text = labelText
										label.TextColor3 = espColor
									end
								end
							end
						end
					end
				end
			end
			for player, data in pairs(gunHighlights) do
				if not foundPlayers[player] then
					if data.highlight then data.highlight:Destroy() end
					if data.billboard then data.billboard:Destroy() end
					gunHighlights[player] = nil
			end
			end
			task.wait(0.5)
		end
	end)
	local function toggleGunEsp()
		if gunEspActive then
			stopGunEsp()
			notify("MM2", "Role ESP stopped")
		else
			gunEspActive = true
			gunEspButton.Text = "Role ESP: ON"
			gunEspButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "Role ESP started - showing names and roles")
		end
	end
	gunEspButton.MouseButton1Click:Connect(toggleGunEsp)
	stopGunFarm = function()
		mm2GunFarming = false
		if gunTween then
			gunTween:Cancel()
			gunTween = nil
		end
		if gunHighlight then
			gunHighlight:Destroy()
			gunHighlight = nil
		end
		local character = localPlayer.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Anchored = false end
		end
		getGButton.Text = "Get Gun"
		getGButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
	end
	task.spawn(function()
		while true do
			local character = localPlayer.Character
			if not character then
				task.wait(0.5)
				continue
			end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				task.wait(0.5)
				continue
			end
			if not mm2GunFarming then
				task.wait(0.2)
				continue
			end
			local hasGun = character:FindFirstChild("Gun")
			if not hasGun then
				local backpack = localPlayer:FindFirstChild("Backpack")
				if backpack then
					hasGun = backpack:FindFirstChild("Gun")
				end
			end
			if hasGun then
				stopGunFarm()
				notify("MM2", "Gun obtained!")
				continue
			end
			local targetObject = Workspace:FindFirstChild("GunDrop", true)
			if not targetObject or not targetObject.Parent then
				task.wait(0.5)
				continue
			end
			local targetCFrame
			if targetObject:IsA("BasePart") then
				targetCFrame = targetObject.CFrame
			elseif targetObject:IsA("Model") then
				targetCFrame = targetObject:GetPivot()
			else
				task.wait(0.5)
				continue
			end
			if gunHighlight then
				gunHighlight:Destroy()
			end
			gunHighlight = Instance.new("Highlight")
			gunHighlight.Name = "VlexGunHighlight"
			gunHighlight.FillColor = Color3.fromRGB(0, 0, 255)
			gunHighlight.FillTransparency = 0.3
			gunHighlight.OutlineColor = Color3.fromRGB(0, 100, 255)
			gunHighlight.OutlineTransparency = 0
			gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			gunHighlight.Adornee = targetObject
			gunHighlight.Parent = targetObject
			local targetPos = targetCFrame.Position - Vector3.new(0, 2, 0)
			local _, currentYaw = hrp.CFrame:ToEulerAnglesYXZ()
			local finalCFrame = CFrame.new(targetPos) * CFrame.Angles(0, currentYaw, 0)
			local distance = (hrp.CFrame.Position - targetPos).Magnitude
			local tweenDuration = math.max(0.1, distance / mm2CoinSpeed)
			hrp.Anchored = true
			if gunTween then
				gunTween:Cancel()
			end
			gunTween = TweenService:Create(hrp, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear), {CFrame = finalCFrame})
			gunTween:Play()
			gunTween.Completed:Wait()
			if not mm2GunFarming then
				if gunHighlight then
					gunHighlight:Destroy()
					gunHighlight = nil
				end
				continue
			end
			hrp.Anchored = false
			local pickupTimeout = 5
			local elapsed = 0
			local movedUp = false
			while targetObject.Parent and mm2GunFarming and elapsed < pickupTimeout do
				task.wait(0.1)
				elapsed += 0.1
				if elapsed >= 1.5 and not movedUp then
					movedUp = true
					hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
				end
			end
			if gunHighlight then
				gunHighlight:Destroy()
				gunHighlight = nil
			end
			if mm2GunFarming then
				hrp.Anchored = true
				task.wait(0.4)
				hrp.Anchored = false
			end
		end
	end)
	local function toggleGunFarm()
		if mm2GunFarming then
			stopGunFarm()
			notify("MM2", "Gun Farm stopped")
		else
			if mm2CoinFarming then
				stopCoinFarm()
			end
			local character = localPlayer.Character
			if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			mm2GunFarming = true
			getGButton.Text = "Stop Gun Farm"
			getGButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "Gun Farm started")
		end
	end
	getGButton.MouseButton1Click:Connect(toggleGunFarm)
	keybindSetButton.MouseButton1Click:Connect(function()
		local keyText = string.upper(string.trim(keybindBox.Text))
		if keyText == "" then
			notify("MM2", "Enter a key name first!")
			return
		end
		local keyCode = nil
		for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
			if string.upper(key.Name) == keyText then
				keyCode = key
				break
			end
		end
		if keyCode then
			mm2Keybind = keyCode
			notify("MM2", "Keybind set to: " .. keyCode.Name)
		else
			notify("MM2", "Invalid key: " .. keyText)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if mm2Keybind and input.KeyCode == mm2Keybind then
			toggleGunFarm()
		end
	end)
	local gunDropEspActive = false
	local gunDropHighlight = nil
	local function stopGunDropEsp()
		gunDropEspActive = false
		if gunDropHighlight then
			gunDropHighlight:Destroy()
			gunDropHighlight = nil
		end
		gunDropButton.Text = "GunDrop Highlight: OFF"
		gunDropButton.BackgroundColor3 = Color3.fromRGB(85, 0, 0)
	end
	task.spawn(function()
		while true do
			if not gunDropEspActive then
				task.wait(0.5)
				continue
			end
			local drop = Workspace:FindFirstChild("GunDrop", true)
			if drop and drop.Parent then
				if not gunDropHighlight or not gunDropHighlight.Parent or gunDropHighlight.Adornee ~= drop then
					if gunDropHighlight then
						gunDropHighlight:Destroy()
					end
					gunDropHighlight = Instance.new("Highlight")
					gunDropHighlight.Name = "VlexGunDropHighlight"
					gunDropHighlight.FillColor = Color3.fromRGB(0, 170, 255)
					gunDropHighlight.FillTransparency = 0.3
					gunDropHighlight.OutlineColor = Color3.fromRGB(0, 255, 255)
					gunDropHighlight.OutlineTransparency = 0
					gunDropHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					gunDropHighlight.Adornee = drop
					gunDropHighlight.Parent = drop
				end
			else
				if gunDropHighlight then
					gunDropHighlight:Destroy()
					gunDropHighlight = nil
				end
			end
			task.wait(0.25)
		end
	end)
	gunDropButton.MouseButton1Click:Connect(function()
		if gunDropEspActive then
			stopGunDropEsp()
			notify("MM2", "GunDrop highlight stopped")
		else
			gunDropEspActive = true
			gunDropButton.Text = "GunDrop Highlight: ON"
			gunDropButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			notify("MM2", "GunDrop highlight started")
		end
	end)

end

-- Open the MM2 menu immediately on load
createMM2Gui()

mm2Gui.Visible = true

mm2Title.Visible = true

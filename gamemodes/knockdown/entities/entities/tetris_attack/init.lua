AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include("shared.lua")

function ENT:Initialize( )
	self:SetModel("models/props_interiors/Furniture_shelf01a.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetPos(self:GetPos() + Vector(0,0,100))
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self:SetUseType(SIMPLE_USE)
	self.state = 1
	self.players = {}
	self.players[1] = {}
	self.players[2] = {}
	self.playField = {}
	self.playField[1] = {}
	self.playField[2] = {}

	local function mySetupVis( pl )
		AddOriginToPVS( self:GetPos() )
	end
	hook.Add( "SetupPlayerVisibility", "AddSelf", mySetupVis )
end

ENT.settings = {}
ENT.settings.blockFallTime = 10
-- frames before a block will fall when over open ground
ENT.settings.swapTime = 4
-- frames it takes for a block to finish swapping
ENT.settings.scrollSpeed = 0.05
-- blocks per second to raise the board
ENT.settings.popFrames = 40
-- frames until the blocks in a popping group begin to pop
ENT.settings.framesPerPop = 8
-- frames between each individual block pop

function ENT:Use( activator, caller )
	if IsValid( caller ) and caller:IsPlayer() then
		if self.players[1].player == nil then
			self.players[1].player = caller
			print("set player 1")
		elseif self.players[2].player == nil and caller ~= self.players[1].player then
			self.players[2].player = caller
			print("set player 2")
		end
	end
	if self.players[1].player ~= nil and self.players[2].player ~= nil and self.players[1].player:IsValid() and self.players[2].player:IsValid() and self.players[1].player:IsPlayer() and self.players[2].player:IsPlayer() then
		if caller == self.players[1].player and self.state == 3 or caller == self.players[2].player and self.state == 3 then return end
		print("starting game")
		self:SetupGame()
	end
	return
end

function ENT:IsBlockComboEligible(block, otherBlock, doIncorporeal)
	--print("testing blocks for combo eligibility")
	local eligible = true
	if block == nil or otherBlock == nil then
		return false
	end
	if not doIncorporeal then
		--print("do NOT do incorporeal")
		if block.state ~= 1 or otherBlock.state ~= 1 or block.blockType ~= otherBlock.blockType then
			eligible = false
		end
	else
		--print("do incorporeal")
		if block.state ~= 1 and block.state ~= 0 or otherBlock.state ~= 1 and otherBlock.state ~= 0 or block.blockType ~= otherBlock.blockType then
			eligible = false
		end
	end

	return eligible

end

function ENT:CheckBlock(fieldIndex, block, doIncorporeal)
	--print("field index is " .. fieldIndex)
	local connected = {}
	local connectedTrack = {}
	local test = {}
	local testTrack = {}
	testTrack[block] = true
	table.insert(test, block)

	--print("testing for combos at " .. "(" .. block.x .. "," .. block.y .. ")")

	local testIndex = 1
	while testIndex <= #test do
		local testPiece = test[testIndex]
		local cellX = testPiece.x
		local cellY = testPiece.y

		local left = self:GetBlock(fieldIndex, cellX - 1, cellY)
		local above = self:GetBlock(fieldIndex, cellX, cellY + 1)
		local right = self:GetBlock(fieldIndex, cellX + 1, cellY)
		local below = self:GetBlock(fieldIndex, cellX, cellY - 1)

		local leftEligible = false
		local aboveEligible = false
		local rightEligible = false
		local belowEligible = false
		
		if doIncorporeal then
			leftEligible = self:IsBlockComboEligible(testPiece, left, true)
			aboveEligible = self:IsBlockComboEligible(testPiece, above, true)
			rightEligible = self:IsBlockComboEligible(testPiece, right, true)
			belowEligible = self:IsBlockComboEligible(testPiece, below, true)
		else
			leftEligible = self:IsBlockComboEligible(testPiece, left)
			aboveEligible = self:IsBlockComboEligible(testPiece, above)
			rightEligible = self:IsBlockComboEligible(testPiece, right)
			belowEligible = self:IsBlockComboEligible(testPiece, below)
		end

		if leftEligible then
			if testTrack[left] == nil then
				table.insert(test, left)
				testTrack[left] = true
			end
		end

		if rightEligible then
			if testTrack[right] == nil then
				table.insert(test, right)
				testTrack[right] = true
			end
		end

		if leftEligible and rightEligible then
			if connectedTrack[testPiece] == nil then
				table.insert(connected, testPiece)
				testPiece.connected = true
				connectedTrack[testPiece] = true
			end
			if connectedTrack[left] == nil then
				table.insert(connected, left)
				left.connected = true
				connectedTrack[left] = true
			end
			if connectedTrack[right] == nil then
				table.insert(connected, right)
				right.connected = true
				connectedTrack[right] = true
			end
		end

		if aboveEligible then
			if testTrack[above] == nil then
				table.insert(test, above)
				testTrack[above] = true
			end
		end

		if belowEligible then
			if testTrack[below] == nil then
				table.insert(test, below)
				testTrack[below] = true
			end
		end

		if aboveEligible and belowEligible then
			if connectedTrack[testPiece] == nil then
				table.insert(connected, testPiece)
				testPiece.connected = true
				connectedTrack[testPiece] = true
			end
			if connectedTrack[above] == nil then
				table.insert(connected, above)
				above.connected = true
				connectedTrack[above] = true
			end
			if connectedTrack[below] == nil then
				table.insert(connected, below)
				below.connected = true
				connectedTrack[below] = true
			end
		end
		testIndex = testIndex + 1
	end
	if #connected > 0 and block.blockType ~= 7 then
		--print("combo found")
		return connected
	else
		--print("no combo found")
		return false
	end
end

function ENT:GenerateNewBlock(pos, remove, blockType)
	local tempBlock = {}
	local possibleBlocks = {}
	if remove == nil then remove = {} end
	if remove[1] == nil then
		possibleBlocks[1] = true
	end
	if remove[2] == nil then
		possibleBlocks[2] = true
	end
	if remove[3] == nil then
		possibleBlocks[3] = true
	end
	if remove[4] == nil then
		possibleBlocks[4] = true
	end
	if remove[5] == nil then
		possibleBlocks[5] = true
	end
	local v, k = table.Random(possibleBlocks)
	if blockType then
		k = blockType
	end
	tempBlock.blockType = k
	tempBlock.state = 1
	tempBlock.chainable = false
	tempBlock.timer = 0
	if pos then
		local nicePos = self:GetBlockXYFromRealPos(pos)
		tempBlock.x = nicePos.x
		tempBlock.y = nicePos.y
	end
	return tempBlock
end

function ENT:GenerateRandomPlayField(seed, fieldIndex)
	math.randomseed(seed)
	tempTable = {}
	for i = 1, 18, 1 do
		local newBlock = self:GenerateNewBlock(#tempTable + 1)
		table.insert(tempTable, newBlock)
	end
	for i = 1, 6, 1 do
		local newBlock = {}
		local air = math.random()
		if air < 0.6 then
			newBlock = self:GenerateNewBlock(#tempTable + 1)
		else
			newBlock = self:GenerateNewBlock(#tempTable + 1, {}, 7)
		end
		table.insert(tempTable, newBlock)
	end
	for i = 1, 6, 1 do
		local newBlock = {}
		local air = math.random()
		if tempTable[#tempTable - 5].blockType ~= 7 and air < 0.6 then
			newBlock = self:GenerateNewBlock(#tempTable + 1)
		else
			newBlock = self:GenerateNewBlock(#tempTable + 1, {}, 7)
		end
		table.insert(tempTable, newBlock)
	end
	for i = 1, 6, 1 do
		local newBlock = {}
		local air = math.random()
		if tempTable[#tempTable - 5].blockType ~= 7 and air < 0.6 then
			newBlock = self:GenerateNewBlock(#tempTable + 1)
		else
			newBlock = self:GenerateNewBlock(#tempTable + 1, {}, 7)
		end
		table.insert(tempTable, newBlock)
	end

	self.playField[3] = tempTable
	local noUse = {}
	for n = 1, 3, 1 do
		for i, v in ipairs(self.playField[3]) do
			if self:CheckBlock(3, v) ~= false then
				noUse[v.blockType] = true
				print("removing " .. v.blockType)
				print("trying a different type of block")
				tempTable[i] = self:GenerateNewBlock(i, noUse)
			end
		end
	end
	--PrintTable(blocks)
	return tempTable
end

function ENT:GenerateRow(playfieldIndex)
	tempTable = self.playField[playfieldIndex]
	if #tempTable >= (6 * 12) then return tempTable end
	self.cursors[playfieldIndex].y = math.min(self.cursors[playfieldIndex].y + 1, 12)
	for i = 1, 6, 1 do
		local newBlock = self:GenerateNewBlock(#tempTable + 1)
		table.insert(tempTable, 1, newBlock)
	end
	self.playField[3] = tempTable
	local tempTable2 = {}
	for n = 1, 4, 1 do
		for i = 1, 6, 1 do
			local pos = self:GetBlockXYFromRealPos(i)
			local sides = {}
			sides[1] = {}
			sides[1][1] = self:GetBlock(3, pos.x - 1,pos.y)
			sides[1][2] = self:GetBlock(3, pos.x - 2,pos.y)
			sides[2] = {}
			sides[2][1] = self:GetBlock(3, pos.x + 1,pos.y)
			sides[2][2] = self:GetBlock(3, pos.x + 2,pos.y)
			sides[3] = {}
			sides[2][1] = self:GetBlock(3, pos.x,pos.y + 1)
			sides[2][2] = self:GetBlock(3, pos.x,pos.y + 2)
			local same = false
			for _,t in ipairs(sides) do
				if t[1] ~= nil and t[2] ~= nil and t[1].blockType == self.playField[3][i].blockType and t[2].blockType == self.playField[3][i].blockType then
					same = true
				end
			end

			if same then
				tempTable2[self.playField[3][i].blockType] = true
				print("removing " .. self.playField[3][i].blockType)
				print("trying a different type of block")
				local tempBlock = self:GenerateNewBlock(i, tempTable2)
				tempTable[i] = tempBlock
				self.playField[3][i] = tempBlock
			end
		end
	end
	return tempTable
end


function ENT:ClearEmptyRows()
	for _, f in ipairs(self.playField) do
		local clear = true
		for i = #f, #f - 5, -1 do
			if self.playField[_][i] ~= nil and self.playField[_][i].blockType ~= 7 then
				clear = false
			end
		end
		if clear then
			for i = #f, #f - 5, -1 do
				--print(self.playField[_][i].blockType)
				print("clearing " .. i)
				self.playField[_][i] = nil
			end
		end
	end
end

function ENT:SetupGame()
	print("Starting game with " .. self.players[1].player:Nick() .. " and " .. self.players[2].player:Nick() .. ".")
	self.players[1].player:SetRunSpeed( 1 )
	self.players[2].player:SetRunSpeed( 1 )
	self.players[1].player:SetWalkSpeed( 1 )
	self.players[2].player:SetWalkSpeed( 1 )
	self.state = 2
	self:SetPlayer1(self.players[1].player)
	self:SetPlayer2(self.players[2].player)
	--todo: setup menus
	for i = 1, 2, 1 do
		self.players[i].player:StripWeapons()
	end
	self:StartGame()
end

function ENT:GetBlock(fieldIndex, x, y)
	if x <= 0 or x >= 7 or y <= 0 or y >= 13 then 
		return nil
	else
		return self.playField[fieldIndex][((y - 1) * 6) + x]
	end
end

function ENT:GetBlockRealPos(x, y)
	if x <= 0 or x >= 7 or y <= 0 or y >= 13 then
		return false
	else
		return ((y - 1) * 6) + x
	end
end

function ENT:GetBlockXYFromRealPos(pos)
	--print(6 % 6)
	return Vector(((pos - 1) % 6) + 1, math.floor((pos - 1) / 6) + 1, 0)
end

function ENT:CanSwapBlocks(fieldIndex, x, y)
	local canSwap = true
	local tempBlock1 = self:GetBlock(fieldIndex, x, y)
	local tempBlock2 = self:GetBlock(fieldIndex, x + 1, y)
	if tempBlock1 == nil or tempBlock2 == nil then return false end
	if tempBlock1.blockType == 8 or tempBlock2.blockType == 8 then return false end
	local tempBlock1Below = self:GetBlock(fieldIndex, x, y - 1)
	local tempBlock2Below = self:GetBlock(fieldIndex, x + 1, y - 1)
	local tempBlock1Above = self:GetBlock(fieldIndex, x, y + 1)
	local tempBlock2Above = self:GetBlock(fieldIndex, x + 1, y + 1)
	if tempBlock1.state == 2 and tempBlock1Below ~= nil and tempBlock1Below.blockType == 7 or tempBlock2.state == 3 and tempBlock2Below ~= nil and tempBlock2Below.blockType == 7 then
		canSwap = false
	end
	if tempBlock1Above ~= nil then
		if tempBlock1Above.state == 2 or tempBlock1Above.state == 3 or tempBlock1Above.state == 4 then
			canSwap = false
		end
	end
	if tempBlock2Above ~= nil then
		if tempBlock2Above.state == 2 or tempBlock2Above.state == 3 or tempBlock2Above.state == 4 then
			canSwap = false
		end
	end
	if tempBlock1.state == 4 or tempBlock2.state == 4 or tempBlock1.state == 0 or tempBlock2.state == 0 then
		canSwap = false
	end
	if tempBlock1.state == 6 or tempBlock1.state == 7 or tempBlock1.state == 8 or tempBlock2.state == 6 or tempBlock2.state == 7 or tempBlock2.state == 8 then
		canSwap = false
	end
	--print(canSwap)	
	return canSwap
end

function ENT:SwapBlocks(fieldIndex, cx, cy)
	if not self:CanSwapBlocks(fieldIndex, cx, cy) then return end
	--print("swapping " .. fieldIndex .. " at " .. CurTime())
	local tempBlock = self:GetBlock(fieldIndex, cx, cy)
	local tempBlock2 = self:GetBlock(fieldIndex, cx + 1, cy)
	tempBlock.state = 3
	tempBlock2.state = 2
	tempBlock.timer = self.settings.swapTime
	tempBlock2.timer = self.settings.swapTime
	local rp1 = self:GetBlockRealPos(cx, cy)
	local rp2 = self:GetBlockRealPos(cx + 1, cy)
	self.playField[fieldIndex][rp1] = tempBlock2
	self.playField[fieldIndex][rp2] = tempBlock
end

function ENT:ForceSwapBlocks(fieldIndex, pos1, pos2)
	local tempBlock = self.playField[fieldIndex][pos1]
	local tempBlock2 = self.playField[fieldIndex][pos2]
	self.playField[fieldIndex][pos1] = tempBlock2
	self.playField[fieldIndex][pos2] = tempBlock
end

function ENT:OnRemove()
	hook.Remove( "SetupPlayerVisibility", "AddSelf")
	self:EndGame()
end

function ENT:StartGame()
	--math.randomseed(SysTime())
	local randomseed = math.random(1,1000)
	self.playField[1] = self:GenerateRandomPlayField(randomseed, 1)
	self.playField[2] = self:GenerateRandomPlayField(randomseed, 2)
	self.players[1].scrollSpeed = self.settings.scrollSpeed
	self.players[2].scrollSpeed = self.settings.scrollSpeed
	self.players[1].boardOffset = 0
	self.players[2].boardOffset = 0
	self.players[1].lastRow = 0
	self.players[2].lastRow = 0
	self.players[1].frame = 0
	self.players[2].frame = 0
	self.players[1].scrollForce = 1
	self.players[2].scrollForce = 1
	self.cursors = {}
	self.cursors[1] = Vector(3,3,0)
	self.cursors[2] = Vector(3,3,0)
	self.state = 3
	for i = 1, 2, 1 do
		hook.Add("KeyPress", "TAK" .. i, function(pl, key)
			local index = i
			if pl ~= self.players[index].player then return end
			if key == IN_ATTACK then
				--print("let's swap p1")
				local cx = self.cursors[index].x
				local cy = self.cursors[index].y
				self:SwapBlocks(index, cx, cy)
			end
			if key == IN_FORWARD and self.cursors[index].y < 11 then
				self.cursors[index].y = self.cursors[index].y + 1
			end
			if key == IN_BACK and self.cursors[index].y > 2 then
				self.cursors[index].y = self.cursors[index].y - 1
			end
			if key == IN_MOVERIGHT and self.cursors[index].x < 5 then
				self.cursors[index].x = self.cursors[index].x + 1
			end
			if key == IN_MOVELEFT and self.cursors[index].x > 1 then
				self.cursors[index].x = self.cursors[index].x - 1
			end
			if key == IN_ATTACK2 then
				math.randomseed(SysTime())
				local randomseed2 = math.random(1,1000)
				self.playField[index] = self:GenerateRandomPlayField(randomseed2, index)
			end
			if key == IN_USE then
				self.players[index].scrollForce = 40
			end
		end)
	end
end

function ENT:GiveLoss(pl)
	for i = 1, 2, 1 do
		self.players[i].player:ChatPrint(pl:Nick() .. " wins!")
	end
	self:EndGame()
end

function ENT:EndGame()
	self.players[1].player:SetRunSpeed( 320 )
	self.players[2].player:SetRunSpeed( 320 )
	self.players[1].player:SetWalkSpeed( 320 )
	self.players[2].player:SetWalkSpeed( 320 )
	self:SetPlayer1(nil)
	self:SetPlayer2(nil)
	self.players[1] = {}
	self.players[2] = {}
	self.playField[1] = {}
	self.playField[2] = {}
	self.state = 4
	for i = 1, 2, 1 do
		hook.Remove("KeyPress", "TAK" .. i)
	end
end

function ENT:QueueGarbage(targetField, width, height)
	print("queuing garbage of width and height " .. width .. " " .. height)
	if self.players[targetField].queuedGarbage == nil then
		self.players[targetField].queuedGarbage = {}
	end
	height = math.min(height, 12)
	local baseGarbage = {}
	baseGarbage.dropPos = math.random(1, 7 - width)
	baseGarbage.width = width
	baseGarbage.height = height
	baseGarbage.baseGarbage = true
	--print("inserting garbage")
	table.insert(self.players[targetField].queuedGarbage, baseGarbage)
end

function ENT:TestGarbage(targetField)
	if self.players[targetField].queuedGarbage == nil then
		self.players[targetField].queuedGarbage = {}
	end
	print(#self.playField[targetField], #self.players[targetField].queuedGarbage, self.players[targetField].boardActive)
	if #self.players[targetField].queuedGarbage > 0 and #self.playField[targetField] <= 78 and self.players[targetField].boardActive == true and not self.players[targetField].queuedGarbage[1].dropped then
		print("makin garbage")
		self.players[targetField].queuedGarbage[1].dropped = true
		for i = 1, 72, 1 do
			if self.playField[targetField][i] == nil then
				self.playField[targetField][i] = self:GenerateNewBlock(i, {}, 7)
			end
		end
		local gbBase = self:GenerateNewBlock(nil, {}, 8)
		local gbRef = self.players[targetField].queuedGarbage[1]
		gbBase.dropPos = gbRef.dropPos
		gbBase.width = gbRef.width
		gbBase.height = gbRef.height
		gbBase.state = 5
		gbBase.timer = 0
		gbBase.children = {}
		if gbBase.height > 1 then
			for i = 1, (gbBase.height - 1) * 6, 1 do
				if self.playField[targetField][i + 72] == nil then
					self.playField[targetField][i + 72] = self:GenerateNewBlock(i, {}, 7)
				end
			end
		end
		local gbPos = 66 + gbBase.dropPos
		self.playField[targetField][gbPos] = gbBase
		for i = 1, (gbBase.width * gbBase.height) - 1, 1 do
			local tempBlock = self:GenerateNewBlock(nil, {}, 8)
			tempBlock.garbagePos = i
			tempBlock.parent = gbBase
			tempBlock.index = gbPos + i
			table.insert(gbBase.children, tempBlock)
			self.playField[targetField][gbPos + i] = tempBlock
		end
		table.remove(self.players[targetField].queuedGarbage,1)
	end
end

function ENT:TestComboGarbage(block, fieldIndex)

	local cellX = block.x
	local cellY = block.y

	local blocks = {}
	table.insert(blocks, self:GetBlock(fieldIndex, cellX - 1, cellY))
	table.insert(blocks, self:GetBlock(fieldIndex, cellX, cellY + 1))
	table.insert(blocks, self:GetBlock(fieldIndex, cellX + 1, cellY))
	table.insert(blocks, self:GetBlock(fieldIndex, cellX, cellY - 1))

	local garbages = {}
	for i, v in ipairs(blocks) do
		if v.blockType == 8 then
			table.insert(garbages, v)
			break
		end
	end

	if #garbages > 0 then
		blocks = {}
		for n, g in ipairs(garbages) do
			if not g.children then g = g.parent end
			table.insert(blocks, g)
			for i, v in ipairs(g.children) do
				table.insert(blocks, v)
			end
		end
		return blocks
	else
		return nil
	end

end

function ENT:DoGameThink(frame)

	if not self.players[1].player:IsValid() or not self.players[2].player:IsValid() then self:EndGame() end

	local playFieldString = {}

	for n, field in ipairs(self.playField) do
		if n == 3 then break end
		playFieldString[n] = ""
		local comboTable = {}
		local popTable = {}
		local noChains = true
		for i, v in ipairs(field) do
			v.oldState = v.state
			if i <= 6 then
				v.state = 0
			else
				if v.state == 0 then
					v.state = 1
				end
			end
			local nicePos = self:GetBlockXYFromRealPos(i)
			v.x = nicePos.x
			v.y = nicePos.y
			v.index = i

			-- if a blog was tagged to be unchained last frame, do it now
			if v.unChainAtEnd then
				v.chainable = false
				v.unChainAtEnd = nil
			end

			-- set states when the timer is zero
			if v.timer == 0 then
				if v.state == 2 or v.state == 3 then
					v.state = 1
				end
				if v.state == 4 then
					v.state = 5
				end
				if v.state == 7 then
					if v.blockType == 8 then
						if v.children then
							self:ForceSwapBlocks(n, i, i + 6)
						else
							local tempClear = v.clearAt
							self.playField[n][i] = self:GenerateNewBlock(i)
							self.playField[n][i].state = 9
							self.playField[n][i].clearAt = tempClear
						end
					else
						v.state = 8
					end
				end
				if v.state == 6 then
					v.state = 7
					table.insert(popTable, v)
				end
			end

			--if v.state == 8 and v.oldState == 7 then
			--	
			--end

			local blockBelow = {}
			blockBelow[1] = self:GetBlock(n, v.x, v.y - 1)
			if v.blockType == 8 and v.children then
				for _ = 1, v.width, 1 do
					blockBelow[_] = self:GetBlock(n, v.x + (_ - 1), v.y - 1)
				end
			end
			local blockAbove = self:GetBlock(n, v.x, v.y + 1)
			if i <= 12 then
				blockBelow[1] = nil
			end

			if blockBelow[1] ~= nil then
				if #blockBelow > 1 then
					local falling = true
					for _, below in ipairs(blockBelow) do
						if below.blockType ~= 7 then
							falling = false
						end
					end
					if falling then
						v.fallAtEnd = true
					else
						v.fallAtEnd = false
					end
				elseif v.blockType ~= 8 and v.state ~= 9 then
					-- handle falling
					if v.state == 5 and blockBelow[1].blockType == 7 then
						v.fallAtEnd = true
					end
					if blockBelow[1].state == 4 and blockBelow[1].blockType ~= 7 or blockBelow[1].state == 5 and blockBelow[1].blockType ~= 7 then
						if v.state ~= 6 and v.state ~= 7 and v.state ~= 8 then
							v.state = blockBelow[1].state
							v.timer = blockBelow[1].timer
						end
					end
					if blockBelow[1].blockType == 7 and blockBelow[1].state == 1 and v.blockType ~= 7 and v.state == 1 then
						v.state = 4
						v.timer = self.settings.blockFallTime
					end
					if v.state == 5 and blockBelow[1].state == 1 and blockBelow[1].blockType ~= 7 then
						v.state = 1
						v.timer = 0
					end
					if v.state == 5 and blockBelow[1].state == 0 and blockBelow[1].blockType ~= 7 then
						v.state = 1
						v.timer = 0
					end
		
					-- handle chains
					if i > 6 then
						if blockBelow[1].state == 8 and blockBelow[1].timer <= 1 or blockBelow[1].chainable == true then
							if v.blockType ~= 7 then
								v.chainable = true
							end
						else
							if blockBelow[1].blockType ~= 7 and blockBelow[1].state == 1 or blockBelow[1].blockType ~= 7 and blockBelow[1].state == 0 then
								v.unChainAtEnd = true
							end
						end
						if v.state == 8 and v.blockType ~= 7 then
							v.chainable = true
						end
					end
				end
			else
				if i > 6 then
					if v.state == 8 then
						if v.blockType ~= 7 then
							v.chainable = true
						end
					else
						v.unChainAtEnd = true
					end
					if v.state == 5 then
						v.state = 1
						v.timer = 0
					end
				end
			end

			if v.state == 0 then
				v.chainable = false
			end

			if blockAbove ~= nil then
				if v.state ~= 1 and v.blockType ~= 7 then
					if blockAbove.state == 6 or blockAbove.state == 7 or blockAbove.state == 8 or blockAbove.chainable == true then
						v.chainable = true
					end
				end
			end


			-- if we enter idle and we weren't in it before, check for chains
			if v.state == 1 and v.oldState ~= 1 and v.blockType ~= 8 then
				tempComboTable = self:CheckBlock(n, v)
				if tempComboTable then
					for _, c in ipairs(tempComboTable) do
						table.insert(comboTable, c)
					end
				end
			end

			-- clear blocks that should be cleared
			if v.clearAt and frame > v.clearAt then
				if v.state == 9 then
					v.state = 1
					v.clearAt = nil
				else
					v.blockType = 7
					v.state = 1
					v.chainable = false
					v.clearAt = nil
				end
			end

			-- decrement timers
			v.timer = math.max(v.timer - 1, 0)

			-- swap any blocks that need to fall
			if v.fallAtEnd then
				self:ForceSwapBlocks(n, i, i - 6)
				v.fallAtEnd = nil
			end

			if v.blockType == 8 and v.parent then
				if self.playField[n][v.parent.index + v.garbagePos] ~= self then
					self:ForceSwapBlocks(n, i, v.parent.index + v.garbagePos)
				end
			end


			if v.chainable == true then
				noChains = false
			end

			playFieldString[n] = playFieldString[n] .. v.blockType .. v.state .. v.timer .. "|"
		end
		-- reset chain if no blocks on the board are considered chainable
		if noChains == true then
			if n == 1 then
				if self:GetPL1Chain() >= 2 then
					print("chain garbage")
					self:QueueGarbage(2, 6, self:GetPL1Chain() - 1)
				end
				self.players[1].boardActive = true
				self:SetPL1Chain(1)
			else
				if self:GetPL2Chain() >= 2 then
					print("chain garbage")
					self:QueueGarbage(1, 6, self:GetPL2Chain() - 1)
				end
				self.players[2].boardActive = true
				self:SetPL2Chain(1)
			end
		end
		-- if we found blocks to pop, set them up
		if #popTable > 0 then
			self.players[n].boardActive = false
			table.sort(popTable,function(a,b) return a.index > b.index end)
			for _, p in ipairs(popTable) do
				p.timer = (self.settings.framesPerPop * _) + (self.settings.framesPerPop * 3)
			end
		end
		-- if a combo was found this frame, set it up
		if #comboTable > 0 then
			print("Found a combo!")
			-- do garbage --
			local isChain = false
			local allIdle = true
			self.players[n].boardActive = false
			if #comboTable >= 4 then
				local target = 1
				if n == 1 then
					target = 2
				end
				print("combo garbage")
				self:QueueGarbage(target, math.Clamp(#comboTable - 1,3,6), 1)
			end
			local newGarbage = {}
			for _, c in ipairs(comboTable) do
				local tempGarbage = self:TestComboGarbage(c, n)
				if tempGarbage and #tempGarbage > 0 then
					for t, a in ipairs(tempGarbage) do
						newGarbage[a] = a
					end
				end
			end
			local tempNumIts = 0
			for k, g in pairs(newGarbage) do
				if tempNumIts < 6 then
					table.insert(comboTable, g)
				end
			end
			for _, c in ipairs(comboTable) do
				if c.state == 1 or c.state == 2 or c.state == 3 then
					allIdle = false
				end
				print(c.index)
				c.state = 6
				c.timer = self.settings.popFrames
				c.clearAt = frame + (self.settings.popFrames + (self.settings.framesPerPop * #comboTable) + (self.settings.framesPerPop * 3))
				if c.chainable == true and allIdle == false then
					isChain = true
				end
			end
			if isChain then
				print("chaining!")
				if n == 1 then
					self:SetPL1Chain(self:GetPL1Chain() + 1)
				else
					self:SetPL2Chain(self:GetPL2Chain() + 1)
				end
			end
		end
		self:TestGarbage(n)
		if self.players[n].player:KeyDown(IN_FORWARD) then
			self.players[n].FORWARDTimer = self.players[n].FORWARDTimer + 1
		else
			self.players[n].FORWARDTimer = 0
		end
		if self.players[n].player:KeyDown(IN_MOVELEFT) then
			self.players[n].MOVELEFTTimer = self.players[n].MOVELEFTTimer + 1
		else
			self.players[n].MOVELEFTTimer = 0
		end
		if self.players[n].player:KeyDown(IN_BACK) then
			self.players[n].BACKTimer = self.players[n].BACKTimer + 1
		else
			self.players[n].BACKTimer = 0
		end
		if self.players[n].player:KeyDown(IN_MOVERIGHT) then
			self.players[n].MOVERIGHTTimer = self.players[n].MOVERIGHTTimer + 1
		else
			self.players[n].MOVERIGHTTimer = 0
		end
		if self.players[n].FORWARDTimer >= 12 then
			self.cursors[n].y = math.min(self.cursors[n].y + 1, 12)
		end
		if self.players[n].MOVELEFTTimer >= 12 then
			self.cursors[n].x = math.max(self.cursors[n].x - 1, 1)
		end
		if self.players[n].BACKTimer >= 12 then
			self.cursors[n].y = math.max(self.cursors[n].y - 1, 2)
		end
		if self.players[n].MOVERIGHTTimer >= 12 then
			self.cursors[n].x = math.min(self.cursors[n].x + 1, 5)
		end
	end
	for _ = 1, 2, 1 do
		local rowTime = 60 / self.players[_].scrollSpeed
		self.players[_].boardOffset = (self.players[_].frame - self.players[_].lastRow) / rowTime
		if self.players[_].deathTimer == nil then self.players[_].deathTimer = 0 end
		if #self.playField[_] > 72 then
			self.players[_].boardOffset = 0
			if self.players[_].boardActive then
				self.players[_].deathTimer = self.players[_].deathTimer + 1
			else
				self.players[_].deathTimer = 0
			end
		end
		if self.players[_].deathTimer > 120 then
			self:GiveLoss(self.players[_].player)
		end
	end

	self:SetSwapTime(self.settings.swapTime)
	self:SetScrollSpeed1(self.players[1].scrollSpeed)
	self:SetScrollSpeed2(self.players[2].scrollSpeed)
	self:SetBoardOffset1(self.players[1].boardOffset)
	self:SetBoardOffset2(self.players[2].boardOffset)
	self:SetPlayField1Length(#self.playField[1])
	self:SetPlayField2Length(#self.playField[2])
	self:SetPlayField1(playFieldString[1])
	self:SetPlayField2(playFieldString[2])
	self:SetCursorPos1(self.cursors[1])
	self:SetCursorPos2(self.cursors[2])
	self:SetCurFrame(frame)

	--print(self.players[2].frame)
	--print(self.players[2].lastRow)
	--print(60 / self.players[2].scrollSpeed)
	--print(self.players[2].lastRow + (60 / self.players[2].scrollSpeed))
	--print(self.players[2].frame >= self.players[2].lastRow + (60 / self.players[2].scrollSpeed))
	--print("-------------")
	for i = 1, 2, 1 do
		if self.players[i].frame >= self.players[i].lastRow + (60 / self.players[i].scrollSpeed) then
			self:GenerateRow(i)
			self.players[i].lastRow = self.players[i].frame
			if not self.players[i].player:KeyDown(IN_USE) then
				self.players[i].scrollForce = 1
			end
		end
	end
	self:ClearEmptyRows()

end

function ENT:Think()
	if self.state ~= 3 then
		self:NextThink(CurTime() + 0.2)
		self.curFrame = 0
		return true
	end

	self:NextThink(CurTime())
	self.curFrame = self.curFrame + 1
	for i = 1, 2, 1 do
		if self.players[i].boardActive and #self.playField[i] < 67 then
			self.players[i].frame = self.players[i].frame + (1 * self.players[i].scrollForce)
		end
	end
	self:DoGameThink(self.curFrame)

	return true
end
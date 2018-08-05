include("shared.lua")

local blockMats = {}
blockMats[1] = Material("tetrisattack/block1.png")
blockMats[2] = Material("tetrisattack/block2.png")
blockMats[3] = Material("tetrisattack/block3.png")
blockMats[4] = Material("tetrisattack/block4.png")
blockMats[5] = Material("tetrisattack/block5.png")
blockMats[6] = Material("tetrisattack/block6.png")
blockMats[7] = Material("tetrisattack/block7.png")
blockMats[8] = Material("tetrisattack/block8.png")
local cursor = Material("tetrisattack/cursor.png")

function ENT:Draw()
	self:DrawModel()
	if self:GetPlayField1() ~= "" then
		local field = self:GetPlayField1()
		local field2 = self:GetPlayField2()
		--LocalPlayer():ChatPrint(field2 .. "\n")
		--print(field)
		--print(string.len(field))
		local tempBlockTable = {}
		tempBlockTable[1] = {}
		tempBlockTable[2] = {}
		-- v.blockType .. v.state .. bool .. v.timer

		local tableLength = {}
		tableLength[1] = self:GetPlayField1Length()
		tableLength[2] = self:GetPlayField2Length()
		local curPos = 0
		for i = 1, tableLength[1], 1 do
			local st, et, strt = string.find(field, "|", curPos + 1)
			if et ~= nil then
				tempTable = {}
				tempTable.blockType = tonumber(string.sub(field,curPos + 1,curPos + 1))
				tempTable.state = tonumber(string.sub(field,curPos + 2,curPos + 2))
				tempTable.timer = tonumber(string.sub(field,curPos + 3,et - 1))
				table.insert(tempBlockTable[1], tempTable)
				curPos = st
			end
		end
		curPos = 0
		for i = 1, tableLength[2], 1 do
			local st, et, strt = string.find(field2, "|", curPos + 1)
			if et ~= nil then
				tempTable = {}
				tempTable.blockType = tonumber(string.sub(field2,curPos + 1,curPos + 1))
				tempTable.state = tonumber(string.sub(field2,curPos + 2,curPos + 2))
				tempTable.timer = tonumber(string.sub(field2,curPos + 3,et - 1))
				table.insert(tempBlockTable[2], tempTable)
				curPos = st
			end
		end
		--print("--------------------------------------")
		--PrintTable(tempBlockTable[1])
		--print("-------   ahem   --------")
		--print("-------   ahem   --------")
		--print("-------   ahem   --------")
		--PrintTable(tempBlockTable[1])
		local blockSize = ScrW() * 0.04
		local fieldPos = {}
		local offset = {}
		offset[1] = self:GetBoardOffset1() * blockSize
		offset[2] = self:GetBoardOffset2() * blockSize
		if self:GetPlayer1() == LocalPlayer() or self:GetPlayer2() == LocalPlayer() then
			fieldPos[1] = Vector((ScrW() * 0.35) - (blockSize * 3),ScrH() - offset[1],0)
			fieldPos[2] = Vector((ScrW() * 0.65) - (blockSize * 3),ScrH() - offset[2],0)
			cam.Start2D()
				for n, s in ipairs(tempBlockTable) do
					-- This for loop draws the blocks.
					for i, v in ipairs(s) do
						surface.SetMaterial( blockMats[v.blockType] )
						surface.SetDrawColor(255,255,255,255)
						local blockX = (((i - 1) % 6) * blockSize) + fieldPos[n].x
						local blockY = (math.floor((i - 1) / 6) * -blockSize) + fieldPos[n].y
						local blockXOffset = 0
						if v.state == 2 or v.state == 3 then
							local dir = 1
							if v.state == 3 then
								dir = -1
							end
							blockXOffset = ((blockSize / self:GetSwapTime()) * v.timer) * dir
						end
						if v.timer ~= 0 and n == 1 then
							--print(i)
							--print(v.timer)
						end
						if v.state == 6 and v.timer % 4 >= 3 then
							surface.SetDrawColor(255,255,255,128)
						end
						if v.state == 7 then
							surface.SetDrawColor(255,255,255,200)
						end
						if v.state == 0 then 
							surface.SetDrawColor(128,128,128,255)
						end
						if v.state ~= 8 and v.blockType ~= 7 then
							surface.DrawTexturedRect(blockX + blockXOffset,blockY,blockSize,blockSize)
						end
						draw.SimpleText(i,"DermaLarge",blockX + blockXOffset + (blockSize * 0.5),blockY + (blockSize * 0.5) - 14,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
						--draw.SimpleText(v.state,"DermaLarge",blockX + blockXOffset + (blockSize * 0.5),blockY + (blockSize * 0.5) + 14,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
					end
				end
				draw.SimpleTextOutlined(self:GetPL1Chain(),"DermaLarge",128,128,Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,Color(0,0,0))
				draw.SimpleTextOutlined(self:GetPL2Chain(),"DermaLarge",128,256,Color(255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,2,Color(0,0,0))
				-- Now we draw the cursors.
				surface.SetMaterial( cursor )
				surface.SetDrawColor(255,255,255,255)
				local cursorPos = self:GetCursorPos1()
				local bx = (cursorPos.x - 1) * blockSize + fieldPos[1].x
				local by = (cursorPos.y - 1) * -blockSize + fieldPos[1].y
				surface.DrawTexturedRect(bx,by,blockSize * 2,blockSize * 2)
				cursorPos = self:GetCursorPos2()
				bx = (cursorPos.x - 1) * blockSize + fieldPos[2].x
				by = (cursorPos.y - 1) * -blockSize + fieldPos[2].y
				surface.DrawTexturedRect(bx,by,blockSize * 2,blockSize * 2)
				--draw.SimpleText(field,"DebugFixed",ScrW() * 0.2,16,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			cam.End2D()
		else
			fieldPos[1] = Vector(blockSize * 7,-offset[1] + (blockSize * 6.5),0)
			fieldPos[2] = Vector(blockSize * 2,-offset[2] + (blockSize * 6.5),0)
			cam.Start3D2D(self:GetPos() + (self:GetAngles():Forward() * 16),self:GetAngles() + Angle(0,90,90),0.1)
				for n, s in ipairs(tempBlockTable) do
					-- This for loop draws the blocks.
					for i, v in ipairs(s) do
						surface.SetMaterial( blockMats[v.blockType] )
						surface.SetDrawColor(255,255,255,255)
						local blockX = (((i - 1) % 6) * blockSize) + fieldPos[n].x
						local blockY = (math.floor((i - 1) / 6) * -blockSize) + fieldPos[n].y
						local blockXOffset = 0
						if v.state == 2 or v.state == 3 then
							local dir = 1
							if v.state == 3 then
								dir = -1
							end
							blockXOffset = ((blockSize / self:GetSwapTime()) * v.timer) * dir
						end
						if v.timer ~= 0 and n == 1 then
							--print(i)
							--print(v.timer)
						end
						if v.state == 6 and v.timer % 4 >= 3 then
							surface.SetDrawColor(255,255,255,128)
						end
						if v.state == 0 then 
							surface.SetDrawColor(128,128,128,255)
						end
						if v.state ~= 8 then
							surface.DrawTexturedRect(blockX + blockXOffset,blockY,blockSize,blockSize)
						end
						--draw.SimpleTextOutlined(v.timer,"DebugFixed",blockX + blockXOffset + (blockSize * 0.5),blockY + (blockSize * 0.5) - 6,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, 1, Color(0,0,0))
						--draw.SimpleTextOutlined(v.state,"DebugFixed",blockX + blockXOffset + (blockSize * 0.5),blockY + (blockSize * 0.5) + 6,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, 1, Color(0,0,0))
					end
				end
				draw.SimpleTextOutlined(self:GetPL1Chain(),"DermaLarge",0,0,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,2,Color(0,0,0))
				draw.SimpleTextOutlined(self:GetPL2Chain(),"DermaLarge",0,256,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,2,Color(0,0,0))
				-- Now we draw the cursors.
				surface.SetMaterial( cursor )
				surface.SetDrawColor(255,255,255,255)
				local cursorPos = self:GetCursorPos1()
				local bx = (cursorPos.x - 1) * blockSize + fieldPos[1].x
				local by = (cursorPos.y - 1) * -blockSize + fieldPos[1].y
				surface.DrawTexturedRect(bx,by,blockSize * 2,blockSize * 2)
				cursorPos = self:GetCursorPos2()
				bx = (cursorPos.x - 1) * blockSize + fieldPos[2].x
				by = (cursorPos.y - 1) * -blockSize + fieldPos[2].y
				surface.DrawTexturedRect(bx,by,blockSize * 2,blockSize * 2)
			cam.End3D2D()
		end
	end
end

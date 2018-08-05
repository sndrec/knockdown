function LoadPropTable(tablename)
	DestroyPropTable()
	curInstancedPropTable = {}
	local spikeTable = {}
	RunString(file.Read("proptables/" .. tablename .. ".txt","DATA"))
	spikeTable["models/platformmaster/1x1x1spike.mdl"] = true
	spikeTable["models/platformmaster/2x1x1spike.mdl"] = true
	spikeTable["models/platformmaster/2x2x1spike.mdl"] = true
	spikeTable["models/platformmaster/4x1x1spike.mdl"] = true
	spikeTable["models/platformmaster/4x2x1spike.mdl"] = true
	spikeTable["models/platformmaster/4x4x1spike.mdl"] = true
	print("fart")
	for k, v in pairs(propTable) do
		if type(v.model) == "string" then
			local newProp = ents.Create("prop_physics")
			newProp:SetModel(v["model"])
			newProp:SetPos(v["pos"])
			newProp:SetAngles(v["angle"])
			newProp:SetMaterial("jumpbox")
			newProp:SetColor(Color(180,180,180))
			newProp:Spawn()
			newProp:PhysicsInitShadow(false,false)
			newProp:SetSolid(SOLID_VPHYSICS)
			newProp:GetPhysicsObject():EnableMotion(false)
			if type(v) == "table" then
				if not newProp.Vars then
					newProp.Vars = {}
				end
				for t, b in pairs(v) do
					if isnumber(k) then
						newProp.Vars[t] = b
					end
				end
			end
			if v["nocollide"] then
				newProp:SetSolid(SOLID_NONE)
			end
			if v["color"] then
				newProp:SetColor(v["color"])
			end
			if v["material"] then
				newProp:SetMaterial(v["material"])
			end
			if v["move"] then
				print("instancing moving prop")
				newProp.Vars["timerName"] = "movetimer" .. newProp:EntIndex()
				newProp.Vars["pos1"] = v["pos1"]
				newProp.Vars["pos2"] = v["pos2"]
				newProp.Vars["movetime"] = v["movetime"]
				newProp:SetPos(newProp.Vars["pos1"])
				local tempPhys = newProp:GetPhysicsObject()
				tempPhys:SetMass(500)
				tempPhys:EnableMotion(true)
				tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
				if v["loop"] then
					local its = 0
					if newProp.Vars["starttime"] then
						timer.Simple(newProp.Vars["starttime"], function()
							timer.Create(newProp.Vars["timerName"], newProp.Vars["movetime"], 0, function()
								if its % 2 == 0 then
									tempPhys:UpdateShadow(newProp.Vars["pos1"],newProp:GetAngles(),newProp.Vars["movetime"])
								else
									tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
								end
								its = its + 1
							end)
						end)
					else
						timer.Create(newProp.Vars["timerName"], newProp.Vars["movetime"], 0, function()
							if its % 2 == 0 then
								tempPhys:UpdateShadow(newProp.Vars["pos1"],newProp:GetAngles(),newProp.Vars["movetime"])
							else
								tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
							end
							its = its + 1
						end)
					end
				elseif v["repeat"] then
					if newProp.Vars["starttime"] then
						timer.Simple(newProp.Vars["starttime"], function()
							timer.Create(newProp.Vars["timerName"], newProp.Vars["movetime"], 0, function()
								tempPhys:SetPos(newProp.Vars["pos1"])
								tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
							end)
						end)
					else
						timer.Create(newProp.Vars["timerName"], newProp.Vars["movetime"], 0, function()
							tempPhys:SetPos(newProp.Vars["pos1"])
							tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
						end)
					end
				else
					tempPhys:UpdateShadow(newProp.Vars["pos2"],newProp:GetAngles(),newProp.Vars["movetime"])
				end
			end
			table.insert(curInstancedPropTable, newProp)
		end
	end

	hook.Add("Tick", "DebugShit", function()
		if propTable and propTable.goalVolume then
			debugoverlay.Box(Vector(0,0,0),propTable.goalVolume.mins, propTable.goalVolume.maxs,0.1,Color( 0, 255, 0, 10 ))
			debugoverlay.Box(Vector(0,0,0),propTable.spawnVolume.mins, propTable.spawnVolume.maxs,0.1,Color( 255, 255, 255, 10 ))
		end
	end)
end

function DestroyPropTable()
	if curInstancedPropTable then
		for k, v in pairs(curInstancedPropTable) do
			if v:IsValid() then
				if v.Vars["timerName"] and timer.Exists( v.Vars["timerName"] ) then
					timer.Remove( v.Vars["timerName"] )
				end
				v:Remove()
			end
		end
	end
end

function WritePropTable(newName)
	local curPropTable = ents.FindByClass("prop_physics")
	local tempString = "propTable = {}\ncurProp = 1\n"
	local noVar = {}
	noVar["model"] = true
	noVar["pos"] = true
	noVar["angle"] = true
	noVar["color"] = true
	noVar["material"] = true
	noVar["timerName"] = true
	for i, v in ipairs(curPropTable) do
		tempString = tempString .. "propTable[curProp] = {}\n"
		tempString = tempString .. "propTable[curProp][\"model\"] = \"" .. v:GetModel() .. "\"\n"
		tempString = tempString .. "propTable[curProp][\"pos\"] = Vector(" .. math.Round(v:GetPos().x, 0) .. "," .. math.Round(v:GetPos().y, 0) .. "," .. math.Round(v:GetPos().z, 0) .. ")\n"
		tempString = tempString .. "propTable[curProp][\"angle\"] = Angle(" .. math.Round(v:GetAngles().p, 0) .. "," .. math.Round(v:GetAngles().y, 0) .. "," .. math.Round(v:GetAngles().r, 0) .. ")\n"
		if v:GetColor() ~= Color(255,255,255) then
			tempString = tempString .. "propTable[curProp][\"color\"] = Color(" .. v:GetColor().r .. "," .. v:GetColor().g .. "," .. v:GetColor().b .. ")\n"
		end
		if v:GetMaterial() ~= "jumpbox" then
			tempString = tempString .. "propTable[curProp][\"material\"] = \"" .. v:GetMaterial() .. "\"\n"
		end
		if v.Vars then
			for k, p in pairs(v.Vars) do
				if not noVar[k] then
					if type(p) == "Vector" then
						tempString = tempString .. "propTable[curProp][\"" .. k .. "\"] = Vector(" .. math.Round(p.x, 0) .. "," .. math.Round(p.y, 0) .. "," .. math.Round(p.z, 0) .. ")\n"
					elseif type(p) == "number" then
						tempString = tempString .. "propTable[curProp][\"" .. k .. "\"] = " .. tonumber(p) .. "\n"
					elseif type(p) == "string" then
						tempString = tempString .. "propTable[curProp][\"" .. k .. "\"] = \"" .. p .. "\"\n"
					elseif type(p) == "boolean" then
						tempString = tempString .. "propTable[curProp][\"" .. k .. "\"] = " .. tostring(p) .. "\n"
					end
				end
			end
		end
		tempString = tempString .. "curProp = curProp + 1\n"
	end
	file.Write("propTables/" .. newName .. ".txt", tempString)
end


hook.Add("PlayerSay", "SandboxVarAdd", function(pl, text, teamchat)

	if pl:IsAdmin() then
		if string.sub(text,1,15) == "/writeproptable" then
			local startpos1, endpos1 = string.find( text, " ", 7 )
			local name = string.sub(text,endpos1 + 1)
			WritePropTable(name)
			for i, v in ipairs(player.GetAll()) do
				v:ChatPrint("Wrote prop table to " .. name .. ".txt")
			end
		end
		if string.sub(text,1,17) == "/destroyproptable" then
			DestroyPropTable()
		end
		if string.sub(text,1,14) == "/loadproptable" then
			local startpos1, endpos1 = string.find( text, " ", 7 )
			local name = string.sub(text,endpos1 + 1)
			LoadPropTable(name)
		end
		if string.sub(text,1,7) == "/setvar" then
			local lookProp = pl:GetEyeTrace().Entity
			local startpos1, endpos1 = string.find( text, " ", 7 )
			local startpos2, endpos2 = string.find( text, " ", endpos1 + 1)
			local startpos3, endpos3 = string.find( text, " ", endpos2 + 1)
			local name = string.sub(text,endpos1 + 1, startpos2 - 1)
			local vartype = string.sub(text,endpos2 + 1, startpos3 - 1)
			local var = string.sub(text,endpos3 + 1)
	
			if not lookProp.Vars then
				lookProp.Vars = {}
			end
			if vartype == "string" then
				lookProp.Vars[name] = var
			elseif vartype == "number" then
				lookProp.Vars[name] = tonumber(var)
			elseif vartype == "bool" then
				lookProp.Vars[name] = tobool(var)
			elseif vartype == "vector" and var == "curpos" then
				lookProp.Vars[name] = lookProp:GetPos()
			end
			for i, v in ipairs(player.GetAll()) do
				v:ChatPrint("Set " .. vartype .. " var " .. name .. " to " .. var .. " on prop of type " .. lookProp:GetClass())
			end
		end
	
		if string.sub(text,1,8) == "/getvars" then
			local lookProp = pl:GetEyeTrace().Entity
			if not lookProp.Vars then
				for i, p in ipairs(player.GetAll()) do
					p:ChatPrint("No variables on that prop.")
					return
				end
			end
			for i, p in ipairs(player.GetAll()) do
				local num = 1
				for k, v in pairs(lookProp.Vars) do
					p:ChatPrint("var " .. num .. " name|type|var = " .. k .. "|" .. type(v) .. "|" .. tostring(v))
					num = num + 1
				end
			end
		end
	
		if string.sub(text,1,10) == "/clearvars" then
			local lookProp = pl:GetEyeTrace().Entity
			lookProp.Vars = nil
			for i, p in ipairs(player.GetAll()) do
				p:ChatPrint("Cleared all variables on entity.")
			end
		end
	end

end)
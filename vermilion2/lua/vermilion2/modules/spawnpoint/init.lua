--[[
 Copyright 2015 Ned Hyett, 

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.

 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation)
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so.
]]

local MODULE = MODULE
MODULE.Name = "Custom Spawnpoints"
MODULE.ID = "spawnpoint"
MODULE.Description = "Allows custom spawn positions to be set besides the map spawn point."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_spawnpoints"
}
MODULE.NetworkStrings = {
	"VGetSpawnpoints",
	"VDelSpawnpoint",
	"VGetRankSpawnpoints",
	"VGoto",
	"VAssignSpawnpoint",
	"VResetSpawnpoint"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "addspawn",
		Description = "Add a new spawnpoint.",
		Syntax = "<name> <radius>",
		CanMute = true,
		Permissions = { "manage_spawnpoints" },
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE:GetData("points", {}, true)[text[1]] != nil) then
				if(MODULE:GetData("points", {}, true)[text[1]].Map != game.GetMap()) then
					log("A spawnpoint with this name already exists, although not on this map!", NOTIFY_ERROR)
				else
					log("A spawnpoint with this name already exists on this map!", NOTIFY_ERROR)
				end
				return
			end
			if(tonumber(text[2]) == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return
			end
			if(not util.IsInWorld(sender:GetPos())) then
				log("Cannot make spawnpoint here.", NOTIFY_ERROR)
				return
			end
			MODULE:GetData("points", {}, true)[text[1]] = {
				Map = game.GetMap(),
				Pos = sender:GetPos(),
				Radius = tonumber(text[2])
			}
			glog(sender:GetName() .. " created a new spawnpoint '" .. text[1] .. "' at " .. table.concat({math.Round(sender:GetPos().x), math.Round(sender:GetPos().y), math.Round(sender:GetPos().z)}, ":"))
		end
	})
end

function MODULE:InitServer()

	if(not MODULE:GetData("uidUpdate", false)) then
		for i,k in pairs(MODULE:GetData("allocations", {}, true)) do
			-- ok, this is not good, but it's the only way this will work. Search through the ranks, try to find one that matches the start of the allocation.
			-- if a rank has a similar start, then this could screw up. (admin and administrator)
			local rankName = nil
			for i,k in pairs(Vermilion.Data.Ranks) do
				if(string.StartWith(i, k.Name) and string.len(k.Name) > string.len(rankName)) then
					rankName = k.Name
				end
			end
			if(rankName == nil) then
				MODULE:GetData("allocations", {}, true)[i] = nil
				continue
			end
			local obj = k
			local nr = Vermilion:GetRank(rankName):GetUID()
			MODULE:GetData("allocations", {}, true)[i] = nil
			MODULE:GetData("allocations", {}, true)[nr .. ":" .. string.Replace(i, rankName, "")] = obj 
		end
		MODULE:SetData("uidUpdate", true)
	end

	local function updateClient(vplayer)
		MODULE:NetStart("VGetSpawnpoints")
		local tab = {}
		for i,k in pairs(MODULE:GetData("points", {}, true)) do
			if(k.Map == game.GetMap()) then
				tab[i] = { p = k.Pos, r = k.Radius }
			end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	local function sendRankAllocs(vplayer)
		local tab = {}
		
		for i,k in pairs(Vermilion.Data.Ranks) do
			tab[k.UniqueID] = MODULE:GetData("allocations", {}, true)[k.UniqueID .. ":" .. game.GetMap()] or "Default"
		end
		MODULE:NetStart("VGetRankSpawnpoints")
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	self:NetHook("VGetSpawnpoints", updateClient)
	self:NetHook("VGetRankSpawnpoints", sendRankAllocs)

	self:NetHook("VDelSpawnpoint", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawnpoints")) then
			local point = net.ReadString()
			MODULE:GetData("points", {}, true)[point] = nil
			for i,k in pairs(MODULE:GetData("allocations", {}, true)) do
				if(k == point) then
					MODULE:GetData("allocations", {}, true)[i] = nil
				end
			end
		end

		updateClient(Vermilion:GetUsersWithPermission("manage_spawnpoints"))
		sendRankAllocs(Vermilion:GetUsersWithPermission("manage_spawnpoints"))
	end)

	self:NetHook("VGoto", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawnpoints")) then
			local point = net.ReadString()
			if(MODULE:GetData("points", {}, true)[point] != nil) then
				vplayer:SetPos(MODULE:GetData("points", {}, true)[point].Pos)
			end
		end
	end)

	local function spawnThink(ply, rankpoint)
		local tpos = rankpoint.Pos + Vector(math.Rand(-rankpoint.Radius, rankpoint.Radius), math.Rand(-rankpoint.Radius, rankpoint.Radius), 0)
			local Ents = ents.FindInBox(tpos + Vector(-16, -16, 0), tpos + Vector(16, 16, 72))
			if(ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED) then
				ply:SetPos(tpos)
				return
			end
			local Blockers = 0

			for k, v in pairs( Ents ) do
				if ( IsValid( v ) && v:GetClass() == "player" && v:Alive() ) then
					Blockers = Blockers + 1
				end
			end

			if(Blockers > 0) then
				timer.Simple(1, function()
					spawnThink(ply, rankpoint)
				end)
				return
			end
			ply:SetPos(tpos)
	end

	function MODULE:DoSpawning(vplayer)
		local rankpoint = MODULE:GetData("allocations", {}, true)[Vermilion:GetUser(vplayer):GetRankUID() .. ":" .. game.GetMap()]
		if(rankpoint != nil) then
			rankpoint = MODULE:GetData("points", {}, true)[rankpoint]
			spawnThink(vplayer, rankpoint)
		end
	end

	self:AddHook("PlayerSpawn", function(vplayer)
		MODULE:DoSpawning(vplayer)
	end)

	self:NetHook("VAssignSpawnpoint", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawnpoints")) then
			local rank = net.ReadString()
			local point = net.ReadString()

			MODULE:GetData("allocations", {}, true)[rank .. ":" .. game.GetMap()] = point
			sendRankAllocs(Vermilion:GetUsersWithPermission("manage_spawnpoints"))
		end
	end)

	self:NetHook("VResetSpawnpoint", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawnpoints")) then
			local rank = net.ReadString()

			MODULE:GetData("allocations", {}, true)[rank .. ":" .. game.GetMap()] = nil
			sendRankAllocs(Vermilion:GetUsersWithPermission("manage_spawnpoints"))
		end
	end)

end

function MODULE:InitClient()
	self:NetHook("VGetSpawnpoints", function()
		local paneldata = Vermilion.Menu.Pages['spawnpoint']
		local data = net.ReadTable()
		paneldata.SpawnpointList:Clear()
		for i,k in pairs(data) do
			paneldata.SpawnpointList:AddLine(i, table.concat({math.Round(k.p.x), math.Round(k.p.y), math.Round(k.p.z)}, ":"), k.r)
		end
	end)

	self:NetHook("VGetRankSpawnpoints", function()
		local paneldata = Vermilion.Menu.Pages['spawnpoint']
		local data = net.ReadTable()
		for i,k in pairs(data) do
			local done = false
			for i1,k1 in pairs(paneldata.RankList:GetLines()) do
				if(k1.UniqueRankID == i) then
					k1:SetValue(2, k)
					done = true
					break
				end
			end
			if(not done) then
				paneldata.RankList:AddLine(Vermilion:GetRankByID(i).Name, k)
			end
		end
	end)

	Vermilion.Menu:AddCategory("player", 4)

	Vermilion.Menu:AddPage({
		ID = "spawnpoint",
		Name = "Custom Spawnpoints",
		Order = 11,
		Category = "player",
		Size = { 750, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_spawnpoints")
		end,
		Builder = function(panel, paneldata)
			local spawnpointList = VToolkit:CreateList({
				cols = {
					"Name",
					"Position",
					"Radius"
				},
				multiselect = false
			})
			spawnpointList:SetPos(10, 30)
			spawnpointList:SetSize(300, panel:GetTall() - 75)
			spawnpointList:SetParent(panel)
			paneldata.SpawnpointList = spawnpointList

			VToolkit:CreateSearchBox(spawnpointList)
			VToolkit:CreateHeaderLabel(spawnpointList, "Spawnpoints"):SetParent(panel)

			local gotoBtn = VToolkit:CreateButton("Goto", function()
				MODULE:NetStart("VGoto")
				net.WriteString(spawnpointList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end)
			gotoBtn:SetParent(panel)
			gotoBtn:SetPos(10, panel:GetTall() - 35)
			gotoBtn:SetSize(145, 25)
			gotoBtn:SetDisabled(true)
			paneldata.GotoBtn = gotoBtn

			local delBtn = VToolkit:CreateButton("Delete", function()
				MODULE:NetStart("VDelSpawnpoint")
				net.WriteString(spawnpointList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end)
			delBtn:SetParent(panel)
			delBtn:SetPos(gotoBtn:GetX() + gotoBtn:GetWide() + 10, panel:GetTall() - 35)
			delBtn:SetSize(145, 25)
			delBtn:SetDisabled(true)
			paneldata.DelBtn = delBtn

			local rnkList = VToolkit:CreateList({
				cols = {
					"Name",
					"Assigned Point"
				},
				multiselect = false,
				sortable = false
			})
			rnkList:SetParent(panel)
			rnkList:SetPos(320, 30)
			rnkList:SetSize(250, panel:GetTall() - 40)
			paneldata.RankList = rnkList

			VToolkit:CreateSearchBox(rnkList)
			VToolkit:CreateHeaderLabel(rnkList, "Ranks"):SetParent(panel)

			local assignPointBtn = VToolkit:CreateButton("Assign Spawnpoint", function()
				MODULE:NetStart("VAssignSpawnpoint")
				net.WriteString(rnkList:GetSelected()[1].UniqueRankID)
				net.WriteString(spawnpointList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end)
			assignPointBtn:SetPos(rnkList:GetX() + rnkList:GetWide() + 10, (panel:GetTall() - 20) / 2)
			assignPointBtn:SetSize(panel:GetWide() - assignPointBtn:GetX() - 10, 20)
			assignPointBtn:SetDisabled(true)
			assignPointBtn:SetParent(panel)
			paneldata.AssignPointBtn = assignPointBtn

			local resetPointBtn = VToolkit:CreateButton("Reset Spawnpoint", function()
				MODULE:NetStart("VResetSpawnpoint")
				net.WriteString(rnkList:GetSelected()[1].UniqueRankID)
				net.SendToServer()
			end)
			resetPointBtn:SetPos(rnkList:GetX() + rnkList:GetWide() + 10, assignPointBtn:GetY() + assignPointBtn:GetTall() + 10)
			resetPointBtn:SetSize(panel:GetWide() - resetPointBtn:GetX() - 10, 20)
			resetPointBtn:SetDisabled(true)
			resetPointBtn:SetParent(panel)
			paneldata.ResetPointBtn = resetPointBtn

			function spawnpointList:OnRowSelected(index, line)
				gotoBtn:SetDisabled(self:GetSelected()[1] == nil)
				delBtn:SetDisabled(self:GetSelected()[1] == nil)
				assignPointBtn:SetDisabled(not (self:GetSelected()[1] != nil and rnkList:GetSelected()[1] != nil))
			end

			function rnkList:OnRowSelected(index, line)
				assignPointBtn:SetDisabled(not (self:GetSelected()[1] != nil and spawnpointList:GetSelected()[1] != nil))
				resetPointBtn:SetDisabled(self:GetSelected()[1] == nil)
			end

		end,
		OnOpen = function(panel, paneldata)
			Vermilion:PopulateRankTable(paneldata.RankList, false, true)
			MODULE:NetCommand("VGetSpawnpoints")
			MODULE:NetCommand("VGetRankSpawnpoints")
			paneldata.GotoBtn:SetDisabled(true)
			paneldata.DelBtn:SetDisabled(true)
			paneldata.AssignPointBtn:SetDisabled(true)
			paneldata.ResetPointBtn:SetDisabled(true)
		end
	})
end

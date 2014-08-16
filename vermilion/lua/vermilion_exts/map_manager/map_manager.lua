--[[
 Copyright 2014 Ned Hyett

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
local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Map Management"
EXTENSION.ID = "maps"
EXTENSION.Description = "Allows administrators to change the map with ease."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"map_management",
	"changelevel",
	"abort_map_change"
}
EXTENSION.PermissionDefinitions = {
	["map_management"] = "This player can see the Map tab in the Vermilion Menu and change the settings within.",
	["changelevel"] = "This player can use the changelevel chat command.",
	["abort_map_change"] = "This player can use the abortmapchange chat command."
}
EXTENSION.NetworkStrings = {
	"VScheduleMapChange",
	"VAbortMapChange",
	"VBroadcastSchedule",
	"VMapList"
}
EXTENSION.MapChangeInProgress = false
EXTENSION.MapChangeAt = nil
EXTENSION.MapChangeTo = nil
EXTENSION.MapCache = {}
EXTENSION.DisplayXPos1 = 0
EXTENSION.DisplayXPos2 = 0
EXTENSION.SoundTimer = nil

function EXTENSION:InitServer()

	-- The map codes are borrowed from getmaps.lua (garrysmod/lua/menu/getmaps.lua)
	local MapPatterns = {
		[ "^aoc_" ] = "Age of Chivalry",
		[ "^asi-" ] = "Alien Swarm",
		
		[ "lobby" ] = "Alien Swarm",
		
		[ "^ar_" ] = "Counter-Strike",
		[ "^cs_" ] = "Counter-Strike",
		[ "^de_" ] = "Counter-Strike",
		[ "^es_" ] = "Counter-Strike",
		[ "^fy_" ] = "Counter-Strike",
		[ "training1" ] = "Counter-Strike",
		
		[ "^dod_" ] = "Day Of Defeat",
		
		[ "cp_pacentro" ] = "Dino D-Day",
		[ "cp_snowypark" ] = "Dino D-Day",
		[ "cp_troina" ] = "Dino D-Day",
		[ "dm_canyon" ] = "Dino D-Day",
		[ "dm_depot" ] = "Dino D-Day",
		[ "dm_fortress_trex" ] = "Dino D-Day",
		[ "dm_gela_trex" ] = "Dino D-Day",
		[ "dm_hilltop" ] = "Dino D-Day",
		[ "dm_market" ] = "Dino D-Day",
		[ "dm_pacentro" ] = "Dino D-Day",
		[ "dm_snowypark" ] = "Dino D-Day",
		[ "dm_troina" ] = "Dino D-Day",
		[ "koth_hilltop" ] = "Dino D-Day",
		[ "koth_market" ] = "Dino D-Day",
		[ "koth_pacentro" ] = "Dino D-Day",
		[ "koth_snowypark" ] = "Dino D-Day",
		[ "obj_canyon" ] = "Dino D-Day",
		[ "obj_depot" ] = "Dino D-Day",
		[ "obj_fortress" ] = "Dino D-Day",

		[ "de_dam" ] = "DIPRIP",
		[ "dm_city" ] = "DIPRIP",
		[ "dm_refinery" ] = "DIPRIP",
		[ "dm_supermarket" ] = "DIPRIP",
		[ "dm_village" ] = "DIPRIP",
		[ "^ur_" ] = "DIPRIP",

		[ "^dys_" ] = "Dystopia",
		[ "^pb_" ] = "Dystopia",

		[ "credits" ] = "Half-Life 2",
		[ "^d1_" ] = "Half-Life 2",
		[ "^d2_" ] = "Half-Life 2",
		[ "^d3_" ] = "Half-Life 2",
		[ "intro" ] = "Half-Life 2",

		[ "^dm_" ] = "Half-Life 2: Deathmatch",
		[ "halls3" ] = "Half-Life 2: Deathmatch",

		[ "^ep1_" ] = "Half-Life 2: Episode 1",
		[ "^ep2_" ] = "Half-Life 2: Episode 2",
		[ "^ep3_" ] = "Half-Life 2: Episode 3", -- very funny Garry. *clap clap*
		
		[ "d2_lostcoast" ] = "Half-Life 2: Lost Coast",

		[ "^c0a" ] = "Half-Life: Source",
		[ "^c1a" ] = "Half-Life: Source",
		[ "^c2a" ] = "Half-Life: Source",
		[ "^c3a" ] = "Half-Life: Source",
		[ "^c4a" ] = "Half-Life: Source",
		[ "^c5a" ] = "Half-Life: Source",
		[ "^t0a" ] = "Half-Life: Source",

		[ "boot_camp" ] = "Half-Life Deathmatch: Source",
		[ "bounce" ] = "Half-Life Deathmatch: Source",
		[ "crossfire" ] = "Half-Life Deathmatch: Source",
		[ "datacore" ] = "Half-Life Deathmatch: Source",
		[ "frenzy" ] = "Half-Life Deathmatch: Source",
		[ "lambda_bunker" ] = "Half-Life Deathmatch: Source",
		[ "rapidcore" ] = "Half-Life Deathmatch: Source",
		[ "snarkpit" ] = "Half-Life Deathmatch: Source",
		[ "stalkyard" ] = "Half-Life Deathmatch: Source",
		[ "subtransit" ] = "Half-Life Deathmatch: Source",
		[ "undertow" ] = "Half-Life Deathmatch: Source",

		[ "^ins_" ] = "Insurgency",

		[ "^l4d" ] = "Left 4 Dead",

		[ "^c1m" ] = "Left 4 Dead 2",
		[ "^c2m" ] = "Left 4 Dead 2",
		[ "^c3m" ] = "Left 4 Dead 2",
		[ "^c4m" ] = "Left 4 Dead 2",
		[ "^c5m" ] = "Left 4 Dead 2",
		[ "^c6m" ] = "Left 4 Dead 2",
		[ "^c7m" ] = "Left 4 Dead 2",
		[ "^c8m" ] = "Left 4 Dead 2",
		[ "^c9m" ] = "Left 4 Dead 2",
		[ "^c10m" ] = "Left 4 Dead 2",
		[ "^c11m" ] = "Left 4 Dead 2",
		[ "^c12m" ] = "Left 4 Dead 2",
		[ "^c13m" ] = "Left 4 Dead 2",
		[ "curling_stadium" ] = "Left 4 Dead 2",
		[ "tutorial_standards" ] = "Left 4 Dead 2",
		[ "tutorial_standards_vs" ] = "Left 4 Dead 2",

		[ "clocktower" ] = "Nuclear Dawn",
		[ "coast" ] = "Nuclear Dawn",
		[ "downtown" ] = "Nuclear Dawn",
		[ "gate" ] = "Nuclear Dawn",
		[ "hydro" ] = "Nuclear Dawn",
		[ "metro" ] = "Nuclear Dawn",
		[ "metro_training" ] = "Nuclear Dawn",
		[ "oasis" ] = "Nuclear Dawn",
		[ "oilfield" ] = "Nuclear Dawn",
		[ "silo" ] = "Nuclear Dawn",
		[ "sk_metro" ] = "Nuclear Dawn",
		[ "training" ] = "Nuclear Dawn",

		[ "^bt_" ] = "Pirates, Vikings, & Knights II",
		[ "^lts_" ] = "Pirates, Vikings, & Knights II",
		[ "^te_" ] = "Pirates, Vikings, & Knights II",
		[ "^tw_" ] = "Pirates, Vikings, & Knights II",

		[ "^escape_" ] = "Portal",
		[ "^testchmb_" ] = "Portal",

		[ "e1912" ] = "Portal 2",
		[ "^mp_coop_" ] = "Portal 2",
		[ "^sp_a" ] = "Portal 2",

		[ "^arena_" ] = "Team Fortress 2",
		[ "^cp_" ] = "Team Fortress 2",
		[ "^ctf_" ] = "Team Fortress 2",
		[ "itemtest" ] = "Team Fortress 2",
		[ "^koth_" ] = "Team Fortress 2",
		[ "^mvm_" ] = "Team Fortress 2",
		[ "^pl_" ] = "Team Fortress 2",
		[ "^plr_" ] = "Team Fortress 2",
		[ "^sd_" ] = "Team Fortress 2",
		[ "^tc_" ] = "Team Fortress 2",
		[ "^tr_" ] = "Team Fortress 2",
		[ "^rd_" ] = "Team Fortress 2",

		[ "^zpa_" ] = "Zombie Panic! Source",
		[ "^zpl_" ] = "Zombie Panic! Source",
		[ "^zpo_" ] = "Zombie Panic! Source",
		[ "^zps_" ] = "Zombie Panic! Source",

		[ "^achievement_" ] = "Achievement",
		[ "^cinema_" ] = "Cinema",
		[ "^theater_" ] = "Cinema",
		[ "^xc_" ] = "Climb",
		[ "^deathrun_" ] = "Deathrun",
		[ "^dr_" ] = "Deathrun",
		[ "^gmt_" ] = "GMod Tower",
		[ "^jb_" ] = "Jailbreak",
		[ "^ba_jail_" ] = "Jailbreak",
		[ "^mg_" ] = "Minigames",
		[ "^phys_" ] = "Physics Maps",
		[ "^pw_" ] = "Pirate Ship Wars",
		[ "^ph_" ] = "Prop Hunt",
		[ "^rp_" ] = "Roleplay",
		[ "^sb_" ] = "Spacebuild",
		[ "^slender_" ] = "Stop it Slender",
		[ "^gms_" ] = "Stranded",
		[ "^surf_" ] = "Surf",
		[ "^ts_" ] = "The Stalker",
		[ "^zm_" ] = "Zombie Survival",
		[ "^zombiesurvival_" ] = "Zombie Survival",
		[ "^zs_" ] = "Zombie Survival",
	}
	
	-- load in the gamemode ones
	for i,gm in pairs(engine.GetGamemodes()) do
		local Name = gm.title or "Unnamed Gamemode"
		local Maps = string.Split(gm.maps, "|")
		if(Maps && gm.maps != "") then
			for k,pattern in pairs(Maps) do
				MapPatterns[pattern] = Name
			end
		end
	end
	
	local IgnoredMaps = { "background", "^test_", "^styleguide", "^devtest", "sdk_shader_samples", "^vst_", "d2_coast_02", "c4a1y", "d3_c17_02_camera", "ep1_citadel_00_demo", "credits", "intro" }

	timer.Simple(2, function()
		Vermilion.Log("WARNING: Building map cache... may cause GMod to hang... Please wait...")
		--EXTENSION.MapCache = Crimson.SearchRecursively("GAME", "maps", ".bsp")
		local cache = file.Find("maps/*.bsp", "GAME")
		for i,k in pairs(cache) do
			cache[i] = string.Replace(string.Replace(k, "maps/", ""), ".bsp", "")
		end
		EXTENSION.MapCache = {}
		for i,k in pairs(cache) do
			local ignore = false
			for dd, ignoredMap in pairs(IgnoredMaps) do
				if(string.find( k, ignoredMap)) then
					ignore = true
					break
				end
			end
			
			if(not ignore) then
				local Cat = "Other"
				local lowername = string.lower(k)
				for pattern, category in pairs(MapPatterns) do
					if((string.StartWith(pattern, "^") or string.EndsWith(pattern, "_") or string.EndsWith(pattern, "-")) && string.find(lowername, pattern)) then
						Cat = category
						break
					end
				end
				if(MapPatterns[k]) then Cat = MapPatterns[k] end
				table.insert(EXTENSION.MapCache, { k, Cat })
			end
		end
		
		Vermilion.Log("Map cache built!")
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("map_manager", "map_management")
	end)
	
	self:AddHook("Tick", function()
		if(EXTENSION.MapChangeInProgress) then
			if(os.time() >= EXTENSION.MapChangeAt) then
				EXTENSION.MapChangeInProgress = false
				EXTENSION.MapChangeAt = nil
				local to = EXTENSION.MapChangeTo
				EXTENSION.MapChangeTo = nil
				RunConsoleCommand("changelevel", to)
				net.Start("VAbortMapChange")
				net.Broadcast()
			end
		end
	end)
	
	self:NetHook("VScheduleMapChange", function(vplayer)
		if(vplayer:HasPermission("map_management")) then
			if(EXTENSION.MapChangeInProgress) then
				Vermilion:SendMessageBox(vplayer, "A map change is already in progress. Abort the map change to change to a new map!")
				return
			end
			EXTENSION.MapChangeInProgress = true
			EXTENSION.MapChangeTo = net.ReadString()
			local delay = tonumber(net.ReadString())
			EXTENSION.MapChangeAt = os.time() + delay
			net.Start("VBroadcastSchedule")
			net.WriteString(tostring(delay))
			net.WriteString(EXTENSION.MapChangeTo)
			net.Broadcast()
		end
	end)
	
	self:NetHook("VAbortMapChange", function(vplayer)
		if(vplayer:HasPermission("map_management")) then
			EXTENSION.MapChangeInProgress = false
			EXTENSION.MapChangeAt = nil
			EXTENSION.MapChangeTo = nil
			net.Start("VAbortMapChange")
			net.Broadcast()
		end
	end)
	
	self:NetHook("VMapList", function(vplayer)
		net.Start("VMapList")
		net.WriteTable(EXTENSION.MapCache)
		net.Send(vplayer)
	end)
	
	Vermilion:AddChatCommand("changelevel", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "changelevel", log)) then
			if(EXTENSION.MapChangeInProgress) then
				log("A map change is already in progress. Abort the map change to change to a new map.", VERMILION_NOTIFY_ERROR)
				return
			end
			if(table.Count(text) == 1) then
				if(file.Exists("maps/" .. text[1] .. ".bsp", "GAME")) then
					RunConsoleCommand("changelevel", text[1])
				else
					log("This map doesn't exist!", VERMILION_NOTIFY_ERROR)
				end
			elseif(table.Count(text) > 1) then
				if(tonumber(text[2]) == nil) then
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
				local delay = tonumber(text[2])
				EXTENSION.MapChangeInProgress = true
				EXTENSION.MapChangeTo = text[1]
				EXTENSION.MapChangeAt = os.time() + delay
				net.Start("VBroadcastSchedule")
				net.WriteString(tostring(delay))
				net.WriteString(EXTENSION.MapChangeTo)
				net.Broadcast()
			else
				log("Syntax: !changelevel <map> [delay in seconds]", VERMILION_NOTIFY_ERROR)
			end
		end	
	end, "<map> [delay in seconds]")
	
	Vermilion:AddChatCommand("abortmapchange", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "abort_map_change", log)) then
			if(not EXTENSION.MapChangeInProgress) then
				log("There is no map change in progress that can be aborted.", VERMILION_NOTIFY_ERROR)
			else
				EXTENSION.MapChangeInProgress = false
				EXTENSION.MapChangeAt = nil
				EXTENSION.MapChangeTo = nil
				net.Start("VAbortMapChange")
				net.Broadcast()
			end
		end
	end)
	
	Vermilion:AddChatCommand("reloadmap", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "reloadmap", log)) then
			if(EXTENSION.MapChangeInProgress) then
				Vermilion:SendMessageBox(vplayer, "A map change is already in progress. Abort the map change to change to a new map!")
				return
			end
			local delay = 10
			if(table.Count(text) > 0) then
				if(tonumber(text[1]) != nil) then
					delay = tonumber(text[1])
				else
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
			end
			EXTENSION.MapChangeInProgress = true
			EXTENSION.MapChangeTo = game.GetMap()
			EXTENSION.MapChangeAt = os.time() + delay
			net.Start("VBroadcastSchedule")
			net.WriteString(tostring(delay))
			net.WriteString(EXTENSION.MapChangeTo)
			net.Broadcast()
		end
	end, "[delay in seconds]")
	
end

function EXTENSION:InitClient()
	self:NetHook("VMapList", function()
		if(IsValid(EXTENSION.MapList)) then
			EXTENSION.MapList:Clear()
			local mapTab = net.ReadTable()
			EXTENSION.MapCache = mapTab
			for i,k in pairs(mapTab) do
				local ln = EXTENSION.MapList:AddLine(k[1], k[2])
				ln.OldCursorMoved = ln.OnCursorMoved
				ln.OldCursorEntered = ln.OnCursorEntered
				ln.OldCursorExited = ln.OnCursorExited
				
				function ln:OnCursorEntered()
					EXTENSION.PreviewPanel:SetVisible(true)
					EXTENSION.PreviewPanel.DHTML:OpenURL("asset://mapimage/" .. self:GetValue(1))
					
					if(self.OldCursorEntered) then self:OldCursorEntered() end
				end
				
				function ln:OnCursorExited()
					EXTENSION.PreviewPanel:SetVisible(false)
					
					if(self.OldCursorExited) then self:OldCursorExited() end
				end
				
				function ln:OnCursorMoved(x,y)
					if(IsValid(EXTENSION.PreviewPanel)) then
						local x, y = input.GetCursorPos()
						EXTENSION.PreviewPanel:SetPos(x - 275, y - 202)
					end
					
					if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
				end
			end
		end
	end)
	
	self:NetHook("VBroadcastSchedule", function()
		EXTENSION.MapChangeInProgress = true
		EXTENSION.MapChangeAt = os.time() + tonumber(net.ReadString())
		EXTENSION.MapChangeTo = net.ReadString()
	end)
	
	self:NetHook("VAbortMapChange", function()
		EXTENSION.MapChangeInProgress = false
		EXTENSION.MapChangeAt = nil
		EXTENSION.MapChangeTo = nil
	end)
	
	self:AddHook("HUDPaint", function()
		if(EXTENSION.MapChangeInProgress) then
			if(EXTENSION.SoundTimer != EXTENSION.MapChangeAt - os.time()) then
				local tr = EXTENSION.MapChangeAt - os.time()
				if(Vermilion:GetExtension("sound") != nil) then
					if(tr == 180) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_3minutestosingularity.wav", "MapChange")
					elseif(tr == 120) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_2minutestosingularity.wav", "MapChange")
					elseif(tr == 60) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_1minutetosingularity.wav", "MapChange")
					elseif(tr == 45) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_45sectosingularity.wav", "MapChange")
					elseif(tr == 30) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_30sectosingularity.wav", "MapChange")
					elseif(tr == 15) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_15sectosingularity.wav", "MapChange")
					elseif(tr == 10) then
						Vermilion:PlaySound("npc/overwatch/cityvoice/fcitadel_10sectosingularity.wav", "MapChange")
					end
				end
				EXTENSION.SoundTimer = EXTENSION.MapChangeAt - os.time()
			end
			local time = os.date("!%H:%M:%S", EXTENSION.MapChangeAt - os.time())
			local col = nil
			if(EXTENSION.MapChangeAt - os.time() > 10) then
				col = Color(0, 0, 0, 255)
			elseif((EXTENSION.MapChangeAt - os.time()) % 2 == 0 or (EXTENSION.MapChangeAt - os.time()) % 60 == 0 or ((EXTENSION.MapChangeAt - os.time()) % 5 == 0 and (EXTENSION.MapChangeAt - os.time()) > 10 and (EXTENSION.MapChangeAt - os.time()) < 30)) then
				col = Color(255, 0, 0, 255)
			else
				col = Color(0, 0, 0, 255)
			end
			if(time == nil) then
				return
			end
			local w,h = draw.WordBox( 8, ScrW() - EXTENSION.DisplayXPos1 - 10, 10, "Server is changing level to " .. tostring(EXTENSION.MapChangeTo) .. " in ".. time, "Default", col, Color(255, 255, 255, 255))
			EXTENSION.DisplayXPos1 = w
			
			if(not file.Exists("maps/" .. EXTENSION.MapChangeTo .. ".bsp", "GAME")) then
				local w1,h1 = draw.WordBox( 8, ScrW() - EXTENSION.DisplayXPos2 - 10, h + 20, "Warning: you do not have this map!", "Default", Color(255, 0, 0, 255), Color(255, 255, 255, 255))
				EXTENSION.DisplayXPos2 = w1
			end
		end
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("map_manager", "Map", "map.png", "Change the map", function(panel)
			EXTENSION.PreviewPanel = vgui.Create("DPanel")
			local x,y = input.GetCursorPos()
			
			EXTENSION.PreviewPanel:SetPos(x - 250, y - 64)
			EXTENSION.PreviewPanel:SetSize(148, 148)
			EXTENSION.PreviewPanel:SetParent(panel)
			EXTENSION.PreviewPanel:SetDrawOnTop(true)
			
			local dhtml = vgui.Create("DHTML")
			dhtml:SetPos(10,10)
			dhtml:SetSize(128, 128)
			dhtml:SetParent(EXTENSION.PreviewPanel)
			
			EXTENSION.PreviewPanel:SetVisible(false)
			EXTENSION.PreviewPanel.DHTML = dhtml
		
			local mapList = Crimson.CreateList({ "Name", "Game" }, false)
			mapList:SetParent(panel)
			mapList:SetPos(10, 30)
			mapList:SetSize(450, 470)
			EXTENSION.MapList = mapList
			
			local mapHeader = Crimson:CreateHeaderLabel(mapList, "Maps")
			mapHeader:SetParent(panel)
			
			local times = {
				{ "Immediately", 0, 0 },
				{ "In 30 seconds", 1, 30 },
				{ "In 1 minute", 2, 60 },
				{ "In 2 minutes", 3, 60 * 2 },
				{ "In 3 minutes", 4, 60 * 3 },
				{ "In 4 minutes", 5, 60 * 4 },
				{ "In 5 minutes", 6, 60 * 5 },
				{ "In 10 minutes", 7, 60 * 10 },
				{ "In 15 minutes", 8, 60 * 15 },
				{ "In 20 minutes", 9, 60 * 20 },
				{ "In 30 minutes", 10, 60 * 30 },
				{ "In 45 minutes", 11, 60 * 45 },
				{ "In 1 hour", 12, 60 * 60 },
				{ "In 2 hours", 13, 60 * 60 * 2 },
				{ "In 3 hours", 14, 60 * 60 * 3 },
				{ "In 4 hours", 15, 60 * 60 * 4 },
				{ "In 5 hours", 16, 60 * 60 * 5 },
				{ "In 10 hours", 17, 60 * 60 * 10 },
				{ "In 15 hours", 18, 60 * 60 * 15 },
				{ "In 20 hours", 19, 60 * 60 * 20 },
				{ "In 1 day", 20, 60 * 60 * 24 }
			}
			
			local searchBox = vgui.Create("DTextEntry")
			searchBox:SetParent(panel)
			searchBox:SetPos(10, 510)
			searchBox:SetSize(450, 25)
			searchBox:SetUpdateOnType(true)
			function searchBox:OnChange()
				local val = searchBox:GetValue()
				if(val == "" or val == nil) then
					EXTENSION.MapList:Clear()
					for i,k in pairs(EXTENSION.MapCache) do
						EXTENSION.MapList:AddLine(k[1], k[2])
					end
				else
					EXTENSION.MapList:Clear()
					for i,k in pairs(EXTENSION.MapCache) do
						if(string.find(string.lower(k[1]), string.lower(val)) or string.find(string.lower(k[2]), string.lower(val))) then
							local ln = EXTENSION.MapList:AddLine(k[1], k[2])
							ln.OldCursorMoved = ln.OnCursorMoved
							ln.OldCursorEntered = ln.OnCursorEntered
							ln.OldCursorExited = ln.OnCursorExited
							
							function ln:OnCursorEntered()
								EXTENSION.PreviewPanel:SetVisible(true)
								EXTENSION.PreviewPanel.DHTML:OpenURL("asset://mapimage/" .. self:GetValue(1))
								
								if(self.OldCursorEntered) then self:OldCursorEntered() end
							end
							
							function ln:OnCursorExited()
								EXTENSION.PreviewPanel:SetVisible(false)
								
								if(self.OldCursorExited) then self:OldCursorExited() end
							end
							
							function ln:OnCursorMoved(x,y)
								if(IsValid(EXTENSION.PreviewPanel)) then
									local x, y = input.GetCursorPos()
									EXTENSION.PreviewPanel:SetPos(x - 275, y - 202)
								end
								
								if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
							end
						end
					end
				end
			end
			
			local searchLogo = vgui.Create("DImage")
			searchLogo:SetParent(searchBox)
			searchLogo:SetPos(searchBox:GetWide() - 25, 5)
			searchLogo:SetImage("icon16/magnifier.png")
			searchLogo:SizeToContents()
			
			local timeDelayComboBox = vgui.Create("DComboBox")
			timeDelayComboBox:SetText("Time Delay")
			timeDelayComboBox.OnSelect = function(panel, index, value, data)
				timeDelayComboBox.Vermilion_Value = value
			end
			for k,v in ipairs(times) do
				timeDelayComboBox:AddChoice(v[1]);
			end
			timeDelayComboBox:ChooseOption(times[1][1])
			timeDelayComboBox:SetDark(true)
			timeDelayComboBox:SetParent(panel)
			timeDelayComboBox:SetPos(470, 120)
			timeDelayComboBox:SetSize(300, 25)
			
			
			local changeTimeHeader = Crimson:CreateHeaderLabel(timeDelayComboBox, "Change to the selected map:")
			changeTimeHeader:SetParent(panel)
			
			local currentMapLabel = Crimson:CreateHeaderLabel(timeDelayComboBox, "Current Map:")
			local cmx, cmy = currentMapLabel:GetPos()
			currentMapLabel:SetPos(cmx, 30)
			currentMapLabel:SetParent(panel)
			
			local currentMap = Crimson:CreateHeaderLabel(timeDelayComboBox, game.GetMap())
			local cmx1, cmy1 = currentMap:GetPos()
			currentMap:SetPos(cmx1, 50)
			currentMap:SetParent(panel)
			
			
			
			local changeMapButton = Crimson.CreateButton("GO!", function(self)
				if(table.Count(mapList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a map to change to!")
					return
				end
				net.Start("VScheduleMapChange")
				net.WriteString(mapList:GetSelected()[1]:GetValue(1))
				for i,k in pairs(times) do
					if(k[1] == timeDelayComboBox.Vermilion_Value) then
						net.WriteString(tostring(k[3])) -- client sends a delay instead of the time the map should change due to timezone interference.
						break
					end
				end
				net.SendToServer()
			end)
			changeMapButton:SetPos(582.5, 170)
			changeMapButton:SetSize(75, 25)
			changeMapButton:SetParent(panel)
			
			
			local abortLevelChangeButton = Crimson.CreateButton("Abort Level Change", function(self)
				Crimson:CreateConfirmDialog("Are you sure you want to abort the level change?", function()
					net.Start("VAbortMapChange")
					net.SendToServer()
				end)
			end)
			abortLevelChangeButton:SetPos(557.5, 220)
			abortLevelChangeButton:SetSize(120, 30)
			abortLevelChangeButton:SetParent(panel)
			
			if(table.Count(EXTENSION.MapCache) == 0) then
				net.Start("VMapList")
				net.SendToServer()
			else
				if(IsValid(EXTENSION.MapList)) then
					EXTENSION.MapList:Clear()
					for i,k in pairs(EXTENSION.MapCache) do
						local ln = EXTENSION.MapList:AddLine(k[1], k[2])
						ln.OldCursorMoved = ln.OnCursorMoved
						ln.OldCursorEntered = ln.OnCursorEntered
						ln.OldCursorExited = ln.OnCursorExited
						
						function ln:OnCursorEntered()
							EXTENSION.PreviewPanel:SetVisible(true)
							EXTENSION.PreviewPanel.DHTML:OpenURL("asset://mapimage/" .. self:GetValue(1))
							
							if(self.OldCursorEntered) then self:OldCursorEntered() end
						end
						
						function ln:OnCursorExited()
							EXTENSION.PreviewPanel:SetVisible(false)
							
							if(self.OldCursorExited) then self:OldCursorExited() end
						end
						
						function ln:OnCursorMoved(x,y)
							if(IsValid(EXTENSION.PreviewPanel)) then
								local x, y = input.GetCursorPos()
								EXTENSION.PreviewPanel:SetPos(x - 275, y - 202)
							end
							
							if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
						end
					end
				end
			end
		end, 9)
	end)
end

Vermilion:RegisterExtension(EXTENSION)
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
EXTENSION.Name = "Stat Manager"
EXTENSION.ID = "stats"
EXTENSION.Description = "Collects stats about the server"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"view_server_stats"
}
EXTENSION.NetworkStrings = {
	"VUpdateStats"
}
EXTENSION.StatData = {}

EXTENSION.Bars = {}

--[[
	Stats to keep:
	- Total uptime
	- Total unique visitors
	- Total playtime for all players
	- Busiest hours
	- Most connections from what country
	- Demographics (gender, age range, ect) (only with user consent)
	- Reports from players
	- Total kills
	- Most used console commands
	- Most used keybinds
	- Addons that are commonly found on connected clients (only with user consent)
	- Most commonly mounted source games (only with user consent)
	- Most active players
	- Total chat lines
	- Prop count per hour
	- Player count per hour
	- RDM reports
	- Tick rate per hour
	- Failed authentication
	- Most common playermodel
]]--

EXTENSION.UpdatedOnHour = false

function EXTENSION:UpdateHourlyStats(time)
	if(self.StatData["BusiestHours"] == nil) then self.StatData["BusiestHours"] = {} for i = 1, 24, 1 do self.StatData["BusiestHours"][i] = 0 end end
	if(self.StatData["BusiestHours"][time.hour + 1] == nil) then 
		self.StatData["BusiestHours"][time.hour + 1] = table.Count(player.GetAll())
	else
		self.StatData["BusiestHours"][time.hour + 1] = (self.StatData["BusiestHours"][time.hour + 1] + table.Count(player.GetAll())) / 2
	end
	
	print("Updated hourly stats.")
end

function EXTENSION:UpdateTrailingStats()
	
	local time = Crimson.TimeTable()
	if(time.min == 0 and not self.UpdatedOnHour) then
		self.UpdatedOnHour = true
		self:UpdateHourlyStats(time)
	elseif(self.UpdatedOnHour and time.min > 0) then
		self.UpdatedOnHour = false
	end
	
	self.StatData["UniqueVisitors"] = table.Count(Vermilion.UserStore)
	
	
end

function EXTENSION:InitServer()
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("stats", "view_server_stats")
	end)
	
	self:AddHook("Vermilion-SaveConfigs", "SaveData", function()
		EXTENSION:UpdateTrailingStats()
		Vermilion:SetSetting("StatsData", EXTENSION.StatData)
	end)
	
	Vermilion:AddChatCommand("forceupdatestats", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "view_server_stats")) then
			EXTENSION:UpdateHourlyStats(Crimson.TimeTable())
			log("Update forced.", VERMILION_NOTIFY_HINT)
		end
	end)
	
	timer.Create("VStatsStuff", 5, 0, function()
		if(EXTENSION.StatData["Uptime"] == nil) then EXTENSION.StatData["Uptime"] = 0 end
		EXTENSION.StatData["Uptime"] = EXTENSION.StatData["Uptime"] + 5
		EXTENSION:UpdateTrailingStats()
	end)
	
	self:NetHook("VUpdateStats", function(vplayer)
		local tab = {}
		for i,k in pairs(EXTENSION.StatData) do
			tab[i] = k
		end
		net.Start("VUpdateStats")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
end

function EXTENSION:InitClient()
	
	self:NetHook("VUpdateStats", function()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			if(i == "BusiestHours") then
				if(IsValid(EXTENSION.BusiestHours)) then
					for i1,k1 in pairs(EXTENSION.Bars) do
						if(IsValid(k1)) then k1:Remove() end
					end
					EXTENSION.Bars = {}
					
					local xpos = 250
					local ypos = 200
					
					for i1,k1 in pairs(k) do
						local bar = vgui.Create("DPanel")
						bar:SetBackgroundColor(Color(255, 0, 0))
						bar:SetPos(xpos, ypos - k1)
						bar:SetSize(10, k1)
						bar:SetParent(EXTENSION.BusiestHours)
						local lab = vgui.Create("DLabel")
						lab:SetText(tostring(i1 - 1))
						lab:SizeToContents()
						lab:SetPos(xpos, ypos + 15)
						lab:SetParent(EXTENSION.BusiestHours)
						lab:SetDark(true)
						xpos = xpos + 20
						table.insert(EXTENSION.Bars, bar)
					end
				end
			else
				
			end
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("stats", "Stats", "server_chart.png", "Get useful stats about your server to help you keep one step ahead.", function(panel)
			local tabs = vgui.Create("DPropertySheet")
			tabs:SetPos(-2, 0)
			tabs:SetParent(panel)
			tabs:SetSize(panel:GetWide() + 12, panel:GetTall() - 10)
			
			local warning = vgui.Create("DPanel")
			local basicStats = vgui.Create("DPanel")
			local busiestHours = vgui.Create("DPanel")
			
			
			EXTENSION.BasicStats = basicStats
			EXTENSION.BusiestHours = busiestHours
			
			tabs:AddSheet("Warning", warning, "icon16/error.png", false, false)
			tabs:AddSheet("Basic Stats", basicStats, "icon16/chart_curve.png", false, false)
			tabs:AddSheet("Busiest Hours", busiestHours, "icon16/time.png", false, false)
			
			local warningtext = vgui.Create("DLabel")
			warningtext:SetParent(warning)
			warningtext:SetPos(10, 10)
			warningtext:SetWrap(true)
			warningtext:SetWide(warning:GetWide() - 10)
			warningtext:SetText("This feature is under construction and is not complete. Please do not treat the data that it provides as accurate and make important decisions upon the data provided until it has been refined.")
			warningtext:SizeToContentsY()
			warningtext:SetDark(true)
			
			net.Start("VUpdateStats")
			net.SendToServer()
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)
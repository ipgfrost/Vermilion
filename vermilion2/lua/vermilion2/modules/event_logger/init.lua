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
MODULE.Name = "Event Logger"
MODULE.ID = "event_logger"
MODULE.Description = "Logs events that take place on the server."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"see_event_log"
}
MODULE.NetworkStrings = {
	"GetEvents",
	"SendEvent"
}

MODULE.SessionLog = {}

function MODULE:InitServer()

	--[[
		Types:
		- chat command DONE
		- kill DONE
		- join DONE
		- leave DONE
		- entity spawn DONE
		- dupe copy
		- dupe paste
		- toolgun use
		- spray DONE
		- use DONE
		- break prop DONE
		- enter vehicle DONE
		- leave vehicle DONE
		- drive prop DONE
		- pvp events DONE
		- pickup ammo
		- pickup weapon
		- voip activated
		- voip deactivated
		- activate noclip
	]]--

	function MODULE:AddEvent(icon, text)
		table.insert(self.SessionLog, { Time = os.time(), Icon = "icon16/" .. icon .. ".png", Text = text })
		MODULE:NetStart("SendEvent")
		net.WriteTable({ Time = os.time(), Icon = "icon16/" .. icon .. ".png", Text = text })
		net.Send(Vermilion:GetUsersWithPermission("see_event_log"))
	end

	self:NetHook("GetEvents", { "see_event_log" }, function(vplayer)
		MODULE:NetStart("GetEvents")
		net.WriteTable(MODULE.SessionLog)
		net.Send(vplayer)
	end)

	self:AddHook("PlayerConnect", function(name, ip)
		MODULE:AddEvent("connect", name .. " has connected to the server.")
	end)

	self:AddHook("PlayerDisconnected", function(ply)
		MODULE:AddEvent("disconnect", ply:GetName() .. " has disconneccted from the server.")
	end)

	self:AddHook("PlayerDeath", function(victim, inflictor, attacker)
		if(victim == attacker) then
			MODULE:AddEvent("gun", victim:GetName() .. " committed suicide.")
		else
			MODULE:AddEvent("gun", victim:GetName() .. " was killed by " .. attacker:GetName())
		end
	end)

	self:AddHook("PlayerSpawnedProp", function(ply, model, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. model .. ")")
	end)

	self:AddHook("PlayerSpawnedEffect", function(ply, model, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. model .. ")")
	end)

	self:AddHook("PlayerSpawnedNPC", function(ply, ent)
		MODULE:AddEvent("monkey", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. ent:GetModel() .. ")")
	end)

	self:AddHook("PlayerSpawnedRagdoll", function(ply, model, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. model .. ")")
	end)

	self:AddHook("PlayerSpawnedSENT", function(ply, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. ent:GetModel() .. ")")
	end)

	self:AddHook("PlayerSpawnedSWEP", function(ply, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. ent:GetModel() .. ")")
	end)

	self:AddHook("PlayerSpawnedVehicle", function(ply, ent)
		MODULE:AddEvent("bricks", ply:GetName() .. " spawned a " .. ent:GetClass() .. " with model (" .. ent:GetModel() .. ")")
	end)

	self:AddHook("PlayerSpray", function(ply)
		MODULE:AddEvent("paintcan", ply:GetName() .. " sprayed near " .. table.concat({ply:GetPos().x, ply:GetPos().y, ply:GetPos().z}, ":"))
	end)


	self:AddHook("PropBreak", function(attacker, prop)
		if(not IsValid(prop) or not IsValid(attacker)) then return end
		if(prop.Vermilion_Owner == nil) then
			MODULE:AddEvent("link_break", attacker:GetName() .. " broke " .. prop:GetClass() .. " with model (" .. prop:GetModel() .. ") near " .. table.concat({attacker:GetPos().x, attacker:GetPos().y, attacker:GetPos().z}, ":"))
			return
		end
		MODULE:AddEvent("link_break", attacker:GetName() .. " broke " .. prop:GetClass() .. "owned by " .. Vermilion:GetUserBySteamID(prop.Vermilion_Owner).Name)
	end)

	self:AddHook("PlayerEnteredVehicle", function(ply, veh, role)
		if(not IsValid(ply) or not IsValid(veh)) then return end
		if(veh.Vermilion_Owner == nil) then
			MODULE:AddEvent("car", ply:GetName() .. " entered " .. veh:GetClass() .. " with model (" .. veh:GetModel() .. ") near " .. table.concat({ply:GetPos().x, ply:GetPos().y, ply:GetPos().z}, ":"))
			return
		end
		if(not IsValid(ply) or not IsValid(veh) or veh.Vermilion_Owner == nil or Vermilion:GetUserBySteamID(veh.Vermilion_Owner) == nil) then return end
		MODULE:AddEvent("car", ply:GetName() .. " entered " .. veh:GetClass() .. " owned by " .. Vermilion:GetUserBySteamID(veh.Vermilion_Owner).Name)
	end)

	self:AddHook("PlayerLeaveVehicle", function(ply, veh)
		if(veh.Vermilion_Owner == nil) then
			MODULE:AddEvent("car_delete", ply:GetName() .. " exited " .. veh:GetClass() .. " with model (" .. veh:GetModel() .. ") near " .. table.concat({ply:GetPos().x, ply:GetPos().y, ply:GetPos().z}, ":"))
			return
		end
		MODULE:AddEvent("car_delete", ply:GetName() .. " exited " .. veh:GetClass() .. " owned by " .. Vermilion:GetUserBySteamID(veh.Vermilion_Owner).Name)
	end)

	local oldStartDriving = drive.PlayerStartDriving
	function drive.PlayerStartDriving(ply, ent, mode)
		if(ent.Vermilion_Owner == nil) then
			MODULE:AddEvent("lorry", ply:GetName() .. " is driving " .. ent:GetClass() .. " with model (" .. ent:GetModel() .. ") near " .. table.concat({ply:GetPos().x, ply:GetPos().y, ply:GetPos().z}, ":"))
			return
		end
		MODULE:AddEvent("lorry", ply:GetName() .. " is driving " .. ent:GetClass() .. " owned by " .. Vermilion:GetUserBySteamID(ent.Vermilion_Owner).Name)
		return oldStartDriving(ply, ent, mode)
	end



end

function MODULE:InitClient()
	self:NetHook("GetEvents", function()
		local paneldata = Vermilion.Menu.Pages["event_log"]
		paneldata.EventList:Clear()
		local var = net.ReadTable()
		for i,k in pairs(var) do
			timer.Simple(i / 30, function()
				local img = vgui.Create("DImage")
				if(k.Icon != nil) then
					img:SetImage(k.Icon)
				end
				img:SizeToContents()

				local ln = paneldata.EventList:AddLine(os.date(Vermilion.GetActiveLanguageFile().ShortDateTimeFormat, k.Time), "", k.Text)
				ln.Columns[2]:Add(img)
			end)
		end
		timer.Simple(table.Count(var) / 30 + 1, function()
			paneldata.EventList.VBar:AnimateTo(paneldata.EventList.VBar.CanvasSize + 100, 1, 0, -3)
		end)
	end)

	self:NetHook("SendEvent", function()
		if(Vermilion.Menu.IsOpen) then
			local paneldata = Vermilion.Menu.Pages["event_log"]
			local k = net.ReadTable()
			local img = vgui.Create("DImage")
			img:SetImage(k.Icon)
			img:SizeToContents()

			local ln = paneldata.EventList:AddLine(os.date(Vermilion.GetActiveLanguageFile().ShortDateTimeFormat, k.Time), "", k.Text)
			ln.Columns[2]:Add(img)

			paneldata.EventList.VBar:AnimateTo(paneldata.EventList.VBar.CanvasSize + 100, 1, 0, -3)
		end
	end)

	Vermilion.Menu:AddCategory("server", 2)

	self:AddMenuPage({
		ID = "event_log",
		Name = "Event Log",
		Order = 6,
		Category = "server",
		Size = { 800, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("see_event_log")
		end,
		Builder = function(panel, paneldata)
			local evtlist = VToolkit:CreateList({
				cols = {
					"Time",
					"",
					"Text"
				},
				multiselect = false,
				sortable = false
			})
			evtlist:Dock(FILL)
			evtlist:SetParent(panel)
			paneldata.EventList = evtlist
			evtlist.Columns[1]:SetFixedWidth(100)
			evtlist.Columns[2]:SetFixedWidth(16)
		end,
		OnOpen = function(panel)
			MODULE:NetCommand("GetEvents")
		end
	})
end

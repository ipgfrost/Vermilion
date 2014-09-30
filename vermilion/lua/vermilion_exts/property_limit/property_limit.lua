--[[
 Copyright 2014 Ned Hyett, 

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
EXTENSION.Name = "Property Limit"
EXTENSION.ID = "property_limit"
EXTENSION.Description = "Limits access to the contextual menu."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_property_limit"
}
EXTENSION.NetworkStrings = {
	"VBuildEntityMenu"
}

function EXTENSION:InitServer()
	
	--[[
		local tab = {}
		for i,k in pairs(extension.Permissions) do
			table.insert(tab, {Owner = extension.Name, Permission = k})
		end
		Crimson.Merge(self.AllPermissions, tab)
	]]--
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "CollectProperties", function()
		local tab = {}
		for i,k in pairs(properties.List) do
			table.insert(tab, { Owner = EXTENSION.Name, Permission = "use_" .. tostring(k.InternalName) .. "_property" })
		end
		Crimson.Merge(Vermilion.AllPermissions, tab)
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddOptions", function()
		local mgr = Vermilion:GetExtension("server_manager")
		mgr:AddOption("property_limit", "enabled", "Property Limiter:", "Combobox", "Limits", 0, 1, "manage_property_limit", { Options = { "Off", "Globally Disable", "Permissions Based" } })
	end)
	
	self:NetHook("VBuildEntityMenu", function(vplayer)
		if(EXTENSION:GetData("enabled", 1, true) == 1) then
			net.Start("VBuildEntityMenu")
			net.WriteTable(table.GetKeys(properties.List))
			net.Send(vplayer)
		end
		if(EXTENSION:GetData("enabled", 1, true) == 2) then return end
		local tab = {}
		for i,k in pairs(properties.List) do
			if(Vermilion:HasPermission(vplayer, "use_" .. tostring(k.InternalName) .. "_property")) then
				table.insert(tab, k.InternalName)
			end
		end
		net.Start("VBuildEntityMenu")
		net.WriteString(net.ReadString()) -- send back the code to make sure that we really want to build this menu
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
end

function EXTENSION:InitClient()
	
	--[[
		These two functions are borrowed from the properties.lua file to facilitate building the contextual menu.
	]]--
	local function AddToggleOption( data, menu, ent, ply, tr )

		if ( !menu.ToggleSpacer ) then
			menu.ToggleSpacer = menu:AddSpacer()
			menu.ToggleSpacer:SetZPos( 500 )
		end

		local option = menu:AddOption( data.MenuLabel, function() data:Action( ent, tr ) end )
		option:SetChecked( data:Checked( ent, ply ) )
		option:SetZPos( 501 )
		return option

	end

	local function AddOption( data, menu, ent, ply, tr )

		if ( data.Type == "toggle" ) then return AddToggleOption( data, menu, ent, ply, tr ) end

		if ( data.PrependSpacer ) then 
			menu:AddSpacer()
		end

		local option = menu:AddOption( data.MenuLabel, function() data:Action( ent, tr ) end )

		if ( data.MenuIcon ) then
			option:SetImage( data.MenuIcon )
		end

		if ( data.MenuOpen ) then
			data.MenuOpen( data, option, ent, tr )
		end

		return option

	end
	
	local lent = nil
	local ltr = nil
	local code = nil
	
	self:NetHook("VBuildEntityMenu", function()
		local rcode = net.ReadString()
		if(rcode == code) then
			local menu = DermaMenu()
			local tab = net.ReadTable()
			for i,k in SortedPairsByMemberValue(properties.List, "Order") do
				if(not k.Filter) then continue end
				if(not k:Filter(lent, LocalPlayer())) then continue end
				if(not table.HasValue(tab, k.InternalName)) then continue end
				local option = AddOption(k, menu, lent, LocalPlayer(), ltr)
				if(k.OnCreate) then k:OnCreate(menu, option) end
			end
			menu:Open()
		end
	end)
	
	function properties.OpenEntityMenu(ent, tr)
		lent = ent
		ltr = tr
		code = tostring(math.Rand(0, 1000000))
		net.Start("VBuildEntityMenu")
		net.WriteString(code)
		net.SendToServer()
	end
	
end

Vermilion:RegisterExtension(EXTENSION)
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
EXTENSION.Name = "Extra Properties"
EXTENSION.ID = "props"
EXTENSION.Description = "Adds some useful properties to the contextual menu"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}
EXTENSION.NetworkStrings = {
	"VCopySteamID",
	"VCopySteamID64",
	"VCopyIP"
}

function EXTENSION:InitServer()
	self:NetHook("VCopySteamID", function(vplayer)
		vplayer:SendLua("SetClipboardText('" .. net.ReadEntity():SteamID() .. "')")
	end)
	
	self:NetHook("VCopySteamID64", function(vplayer)
		vplayer:SendLua("SetClipboardText('" .. tostring(net.ReadEntity():SteamID64()) .. "')")
	end)
	
	self:NetHook("VCopyIP", function(vplayer)
		vplayer:SendLua("SetClipboardText('" .. tostring(net.ReadEntity():IPAddress()) .. "')")
	end)
end

function EXTENSION:InitShared()
	--[[
		make friendly
		make hostile
		hacked by alyx
		set model
		enable camera
		disable camera
		enable thumper
		disable thumper
		change weapon
		strip weapon
		dog - fetch
	]]--
	
	properties.Add("copysteamid", {
		MenuLabel = "Copy SteamID",
		Order = 10000,
		MenuIcon = "icon16/paste_plain.png",
		Filter = function(self, ent, ply)
			if(not IsValid(ent)) then return false end
			if(not ent:IsPlayer()) then return false end
			return true
		end,
		Action = function(self, ent)
			net.Start("VCopySteamID")
			net.WriteEntity(ent)
			net.SendToServer()
		end
	})
	
	properties.Add("copysteamid64", {
		MenuLabel = "Copy 64-Bit SteamID",
		Order = 10001,
		MenuIcon = "icon16/paste_plain.png",
		Filter = function(self, ent, ply)
			if(not IsValid(ent)) then return false end
			if(not ent:IsPlayer()) then return false end
			return true
		end,
		Action = function(self, ent)
			net.Start("VCopySteamID64")
			net.WriteEntity(ent)
			net.SendToServer()
		end
	})
	
	properties.Add("copyip", {
		MenuLabel = "Copy IP",
		Order = 10002,
		MenuIcon = "icon16/paste_plain.png",
		Filter = function(self, ent, ply)
			if(not IsValid(ent)) then return false end
			if(not ent:IsPlayer()) then return false end
			if(not ply:IsAdmin()) then return false end
			return true
		end,
		Action = function(self, ent)
			net.Start("VCopyIP")
			net.WriteEntity(ent)
			net.SendToServer()
		end
	})
	
	properties.Add("copyname", {
		MenuLabel = "Copy Name",
		Order = 10003,
		MenuIcon = "icon16/paste_plain.png",
		Filter = function(self, ent, ply)
			if(not IsValid(ent)) then return false end
			if(not ent:IsPlayer()) then return false end
			return true
		end,
		Action = function(self, ent)
			SetClipboardText(ent:GetName())
		end
	})
end

Vermilion:RegisterExtension(EXTENSION)
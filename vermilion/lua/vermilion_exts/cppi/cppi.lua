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
EXTENSION.Name = "Experimental CPPI Module"
EXTENSION.ID = "cppi"
EXTENSION.Description = "Implements the CPPI protocol"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}

EXTENSION.UidCache = {}

CPPI = {}

function EXTENSION:InitServer()
	
	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		if(self.Vermilion_Owner == nil) then return nil, nil end
		local oPlayer = Crimson.LookupPlayerBySteamID(self.Vermilion_Owner)
		return oPlayer, CPPI.CPPI_NOTIMPLEMENTED
	end
	
	
	function eMeta:CPPISetOwner(vplayer)
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) == nil) then
				Vermilion.Log("Warning (" .. tostring(self) .. "): prop owner was overwritten by CPPI!")
				self.Vermilion_Owner = vplayer:SteamID()
				self:SetNWString("Vermilion_Owner", vplayer:SteamID())
				return true
			end
		end
		return false
	end
	
	function eMeta:CPPISetOwnerUID( uid )
		local vplayer = Crimson.LookupPlayerByName(CPPI.GetNameFromUID(uid))
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) == nil) then
				self.Vermilion_Owner = vplayer:SteamID()
				return true
			end
		end
		return false
	end
	
	function eMeta:CPPICanTool( vplayer, tool )
		if(Vermilion:GetExtension("prop_protect") != nil) then
			return Vermilion:GetExtension("prop_protect"):CanTool(vplayer, self, tool) == nil
		end
		return true -- we can't decide since toolgun management is disabled.
	end
	
	function eMeta:CPPICanPhysgun( vplayer )
		if(Vermilion:GetExtension("prop_protect") != nil) then
			return Vermilion:GetExtension("prop_protect"):CanPhysgun( vplayer, self )
		end
		return true -- we can't decide since physgun management is disabled.
	end
	
	function eMeta:CPPICanPickup( vplayer )
		if(Vermilion:GetExtension("prop_protect") != nil) then
			return Vermilion:GetExtension("prop_protect"):CanGravGunPickup( vplayer, self )
		end
		return true -- we can't decide since gravgun management is disabled.
	end
	
	function eMeta:CPPICanPunt( vplayer )
		if(Vermilion:GetExtension("prop_protect") != nil) then
			return Vermilion:GetExtension("prop_protect"):CanGravGunPunt( vplayer, self )
		end
		return true -- we can't decide since gravgun management is disabled.
	end
	
end

function EXTENSION:InitClient()

	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	
end

function EXTENSION:InitShared()
	CPPI.CPPI_DEFER = -666888
	CPPI.CPPI_NOTIMPLEMENTED = -999333
	
	function CPPI.GetName()
		return "Vermilion CPPI Module"
	end
	
	function CPPI.GetVersion()
		return Vermilion.GetVersion()
	end
	
	function CPPI.GetInterfaceVersion()
		return 1.1
	end
	
	function CPPI.GetNameFromUID( uid )
		if(EXTENSION.UidCache[uid] != nil) then return EXTENSION.UidCache[uid] end
		for i,k in pairs(player.GetAll()) do
			if(IsValid(k)) then
				if(not table.HasValue(EXTENSION.UidCache, k:GetName())) then
					EXTENSION.UidCache[k:UniqueID()] = k:GetName()
				end
			end
		end
		if(EXTENSION.UidCache[uid] != nil) then return EXTENSION.UidCache[uid] end
		return nil
	end
	
	local pMeta = FindMetaTable("Player")
	function pMeta:CPPIGetFriends()
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	
	
end

Vermilion:RegisterExtension(EXTENSION)
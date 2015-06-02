--[[
 Copyright 2015 Ned Hyett

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

function VToolkit.NetSanitiseTable(tab)
	local rtab = {}
	for i,k in pairs(tab) do
		if(istable(k)) then rtab[i] = VToolkit.NetSanitiseTable(k) else
			if(not (isfunction(k))) then
				rtab[i] = k
			end
		end
	end
	return rtab
end

function net.ReadBoolean()
	if(net.ReadBool) then return net.ReadBool() end -- only do this on newer versions to keep compatibility with old GMod servers.
	return net.ReadBit() == 1
end

-- just to make it look nicer
function net.WriteBoolean(bool)
	if(net.WriteBool) then -- only do this on newer versions to keep compatibility with old GMod servers.
		net.WriteBool(bool)
		return
	end
	net.WriteBit(bool)
end

VToolkit.TimeDiff = 0

function VToolkit:ServerTime()
	if(SERVER) then return os.time() end
	return os.time() + self.TimeDiff
end


if(SERVER) then
	util.AddNetworkString("VTimeSync")
	-- use hook.Add here since Vermilion hasn't overwritten the hooks yet.
	hook.Add("PlayerSpawn", "VTimeSync", function(ply)
		net.Start("VTimeSync")
		net.WriteUInt(os.time(), 32)
		net.Send(ply)
	end)
else
	net.Receive("VTimeSync", function(len)
		VToolkit.TimeDiff = net.ReadUInt(32) - os.time()
		print("VToolkit: Synced the client time with the server.")
	end)
end

--[[
	The following segment of code is here to replace the screwed up network variables that were introduced in the latest version of GMod. (9/3/15)
]]--

-- GLOABL NETWORKING VALUES
VToolkit.GlobalValues = {}
VToolkit.EntityValues = { { } }

local eMeta = FindMetaTable("Entity")
function eMeta:SetGlobalValue(name, value)
	if(VToolkit.EntityValues[self:EntIndex()] == nil) then
		VToolkit.EntityValues[self:EntIndex()] = {}
	end
	VToolkit.EntityValues[self:EntIndex()][name] = value
	if(SERVER) then
		net.Start("VEGVar")
		net.WriteEntity(self)
		net.WriteString(name)
		net.WriteType(value)
		net.Broadcast()
	end
end

function eMeta:GetGlobalValue(name, default)
	if(VToolkit.EntityValues[self:EntIndex()] == nil) then return default end
	return VToolkit.EntityValues[self:EntIndex()][name] or default
end

hook.Add("EntityRemoved", "VToolkitEGVAR_Remove", function(entity)
	VToolkit.EntityValues[entity:EntIndex()] = nil
end)


function VToolkit:SetGlobalValue(name, value)
	VToolkit.GlobalValues[name] = value
	if(SERVER) then
		net.Start("VGVar")
		net.WriteString(name)
		net.WriteType(value)
		net.Broadcast()
	end
end

function VToolkit:GetGlobalValue(name, default)
	if(VToolkit.GlobalValues[name] == nil) then return default end
	return VToolkit.GlobalValues[name]
end

if(SERVER) then
	util.AddNetworkString("VGVar")
	util.AddNetworkString("VEGVar")

	hook.Add("PlayerInitialSpawn", "VToolkitGVAR", function(vplayer)
		timer.Simple(1, function()
			for i,k in pairs(VToolkit.GlobalValues) do
				net.Start("VGVar")
				net.WriteString(i)
				net.WriteType(k)
				net.Send(vplayer)
			end
			for i,k in pairs(VToolkit.EntityValues) do
				for i1,k1 in pairs(k) do
					net.Start("VEGVar")
					net.WriteUInt(i, 16)
					net.WriteString(i1)
					net.WriteType(k1)
					net.Send(vplayer)
				end
			end
		end)
	end)

else
	net.Receive("VGVar", function()
		VToolkit.GlobalValues[net.ReadString()] = net.ReadType(net.ReadUInt(8))
	end)
	net.Receive("VEGVar", function()
		local ent = net.ReadUInt(16)
		if(VToolkit.EntityValues[ent] == nil) then VToolkit.EntityValues[ent] = {} end
		VToolkit.EntityValues[ent][net.ReadString()] = net.ReadType(net.ReadUInt(8))
	end)

end

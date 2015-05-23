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

function Vermilion:CreateUserObj(name, steamid, rank, permissions)
	local usr = {}

	usr.Name = name
	usr.SteamID = steamid
	usr.Rank = rank
	usr.Permissions = permissions
	usr.Playtime = 0
	usr.Kills = 0
	usr.Deaths = 0
	usr.Achievements = {}
	usr.Karma = { Positive = {}, Negative = {} }


	usr.Metadata = {}

	self:AttachUserFunctions(usr)

	return usr
end

function Vermilion:AttachUserFunctions(usrObject)
	if(Vermilion.PlayerMetaTable == nil) then
		local meta = {}
		
		
		function meta:GetName()
			return self.Name
		end

		function meta:GetRank()
			return Vermilion:GetRankByID(self.Rank)
		end

		function meta:GetRankUID()
			return self.Rank
		end

		function meta:GetRankName()
			return self:GetRank():GetName()
		end

		function meta:GetEntity()
			for i,k in pairs(VToolkit.GetValidPlayers()) do
				if(k:SteamID() == self.SteamID) then return k end
			end
		end
		
		function meta:IsOnline()
			return IsValid(self:GetEntity())
		end

		function meta:IsImmune(other)
			if(istable(other)) then
				return self:GetRank():IsImmuneToRank(other)
			end
			if(IsValid(other)) then
				return self:GetRank():IsImmuneToRank(Vermilion:GetUser(other):GetRank())
			end
		end

		function meta:SetRank(rank, override)
			if(CLIENT) then
				Vermilion.Log("Cannot call user:SetRank() on client!")
				return
			end
			if(Vermilion:HasRankID(rank) or override) then
				local old = self.Rank
				self.Rank = rank
				Vermilion:GetDriver():SetUserRank(self)
				hook.Run(Vermilion.Event.PlayerChangeRank, self, old, rank)
				local ply = self:GetEntity()
				if(IsValid(ply)) then
					Vermilion:AddNotification(ply, "change_rank", {self.Rank})
					ply:SetNWString("Vermilion_Rank", self.Rank)
					Vermilion:BroadcastActiveUserData()
				end
			end
		end

		function meta:HasPermission(permission)
			if(permission != "*") then
				local has = false
				for i,k in pairs(Vermilion.AllPermissions) do
					if(k.Permission == permission) then has = true break end
				end
				if(not has) then
					Vermilion.Log(Vermilion:TranslateStr("config:unknownpermission", { permission }))
				end
			end
			if(table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")) then return true end
			return self:GetRank():HasPermission(permission)
		end

		function meta:GetColour()
			return self:GetRank():GetColour()
		end
		
		function meta:GetNetPacket()
			local usr = {}

			usr.Name = self.Name
			usr.SteamID = self.SteamID
			usr.Rank = self.Rank
			usr.Permissions = self.Permissions
			usr.Playtime = self.Playtime
			usr.Kills = self.Kills
			usr.Deaths = self.Deaths
			usr.Achievements = self.Achievements
			usr.Karma = self.Karma

			return usr
		end
		
		Vermilion.PlayerMetaTable = meta
	end

	if(not Vermilion:GetData("UIDUpgraded", false)) then
		if(Vermilion:GetRank(usrObject.Rank) != nil) then
			usrObject.Rank = Vermilion:GetRank(usrObject.Rank):GetUID()
		end
	end

	setmetatable(usrObject, { __index = Vermilion.PlayerMetaTable }) // <-- The metatable creates phantom functions.
end
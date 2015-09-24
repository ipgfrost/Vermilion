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

function Vermilion:CreateRankObj(name, permissions, protected, colour, icon, inherits)
	local rnk = {}

	rnk.Name = name
	rnk.UniqueID = Vermilion:CreateRankID()
	rnk.Permissions = permissions or {}
	rnk.Protected = protected or false
	if(colour == nil) then rnk.Colour = { 255, 255, 255 } else
		rnk.Colour = { colour.r, colour.g, colour.b }
	end
	rnk.Icon = icon
	rnk.InheritsFrom = inherits

	rnk.Metadata = {}

	self:AttachRankFunctions(rnk)

	return rnk
end

function Vermilion:AttachRankFunctions(rankObj)

	if(Vermilion.RankMetaTable == nil) then
		local meta = {}

		function meta:GetName()
			return self.Name
		end

		function meta:GetUID()
			return self.UniqueID
		end

		function meta:IsDefault()
			return self.UniqueID == Vermilion:GetDefaultRank()
		end

		function meta:IsProtected()
			return self.Protected
		end

		function meta:IsImmuneToRank(rank)
			return self:GetImmunity() < rank:GetImmunity()
		end

		function meta:GetImmunity()
			return Vermilion:GetDriver():GetRankImmunity(self)
		end

		function meta:MoveUp()
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:MoveUp() on client!")
				return
			end
			if(self:GetImmunity() <= 2) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:cantmoveup"))
				return false
			end
			if(self:IsProtected()) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:moveprotected"))
				return false
			end
			Vermilion:GetDriver():IncreaseRankImmunity(self)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
			return true
		end

		function meta:MoveDown()
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:MoveDown() on client!")
				return
			end
			if(self:GetImmunity() == table.Count(Vermilion.Data.Ranks)) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:cantmovedown"))
				return false
			end
			if(self:IsProtected()) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:moveprotected"))
				return false
			end
			Vermilion:GetDriver():DecreaseRankImmunity(self)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
			return true
		end

		function meta:GetUsers()
			local users = {}
			for i,k in pairs(Vermilion:GetDriver():GetAllUsers()) do
				if(k:GetRankUID() == self.UniqueID and k:GetEntity() != nil) then
					table.insert(users, k:GetEntity())
				end
			end
			return users
		end

		function meta:GetUserObjects()
			local users = {}
			for i,k in pairs(Vermilion:GetDriver():GetAllUsers()) do
				if(k:GetRankUID() == self.UniqueID) then table.insert(users, k) end
			end
			return users
		end

		function meta:Rename(newName)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:Rename() on client!")
				return
			end
			-- if(self:IsProtected()) then
			-- 	Vermilion.Log(Vermilion:TranslateStr("config:rank:renameprotected"))
			-- 	return false
			-- end
			Vermilion.Log(Vermilion:TranslateStr("config:rank:renamed", { self.Name, newName }))
			hook.Run(Vermilion.Event.RankRenamed, self.UniqueID, self.Name, newName)
			self.Name = newName
			Vermilion:GetDriver():RenameRank(self)
			Vermilion:BroadcastRankData()
			return true
		end

		function meta:Delete()
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:Delete() on client!")
				return
			end
			if(self:IsProtected()) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:deleteprotected"))
				return false
			end
			for i,k in pairs(self:GetUsers()) do
				k:SetRank(Vermilion:GetDefaultRank())
			end
			for i,k in pairs(Vermilion:GetDriver():GetAllRanks()) do
				if(k.InheritsFrom == self.UniqueID) then
					k:SetParent(nil)
				end
			end
			Vermilion:GetDriver():DeleteRank(self)
			Vermilion:BroadcastRankData()
			Vermilion.Log(Vermilion:TranslateStr("config:rank:deleted", { self.Name }))
			hook.Run(Vermilion.Event.RankDeleted, self.UniqueID)
			return true
		end

		function meta:SetParent(parent)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:SetParent() on client!")
				return
			end
			if(parent == nil) then
				self.InheritsFrom = nil
				Vermilion:GetDriver():SetRankParent(self, nil)
				Vermilion:BroadcastRankData()
				return
			end
			self.InheritsFrom = parent:GetUID()
			Vermilion:GetDriver():SetRankParent(self, parent:GetUID())
			Vermilion:BroadcastRankData()
		end

		function meta:AddPermission(permission)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:AddPermission() on client!")
				return
			end
			if(self:IsProtected()) then return end
			if(not istable(permission)) then permission = { permission } end
			for i,perm in pairs(permission) do
				if(not self:HasPermission(perm)) then
					local has = false
					for i,k in pairs(Vermilion.AllPermissions) do
						if(k.Permission == perm) then has = true break end
					end
					if(has) then
						table.insert(self.Permissions, perm)
					end
				end
			end
			Vermilion:GetDriver():UpdateRankPermissions(self)
			Vermilion:BroadcastRankData()
		end

		function meta:RevokePermission(permission)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:RevokePermission() on client!")
				return
			end
			if(self:IsProtected()) then return end
			if(not istable(permission)) then permission = { permission } end
			for i,perm in pairs(permission) do
				if(self:HasPermission(perm)) then
					local has = false
					for i,k in pairs(Vermilion.AllPermissions) do
						if(k.Permission == perm) then has = true break end
					end
					if(has) then
						table.RemoveByValue(self.Permissions, perm)
					end
				end
			end
			Vermilion:GetDriver():UpdateRankPermissions(self)
			Vermilion:BroadcastRankData()
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
			if(self.InheritsFrom != nil) then
				if(Vermilion:GetRank(self.InheritsFrom) == nil) then
					Vermilion.Log("Bad rank inheritance for '" .. self.Name .. "'; Cannot find parent rank. Removing link.")
					self.InheritsFrom = nil
				else
					if(Vermilion:GetRank(self.InheritsFrom):HasPermission(permission)) then return true end
				end
			end
			return table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")
		end

		function meta:SetColour(colour)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:SetColour() on client!")
				return
			end
			if(IsColor(colour)) then
				self.Colour = { colour.r, colour.g, colour.b }
				Vermilion:GetDriver():SetRankColour(self)
				Vermilion:BroadcastRankData()
			elseif(istable(colour)) then
				self.Colour = colour
				Vermilion:GetDriver():SetRankColour(self)
				Vermilion:BroadcastRankData()
			else
				Vermilion.Log(Vermilion:TranslateStr("config:rank:badcolour", { type(colour) }))
			end
		end

		function meta:GetColour()
			return Color(self.Colour[1], self.Colour[2], self.Colour[3])
		end

		function meta:GetIcon()
			return self.Icon
		end

		function meta:SetIcon(icon)
			if(CLIENT) then
				Vermilion.Log("Cannot call rank:SetIcon() on client!")
				return
			end
			self.Icon = icon
			Vermilion:GetDriver():SetRankIcon(self)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
		end

		function meta:GetNetPacket()
			local rnk = {}

			rnk.Name = self.Name
			rnk.UniqueID = self.UniqueID
			rnk.Permissions = self.Permissions or {}
			rnk.Protected = self.Protected or false
			if(self.Colour == nil) then rnk.Colour = { 255, 255, 255 } else
				if(IsColor(self.Colour)) then
					rnk.Colour = { self.Colour.r, self.Colour.g, self.Colour.b }
				else
					rnk.Colour = { self.Colour[1], self.Colour[2], self.Colour[3] }
				end
			end
			rnk.Icon = self.Icon
			rnk.InheritsFrom = self.InheritsFrom

			return rnk
		end

		Vermilion.RankMetaTable = meta
	end

	if(rankObj.UniqueID == nil) then -- upgrade existing configurations.
		Vermilion.Log("Old-style rank detected (" .. rankObj.Name .. "); upgrading to UID...")
		rankObj.UniqueID = Vermilion:CreateRankID()
		Vermilion.Log("Rank given UID '" .. rankObj.UniqueID .. "'!")
	end

	setmetatable(rankObj, { __index = Vermilion.RankMetaTable }) // <-- The metatable creates phantom functions.
end

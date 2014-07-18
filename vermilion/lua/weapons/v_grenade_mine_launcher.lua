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

SWEP.PrintName = "Grenade Mine Launcher"
SWEP.Author = "Ned - Vermilion"
SWEP.Instructions = "Left click to fire lots of grenades, right click to detonate"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Vermilion"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom	= false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
-- npc_grenade_frag

SWEP.Grenades = {}

function SWEP:PrimaryAttack()
	self:ShootEffects()
	self.Weapon:SetNextPrimaryFire(CurTime() + 0.07)
	if(SERVER) then
		if(self.Grenades[self.Owner:GetName()] == nil) then
			self.Grenades[self.Owner:GetName()] = {}
		end
		if(table.Count(self.Grenades[self.Owner:GetName()]) >= 200) then
			Vermilion:SendNotify(self.Owner, "Too many grenades!", 3, NOTIFY_ERROR)
			self.Weapon:SetNextPrimaryFire(CurTime() + 3)
			return
		end
		local grenade = ents.Create("npc_grenade_frag")
		if(not IsValid(grenade)) then 
			print("NOT VALID")
			return 
		end
		grenade:SetModel("models/weapons/w_npcnade.mdl")
		grenade:SetPos( self.Owner:EyePos() + ( self.Owner:GetAimVector() * 64 ) )
		
		grenade:SetOwner(self.Owner)
		
		grenade:Spawn()
		
		
		local phys = grenade:GetPhysicsObject()
		if ( not IsValid( phys ) ) then grenade:Remove() return end
		
		local velocity = self.Owner:GetAimVector()
		velocity = velocity * 500
		velocity = velocity + ( VectorRand() * 10 ) -- a random element
		phys:ApplyForceCenter( velocity )
		
		
		
		table.insert(self.Grenades[self.Owner:GetName()], grenade)
	end
end

function SWEP:SecondaryAttack()
	if(SERVER) then
		if(self.Grenades[self.Owner:GetName()] == nil) then
			self.Grenades[self.Owner:GetName()] = {}
		end
		for i,k in pairs(self.Grenades[self.Owner:GetName()]) do
			if(IsValid(k)) then k:Fire("SetTimer", "0", 0) end
		end
		self.Grenades[self.Owner:GetName()] = {}
	end
end
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

-- Author: Jacob Forsyth

SWEP.Author = "Foxworrior"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Category = "Vermilion"

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.ClipSize = 9001
SWEP.Primary.DefaultClip = 9001
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = 9001
SWEP.Secondary.DefaultClip = 9001
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.PrintName = "Babygun"
SWEP.Slot = 1
SWEP.SlotPos = 99
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local Model = "models/props_c17/doll01.mdl"


function SWEP:FireBaby(model_file)
	local trace = self.Owner:GetEyeTrace()
	
	self.BaseClass.ShootEffects(self)

	if(CLIENT) then return end

	local entity = ents.Create("prop_physics")
	entity:SetModel(model_file)
	entity:SetPos(self.Owner:EyePos() + (self.Owner:GetAimVector() * 64))
	entity:SetAngles(self.Owner:EyeAngles())
	entity:Spawn()

	local phys = entity:GetPhysicsObject()

	if !(phys && IsValid(phys)) then entity:Remove() return end

	local velocity = self.Owner:GetAimVector()
	velocity = velocity * 1000000

	phys:ApplyForceCenter(velocity)--self.Owner:GetAimVector():GetNormalized() * math.pow(trace.HitPos:Length(),3))
	phys:AddAngleVelocity(Vector( math.random(1500, 3000), math.random(1500, 3000), math.random(1500, 3000)))
	
	timer.Simple(5, function()
		entity:Remove()
	end)
end

function SWEP:PrimaryAttack()
	self:FireBaby(Model)

end

function SWEP:SecondaryAttack()
	self:FireBaby(Model)
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.01 )
end






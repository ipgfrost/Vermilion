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
SWEP.Purpose = "A shotgun which is OP!"
SWEP.Instructions = "Left click to fire once, Right click to fire loads"
SWEP.Category = "Vermilion"

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/weapons/v_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.HoldType = "shotgun"

SWEP.Primary.ClipSize = 9001
SWEP.Primary.DefaultClip = 9001
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Buckshot"

SWEP.Secondary.ClipSize = 9001
SWEP.Secondary.DefaultClip = 9001
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "Buckshot"

SWEP.PrintName = "Machine Shotgun"
SWEP.Slot = 1
SWEP.SlotPos = 99
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.FiresUnderwater = true

local ShootSound = Sound("Weapon_Shotgun.Single")

function SWEP:PrimaryAttack()
	self:EmitSound(ShootSound)
	self:ShootEffects()
	self.Weapon:FireBullets({ Attacker = self.Owner, Callback = function() end, Damage = 10, Force = 250, Distance = 600, HullSize = 1, Num = 30, Tracer = 1, AmmoType = "Buckshot", TracerName = "Buckshot", Dir = self.Owner:GetAimVector(), Spread = Vector( 0.25, 0.25 ), Src = self.Owner:EyePos()}, nil)
end
function SWEP:SecondaryAttack()
	self:EmitSound(ShootSound)
	self:ShootEffects()
	self.Weapon:FireBullets({ Attacker = self.Owner, Callback = function() end, Damage = 10, Force = 250, Distance = 600, HullSize = 1, Num = 30, Tracer = 1, AmmoType = "Buckshot", TracerName = "Buckshot", Dir = self.Owner:GetAimVector(), Spread = Vector( 0.25, 0.25 ), Src = self.Owner:EyePos()}, nil)
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.01 )
end

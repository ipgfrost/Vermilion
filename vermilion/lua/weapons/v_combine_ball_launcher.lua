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

SWEP.PrintName = "Combine Ball Launcher"
SWEP.Author = "Ned - Vermilion"
SWEP.Instructions = "Left click to fire lots of combine balls"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Vermilion"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
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
-- prop_combine_ball

function SWEP:PrimaryAttack()
	self:ShootEffects()
	
	if(SERVER) then
		local grenade = ents.Create("prop_combine_ball")
		if(not IsValid(grenade)) then 
			print("NOT VALID")
			return 
		end
		grenade:SetModel("models/effects/combineball.mdl")
		grenade:SetPos( self.Owner:EyePos() + ( self.Owner:GetAimVector() * 64 ) )
		
		
		
		
		--grenade:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		grenade:Spawn()
		grenade:Activate()
		
		grenade:SetSaveValue('m_flRadius', 12)
		grenade:SetSaveValue('m_nMaxBounces', 700000)
		grenade:SetSaveValue("m_bBounceDie", false)
		grenade:SetSaveValue("m_bWeaponLaunched", true)
		grenade:SetSaveValue("friction", 0)
		
		local phys = grenade:GetPhysicsObject()
		if ( not IsValid( phys ) ) then grenade:Remove() return end
		
		phys:AddGameFlag( FVPHYSICS_DMG_DISSOLVE );
		phys:AddGameFlag( FVPHYSICS_WAS_THROWN );
		local velocity = self.Owner:GetAimVector()
		velocity = velocity * 10000
		phys:SetVelocity( velocity );
		phys:Wake()
		grenade:EmitSound( "NPC_CombineBall.Launch" );
		
		
		local velocity = self.Owner:GetAimVector()
		velocity = velocity * 200000
		--velocity = velocity + ( VectorRand() * 10 ) -- a random element
		phys:ApplyForceCenter( velocity )
		self.Weapon:SetNextPrimaryFire(CurTime() + 0.1)
	end
end

function SWEP:SecondaryAttack()

end
SWEP.PrintName = "Grenade Launcher"
SWEP.Author = "Ned - Vermilion"
SWEP.Instructions = "Left click to fire one grenade, hold right click to fire many"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Vermilion"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
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
-- npc_grenade_frag

function SWEP:PrimaryAttack()
	self:ShootEffects()

	if(SERVER) then
		local grenade = ents.Create("npc_grenade_frag")
		if(not IsValid(grenade)) then 
			print("NOT VALID")
			return 
		end
		grenade:SetModel("models/weapons/w_npcnade.mdl")
		grenade:SetPos( self.Owner:EyePos() + ( self.Owner:GetAimVector() * 16 ) )
		grenade:Spawn()
		
		grenade:Fire("SetTimer", "7", 0)
		
		local phys = grenade:GetPhysicsObject()
		if ( not IsValid( phys ) ) then grenade:Remove() return end
		
		local velocity = self.Owner:GetAimVector()
		velocity = velocity * 1000
		velocity = velocity + ( VectorRand() * 10 ) -- a random element
		phys:ApplyForceCenter( velocity )
	end
end

function SWEP:SecondaryAttack()
	self:ShootEffects()

	self.Weapon:SetNextPrimaryFire( CurTime() + 3 )
	if(SERVER) then
		local grenade = ents.Create("npc_grenade_frag")
		if(not IsValid(grenade)) then 
			print("NOT VALID")
			return 
		end
		grenade:SetModel("models/weapons/w_npcnade.mdl")
		grenade:SetPos( self.Owner:EyePos() + ( self.Owner:GetAimVector() * 16 ) )
		grenade:Spawn()
		
		grenade:Fire("SetTimer", "7", 0)
		
		local phys = grenade:GetPhysicsObject()
		if ( not IsValid( phys ) ) then grenade:Remove() return end
		
		local velocity = self.Owner:GetAimVector()
		velocity = velocity * 1000
		velocity = velocity + ( VectorRand() * 10 ) -- a random element
		phys:ApplyForceCenter( velocity )
	end
end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.Countdown = 0
ENT.Active = false
ENT.Target = nil
ENT.Reverse = false

function ENT:SpawnFunction(ply, tr, ClassName)
	if(!tr.HitWorld) then return end

	local ent = ents.Create(ClassName)
	ent:SetPos(tr.HitPos + Vector(0,0,50))
	ent:Spawn()

	return ent
end

function ENT:Initialize()

	self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNetworkedBool("chasing", false, false)

	local phys = self:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Use(activator, caller)
	if(!activator:IsPlayer()) then return end
	
	self.Active = true
	self.Target = nil
	
	return
end

function ENT:DoesHitWorld(norm)
	local vpos = self:GetPos()
	for var=1,80,1 do
		vpos = vpos - norm
		if(not util.IsInWorld(vpos)) then return true end
	end
	return false
end

function ENT:Think()
	local phys = self:GetPhysicsObject()
	if(self:GetNetworkedBool("chasing") and phys:IsAsleep()) then
		self:SetNetworkedBool("chasing", false, false)
	end
	if(self:DoesHitWorld(Vector(0, 0, 1))) then
		phys:ApplyForceCenter(Vector(0, 0, 8000))
	end
	if(self:DoesHitWorld(Vector(0, 0, -1))) then
		phys:ApplyForceCenter(Vector(0, 0, -8000))
	end
	if(self:DoesHitWorld(Vector(1, 0, 0))) then
		phys:ApplyForceCenter(Vector(8000, 0, 0))
	end
	if(self:DoesHitWorld(Vector(-1, 0, 0))) then
		phys:ApplyForceCenter(Vector(-8000, 0, 0))
	end
	if(self:DoesHitWorld(Vector(0, 1, 0))) then
		phys:ApplyForceCenter(Vector(0, 8000, 0))
	end
	if(self:DoesHitWorld(Vector(0, -1, 0))) then
		phys:ApplyForceCenter(Vector(0, -8000, 0))
	end
	
	if(phys:IsValid() and self.Active) then
		self:NextThink(CurTime())
		if(not phys:IsMotionEnabled()) then
			phys:EnableMotion(true)
		end
		if(self.Countdown <= 0 or self.Target == nil or not self.Target:Alive()) then
			local home = self:GetPos()
			local players = player.GetAll()
			local dist = {}

			for j,k in pairs(players) do
				local distance = home:Distance(k:GetPos())
				table.insert(dist, { Distance = distance, VPlayer = k })
			end
			table.SortByMember(dist, "Distance") 
			for i,k in pairs(dist) do
				if(k.VPlayer:Alive()) then
					self.Target = k.VPlayer
					break
				end
			end
			--self.Target = table.Random(player.GetAll())
			self.Countdown = 50
		end
		self.Countdown = self.Countdown - 1
		self:SetNetworkedString("swag", "Time until next target: " .. tostring(self.Countdown) .. "\nTarget: " .. self.Target:GetName())
		local vector = self.Target:GetPos() - self:GetPos()
		phys:ApplyForceCenter(vector* Vector(25, 25, 50))
		self:SetNetworkedBool("chasing", true, true)
	end
end


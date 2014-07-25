
include("shared.lua")

function ENT:Draw()

	--self:DrawEntityOutline(1.0)
	self:DrawModel()
	if(self:GetNetworkedBool("chasing")) then
		AddWorldTip(self:EntIndex(), self:GetNetworkedString("swag"), 0.5, self:GetPos(), self)
	end
end
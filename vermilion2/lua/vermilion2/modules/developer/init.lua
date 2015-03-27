--[[
 Copyright 2015 Ned Hyett, 

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

MODULE.Name = "Developer Tweaks"
MODULE.ID = "developer"
MODULE.Description = "Enables developer functionality that should usually be disabled on public servers."
MODULE.Author = "Ned"
MODULE.StartDisabled = true
MODULE.Permissions = {
	"bot"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "bot",
		Description = "Adds a bot",
		Syntax = "<number of bots>",
		Permissions = { "bot" },
		Function = function(sender, text, log, glog)
			local num = tonumber(text[1]) or 1
			for i=1,num,1 do
				RunConsoleCommand("bot")
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "bot_zombie",
		Description = "Toggles bot zombie mode.",
		Syntax = "<enabled>",
		Permissions = { "bot" },
		Function = function(sender, text, log, glog)
			local bool = tobool(text[1])
			if(isbool(bool)) then
				if(bool) then
					bool = 1
				else
					bool = 0
				end
				RunConsoleCommand("bot_zombie", bool)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "bucket",
		Description = "Do you really need one?",
		Syntax = "[player]",
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			target.VBucket = not target.VBucket
			target:SetNWBool("VBucket", target.VBucket)
		end,
	})
	
end

function MODULE:InitShared()
	include("vermilion2/modules/developer/interfacebuilder/init.lua")
end

function MODULE:InitServer()

end

function MODULE:InitClient()
	util.PrecacheModel("models/props_junk/MetalBucket01a.mdl")

	self:AddHook("Think", function()
		for i,k in pairs(VToolkit.GetValidPlayers()) do
			if(k:GetNWBool("VBucket")) then
				if(not IsValid(k.VBucketModel)) then
					k.VBucketModel = ents.CreateClientProp()
					k.VBucketModel:SetModel("models/props_junk/MetalBucket01a.mdl")
					
					k.VBucketModel:Spawn()
				else
					local mi,ma = k:GetModelBounds()
					local height = math.abs(mi.z - ma.z)
					local ang = Angle()
					ang:Set(k:GetAngles())
					ang.pitch = 0
					local forw = ang:Forward()
					forw:Mul(15)
					k.VBucketModel:SetPos(k:GetPos() + Vector(0, 0, height - 15) + forw)
					k.VBucketModel:SetAngles(Angle(180, k:GetAngles().yaw, 0))
				end
			else
				if(IsValid(k.VBucketModel)) then
					k.VBucketModel:Remove()
					k.VBucketModel = nil
				end
			end
		end
	end)
end

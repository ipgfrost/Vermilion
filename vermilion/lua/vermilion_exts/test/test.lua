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
local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Testing"
EXTENSION.ID = "test"
EXTENSION.Description = "test"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}

local TEST1 = "testing"

function EXTENSION:InitServer()

	-- this stuff automatically respawns dead zombie bots
	CreateConVar("vermilion_bot_test", "0", FCVAR_NOTIFY, "Automatically respawn dead zombie bots.")
	
	self:AddHook("DoPlayerDeath", function(vplayer, attacker, dmg)
		if(GetConVarNumber("vermilion_bot_test") != 1) then return end 
		if(vplayer:IsBot()) then
			timer.Simple(2, function()
				if(not IsValid(vplayer) or vplayer:Alive()) then return end
				vplayer:Spawn()
			end)
		end
	end)
	
	print(list.Get("Weapon")["weapon_crowbar"]['PrintName'])
	
	concommand.Add("print_wep_table", function(sender, cmd, args, fs)
		print(table.Count(list.Get("Weapon")[args[1]]))
		for i,k in pairs(list.Get("Weapon")[args[1]]) do
			print(tostring(i) .. " ==> " .. tostring(k))
		end
		print(list.Get("Weapon")[args[1]]:IsNPC())
	end)
	
	concommand.Add("print_weps", function()
		for i,k in pairs(list.Get("Weapon")) do
			print(i)
		end
	end)
	
	--[[Vermilion:AddChatCommand("rocket", function(sender, text)
		local rocket = ents.Create("rpg_missile")
		rocket:SetPos(sender:GetPos() + Vector(0, 0, 120))
		rocket:Spawn()
		
		rocket:Fire("SetGracePeriod", "0.1", 0)
		
		local val = math.random(0, 1000000)
		timer.Create("Rocket" .. tostring(val), 0.1, 0, function()
			if(not IsValid(rocket)) then
				timer.Destroy("Rocket" .. tostring(val))
				return
			end
			rocket:SetAngles(sender:EyeAngles())
			
		end)
	end)]]
	
	
end

function EXTENSION:InitClient()
	concommand.Add("vermilion_testbrowser", function(executor)
		if(true) then
			local panel = Crimson.CreateFrame(
				{
					['size'] = { 1000, 600 },
					['pos'] = { (ScrW() / 2) - 500, (ScrH() / 2) - 300 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Test Browser",
					['bgBlur'] = true
				}
			)
			panel:MakePopup()
			panel:DoModal()
			panel:SetAutoDelete(true)
			
			local dhtml = vgui.Create("HTML")
			dhtml:SetPos(0, 55)
			dhtml:SetSize(1000, 500)
			dhtml:SetParent(panel)
			dhtml:OpenURL("http://google.com")
			
			local HTMLControls = vgui.Create( "DHTMLControls" ) --Create the DHTMLControls control
			HTMLControls:SetHTML( dhtml )
			HTMLControls:SetPos(0, 20)
			HTMLControls:SetWide(1000)
			HTMLControls:SetParent(panel)
		end
	end)

end

Vermilion:RegisterExtension(EXTENSION)
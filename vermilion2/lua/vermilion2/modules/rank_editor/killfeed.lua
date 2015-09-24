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

-- Note: this file also contains code from the GMod Lua directory. Such code will be noted and is not
-- subject the the above license.

local MODULE = Vermilion:GetModule("rank_editor")
local Deaths = {}

//This part of the code is copied directly from GMod's Lua directory and is licensed under the same license as GMod itself.
local Color_Icon = Color( 255, 80, 0, 255 )
local NPC_Color = Color( 250, 50, 50, 255 )

MODULE:AddHook("AddDeathNotice", function( Victim, team1, Inflictor, Attacker, team2 )
	local Death = {}
	Death.victim	= Victim
	Death.attacker	= Attacker
	Death.time		= CurTime()

	Death.left		= Victim
	Death.right		= Attacker
	Death.icon		= Inflictor

	if ( team1 == -1 ) then Death.colourv = table.Copy( NPC_Color )
	else Death.colourv = table.Copy( team.GetColor( team1 ) ) end

	if ( team2 == -1 ) then Death.coloura = table.Copy( NPC_Color )
	else Death.coloura = table.Copy( team.GetColor( team2 ) ) end

	if (Death.left == Death.right) then
		Death.left = nil
		Death.icon = "suicide"
	end

	table.insert( Deaths, Death )
end)
//This is no longer GMod code.

MODULE:NetHook("PlayerKilledPlayer", function()
  local v = net.ReadEntity()
  local i = net.ReadString()
  local a = net.ReadEntity()
  if(not IsValid(a) or not IsValid(v)) then return end
  local Death = {}
	Death.victim	= v:Name()
	Death.attacker	= a:Name()
	Death.time		= CurTime()

	Death.left		= a:Name()
	Death.right		= v:Name()
	Death.icon		= i
	if(Vermilion:GetUser(a) != nil and Vermilion:GetUser(a):GetRank() != nil) then
		Death.coloura = Vermilion:GetUser(a):GetRank():GetColour()
	else
		Death.coloura = NPC_Color
		print("Killfeed error: cannot obtain Vermilion rank colour for the attacker in this event!")
  end
	if(Vermilion:GetUser(v) != nil and Vermilion:GetUser(v):GetRank() != nil) then
  	Death.colourv = Vermilion:GetUser(v):GetRank():GetColour()
	else
		Death.colourv = NPC_Color
		print("Killfeed error: cannot obtain Vermilion rank colour for the victim in this event!")
	end
  if(Death.left == Death.right) then
    Death.left = nil
    Death.icon = "suicide"
  end
  table.insert(Deaths, Death)
end)

MODULE:NetHook("PlayerSuicide", function()
  local v = net.ReadEntity()
  if(not IsValid(v)) then
    local Death = {}
  	Death.victim	= v:Name()
  	Death.attacker	= v:Name()
  	Death.time		= CurTime()

  	Death.right		= v:Name()
  	Death.icon		= i
    Death.colourv = Vermilion:GetUser(v):GetRank():GetColour()
    table.insert(Deaths, Death)
  end
end)

MODULE:NetHook("PlayerKilled", function()
  local v = net.ReadEntity()
  if(not IsValid(v)) then return end
  local i = net.ReadString()
  local a = "#" .. net.ReadString()
  local Death = {}
	Death.victim	= v:Name()
	Death.attacker	= a
	Death.time		= CurTime()

	Death.left		= a
	Death.right		= v:Name()
	Death.icon		= i
  Death.coloura = table.Copy(NPC_Color)
  Death.colourv = Vermilion:GetUser(v):GetRank():GetColour()
  table.insert(Deaths, Death)
end)

MODULE:NetHook("PlayerKillNPC", function()
  local vt = net.ReadString()
	local v	= "#" .. vt
	local i	= net.ReadString()
	local a	= net.ReadEntity()

  if(not IsValid(a)) then return end
  local Death = {}
	Death.victim	= v
	Death.attacker	= a:Name()
	Death.time		= CurTime()

	Death.left		= a:Name()
	Death.right		= v
	Death.icon		= i
  Death.coloura = Vermilion:GetUser(a):GetRank():GetColour()
  Death.colourv = table.Copy(NPC_Color)
  table.insert(Deaths, Death)
end)

MODULE:NetHook("NPCKilledNPC", function()
  local v = "#" .. net.ReadString()
  local i = net.ReadString()
  local a = "#" .. net.ReadString()
  local Death = {}
	Death.victim	= v
	Death.attacker	= a
	Death.time		= CurTime()

	Death.left		= a
	Death.right		= v
	Death.icon		= i

  Death.colourv = table.Copy(NPC_Color)
  Death.coloura = table.Copy(NPC_Color)

	if(Death.left == Death.right) then
		Death.left = nil
		Death.icon = "suicide"
	end

	table.insert( Deaths, Death )
end)

//This part of the code is copied directly from GMod's Lua directory and is licensed under the same license as GMod itself.

local function DrawDeath( x, y, death, hud_deathnotice_time )

	local w, h = killicon.GetSize( death.icon )
	if ( !w || !h ) then return end

	local fadeout = ( death.time + hud_deathnotice_time ) - CurTime()

	local alpha = math.Clamp( fadeout * 255, 0, 255 )
	death.colourv.a = alpha
	death.coloura.a = alpha

	-- Draw Icon
	killicon.Draw( x, y, death.icon, alpha )

	-- Draw KILLER
	if ( death.left ) then
		draw.SimpleText( death.left,	"ChatFont", x - ( w / 2 ) - 16, y, death.coloura, TEXT_ALIGN_RIGHT )
	end

	-- Draw VICTIM
	draw.SimpleText( death.right,		"ChatFont", x + ( w / 2 ) + 16, y, death.colourv, TEXT_ALIGN_LEFT )

	return ( y + h * 0.70 )

end

MODULE:AddHook("DrawDeathNotice", function(x, y)
  if ( GetConVarNumber( "cl_drawhud" ) == 0 ) then return end

	local hud_deathnotice_time = GetConVarNumber("hud_deathnotice_time")

	x = x * ScrW()
	y = y * ScrH()

	-- Draw
	for k, Death in pairs( Deaths ) do

		if ( Death.time + hud_deathnotice_time > CurTime() ) then

			if ( Death.lerp ) then
				x = x * 0.3 + Death.lerp.x * 0.7
				y = y * 0.3 + Death.lerp.y * 0.7
			end

			Death.lerp = Death.lerp or {}
			Death.lerp.x = x
			Death.lerp.y = y

			y = DrawDeath( x, y, Death, hud_deathnotice_time )

		end

	end

	for k, Death in pairs( Deaths ) do
		if ( Death.time + hud_deathnotice_time > CurTime() ) then
			return false
		end
	end

	Deaths = {}
  return false
end)
//This is no longer GMod code.

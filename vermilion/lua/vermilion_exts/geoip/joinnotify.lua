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

local EXTENSION = Vermilion:GetExtension("geoip")

EXTENSION:AddHook("VermilionJoinNotify", function(vplayer, first)
	if(EXTENSION:GetData("enabled", true, true)) then
		timer.Simple(2, function()
			if(vplayer:IsBot()) then return end
			local vuser = Vermilion:GetUser(vplayer)
			Vermilion.GetGeoIPForPlayer(vplayer, function(tab)
				if(first) then
					Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerFirstGeoIP, vplayer:GetName(), tab['country_name']))
				else
					Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerGeoIP, vplayer:GetName(), tab['country_name']))
				end
				vplayer.Vermilion_Location = tab['country_code']
				vplayer:SetNWString("Country_Code", tab['country_code'])
				vuser.CountryCode = tab['country_code']
				vuser.CountryName = tab['country_name']
				Vermilion.Log({
					"Obtained GeoIP information for ",
					Vermilion.Colours.Blue,
					vplayer:GetName(),
					Vermilion.Colours.White,
					" successfully."
				})
			end, function()
				Vermilion.Log({
					"Failed to obtain GeoIP information for ",
					Vermilion.Colours.Blue,
					vplayer:GetName(),
					Vermilion.Colours.White,
					"; reverting to previously stored information!"
				})
				vplayer.Vermilion_Location = vuser.CountryCode
				vplayer:SetNWString("Country_Code", vuser.CountryCode)
				if(first) then
					Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServerFirst, vplayer:GetName()))
				else
					Vermilion:BroadcastNotify(string.format(Vermilion.Lang.JoinedServer, vplayer:GetName()))
				end
			end)
		end)
		return false
	end
end)
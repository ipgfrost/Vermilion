--[[
 Copyright 2014 Ned Hyett, 

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
EXTENSION.Name = "Profiles"
EXTENSION.ID = "profiles"
EXTENSION.Description = "Provides server profiles"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}
EXTENSION.NetworkStrings = {
	"VProfileData"
}

--[[
	Todo:
	- Comments
	- Images
	- Most active times
	- Past bans
	- Donator
	- Swear count
	- Quotes (from chat)
	- Last seen
	- Lines in chat
]]--

EXTENSION.DataTypes = {}

function EXTENSION:AddType(typ, sfunc, gfunc, renderfunc, sortingorder)
	if(sfunc == nil) then
		sfunc = function() end
	end
	if(gfunc == nil) then
		gfunc = function() end
	end
	sortingorder = sortingorder or 99999
	self.DataTypes[typ] = { SetupFunction = sfunc, GetFunction = gfunc, RenderFunction = renderfunc, Order = sortingorder }  
end

function EXTENSION:InitShared()
	self:AddType("FirstJoin", function(userTable)
		return os.time()
	end, function(userTable)
		return userTable.FirstJoin
	end)
	
	self:AddType("Cumulative Deaths", function(userTable)
		return 0
	end, function(userTable)
		return userTable.CumulativeDeaths or 0
	end, nil, 4)
	
	self:AddType("Cumulative Kills", function(userTable)
		return 0
	end, function(userTable)
		return userTable.CumulativeKills or 0
	end, nil, 3)
	
	self:AddType("BanData", function(userTable)
		return nil
	end, function(userTable)
		return nil
	end)
	
	self:AddType("Karma", nil, function(userTable)
		return Vermilion:GetKarmaRating(userTable.SteamID)
	end, function(scroll, max, lab, val)
		for i = 1,val,1 do
			local image = vgui.Create("DImage")
			image:SetImage("icon16/star.png")
			image:SizeToContents()
			image:SetPos(lab:GetWide() + 15 + (18 * (i - 1)), max + 8)
			image:SetParent(scroll)
		end
		return max + 22
	end, 1)
	
	local function SecondsToClock(sSeconds)
		local nSeconds = tonumber(sSeconds)
		if (nSeconds == 0) then
			--return nil;
			return "00:00:00";
		else
			local nDays = math.floor(nSeconds/86400)
			nSeconds = nSeconds % 86400
			local nHours = math.floor(nSeconds/3600)
			nSeconds = nSeconds % 3600
			local nMins = math.floor(nSeconds/60)
			local nSecs = math.floor(nSeconds % 60)
			
			
			return tostring(nDays) .. ":" .. tostring(nHours)..":"..tostring(nMins)..":"..tostring(nSecs)
		end
	end
	
	self:AddType("Playtime", nil, function(userTable)
		return userTable.Playtime
	end, function(scroll, max, lab, val)
		lab:SetText("Playtime: " .. SecondsToClock(val))
		lab:SizeToContents()
		return max + 20
	end, 2)
	
	self:AddType("Rank", nil, function(userTable)
		return userTable.Rank
	end, nil, 0)
	
	self:AddType("SteamID", nil, function(userTable)
		return userTable.SteamID
	end, nil, 1.5)
	
	self:AddType("Name", nil, function(userTable)
		return userTable.Name
	end)
	
	self:AddType("Country", nil, function(userTable)
		if(Vermilion:GetModuleData("geoip", "enabled", true)) then
			return userTable.CountryName
		end
	end, nil, 5)
	
	if(SERVER) then
		for i,k in pairs(Vermilion.Settings.Users) do
			for i1,k1 in pairs(self.DataTypes) do
				if(k[string.Replace(i1, " ", "")] == nil) then
					local val = k1.SetupFunction(k)
					if(val != nil) then
						k[string.Replace(i1, " ", "")] = val
					end
				end
			end
		end
	end
end

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("openprofile", function(sender)
		local tplayerTable = Vermilion:GetUserSteamID(sender:SteamID())
		local dat = {}
		for i,k in pairs(EXTENSION.DataTypes) do
			dat[i] = { Value = k.GetFunction(tplayerTable), Order = k.Order }
		end
		net.Start("VProfileData")
		net.WriteTable(dat)
		net.Send(sender)
	end)

	self:NetHook("VProfileData", function(vplayer)
		local tplayer = net.ReadString()
		local tplayerTable = Vermilion:GetUserSteamID(tplayer)
		if(tplayerTable == nil) then return end
		local dat = {}
		for i,k in pairs(EXTENSION.DataTypes) do
			dat[i] = { Value = k.GetFunction(tplayerTable), Order = k.Order }
		end
		net.Start("VProfileData")
		net.WriteTable(dat)
		net.Send(vplayer)
	end)
	


	self:AddHook("Vermilion_RegisteredUser", function(userTable)
		for i,k in pairs(EXTENSION.DataTypes) do
			local val = k.SetupFunction(userTable)
			if(val != nil) then
				userTable[string.Replace(i, " ", "")] = val
			end
		end
	end)
	

end

function EXTENSION:InitClient()

	surface.CreateFont( "ProfileTitle", {
		font = "Roboto",
		size = 28,
		weight = 500,
		antialias = true
	})

	function EXTENSION:OpenProfile(vplayer)
		if(IsValid(vplayer)) then
			self:OpenProfileSteamID(vplayer:SteamID())
		end
	end
	
	function EXTENSION:OpenProfileSteamID(steamid)
		net.Start("VProfileData")
		net.WriteString(steamid)
		net.SendToServer()
	end
	
	self:NetHook("VProfileData", function()
		local data = net.ReadTable()
		local frame = Crimson.CreateFrame(
			{
				['size'] = { 800, 600 },
				['pos'] = { (ScrW() / 2) - 400, (ScrH() / 2) - 300 },
				['closeBtn'] = true,
				['draggable'] = true,
				['title'] = "Profile - " .. data.Name.Value,
				['bgBlur'] = true
			})
		
		local avatar = Crimson.CreateAvatarImage(data.SteamID.Value, 64)
		avatar:SetPos(10, 30)
		avatar:SetParent(frame)
		
		local username = Crimson.CreateLabel(data.Name.Value)
		username:SetPos(10, 110)
		username:SetBright(true)
		username:SetFont("ProfileTitle")
		username:SetTextColor(Vermilion.Colours.White)
		username:SetParent(frame)
		username:SizeToContents()
		username:SetWide(200)
		
		local firstJoined = Crimson.CreateLabel("First joined:\n" .. os.date("%d %B %Y", data.FirstJoin.Value))
		firstJoined:SetPos(10, 150)
		firstJoined:SetBright(true)
		firstJoined:SetTextColor(Vermilion.Colours.White)
		firstJoined:SetParent(frame)
		firstJoined:SizeToContents()
		firstJoined:SetWide(200)
		
		local scroll = vgui.Create("DScrollPanel")
		scroll:SetPos(200, 30)
		scroll:SetParent(frame)
		scroll:SetSize(600, 570)
		
		local max = 0
		for i,k in SortedPairsByMemberValue(data, "Order") do
			if(i == "Name" or i == "FirstJoin") then continue end
			if(EXTENSION.DataTypes[string.Replace(i, " ", "")] != nil and EXTENSION.DataTypes[string.Replace(i, " ", "")].RenderFunction != nil and isfunction(EXTENSION.DataTypes[string.Replace(i, " ", "")].RenderFunction) and true) then
				local lab = Crimson.CreateLabel(i .. ":")
				lab:SetBright(true)
				lab:SetTextColor(Vermilion.Colours.White)
				lab:SetParent(scroll)
				lab:SizeToContents()
				lab:SetPos(10, max + 10)
				max = EXTENSION.DataTypes[string.Replace(i, " ", "")].RenderFunction(scroll, max, lab, k.Value)
				continue
			end
			if(k.Value == nil) then continue end
			local lab = Crimson.CreateLabel(i .. ": " .. tostring(k.Value))
			lab:SetBright(true)
			lab:SetTextColor(Vermilion.Colours.White)
			lab:SetParent(scroll)
			lab:SizeToContents()
			lab:SetPos(10, max + 10)
			max = max + 20
		end
		
		frame:MakePopup()
		frame:DoModal()
		frame:SetAutoDelete(true)
		
	end)
	
	

end

Vermilion:RegisterExtension(EXTENSION)
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

local EXTENSION = Vermilion:GetExtension("sound")

EXTENSION.SoundCloud = {}

EXTENSION.SoundCloud.ClientID = "723bb3b64d04057d0c11ae48cc57ab80"

EXTENSION.SoundCloud.Playlists = {}

function EXTENSION.SoundCloud.url_encode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
		end
	return str
end

function EXTENSION.SoundCloud:SearchUsers(query, callback)
	http.Fetch("https://api.soundcloud.com/users.json?client_id=" .. self.ClientID .. "&q=" .. self.url_encode(query), function(body)
		callback(util.JSONToTable(body))
	end)
end

function EXTENSION.SoundCloud:SearchTracks(query, callback)
	http.Fetch("https://api.soundcloud.com/tracks.json?client_id=" .. self.ClientID .. "&q=" .. self.url_encode(query), function(body)
		callback(util.JSONToTable(body))
	end)
end

function EXTENSION.SoundCloud:LoadSettings()
	self.Playlists = Vermilion:GetSetting("soundcloud_playlists", {})
	if(table.Count(self.Playlists) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
end

function EXTENSION.SoundCloud:SaveSettings()
	Vermilion:SetSetting("soundcloud_playlists", EXTENSION.SoundCloud.Playlists)
end

function EXTENSION.SoundCloud:ResetSettings()
	self.Playlists = {}
end

function EXTENSION:SoundCloudInitServer()
	resource.AddSingleFile("materials/vermilion/sc_logo.png")

	--[["VSCGetPlaylist",
	"VSCSetPlaylist",
	"VSCNewPlaylist",
	"VSCDeletePlaylist",
	"VSCPlayPlaylist"]]
	
	function EXTENSION:UpdateSoundCloudPlaylists(vplayer)
		net.Start("VSCGetAllPlaylists")
		local tab = {}
		for i,k in pairs(EXTENSION.SoundCloud.Playlists) do
			table.insert(tab, { Name = k.Name, Owner = k.Owner, Tracks = table.Count(k.Tracks), ID = i })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end
	
	self:NetHook("VSCNewPlaylist", function(vplayer)
		local name = net.ReadString()
		for i,k in pairs(EXTENSION.SoundCloud.Playlists) do
			if(k.Name == name) then
				Vermilion:SendMessageBox(vplayer, "Playlist already exists!")
				return
			end
		end
		table.insert(EXTENSION.SoundCloud.Playlists, { Name = name, Owner = vplayer:SteamID(), Tracks = {} })
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCGetPlaylist", function(vplayer)
		local playlistId = tonumber(net.ReadString())
		net.Start("VSCGetPlaylist")
		net.WriteTable(EXTENSION.SoundCloud.Playlists[playlistId])
		net.Send(vplayer)
	end)
	
	self:NetHook("VSCGetAllPlaylists", function(vplayer)
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCSetPlaylist", function(vplayer)
		local playlistId = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistId] == nil) then
			return
		end
		if(EXTENSION.SoundCloud.Playlists[playlistId].Owner != vplayer:SteamID()) then
			return
		end
		EXTENSION.SoundCloud.Playlists[playlistId] = net.ReadTable()
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCDeletePlaylist", function(vplayer)
		local playlistid = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistid] == nil) then return end
		if(EXTENSION.SoundCloud.Playlists[playlistid].Owner != vplayer:SteamID()) then return end
		EXTENSION.SoundCloud.Playlists[playlistid] = nil
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCPlayPlaylist", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "playsound")) then
			return
		end
		local playlistId = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistId] == nil) then
			return
		end
		net.Start("VSCPlayPlaylist")
		net.WriteTable(EXTENSION.SoundCloud.Playlists[playlistId].Tracks)
		net.Broadcast()
	end)
	
	self:NetHook("VSCAddToPlaylist", function(vplayer)
		local playlistId = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistId] == nil) then
			return
		end
		if(EXTENSION.SoundCloud.Playlists[playlistId].Owner != vplayer:SteamID()) then
			return
		end
		table.insert(EXTENSION.SoundCloud.Playlists[playlistId].Tracks, { Title = net.ReadString(), Uploader = net.ReadString(), UploadDate = net.ReadString(), StreamURL = net.ReadString() })
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCRemoveFromPlaylist", function(vplayer)
		local playlistid = tonumber(net.ReadString())
		local trackIndex = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistid] == nil) then return end
		if(EXTENSION.SoundCloud.Playlists[playlistid].Owner != vplayer:SteamID()) then return end
		table.remove(EXTENSION.SoundCloud.Playlists[playlistid].Tracks, trackIndex)
		net.Start("VSCGetPlaylistContent")
		net.WriteTable(EXTENSION.SoundCloud.Playlists[playlistid])
		net.Send(vplayer)
		EXTENSION:UpdateSoundCloudPlaylists(vplayer)
	end)
	
	self:NetHook("VSCMoveTrack", function(vplayer)
		local playlistid = tonumber(net.ReadString())
		local trackIndex = tonumber(net.ReadString())
		local dir = net.ReadString()
		if(EXTENSION.SoundCloud.Playlists[playlistid] == nil) then return end
		if(EXTENSION.SoundCloud.Playlists[playlistid].Owner != vplayer:SteamID()) then return end
		local trackinfo = EXTENSION.SoundCloud.Playlists[playlistid].Tracks[trackIndex]
		table.remove(EXTENSION.SoundCloud.Playlists[playlistid].Tracks, trackIndex)
		if(dir == "UP") then
			table.insert(EXTENSION.SoundCloud.Playlists[playlistid].Tracks, trackIndex - 1, trackinfo)
		elseif(dir == "DOWN") then
			table.insert(EXTENSION.SoundCloud.Playlists[playlistid].Tracks, trackIndex + 1, trackinfo)
		end
		net.Start("VSCGetPlaylistContent")
		net.WriteTable(EXTENSION.SoundCloud.Playlists[playlistid])
		net.Send(vplayer)
	end)
	
	self:NetHook("VSCGetPlaylistContent", function(vplayer)
		local playlistid = tonumber(net.ReadString())
		if(EXTENSION.SoundCloud.Playlists[playlistid] == nil) then return end
		net.Start("VSCGetPlaylistContent")
		net.WriteTable(EXTENSION.SoundCloud.Playlists[playlistid])
		net.Send(vplayer)
	end)
	
	self:AddHook("Vermilion-SaveConfigs", "soundcloud_save", function()
		EXTENSION.SoundCloud:SaveSettings()
	end)
	
	EXTENSION.SoundCloud:LoadSettings()
end

function EXTENSION:SoundCloudInitClient()
	--https://developers.soundcloud.com/assets/logo_big_black-75c05c178d54c50c8ff0afbb282d2c21.png
	
	self:NetHook("VSCPlayPlaylist", function()
		EXTENSION.ActivePlaylist = net.ReadTable()
		EXTENSION.PlayListIndex = 1
		sound.PlayURL(EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].StreamURL .. "?client_id=" .. EXTENSION.SoundCloud.ClientID, "noplay", function(station, errorID, errName)
			if(IsValid(station)) then
				EXTENSION.Credits = string.Explode("\n", EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].Title .. "\n" .. EXTENSION.ActivePlaylist[EXTENSION.PlayListIndex].Uploader .. "\nStreamed from SoundCloud")
				timer.Simple(10, function()
					EXTENSION.Credits = nil
				end)
				station:Play()
				EXTENSION.IsPlayingPlaylist = true
				EXTENSION.ActiveSound["BaseSound"] = station
			else
				EXTENSION.ActivePlaylist = nil
				EXTENSION.PlayListIndex = 1
				EXTENSION.IsPlayingPlaylist = false
			end
		end)
	end)
	
	self:NetHook("VSCGetAllPlaylists", function()
		local Playlists = net.ReadTable()
		if(IsValid(EXTENSION.SoundCloud.PlaylistSelector)) then
			EXTENSION.SoundCloud.PlaylistSelector.Translations = {}
			for i,k in pairs(Playlists) do
				if(k.Owner == LocalPlayer():SteamID()) then
					local cid = EXTENSION.SoundCloud.PlaylistSelector:AddChoice(k.Name)
					EXTENSION.SoundCloud.PlaylistSelector.Translations[k.Name] = k.ID
				end
			end
		end
		if(IsValid(EXTENSION.SoundCloud.PlaylistList)) then
			EXTENSION.SoundCloud.PlaylistList:Clear()
			for i,k in pairs(Playlists) do
				EXTENSION.SoundCloud.PlaylistList:AddLine(k.Name, k.Owner, k.Tracks).PlaylistID = k.ID
			end
		end
	end)
	
	self:NetHook("VSCGetPlaylistContent", function()
		if(IsValid(EXTENSION.PlaylistContentList)) then
			local ptab = net.ReadTable()
			EXTENSION.PlaylistContentList:Clear()
			for i,k in pairs(ptab.Tracks) do
				EXTENSION.PlaylistContentList:AddLine(k.Title, k.Uploader, k.UploadDate)
			end
		end
	end)
	
	function EXTENSION:BuildSoundCloudBrowser()
		local soundCloud = Crimson.CreateFrame({
			size = { 750, 650 },
			pos = { (ScrW() - 750) / 2, (ScrH() - 650) / 2 },
			closeBtn = true,
			draggable = true,
			title = "Vermilion SoundCloud® Browser"
		})
		
		local img = vgui.Create("DImage")
		img:SetPos(10, 50)
		img:SetImage("vermilion/sc_logo.png")
		img:SizeToContents()
		img:SetParent(soundCloud)
		
		local slist = Crimson.CreateList({"Title", "Uploader", "Plays", "Upload Date"}, false)
		slist:SetPos(10, 120)
		slist:SetSize(730, 520)
		slist:SetParent(soundCloud)
		
		
		
		local searchBox = vgui.Create("DTextEntry")
		searchBox:SetPos(10, 30)
		searchBox:SetSize(620, 20)
		searchBox:SetParent(soundCloud)
		
		local function updateSearch()
			EXTENSION.SoundCloud:SearchTracks(searchBox:GetValue(), function(tab)
				slist:Clear()
				for i,k in pairs(tab) do
					if(k.streamable) then
						slist:AddLine(k.title, k.user.username, k.playback_count, k.created_at).stream_url = k.stream_url
					end
				end
			end)
		end
		
		searchBox.OnEnter = function()
			updateSearch()
		end
		
		local searchbtn = Crimson.CreateButton("Search", function()
			updateSearch()
		end)
		searchbtn:SetPos(640, 30)
		searchbtn:SetSize(100, 20)
		searchbtn:SetParent(soundCloud)
		
		local playBtn = Crimson.CreateButton("Broadcast", function()
			if(table.Count(slist:GetSelected()) == 0) then
				Crimson:CreateErrorDialog("You must select a track to stream!")
				return
			end
			net.Start("VBroadcastStream")
			net.WriteString(slist:GetSelected()[1].stream_url .. "?client_id=" .. EXTENSION.SoundCloud.ClientID)
			net.WriteString(tostring(100))
			net.WriteString(tostring(false))
			net.WriteString(tostring(true))
			net.WriteString(slist:GetSelected()[1]:GetValue(1) .. "\n" .. slist:GetSelected()[1]:GetValue(2) .. "\nStreamed from SoundCloud®")
			net.SendToServer()
		end)
		playBtn:SetPos(640, 60)
		playBtn:SetSize(100, 20)
		playBtn:SetParent(soundCloud)
		
		local playlistsBtn = Crimson.CreateButton("Playlists", function()
			local soundCloudPlaylists = Crimson.CreateFrame({
				size = { 650, 550 },
				pos = { (ScrW() - 650) / 2, (ScrH() - 550) / 2 },
				closeBtn = true,
				draggable = true,
				title = "Vermilion SoundCloud® Playlist Browser"
			})
			
			local playlistList = Crimson.CreateList({"Name", "Owner", "Tracks"}, false)
			playlistList:SetPos(10, 120)
			playlistList:SetSize(310, 420)
			playlistList:SetParent(soundCloudPlaylists)
			EXTENSION.SoundCloud.PlaylistList = playlistList
			
			local playlistLabel = Crimson:CreateHeaderLabel(playlistList, "Playlists")
			playlistLabel:SetParent(soundCloudPlaylists)
			playlistLabel:SetDark(false)
			
			local playlistContentList = Crimson.CreateList({"Title", "Uploader", "Upload Date"}, false, false)
			playlistContentList:SetPos(330, 120)
			playlistContentList:SetSize(310, 420)
			playlistContentList:SetParent(soundCloudPlaylists)
			EXTENSION.PlaylistContentList = playlistContentList
			
			local contentLabel = Crimson:CreateHeaderLabel(playlistContentList, "Playlist Contents")
			contentLabel:SetParent(soundCloudPlaylists)
			contentLabel:SetDark(false)
			
			local playPlaylistBtn = Crimson.CreateButton("Play Playlist", function()
				if(table.Count(playlistList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a playlist to play!")
					return
				end
				net.Start("VSCPlayPlaylist")
				net.WriteString(tostring(playlistList:GetSelected()[1].PlaylistID))
				net.SendToServer()
			end)
			playPlaylistBtn:SetPos(10, 30)
			playPlaylistBtn:SetSize(150, 20)
			playPlaylistBtn:SetParent(soundCloudPlaylists)
			
			local createPlaylistBtn = Crimson.CreateButton("Create Playlist", function()
				Crimson:CreateTextInput("Enter the name for this playlist:", function(result)
					net.Start("VSCNewPlaylist")
					net.WriteString(result)
					net.SendToServer()
					timer.Simple(3, function()
						net.Start("VSCGetAllPlaylists")
						net.SendToServer()
					end)
				end)
			end)
			createPlaylistBtn:SetPos(170, 30)
			createPlaylistBtn:SetSize(150, 20)
			createPlaylistBtn:SetParent(soundCloudPlaylists)
			
			local deletePlaylistBtn = Crimson.CreateButton("Delete Playlist", function()
				if(table.Count(playlistList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a playlist to delete!")
					return
				end
				net.Start("VSCDeletePlaylist")
				net.WriteString(tostring(playlistList:GetSelected()[1].PlaylistID))
				net.SendToServer()
			end)
			deletePlaylistBtn:SetPos(330, 30)
			deletePlaylistBtn:SetSize(150, 20)
			deletePlaylistBtn:SetParent(soundCloudPlaylists)
			
			local showContents = Crimson.CreateButton("Open Playlist", function()
				if(table.Count(playlistList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a playlist to open!")
					return
				end
				net.Start("VSCGetPlaylistContent")
				net.WriteString(tostring(playlistList:GetSelected()[1].PlaylistID))
				net.SendToServer()
				EXTENSION.SoundCloud.EditingPlaylistID = playlistList:GetSelected()[1].PlaylistID
			end)
			showContents:SetPos(490, 30)
			showContents:SetSize(150, 20)
			showContents:SetParent(soundCloudPlaylists)
			
			local removeFromPlaylist = Crimson.CreateButton("Remove Track", function()
				if(EXTENSION.SoundCloud.EditingPlaylistID == nil) then
					Crimson:CreateErrorDialog("Must be editing a playlist to do this.")
					return
				end
				if(table.Count(playlistContentList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one track to remove from this playlist.")
					return
				end
				net.Start("VSCRemoveFromPlaylist")
				net.WriteString(tostring(EXTENSION.SoundCloud.EditingPlaylistID))
				net.WriteString(tostring(playlistContentList:GetSelected()[1]:GetID()))
				net.SendToServer()
			end)
			removeFromPlaylist:SetPos(10, 60)
			removeFromPlaylist:SetSize(150, 20)
			removeFromPlaylist:SetParent(soundCloudPlaylists)
			
			local moveUp = Crimson.CreateButton("Move Up", function()
				if(EXTENSION.SoundCloud.EditingPlaylistID == nil) then
					Crimson:CreateErrorDialog("Must be editing a playlist to do this.")
					return
				end
				if(table.Count(playlistContentList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a track to move.")
					return
				end
				if(playlistContentList:GetSelected()[1] == 1) then
					Crimson:CreateErrorDialog("Cannot move this up; it's already at the top of the list!")
					return
				end
				net.Start("VSCMoveTrack")
				net.WriteString(tostring(EXTENSION.SoundCloud.EditingPlaylistID))
				net.WriteString(tostring(playlistContentList:GetSelected()[1]:GetID()))
				net.WriteString("UP")
				net.SendToServer()
			end)
			moveUp:SetPos(170, 60)
			moveUp:SetSize(150, 20)
			moveUp:SetParent(soundCloudPlaylists)
			
			local moveDown = Crimson.CreateButton("Move Down", function()
				if(EXTENSION.SoundCloud.EditingPlaylistID == nil) then
					Crimson:CreateErrorDialog("Must be editing a playlist to do this.")
					return
				end
				if(table.Count(playlistContentList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a track to move.")
					return
				end
				if(table.Count(playlistContentList:GetLines()) == playlistContentList:GetSelected()[1]:GetID()) then
					Crimson:CreateErrorDialog("Cannot move this down; it's already at the bottom of the list!")
					return
				end
				net.Start("VSCMoveTrack")
				net.WriteString(tostring(EXTENSION.SoundCloud.EditingPlaylistID))
				net.WriteString(tostring(playlistContentList:GetSelected()[1]:GetID()))
				net.WriteString("DOWN")
				net.SendToServer()
			end)
			moveDown:SetPos(330, 60)
			moveDown:SetSize(150, 20)
			moveDown:SetParent(soundCloudPlaylists)
			
			net.Start("VSCGetAllPlaylists")
			net.SendToServer()
			
			soundCloudPlaylists:MakePopup()
			soundCloudPlaylists:SetAutoDelete(true)
		end)
		playlistsBtn:SetPos(640, 90)
		playlistsBtn:SetSize(100, 20)
		playlistsBtn:SetParent(soundCloud)
		
		local addBtn = Crimson.CreateButton("Add To Playlist", function()
			if(table.Count(slist:GetSelected()) == 0) then
				Crimson:CreateErrorDialog("Must select at least one track to add to a playlist.")
				return
			end
			local panel = Crimson.CreateFrame(
				{
					['size'] = { 500, 100 },
					['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Add To Playlist",
					['bgBlur'] = true
				}
			)
			
			panel:MakePopup()
			panel:SetAutoDelete(true)
			
			Crimson:SetDark(false)
			local textLabel = Crimson.CreateLabel("Select the playlist to add this track to:")
			textLabel:SizeToContents()
			textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
			textLabel:SetParent(panel)
			
			local playlistSelector = vgui.Create("DComboBox")
			playlistSelector:SetPos(10, 50)
			playlistSelector:SetSize(panel:GetWide() - 20, 20)
			playlistSelector:SetParent(panel)
			
			playlistSelector.OnSelect = function(panel, index, val)
				playlistSelector.PLID = playlistSelector.Translations[val]
			end
			
			EXTENSION.SoundCloud.PlaylistSelector = playlistSelector
			
			net.Start("VSCGetAllPlaylists")
			net.SendToServer()
			
			local confirmButton = Crimson.CreateButton("OK", function(self)
				net.Start("VSCAddToPlaylist")
				net.WriteString(playlistSelector.PLID)
				net.WriteString(slist:GetSelected()[1]:GetValue(1))
				net.WriteString(slist:GetSelected()[1]:GetValue(2))
				net.WriteString(slist:GetSelected()[1]:GetValue(4))
				net.WriteString(slist:GetSelected()[1].stream_url)
				net.SendToServer()
				panel:Close()
			end)
			confirmButton:SetPos(255, 75)
			confirmButton:SetSize(100, 20)
			confirmButton:SetParent(panel)
			
			local cancelButton = Crimson.CreateButton("Cancel", function(self)
				panel:Close()
			end)
			cancelButton:SetPos(145, 75)
			cancelButton:SetSize(100, 20)
			cancelButton:SetParent(panel)
			
			Crimson:SetDark(true)
					
		end)
		addBtn:SetPos(530, 90)
		addBtn:SetSize(100, 20)
		addBtn:SetParent(soundCloud)
		
		soundCloud:MakePopup()
		soundCloud:SetAutoDelete(true)
	end
	
	concommand.Add("vermilion_soundcloud_browser", function()
		EXTENSION:BuildSoundCloudBrowser()
	end)
end
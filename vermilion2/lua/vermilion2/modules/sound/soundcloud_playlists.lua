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

local MODULE = Vermilion:GetModule("sound")

--[[

	"VSoundCloudGetPlaylists",
	"VSoundCloudGetPlaylistContent",
	"VSoundCloudNewPlaylist",
	"VSoundCloudAddToPlaylist",
	"VSoundCloudEditPlaylist",
	"VSoundCloudRemoveFromPlaylist",
	"VSoundCloudRemovePlaylist",
	"VSoundCloudPlayPlaylist",
	"VSoundCloudBroadcastPlaylist"

]]--


if(SERVER) then
	local bPlaylist = {}
	function bPlaylist:GetOwner()
		return self.Owner
	end
	function bPlaylist:GetName()
		return self.Name
	end
	function bPlaylist:GetTrack(id)
		for i,k in pairs(self.Content) do
			if(k.ID == id) then return k end
		end
	end
	function bPlaylist:HasTrack(id)
		return self:GetTrack(id) != nil
	end
	function bPlaylist:AddTrack(id, name, uploader)
		if(self:HasTrack(id)) then return end
		table.insert(self.Content, { ID = id, Name = name, Uploader = uploader })
	end
	function bPlaylist:DelTrack(id)
		if(not self:HasTrack(id)) then return end
		table.RemoveByValue(self.Content, self:GetTrack(id))
	end
	function bPlaylist:MoveUp(id)
		for i,k in pairs(self.Content) do
			if(k.ID == id) then
				if(i == 1) then return end
				table.RemoveByValue(self.Content, k)
				table.insert(self.Content, i - 1, k)
				return
			end
		end
	end
	function bPlaylist:MoveDown(id)
		for i,k in pairs(self.Content) do
			if(k.ID == id) then
				if(i == table.Count(self.Content)) then return end
				table.RemoveByValue(self.Content, k)
				table.insert(self.Content, i + 1, k)
				return
			end
		end
	end

	local function attachPlaylistFunctions(playlist)
		setmetatable(playlist, { __index = bPlaylist })
	end

	for i,k in pairs(MODULE:GetData("scplaylists", {}, true)) do
		attachPlaylistFunctions(k)
	end

	local function createNewPlaylist(vplayerOwner, name)
		local pl = {
			Owner = vplayerOwner:SteamID(),
			Name = name,
			Content = {}
		}
		attachPlaylistFunctions(pl)
		return pl
	end

	local function sendPlaylistsToPlayer(vplayer)
		local tab = {}
		for i,k in pairs(MODULE:GetData("scplaylists", {}, true)) do
			if(k:GetOwner() == vplayer:SteamID()) then
				local k1 = table.Copy(k)
				k1.Content = table.Count(k.Content)
				table.insert(tab, k1)
			end
		end
		MODULE:NetStart("VSoundCloudGetPlaylists")
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	function MODULE:LookupPlaylist(plName, vplayerOwner)
		for i,k in pairs(MODULE:GetData("scplaylists", {}, true)) do
			if(k:GetName() == plName and vplayerOwner:SteamID() == k:GetOwner()) then return k end
		end
	end

	MODULE:NetHook("VSoundCloudGetPlaylists", { "use_playlists" }, function(vplayer)
		sendPlaylistsToPlayer(vplayer)
	end)

	MODULE:NetHook("VSoundCloudNewPlaylist", { "use_playlists" }, function(vplayer)
		local pl = createNewPlaylist(vplayer, net.ReadString())
		table.insert(MODULE:GetData("scplaylists", {}, true), pl)
		sendPlaylistsToPlayer(vplayer)
	end)

	MODULE:NetHook("VSoundCloudRemovePlaylist", { "use_playlists" }, function(vplayer)
		local plName = net.ReadString()
		local pl = MODULE:LookupPlaylist(plName, vplayer)
		if(pl == nil) then return end
		table.RemoveByValue(MODULE:GetData("scplaylists", {}, true), pl)
		sendPlaylistsToPlayer(vplayer)
	end)

	MODULE:NetHook("VSoundCloudAddToPlaylist", { "use_playlists" }, function(vplayer)
		local plName = net.ReadString()
		local trackID = net.ReadString()
		local trackName = net.ReadString()
		local trackUploader = net.ReadString()

		local pl = MODULE:LookupPlaylist(plName, vplayer)
		if(pl == nil) then return end
		pl:AddTrack(trackID, trackName, trackUploader)
	end)

	MODULE:NetHook("VSoundCloudRemoveFromPlaylist", { "use_playlists" }, function(vplayer)
		local plName = net.ReadString()
		local trackID = net.ReadString()

		local pl = MODULE:LookupPlaylist(plName, vplayer)
		if(pl == nil) then return end
		pl:DelTrack(trackID)
		MODULE:NetStart("VSoundCloudGetPlaylistContent")
		net.WriteString(plName)
		net.WriteTable(pl.Content)
		net.Send(vplayer)
	end)

	MODULE:NetHook("VSoundCloudGetPlaylistContent", { "use_playlists" }, function(vplayer)
		local plName = net.ReadString()

		local pl = MODULE:LookupPlaylist(plName, vplayer)
		if(pl == nil) then return end
		MODULE:NetStart("VSoundCloudGetPlaylistContent")
		net.WriteString(plName)
		net.WriteTable(pl.Content)
		net.Send(vplayer)
	end)

	MODULE:NetHook("VSoundCloudEditPlaylist", { "use_playlists" }, function(vplayer)
		local plName = net.ReadString()
		local trackID = net.ReadString()
		local dir = net.ReadBoolean()

		local pl = MODULE:LookupPlaylist(plName, vplayer)
		if(pl == nil) then return end

		if(dir) then
			pl:MoveUp(trackID)
		else
			pl:MoveDown(trackID)
		end
		MODULE:NetStart("VSoundCloudGetPlaylistContent")
		net.WriteString(plName)
		net.WriteTable(pl.Content)
		net.Send(vplayer)
	end)

	MODULE:NetHook("VSoundCloudAddToPlaylistQuestion", { "use_playlists" }, function(vplayer)
		MODULE:NetStart("VSoundCloudAddToPlaylistQuestion")
		local tab = {}
		for i,k in pairs(MODULE:GetData("scplaylists", {}, true)) do
			if(k:GetOwner() == vplayer:SteamID()) then
				table.insert(tab, k:GetName())
			end
		end
		for i=0,2,1 do
			net.WriteString(net.ReadString())
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)

else
	local singleton = false

	local PlaylistListGlobal = nil
	local PlaylistContentGlobal = nil

	local playingPlaylist = false
	local playingPlaylistContent = nil
	local playingPlaylistIDX = 1

	MODULE:AddHook("VAudioChannelStopped", function(channel)
		if(channel == "BaseSound") then
			if(playingPlaylist) then
				playingPlaylistIDX = playingPlaylistIDX + 1
				if(playingPlaylistIDX > table.Count(playingPlaylistContent)) then
					playingPlaylist = false
					playingPlaylistIDX = 1
					playingPlaylistContent = nil
					return
				end
				MODULE:QueueSoundStream(SoundCloud.Tracks:GenerateStream(playingPlaylistContent[playingPlaylistIDX]), "BaseSound", {}, function(data)
					MODULE:PlayChannel("BaseSound")
				end)
			end
		end
	end)


	MODULE:NetHook("VSoundCloudGetPlaylists", function()
		if(IsValid(PlaylistListGlobal)) then
			PlaylistListGlobal:Clear()
			local playlists = net.ReadTable()
			for i,k in pairs(playlists) do
				PlaylistListGlobal:AddLine(k.Name, k.Content)
			end
			PlaylistListGlobal:OnRowSelected()
		end
	end)

	MODULE:NetHook("VSoundCloudGetPlaylistContent", function()
		if(IsValid(PlaylistContentGlobal)) then
			if(PlaylistListGlobal:GetSelected()[1] == nil or PlaylistListGlobal:GetSelected()[1]:GetValue(1) != net.ReadString()) then return end
			PlaylistContentGlobal:Clear()
			local content = net.ReadTable()
			for i,k in pairs(content) do
				PlaylistContentGlobal:AddLine(k.Name, k.Uploader).SCID = k.ID
			end
			PlaylistContentGlobal:OnRowSelected()
		end
	end)

	MODULE:NetHook("VSoundCloudAddToPlaylistQuestion", function()
		local id = net.ReadString()
		local name = net.ReadString()
		local uploader = net.ReadString()
		local playlists = net.ReadTable()
		VToolkit:CreateComboboxPanel("Please choose a playlist to add this track to...", playlists, 1, function(val)
			MODULE:NetStart("VSoundCloudAddToPlaylist")
			net.WriteString(val)
			net.WriteString(id)
			net.WriteString(name)
			net.WriteString(uploader)
			net.SendToServer()
		end)
	end)

	local function buildAddPlaylistDrawer(panel)
		local drawer = VToolkit:CreateRightDrawer(panel)

		local textbox = VToolkit:CreateTextbox()
		textbox:SetPos(10, 50)
		textbox:SetSize(drawer:GetWide() - 25, 30)
		textbox:SetParent(drawer)

		local submitButton = VToolkit:CreateButton("Create Playlist", function()
			local name = textbox:GetValue()
			if(name == nil or name == "") then return end
			MODULE:NetStart("VSoundCloudNewPlaylist")
			net.WriteString(name)
			net.SendToServer()
			drawer:Close()
		end)
		submitButton:SetPos(10, 90)
		submitButton:SetSize(drawer:GetWide() - 25, 30)
		submitButton:SetParent(drawer)

		return drawer
	end

	function MODULE:BuildSoundCloudPlaylistsGUI()
		if(singleton) then return end
		singleton = true
		local frame = VToolkit:CreateFrame({
			size = { 800, 600 },
			title = "Vermilion - SoundCloud - Playlists"
		})
		frame:MakePopup()
		frame:SetAutoDelete(true)

		frame.OldCloseF = frame.Close
		function frame:Close()
			singleton = false
			PlaylistListGlobal = nil
			self:OldCloseF()
		end

		local panel = vgui.Create("DPanel")
		panel:SetPos(10, 35)
		panel:SetSize(780, 555)
		panel:SetParent(frame)

		local playlistList = VToolkit:CreateList({
			cols = {
				"Name",
				"Tracks"
			}
		})
		playlistList:SetParent(panel)
		playlistList:SetSize(250, panel:GetTall() - 60)
		playlistList:SetPos(10, 10)
		playlistList.Columns[2]:SetFixedWidth(50)
		PlaylistListGlobal = playlistList

		local addPlaylistDrawer = buildAddPlaylistDrawer(panel)

		local addPlaylistButton = VToolkit:CreateButton("New", function()
			addPlaylistDrawer:Open()
		end)
		addPlaylistButton:SetPos(10, playlistList:GetTall() + playlistList:GetX() + 10)
		addPlaylistButton:SetSize(120, 30)
		addPlaylistButton:SetParent(panel)

		local delPlaylistButton = VToolkit:CreateButton("Delete", function()
			VToolkit:CreateConfirmDialog("Are you sure you want to delete this playlist?", function()
				MODULE:NetStart("VSoundCloudRemovePlaylist")
				net.WriteString(playlistList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end, {
				Confirm = "Yes",
				Deny = "No",
				Default = false
			})
		end)
		delPlaylistButton:SetPos(140, playlistList:GetTall() + playlistList:GetX() + 10)
		delPlaylistButton:SetSize(120, 30)
		delPlaylistButton:SetParent(panel)
		delPlaylistButton:SetDisabled(true)

		local playlistContentList = VToolkit:CreateList({
			cols = {
				"Name",
				"Uploader"
			}
		})
		playlistContentList:SetParent(panel)
		playlistContentList:SetSize(325, panel:GetTall() - 20)
		playlistContentList:SetPos(playlistList:GetX() + playlistList:GetWide() + 10, 10)
		PlaylistContentGlobal = playlistContentList

		local playPlaylistButton = VToolkit:CreateButton("Play", function()
			playingPlaylist = true
			playingPlaylistContent = {}
			for i,k in pairs(playlistContentList:GetLines()) do
				table.insert(playingPlaylistContent, k.SCID)
			end
			playingPlaylistIDX = 1
			MODULE:QueueSoundStream(SoundCloud.Tracks:GenerateStream(playingPlaylistContent[playingPlaylistIDX]), "BaseSound", {}, function(data)
				MODULE:PlayChannel("BaseSound")
			end)
		end)
		playPlaylistButton:SetParent(panel)
		playPlaylistButton:SetPos(playlistContentList:GetX() + playlistContentList:GetWide() + 10, 50)
		playPlaylistButton:SetSize(panel:GetWide() - playPlaylistButton:GetX() - 10, 30)
		playPlaylistButton:SetDisabled(true)

		local removeFromPlaylistButton = VToolkit:CreateButton("Remove Track", function()
			VToolkit:CreateConfirmDialog("Are you sure you want to remove this track?", function()
				MODULE:NetStart("VSoundCloudRemoveFromPlaylist")
				net.WriteString(playlistList:GetSelected()[1]:GetValue(1))
				net.WriteString(playlistContentList:GetSelected()[1].SCID)
				net.SendToServer()
			end, {
				Confirm = "Yes",
				Deny = "No",
				Default = false
			})
		end)
		removeFromPlaylistButton:SetParent(panel)
		removeFromPlaylistButton:SetPos(playlistContentList:GetX() + playlistContentList:GetWide() + 10, 120)
		removeFromPlaylistButton:SetSize(panel:GetWide() - removeFromPlaylistButton:GetX() - 10, 30)
		removeFromPlaylistButton:SetDisabled(true)

		local moveUpInPlaylistButton = VToolkit:CreateButton("Move Up", function()
			MODULE:NetStart("VSoundCloudEditPlaylist")
			net.WriteString(playlistList:GetSelected()[1]:GetValue(1))
			net.WriteString(playlistContentList:GetSelected()[1].SCID)
			net.WriteBoolean(true)
			net.SendToServer()
		end)
		moveUpInPlaylistButton:SetParent(panel)
		moveUpInPlaylistButton:SetPos(playlistContentList:GetX() + playlistContentList:GetWide() + 10, 160)
		moveUpInPlaylistButton:SetSize(panel:GetWide() - moveUpInPlaylistButton:GetX() - 10, 30)
		moveUpInPlaylistButton:SetDisabled(true)

		local moveDownInPlaylistButton = VToolkit:CreateButton("Move Down", function()
			MODULE:NetStart("VSoundCloudEditPlaylist")
			net.WriteString(playlistList:GetSelected()[1]:GetValue(1))
			net.WriteString(playlistContentList:GetSelected()[1].SCID)
			net.WriteBoolean(false)
			net.SendToServer()
		end)
		moveDownInPlaylistButton:SetParent(panel)
		moveDownInPlaylistButton:SetPos(playlistContentList:GetX() + playlistContentList:GetWide() + 10, 200)
		moveDownInPlaylistButton:SetSize(panel:GetWide() - moveDownInPlaylistButton:GetX() - 10, 30)
		moveDownInPlaylistButton:SetDisabled(true)

		local stopPlaylistButton = VToolkit:CreateButton("Stop Active Playlist", function()
			playingPlaylist = false
			playingPlaylistContent = {}
			playingPlaylistIDX = 1
			MODULE:StopChannel("BaseSound")
		end)
		stopPlaylistButton:SetParent(panel)
		stopPlaylistButton:SetPos(playlistContentList:GetX() + playlistContentList:GetWide() + 10, 480)
		stopPlaylistButton:SetSize(panel:GetWide() - stopPlaylistButton:GetX() - 10, 30)


		function playlistList:OnRowSelected()
			playlistContentList:Clear()
			delPlaylistButton:SetDisabled(table.Count(self:GetSelected()) != 1)
			playPlaylistButton:SetDisabled(table.Count(self:GetSelected()) != 1)
			if(table.Count(self:GetSelected()) == 1) then
				MODULE:NetStart("VSoundCloudGetPlaylistContent")
				net.WriteString(self:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end
			playlistContentList:OnRowSelected()
		end

		function playlistContentList:OnRowSelected()
			removeFromPlaylistButton:SetDisabled(table.Count(self:GetSelected()) != 1)
			moveUpInPlaylistButton:SetDisabled(table.Count(self:GetSelected()) != 1)
			moveDownInPlaylistButton:SetDisabled(table.Count(self:GetSelected()) != 1)
		end


		addPlaylistDrawer:MoveToFront()
		MODULE:NetCommand("VSoundCloudGetPlaylists")
	end

end

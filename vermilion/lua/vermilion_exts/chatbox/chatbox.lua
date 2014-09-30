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
EXTENSION.Name = "Chatbox"
EXTENSION.ID = "chatbox"
EXTENSION.Description = "Replaces the default chat box with a more advanced one"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.NetworkStrings = {
	"VAddPlayerSay",
	"VPlayerSay"
}

EXTENSION.MessageHistory = {}
EXTENSION.InputHistory = {}
EXTENSION.ChatOpen = false


function EXTENSION:AddMessage(data)
	data.Timeout = os.time() + 15
	table.insert(EXTENSION.MessageHistory, data)
	if(self.ChatOpen) then
		EXTENSION:RebuildScroller()
	end
end

function EXTENSION:RebuildScroller()
	local ypos = 5
	if(IsValid(EXTENSION.MessageBox)) then
		for i,k in pairs(EXTENSION.MessageHistory) do
			local nameLabel = vgui.Create("DLabel")
			nameLabel:SetPos(5, ypos)
			nameLabel:SetText(k.Name .. ":")
			nameLabel:SizeToContents()
			EXTENSION.MessageBox:AddItem(nameLabel)
			
			local messages = {}
			local curText = ""
			for i1,k1 in pairs(string.Split(k.Message, " ")) do
				if(string.len(curText .. k1) > 80) then
					table.insert(messages, curText)
					curText = ""
				end
				curText = curText .. " " .. k1
			end
			if(curText != "") then table.insert(messages, curText) end
			
			local height = 0
			
			for i1,k1 in pairs(messages) do
				local messageLabel = vgui.Create("DLabel")
				messageLabel:SetPos(nameLabel:GetWide() + 10, ypos + height)
				messageLabel:SetSize(EXTENSION.MessageBox:GetWide() - nameLabel:GetWide() - 20, 13)
				messageLabel:SetText(k1)
				EXTENSION.MessageBox:AddItem(messageLabel)
				height = height + 15
			end
			
			
			
			ypos = ypos + height + 1
		end
		local spacer = vgui.Create("DLabel")
		spacer:SetPos(0, ypos)
		spacer:SetText("")
		EXTENSION.MessageBox:AddItem(spacer)
		
		local x, y = EXTENSION.MessageBox:GetSize()
		local w, h = EXTENSION.MessageBox:GetSize()
		
		y = y + h * 0.5;
		y = y - EXTENSION.MessageBox:GetTall() * 0.5;

		EXTENSION.MessageBox:GetVBar():AnimateTo( y, 0.5, 0, 0.5 );
	end
end

function EXTENSION:CloseChat()
	if(IsValid(EXTENSION.ChatPanel)) then
		EXTENSION.ChatPanel:Close()
		EXTENSION.ChatPanel = nil
		EXTENSION.ChatOpen = false
		return true
	end
end

function EXTENSION:InitServer()
	self:AddHook("PlayerSay", function(vplayer, msg, isTeam, isDead)
		net.Start("VAddPlayerSay")
		if(not IsValid(vplayer)) then
			net.WriteString("[Console]")
		else
			net.WriteString(vplayer:GetName())
		end
		net.WriteString(msg)
		net.Broadcast()
	end)
	
	self:NetHook("VPlayerSay", function(vplayer)
		local message = net.ReadString()
		local isTeam = net.ReadBoolean()
		vplayer:Say(message, isTeam)
	end)
end

function EXTENSION:InitClient()
	
	CreateClientConVar("vermilion_replace_chat", 0, true, false)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, function()
		if(Vermilion:GetExtension("dermainterface") != nil) then
			Vermilion:AddClientOption("Enable replacement chatbox", "vermilion_replace_chat")
		end
	end)
	
	self:AddHook("ChatText", function(idx, name, text, typ)
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		if(name == "Console" and typ == "none") then
			EXTENSION:AddMessage({Name = "[Console]", Message = text})
		end
	end)

	self:AddHook("HUDPaint", function()
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		local cx, cy = chat.GetChatBoxPos()
		for i,k in pairs(EXTENSION.MessageHistory) do
			if(k.Timeout >= os.time()) then
				local w,h = draw.SimpleText(k.Name .. ":", "ChatFont", cx, cy, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				local messages = {}
				local curText = ""
				for i1,k1 in pairs(string.Split(k.Message, " ")) do
					if(string.len(curText .. k1) > 60) then
						table.insert(messages, curText)
						curText = ""
					end
					curText = curText .. " " .. k1
				end
				if(curText != "") then table.insert(messages, curText) end
				local height = 0
				for i1,k1 in pairs(messages) do
					local w1,h1 = draw.SimpleText(k1, "ChatFont", cx + w + 10, cy + height, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					height = height + h1 + 2
				end
				cy = cy + height
			end
		end
	end)

	self:NetHook("VAddPlayerSay", function()
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		EXTENSION:AddMessage({ Name = net.ReadString(), Message = net.ReadString() })
	end)
	
	self:AddHook("HUDShouldDraw", function(name)
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		if(name == "CHudChat") then return false end
	end)
	
	self:AddHook("PlayerButtonDown", function(vplayer, button)
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		if(button == KEY_ESCAPE and EXTENSION.ChatOpen) then return false end
	end)
	
	self:AddHook("PlayerBindPress", function(vplayer, bind, pressed)
		if(GetConVarNumber("vermilion_replace_chat") != 1) then return end
		if(string.find(bind, "cancelselect")) then 
			return EXTENSION:CloseChat()
		end
		if(string.find(bind, "messagemode")) then
			if(pressed) then
				local isTeam = bind == "messagemode2"
				gui.EnableScreenClicker( true )
				hook.Call("StartChat", GAMEMODE, isTeam)
				
				local cx, cy = chat.GetChatBoxPos()
				
				local title = "Chat"
				if(isTeam) then title = "Chat (TEAM)" end
				
				local panel = Crimson.CreateFrame(
					{
						['size'] = { 500, 235 },
						['pos'] = { cx, cy - 10 },
						['closeBtn'] = true,
						['draggable'] = false,
						['title'] = title,
						['bgBlur'] = false
					}
				)
				
				
				
				panel.OldClose = panel.Close
				function panel:Close()
					gui.EnableScreenClicker( false )
					hook.Call("FinishChat", GAMEMODE)
					self:OldClose()
				end
				
				local messages = vgui.Create("DScrollPanel")
				messages:SetPos(5, 25)
				messages:SetSize(490, 180)
				messages:SetParent(panel)
				--messages:SetDrawBackground(false)
				EXTENSION.MessageBox = messages
				
				
				
				local inputBox = vgui.Create("DTextEntry")
				inputBox:SetPos(5, 210)
				inputBox:SetSize(490, 20)
				inputBox:SetParent(panel)
				inputBox:SetUpdateOnType(true)
				
				function inputBox:OnChange()
					local val = inputBox:GetValue()
					hook.Call("ChatTextChanged", GAMEMODE, val)
				end

				function inputBox:OnKeyCode(key)
					if(key == KEY_RIGHT and self:GetCaretPos() == string.len(self:GetText())) then
						local result = hook.Call("OnChatTab", GAMEMODE, inputBox:GetValue())
						if(not string.StartWith(self:GetText(), result)) then
							if(isstring(result)) then
								self:SetText(result)
								self:SetCaretPos(string.len(self:GetText()))
								hook.Call("ChatTextChanged", GAMEMODE, self:GetText())
							end
						end
					end
				end
				
				inputBox.OnEnter = function(self)
					if(self:GetValue() != nil and self:GetValue() != "") then
						net.Start("VPlayerSay")
						net.WriteString(string.Trim(self:GetValue()))
						net.WriteBoolean(false)
						net.SendToServer()
					end
					EXTENSION:CloseChat()
				end
				
				panel:MakePopup()
				panel:DoModal()
				panel:SetAutoDelete(true)
				
				inputBox:RequestFocus()
				
				EXTENSION:RebuildScroller()
				
				EXTENSION.ChatPanel = panel
				EXTENSION.ChatOpen = true
				hook.Call("StartChat", GAMEMODE, isTeam)
			end
			
			return true
			
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)
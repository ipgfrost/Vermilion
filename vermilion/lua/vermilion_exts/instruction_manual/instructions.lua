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
EXTENSION.Name = "Instruction Manual"
EXTENSION.ID = "instructions"
EXTENSION.Description = "Provides help and stuff"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {

}
EXTENSION.Topics = {}

function EXTENSION:InitServer()
	
end

function EXTENSION:InitClient()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddClientTab("instructions", "Instructions", "book.png", "When all else fails, read the Enclosed Instruction Book!", function(panel)
			local title = Crimson.CreateLabel("")
			title:SetPos(270, 30)
			title:SetFont("DermaLarge")
			title:SizeToContents()
			title:SetParent(panel)
			
			local contentWindow = vgui.Create("DScrollPanel")
			contentWindow:SetPos(270, 80)
			contentWindow:SetSize(panel:GetWide() - 270, panel:GetTall() - 110)
			contentWindow:SetParent(panel)
			
			--[[ local infoText = vgui.Create("DLabel")
			infoText:SetPos(0, 0)
			infoText:SetSize(contentWindow:GetWide(), 0)
			infoText:SetAutoStretchVertical(true)
			infoText:SetWrap(true)
			infoText:SetText("")
			contentWindow:AddItem(infoText) ]]
			
			local topicList = Crimson.CreateList({"Topic"}, false, false)
			topicList:SetPos(10, 30)
			topicList:SetSize(250, 500)
			topicList:SetParent(panel)
			topicList.OldClickLine = topicList.OnClickLine
			function topicList:OnClickLine(line, selected)
				title:SetText(line:GetValue(1))
				title:SizeToContents()
				contentWindow:Clear()
				EXTENSION.Topics[line.TopicIndex].Content(contentWindow)
				self:OldClickLine(line, selected)
			end
			
			for i,k in ipairs(EXTENSION.Topics) do
				topicList:AddLine(k.Topic).TopicIndex = i
			end
			
			local topicListLabel = Crimson:CreateHeaderLabel(topicList, "Topics")
			topicListLabel:SetParent(panel)
			
			title:SetText("Welcome")
			title:SizeToContents()
			
			EXTENSION.Topics[1].Content(contentWindow)
		end)
	end)
	
	self:AddHelpTopic("Welcome", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("Welcome to Vermilion.\n\nThis is where you will find a comprehensive guide that should help you make the most out of Vermilion!\n\nVermilion is a new type of Administration Tool. It works out of the box, with smart defaults and powerful tools to help you manage your server, and it's not done yet! You can expect much more functionality as time goes on, the todo list for Vermilion is still growing as more ways to manage a GMod server are discovered.\n\n\n\nChoose a topic on the left to get started!")
	end)
	
	self:AddHelpTopic("The Vermilion Menu", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("The Vermilion Menu is your one-stop-shop for total server control. It is context-sensitive and as such will only display the options that the current user is permitted to see.\n\nAlong the top of the menu, you can see the tabs bar. Each tab manages a different function that Vermilion has to offer.\n\n\nA few things to note:\n\n- The \"Client Options\" tab will always be visible to everybody, but it only changes the way the Vermilion works on the current client, and as such is limited to cosmetic changes.\n- The \"Instructions\" tab will also be visible to everybody.\n- If you ever lose access to the Vermilion controls (i.e. you lose your rank), then one of two different behaviours will occur. If you were an \"owner\" and you lost your rank, you need to re-join the server quickly as the next player to join will be auto-promoted to owner. If you were not an \"owner\" or someone who can control ranks and you lost access, you will need to contact someone who has authority to do so.")
		local lab1 = EXTENSION:GetLabel(contentWindow)
		lab1:SetText("- The Vermilion menu will stay open until you press the close button. You do not have to hold down your keybind.")
		lab1:SetPos(0, 220)
	end)
	
	self:AddHelpTopic("Ranks", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("Ranks are an essential part of the Vermilion engine. Without them, people could do anything they wanted. Defining ranks and using them effectively is the secret to effective server management.\n\nFirstly, to manage ranks you need to click on the \"Ranks\" tab of the Vermilion Menu. The ranks interface can look pretty daunting at first, but this is because it has a lot to offer.\n\n\nThe buttons next to the list titled \"Ranks\" manage the ranks list. All of the buttons here are self explanatory. You need to select a rank in the list to allow the buttons to perform their actions. The only potentially confusing part here is that you need to press \"Save Ranks\" after you have finished editing this list to upload the new ranks configuration to the server.")
		
		local lab1 = EXTENSION:GetLabel(contentWindow)
		lab1:SetText("There are however, two catches to this system. The first being that you cannot delete a rank that is set as the \"default rank\". This is because Vermilion would be unable to assign new players to a rank without user intervention. To re-assign the default rank, simply highlight the rank in the \"Ranks\" list and press \"Set Default Rank\". This will assign the selected rank to be the \"default rank\" that Vermilion will assign to new players. Common sense dictates that you should not set a rank with high access levels as the default rank.\n\nThe second catch here is that you cannot perform any action on a \"protected\" rank. These ranks are used internally by Vermilion for under-the-hood player management. These ranks are \"owner\" and \"banned\".\n\n\nTo set a player's rank, select the target rank in the \"Ranks\" list, and select any number of players in the \"Active Players\" list, and press \"Set Rank\". This will put every player you selected into the selected rank. You do NOT need to save the ranks after doing this.")
		lab1:SetPos(0, 175)
		
		local lab2 = EXTENSION:GetLabel(contentWindow)
		lab2:SetText("To assign permissions to ranks, you need to select a rank in the \"Ranks\" list and press the \"Load Permissions\" button. This will load the permissions for this rank. Note that you cannot edit the permissions for the \"owner\" and \"banned\" ranks. You can then select any number of permissions from the list on the right and press \"Give Permission\" to give those permissions to the rank. This also works in the opposite direction. You can select any number of permissions from the list on the left and press \"Take Permission\" to remove those permissions from the rank. After you have made you changes, press \"Save Permissions\" to upload the new rank permissions list to the server.")
		lab2:SetPos(0, 395)
		
	end)
	
	self:AddHelpTopic("Auto-Promotion", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("Auto-Promotion can be used to promote a user after they have spent some time playing on the server.\n\nThere are two things to note about the system:\n\n1. The system counts in 5 second intervals, meaning that every 5 seconds Vermilion increments it's internal playtime counter and the promotion checker counts in 10 second intervals.\n2. The playtime is cumulative. This means that this is the amount of time that the player has spent on the server since they first joined. For example, if you have 10 hours of playtime and the administrator adds a promotion for 5 hours, you will instantly get that promotion.")
	end)
	
	self:AddHelpTopic("Chat Commands", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("Vermilion has commands that can be run from the chat. You can activate these commands by typing \"!<command name> <args>\" into the chat.\n\nTo get a list of commands, type the command prefix (!) into the chat box. Please note that commands are also subject to access permissions and will check if you are allowed to run them if such a check is required.")
		
		for i,k in pairs(commandList) do
			lst:AddLine(k)
		end
		
	end)
	
	self:AddHelpTopic("Setting the MOTD", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("To set the MOTD, open the Vermilion Menu and select \"Server Settings\". In here, press \"Set MOTD\". The MOTD can be defined in the provided box. To use an \"active value\", you need to surround some text with percentage symbols (%). You can look up what values can be used by pressing the \"Variables\" button at the bottom of the window.\n\nEach new line is printed out as a separate hint, so make sure each line isn't too long. A separate HTML based MOTD system is being worked on.")
	end)
	
	
	self:AddHelpTopic("Zones", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("Zones are very powerful. They can be used for a variety of tasks, or just for messing around in anti-gravity.\n\nTo start off, you need to create a zone. To create a zone, stand where you want one corner of the zone to be and open the chat. In the chat, type \"!addzone\". This will activate the \"drawing mode\". Start moving in any direction to define the second point. Notice that the area that the zone will cover is being highlighted by a black box. When you are ready, open the chat again and type \"!addzone <name>\" where <name> is the unique name of the zone, for example \"spawn\". This is the name you will use to reference this zone in the other commands.")
		
		local lab1 = EXTENSION:GetLabel(contentWindow)
		lab1:SetPos(0, 145)
		lab1:SetText("Now you have created your zone, it's time to start doing stuff with it. You can add a new \"mode\" to the zone by typing \"!setmode <name> <mode>\" where <name> is the name of the zone and <mode> is the name of the mode to add to the zone. Zones can have any combination of modes, but sometimes they just don't work with each other. It would be pointless to have an anti-pvp zone that kills players who enter it! You can list the modes on the zone by typing \"!listmodes <name>\" where <name> is the name of the zone. If you do not add <name> to the command, a list of possible modes will be given instead.\n\nTo remove a mode from a zone, type \"!unsetmode <name> <mode>\" where <name> is the name of the zone and <mode> is the mode to disable. Note that some modes require the zone to be vacant before disabled otherwise the effect will linger. Most notably the anti-gravity field suffers from this bug. It is however being fixed.")
		
		local lab2 = EXTENSION:GetLabel(contentWindow)
		lab2:SetPos(0, 320)
		lab2:SetText("To remove a zone, type \"!clearzone <name>\" into the chat where <name> is the name of the zone to remove.\n\nNote that this feature is experimental and there will be a GUI to interact with the zones in the near future.")
	end)
	
	self:AddHelpTopic("Hints and Tips", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("1. Right click on things such as lists. Vermilion has a large amount of contextual properties in the Vermilion Menu.\n2. Don't repeatedly open the Vermilion Menu in a short space of time. The server has to update it and the client has to re-build it each time it is opened to ensure fresh data is visible.\n3. The Vermilion SoundCloud browser can be bound to a key using 'vermilion_soundcloud_browser'\n4. If you don't see the 'Tool Limits' menu, then the Gamemode that you are playing does not support the toolgun.\n5. If the server starts a level change count-down, a notification will be displayed if you don't have the map to give you time to obtain the map.\n6. You can press tab to autocomplete a Vermilion chat command.\n7. There are two types of sound visualiser available. Change between them by changing the value of 'vermilion_fft_type'.\n8. Vermilion overrides 'sbox_noclip', therefore changing its value is pointless.\n9. If you get a notification that the password was wrong when joining a server, that means you have been banned by Vermilion.")
	end)
	
	self:AddHelpTopic("Help me! I'm locked out!", function(contentWindow)
		local lab = EXTENSION:GetLabel(contentWindow)
		lab:SetText("So, even though measures were put in place to stop this happening, you managed to lock yourself out of your own server? First thing to do, is report how you did it. I need to know these things so I can prevent them happening to you again or other people. Secondly, if you are using a dedicated server you can type the following command into the SERVER console to restore access: \"vermilion_setrank <name> Owner\". If you are not using a dedicated server and are instead using a listen server or are using singleplayer, simply restart the map and Vermilion should recognise the error and repair your configuration files. If this fails and Vermilion is still failing to recognise your rank, you may be dealing with a corrupt configuration file. Exit back to the main menu (or shut down the dedicated server) and delete the Vermilion configuration file (or rename it so Vermilion doesn't load it). You can now open up a new map (or start the dedicated server) and Vermilion should load using default settings.")
		
		local lab1 = EXTENSION:GetLabel(contentWindow)
		lab1:SetPos(0, 155)
		lab1:SetText("If this does not work, please send a copy of the configuration file, a list of addons and important chnages you may have made to the server configuration to me so I can investigate. Of course, you are not obligated to do so, and if you wish, you can remove any sensitive information (i.e. (especially) RCON/server passwords and personal contact details).")
	end)
	
	
end

function EXTENSION:GetLabel(contentWindow)
	local infoText = vgui.Create("DLabel")
	infoText:SetSize(contentWindow:GetWide() - 20, 0)
	infoText:SetAutoStretchVertical(true)
	infoText:SetWrap(true)
	infoText:SetDark(true)
	contentWindow:AddItem(infoText)
	
	return infoText
end

function EXTENSION:AddHelpTopic(topic, help)
	--self.Topics[topic] = help
	table.insert(self.Topics, { Topic = topic, Content = help })
end

Vermilion:RegisterExtension(EXTENSION)
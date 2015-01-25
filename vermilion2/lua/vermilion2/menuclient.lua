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

--[[
	HUD Components:
	1	=	NetGraph
	2	=	CHudDeathNotice
	3	=	CHudChat
	4	=	CHudWeaponSelection
	5	=	CHudHealth
	6	=	CHudSecondaryAmmo
	7	=	CHudAmmo
	8	=	CHudGMod
	9	=	CHudTrain
	10	=	CHudMessage
	11	=	CHudMenu
	12	=	CHudWeapon
	13	=	CHudHintDisplay
	14	=	CHudCrosshair

]]--

Vermilion.Menu = {}
Vermilion.Menu.Categories = {}
Vermilion.Menu.Pages = {}
Vermilion.Menu.Built = false

function Vermilion.Menu:AddCategory(id, order)
	local has = false
	for index,data in pairs(self.Categories) do
		if(data.ID == id) then
			has = true
			break
		end
	end
	if(has) then return end
	table.insert(self.Categories, { ID = id, Name = Vermilion:TranslateStr("category:" .. id), Order = order })
end

function Vermilion.Menu:AddPage(data)
	local mustHave = { "ID", "Name", "Order", "Category", "Size" }
	local shouldHave = { 
		{ "Conditional", function() return true end },
		{ "Builder", function() end },
		{ "Destroyer", function() end },
		{ "OnOpen", function() end },
		{ "OnClose", function() end }
	}
	local probablyShouldntHave = {
		{ "Updater", "Updater is deprecated; use OnOpen instead" },
	}
	for i,k in pairs(mustHave) do
		assert(data[k] != nil, "Page missing required component!")
	end
	for i,k in pairs(shouldHave) do
		if(data[k[1]] == nil) then data[k[1]] = k[2] end
	end
	for i,k in pairs(probablyShouldntHave) do
		if(data[k[1]] != nil) then
			Vermilion.Log("Page '" .. data.Name .. "' is using component '" .. k[1] .. "'! (Complaint reason: " .. k[2] .. ")")
		end
	end
	local has = false
	for index,cat in pairs(self.Categories) do
		if(cat.ID == data.Category) then
			has = true
			break
		end
	end
	if(not has) then
		Vermilion.Log("Warning: no such category " .. data.Category .. " exists (registering page: " .. data.ID .. ")!")
		return
	end
	if(data.Size[1] > ScrW() - 200 or data.Size[2] > ScrH() - 10) then
		Vermilion.Log("Uh oh... It appears that your screen resolution is too small to display a tab on the menu...")
		Vermilion.Log("Recommended minimum resolution: 1366x768")
		Vermilion.Log("You have: " .. tostring(ScrW()) .. "x" .. tostring(ScrH()))
	end
	self.Pages[data.ID] = data
end

function Vermilion.Menu:GetActivePage()
	return self.Pages[self.ActiveTab]
end

function Vermilion.Menu:GetCategory(name)
	for index,cat in pairs(self.Categories) do
		if(cat.Name == name) then return cat end
	end
end

function Vermilion.Menu:GetCategoryID(id)
	for index,cat in pairs(self.Categories) do
		if(cat.ID == id) then return cat end
	end
end

local MENU = Vermilion.Menu
MENU.IsOpen = false
MENU.ActiveTab = "welcome"

MENU:AddCategory("basic", 1)

MENU:AddPage({
	ID = "welcome",
	Name = Vermilion:TranslateStr("menu:welcome"),
	Order = -9000,
	Category = "basic",
	Size = { 580, 560 },
	Builder = function(panel)
		local welcomeLabel = VToolkit:CreateLabel(Vermilion:TranslateStr("welcome:welcome"))
		welcomeLabel:SetFont("DermaLarge")
		welcomeLabel:SizeToContents()
		welcomeLabel:SetPos((580 - welcomeLabel:GetWide()) / 2, 30)
		welcomeLabel:SetParent(panel)
		
		local tabs = VToolkit:CreatePropertySheet()
		tabs:SetPos(0, 90)
		tabs:SetSize(580, 470)
		tabs:SetParent(panel)
		tabs.VHideBG = true
		
		
		local changelogPanel = tabs:AddBlankSheet(Vermilion:TranslateStr("welcome:changelog"), "icon16/report.png", "", false)
		local faqPanel = tabs:AddBlankSheet(Vermilion:TranslateStr("welcome:faq"), "icon16/user_comment.png", "", false)
		--local bugReport = tabs:AddBlankSheet(Vermilion:TranslateStr("welcome:bugreport"), "icon16/bug.png", "", false)
		
		
		local clContainer = VToolkit:CreateCategoryList(true)
		clContainer:SetParent(changelogPanel)
		clContainer:Dock(FILL)
		clContainer:DockMargin(2, 2, 2, 2)
		
		local changelog = {
			{ "2.4 - 25th January 2015", {
					"Huge update for the localisation system and added more localisation options for translators",
					"Updated some global broadcasts to translate into player's chosen language automatically",
					"Added German translation (courtesy of Spennyone and SunRed)",
					"Fixed zone bugs",
					"Added replacement TargetID",
					"Rank icons now appear on TargetID",
					"Blocked sv_cheats in the !convar command (would have errored anyway)",
					"Fixed spawn caps bugs",
					"Attempt to stop GMod from blaming Vermilion for everything",
					"Attempted to make timer failure less frightening"
				}
			},
			{ "2.3.6 - 15th January 2015", {
					"Attempt to fix serious jail bug with the movement hook."
				}
			},
			{ "2.3.5 - 12th January 2015", {
					"Added !addplayer",
					"Added !delplayer",
					"Updated !setrank to work on offline players",
					"Max Health spawnflag now works on values above 100",
					"Player pickup protection now works regardless of the state of the physgun protection",
					"More tweaks to the MOTD"
				}
			},
			{ "2.3.4 - 4th January 2015", {
					"Disabled button colour is now grey",
					"Fixed bug with decimal values in the spawn settings",
					"Fixed bug with reloading values in the spawn settings",
					"Fixed bug with !motd",
					"Fixed bug with MOTD initialisation"
				}
			},
			{ "2.3.3 - 24th December 2014", {
					"Bug fixes for upcoming GMod update",
					"Bug fixes for prop protection"
				}
			},
			{ "2.3.2 - 19th December 2014", {
					"Fix syntax error"
				}
			},
			{ "2.3.1 - 18th December 2014", {
					"Fixes bug in jail code that causes errors when loading saves"
				}
			},
			{ "2.3 - 13th December 2014", {
					"Finished kits",
					"Improved localisation",
					"Fixed bug where the backup system would only delete old configurations after losing the config",
					"Added !jail and !setjailpos",
					"Updated CPPI to version 1.3",
					"Added prop protection settings for breaking, driving, damaging and property editing",
					"Added prop protection buddy list",
					"Fixed bug in CPPI Player UID Caching",
					"Added default permissions for prop protection",
					"Added Russian Translation (courtesy of BatyaMedic)",
					"Fixed the lack of predictions at the start of a command",
					"Fixed VoIP graphs starting at zero",
					"Direct DarkRP integration",
					"Fix for User Rank Editor bug triggered by FPP",
					"Fixed severe bug regarding SteamIDs on Linux",
					"Modules no longer have to declare the MODULE namespace or register themselves",
					"Modules can start disabled",
					"Added developer module (starts disabled)",
					"Fixed another GeoIP bug",
					"Added !version",
					"Added custom spawnpoints",
					"The menu now only updates tabs while they are active, reducing the load when the menu is opened",
					"Added 'self-destruct' hooks (one time hooks)",
					"Vermilion's setup hooks now self-destruct to free memory",
					"Fixed Vermilion 2 accidentally claiming to be Vermilion 1 in the log",
					"VoIP graphs can now be personalised",
					"Created second menu command 'vermillion_menu' in case people misspell 'Vermilion'",
					"Added automatic prop cleanup",
					"Added configuration reset button",
					"The chat predictor will now explain why it cannot complete a request",
					"The chat predictor can now be turned off on a client-by-client basis",
					"Added new questions to the FAQ",
					"Misc refinements on OS X and Linux",
					"Removed the 'Server Information' tab for the time being",
					"Calls to OnOpen for menu pages are now safe and will not lock up the menu if they break",
					"Attempted to fix skin problems",
					"Added Zones GUI",
					"Drastically reduced number of network strings using a layering technique (187 => 46)",
					"Added notification zones"
				}
			},
			{ "2.2.4 - 10th December 2014", {
					"Fixed skin errors"
				}
			},
			{ "2.2.3 - 25th November 2014", {
					"Fixed missing permissions"
				}
			},
			{ "2.2.2 - 21st November 2014", {
					"Fixed the CatList errors (hopefully)"
				}
			},
			{ "2.2.1 - 18th November 2014", {
					"Fix for stupid mistake when regaining control of the hook system"
				}
			},
			{ "2.2 - 16th November 2014", {
					"Chat tags now work",
					"Rank colour is now displayed in chat",
					"Fixes for errors when setting the colour of a rank",
					"Noclip will now never get stuck",
					"Added !slap",
					"Added !adminchat and !asay (!asay is alias of !adminchat)",
					"Added !gimp and the Gimp Editor panel",
					"Added !gag",
					"Added !mute",
					"Vermilion now checks for the presence of Vermilion 1 and will stop loading if it is found",
					"Rebuilt the changelog so it scrolls properly and looks nicer",
					"Fixed !ragdoll",
					"Added the userdata browser (not finished)",
					"Started work on new skin elements",
					"Added kits",
					"The Vermilion Menu now notifies tabs that they have just been opened/closed",
					"Fixed weird menu bugs",
					"Vermilion Menu now shows the title of the active tab in the title",
					"Command parsing now ignores a blank final parameter",
					"Notifications now slide up when those above have dissappeared",
					"Notifications now will not stick if animating",
					"The menu now updates in real-time with changes that other users are making"
				}
			},
			{ "2.1.1 - 11th November 2014", {
					"Loadout can be turned off on non-sandbox gamemodes",
					"Fixes for bad VoIP settings"
				}
			},
			{ "2.1 - 9th November 2014", {
					"Fixed prop-break errors",
					"Added Chat Censor and IPv4 filter",
					"Added \"Workshop Rating\" to credits",
					"Chat command menu registration is now automatic",
					"Swapped parameters for !speed to maintain compatibility with the new menu registration",
					"Chat commands are now registered both on the server and the client",
					"Added punishment commands",
					"Fixed localisation error with Battery Meter causing it to error A LOT",
					"Version information can now be retrieved numerically by calling Vermilion.GetVersion()",
					"Version information can still be retrieved as a string by calling Vermilion.GetVersionString()"
				}
			},
			{ "2.0.2 - 7th November 2014", {
					"Fixed \"Workshop Page\" button",
					"Fixed alignment of buttons on ban interface",
					"Added FAQ",
					"Fixed blocking properties that were not registered on both the server and the client",
					"Fixed bugs with the event logger"
				}
			},
			{ "2.0.1 - 7th November 2014", {
					"Fixed bug where MOTD would crash the server",
					"Fixed bug where entering a chat command in the console when the event log was enabled would not work",
					"Removed useless if case"
				}
			},
			{ "2.0 - 7th November 2014", {
					"Initial Release"
				}
			}
		}
		
		for i,k in pairs(changelog) do
			local version = clContainer:Add(k[1])
			for i1,k1 in pairs(k[2]) do
				version:Add(k1)
			end
		end
		
		local faqContainer = VToolkit:CreateCategoryList(true)
		faqContainer:SetParent(faqPanel)
		faqContainer:Dock(FILL)
		faqContainer:DockMargin(2, 2, 2, 2)
		local faqs = {
			{ "How do I make myself owner on a dedicated server?", "Open the server console (not the one in GMod, but the terminal that the server is running on) and type\n\n \"vermilion setrank <yourname> owner\"", 50 },
			{ "How do I make myself owner on a listen server/singleplayer?", "This happens automatically on listen servers and singleplayer." },
			{ "I can't use chat!", "Do you have the permission to use chat?" },
			{ "How do I disable god mode?", "Server Settings -> Basic Settings -> Disable Damage -> \"Off\" or use !damagemode.\nAlso, disable the PvP management in the same screen and ensure that sbox_godmode is disabled.", 50 },
			{ "How do I change the permissions of the owner rank?", "You can't. It's not designed to be chanaged." },
			{ "Is Vermilion compatible with X?", "If X is not an older version of Vermilion or another administration tool, then the answer is probably yes." },
			{ "Do you plan on making Vermilion compatible with <insert other admin tool here>?", "No. If I make it compatible, then I lose my reason to make Vermilion even better." },
			{ "I installed Vermilion with another admin tool and everything broke. I hate you!", "I did warn you not to do it. Please read the FAQs next time." },
			{ "What is the GeoIP system used for?", "Currently, it only displays the flags on TargetID, but more features are planned." },
			{ "Can I request a feature?", "Certainly, just post a comment on the workshop page and I'll take a look!" },
			{ "Can I add you as a friend on Steam?", "I would rather not, instead, take a look at the Steam Group!" },
			{ "Loadouts aren't working!", "If you are in a gamemode other than sandbox, you need to enable loadouts in the Misc category of the Basic Settings panel.", 30 },
			{ "How do I turn off GeoIP?", "Server Settings -> Basic Settings -> Misc -> Enable GeoIP Services" },
			{ "How do I use the SoundCloud integration?", "Bind a key to \"vermilion_soundcloud_browser\"" },
			{ "How do I stop a sound?", "Type !stopsound in chat, or run \"vermilion stopsound\" in the console." },
			{ "Vermilion causes another addon to break!", "Report the issue to me ASAP. I can probably integrate a fix into the next release." },
			{ "You keep talking about localisation, where is it?", "It isn't ready yet, but if you want to help translate Vermilion in the future, don't hesitate to contribute to the GitHub repository (I will post an announcement when it is safe to start translating!", 40 },
			{ "I see you can select a visualiser, how do I make my own?", "I plan on adding a visualiser development kit later on, but for now, you can look at the GitHub code.", 30 },
			{ "I'm getting a lot of errors, what the heck?", "Firstly, make sure that there are no other administration tools on the server (this includes Vermilion 1) and then restart the server. If this doesn't fix anything, try deleting the Vermilion configuration. As a last resort, check for similar reports and if one doesn't exist, file a new one!", 50 },
			{ "I don't like the way you have spelled something (i.e. colour)! Change it!", "No. If you can't stand it, make your own localisation file." },
			{ "How do I enable anti-spam?", "Look in the Basic Settings panel." },
			{ "How do I select all players in a chat command?", "Replace the player argument with \"@\"" },
			{ "How often do you update?", "I don't have a schedule, but I will usually release a minor update after a bug report and large releases will take place every now and then.", 30 },
			{ "Can you sort out the text on OS X?", "The text will be fixed an a future GMod update where the default text on OS X will be easier to read." },
			{ "The question I have isn't answered here!", "Please tell me about it! Ask the question on the comments and I'll probably add it to the FAQ in the future." }
		}
		
		for i,k in pairs(faqs) do
			local question = faqContainer:Add(k[1])
			local lab = vgui.Create("DLabel")
			lab:SetText(k[2])
			lab:SetParent(question)
			lab:SetWrap(true)
			lab:SetTall(k[3] or 20)
			lab:DockMargin(2, 2, 2, 2)
			lab:Dock(TOP)
			lab:SetDark(true)
		end
		
	end
})

MENU:AddPage({
	ID = "modules",
	Name = Vermilion:TranslateStr("menu:modules"),
	Order = 1,
	Category = "basic",
	Size = { 700, 560 },
	Builder = function(panel, paneldata)
		local mlist = VToolkit:CreateList({
			cols = {
				Vermilion:TranslateStr("name")
			}
		})
		mlist:Dock(LEFT)
		mlist:DockMargin(10, 10, 0, 10)
		mlist:SetParent(panel)
		mlist:SetWide(200)
		paneldata.ModuleList = mlist
		
		local infopanel = vgui.Create("DPanel")
		infopanel:SetDrawBackground(false)
		infopanel:Dock(FILL)
		infopanel:DockMargin(10, 10, 10, 10)
		infopanel:SetParent(panel)
		
		local title = VToolkit:CreateLabel(Vermilion:TranslateStr("modules:clickon"))
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:Dock(TOP)
		title:SetParent(infopanel)
		paneldata.TitleLabel = title
		
		local author = VToolkit:CreateLabel("")
		author:Dock(TOP)
		author:SetParent(infopanel)
		paneldata.AuthorLabel = author
		
		local enablerPanel = vgui.Create("DPanel")
		enablerPanel:SetParent(infopanel)
		enablerPanel:Dock(TOP)
		enablerPanel:SetTall(20)
		enablerPanel:DockMargin(0, 10, 0, 10)
		enablerPanel:SetDrawBackground(false)
		enablerPanel:SetVisible(false)

		paneldata.EnablerPanel = enablerPanel
		
		local enableCB = VToolkit:CreateCheckBox(Vermilion:TranslateStr("modules:enabled"))
		enableCB:Dock(FILL)
		enableCB:SetParent(enablerPanel)
		enableCB.CanUpdate = true
		function enableCB:OnChange(val)
			if(not self.CanUpdate) then return end
			net.Start("VModuleDataEnableChange")
			net.WriteString(self.ModuleID)
			net.WriteBoolean(val)
			net.SendToServer()
		end
		paneldata.EnableCB = enableCB
		
		
		local description = vgui.Create("DTextEntry")
		description:SetDrawBackground(false)
		description:SetMultiline(true)
		description:Dock(TOP)
		description:SetTall(50)
		description:DockMargin(0, 10, 0, 10)
		description:SetParent(infopanel)
		description:SetValue("")
		description:SetEditable(false)
		paneldata.Description = description
		
		
		
		
		local scrollp = vgui.Create("DScrollPanel")
		scrollp:SetParent(infopanel)
		scrollp:Dock(FILL)
		scrollp:DockMargin(0, 10, 0, 0)
		scrollp:SetVisible(false)
		
		net.Receive("VModuleDataUpdate", function()
			enableCB.CanUpdate = false
			enableCB:SetValue(net.ReadBoolean())
			enableCB.CanUpdate = true
		end)
		
	end,
	OnOpen = function(panel, paneldata)
		if(table.Count(paneldata.ModuleList:GetLines()) == 0) then
			for i,k in pairs(Vermilion.Modules) do
				local ln = paneldata.ModuleList:AddLine(k.Name)
				ln.OldClick = ln.OnMousePressed
				function ln:OnMousePressed(mc)
					paneldata.TitleLabel:SetText(k.Name)
					paneldata.TitleLabel:SizeToContents()
					
					paneldata.AuthorLabel:SetText("Author: " .. k.Author)
					paneldata.AuthorLabel:SizeToContents()
					
					paneldata.Description:SetValue(k.Description)
					paneldata.Description:SetEditable(false)
					
					paneldata.EnableCB.ModuleID = k.ID
					
					
					paneldata.EnablerPanel:SetVisible(Vermilion:HasPermission("*") and not k.PreventDisable)
					
					net.Start("VModuleDataUpdate")
					net.WriteString(k.ID)
					net.SendToServer()
					
					self:OldClick(mc)
				end
			end
			paneldata.ModuleList:SortByColumn(paneldata.ModuleList.Columns[1]:GetColumnID())
		end
	end
})

MENU:AddPage({
	ID = "api",
	Name = Vermilion:TranslateStr("menu:api"),
	Order = 10,
	Category = "basic",
	Size = { 600, 560 },
	Builder = function(panel)
		local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
		label:SetFont("DermaLarge")
		label:SizeToContents()
		label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
		label:SetParent(panel)
	end
})

MENU:AddPage({
	ID = "credits",
	Name = Vermilion:TranslateStr("menu:credits"),
	Order = 50,
	Category = "basic",
	Size = { 600, 560 },
	Builder = function(panel, paneldata)
		local title = VToolkit:CreateLabel(Vermilion:TranslateStr("credits:title"))
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:SetParent(panel)
		title:Dock(TOP)
		title:DockMargin((600 - title:GetWide()) / 2, 10, 0, 10)
		
		local scrollPanel = vgui.Create("DScrollPanel")
		scrollPanel:SetParent(panel)
		scrollPanel:Dock(FILL)
		
		local contributors = {
			{
				Name = "Ned",
				SteamID = "STEAM_0:0:44370296",
				Role = "Project Lead - Coding",
			},
			{
				Name = "Wheatley",
				SteamID = "STEAM_0:0:44277237",
				Role = "GUI Skin Designer"
			},
			{
				Name = "TehAngel",
				SteamID = "STEAM_0:1:79012222",
				Role = "Ideas, Persuasion, Bug Reports and Workshop Icon"
			}
		}
		
		local size = 64
		
		for i,k in pairs(contributors) do
			local contributorPanel = vgui.Create("DPanel")
			contributorPanel:SetDrawBackground(false)
			contributorPanel:Dock(TOP)
			contributorPanel:DockPadding(10, 2, 10, 2)
			contributorPanel:SetParent(scrollPanel)
			contributorPanel:SetTall(68)
			
			local avb = vgui.Create("DButton")
			avb:SetSize(size, size)
			avb:SetParent(contributorPanel)
			avb:Dock(LEFT)
			avb:DockMargin(0, 0, 10, 0)
			
			local av = VToolkit:CreateAvatarImage(k.SteamID, size)
			av:SetParent(avb)
			av:SetMouseInputEnabled(false)
			
			function avb:DoClick(mc)
				gui.OpenURL("http://steamcommunity.com/profiles/" .. util.SteamIDTo64(k.SteamID))
			end
			
			av:SetCursor("hand")
			
			local dataPanel = vgui.Create("DPanel")
			dataPanel:SetTall(64)
			dataPanel:Dock(LEFT)
			dataPanel:DockPadding(0, 10, 0, 0)
			dataPanel:SetWide(300)
			dataPanel:SetParent(contributorPanel)
			dataPanel:SetDrawBackground(false)
			
			local name = vgui.Create("DLabel")
			steamworks.RequestPlayerInfo(util.SteamIDTo64(k.SteamID))
			timer.Simple(3, function()
				if(not IsValid(name)) then return end
				name:SetText(steamworks.GetPlayerName(util.SteamIDTo64(k.SteamID)))
				name:SizeToContents()
			end)
			name:SetText(k.Name)
			name:SetFont("DermaDefaultBold")
			name:SizeToContents()
			name:Dock(TOP)
			name:SetDark(true)
			name:SetParent(dataPanel)
			
			local role = vgui.Create("DLabel")
			role:SetText(k.Role)
			role:SizeToContents()
			role:Dock(TOP)
			role:SetDark(true)
			role:SetParent(dataPanel)
		end
		
		local thanks = VToolkit:CreateLabel(Vermilion:TranslateStr("credits:thanks"))
		thanks:Dock(TOP)
		thanks:DockMargin(10, 10, 10, 10)
		thanks:SetParent(scrollPanel)
		thanks:SetDark(true)
		thanks:SetWrap(true)
		thanks:SetTall(thanks:GetTall() * 2)
		
		local poweredBySoundCloud = VToolkit:CreateLabel(Vermilion:TranslateStr("credits:scapi"))
		poweredBySoundCloud:Dock(TOP)
		poweredBySoundCloud:SetWrap(true)
		poweredBySoundCloud:SetTall(poweredBySoundCloud:GetTall() * 2)
		poweredBySoundCloud:DockMargin(10, 10, 10, 10)
		poweredBySoundCloud:SetParent(scrollPanel)
		poweredBySoundCloud:SetDark(true)
		
		local poweredByFGIP = VToolkit:CreateLabel(Vermilion:TranslateStr("credits:fgip"))
		poweredByFGIP:Dock(TOP)
		poweredByFGIP:SetWrap(true)
		poweredByFGIP:SetTall(poweredByFGIP:GetTall() * 2)
		poweredByFGIP:DockMargin(10, 10, 10, 10)
		poweredByFGIP:SetParent(scrollPanel)
		poweredByFGIP:SetDark(true)
		
		
		local buttonBar = vgui.Create("DPanel")
		buttonBar:Dock(TOP)
		buttonBar:DockMargin(10, 10, 10, 10)
		buttonBar:SetParent(scrollPanel)
		buttonBar:SetTall(25)
		buttonBar:SetDrawBackground(false)
		
		local gotoWorkshop = VToolkit:CreateButton(Vermilion:TranslateStr("credits:workshop"), function()
			steamworks.ViewFile("338063408")
		end)
		gotoWorkshop:Dock(LEFT)
		gotoWorkshop:SetSize(200, 25)
		gotoWorkshop:SetParent(buttonBar)
		
		local openGithub = VToolkit:CreateButton(Vermilion:TranslateStr("credits:github"), function()
			gui.OpenURL("http://github.com/nedhyett/Vermilion")
		end)
		openGithub:Dock(RIGHT)
		openGithub:SetSize(200, 25)
		openGithub:SetParent(buttonBar)
		
		local openSteamGroup = VToolkit:CreateButton(Vermilion:TranslateStr("credits:group"), function()
			gui.OpenURL("http://steamcommunity.com/groups/VSM-GMOD")
		end)
		openSteamGroup:Dock(TOP)
		openSteamGroup:SetSize(scrollPanel:GetWide(), 25)
		openSteamGroup:DockMargin(5, 0, 5, 0)
		openSteamGroup:SetParent(buttonBar)
		
		local workshopRating = vgui.Create("DProgress")
		workshopRating:SetParent(scrollPanel)
		workshopRating:Dock(TOP)
		workshopRating:DockMargin(5, 5, 5, 5)
		paneldata.WorkshopRating = workshopRating
		
		local workshopRatingLabel = vgui.Create("DLabel")
		workshopRatingLabel:SetText(Vermilion:TranslateStr("credits:workshoprating"))
		workshopRatingLabel:SizeToContents()
		workshopRatingLabel:SetParent(workshopRating)
		workshopRatingLabel:SetDark(true)
		paneldata.WorkshopRatingLabel = workshopRatingLabel
	end,
	OnOpen = function(panel, paneldata)
		steamworks.VoteInfo(338063408, function(result)
			paneldata.WorkshopRating:SetFraction(result.up / result.total)
			paneldata.WorkshopRatingLabel:SetText(Vermilion:TranslateStr("credits:workshoprating:detail", { tostring(math.Round((result.up/result.total) * 100, 2)) }))
			paneldata.WorkshopRatingLabel:SizeToContents()
			paneldata.WorkshopRatingLabel:Center()
		end)
	end
})


-- stop drawing netgraph or the ammo count if the menu is open
Vermilion:AddHook("HUDShouldDraw", "MenuClientHudDraw", false, function(name)
	if(name == "NetGraph" or name == "CHudAmmo") then
		if(MENU.IsOpen) then return false end
	end
end)

-- switch the menu tab
function MENU:ChangeTab(to, quiet)
	if(to == self.ActiveTab) then return end
	quiet = quiet or false
	if(not quiet) then
		if(hook.Run(Vermilion.Event.MENU_TAB, self.ActiveTab, to) == false) then return false end
	end
	if(self.Animating) then return false end
	local oldName = self.ActiveTab
	assert(self.Pages[to] != nil)
	if(quiet) then
		self:GetActivePage().Panel:SetVisible(false)
		self:GetActivePage().OnClose(self:GetActivePage().Panel, self:GetActivePage())
		self.Pages[to].Panel:SetVisible(true)
		self.ActiveTab = to
		self.CatList:UnselectAll()
		self:GetActivePage().TabButton:SetSelected(true)
		self.ContentPanel:SetSize(self:GetActivePage().Size[1] + 20, self:GetActivePage().Size[2] + 40)
		self:GetActivePage().OnOpen(self:GetActivePage().Panel, self:GetActivePage())	
		self.ContentPanel:SetTitle("Vermilion Menu - " .. self:GetActivePage().Name)
	else
		self.Animating = true
		local oldPage = self:GetActivePage()
		local newPage = self.Pages[to]
		oldPage.Panel:AlphaTo(0, 0.25, 0, function()
			oldPage.Panel:SetVisible(false)
			MENU:GetActivePage().OnClose(MENU:GetActivePage().Panel, MENU:GetActivePage())
			oldPage.Panel:SetAlpha(255)
			MENU.ActiveTab = to
			MENU.ContentPanel:SizeTo(newPage.Size[1] + 20, newPage.Size[2] + 40, 0.5, 0, -3, function()
				if(MENU.ActiveTab != to) then return end
				newPage.Panel:SetAlpha(0)
				newPage.Panel:SetVisible(true)
				pcall(MENU:GetActivePage().OnOpen, MENU:GetActivePage().Panel, MENU:GetActivePage())
				newPage.Panel:AlphaTo(255, 0.25, 0, function()
					MENU.ContentPanel:SetTitle("Vermilion Menu - " .. self:GetActivePage().Name)
					MENU.Animating = false
					if(MENU.ActiveTab != to) then
						newPage.Panel:SetAlpha(255)
						newPage.Panel:SetVisible(false)
					end
				end)
			end)
		end)
	end
	return true
end

Vermilion:AddHook(Vermilion.Event.MOD_POST, "MenuClientBuild", true, function()
	-- assume that all modules have run their code to register their pages
	
	MENU.TabPanel = VToolkit:CreateFrame({
		size = { 170, 600 },
		pos = { -170, 10 },
		closeBtn = false,
		draggable = false,
		title = "",
		bgBlur = false
	})
	
	MENU.ContentPanel = VToolkit:CreateFrame({
		size = { 600, 600 },
		pos = { 200, ScrH() },
		closeBtn = true,
		draggable = false,
		title = "Vermilion Menu",
		bgBlur = false
	})
	
	MENU.ContentPanel.lblTitle.UpdateColours = function() end
	
	
	-- add a list thingy
	local catList = VToolkit:CreateCategoryList()
	catList:SetPos(5, 5)
	catList:SetSize(160, 590)
	catList:SetParent(MENU.TabPanel)
	
	MENU.CatList = catList
	
	MENU.TabPanel:SetVisible(false)
	MENU.ContentPanel:SetVisible(false)
	MENU.TabPanel:MakePopup()
	MENU.ContentPanel:MakePopup()

	function MENU.ContentPanel:Close()
		MENU:Close()
	end

	function MENU:Open()
		if(hook.Run(Vermilion.Event.MENU_OPENING) == false or MENU.IsOpen or not MENU.Built) then return end
		
		for i,k in pairs(MENU.Pages) do
			if(k.Conditional(LocalPlayer()) and k.Updater != nil) then
				xpcall(k.Updater, function(err)
					Vermilion.Log("Failed to update panel (" .. k.ID .. "): " .. err)
					debug.Trace()
				end, k.Panel, k)
			end
		end
		
		self:GetActivePage().OnOpen(self:GetActivePage().Panel, self:GetActivePage())
		
		MENU.IsOpen = true
		MENU.TabPanel:SetVisible(true)
		MENU.ContentPanel:SetVisible(true)
		MENU.TabPanel:MoveTo(10, 10, 0.5, 0, -3)
		MENU.ContentPanel:MoveTo(200, 10, 0.5, 0, -3, function()
			MENU.TabPanel:SetKeyboardInputEnabled(true)
			MENU.ContentPanel:SetKeyboardInputEnabled(true)
			hook.Run(Vermilion.Event.MENU_OPEN)
		end)
	end

	function MENU:Close(force)
		if(not force and (hook.Run(Vermilion.Event.MENU_CLOSING) == false or not MENU.IsOpen)) then return end
		
		MENU.TabPanel:MoveTo(-170, 10, 0.5, 0, -3)
		MENU.ContentPanel:MoveTo(200, ScrH(), 0.5, 0, -3, function()
			MENU.TabPanel:SetVisible(false)
			MENU.ContentPanel:SetVisible(false)
			MENU.TabPanel:SetKeyboardInputEnabled(false)
			MENU.ContentPanel:SetKeyboardInputEnabled(false)
			MENU.IsOpen = false
			for i,k in pairs(MENU.Pages) do
				local suc, err = pcall(k.Destroyer, k.Panel, k)
				if(not suc) then print(err) end
			end
			hook.Run(Vermilion.Event.MENU_CLOSED)
		end)
	end
	
	local categories = {}
	for index,catData in SortedPairsByMemberValue(MENU.Categories, "Order", false) do
		categories[catData.ID] = MENU.CatList:Add(catData.Name)
		catData.Impl = categories[catData.ID]
	end
	
	for index,pageData in SortedPairsByMemberValue(MENU.Pages, "Order", false) do
		local cat = categories[pageData.Category]
		local btn = cat:Add(pageData.Name)
		btn.OldDCI = btn.DoClickInternal
		btn.DoClickInternal = function()
			if(not MENU:ChangeTab(pageData.ID)) then return end
			btn.OldDCI()
		end
		btn.TabID = pageData.ID
		MENU.Pages[pageData.ID].TabButton = btn
		
		local panel = vgui.Create("DPanel")
		panel:SetParent(MENU.ContentPanel)
		panel:SetSize(pageData.Size[1], pageData.Size[2])
		panel:SetPos(10, 30)
		if(pageData.ID != "welcome") then 
			panel:SetVisible(false)
		end
		
		MENU.Pages[pageData.ID].Panel = panel
		
		xpcall(pageData.Builder, function(err)
			Vermilion.Log("Error building page: " .. err)
			debug.Trace()
		end, panel, pageData)
		
		btn:SetVisible(pageData.Conditional(LocalPlayer()))
		
	end
	
	for i,k in pairs(categories) do		
		local visibleChildren = 0
		for i1,k1 in pairs(k:GetChildren()) do
			if(k1:IsVisible()) then visibleChildren = visibleChildren + 1 end
		end
		k:SetVisible(visibleChildren > 1)
	end
	
	MENU.Pages["welcome"].TabButton:SetSelected(true)
	MENU.Built = true
end)

concommand.Add("vermilion_menu", function()
	MENU:Open()
end)

concommand.Add("vermillion_menu", function()
	Vermilion.Log("Warning: you have made a spelling error in the 'vermilion_menu' command. Please re-bind the command!")
	MENU:Open()
end)

Vermilion:AddHook(Vermilion.Event.CLIENT_GOT_RANKS, "UpdateMenuAccess", true, function()
	if(not MENU.Built or table.Count(MENU.Pages) == 0) then return end
	if(MENU.Pages["welcome"].TabButton == nil) then return end
	for i,k in pairs(MENU.Pages) do
		k.TabButton:SetVisible(k.Conditional(LocalPlayer()))
	end
	
	for i,k in pairs(MENU.Categories) do
		local visibleChildren = 0
		for i1,k1 in pairs(k.Impl:GetChildren()) do
			if(k1:IsVisible()) then visibleChildren = visibleChildren + 1 end
		end
		k.Impl:SetVisible(visibleChildren > 1)
	end
	if(not MENU:GetActivePage().TabButton:IsVisible()) then MENU:ChangeTab("welcome") end
	MENU.CatList:InvalidateLayout()
end)
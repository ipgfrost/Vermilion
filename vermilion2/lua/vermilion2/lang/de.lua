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
	Translated by Spennyone
	https://github.com/Spennyone
]]--

--[[
	Note: Always save this file in "UTF-8 w/o BOM" instead of ASCII when using NP++ or the characters will be lost!
]]

local lang = Vermilion:CreateLangBody("German")

lang:Add("yes", "Ja")
lang:Add("no", "Nein")
lang:Add("close", "Schließen")

lang:Add("dayslabel", "Tage:")
lang:Add("hourslabel", "Stunden:")
lang:Add("minuteslabel", "Minuten:")
lang:Add("secondslabel", "Sekunden:")


lang:Add("no_users", "Dieser Spieler existiert nicht auf diesem Server.")
lang:Add("ambiguous_users", "Mehrere Treffer für \"%s\". (Treffer: %s).")
lang:Add("access_denied", "Zugriff verweigert!")
lang:Add("under_construction", "Unter Arbeit!")
lang:Add("bad_syntax", "Ungültiger Syntax!")
lang:Add("not_number", "Das ist keine Nummer!")
lang:Add("not_bool", "Das ist kein boolean!")
lang:Add("player_immune", "%s ist immun gegen dich.")
lang:Add("ban_self", "Du kannst dich nicht selber bannen!")
lang:Add("kick_self", "Du kannst dich nicht selber kicken!")
lang:Add("no_rank", "Rang existiert nicht!")


--[[

	//		Prints:Settings		\\

]]--


--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Basics")
lang:Add("category:server", "Server Optionen")
lang:Add("category:ranks", "Ränge")
lang:Add("category:player", "Spieler Verwaltung")
lang:Add("category:limits", "Limits")



--[[

	//		Addon Validator		\\

]]--
lang:Add("addon_validator:title", "Vermilion Addon Meldung")
lang:Add("addon_validator:windowtext", [[Vermilion hat mitbekommen das dir Addons fehlen. 

 
Wenn du diese Addons abonnierst wird es deine Verbindungszeit extrem vergeringern auch musst du diese dann nicht mehr beim Verbinden herunterladen, zudem wird es auch viele fehlende Texturen beheben welche durch die fehlenden Addons kommt!

Bitte behebe dies indem du Liste benutzt!]])
lang:Add("addon_validator:open_workshop_page", "Workshop Seite öffnen")
lang:Add("addon_validator:open_workshop_page:g1", "Du musst mindestens 1 Addon auswählen um die Workshop Seite zuöffnen!")
lang:Add("addon_validator:dna", "Schließen und nicht nochmal nachfragen!")
lang:Add("addon_validator:dna:confirm", "Bist du dir sicher?\nDas wird Auswirkungen für jeden Server auf dem du vebindest nehmen.\nZum zurücksetzen schreibe: \"vermilion_addonnag_do_not_ask 0\" in die Konsole!")


--[[

	//		Automatic Broadcast		\\

]]--
lang:Add("menu:autobroadcast", "Automatische Meldung")
lang:Add("autobroadcast:list:text", "Text")
lang:Add("autobroadcast:list:interval", "Interval")
lang:Add("autobroadcast:list:title", "Automatische Meldungs Einträge")
lang:Add("autobroadcast:remove", "Eintrag entfernen")
lang:Add("autobroadcast:remove:g1", "Du musst mindestens einen Eintrag auswählen zum entfernen")
lang:Add("autobroadcast:new", "Neuer Eintrag...")
lang:Add("autobroadcast:new:interval", "Senden jede:")
lang:Add("autobroadcast:new:add", "Neuer Eintrag hinzufügen")
lang:Add("autobroadcast:new:gz", "Der Interval muss über 1 sein!")


--[[

	//		Battery Meter		\\

]]--
lang:Add("battery_meter:unplugged", "Computer ist nicht eingesteckt!")
lang:Add("battery_meter:pluggedin", "Computer eingesteckt!")
lang:Add("battery_meter:low", "Niedriger Batterie Status: %s%!")
lang:Add("battery_meter:critical", "Kritischer Batterie Status: %s%!")
lang:Add("battery_meter:interface", "Batterie: %s%%")
lang:Add("battery_meter:cl_opt", "Aktiviere Batterie Anzeige")

--[[

	//		Toolgun Limiter		\\

]]--

lang:Add("limit_toolgun:cannot_use", "Du kannst diesen Tool Modus nicht benutzen!")

--[[

	//		Commands		\\

]]--
lang:Add("commands:list:text", "Verspottungs Narricht")
lang:Add("commands:list:title", "Verspottung")
lang:Add("commands:remove", "Entferne Verspottung")
lang:Add("commands:remove:g1", "Du musst mindestens eine Verspottung auswählen.")
lang:Add("commands:new", "Neue Verspottung")
lang:Add("commands:new:add", "Füge Verspottung hinzu")

Vermilion:RegisterLanguage(lang)

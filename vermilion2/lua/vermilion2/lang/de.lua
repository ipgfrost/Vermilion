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
lang:Add("refresh", "Neuladen")
lang:Add("ok", "OK")
lang:Add("error", "Error")
lang:Add("cancel", "Abbrechen")
lang:Add("none", "Nichts")
lang:Add("rank", "Rang")

lang:Add("name", "Name")

lang:Add("yearslabel", "Jahre:")
lang:Add("monthslabel", "Monate:")
lang:Add("weekslabel", "Wochen:")
lang:Add("dayslabel", "Tage:")
lang:Add("hourslabel", "Stunden:")
lang:Add("minuteslabel", "Minuten:")
lang:Add("secondslabel", "Sekunden:")

lang:Add("activeplayers", "Aktive Spieler")


lang:Add("no_users", "Dieser Spieler existiert nicht auf dem Server.")
lang:Add("ambiguous_users", "Mehrere Treffer für \"%s\". (Treffer: %s).")
lang:Add("access_denied", "Zugriff verweigert!")
lang:Add("under_construction", "Im Bau!")
lang:Add("bad_syntax", "Ungültige Syntax!")
lang:Add("not_number", "Das ist kein numerischer Wert!")
lang:Add("not_bool", "Das ist kein boolescher Wert!")
lang:Add("player_immune", "%s ist immun gegen dich.")
lang:Add("ban_self", "Du kannst dich nicht selber bannen!")
lang:Add("kick_self", "Du kannst dich nicht selber kicken!")
lang:Add("no_rank", "Rang existiert nicht!")
lang:Add("cmd_failure", "Befehl fehlgeschlagen!")
lang:Add("cmd_notfound", "Der Befehl wurde nicht gefunden!")

lang:Add("combopanel_title", "Vermilion - Wähle eine Option")
lang:Add("confirmpanel_title", "Vermilion - Bestätigen")
lang:Add("textpanel_title", "Vermilion - Texteingabe benötigt")

lang:Add("cmd_chatpredict_prompt", "Drücke oben/runter um einen Vorschlag auszuwählen, drücke Tab um ihn einzufügen.")
lang:Add("cmd_chatpredict_nopredict", "Keine Vervollständigung verfügbar!")
lang:Add("cmd_chatpredict_setting", "Aktiviere Auto-Vervollständigung.")

lang:Add("cmd_all_bad_pos", "Du kannst hier nicht alle Spieler (@) angeben!")

lang:Add("basecommand:dedicatedunknown", "Unbekannter Befehl! Du bist nicht der Host dieses Servers; Versuchst du dir deinen Rang zu setzen? Wenn ja ist das die falsche Konsole!")
lang:Add("basecommand:unknown", "Unbekannter Befehl!")


--[[

	//		Prints:Config		\\

]]--
lang:Add("config:rank:cantmoveup", "Du kannst den Rang nicht weiter nach oben setzen, es würde sich mit dem Rang des Besitzers überlagern.")
lang:Add("config:rank:moveprotected", "Verschieben von geschütztem Rang nicht möglich!")
lang:Add("config:rank:cantmovedown", "Verschieben nicht möglich, es ist schon der letzte Rang!")
lang:Add("config:rank:renameprotected", "Kann nicht umbenannt werden, geschützter Rang!")
lang:Add("config:rank:renamed", "Rang wurde umbenannt von %s in %s")
lang:Add("config:rank:deleteprotected", "Löschen nicht möglich, dies ist ein geschützer Rang!")
lang:Add("config:rank:deleted", "Rang gelöscht: %s")
lang:Add("config:unknownpermission", "Suche nach unbekannten Rechten (%s)!")
lang:Add("config:badcolour", "Warnung: Farbe konnte nicht gesetzt werden. Falscher Typ: %s!")
lang:Add("config:invaliduser", "Ungültiger User während der Überprüfung der Rechte, voraussichtlich die Konsole!")
lang:Add("config:saving", "Speichere Daten...")
lang:Add("config:loaded", "Lade Daten!")
lang:Add("config:backup", "Erstelle ein Backup von der Konfiguration...")


lang:Add("config:join", "%s ist dem Server beigetreten.")
lang:Add("config:join:first", "%s ist dem Server zum ersten Mal beigetreten!")

lang:Add("config:left", "%s hat den Server verlassen: %s")


--[[

	//		GeoIP		\\

]]--
lang:Add("geoip:enablesetting", "Aktiviere GeoIP Service")
lang:Add("geoip:cache:expired", "GeoIP-Cache ist abgelaufen. Lösche...")


--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Allgemein")
lang:Add("category:server", "Server Optionen")
lang:Add("category:ranks", "Ränge")
lang:Add("category:player", "Spieler Verwaltung")
lang:Add("category:limits", "Beschränkungen")

--[[

	//		Base Menus		\\

]]--

lang:Add("menu:api", "API Dokumentation")
lang:Add("menu:credits", "Credits")

lang:Add("credits:title", "Vermilion Credits")
lang:Add("credits:thanks", "Danke an alle, die ihre Ideen in Vermilion eingebracht und die gesamte Entwicklung unterstützt haben!")
lang:Add("credits:scapi", "Vermilion verwendet die SoundCloud API. Die Verwendung der Dienste, die von Vermilion bereitgestellt werden, die die SoundCloud API verwenden, stimmen den Nutzungsbedingungen der SoundCloud API zu.")
lang:Add("credits:fgip", "Die GeoIP-Dienste in Vermilion werden unterstützt durch freegeoip.net. freegeoip.net nutzt die von MaxMind zusammengestellten GeoLite-Daten, zu finden unter maxmind.com.")
lang:Add("credits:workshop", "Vermilion Workshop Seite")
lang:Add("credits:github", "GitHub Projekt")
lang:Add("credits:group", "Steam Gruppe")
lang:Add("credits:workshoprating", "Workshop Bewertung")
lang:Add("credits:workshoprating:detail", "Workshop Bewertung: %s%%")

lang:Add("menu:modules", "Module")
lang:Add("modules:clickon", "Klicke auf ein Modul...")
lang:Add("modules:enabled", "Aktiviert")


--[[

	//		Welcome Panel		\\

]]--
lang:Add("menu:welcome", "Willkommen")
lang:Add("welcome:welcome", "Willkommen bei Vermilion!")
lang:Add("welcome:changelog", "Changelog")
lang:Add("welcome:faq", "FAQ")


--[[

	//		Addon Validator		\\

]]--
lang:Add("addon_validator:title", "Vermilion Addon Meldung")
lang:Add("addon_validator:windowtext", [[Vermilion hat bemerkt, dass dir Addons fehlen.
Wenn du diese Addons abonnierst, wird es dich deutlich weniger Zeit kosten dem Server beizutreten, auch musst du diese dann nicht mehr beim Verbinden herunterladen. Zudem wird es auch viele fehlende Texturen beheben, welche durch fehlende Addons erzeugt werden!
Du kannst dies beheben, indem du folgende Liste verwendest!]])
lang:Add("addon_validator:open_workshop_page", "Workshop Seite öffnen")
lang:Add("addon_validator:open_workshop_page:g1", "Du musst mindestens 1 Addon auswählen um die Workshop Seite zu öffnen!")
lang:Add("addon_validator:dna", "Schließen und nicht nochmal nachfragen!")
lang:Add("addon_validator:dna:confirm", "Bist du dir sicher?\nDas wird Auswirkungen auf jeden Server haben, mit dem du dich vebindest.\nUm zurückzusetzen gebe folgendes in die Konsole ein: \"vermilion_addonnag_do_not_ask 0\"")


--[[

	//		Automatic Broadcast		\\

]]--
lang:Add("menu:autobroadcast", "Auto-Broadcast")
lang:Add("autobroadcast:list:text", "Text")
lang:Add("autobroadcast:list:interval", "Intervall")
lang:Add("autobroadcast:list:title", "Auto-Broadcast Einträge")
lang:Add("autobroadcast:remove", "Eintrag entfernen")
lang:Add("autobroadcast:remove:g1", "Du musst mindestens einen Eintrag zum Entfernen auswählen.")
lang:Add("autobroadcast:new", "Neuer Eintrag...")
lang:Add("autobroadcast:new:interval", "Sende jede:")
lang:Add("autobroadcast:new:add", "Eintrag hinzufügen")
lang:Add("autobroadcast:new:gz", "Das Intervall muss größer als 0 sein!")


--[[

	//		Automatic Promotion		\\

]]--
lang:Add("menu:autopromote", "Auto-Promote")
lang:Add("auto_promote:autodone", "%s wurde automatisch zum %s Rang hinzugefügt, nachdem er für %s gespielt hat!")
lang:Add("auto_promote:header", "Auto-Promotion Einträge")
lang:Add("auto_promote:remove", "Eintrag entfernen")
lang:Add("auto_promote:remove:error", "Du musst mindestens einen Eintrag auswählen.")
lang:Add("auto_promote:save", "Einträge speichern")
lang:Add("auto_promote:from", "Vom Rang: ")
lang:Add("auto_promote:to", "Bis Rang: ")
lang:Add("auto_promote:after", "Nach einer Spielzeit von (Ausgegangen wird vom ersten Verbinden, nicht von der letzten Beförderung!):")
lang:Add("auto_promote:list:from", "Vom Rang")
lang:Add("auto_promote:list:to", "Bis Rang")
lang:Add("auto_promote:list:after", "Nach einer Spielzeit von")
lang:Add("auto_promote:add", "Eintrag hinzufügen")
lang:Add("auto_promote:add:error:inittarrank", "Bitte gebe einen gültigen Anfangs- und Ziel-Rang an!")
lang:Add("auto_promote:add:error:diff", "Es müssen zwei unterschiedliche Ränge sein.")
lang:Add("auto_promote:add:error:time:0", "Die Spielzeit muss größer als 0 sein!")LO
lang:Add("auto_promote:unsaved", "Es gibt nicht gespeicherte Veränderungen in den Auto-Promote Einstellungen! Sicher schließen?")


--[[

	//		Bans		\\

]]--
lang:Add("menu:bans", "Bann-Manager")
lang:Add("cmd:ban:syntax", "<Name> <Zeit:Minuten (können gebrochene Zahlen sein, oder 0 für einen permanenten Bann)> <Grund>")
lang:Add("cmd:kick:syntax", "<Name> <Grund>")
lang:Add("cmd:unban:syntax", "<Name>")
lang:Add("bans:noreason", "Kein Grund angegeben!")
lang:Add("bans:ban:allplayers:perma", "Alle Spieler wurden permanent gebannt von %s, mit der Begründung: %s")
lang:Add("bans:ban:allplayers", "Alle Spieler wurden gebannt von %s, bis %s, mit der Begründung: %s")
lang:Add("bans:ban:perma:text", "%s wurde permanent gebannt von %s, mit der Begründung: %s")
lang:Add("bans:ban:text", "%s wurde gebannt von %s bis %s, mit der Begründung: %s")
lang:Add("bans:kick:kicked", "%s wurde gekickt von %s: %s")
lang:Add("bans:kick:kickedtext", "Gekickt von %s: %s")
lang:Add("bans:kick:allplayers", "Alle Spieler wurden gekickt von %s, mit der Begründung: %s")
lang:Add("bans:unban:toomany", "Zu viele Treffer. Bitte grenze deine Suche ein.")
lang:Add("bans:unban:none", "Kein Ergebnis gefunden.")
lang:Add("bans:unban:text", "%s wurde entbannt von %s")
lang:Add("bans:alreadybanned", "Dieser Spieler wurde bereits gebannt!")
lang:Add("bans:time:toosmall", "Du kannst keine Spieler für weniger als 0 Sekunden bannen! Möglich ist 0 (Permaban) und größer als 0 (Sekunden).")
lang:Add("bans:reconnectalert", "%s hat versucht den Server erneut beizutreten!")
lang:Add("bans:reconnect:event", "%s hat versucht den Server erneut beizutreten!")
lang:Add("bans:retorttext:perma", "Du bist permanent gebannt: %s")
lang:Add("bans:retorttext", "Du bist gebannt bis %s: %s")
lang:Add("bans:gui:bantime", "Gebe eine Banndauer an")
lang:Add("bans:reason", "Aus welchem Grund bannst du diese(n) Spieler?")
lang:Add("bans:never", "Nie")
lang:Add("bans:listings", "Bann-Einträge")
lang:Add("bans:banbtn", "Spieler bannen")
lang:Add("bans:banbtn:error:0", "Du musst mindestens einen Spieler zum Bannen auswählen.")
lang:Add("bans:kickbtn", "Spieler kicken")
lang:Add("bans:kickbtn:error:0", "Du musst mindestens einen Spieler zum Kicken auswählen.")
lang:Add("bans:kickbtn:reason", "Aus welchem Grund kickst du diese(n) Spieler?")
lang:Add("bans:banply", "Spieler bannen")
lang:Add("bans:kickply", "Spieler kicken")
lang:Add("bans:editreason", "Grund bearbeiten")
lang:Add("bans:editreason:dialog", "Trage den neuen Bann-Grund für diesen Spieler ein:")
lang:Add("bans:details", "Details...")
lang:Add("bans:editduration", "Dauer bearbeiten")
lang:Add("bans:unbanbtn", "Spieler entbannen")
lang:Add("bans:list:bannedon", "Gebannt am")
lang:Add("bans:list:expires", "Läuft aus am")
lang:Add("bans:list:bannedby", "Gebannt von")
lang:Add("bans:list:reason", "Grund")


--[[

	//		Battery Meter		\\

]]--
lang:Add("battery_meter:unplugged", "Computer ist nicht eingesteckt!")
lang:Add("battery_meter:pluggedin", "Computer eingesteckt!")
lang:Add("battery_meter:low", "Niedrigen Batterie-Status: %s%!")
lang:Add("battery_meter:critical", "Kritischer Batterie-Status: %s%!")
lang:Add("battery_meter:interface", "Batterie: %s%%")
lang:Add("battery_meter:cl_opt", "Aktiviere Batterie-Anzeige")

--[[

	//		Chat Censor		\\

]]--
lang:Add("menu:chat_censor", "Chat-Zensur")
lang:Add("chat_censor:enable", "Aktivere Chat-Zensur")
lang:Add("chat_censor:ipv4", "Zensiere IPv4-Adressen")
lang:Add("chat_censor:add", "Neuen Ausdruck hinzufügen")
lang:Add("chat_censor:edit", "Ausdruck bearbeiten")
lang:Add("chat_censor:remove", "Ausdruck entfernen")
lang:Add("chat_censor:phrase", "Ausdruck")
lang:Add("chat_censor:list", "Blockierte Ausdrücke")

--[[

	//		Client Settings		\\

]]--
lang:Add("menu:client_settings", "Client-Optionen")
lang:Add("client_settings:cat:features", "Features")
lang:Add("client_settings:cat:graphics", "Grafik")
lang:Add("client_settings:opt:skin", "Skin (erfordert Neustart)")
lang:Add("client_settings:opt:lang", "Sprache (erfordert Neustart)")

--[[

	//		Player Management Menu		\\

]]--
lang:Add("menu:playermanagement", "Befehl ausführen")


--[[

	//		Toolgun Limiter		\\

]]--

lang:Add("limit_toolgun:cannot_use", "Du kannst diesen Toolgun-Modus nicht verwenden!")


--[[

	//		Prop Protection		\\

]]--
lang:Add("prop_protect:toolgun:cannotuse", "Du kannst die Toolgun nicht auf diesem Prop anwenden!")
lang:Add("prop_protect:world:cannotuse", "Du kannst nicht mit Kartengegenständen interagieren.")
lang:Add("prop_protect:gravgun:cannotuse", "Du kannst die Gravity Gun nicht auf diesen Prop anwenden!")
lang:Add("prop_protect:physgun:cannotuse", "Du kannst die Physics Gun nicht auf diesen Prop anwenden!")
lang:Add("prop_protect:use:cannotuse", "Du kannst diesen Prop nicht benutzen!")
lang:Add("prop_protect:drive:cannotuse", "Du kannst diesen Prop nicht fahren!")
lang:Add("prop_protect:break:cannotuse", "Du kannst diesen Prop nicht brechen!")
lang:Add("prop_protect:property:cannotuse", "Du kannst diese Eigenschaft nicht auf diesem Prop anwenden!")
lang:Add("prop_protect:variable:cannotuse", "Du kannst die Prop Variablen nicht editieren!")
lang:Add("prop_protect:quotaheader", "Buddy Quota (%s/64):")

--[[

	//		Commands		\\

]]--
lang:Add("menu:gimps", "Gimp Editor")
lang:Add("commands:list:text", "Gimp-Nachricht")
lang:Add("commands:list:title", "Gimps")
lang:Add("commands:remove", "Entferne Gimp")
lang:Add("commands:remove:g1", "Du musst mindestens einen Gimp auswählen.")
lang:Add("commands:new", "Neues Gimp")
lang:Add("commands:new:add", "Gimp hinzufügen")
lang:Add("commands:gimps:newlines", "Gimp darf keine Zeilenumbrüche beinhalten!")

lang:Add("commands:version", "Die aktuelle Version ist: %s")

lang:Add("commands:cmd:tplook:syntax", "[Spieler zum Teleportieren] [Spieler-Bezug]")
lang:Add("commands:cmd:tppos:syntax", "[Spieler] <x> <y> <z>")
lang:Add("commands:cmd:teleport:syntax", "[Spieler zum teleportieren] <Spieler, zu dem teleportiert wird>")
lang:Add("commands:cmd:goto:syntax", "<Spieler, zu dem gesprungen werden soll>")
lang:Add("commands:cmd:bring:syntax", "<Spieler, der gebracht werden soll>")
lang:Add("commands:cmd:tpquery:syntax", "<Spieler>")
lang:Add("commands:cmd:tpaccept:syntax", "<Spieler>")
lang:Add("commands:cmd:tpdeny:syntax", "<Spieler>")
lang:Add("commands:cmd:speed:syntax", "[Spieler] <Geschwindigkeits-Multiplikator>")
lang:Add("commands:cmd:respawn:syntax", "[Spieler]")
lang:Add("commands:cmd:pm:syntax", "<Spieler> <Nachricht>")
lang:Add("commands:cmd:r:syntax", "<Nachricht>")
lang:Add("commands:cmd:getpos:syntax", "[Spieler]")
lang:Add("commands:cmd:sudo:syntax", "<Spieler> <Befehl>")
lang:Add("commands:cmd:spectate:syntax", "[-entity <entityid>] [-player <Spieler>]") -- Note: don't localise -entity and -player
lang:Add("commands:cmd:steamid:syntax", "[Spieler]")
lang:Add("commands:cmd:ping:syntax", "[Spieler]")
lang:Add("commands:cmd:convar:syntax", "<cvar> [Wert]")
lang:Add("commands:cmd:deaths:syntax", "<Spieler> <Tode>")
lang:Add("commands:cmd:frags:syntax", "<Spieler> <Kills>")
lang:Add("commands:cmd:armour:syntax", "<Spieler> <Rüstung>")
lang:Add("commands:cmd:kickvehicle:syntax", "<Spieler>")
lang:Add("commands:cmd:ignite:syntax", "<Spieler> <Zeit:Sekunden>")
lang:Add("commands:cmd:extinguish:syntax", "<Spieler>")
lang:Add("commands:cmd:random:syntax", "[min] <max>")
lang:Add("commands:cmd:lockplayer:syntax", "<Spieler>")
lang:Add("commands:cmd:unlockplayer:syntax", "<Spieler>")
lang:Add("commands:cmd:kill:syntax", "<Spieler>")
lang:Add("commands:cmd:assassinate:syntax", "<Spieler>")
lang:Add("commands:cmd:ragdoll:syntax", "<Spieler>")
lang:Add("commands:cmd:stripammo:syntax", "<Spieler>")
lang:Add("commands:cmd:flatten:syntax", "<Spieler>")
lang:Add("commands:cmd:launch:syntax", "<Spieler>")
lang:Add("commands:cmd:stripweapons:syntax", "<Spieler>")
lang:Add("commands:cmd:health:syntax", "[Spieler] <Leben>")
lang:Add("commands:cmd:explode:syntax", "<Spieler> [Größe:20]")
lang:Add("commands:cmd:setteam:syntax", "<Spieler> <Team>")
lang:Add("commands:cmd:slap:syntax", "<Spieler> <Anzahl> <Schaden>")
lang:Add("commands:cmd:adminchat:syntax", "<Nachricht>")
lang:Add("commands:cmd:gimp:syntax", "<Spieler>")
lang:Add("commands:cmd:mute:syntax", "<Spieler>")
lang:Add("commands:cmd:gag:syntax", "<Spieler>")
lang:Add("commands:cmd:jail:syntax", "<Spieler>")

lang:Add("commands:tplook:text:self", "%s teleportiert %s zuseiner Crosshair Position.")
lang:Add("commands:tplook:text", "%s teleportiert %s zu %s's Crosshair Position.")
lang:Add("commands:tplook:all", "Alle Spieler wurde zu %s's Crosshair Position teleportiert.")

lang:Add("commands:tppos:outofworld", "Kann keinen Spieler hier hin teleportieren; es ist außerhalb der Karte!")
lang:Add("commands:tppos:teleported", "%s teleportiert %s zu %s")
lang:Add("commands:tppos:teleported:all", "%s teleportierte alle Spieler zu %s")

lang:Add("commands:teleport", "%s teleportiert %s zu %s")
lang:Add("commands:teleport:all", "%s teleportierte alle Spieler zu %s")

lang:Add("commands:goto", "%s teleportierte sich zu %s")

lang:Add("commands:bring", "%s brachte %s zu sich.")
lang:Add("commands:bring:all", "%s brachte alle Spieler zu sich.")

lang:Add("commands:tpquery:otherpermission", "Diesem Spieler ist es nicht erlaubt Teleportations-Anfragen anzunehmen.")
lang:Add("commands:tpquery:sent", "Anfrage versandt!")
lang:Add("commands:tpquery:notification", "%s fragt, ob er sich zu dir teleportieren darf...")

lang:Add("commands:tpaccept:notask", "Dieser Spieler hat nicht gefragt ob er sich zu dir teleportieren darf.")
lang:Add("commands:tpaccept:already", "Dieser Spieler hat sich bereits zu dir teleportiert, die Anfrage wurde gelöscht!")
lang:Add("commands:tpaccept:accepted", "Anfrage angenommen! Teleportiert in 10 Sekunden.")
lang:Add("commands:tpaccept:moved", "Irgendjemand hat sich bewegt! Teleportation wurde abgebrochen!")
lang:Add("commands:tpaccept:done", "Teleportiert...")

lang:Add("commands:tpdeny:notask", "Dieser Spieler hat dich nicht gefragt, ob er sich zu dir teleportieren darf.")
lang:Add("commands:tpdeny:already", "Dieser Spieler hat sich bereits zu dir teleportiert, die Anfrage wurde gelöscht!")
lang:Add("commands:tpdeny:done", "Anfrage abgelehnt!")

lang:Add("commands:speed:done:self", "%s hat seine Geschwindigkeit auf %sx normale Geschwindigkeit gesetzt.")
lang:Add("commands:speed:done:other", "%s hat die Geschwindigkeit von %s auf %sx normale Geschwindigkeit gesetzt.")
lang:Add("commands:speed:done:all", "%s hat die Geschwindigkeit von allen auf %sx normale Geschwindigkeit gesetzt.")

lang:Add("commands:respawn:done", "%s zwang %s zu respawnen.")
lang:Add("commands:respawn:done:all", "%s zwang alle Spieler zu respawnen.")

lang:Add("commands:r:notvalid", "Du hast noch keine Nachricht erhalten oder der Spieler hat den Server verlassen!")
lang:Add("commands:r:private", "Privat")

lang:Add("commands:time", "Uhrzeit des Servers ist: %s")

lang:Add("commands:getpos:self", "Deine Position ist %s")
lang:Add("commands:getpos:other", "%s's Position ist %s")

lang:Add("commands:spectate:banned", "Du kannst diesem Entity nicht zuschauen!")
lang:Add("commands:spectate:done", "Du schaust nun %s zu")
lang:Add("commands:spectate:ent:invalid", "Das ist kein gültiges Entity.")
lang:Add("commands:spectate:ply:self", "Du kannst dich nicht selber beobachten!")
lang:Add("commands:spectate:invtyp", "Ungültiger Typ!")
lang:Add("commands:spectate:removed", "Das Entity, welchem du zuschauen möchtest, wurde entfernt.")

lang:Add("commands:unspectate:bad", "Du beobachtest nichts...")

lang:Add("commands:steamid:self", "Deine SteamID ist %s")
lang:Add("commands:steamid:other", "%s's SteamID ist %s")

lang:Add("commands:ping:self", "Dein Ping ist %sms")
lang:Add("commands:ping:other", "%s's Ping ist %sms")

lang:Add("commands:convar:nexist", "Dieser Convar existiert nicht!")
lang:Add("commands:convar:value", "%s wurde gesetzt zu %s")
lang:Add("commands:convar:cannotset", "Du kannst dieses convar nicht setzen.")
lang:Add("commands:convar:set", "%s setzte %s auf %s")

lang:Add("commands:deaths", "%s setzte %s's Todes-Counter auf %s")

lang:Add("commands:frags", "%s setzte %s's Kill-Counter auf %s")

lang:Add("commands:armour", "%s setzte %s's Rüstung auf %s")

lang:Add("commands:decals", "%s hat alle Decals entfernt.")

lang:Add("commands:kickvehicle:notin", "Dieser Spieler befindet sich nicht in einem Fahrzeug!")
lang:Add("commands:kickvehicle:done", "%s warf %s aus seinem/ihrem Fahrzeug.")

lang:Add("commands:ignite:done", "%s setzte %s in Brand für %s Sekunden.")

lang:Add("commands:extinguish:done", "%s löschte %s")

lang:Add("commands:random", "Nummer: %s")

lang:Add("commands:suicide", "%s hat sich selbst gekickt.")

lang:Add("commands:lockplayer", "%s wurde gesperrt von %s")
lang:Add("commands:lockplayer:all", "%s sperrte alle Spieler.")

lang:Add("commands:unlockplayer", "%s wurde entsperrt von %s")
lang:Add("commands:unlockplayer:all", "%s hat alle Spieler entsperrt.")

lang:Add("commands:kill", "%s tötete %s")
lang:Add("commands:kill:all", "%s tötete jeden.")

lang:Add("commands:ragdoll:done", "%s verwandelte %s in eine Ragdoll.")
lang:Add("commands:ragdoll:done:all", "%s verwandelte alle Spieler in Ragdolls.")

lang:Add("commands:stripammo:done", "%s entfernte %s's Munition.")
lang:Add("commands:stripammo:done:all", "%s entfernte von jedem die Munition.")

lang:Add("commands:stripweapons:done", "%s entzog %s seine Waffen!")
lang:Add("commands:stripweapons:done:all", "%s entzog allen Spielern die Waffen!")

lang:Add("commands:flatten:done", "%s planierte %s")
lang:Add("commands:flatten:done:all", "%s planierte alle Spieler.")

lang:Add("commands:launch:done", "%s katapultierte %s in die Luft!")
lang:Add("commands:launch:done:all", "%s katapultierte alle Spieler in die Luft!")

lang:Add("commands:health:done", "%s setzte %s's Leben auf %s")
lang:Add("commands:health:done:all", "%s setzte von allen Spielern das Leben auf %s")

lang:Add("commands:explode:done", "%s lies %s explodieren.")
lang:Add("commands:explode:done:all", "%s lies alle Spieler explodieren.")

lang:Add("commands:setteam:amb", "Mehrere Ergebnisse für Teamname, versuche es erneut!")
lang:Add("commands:setteam:nores", "Kein Ergebnis für diesen Teamnamen, versuche es erneut!")
lang:Add("commands:setteam:done", "%s wies %s dem Team '%s' zu")
lang:Add("commands:setteam:done:all", "%s wies alle Spieler dem Team '%s' zu")

lang:Add("commands:slap:done", "%s schlug %s %s mal!")
lang:Add("commands:slap:done:all", "%s schlug alle Spieler %s mal!")

lang:Add("commands:adminchat:noadmin", "Momentan sind keine Admins online.")
lang:Add("commands:adminchat:sent", "Nachricht versandt!")

lang:Add("commands:gimp:gimped:done", "%s vespottete %s")
lang:Add("commands:gimp:ungimped:done", "%s entfernte den Gimp von %s")
lang:Add("commands:gimp:help", "Führe den Gimp-Befehl nochmal aus um ihn zu entfernen.")

lang:Add("commands:mute:muted:done", "%s stelle %s auf stumm")
lang:Add("commands:mute:unmuted:done", "%s ließ %s wieder sprechen")
lang:Add("commands:mute:help", "Führe nochmal den Mute-Befehl aus um ihn zu entmuten.")

lang:Add("commands:gag:gagged:done", "%s verbat %s das Schreiben im Chat")
lang:Add("commands:gag:ungagged:done", "%s erlaubte %s das Schreiben im Chat")
lang:Add("commands:gag:help", "Führe nochmal den Gag-Befehl aus um das Schreiben im Chat wieder zu erlauben.")

lang:Add("commands:jail:release", "%s hat %s vom Gefängnis befreit!")
lang:Add("commands:jail:nojail", "Keine Gefängnis-Position gesetzt!")
lang:Add("commands:jail:jail", "%s hat %s in das Gefängnis verwiesen!")

lang:Add("commands:setjailpos:world", "Das ist nicht innerhalb der Welt...")
lang:Add("commands:setjailpos:done", "%s hat die Gefängnis Position auf %s gesetzt!")

--[[

	//		Zones		\\

]]--
lang:Add("zones:mode_params", "Modus-Parameter")

lang:Add("zones:mode:anti_noclip", "Anti-Noclip")
lang:Add("zones:mode:anti_rank", "Anti-Rang")
lang:Add("zones:mode:sudden_death", "Sudden Death")
lang:Add("zones:mode:notify_enter", "Nachricht beim Betreten")
lang:Add("zones:mode:notify_leave", "Nachricht beim Verlassen")
lang:Add("zones:mode:speed", "Geschwindigkeits Boost")
lang:Add("zones:mode:no_vehicles", "Keine Fahrzeuge")
lang:Add("zones:mode:confiscate_weapons", "Waffen beschlagnahmen")
lang:Add("zones:mode:kill", "Töten")
lang:Add("zones:mode:anti_propspawn", "Spieler Props verbieten")
lang:Add("zones:mode:no_gravity", "Keine Schwerkraft")
lang:Add("zones:mode:anti_pvp", "Anti-PvP")

--[[
	
	//		Event Log		\\
	
]]--
lang:Add("event_logger:chatcommand", "%s hat den %s Chat-Befehl ausgeführt. (%s)")

Vermilion:RegisterLanguage(lang)

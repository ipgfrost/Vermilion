--[[
 Copyright 2015-16 Ned Hyett,

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

Vermilion.ChatCommands = {}
Vermilion.ChatAliases = {}
Vermilion.ChatCommandConst = {
	MultiPlayerArg = 1,
	PlayerArg = 2,
	StringArg = 3,
	NumberArg = 4,
	NumberRangeArg = 5
}

util.AddNetworkString("VFakeChat")
util.AddNetworkString("VClientCMD")
util.AddNetworkString("VSendCommands")
util.AddNetworkString("VClientPrint")

net.Receive("VFakeChat", function(len, vplayer)
	Vermilion:HandleChat(vplayer, net.ReadString(), vplayer, false, { vplayer, "", false } )
end)

net.Receive("VClientCMD", function(len, vplayer)
	Vermilion:HandleChat(vplayer, net.ReadString(), vplayer, true, { vplayer, "", false } )
end)



local commandMustHave = { "Name", "Function" }
local commandShouldHave = {
	{ "Predictor", nil },
	{ "Syntax", "" },
	{ "CanMute", false },
	{ "CanRunOnDS", true },
	{ "Permissions", {} },
	{ "AllBroadcast", nil },
	{ "AllValid", nil },
	{ "BasicParameters", nil },
	{ "Category", "Misc" },
	{ "CommandFormat", "" }
}

local function commandGLOG(commandname, executor, text, replacements, typ, time) -- Global Logger: use this to mute commands.
	if(text == nil) then return end
	if(Vermilion:GetData("muted_commands", {}, true)[commandname] == false) then return end
	if(IsValid(executor)) then
		if(Vermilion:HasPermission(executor, "anonymous_command_exec") && Vermilion:GetUser(executor):GetRank():GetUID() != Vermilion:GetOwnerRank():GetUID() && replacements != nil) then
			for i,k in pairs(replacements) do
				if(k == executor:GetName()) then
					replacements[i] = "Somebody"
				end
			end
		end
	end
	Vermilion:BroadcastNotification(text, replacements, typ, time)
end

local function commandFilter(commandname)
	if(text == nil) then return end
	if(Vermilion:GetData("muted_commands", {}, true)[commandname] == false) then return false end
	return true
end

function Vermilion:AddChatCommand(props)
	for i,k in pairs(commandMustHave) do
		assert(props[k] != nil)
	end
	for i,k in pairs(commandShouldHave) do
		if(props[k[1]] == nil) then props[k[1]] = k[2] end
	end
	if(props.Description == nil) then
		props.Description = Vermilion:TranslateStr("cmd:" .. props.Name .. ":description")
	end
	if(props.Syntax == "") then
		local test = Vermilion:TranslateStr("cmd:" .. props.Name .. ":syntax")
		if(test != "cmd:" .. props.Name .. ":syntax") then
			props.Syntax = test
		end
	end
	if(self.ChatCommands[activator] != nil) then
		self.Log("Chat command " .. activator .. " has been overwritten!")
	end
	if(props.CanRunOnDS) then
		Vermilion:AddCommand(props.Name, function(sender, args)
			for i,k in pairs(props.Permissions) do
				if(not Vermilion:HasPermission(sender, k)) then
					Vermilion.Log(Vermilion:TranslateStr("access_denied", nil, sender))
					return
				end
			end
			if(not IsValid(sender)) then
				sender = {}
				function sender:GetName()
					return "Console"
				end
				function sender:SteamID()
					return "CONSOLE"
				end
			else
				if(Vermilion:GetModule("event_logger") != nil) then
					Vermilion:GetModule("event_logger"):AddEvent("script", Vermilion:TranslateStr("event_logger:chatcommand", { sender:GetName(), props.Name, table.concat(args, ", ") }))
				end
			end

			local success = props.Function(sender, args, function(text, replacements) Vermilion.Log(Vermilion:TranslateStr(text, replacements)) end, function(text, replacements, typ, time) commandGLOG(props.Name, vplayer, text, replacements, typ, time) end)
			if(success == nil) then success = true end
			if(not success) then
				Vermilion.Log(Vermilion:TranslateStr("cmd_failure", nil, sender))
			end
		end)
	end
	self.ChatCommands[props.Name] = props
end

Vermilion:AddChatCommand({
	Name = "version",
	Description = "Prints the current version number.",
	Function = function(sender, text, log, glog)
		log(Vermilion:TranslateStr("commands:version", { Vermilion.GetVersionString() }))
	end
})



function Vermilion:AliasChatCommand(command, aliasTo)
	if(self.ChatAliases[aliasTo] != nil) then
		self.Log("Chat alias " .. aliasTo .. " is being overwritten!")
	end
	self.ChatAliases[aliasTo] = command
end



function Vermilion:HandleChat(vplayer, text, targetLogger, isConsole, oargs)
	targetLogger = targetLogger or vplayer
	local logFunc = nil
	if(isfunction(targetLogger)) then
		logFunc = targetLogger
	else
		if(isConsole) then
			logFunc = function(text, replacements) if(vplayer == nil and vplayer:SteamID() != "CONSOLE") then Vermilion.Log(Vermilion:TranslateStr(text, replacements)) else
				net.Start("VClientPrint")
				net.WriteString(Vermilion:TranslateStr(text, replacements))
				net.Send(vplayer)
			end end
			if(vplayer == nil) then
				vplayer = {}
				function vplayer:GetName()
					return "Console"
				end
				function vplayer:SteamID()
					return "CONSOLE"
				end
			end
		else
			logFunc = function(text, replacements, typ, delay) Vermilion:AddNotification(targetLogger, text, replacements, typ, delay) end
		end
	end
	if(string.StartWith(text, Vermilion:GetData("command_prefix", "!", true))) then
		local commandText = string.sub(text, 2)
		local commandName, parts = Vermilion.ParseChatLineForParameters(commandText)
		if(Vermilion.ChatAliases[commandName] != nil) then
			commandName = Vermilion.ChatAliases[commandName]
		end
		local command = Vermilion.ChatCommands[commandName]
		if(command != nil) then
			for i,k in pairs(command.Permissions) do
				if(not Vermilion:HasPermission(vplayer, k)) then
					logFunc("access_denied", nil, NOTIFY_ERROR)
					return ""
				end
			end
			local atindexes = {}
			for i,k in pairs(parts) do
				if(k == "@") then // <-- this does hax to make sure I don't have to program in a load of possible cases in each command. Plus this means that I can add other symbols at some point.
					table.insert(atindexes, i)
				end
			end
			if(table.Count(atindexes) > 0) then
				if(command.AllValid != nil) then
					for i,k in pairs(atindexes) do
						for i1,k1 in pairs(command.AllValid) do
							if(k1.Size != nil) then
								if(k1.Size != table.Count(parts)) then
									continue
								end
							end
							if(not table.HasValue(k1.Indexes, k)) then
								logFunc("cmd_add_bad_pos", nil, NOTIFY_ERROR)
								return ""
							end
						end
					end
				else
					logFunc("cmd_all_bad_pos", nil, NOTIFY_ERROR)
					return ""
				end
				if(Vermilion:GetModule("event_logger") != nil) then
					Vermilion:GetModule("event_logger"):AddEvent("script", Vermilion:TranslateStr("event_logger:chatcommand", { vplayer:GetName(), commandName, table.concat(parts, ", ") }))
				end
				local edittable = table.Copy(parts)
				for i,k in pairs(VToolkit.GetValidPlayers()) do
					for i1,k1 in pairs(atindexes) do
						edittable[k1] = k:GetName()
					end
					local success = command.Function(vplayer, edittable, logFunc, function() end) // <-- we ignore global output here, otherwise we get spammed.
					if(success == nil) then success = true end
					if(not success) then
						return "" // <-- we can assume that this error will happen again, so don't bother repeating.
					end
				end
				if(command.AllBroadcast != nil) then
					if(commandFilter(command.Name)) then
						local ttext, rreplacements = command.AllBroadcast(vplayer, parts)
						for i,k in pairs(VToolkit.GetValidPlayers()) do
							Vermilion:AddNotification(k, ttext, rreplacements)
						end
					end
				end
			else
				if(Vermilion:GetModule("event_logger") != nil) then
					Vermilion:GetModule("event_logger"):AddEvent("script", Vermilion:TranslateStr("event_logger:chatcommand", { vplayer:GetName(), commandName, table.concat(parts, ", ") }))
				end
				local success = command.Function(vplayer, parts, logFunc, function(text, replacements, typ, time) commandGLOG(commandName, vplayer, text, replacements, typ, time) end)
				if(success == nil) then success = true end
				if(not success) then
					Vermilion.Log(Vermilion:TranslateStr("cmd_failure", nil, vplayer))
				end
			end
			return ""
		else
			local result = hook.Run("VPlayerSay", oargs[1], oargs[2], oargs[3])
			if(result == "") then
				return result
			end
			logFunc("cmd_notfound", nil, NOTIFY_ERROR)
			return ""
		end
	else
		return hook.Run("VPlayerSay", oargs[1], oargs[2], oargs[3])
	end
end

Vermilion:AddHook("PlayerSay", "Say1", false, function(vplayer, text, teamChat)
	return Vermilion:HandleChat(vplayer, text, vplayer, false, {vplayer, text, teamChat})
end)

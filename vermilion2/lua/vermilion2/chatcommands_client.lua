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

Vermilion.ChatCommandsClient = {}
Vermilion.ChatCommandConst = {
	MultiPlayerArg = 1,
	PlayerArg = 2,
	StringArg = 3,
	NumberArg = 4,
	NumberRangeArg = 5
}

net.Receive("VClientPrint", function()
	Vermilion.Log(net.ReadString(), "Server CMD")
end)

function Vermilion:AddChatCommand(props)
	Vermilion.ChatCommandsClient[props.Name] = props
end

function Vermilion:AliasChatCommand() end

Vermilion:AddHook(Vermilion.Event.MOD_POST, "AddToCommandMenu", true, function()
	if(Vermilion:GetModule("playermanagement") == nil) then return end
	local mod = Vermilion:GetModule("playermanagement")

	for i,k in pairs(Vermilion.ChatCommandsClient) do
		if(k.BasicParameters == nil) then continue end
		local tree = {}
		local target = "Stage1"
		local functionStages = {}
		for i1,k1 in pairs(k.BasicParameters) do
			if(k1.Type == Vermilion.ChatCommandConst.MultiPlayerArg and target == "Stage1") then
				tree.Stage1 = "PLAYERLIST"
				target = "Stage2"
				continue
			end
			if(k1.Type == Vermilion.ChatCommandConst.MultiPlayerArg and tree.Stage1 != nil) then return end
			if(k1.Type == Vermilion.ChatCommandConst.PlayerArg) then
				table.insert(functionStages, { Type = "playercombo", CmdIndex = i1 })
				continue
			end
			if(k1.Type == Vermilion.ChatCommandConst.StringArg) then
				table.insert(functionStages, { Type = "textbox", CmdIndex = i1 })
				continue
			end
			if(k1.Type == Vermilion.ChatCommandConst.NumberArg) then
				table.insert(functionStages, { Type = "numberwang", CmdIndex = i1, Bounds = k1.Bounds })
				continue
			end
			if(k1.Type == Vermilion.ChatCommandConst.NumberRangeArg) then
				table.insert(functionStages, { Type = "slider", Bounds = k1.Bounds, Decimals = k1.Decimals, Text = k1.InfoText, CmdIndex = i1 })
				continue
			end
		end
		tree[target] = function(paneld, playerlist)
			local impl = {}
			for i2,k2 in pairs(functionStages) do
				if(k2.Type == "playercombo") then
					impl[k2.CmdIndex] = VToolkit:CreateComboBox(VToolkit.GetPlayerNames(), 1)
					paneld:Add(impl[k2.CmdIndex])
				end
				if(k2.Type == "textbox") then
					impl[k2.CmdIndex] = VToolkit:CreateTextbox()
					paneld:Add(impl[k2.CmdIndex])
				end
				if(k2.Type == "numberwang") then
					impl[k2.CmdIndex] = VToolkit:CreateNumberWang(k2.Bounds.Min, k2.Bounds.Max)
					paneld:Add(impl[k2.CmdIndex])
				end
				if(k2.Type == "slider") then
					impl[k2.CmdIndex] = VToolkit:CreateSlider(k2.Text, k2.Bounds.Min, k2.Bounds.Max, k2.Decimals)
					paneld:Add(impl[k2.CmdIndex])
				end
			end
			paneld:Add(VToolkit:CreateButton("Run", function()
				if(target == "Stage1") then
					local cmdtext = k.CommandFormat
					local params = {}
					for i3,k3 in pairs(impl) do
						table.insert(params, tostring(k3:GetValue()))
					end
					cmdtext = string.format(cmdtext, unpack(params))
					mod:SendChat("!" .. k.Name .. " " .. cmdtext)
				else
					for i3,k3 in pairs(playerlist:GetSelected()) do
						local cmdtext = k.CommandFormat
						local params = { k3:GetValue(1) }
						for i4,k4 in pairs(impl) do
							table.insert(params, tostring(k4:GetValue()))
						end
						cmdtext = string.format(cmdtext, unpack(params))
						mod:SendChat("!" .. k.Name .. " " .. cmdtext)
					end
				end
			end))
		end
		mod:AddDefinition(k.Name, k.Category, tree)
	end
end)

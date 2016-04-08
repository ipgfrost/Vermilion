--[[
 Copyright 2015-16 Ned Hyett

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

local MODULE = MODULE
MODULE.Name = "Reserved Slots"
MODULE.ID = "reserved_slots"
MODULE.Description = "Allows staff to reserve slots on the server to make sure they can always get on."
MODULE.Author = "Ned"
MODULE.Permissions = {
  "modify_reserved_slots"
}
MODULE.NetworkStrings = {
  "AddSlot",
  "RemoveSlot",
  "GetSlotList"
}

function MODULE:InitServer()

  function sendSlotList(vplayer)
    local tab = {}

    for i,k in pairs(MODULE:GetData("slots", {}, true)) do
      table.insert(tab, k)
    end

    MODULE:NetStart("GetSlotList")
    net.WriteTable(tab)
    net.Send(vplayer)
  end

  self:NetHook("AddSlot", { "modify_reserved_slots" }, function(vplayer)
    table.insert(MODULE:GetData("slots", {}, true), { Name = net.ReadString(), SteamID = net.ReadString() })
    sendSlotList(vplayer)
  end)

  self:NetHook("RemoveSlot", { "modify_reserved_slots" }, function(vplayer)
    local steamid = net.ReadString()
    for i,k in pairs(MODULE:GetData("slots", {}, true)) do
      if(k.SteamID == steamid) then
        table.RemoveByValue(MODULE:GetData("slots", {}, true), k)
        break
      end
    end
    sendSlotList(vplayer)
  end)

  self:NetHook("GetSlotList", function(vplayer)
    sendSlotList(vplayer)
  end)

  self:AddHook("CheckPassword", function(steamID64, ipAddress, svPassword, clPassword, name)
    for i,k in pairs(MODULE:GetData("slots", {}, true)) do
      if(k.SteamID == util.SteamIDFrom64(steamID64)) then
        return
      end
    end
    local numPlayers = 0
    for i,k in pairs(player.GetAll()) do
      local has = false
      for i1,k1 in pairs(MODULE:GetData("slots", {}, true)) do
        if(k1.SteamID == k:SteamID()) then
          has = true
          break
        end
      end
      if(has) then continue end
      numPlayers = numPlayers + 1
    end
    if(numPlayers >= (game.MaxPlayers() - table.Count(MODULE:GetData("slots", {}, true)))) then
      return false, MODULE:TranslateStr("noslots")
    end
  end)

end

function MODULE:InitClient()

  self:NetHook("GetSlotList", function()
    local paneldata = Vermilion.Menu.Pages["reserved_slots"]
    local data = net.ReadTable()

    paneldata.SlotList:Clear()

    for i,k in pairs(data) do
      paneldata.SlotList:AddLine(k.Name, k.SteamID).SteamID = k.SteamID
    end

    paneldata.AddSlotPlayerList:Clear()
    for i,k in pairs(VToolkit.GetValidPlayers()) do
      local has = false
      for i1,k1 in pairs(paneldata.SlotList:GetLines()) do
        if(k1.SteamID == k:SteamID()) then
          has = true
          break
        end
      end
      if(has) then continue end
      paneldata.AddSlotPlayerList:AddLine(k:GetName()).SteamID = k:SteamID()
    end

  end)


  Vermilion.Menu:AddCategory("server", 2)

	self:AddMenuPage({
			ID = "reserved_slots",
			Name = Vermilion:TranslateStr("menu:reserved_slots"),
			Order = 6.5,
			Category = "server",
			Size = { 785, 540 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("modify_reserved_slots")
			end,
			Builder = function(panel, paneldata)
				local slots = VToolkit:CreateList({
					cols = MODULE:TranslateTable({ "list:name", "list:steamid" })
				})
				slots:SetPos(10, 30)
				slots:SetSize(765, 460)
				slots:SetParent(panel)

				slots.Columns[2]:SetFixedWidth(200)

				paneldata.SlotList = slots

				local listingsLabel = VToolkit:CreateHeaderLabel(slots, MODULE:TranslateStr("list:title"))
				listingsLabel:SetParent(panel)

				local removeSlot = VToolkit:CreateButton(MODULE:TranslateStr("remove"), function()
					if(table.Count(slots:GetSelected()) == 0) then return end
          for i,k in pairs(slots:GetSelected()) do
            MODULE:NetStart("RemoveSlot")
            net.WriteString(k.SteamID)
            net.SendToServer()
          end
				end)
				removeSlot:SetPos(670, 500)
				removeSlot:SetSize(105, 30)
				removeSlot:SetParent(panel)
				removeSlot:SetDisabled(true)
        paneldata.RemoveSlot = removeSlot


				function slots:OnRowSelected(index, line)
					local enabled = self:GetSelected()[1] == nil
					removeSlot:SetDisabled(enabled)
				end


				local addSlotPanel = VToolkit:CreateRightDrawer(panel, 0, true)
				paneldata.AddSlotPanel = addSlotPanel

        local addSlotPlayerList = VToolkit:CreateList({
  				cols = {
  					MODULE:TranslateStr("name")
  				}
  			})
  			addSlotPlayerList:SetPos(10, 40)
  			addSlotPlayerList:SetSize(240, panel:GetTall() - 50)
  			addSlotPlayerList:SetParent(addSlotPanel)
  			paneldata.AddSlotPlayerList = addSlotPlayerList

  			VToolkit:CreateSearchBox(addSlotPlayerList)

  			local addSlotPlayerHeader = VToolkit:CreateHeaderLabel(addSlotPlayerList, MODULE:TranslateStr("activeplayers"))
  			addSlotPlayerHeader:SetParent(addSlotPanel)

  			local addSlotFinalBtn = VToolkit:CreateButton(MODULE:TranslateStr("new:add"), function()
  				addSlotPanel:Close()
  				MODULE:NetStart("AddSlot")
          net.WriteString(addSlotPlayerList:GetSelected()[1]:GetValue(1))
  				net.WriteString(addSlotPlayerList:GetSelected()[1].SteamID)
  				net.SendToServer()
  			end)
  			addSlotFinalBtn:SetTall(30)
  			addSlotFinalBtn:SetPos(addSlotPanel:GetWide() - 185, (addSlotPanel:GetTall() - addSlotFinalBtn:GetTall()) / 2)
  			addSlotFinalBtn:SetWide(addSlotPanel:GetWide() - addSlotFinalBtn:GetX() - 15)
  			addSlotFinalBtn:SetParent(addSlotPanel)

        function addSlotPlayerList:OnRowSelected()
          addSlotFinalBtn:SetDisabled(table.Count(addSlotPlayerList:GetSelected()) == 0)
        end

				local addSlotButton = VToolkit:CreateButton(MODULE:TranslateStr("new"), function()
					addSlotPanel:Open()
				end)
				addSlotButton:SetPos(10, 500)
				addSlotButton:SetSize(105, 30)
				addSlotButton:SetParent(panel)


				addSlotPanel:MoveToFront()
			end,
			OnOpen = function(panel, paneldata)
				paneldata.AddSlotPanel:Close()
        paneldata.RemoveSlot:SetDisabled(true)

        paneldata.AddSlotPlayerList:Clear()
  			for i,k in pairs(VToolkit.GetValidPlayers()) do
          local has = false
          for i1,k1 in pairs(paneldata.SlotList:GetLines()) do
            if(k1.SteamID == k:SteamID()) then
              has = true
              break
            end
          end
          if(has) then continue end
  				paneldata.AddSlotPlayerList:AddLine(k:GetName()).SteamID = k:SteamID()
  			end

        MODULE:NetCommand("GetSlotList")
			end
		})
end

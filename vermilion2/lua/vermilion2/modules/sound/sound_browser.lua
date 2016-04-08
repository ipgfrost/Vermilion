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

local MODULE = Vermilion:GetModule("sound")

if(CLIENT) then

	function MODULE:BuildSoundSearchPanel()
		local panel = vgui.Create("DPanel")
		panel:SetSize(600, 400)

		return panel
	end

	function MODULE:SearchTest()
		local panel = VToolkit:CreateFrame({
			size = { 600, 600 },
			pos = { (ScrW() - 600) / 2, (ScrH() - 600) / 2 },
			title = ""
		})

		local viewPanel = self:BuildSoundSearchPanel()
		viewPanel:SetParent(panel)

		viewPanel:SetPos(0, 30)

		panel:MakePopup()
		panel:DoModal()
		panel:SetAutoDelete(true)
	end

end

--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
]]

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Derma Interface - ServerSide"
EXTENSION.ID = "dermainterfaceserver"
EXTENSION.Description = "Gives Vermilion a Derma interface"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.Tabs = {}

function EXTENSION:InitServer()
	util.AddNetworkString("Vermilion_TabRequest")
	util.AddNetworkString("Vermilion_TabResponse")
	
	net.Receive("Vermilion_TabRequest", function(len, vplayer)
		net.Start("Vermilion_TabResponse")
		local allowedTabs = {
			"extension_control",
			"ban_control",
			"rank_control"
		}
		net.WriteTable(allowedTabs)
		net.Send(vplayer)
	end)
	
	function Vermilion:AddInterfaceTab( tabName, permission )
		table.insert(EXTENSION.Tabs, { tabName, permission })
	end
end

Vermilion:RegisterExtension(EXTENSION)
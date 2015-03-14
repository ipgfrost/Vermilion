--[[
	This file will never be loaded by Vermilion and is here to serve as a reference file for all the possible properties that Vermilion
	will be looking for in a module file.
]]--

--[[
	MODULE is defined by Vermilion before loading the file. It is in the global scope.

	It will only be defined by Vermilion in your init.lua file. It will be nil outside
	of the init.lua file where you must define it as a local variable yourself.
]]--

MODULE.Name = "Base" -- human readable name
MODULE.ID = "base" -- machine unique id (usually the same as the module folder)
MODULE.Description = "Something" -- a short description of the module (or a witty placeholder)
MODULE.Author = "Ned" -- your name / online nickname
MODULE.Permissions = { -- a list of permissions that Vermilion should load. Note that you cannot dynamically add and remove permissions.
	"your_permission_name_here",
	"my_new_permission"
}
MODULE.NetworkStrings = { -- list of message names to send to and from the server, only has to be unique inside the module
	"MyNetworkString" 
}


function MODULE:InitServer()
	
end

function MODULE:InitClient()

end

Vermilion:RegisterModule(MODULE)

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

local EXTENSION = Vermilion:GetExtension("sound")

Vermilion:AddChatCommand("base", function(sender, text)
	if(Vermilion:HasPermissionError(sender, "use_vox_announcer")) then
		Vermilion:Vox("all your base are beyond to us", player.GetAll())
	end
end)

function Vermilion:Vox(str, tplayer)
	local tstr = {}
	if(istable(str)) then tstr = str else tstr = string.Explode(" ", str) end
	local ttime = 0
	for i,k in pairs(tstr) do
		local dur = SoundDuration("vox/" .. k .. ".wav") + 0.05
		timer.Simple(ttime, function()
			Vermilion:PlaySound(tplayer, "vox/" .. k .. ".wav")
		end)
		ttime = ttime + dur
	end
end

function Vermilion:VoxTime(str)
	local tstr = {}
	if(istable(str)) then tstr = str else tstr = string.Explode(" ", str) end
	local ttime = 0
	table.insert(tstr, "")
	for i,k in pairs(tstr) do
		ttime = ttime + SoundDuration("vox/" .. k .. ".wav") + 0.05
	end
	return ttime
end

Vermilion:AddChatCommand("vox", function(sender, text)
	if(Vermilion:HasPermissionError(sender, "use_vox_announcer")) then
		Vermilion:Vox(text, player.GetAll())
	end
end, "<words to speak>")

local voxcache = {}

Vermilion:AddChatPredictor("vox", function(pos, current)
	if(table.Count(voxcache) == 0) then
		local a,b = file.Find("sound/vox/*.wav", "GAME")
		for i,k in pairs(a) do
			if(string.StartWith(k, "_")) then continue end
			table.insert(voxcache, string.StripExtension(k))
		end
	end
	if(string.len(current) < 1) then return end
	local tab = {}
	for i,k in pairs(voxcache) do
		if(string.StartWith(string.lower(k), string.lower(current))) then
			table.insert(tab, k)
		end
	end
	return tab
end)

local words = {"one ", "two ", "three ", "four ", "five ", "six ", "seven ", "eight ", "nine "}
local levels = {"thousand ", "million ", "billion ", "trillion ", "quadrillion ", "quintillion ", "sextillion ", "septillion ", "octillion ", [0] = ""}
local iwords = {"ten ", "twenty ", "thirty ", "fourty ", "fifty ", "sixty ", "seventy ", "eighty ", "ninety "}
local twords = {"eleven ", "twelve ", "thirteen ", "fourteen ", "fifteen ", "sixteen ", "seventeen ", "eighteen ", "nineteen "}
 
local function digits(n)
  local i, ret = -1
  return function()
	i, ret = i + 1, n % 10
	if n > 0 then
	  n = math.floor(n / 10)
	  return i, ret
	end
  end
end
 
local level = false
local function getname(pos, dig) --stateful, but effective.
  level = level or pos % 3 == 0
  if(dig == 0) then return "" end
  local name = (pos % 3 == 1 and iwords[dig] or words[dig]) .. (pos % 3 == 2 and "hundred and " or "")
  if(level) then name, level = name .. levels[math.floor(pos / 3)], false end
  return name
end

local function getNum(num)
	local val, vword = num + 0, ""
	 
	for i, v in digits(val) do
	  vword = getname(i, v) .. vword
	end
	 
	for i, v in ipairs(words) do
	  --vword = vword:gsub("ty " .. v, "ty " .. v)
	  vword = vword:gsub("ten " .. v, twords[i])
	end
	 
	if #vword == 0 then return "zero" else return vword end
end
Vermilion:AddChatCommand("voxcount", function(sender, text)
	if(Vermilion:HasPermissionError(sender, "use_vox_announcer")) then
		local voxtime = 0
		for val=0,tonumber(text[1]),1 do
			timer.Simple(voxtime, function()
				print(tostring(tonumber(text[1]) - val) .. " " .. getNum(tonumber(text[1]) - val))
				Vermilion:Vox(string.Trim(getNum(tonumber(text[1]) - val)), player.GetAll())
			end)
			voxtime = voxtime + Vermilion:VoxTime(getNum(tonumber(text[1]) - val))
		end
	end
end, "<number to count down from>")
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

function Vermilion:SendNotify(vplayer, text, duration, notifyType)
	if(vplayer == nil or text == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayer) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
	end
	if(duration == nil) then
		duration = 5
	end
	if(notifyType == nil) then
		notifyType = NOTIFY_GENERIC
	end
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.Send(vplayer)
end

function Vermilion:BroadcastNotify(text, duration, notifyType)
	self:SendNotify(player.GetAll(), text, duration, notifyType)
end

function Vermilion:BroadcastNotifyOmit(vplayerToOmit, text, duration, notifyType)
	if(vplayerToOmit == nil or text == nil) then
		self.Log("Attempted to send notification with a nil parameter.")
		self.Log(tostring(vplayerToOmit) .. " === " .. text .. " === " .. tostring(duration) .. " === " .. tostring(notifyType))
		return
	end
	if(duration == nil) then
		duration = 5
	end
	if(notifyType == nil) then
		notifyType = NOTIFY_GENERIC
	end
	net.Start("Vermilion_Hint")
	net.WriteString("Vermilion: " .. tostring(text))
	net.WriteString(tostring(duration))
	net.WriteString(tostring(notifyType))
	net.SendOmit(vplayerToOmit)
end

function Vermilion:SendMessageBox(vplayer, text)
	if(vplayer == nil or text == nil) then
		self.Log("Attempted to send messagebox with a nil parameter!")
		self.Log(tostring(vplayer) .. " === " .. tostring(text))
	end
	net.Start("Vermilion_ErrorMsg")
	net.WriteString(text)
	net.Send(vplayer)
end
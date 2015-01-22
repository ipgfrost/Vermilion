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
Translated by BatyaMedic
http://steamcommunity.com/id/batyamedic
]]

--[[
	Note: Always save this file in "UTF-8 w/o BOM" when using NP++ or the characters will be lost!
]]

local lang = Vermilion:CreateLangBody("Russian")

lang.ButtonFontScale = 0.9 -- this is needed to make all the text fit onto most of the buttons because it would be a pain to re-build all the GUIs to accommodate for this.

lang:Add("yes", "Да")
lang:Add("no", "Нет")
lang:Add("close", "Закрыть")

lang:Add("dayslabel", "Дни:")
lang:Add("hourslabel", "Часы:")
lang:Add("minuteslabel", "Минуты:")
lang:Add("secondslabel", "Секунды:")


lang:Add("no_users", "Нет такого игрока.")
lang:Add("ambiguous_users", "Ambiguous results for search \"%s\". (Matched %s users).")
lang:Add("access_denied", "Доступ запрещен!")
lang:Add("under_construction", "В разработке!")
lang:Add("bad_syntax", "Неизвестный синтакс!")
lang:Add("not_number", "Это не число!")
lang:Add("not_bool", "Это не булево число!")
lang:Add("player_immune", "%s is immune to you.")
lang:Add("ban_self", "Ты не можешь забанить себя!")
lang:Add("kick_self", "Ты не можешь кикнуть себя!")
lang:Add("no_rank", "Такого ранга не существует!")


--[[

	//		Prints:Settings		\\

]]--


--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Главное")
lang:Add("category:server", "Настроки сервера")
lang:Add("category:ranks", "Ранги")
lang:Add("category:player", "Управление игроками")
lang:Add("category:limits", "Лимиты")



--[[

	//		Addon Validator		\\

]]--
lang:Add("addon_validator:title", "Аддоны мастерской")
lang:Add("addon_validator:windowtext", [[Vermilion обнаружил что у вас нет этих аддонов. 

Скачайте эти аддоны и вам будет легче заходить на сервер и у вас не будет ERROR`ов и эмо-текстур! 

Используйте этот лист!]])
lang:Add("addon_validator:open_workshop_page", "Открыть страницу мастерской")
lang:Add("addon_validator:open_workshop_page:g1", "Выберете хотя бы 1 аддон!")
lang:Add("addon_validator:dna", "Закрыть и не показывать")
lang:Add("addon_validator:dna:confirm", "Вы уверены?\nЭто срабатывает на каждом сервер на который вы заходите.\nЧтобы отменить это напишите \"vermilion_addonnag_do_not_ask 0\" в консоль!")


--[[

	//		Automatic Broadcast		\\

]]--
lang:Add("menu:autobroadcast", "Авто-Сообщение")
lang:Add("autobroadcast:list:text", "Текст")
lang:Add("autobroadcast:list:interval", "Интервал")
lang:Add("autobroadcast:list:title", "Обьявления")
lang:Add("autobroadcast:remove", "Удалить обьяв.")
lang:Add("autobroadcast:remove:g1", "Выберете хотя бы одно обьявление.")
lang:Add("autobroadcast:new", "Новое обьяв...")
lang:Add("autobroadcast:new:interval", "Сообщать каждый(ю):")
lang:Add("autobroadcast:new:add", "Добавить обьяв.")
lang:Add("autobroadcast:new:gz", "Интервал не может быть равный 0!")


--[[

	//		Battery Meter		\\

]]--
lang:Add("battery_meter:unplugged", "Компьютер отключен!")
lang:Add("battery_meter:pluggedin", "Компьютер подключен!")
lang:Add("battery_meter:low", "Батарея разряжена: %s%%!")
lang:Add("battery_meter:critical", "Критический статус батареи: %s%%!")
lang:Add("battery_meter:interface", "Уровень Заряда: %s%%")
lang:Add("battery_meter:cl_opt", "Включить Смотрителя заряда батареи")

--[[

	//		Toolgun Limiter		\\

]]--

lang:Add("limit_toolgun:cannot_use", "Вы не можете использовать этот режим тулгана!")

--[[

	//		Commands		\\

]]--
lang:Add("commands:list:text", "Поддельные сообщения")
lang:Add("commands:list:title", "Сообщения")
lang:Add("commands:remove", "Удалить сообщение")
lang:Add("commands:remove:g1", "Нужно выбрать хотя бы одно сообщение.")
lang:Add("commands:new", "Добавить сообщение")
lang:Add("commands:new:add", "Добавить сообщение")

Vermilion:RegisterLanguage(lang)
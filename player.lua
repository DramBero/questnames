local self = require("openmw.self")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require('openmw.util')
local async = require('openmw.async')
local ambient = require("openmw.ambient")
local vfs = require('openmw.vfs')

local playerqlist = {}
local element = nil
local questnames = require("scripts.SSQN.qnamelist")
local shadow = require("scripts.SSQN.iconlist")
local iconlist = { }
local vfsname = nil
for k, v in pairs(shadow) do
	vfsname = string.sub(v, 2, -1)
	iconlist[k:lower()] = vfsname
end


local function initQuestlist()
	print("Building existing player quest list")
	local quests = types.Player.quests(self)
	for _,v in pairs(quests) do
		print(v)
		local qid = v.id:lower()
       		if playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
--			print(qid, playerqlist[qid])
		end
	end
end

local function iconpicker(qIDString)
    --checks for full name of index first as requested, then falls back on finding prefix
    if (iconlist[qIDString] ~= nil) then
        return iconlist[qIDString:lower()]
    else
		local searchString = qIDString
		local j = 0 --Just to prevent a possible infinite loop
		repeat
			j = j + 1
			local loc = nil
			local i = 0
			repeat
				i = i - 1
				loc = string.find(searchString, "_", i)
			until (loc ~= nil) or (i == -string.len(searchString))
			if ( loc ~= nil ) then
				searchString = string.sub(searchString,1,loc)
				if (iconlist[searchString:lower()] ~= nil) then
					break
				else
					searchString = string.sub(searchString,1,loc - 1)
				end
			else
				searchString = ""
				break
			end
		until (iconlist[searchString:lower()] ~= nil) or (searchString == "") or (j == 10)
		
        if (iconlist[searchString:lower()] ~= nil) then
	        return iconlist[searchString:lower()]
        else
            return "Icons\\SSQN\\DEFAULT.dds" --Default in case no icon is found
        end
    end
end

local function removePopup()
	if element == nil then return end
	element:destroy()
	element = nil
end

local function displayPopup(questId)
	local qname = questnames[questId]
	if qname == nil then qname = questId end
	print("123")
	print(questId)
	local notificationImage = iconpicker(questId)
	print(notificationImage)
	if not vfs.fileExists(notificationImage) then notificationImage = "Icons\\SSQN\\DEFAULT.dds" end
	local notificationText = "Quest Started:"
	if playerqlist[questId] then notificationText = "Quest Finished:" end

element = ui.create {
	layer = 'Notification',
		--** if you want a notification box with a solid background
		--** replace boxTransparentThick with boxSolidThick in line below
	template = I.MWUI.templates.boxTransparentThick,
	type = ui.TYPE.Container,
	props = {
		--** For position of message box on screen, change numbers in the relativePosition line below
		--** ( [0/0.5/1 = left/center/right], [0/0.5/1 = top/center/bottom] ) 
	relativePosition = util.vector2(0.5, 0.1),
	anchor = util.vector2(0.5, 0.1),
	},
	content = ui.content {
		--** Size of notification box 480 x 72. Change numbers in the line below.
	{ type = ui.TYPE.Widget, props = { size = util.vector2(480, 72) },

	content = ui.content {

	{ type = ui.TYPE.Image,
            props = {
			--** Position of icon inside notification box.
			--** ( [0/0.5/1 = left/center/right], [0/0.5/1 = top/center/bottom] ) 
    		relativePosition = util.vector2(0.02, 0.5),
    		anchor = util.vector2(0.02, 0.5),
			--** Size of Icon 48 x 48. Change values in line below.
                size = util.vector2(48, 48),
		resource = ui.texture { path = notificationImage },
		},
	},

	{ template = I.MWUI.templates.textNormal,
	    type = ui.TYPE.Text,
            props = {
	    relativePosition = util.vector2(0.55, 0.2),
	    anchor = util.vector2(0.5, 0.2),
	    text = notificationText,
	    textSize = 16,
		},
	},

	{ template = I.MWUI.templates.textHeader,
	type = ui.TYPE.Text,
            props = {
    relativePosition = util.vector2(0.55, 0.8),
    anchor = util.vector2(0.5, 0.8),
	text = qname,
    textSize = 16,
		},
	},

	},

	},
	},
}
	print(notificationImage)
		--** Line below sets the popup box to stay onscreen for 5 seconds
	async:newUnsavableSimulationTimer(5, function() removePopup() end)
		--** Location of sound file to play
	ambient.playSoundFile("Sound\\SSQN\\quest_update.wav")
end

local function getQuestchange(quests)
	for _,v in pairs(quests) do
		local qid = v.id:lower()
       		if playerqlist[qid] ~= nil then
			if v.finished and not playerqlist[qid] then
				playerqlist[qid] = true
				return qid
			end
		end
		if playerqlist[qid] == nil then
			playerqlist[qid] = v.finished
			if questnames[qid] ~= "skip" then return qid end
		end
	end
	return nil
end

local function journalHandler()
	if element ~= nil then return end
	local questId = getQuestchange(types.Player.quests(self))
	if questId ~= nil then
		displayPopup(questId)
--		print(questId, types.Player.quests(self).stage)
	end
end

time.runRepeatedly(function()
	journalHandler()
end, 1 * time.second)


return {
	engineHandlers = {
		onInit = initQuestlist,
		onLoad = initQuestlist
}
}
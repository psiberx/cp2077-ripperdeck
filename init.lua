--[[
RipperDeck
- Manage cyberware without visiting ripperdoc
- Dispose unwanted cyberware
- Extends Hub menu
- Multi-language support

Copyright (c) 2021 psiberx
]]--

loadfile('meta') {
	mod = 'RipperDeck',
	version = '0.9.5',
	framework = '1.14.0'
}

local Cron = require('Cron')
--local ModUI = require('ModUI')
local NativeUI = require('NativeUI')
local RipperDoc = require('RipperDoc')
local GameLanguage = require('GameLanguage')

registerForEvent('onInit', function()
	GameLanguage.Init()

	RipperDoc.Init()

	--ModUI.Init()
	--ModUI.OnReadyCheck(RipperDoc.IsReady)
	--ModUI.OnListItems(RipperDoc.GetItems)
	--ModUI.OnActivate(RipperDoc.Activate)

	NativeUI.Init()
	NativeUI.OnReadyCheck(RipperDoc.IsReady)
	NativeUI.OnActivate(RipperDoc.Activate)
end)

registerForEvent('onShutdown', function()
	NativeUI.Dispose()
	RipperDoc.Dispose()
end)

registerForEvent('onUpdate', function(delta)
	Cron.Update(delta)
end)

--registerForEvent('onOverlayOpen', function()
--	ModUI.Show()
--end)
--
--registerForEvent('onOverlayClose', function()
--	ModUI.Hide()
--end)
--
--registerForEvent('onDraw', function()
--	ModUI.Draw()
--end)
--
--registerHotkey('ManageCyberware', 'Manage Cyberware', function()
--	RipperDoc.Activate()
--end)

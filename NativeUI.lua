local GameLocale = require('GameLocale')

local NativeUI = {}

local logic = {
	isReady = function() return false end,
	isActive = function() return false end,
	activateDeck = function() end,
}

local hubMenuController
local hubMenuButton
local hubMenuButtonData
local hubMenuButtonId = 101
local hubMenuInventoryId = EnumInt(HubMenuItems.Inventory)
local hubMenuRequest
local vendorMenuController

local function modifyHubMenu()
	local inventoryPanel = hubMenuController.panelInventory.widget
	local journalPanel = hubMenuController.panelJournal.widget

	hubMenuButton = journalPanel:GetWidgetByIndex(2)
	hubMenuButtonData = hubMenuButton.logicController.menuData

	local ripperButtonData = MenuData.new()
	ripperButtonData.label = GameLocale.Text('RipperDeck')
	ripperButtonData.icon = 'ico_shards_hub'
	ripperButtonData.fullscreenName = 'MenuScenario_Vendor'
	ripperButtonData.identifier = hubMenuButtonId
	ripperButtonData.parentIdentifier = hubMenuInventoryId

	if hubMenuButtonData.disabled then
		hubMenuButton:SetOpacity(1)
		hubMenuButton.logicController.icon.widget:SetOpacity(1)
		hubMenuButton.logicController.label.widget:SetOpacity(1)
	end

	hubMenuButton.logicController:Init(ripperButtonData)
	hubMenuButton:Reparent(inventoryPanel)
end

local function restoreHubMenu()
	if hubMenuButton then
		if hubMenuButton.logicController then
			local journalPanel = hubMenuController.panelJournal.widget

			hubMenuButton.logicController:Init(hubMenuButtonData)
			hubMenuButton:Reparent(journalPanel, 2)
		end

		hubMenuButton = nil
		hubMenuButtonData = nil
	end
end

function NativeUI.Initialize()
	Observe('MenuHubLogicController', 'OnInitialize', function(self)
		hubMenuController = self
	end)

	Observe('MenuHubLogicController', 'OnUninitialize', function()
		hubMenuController = nil
	end)

	Observe('MenuItemController', 'OnItemHoverOver', function(self)
		if hubMenuController and self.hoverPanel.widget then
			if self.menuData.identifier == hubMenuInventoryId and self.hoverPanel.widget:GetNumChildren() < 3 then
				modifyHubMenu()
			end
		end
	end)

	Observe('MenuItemController', 'OnHoverPanelOver', function(self)
		if hubMenuController and self.hoverPanel.widget then
			if self.menuData.identifier == hubMenuInventoryId and self.hoverPanel.widget:GetNumChildren() < 3 then
				modifyHubMenu()
			end
		end
	end)

	Observe('MenuItemController', 'OnMenuItemDelayedUpdate', function(self)
		if hubMenuController then
			if self.menuData.identifier == hubMenuInventoryId and not self.itemHovered and not self.panelHovered then
				restoreHubMenu()
			end
		end
	end)

	Observe('MenuHubGameController', 'OnOpenMenuRequest', function(_, request)
		if hubMenuController then
			if request.eventData.identifier == hubMenuButtonId then
				logic.activateDeck()
			elseif vendorMenuController then
				hubMenuRequest = request
				vendorMenuController:CloseVendor()
			end
		end
	end)

	Observe('VendorHubMenuGameController', 'SetupTopBar', function(self)
		if hubMenuController then
			vendorMenuController = self
			self:GetRootWidget():SetVisible(false)
		end
	end)

	Observe('RipperDocGameController', 'OnInitialize', function(self)
		if hubMenuController then
			self:GetRootWidget():GetWidget('wrapper'):GetWidget('moneyContainer'):SetVisible(false)
		end
	end)

	Override('MenuScenario_Vendor', 'OnVendorClose', function(self)
		if hubMenuController then
			self:GetMenusState():CloseAllMenus()

			if hubMenuRequest then
				local initData = HubMenuInitData.new()
				initData.menuName = hubMenuRequest.eventData.fullscreenName
				hubMenuRequest = nil

				self:SwitchToScenario('MenuScenario_HubMenu', initData)
			else
				self:SwitchToScenario('MenuScenario_HubMenu')
			end

			vendorMenuController = nil
		else
			self:GotoIdleState()
		end
	end)

	Observe('MenuScenario_HubMenu', 'OnLeaveScenario', function()
		if vendorMenuController then
			vendorMenuController:CloseVendor()
			vendorMenuController = nil
		end
	end)
end

function NativeUI.Dispose()
	if hubMenuController and hubMenuController.panelInventory.widget then
		if hubMenuController.panelInventory.widget:GetNumChildren() >= 3 then
			restoreHubMenu()
		end
	end
end

function NativeUI.OnReadyCheck(callback)
	if type(callback) == 'function' then
		logic.isReady = callback
	end
end

function NativeUI.OnActiveCheck(callback)
	if type(callback) == 'function' then
		logic.isActive = callback
	end
end

function NativeUI.OnActivate(callback)
	if type(callback) == 'function' then
		logic.activateDeck = callback
	end
end

return NativeUI
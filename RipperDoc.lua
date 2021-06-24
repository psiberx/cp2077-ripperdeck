local Cron = require('Cron')
local GameLanguage = require('GameLanguage')

local RipperDoc = {}

local isGameplay = false
local isVendorMenu = false
local isRipperDeck = false
local ripperDocList = {}
local ripperDocEntity
local ripperDocEntityId
local ripperDocVendorId
local ripperDocController
local dropAction = 'activate_secondary'
local unequipAction = 'unequip_item'

local function isActiveRipperDoc(vendorRecord)
	return vendorRecord:VendorType()
		and vendorRecord:VendorType():Type() == gamedataVendorType.RipperDoc
		and vendorRecord:GetItemStockCount() > 0
		and vendorRecord:LocalizedName() ~= ''
		and Game.GetLocalizedText(vendorRecord:LocalizedName()) ~= 'DELETE'
end

function RipperDoc.Init()
	dropAction = CName.new(dropAction)
	unequipAction = CName.new(unequipAction)

	if not TweakDB:GetRecord('_CWA_.Character.RemoteRipperDoc') then
		TweakDB:CloneRecord('_CWA_.Character.RemoteRipperDoc', 'Character.Victor_Vector')
	end

	if not TweakDB:GetRecord('_CWA_.Vendors.OwnCyberware') then
		TweakDB:CloneRecord('_CWA_.Vendors.OwnCyberware', 'Vendors.wat_lch_ripperdoc_01')
	end

	TweakDB:SetFlatNoUpdate('_CWA_.Vendors.OwnCyberware.itemStock', {})
	TweakDB:SetFlatNoUpdate('_CWA_.Vendors.OwnCyberware.inGameTimeToRestock', 1)
	TweakDB:SetFlatNoUpdate('_CWA_.Vendors.OwnCyberware.localizedName', '')
	TweakDB:Update('_CWA_.Vendors.OwnCyberware')

	for _, vendorRecord in ipairs(TweakDB:GetRecords('gamedataVendor_Record')) do
		if isActiveRipperDoc(vendorRecord) then
			local ripperDocItem = {
				name = Game.GetLocalizedText(vendorRecord:LocalizedName()),
				desc = Game.GetLocalizedText(vendorRecord:LocalizedDescription()),
				vendorId = vendorRecord:GetID()
			}

			ripperDocItem.filter = ripperDocItem.name:upper()

			table.insert(ripperDocList, ripperDocItem)
		end
	end

	table.sort(ripperDocList, function(a, b)
		return a.name < b.name
	end)

	Observe('MenuScenario_Vendor', 'OnEnterScenario', function()
		if isRipperDeck and ripperDocEntity then
			Game.GetPreventionSpawnSystem():RequestDespawn(ripperDocEntityId)
			ripperDocEntity = nil
		end

		isVendorMenu = true
	end)

	Observe('MenuScenario_Vendor', 'OnLeaveScenario', function(self)
		-- Nested RTTI call workaround
		Cron.After(0.001, function()
			if self:IsA('MenuScenario_Vendor') then
				isVendorMenu = false

				if ripperDocEntityId then
					local marketSystem = MarketSystem.GetInstance()

					for i, vendor in ipairs(marketSystem.vendors) do
						if vendor.vendorObject then
							if vendor.vendorObject:GetEntityID().hash == ripperDocEntityId.hash then
								local vendors = marketSystem.vendors
								table.remove(vendors, i)
								marketSystem.vendors = vendors
								break
							end
						end
					end

					marketSystem:ClearVendorHashMap()
					ripperDocEntityId = nil
				end

				if ripperDocEntity then
					Cron.After(0.1, function()
						Game.GetPreventionSpawnSystem():RequestDespawn(ripperDocEntity:GetEntityID())
						ripperDocEntity = nil
					end)
				end
			end
		end)
	end)

	Observe('RipperDocGameController', 'OnInitialize', function(self)
		ripperDocController = self
	end)

	Observe('RipperDocGameController', 'OnUninitialize', function()
		ripperDocController = nil
	end)

	Observe('RipperDocGameController', 'Init', function(self)
		if isRipperDeck and self.ripperId then
			self.ripperId:SetName(GameLanguage.Get('RipperDeck'))
			self.ripperId:GetRootWidget():GetWidget('fluff'):GetWidget('money'):SetVisible(false)
			self.radioGroupRef.widget:SetVisible(false)
			--self.ripperdocIdRoot.widget:SetVisible(false)
		end
	end)

	Observe('RipperDocGameController', 'SetInventoryItemButtonHintsHoverOver', function(self, displayingData)
		if isRipperDeck then
			self.buttonHintsController:RemoveButtonHint(dropAction)
			self.buttonHintsController:RemoveButtonHint(unequipAction)

			if not displayingData.Empty and not displayingData.IsVendorItem then
				if displayingData.IsEquipped then
					self.buttonHintsController:AddButtonHint(unequipAction, 'UI-UserActions-Unequip')
				elseif self.mode == RipperdocModes.Item then
					self.buttonHintsController:AddButtonHint(dropAction, 'UI-ScriptExports-Drop0')
				end
			end
		end
	end)

	Observe('RipperDocGameController', 'SetInventoryItemButtonHintsHoverOut', function(self)
		if isRipperDeck then
			self.buttonHintsController:RemoveButtonHint(dropAction)
			self.buttonHintsController:RemoveButtonHint(unequipAction)
		end
	end)

	Observe('InventoryItemDisplayController', 'OnDisplayClicked', function(self, event)
		if isRipperDeck then
			if event:IsAction(unequipAction) and self.itemData.IsEquipped then
				Game.GetScriptableSystemsContainer():Get('EquipmentSystem'):GetPlayerData(Game.GetPlayer()):UnequipItem(self.itemData.ID)

				ripperDocController:PlaySound('ItemAdditional', 'OnUnequip')
				ripperDocController.buttonHintsController:RemoveButtonHint(unequipAction)

				if ripperDocController.mode == RipperdocModes.Item then
					ripperDocController.equiped = false
				else
					ripperDocController.InventoryManager:MarkToRebuild()
					ripperDocController:UpdateCWAreaGrid(ripperDocController.selectedArea)
				end

			elseif event:IsAction(dropAction) and not self.itemData.IsEquipped and ripperDocController.mode == RipperdocModes.Item then
				Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), self.itemData.ID, 1)

				ripperDocController:PlaySound('Item', 'OnDrop')
				ripperDocController.InventoryManager:MarkToRebuild()
				ripperDocController:SetInventoryCWList()
			end
		end
	end)

	-- Fix a game bug where the cyberware slot is not selected when opening the menu for the first time
	Observe('CyberwareInventoryMiniGrid', 'OnSlotSpawned', function(_, _, userData)
		if ripperDocController then
			if userData.index == ripperDocController.selectedPreviewSlot then
				Cron.After(0.001, function()
					if ripperDocController then
						ripperDocController:SelectSlot(ripperDocController.selectedPreviewSlot)
					end
				end)
			end
		end
	end)

	local player = Game.GetPlayer()
	local isPreGame = Game.GetSystemRequestsHandler():IsPreGame()
	isGameplay = player and player:IsAttached() and not isPreGame

	Observe('QuestTrackerGameController', 'OnInitialize', function()
		isGameplay = true
	end)

	Observe('QuestTrackerGameController', 'OnUninitialize', function()
		isGameplay = Game.GetPlayer() ~= nil
	end)
end

function RipperDoc.Activate(ripperDoc)
	if isVendorMenu or ripperDocEntityId then
		return
	end

	if ripperDoc then
		ripperDocVendorId = ripperDoc.vendorId
		isRipperDeck = false
	else
		ripperDocVendorId = TweakDBID.new('_CWA_.Vendors.OwnCyberware')
		isRipperDeck = true
	end

	TweakDB:SetFlat('_CWA_.Character.RemoteRipperDoc.vendorID', ripperDocVendorId)

	local player = Game.GetPlayer()
	local forwardVector = player:GetWorldForward()
	local offsetVector = Vector3.new(forwardVector.x * -1, forwardVector.y * -1, -10)
	local spawnTransform = player:GetWorldTransform()
	local spawnPosition = spawnTransform.Position:ToVector4()
	spawnTransform:SetPosition(Vector4.new(
		spawnPosition.x + offsetVector.x,
		spawnPosition.y + offsetVector.y,
		spawnPosition.z + offsetVector.z,
		spawnPosition.w
	))

	ripperDocEntityId = Game.GetPreventionSpawnSystem():RequestSpawn(TweakDBID.new('_CWA_.Character.RemoteRipperDoc'), -1, spawnTransform)
	--ripperDocEntityId = WorldFunctionalTests.SpawnEntity('base\\quest\\tertiary_characters\\victor_vector.ent', spawnTransform, '')

	Cron.Every(0.01, function(timer)
		ripperDocEntity = Game.FindEntityByID(ripperDocEntityId)

		if not ripperDocEntity then
			return
		end

		local vendorData = VendorData.new()
		vendorData.entityID = ripperDocEntityId
		vendorData.isActive = true

		local vendorPanelData = VendorPanelData.new()
		vendorPanelData.data = vendorData

		Game.GetUISystem():RequestVendorMenu(vendorPanelData, 'MenuScenario_Vendor')

		timer:Halt()
	end)
end

function RipperDoc.Dispose()
	if ripperDocEntityId then
		Game.GetPreventionSpawnSystem():RequestDespawn(ripperDocEntityId)
		--WorldFunctionalTests.DespawnEntity(Game.FindEntityByID(ripperDocEntityId))
	end
end

function RipperDoc.IsReady()
	return isGameplay and not isVendorMenu and not ripperDocEntityId
end

function RipperDoc.isActive()
	return isVendorMenu or ripperDocEntityId
end

function RipperDoc.GetItems(filter)
	if not filter or filter == '' then
		return ripperDocList
	end

	local filterEsc = filter:gsub('([^%w])', '%%%1'):upper()
	local filterRe = filterEsc:gsub('%s+', '.* ') .. '.*'
	local filtered = {}

	for _, item in ipairs(ripperDocList) do
		if item.filter:find(filterRe) then
			table.insert(filtered, item)
		end
	end

	return filtered
end

return RipperDoc

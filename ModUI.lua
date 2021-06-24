local ModUI = {}

local style = {}

local state = {
	initialized = false,
	open = false,
	filter = '',
	selected = nil,
}

local logic = {
	isReady = function() return false end,
	getItemList = function() return {} end,
	activateItem = function() end,
}

function ModUI.Init()
	style.scale = ImGui.GetFontSize() / 13

	style.windowWidth = 340 * style.scale
	style.windowHeight = 0 -- Auto height
	style.windowPaddingX = 8 * style.scale
	style.windowPaddingY = 8 * style.scale

	style.framePaddingX = 3 * style.scale
	style.framePaddingY = 3 * style.scale
	style.innerSpacingX = 4 * style.scale
	style.innerSpacingY = 4 * style.scale
	style.itemSpacingX = 8 * style.scale
	style.itemSpacingY = 4 * style.scale

	style.listBoxHeight = (7 * 17 - 2) * style.scale
	style.buttonHeight = 20 * style.scale

	local screenWidth, screenHeight = GetDisplayResolution()

	style.windowX = (screenWidth - style.windowWidth) / 2
	style.windowY = (screenHeight - style.windowHeight) / 2

	state.initialized = true
end

function ModUI.OnReadyCheck(callback)
	if type(callback) == 'function' then
		logic.isReady = callback
	end
end

function ModUI.OnListItems(callback)
	if type(callback) == 'function' then
		logic.getItemList = callback
	end
end

function ModUI.OnActivate(callback)
	if type(callback) == 'function' then
		logic.activateItem = callback
	end
end

function ModUI.Show()
	state.open = true
end

function ModUI.Hide()
	state.open = false
end

function ModUI.Draw()
	if not state.open or not state.initialized then
		return
	end

	ImGui.SetNextWindowPos(style.windowX, style.windowY, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(style.windowWidth + style.windowPaddingX * 2 - 1, style.windowHeight)

	ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, style.windowPaddingX, style.windowPaddingY)
	ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, style.framePaddingX, style.framePaddingY)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, style.innerSpacingX, style.innerSpacingY)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, style.itemSpacingX, style.itemSpacingY)

	if ImGui.Begin('Cyberware Anywhere', ImGuiWindowFlags.NoResize + ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.NoScrollWithMouse) then
		if logic.isReady() then
			ImGui.SetNextItemWidth(style.windowWidth)
			ImGui.PushStyleColor(ImGuiCol.TextDisabled, 0xffaaaaaa)
			state.filter = ImGui.InputTextWithHint('##ItemFilter', 'Search...', state.filter, 100)
			ImGui.PopStyleColor()

			ImGui.Spacing()

			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			if ImGui.BeginListBox('##ItemList', style.windowWidth, style.listBoxHeight) then
				for i, item in ipairs(logic.getItemList(state.filter)) do
					if ImGui.Selectable(item.name .. '##Item' .. i, (state.selected == item)) then
						state.selected = item
					end
				end
				ImGui.EndListBox()
			end
			ImGui.PopStyleVar(2)
			ImGui.PopStyleColor()

			ImGui.Separator()

			if state.selected then
				--ImGui.Spacing()
				--ImGui.Separator()
				--ImGui.Spacing()
				--
				--ImGui.PushStyleColor(ImGuiCol.Text, 0xfffefd01)
				--ImGui.Text(state.selected.name)
				--ImGui.PopStyleColor()
				--
				--ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
				--ImGui.TextWrapped(state.selected.desc)
				--ImGui.PopStyleColor()
				--
				--ImGui.Spacing()

				if ImGui.Button('Access RipperDoc', style.windowWidth, style.buttonHeight) then
					logic.activateItem(state.selected)
				end
			else
				ImGui.PushStyleColor(ImGuiCol.Button, 0xaa777777)
				ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xaa777777)
				ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xaa777777)
				ImGui.Button('Select RipperDoc...', style.windowWidth, style.buttonHeight)
				ImGui.PopStyleColor(3)
			end

			ImGui.Separator()

			if ImGui.Button('Manage Cyberware', style.windowWidth, style.buttonHeight) then
				logic.activateItem()
			end
		else
			ImGui.Spacing()
			ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
			ImGui.TextWrapped('To access RipperDocs menu:')
			ImGui.TextWrapped('- Load into the game')
			ImGui.TextWrapped('- Close any current vendor menu')
			ImGui.PopStyleColor()
			ImGui.Spacing()
		end
	else
		state.selected = nil
	end

	ImGui.End()

	ImGui.PopStyleVar(4)
end

return ModUI
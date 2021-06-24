local GameLanguage = {}

local languageGroupPath = '/language'
local languageVarName = 'OnScreen'
local languageDefault = 'en-us'

local language = languageDefault
local languageDir = 'data/lang'
local languageData = {}

local function getOnScreenLanguage()
	return Game.NameToString(Game.GetSettingsSystem():GetVar(languageGroupPath, languageVarName):GetValue())
end

local function loadTranslationData()
	local chunk = loadfile(languageDir .. '/' .. language)

	if chunk then
		languageData = chunk()
		return
	end

	chunk = loadfile(languageDir .. '/' .. languageDefault)

	if chunk then
		languageData = chunk()
		return
	end

	languageData = {}
end

local function getTranslation(key)
	return languageData[key] ~= nil and languageData[key] or key
end

function GameLanguage.Init(dataDir)
	languageGroupPath = CName.new(languageGroupPath)
	languageVarName = CName.new(languageVarName)

	if dataDir then
		languageDir = dataDir
	end

	language = getOnScreenLanguage()
	loadTranslationData()

	Observe('SettingsMainGameController', 'OnVarModified', function(_, groupPath, varName, _, reason)
		if groupPath == languageGroupPath and varName == languageVarName and reason == InGameConfigChangeReason.Accepted then
			language = getOnScreenLanguage()
			loadTranslationData()
		end
	end)
end

function GameLanguage.Get(key)
	return getTranslation(key)
end

function GameLanguage.GetTranslator()
	return getTranslation
end

function GameLanguage.GetLanguage()
	return language
end

return GameLanguage
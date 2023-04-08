local bar_template = mainForm:GetChildChecked("Bar", false)
local spell_template = mainForm:GetChildChecked("IconSpell", false)

local active_casts = {}
local counter = 0

local active_buffs = {}
local active_mobs = {}
local reaction_binds = {}
local alt_reaction_binds = {}
local Config = {}
local DefaultConfig = {
	clickable = false
}

local TRACKED_UNITS = {}

local function destroyCastBar(widget)
	widget:Show(false)

	for k, v in pairs(active_casts) do
		if (v:GetName() == widget:GetName()) then
			table.remove(active_casts, k)
			v:DestroyWidget()
		end
	end

	for k, v in pairs(active_casts) do
		local tempPos = bar_template:GetPlacementPlain()
		tempPos.posY = tempPos.posY + 42 * (k - 1)
		WtSetPlace(v, tempPos)
		v:Show(k <= (tonumber(UI.get("Bars", "MaxBars")) or 6))
	end
end

local function onBuffRemovedDetected(removed_buff)
	local widget = active_buffs[removed_buff.buffId]
	if (not widget) then return end
	destroyCastBar(widget)

	active_buffs[removed_buff.buffId] = nil
	local params = {}
	params.objectId = removed_buff.objectId
	common.UnRegisterEventHandler(onBuffRemovedDetected, "EVENT_OBJECT_BUFF_REMOVED", params)
end

local function addCast(castInfo)
	local bar
	bar = mainForm:CreateWidgetByDesc(bar_template:GetWidgetDesc())
	counter = counter + 1
	bar:SetName("CastBar" .. tostring(counter))
	bar:Show(#active_casts < (tonumber(UI.get("Bars", "MaxBars")) or 6))

	table.insert(active_casts, bar)

	local castBar
	castBar = mainForm:CreateWidgetByDesc(mainForm:GetChildChecked("CastBar", false):GetWidgetDesc())
	castBar:Show(true)
	bar:AddChild(castBar)

	local tempPos = bar_template:GetPlacementPlain()
	tempPos.posY = tempPos.posY + 42 * (#active_casts - 1)
	WtSetPlace(bar, tempPos)
	WtSetPlace(castBar,
		{ sizeX = tonumber(UI.get("Bars", "BarsWidth")) or 300, sizeY = tonumber(UI.get("Bars", "BarsHeight")) or 40 })

	if (castInfo.buffInfo) then
		active_buffs[castInfo.buffInfo.buffId] = bar
		local params = {}
		params.objectId = castInfo.buffInfo.objectId
		common.RegisterEventHandler(onBuffRemovedDetected, "EVENT_OBJECT_BUFF_REMOVED", params)

		reaction_binds["CastBar" .. tostring(counter)] = castInfo.buffInfo.objectId

		if (castInfo.target == FromWS(object.GetName(avatar.GetId()))) then
			castBar:SetBackgroundColor(UI.getGroupColor("MyBuffColor") or { r = 0.0, g = 0.8, b = 0.0, a = 0.5 })
		elseif (castInfo.alt_id and object.IsFriend(castInfo.buffInfo.objectId) and object.IsEnemy(castInfo.alt_id)) then
			castBar:SetBackgroundColor(UI.getGroupColor("EnemyBuffColor") or { r = 0.8, g = 0, b = 0, a = 0.5 })
		else
			castBar:SetBackgroundColor(UI.getGroupColor("OtherBuffColor") or { r = 0.0, g = 0.6, b = 0.6, a = 0.5 })
		end
		WtSetPlace(castBar, { alignX = 0, sizeX = tonumber(UI.get("Bars", "BarsWidth")) or 300 })
		local castBarPlacementEnd = castBar:GetPlacementPlain()
		castBarPlacementEnd.sizeX = 0
		castBar:PlayResizeEffect(castBar:GetPlacementPlain(), castBarPlacementEnd, castInfo.duration,
			EA_MONOTONOUS_INCREASE)

		if (not UI.get("Bars", "ShowBuffCaster")) then
			castInfo.target = ""
		elseif castInfo.alt_id then
			alt_reaction_binds["CastBar" .. tostring(counter)] = castInfo.alt_id
		end
	else
		if (castInfo.alt_id and castInfo.alt_id == avatar.GetId()) then
			castBar:SetBackgroundColor(UI.getGroupColor("MobCastAtMeColor") or { r = 0.8, g = 0, b = 0.0, a = 0.5 })
		else
			castBar:SetBackgroundColor(UI.getGroupColor("MobCastColor") or { r = 0.8, g = 0, b = 0.0, a = 0.5 })
		end
		WtSetPlace(castBar, { alignX = 0, sizeX = 0 })
		local castBarPlacementEnd = castBar:GetPlacementPlain()
		castBarPlacementEnd.sizeX = tonumber(UI.get("Bars", "BarsWidth")) or 300
		castBar:PlayResizeEffect(castBar:GetPlacementPlain(), castBarPlacementEnd, castInfo.duration,
			EA_MONOTONOUS_INCREASE)

		if (not UI.get("Bars", "ShowCastTarget")) then
			castInfo.target = ""
		elseif castInfo.alt_id then
			alt_reaction_binds["CastBar" .. tostring(counter)] = castInfo.alt_id
		end
	end

	if (castInfo.mob) then
		active_mobs[castInfo.mob] = bar
		reaction_binds["CastBar" .. tostring(counter)] = castInfo.mob
	end

	if (castInfo.customColor) then
		castBar:SetBackgroundColor(castInfo.customColor)
	end

	-- if (Settings.customColorsByName and Settings.customColorsByName[castInfo.name]) then
	-- 	castBar:SetBackgroundColor(Settings.customColorsByName[castInfo.name])
	-- end

	local spell
	spell = mainForm:CreateWidgetByDesc(spell_template:GetWidgetDesc())
	WtSetPlace(spell,
	{ sizeX = tonumber(UI.get("Bars", "BarsWidth")) or 300, sizeY = tonumber(UI.get("Bars", "BarsHeight")) or 40 })

	local iconSize = (tonumber(UI.get("Bars", "BarsHeight")) or 40) - 8

	if (castInfo.texture) then
		spell:SetBackgroundTexture(castInfo.texture)
	end

	bar:AddChild(spell)
	spell:Show(true)

	local castName = CreateWG("Label", "CastName", bar, true,
		{
			alignX = 0,
			sizeX = (tonumber(UI.get("Bars", "BarsWidth")) or 300) - (tonumber(UI.get("Bars", "BarsHeight")) or 40),
			posX = iconSize + 6,
			highPosX = 0,
			alignY = 0,
			sizeY = 20,
			posY = 2,
			highPosY = 0
		})
	castName:SetFormat(userMods.ToWString(
		"<html><body alignx='left' aligny='bottom' fontsize='16' outline='1' shadow='1'><rs class='class'><r name='name'/></rs></body></html>"))
	castName:SetVal("name", castInfo.name)
	castName:SetClassVal("class", "ColorWhite")

	local offsetTargetText = 0
	if (castInfo.target) then offsetTargetText = 115 end

	local castUnit = CreateWG("Label", "CastUnit", bar, true,
		{
			alignX = 0,
			sizeX = (tonumber(UI.get("Bars", "BarsWidth")) or 300) - iconSize - offsetTargetText,
			posX = iconSize + 6,
			highPosX = 0,
			alignY = 0,
			sizeY = 20,
			posY = 18,
			highPosY = 0
		})
	castUnit:SetFormat(userMods.ToWString(
		"<html><body alignx='left' aligny='bottom' fontsize='13' outline='1' shadow='1'><rs class='class'><r name='name'/></rs></body></html>"))
	castUnit:SetVal("name", castInfo.unit)
	castUnit:SetClassVal("class", "ColorWhite")

	local castTarget = CreateWG("Label", "CastTarget", bar, true,
		{ alignX = 1, sizeX = 120, posX = 0, highPosX = 2, alignY = 0, sizeY = 20, posY = 18, highPosY = 0 })
	castTarget:SetFormat(userMods.ToWString(
		"<html><body alignx='right' aligny='bottom' fontsize='12' outline='1' shadow='1'><rs class='class'><r name='name'/></rs></body></html>"))
	castTarget:SetVal("name", castInfo.target)
	castTarget:SetClassVal("class", "RelicCursed")

	bar:AddChild(castName)
	bar:AddChild(castUnit)
	bar:AddChild(castTarget)

	WtSetPlace(spell,
		{ alignX = 0, posX = 4, highPosX = 0, alignY = 0, posY = 4, highPosY = 0, sizeX = iconSize, sizeY = iconSize })

	bar:SetTransparentInput(not Config.clickable)
	castBar:SetTransparentInput(true)
	spell:SetTransparentInput(true)
end

local function onPlayEffectFinished(e)
	if e.wtOwner then
		if e.wtOwner:GetName() ~= "CastBar" then return end

		destroyCastBar(e.wtOwner:GetParent())
	end
end

local function onCast(p)
	if (p.id and p.duration and p.name) then
		local CastsMode = UI.get("CastsSettings", "Mode")
		local castItem = UI.getItem("CastsSettings", FromWS(p.name))
		if (CastsMode == "HideOnly") then
			if (castItem and castItem.enabled) then return end
		elseif (CastsMode == "ShowOnly") then
			if (not castItem or not castItem.enabled) then return end
		end

		local UnitsMode = UI.get("UnitsSettings", "Mode")
		local unitItem = UI.getItem("UnitsSettings", FromWS(object.GetName(p.id)))
		if (UnitsMode == "HideOnly") then
			if (unitItem and unitItem.enabled) then return end
		elseif (UnitsMode == "ShowOnly") then
			if (not unitItem or not unitItem.enabled) then return end
		end

		local targetId = unit.GetTarget(p.id)
		local primaryTarget = unit.GetPrimaryTarget(p.id)

		local castInfo = {
			["name"] = FromWS(p.name),
			["unit"] = FromWS(object.GetName(p.id)),
			["duration"] = p.duration - p.progress,
			["mob"] = p.id
		}

		if (targetId and targetId ~= p.id) then
			castInfo.target = FromWS(object.GetName(targetId))
			castInfo.alt_id = targetId
		end

		if (p.spellId) then
			castInfo.texture = spellLib.GetIcon(p.spellId)
			UI.registerTexture(FromWS(p.name), {
				spellId = p.spellId,
			})
		end
		addCast(castInfo)
	end
end

local function onBuff(p)
	local show = false
	local info = object.GetBuffInfo(p.buffId)
	if (not info) then return end

	local maskName = FromWS(p.buffName)
	if (Settings.descriptionMasks) then
		for k, v in pairs(Settings.descriptionMasks) do
			if (userMods.FromWString(common.ExtractWStringFromValuedText(info.description)) == k) then
				maskName = v
				goto endloop
			end
		end
		::endloop::
	end

	local mode = UI.get("BuffsSettings", "Mode")
	if (mode ~= "ShowOnly") then return end
	local buffSettings = UI.getItem("BuffsSettings", maskName)
	if (buffSettings == nil or not buffSettings.enabled) then return end

	if (buffSettings["enemyMob"]) then
		show = show or (object.IsEnemy(p.objectId) and not unit.IsPlayer(p.objectId))
	end
	if (buffSettings["enemyPlayer"]) then
		show = show or (not object.IsFriend(p.objectId) and not unit.IsPlayer(p.objectId))
	end
	if (buffSettings["friendMob"]) then
		show = show or (object.IsFriend(p.objectId) and not unit.IsPlayer(p.objectId))
	end
	if (buffSettings["friendPlayer"]) then
		show = show or (object.IsFriend(p.objectId) and unit.IsPlayer(p.objectId))
	end
	if (buffSettings["self"]) then
		show = show or (p.objectId == avatar.GetId())
	end
	if (buffSettings["raidgroup"]) then
		local tmp = false
		if raid.IsExist() then
			if raid.IsPlayerInAvatarsRaid(object.GetName(p.objectId)) then tmp = true end
		elseif group.IsCreatureInGroup(avatar.GetId()) then
			if group.IsCreatureInGroup(p.objectId) then tmp = true end
		elseif p.objectId == avatar.GetId() then
			tmp = true
		end

		show = show or tmp
	end

	if (show) then
		local buffObject = p.objectId
		local buffId = p.buffId

		if (object.IsUnit(buffObject)) then
			local info = object.GetBuffInfo(buffId)

			if (info) then
				local caster = ""
				if (info.producer.casterId) then caster = FromWS(object.GetName(info.producer.casterId)) end

				local castInfo = {
					["name"] = FromWS(info.name),
					["unit"] = FromWS(object.GetName(buffObject)),
					["target"] = caster,
					["duration"] = info.remainingMs,
					["buffInfo"] = p,
					["texture"] = info.texture,
					["alt_id"] = info.producer.casterId
				}

				UI.registerTexture(FromWS(info.name), {
					buffId = info.buffId,
				})
				addCast(castInfo)
			end
		end
	end
end

local function onUnitDeadChanged(p)
	-- test
	-- if (object.IsDead(p.unitId)) then
	-- 	for k, v in pairs(TRACKED_UNITS) do
	-- 		if (v == p.unitId) then
	-- 			table.remove(TRACKED_UNITS, k)
	-- 		end
	-- 	end
	-- end
end

local function getUnits()
	local units = avatar.GetUnitList()
	for _, id in ipairs(units) do
		table.insert(TRACKED_UNITS, id)
		common.RegisterEventHandler(onBuff, "EVENT_OBJECT_BUFF_ADDED", {
			objectId = id
		})
	end
end

local function onUnitsChanged(p)
	local spawned = p.spawned
	local despawned = p.despawned

	for i = 0, len(spawned) - 1, 1 do
		local id = spawned[i]
		if (id ~= nil) then
			-- Log("spawned " .. tostring(id) .. " " .. FromWS(object.GetName(id)))
			table.insert(TRACKED_UNITS, id)
			common.RegisterEventHandler(onBuff, "EVENT_OBJECT_BUFF_ADDED", {
				objectId = id
			})
		end
	end

	for i = 0, len(despawned) - 1, 1 do
		local id = despawned[i]
		if (id ~= nil) then
			-- Log("despawned " .. tostring(id) .. " " .. FromWS(object.GetName(id)))
			common.UnRegisterEventHandler(onBuff, "EVENT_OBJECT_BUFF_ADDED", {
				objectId = id
			})
			for k, v in pairs(TRACKED_UNITS) do
				if (v == id) then
					table.remove(TRACKED_UNITS, k)
				end
			end
		end
	end
end

local function onCastFinish(p)
	local widget = active_mobs[p.id]
	if (not widget) then return end

	destroyCastBar(widget)
	active_mobs[p.id.buffId] = nil
end

local function onSlash(p)
	local m = userMods.FromWString(p.text)
	local split_string = {}
	for w in m:gmatch("%S+") do table.insert(split_string, w) end

	if (split_string[1]:lower() == '/casttest' and split_string[2]) then
		local castInfo = {
			["name"] = "Some spell",
			["unit"] = "Some unit",
			["target"] = "Some target",
			["duration"] = string.match(split_string[2], '%d[%d.,]*') * 1000,
		}
		addCast(castInfo)
	end

	if (split_string[1]:lower() == '/casttest2' and split_string[2]) then
		local castInfo = {
			["name"] = "Some spell",
			["unit"] = "Some unit",
			["target"] = "Some target",
			["duration"] = string.match(split_string[2], '%d[%d.,]*') * 1000,
			["customColor"] = { r = 0.0, g = 0.6, b = 0.6, a = 0.5 }
		}
		addCast(castInfo)
	end

	if (split_string[1]:lower() == '/casts.chore') then
		UI.chore()
	end
end

function ToggleDnd()
	if (bar_template:IsVisibleEx()) then
		DnD.Enable(bar_template, false)
		bar_template:Show(false)
		bar_template:SetTransparentInput(true)
		spell_template:SetTransparentInput(true)

		for k, v in pairs(active_casts) do
			local tempPos = bar_template:GetPlacementPlain()
			tempPos.posY = tempPos.posY + 42 * (k - 1)
			WtSetPlace(v, tempPos)
			v:Show(k <= (tonumber(UI.get("Bars", "MaxBars")) or 6))
		end

		Log("Drag & Drop - Off.")
	else
		DnD.Enable(bar_template, true)
		bar_template:Show(true)
		bar_template:SetTransparentInput(false)
		spell_template:SetTransparentInput(false)

		for k, v in pairs(active_casts) do
			v:Show(false)
		end

		Log("Drag & Drop - On.")
	end
end

local function onButton(reaction)
	local id = reaction_binds[reaction.widget:GetName()]

	if (id and object.IsUnit(id)) then
		avatar.SelectTarget(id)
	end
end

local function onButtonAlt(reaction)
	if (not UI.get("Interaction", "EnableRightClick")) then return end
	local id = alt_reaction_binds[reaction.widget:GetName()]

	if (id and object.IsUnit(id)) then
		avatar.SelectTarget(id)
	end
end

local function onCfgLeft()
	if DnD:IsDragging() then
		return
	end

	UI.toggle()
end

local function onCfgRight()
	if DnD:IsDragging() then
		return
	end

	ToggleDnd()
end

local function isClickableCallback(value)
	Config.clickable = value
	userMods.SetGlobalConfigSection("CastPlatesConfig", Config)

	for k, v in pairs(active_casts) do
		v:SetTransparentInput(not Config.clickable)
	end

	if (Config.clickable) then
		Log("Clickable - On.")
	else
		Log("Clickable - Off.")
	end
end

local function addBuffCallback(widget, settings, editline)
	editline:SetFocus(false)
	local text = editline:GetString()

	UI.groupPush("BuffsSettings",
		UI.createItemSetting(text, {
			iconName = text,
			checkboxes = {
				{
					name = "self",
					label = "CB_self",
					default = false
				},
				{
					name = "enemyPlayer",
					label = "CB_enemyPlayer",
					default = false
				},
				{
					name = "enemyMob",
					label = "CB_enemyMob",
					default = false
				},
				{
					name = "raidgroup",
					label = "CB_raidgroup",
					default = false
				},
				{
					name = "friendlyPlayer",
					label = "CB_friendlyPlayer",
					default = false
				},
				{
					name = "friendlyMob",
					label = "CB_friendlyMob",
					default = false
				}
			}
		}, true), true
	)

	UI.render()
end

local function addCastCallback(widget, settings, editline)
	editline:SetFocus(false)
	local text = editline:GetString()

	UI.groupPush("CastsSettings",
		UI.createItemSetting(text, {
			iconName = text,
			checkboxes = {}
		}, true), true
	)

	UI.render()
end

local function addUnitCallback(widget, settings, editline)
	editline:SetFocus(false)
	local text = editline:GetString()

	UI.groupPush("UnitsSettings",
		UI.createItemSetting(text, {
			iconName = "UNIT",
			checkboxes = {}
		}, true), true
	)

	UI.render()
end

local function addRecommendedBuffs()
	UI.groupPush("BuffsSettings",
		UI.createItemSetting("*Длительный контроль*", {
			iconName = "*Длительный контроль*",
			checkboxes = {
				{
					name = "self",
					label = "CB_self",
					default = false
				},
				{
					name = "enemyPlayer",
					label = "CB_enemyPlayer",
					default = true
				},
				{
					name = "enemyMob",
					label = "CB_enemyMob",
					default = true
				},
				{
					name = "raidgroup",
					label = "CB_raidgroup",
					default = true
				},
				{
					name = "friendlyPlayer",
					label = "CB_friendlyPlayer",
					default = false
				},
				{
					name = "friendlyMob",
					label = "CB_friendlyMob",
					default = false
				}
			}
		}, true), true
	)

	UI.render()
end

local function addRecommendedUnits()
	local recomendedUnits = {
		"Демонический маяк",
		"Песчаный червь",
		"Охотник Свалки",
		"Охотница Свалки"
	}

	for _, unit in pairs(recomendedUnits) do
		UI.groupPush("UnitsSettings",
			UI.createItemSetting(unit, {
				iconName = "UNIT",
				checkboxes = {}
			}, true), true
		)
	end

	UI.render()
end

local function setupUI()
	LANG = common.GetLocalization() or "rus"
	UI.init("ImportantCasts")

	UI.addGroup("Bars", {
		UI.createInput("MaxBars", {
			maxChars = 2,
			filter = "_INT"
		}, '6'),
		UI.createInput("BarsWidth", {
			maxChars = 4,
			filter = "_INT"
		}, '300'),
		UI.createList("BarsHeight", range(32, 64, 4), 3, false),
		UI.createCheckBox("ShowBuffCaster", true),
		UI.createCheckBox("ShowCastTarget", true),
	})

	UI.addGroup("Interaction", {
		UI.withCallback(UI.createCheckBox("IsClickable", false), isClickableCallback),
		UI.createCheckBox("EnableRightClick", true),
	})

	UI.createColorGroup("MyBuffColor", {
		r = 0,
		g = 204,
		b = 0,
		a = 50,
	})

	UI.createColorGroup("EnemyBuffColor", {
		r = 204,
		g = 0,
		b = 0,
		a = 50,
	})

	UI.createColorGroup("OtherBuffColor", {
		r = 0,
		g = 153,
		b = 153,
		a = 50,
	})

	UI.createColorGroup("MobCastColor", {
		r = 204,
		g = 0,
		b = 0,
		a = 50,
	})


	UI.createColorGroup("MobCastAtMeColor", {
		r = 255,
		g = 255,
		b = 255,
		a = 50,
	})

	UI.addGroup("BuffsSettings", {
		UI.createList("Mode", {
			"Disable",
			"ShowOnly",
		}, 2, true),
		UI.withCustomClass(UI.createListLabel("Mode", {
			"BuffsModeDisableInfo",
			"BuffsModeShowOnlyInfo",
		}), "tip_white"),
		UI.withCondition(UI.withCustomClass(
			UI.createButton("AddRecommended", {
				width = 90,
				states = {
					"ButtonAdd",
				},
				callback = addRecommendedBuffs
			}, 1),
			"tip_white"
		), "Mode", "ShowOnly"),
		UI.createButtonInput("AddBuff", {
			width = 90,
			states = {
				"ButtonAdd",
			},
			callback = addBuffCallback
		}, 1),
	})

	UI.addGroup("CastsSettings", {
		UI.createList("Mode", {
			"HideOnly",
			"ShowOnly",
		}, 1, true),
		UI.withCustomClass(UI.createListLabel("Mode", {
			"CastsModeHideOnlyInfo",
			"CastsModeShowOnlyInfo",
		}), "tip_white"),
		UI.createButtonInput("AddCast", {
			width = 90,
			states = {
				"ButtonAdd",
			},
			callback = addCastCallback
		}, 1),
	})

	UI.addGroup("UnitsSettings", {
		UI.createList("Mode", {
			"HideOnly",
			"ShowOnly",
		}, 1, true),
		UI.withCustomClass(UI.createListLabel("Mode", {
			"UnitsModeHideOnlyInfo",
			"UnitsModeShowOnlyInfo",
		}), "tip_white"),
		UI.withCondition(UI.withCustomClass(
			UI.createButton("AddRecommended", {
				width = 90,
				states = {
					"ButtonAdd",
				},
				callback = addRecommendedUnits
			}, 1),
			"tip_white"
		), "Mode", "HideOnly"),
		UI.createButtonInput("AddUnit", {
			width = 90,
			states = {
				"ButtonAdd",
			},
			callback = addUnitCallback
		}, 1),
	})

	UI.setTabs({
		{
			label = "Common",
			buttons = {
				left = { "Restore" },
				right = { "Accept" }
			},
			groups = {
				"Bars",
				"Interaction"
			}
		},
		{
			label = "Buffs",
			buttons = {
				left = { "Restore" },
				right = { "Accept" }
			},
			groups = {
				"BuffsSettings"
			}
		},
		{
			label = "Casts",
			buttons = {
				left = { "Restore" },
				right = { "Accept" }
			},
			groups = {
				"CastsSettings"
			}
		},
		{
			label = "Units",
			buttons = {
				left = { "Restore" },
				right = { "Accept" }
			},
			groups = {
				"UnitsSettings"
			}
		},
		{
			label = "Colors",
			buttons = {
				left = { "Restore" },
				right = { "Accept" }
			},
			groups = {
				"MyBuffColor",
				"EnemyBuffColor",
				"OtherBuffColor",
				"MobCastColor",
				"MobCastAtMeColor",
			}
		}
	}, "Common")

	UI.loadUserSettings()
	UI.render()
end

function Init()
	LOGGER.Init()

	Config = userMods.GetGlobalConfigSection("CastPlatesConfig") or DefaultConfig

	common.RegisterEventHandler(onPlayEffectFinished, 'EVENT_EFFECT_FINISHED')
	common.RegisterEventHandler(onSlash, 'EVENT_UNKNOWN_SLASH_COMMAND')
	-- common.RegisterEventHandler(onBuff, 'EVENT_OBJECT_BUFF_ADDED')
	-- common.RegisterEventHandler(onBuffsChanged, 'EVENT_OBJECT_BUFFS_CHANGED')
	common.RegisterEventHandler(onUnitsChanged, 'EVENT_UNITS_CHANGED')
	common.RegisterEventHandler(onUnitDeadChanged, 'EVENT_UNIT_DEAD_CHANGED')




	-- common.RegisterEventHandler(onBuffProgressAdded, 'EVENT_OBJECT_BUFF_PROGRESS_ADDED')
	-- common.RegisterEventHandler(onBuffProgressChanged, 'EVENT_OBJECT_BUFF_PROGRESS_CHANGED')
	-- common.RegisterEventHandler(onBuffProgressRemoved, 'EVENT_OBJECT_BUFF_PROGRESS_REMOVED')

	common.RegisterEventHandler(onCast, 'EVENT_MOB_ACTION_PROGRESS_START')
	common.RegisterEventHandler(onCastFinish, "EVENT_MOB_ACTION_PROGRESS_FREEZE")
	common.RegisterEventHandler(onCastFinish, "EVENT_MOB_ACTION_PROGRESS_FINISH")
	common.RegisterReactionHandler(onButton, "OnBarClick")
	common.RegisterReactionHandler(onButtonAlt, "OnBarAltClick")
	common.RegisterReactionHandler(onCfgLeft, "ConfigLeftClick")
	common.RegisterReactionHandler(onCfgRight, "ConfigRightClick")

	bar_template:AddChild(spell_template)
	spell_template:Show(true)
	bar_template:SetTransparentInput(true)
	spell_template:SetTransparentInput(true)

	local iconSize = (tonumber(UI.get("Bars", "BarsHeight")) or 40) - 8
	WtSetPlace(bar_template,
		{ sizeX = tonumber(UI.get("Bars", "BarsWidth")) or 300, sizeY = tonumber(UI.get("Bars", "BarsHeight")) or 40 })
	WtSetPlace(spell_template,
		{ alignX = 0, posX = 4, highPosX = 0, alignY = 0, posY = 4, highPosY = 0, sizeX = iconSize, sizeY = iconSize })

	DnD.Init(bar_template, spell_template, true)
	local cfgBtn = mainForm:GetChildChecked("ConfigButton", false)
	DnD.Init(cfgBtn, cfgBtn, true)
	DnD.Enable(cfgBtn, true)

	setupUI()
	getUnits()
end

if (avatar.IsExist()) then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end

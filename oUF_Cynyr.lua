--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

--some settings have been moved to here, for easier changing
local minalpha = 0
local maxalpha = 1
local castbaroffset = 80
local castbarheight = 16
local castbarbuttonsize = 21
local playertargetheight = 27
local playertargetwidth = 180
local petheight = 27
local petwidth = 130
local focustargettargetheight = 20
local focustargettargetwidth = playertargetwidth * .80
local debuffsize = 10
local hideparty=true



local max = math.max
local floor = math.floor

local minimalist = [=[Interface\AddOns\oUF_Cynyr\media\minimalist]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}
local FONT = 'GameFontHighlightSmallRight'

local colors = setmetatable({
	power = setmetatable({
		MANA = {0, 144/255, 1}
	}, {__index = oUF.colors.power}),
	reaction = setmetatable({
		[2] = {1, 0, 0},
		[4] = {1, 1, 0},
		[5] = {0, 1, 0}
	}, {__index = oUF.colors.reaction}),
	runes = setmetatable({
		[1] = {0.8, 0, 0},
		[3] = {0, 0.4, 0.7},
		[4] = {0.8, 0.8, 0.8}
	}, {__index = oUF.colors.runes})
}, {__index = oUF.colors})

local buffFilter = {
	[GetSpellInfo(62600)] = true,
	[GetSpellInfo(61336)] = true,
	[GetSpellInfo(52610)] = true,
	[GetSpellInfo(22842)] = true,
	[GetSpellInfo(22812)] = true,
	[GetSpellInfo(16870)] = true
}

local function menu(self)
	local drop = _G[string.gsub(self.unit, '(.)', string.upper, 1) .. 'FrameDropDown']
	if(drop) then
		ToggleDropDownMenu(1, nil, drop, 'cursor')
	end
end

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local function updatePower(self, event, unit, bar, minVal, maxVal)
	if(unit ~= 'target') then return end

	if(maxVal ~= 0) then
		self.Health:SetHeight(22)
		bar:Show()
	else
		self.Health:SetHeight(27)
		bar:Hide()
	end
end

local function castIcon(self, event, unit)
	local castbar = self.Castbar
	if(castbar.interrupt) then
		castbar.Button:SetBackdropColor(0, 0.9, 1)
	else
		castbar.Button:SetBackdropColor(0, 0, 0)
	end
end

local function castTime(self, duration)
	if(self.channeling) then
		self.Time:SetFormattedText('%.1f ', duration)
	elseif(self.casting) then
		self.Time:SetFormattedText('%.1f ', self.max - duration)
	end
end

local function updateTime(self, elapsed)
	self.remaining = max(self.remaining - elapsed, 0)
	self.time:SetText(self.remaining < 90 and floor(self.remaining) or '')
end

local function updateBuff(self, icons, unit, icon, index)
	local _, _, _, _, _, duration, expiration = UnitAura(unit, index, icon.filter)

	if(duration > 0 and expiration) then
		icon.remaining = expiration - GetTime()
		icon:SetScript('OnUpdate', updateTime)
	else
		icon:SetScript('OnUpdate', nil)
		icon.time:SetText()
	end
end

local function updateDebuff(self, icons, unit, icon, index)
	local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)

	if(icon.debuff) then
		if(not UnitIsFriend('player', unit) and icon.owner ~= 'player' and icon.owner ~= 'vehicle') then
			icon:SetBackdropColor(0, 0, 0)
			icon.icon:SetDesaturated(true)
		else
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			icon:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			icon.icon:SetDesaturated(false)
		end
	end
end

local function createAura(self, button, icons)
	icons.showDebuffType = true

	button.cd:SetReverse()
	button:SetBackdrop(backdrop)
	button:SetBackdropColor(0, 0, 0)
	button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	button.icon:SetDrawLayer('ARTWORK')
	button.overlay:SetTexture()

	if(self.unit == 'player') then
		icons.disableCooldown = true

		button.time = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
		button.time:SetPoint('TOPLEFT', button)
	end
end

local function customFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expiration, caster)
	if(buffFilter[name] and caster == 'player') then
		return true
	end
end

 --[[ Creates a RuneFrame
FRAME CreateRuneFrame(FRAME self)
]]
local CreateRuneFrame = function(self)
    local i
    local rf = CreateFrame('Frame', nil, self)
    rf:SetHeight(10)
    rf:SetWidth(33)

    for i = 1, 6 do
        rf[i] = CreateFrame('StatusBar', nil, rf)
        rf[i]:SetHeight(10)
        rf[i]:SetWidth(33)
        rf[i]:SetStatusBarTexture(minimalist, 'BORDER')
        rf[i]:SetBackdrop(backdrop)
        rf[i]:SetBackdropColor(0, 0, 0, 1)
        rf[i]:SetBackdropBorderColor(0, 0, 0, 0)
        rf[i].bg = rf[i]:CreateTexture(nil, 'BACKGROUND')
        rf[i].bg:SetAllPoints(rf[i])
        rf[i].bg:SetTexture(backdrop)
        rf[i].bg:SetVertexColor(0.3, 0.3, 0.3, 0.5)
        --[[lib.CreateBorder(rf[i], 10)
        for _, tex in ipairs(rf[i].borderTextures) do
            tex:SetParent(rf[i])
        end--]]
        if (i == 1) then
            rf[i]:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, -10)
        else
            rf[i]:SetPoint('LEFT', rf[i-1], 'RIGHT', 5, 0)
        end
        rf[i]:Show()
    end

    return rf
end

local function style(self, unit)
	self.colors = colors
	self.menu = menu

	self:RegisterForClicks('AnyUp')
	self:SetAttribute('type2', 'menu')

	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetPoint('TOPRIGHT')
	self.Health:SetPoint('TOPLEFT')
	self.Health:SetStatusBarTexture(minimalist)
	self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
	self.Health:SetHeight((unit == 'focus' or unit == 'targettarget') and 20 or 22)
	self.Health.frequentUpdates = true

	self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(0.3, 0.3, 0.3)

	local health = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
	health:SetPoint('RIGHT', self.Health, -2, -1)
	health.frequentUpdates = 0.25
	self:Tag(health, '[phealth][cpoints]')

	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetPoint('TOP', self, 0, 8)
	self.RaidIcon:SetHeight(16)
	self.RaidIcon:SetWidth(16)

	if(unit == 'focus' or unit == 'targettarget') then
		self:SetAttribute('initial-height', focustargettargetheight)
		self:SetAttribute('initial-width', focustargettargetwidth)

		--self.Debuffs = CreateFrame('Frame', nil, self)
		--self.Debuffs:SetHeight(20)
		--self.Debuffs:SetWidth(44)
		--self.Debuffs.num = 2
		--self.Debuffs.size = debuffsize
		--self.Debuffs.spacing = 4
		--self.PostCreateAuraIcon = createAura

		if(unit == 'focus') then
			--self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
			--self.Debuffs.onlyShowPlayer = true
			--self.Debuffs.initialAnchor = 'TOPLEFT'
		else
			--self.Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
			--self.Debuffs.initialAnchor = 'TOPRIGHT'
			--self.Debuffs['growth-x'] = 'LEFT'
		end
	else
		self.Power = CreateFrame('StatusBar', nil, self)
		self.Power:SetPoint('BOTTOMRIGHT')
		self.Power:SetPoint('BOTTOMLEFT')
		self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1)
		self.Power:SetStatusBarTexture(minimalist)
		self.Power.frequentUpdates = true

		self.Power.colorClass = true
		self.Power.colorTapping = true
		self.Power.colorDisconnected = true
		self.Power.colorReaction = unit ~= 'pet'
		self.Power.colorHappiness = unit == 'pet'
		self.Power.colorPower = unit == 'pet'

		self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
		self.Power.bg:SetAllPoints(self.Power)
		self.Power.bg:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
		self.Power.bg.multiplier = 0.3
	end

	if(unit == 'player' or unit == 'pet') then
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -10)
			self.Experience:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -10)
			self.Experience:SetHeight(11)
			self.Experience:SetStatusBarTexture(minimalist)
			self.Experience:SetStatusBarColor(0.15, 0.7, 0.1)
			self.Experience.Tooltip = true

			self.Experience.Rested = CreateFrame('StatusBar', nil, self)
			self.Experience.Rested:SetAllPoints(self.Experience)
			self.Experience.Rested:SetStatusBarTexture(minimalist)
			self.Experience.Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			self.Experience.Rested:SetBackdrop(backdrop)
			self.Experience.Rested:SetBackdropColor(0, 0, 0)

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
			self.Experience.Text:SetPoint('CENTER', self.Experience)

			self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.3, 0.3, 0.3)
		end

		local power = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		power:SetPoint('LEFT', self.Health, 2, -1)
		power.frequentUpdates = 0.1
		self:Tag(power, '[ppower][druidpower]')
	else
		local info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		info:SetPoint('LEFT', self.Health, 2, -1)
		info:SetPoint('RIGHT', health, 'LEFT')
		self:Tag(info, '[pname]|cff0090ff[rare]|r')
	end

	if(unit == 'pet') then
		self:SetAttribute('initial-height', petheight)
		self:SetAttribute('initial-width', petwidth)

		self.Auras = CreateFrame('Frame', nil, self)
		self.Auras:SetPoint('TOPRIGHT', self, 'TOPLEFT', -4, 0)
		self.Auras:SetHeight(4)
		self.Auras:SetWidth(256)
		self.Auras.size = 22
		self.Auras.spacing = 4
		self.Auras.initialAnchor = 'TOPRIGHT'
		self.Auras['growth-x'] = 'LEFT'
		self.PostCreateAuraIcon = createAura
	end

	if(unit == 'player' or unit == 'target') then
		self:SetAttribute('initial-height', playertargetheight)
		self:SetAttribute('initial-width', playertargetwidth)

		--self.Buffs = CreateFrame('Frame', nil, self)
		--self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 4, 0)
		--self.Buffs:SetHeight(44)
		--self.Buffs:SetWidth(236)
		--self.Buffs.num = 20
		--self.Buffs.size = debuffsize
		--self.Buffs.spacing = 4
		--self.Buffs.initialAnchor = 'TOPLEFT'
		--self.Buffs['growth-y'] = 'DOWN'
		--self.PostCreateAuraIcon = createAura

		self.Castbar = CreateFrame('StatusBar', nil, self)
		self.Castbar:SetWidth(playertargetwidth - 25)
		self.Castbar:SetHeight(castbarheight)
		self.Castbar:SetStatusBarTexture(minimalist)
		self.Castbar:SetStatusBarColor(0.25, 0.25, 0.35)
		self.Castbar:SetBackdrop(backdrop)
		self.Castbar:SetBackdropColor(0, 0, 0)

		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(0.3, 0.3, 0.3)

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Castbar.Text:SetPoint('LEFT', 2, 1)

		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
		self.Castbar.Time:SetPoint('RIGHT', -2, 1)
		self.Castbar.CustomTimeText = castTime

		self.Castbar.Button = CreateFrame('Frame', nil, self.Castbar)
		self.Castbar.Button:SetHeight(castbarbuttonsize)
		self.Castbar.Button:SetWidth(castbarbuttonsize)
		self.Castbar.Button:SetBackdrop(backdrop)
		self.Castbar.Button:SetBackdropColor(0, 0, 0)

		self.Castbar.Icon = self.Castbar.Button:CreateTexture(nil, 'ARTWORK')
		self.Castbar.Icon:SetAllPoints(self.Castbar.Button)
		self.Castbar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		if(unit == 'target') then
			self.PostCastStart = castIcon
			self.PostChannelStart = castIcon
			self.Castbar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, castbaroffset)
			self.Castbar.Button:SetPoint('BOTTOMLEFT', self.Castbar, 'BOTTOMRIGHT', 4, 0)
		else
			self.Castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, castbaroffset)
			self.Castbar.Button:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMLEFT', -4, 0)
		end

		self.PostUpdatePower = updatePower
	end

	if(unit == 'target') then
		--self.Debuffs = CreateFrame('Frame', nil, self)
		--self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -4)
		--self.Debuffs:SetHeight(20 * 0.97)
		--self.Debuffs:SetWidth(playertargetwidth)
		--self.Debuffs.num = 20
		--self.Debuffs.size = 20 * 0.97
		--self.Debuffs.spacing = 4
		--self.Debuffs.initialAnchor = 'TOPLEFT'
		--self.Debuffs['growth-y'] = 'DOWN'
		--self.PostCreateAuraIcon = createAura
		--self.PostUpdateAuraIcon = updateDebuff

		--self.CPoints = self:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		--self.CPoints:SetPoint('RIGHT', self, 'LEFT', -9, 0)
		--self.CPoints:SetTextColor(1, 1, 1)
		--self.CPoints:SetJustifyH('RIGHT')
		--self.CPoints.unit = PlayerFrame.unit
		--self:RegisterEvent('UNIT_COMBO_POINTS', updateCombo)
	end

	if(unit == 'player') then
		if(select(2, UnitClass('player')) == 'DEATHKNIGHT') then
            local runes  = CreateRuneFrame()
            runes:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -20)
			runes:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -20)

            self.Runes = runes
		end
        if(unit=="player" and IsAddOnLoaded("oUF_BarFader")) then
            self.BarFade = true
            self.BarFaderMinAlpha = minalpha
            self.BarFaderMaxAlpha = maxalpha
        end

		self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Leader:SetPoint('TOPLEFT', self, 0, 8)
		self.Leader:SetHeight(16)
		self.Leader:SetWidth(16)

		self.Assistant = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Assistant:SetPoint('TOPLEFT', self, 0, 8)
		self.Assistant:SetHeight(16)
		self.Assistant:SetWidth(16)

		local info = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
		info:SetPoint('CENTER', 0, -1)
		info.frequentUpdates = 0.25
		self:Tag(info, '[pthreat]|cffff0000[pvptime]|r')

		--self.PostUpdateAuraIcon = updateBuff
		--self.CustomAuraFilter = customFilter
	end

	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true
    self.MoveableFrames = true
end

local function hideBlizPartyFrames(self)
    local blizUI = PartyMemberBackground
    for i=1,4 do _G["PartyMemberFrame"..i]:SetParent( blizUI )
        _G["PartyMemberFrame"..i.."PetFrame"]:SetParent( blizUI )
    end
    blizUI:Hide(); 
end

oUF:RegisterStyle('Cynyr', style)
oUF:SetActiveStyle('Cynyr')

oUF:Spawn('player', "oUF_Cynyr_player"):SetPoint('CENTER', UIParent, -220, -250)
oUF:Spawn('target', "oUF_Cynyr_target"):SetPoint('CENTER', UIParent, 220, -250)
oUF:Spawn('targettarget', "oUF_Cynyr_targettarget"):SetPoint('BOTTOMRIGHT', oUF.units.target, 'TOPRIGHT', 0, 5)
oUF:Spawn('focus', "oUF_Cynyr_focus"):SetPoint('BOTTOMLEFT', oUF.units.player, 'TOPLEFT', 0, 5)
oUF:Spawn('pet', "oUF_Cynyr_pet"):SetPoint('RIGHT', oUF.units.player, 'LEFT', -25, 0)
if (hideparty) then
    hideBlizPartyFrames()
end


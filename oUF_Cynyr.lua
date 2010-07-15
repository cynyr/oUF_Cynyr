--[[

  This a modification of oUF_lily by Haste(Trond a Ekseth).
  http://www.wowinterface.com/downloads/info9995-oUF_Lily

--]]

--get the addon namespace
local addon, ns = ...

--get the config values
local cfg = ns.cfg

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", string.upper)
    
    --Set the unit to pet if we are in a vehicle.
	if(cunit == 'Vehicle') then
		cunit = 'Pet'
	end
    
    --Last three argument control the placement of the menu.
	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

oUF.Tags['lily:health'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(not UnitIsFriend('player', unit)) then
		return siValue(min)
	elseif(min ~= 0 and min ~= max) then
		return '-' .. siValue(max - min)
	else
		return max
	end
end
oUF.TagEvents['lily:health'] = oUF.TagEvents.missinghp

oUF.Tags['lily:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min)
end
oUF.TagEvents['lily:power'] = oUF.TagEvents.missingpp

local updateName = function(self, event, unit)
    --control the color of the name for unit reaction
	if(self.unit == unit) then
		local r, g, b, t
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			r, g, b = .6, .6, .6
		elseif(unit == 'pet') then
			t = self.colors.happiness[GetPetHappiness()]
		elseif(UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		else
			t = self.colors.reaction[UnitReaction(unit, "player")]
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(r) then
			self.Name:SetTextColor(r, g, b)
		end
	end
end

local PostUpdateHealth = function(Health, unit, min, max)
	if(UnitIsDead(unit)) then
		Health:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		Health:SetValue(0)
	end

	Health:SetStatusBarColor(.25, .25, .35)
	return updateName(Health:GetParent(), 'PostUpdateHealth', unit)
end

local PostCastStart = function(Castbar, unit, spell, spellrank)
	Castbar:GetParent().Name:SetText('×' .. spell)
end

local PostCastStop = function(Castbar, unit)
	local self = Castbar:GetParent()
	self.Name:SetText(UnitName(self.realUnit or unit))
end

local PostCastStopUpdate = function(self, event, unit)
	if(unit ~= self.unit) then return end
	return PostCastStop(self.Castbar, unit)
end

local PostCreateIcon = function(Auras, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"

	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local PostUpdateIcon
do
	local playerUnits = {
		player = true,
		pet = true,
		vehicle = true,
	}

	PostUpdateIcon = function(icons, unit, icon, index, offset, filter, isDebuff)
		local texture = icon.icon
		if(playerUnits[icon.owner]) then
			texture:SetDesaturated(false)
		else
			texture:SetDesaturated(true)
		end
	end
end

local PostUpdatePower = function(Power, unit, min, max)
	local Health = Power:GetParent().Health
    if (select(2, UnitClass('player')) == 'DEATHKNIGHT' and unit == "player") then
        height = cfg.height - 5
    else
        height = cfg.height
    end
    print("The height of health for unit:" .. unit .. " is: " .. height)
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		Power:SetValue(0)
		Health:SetHeight(height)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		Power:SetValue(0)
		Health:SetHeight(height)
	else
		Health:SetHeight(height-2)
	end
end

local RAID_TARGET_UPDATE = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

local Shared = function(self, unit)
    --Set up the menu type and placement.
	self.menu = menu

    if cfg.allow_frame_movement then
        self:SetMovable(true)
        self:SetUserPlaced(true)
        if not cfg.frames_locked then
            self:EnableMouse(true)
            self:RegisterForDrag("LeftButton","RightButton")
            self:SetScript("OnDragStart", function(self) if IsAltKeyDown() and IsShiftKeyDown() then self:StartMoving() end end)
            self:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        end
    else
        self:IsUserPlaced(false)
    end

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
    
    --create the healthbar
	local Health = CreateFrame("StatusBar", nil, self)
    --this needs to be a % of total height, so that it is easy to scale up and down.
    --leaving it as is for now. I'll need to update its height in player( DK() )
	--Health:SetHeight((cfg.height-2))
	Health:SetHeight(cfg.height)
	Health:SetStatusBarTexture(cfg.texture)
	Health:GetStatusBarTexture():SetHorizTile(false)

	Health.frequentUpdates = true

	Health:SetPoint"TOP"
	Health:SetPoint"LEFT"
	Health:SetPoint"RIGHT"

	self.Health = Health

	local HealthBackground = Health:CreateTexture(nil, "BORDER")
    --make the background match self
	HealthBackground:SetAllPoints(self)
	HealthBackground:SetTexture(0, 0, 0, .5)

	Health.bg = HealthBackground

	local HealthPoints = Health:CreateFontString(nil, "OVERLAY")
	HealthPoints:SetPoint("RIGHT", -2, -1)
	HealthPoints:SetFontObject(GameFontNormalSmall)
	HealthPoints:SetTextColor(1, 1, 1)
    --Guessing that this sets the health points string to
    --dead, offline, or health, whichever matches first.
	self:Tag(HealthPoints, '[dead][offline][lily:health]')

	Health.value = HealthPoints

    --power frame time.
	local Power = CreateFrame("StatusBar", nil, self)
    --again should be a % based height, Leaving alone for now.
	Power:SetHeight(2)
	Power:SetStatusBarTexture(cfg.texture)
	Power:GetStatusBarTexture():SetHorizTile(false)

	Power.frequentUpdates = true
	Power.colorTaPowering = true
	Power.colorHaPoweriness = true
	Power.colorClass = true
	Power.colorReaction = true

	Power:SetParent(self)
	Power:SetPoint"LEFT"
	Power:SetPoint"RIGHT"
	Power:SetPoint("TOP", Health, "BOTTOM")

	self.Power = Power

    --Power points text
	local PowerPoints = Power:CreateFontString(nil, "OVERLAY")
	PowerPoints:SetPoint("RIGHT", HealthPoints, "LEFT", 0, 0)
	PowerPoints:SetFontObject(GameFontNormalSmall)
	PowerPoints:SetTextColor(1, 1, 1)
	self:Tag(PowerPoints, '[lily:power< | ]')

	Power.value = PowerPoints

    --castbar time.
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(cfg.texture)
	Castbar:SetStatusBarColor(1, .25, .35, .5)
	--Make it the same size as the HP bar.
    Castbar:SetAllPoints(Health)
    --Make it overlay health. This could be an issue 
    --if something chaincasts
	Castbar:SetToplevel(true)
	Castbar:GetStatusBarTexture():SetHorizTile(false)

	self.Castbar = Castbar
    
    --Icon time
    --Leader icon
	local Leader = self:CreateTexture(nil, "OVERLAY")
	Leader:SetHeight(16)
	Leader:SetWidth(16)
    --set it above the Health bar, but lowered 5 px.
	Leader:SetPoint("BOTTOM", Health, "TOP", 0, -5)

	self.Leader = Leader

    --master looter icon
	local MasterLooter = self:CreateTexture(nil, 'OVERLAY')
	MasterLooter:SetHeight(16)
	MasterLooter:SetWidth(16)
    --set it to the right of Leader icon.
	MasterLooter:SetPoint('LEFT', Leader, 'RIGHT')

	self.MasterLooter = MasterLooter

    --Raid icon(the circle, square, etc)
	local RaidIcon = Health:CreateFontString(nil, "OVERLAY")
	RaidIcon:SetPoint("LEFT", 2, 4)
	RaidIcon:SetJustifyH"LEFT"
	RaidIcon:SetFontObject(GameFontNormalSmall)
	RaidIcon:SetTextColor(1, 1, 1)

	self.RIcon = RaidIcon
    --handle target switches.
	self:RegisterEvent("RAID_TARGET_UPDATE", RAID_TARGET_UPDATE)
	table.insert(self.__elements, RAID_TARGET_UPDATE)

    --Show the name on the frame.
	local name = Health:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", RaidIcon, "RIGHT", 0, -5)
	name:SetPoint("RIGHT", PowerPoints, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)

	self.Name = name
    
    --Set frame size. 
	self:SetAttribute('initial-height', cfg.height)
	self:SetAttribute('initial-width', cfg.width)
    
    --make sure the cast bar keeps up with target switchs.
	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

    
	Castbar.PostChannelStart = PostCastStart
	Castbar.PostCastStart = PostCastStart

	Castbar.PostCastStop = PostCastStop
	Castbar.PostChannelStop = PostCastStop

	Health.PostUpdate = PostUpdateHealth
	Power.PostUpdate = PostUpdatePower
end

--Unit specfic layout stuff.
local UnitSpecific = {
	pet = function(self)
        --Run the shared layout, and then the custom layout code.
		Shared(self)
		self:RegisterEvent("UNIT_HAPPINESS", updateName)
	end,

	target = function(self)
        --Run Shared layout then add custom stuff.
		Shared(self)
        
        --[[
        --Uncomment to show buffs/debuffs
		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "BOTTOMRIGHT"
		Buffs["growth-x"] = "LEFT"
		Buffs:SetPoint("RIGHT", self, "LEFT")

		Buffs:SetHeight(22)
		Buffs:SetWidth(8 * 22)
		Buffs.num = 8
		Buffs.size = 22

		self.Buffs = Buffs

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("LEFT", self, "RIGHT")
		Debuffs.showDebuffType = true
		Debuffs.initialAnchor = "BOTTOMLEFT"

		Debuffs:SetHeight(22)
		Debuffs:SetWidth(8 * 22)
		Debuffs.num = 8
		Debuffs.size = 22

		self.Debuffs = Debuffs

		Debuffs.PostCreateIcon = PostCreateIcon
		Debuffs.PostUpdateIcon = PostUpdateIcon

		Buffs.PostCreateIcon = PostCreateIcon
		Buffs.PostUpdateIcon = PostUpdateIcon
        --]]
	end,
    
    player = function(self)
        Shared(self)
        if (select(2, UnitClass('player')) == 'DEATHKNIGHT') then
            local Health = self.Health
            
            --[[ Creates a RuneFrame
                FRAME CreateRuneFrame(FRAME self)
            ]]
            local i
            local runes = CreateFrame('Frame', nil, self)
            --Needs to be positioned to anchor runes to it.
            runes:SetHeight(5)
            runes:SetPoint"LEFT"
            runes:SetPoint"RIGHT"
            runes:SetPoint"BOTTOM"

            for i = 1, 6 do
                runes[i] = CreateFrame('StatusBar', nil, runes)
                --runes[i]:SetParent(runes)
                runes[i]:SetHeight(5)
                runes[i]:SetWidth((cfg.width-5)/6)
                --runes[i]:SetWidth(36)
                runes[i]:SetStatusBarTexture(cfg.texture, 'BORDER')
                runes[i]:SetBackdrop(cfg.backdrop)
                runes[i]:SetBackdropColor(0, 0, 0, 1)
                runes[i]:SetBackdropBorderColor(0, 0, 0, 0)
                runes[i].bg = runes[i]:CreateTexture(nil, 'BACKGROUND')
                runes[i].bg:SetAllPoints(runes[i])
                runes[i].bg:SetTexture(cfg.texture)
                runes[i].bg:SetVertexColor(0.3, 0.3, 0.3, 0.5)
                if (i == 1) then
                    runes[i]:SetPoint('TOPLEFT', runes, 'TOPLEFT', 0, 0)
                else
                    runes[i]:SetPoint('LEFT', runes[i-1], 'RIGHT', 1, 0)
                end
            end
            self.Runes = runes                                                     
        end
    end,

    targettarget = function(self)
        Shared(self)
        --Make target and focus smaller.
        self:SetAttribute('initial-width', cfg.width * 0.85)
    end,

}
UnitSpecific.focus = UnitSpecific.targettarget

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
	}

	UnitSpecific.party = function(self)
		Shared(self)

		local Health, Power = self.Health, self.Power
		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetHeight(Health:GetHeight() + Power:GetHeight())
		Auras:SetPoint("LEFT", self, "RIGHT")

		Auras.showDebuffType = true

		Auras:SetWidth(9 * 22)
		Auras.size = 22
		Auras.gap = true
		Auras.numBuffs = 4
		Auras.numDebuffs = 4

		Auras.PostCreateIcon = PostCreateIcon

		self.Auras = Auras

		self.Range = range
	end
end

oUF:RegisterStyle("Cynyr", Shared)
for unit,layout in next, UnitSpecific do
	-- Capitalize the unit name, so it looks better.
	oUF:RegisterStyle('Cynyr - ' .. unit:gsub("^%l", string.upper), layout)
end

-- A small helper to change the style into a unit specific, if it exists.
local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Cynyr - ' .. unit:gsub("^%l", string.upper))
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	else
		self:SetActiveStyle'Cynyr'
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	end
end

oUF:Factory(function(self)
	local base = 100
	spawnHelper(self, 'focus', "BOTTOM", 0, base + (40 * 1))
	spawnHelper(self, 'pet', 'BOTTOM', 0, base + (40 * 2))
	spawnHelper(self, 'player', 'BOTTOM', 0, base + (40 * 3))
	spawnHelper(self, 'target', 'BOTTOM', 0, base + (40 * 4))
	spawnHelper(self, 'targettarget', 'BOTTOM', 0, base + (40 * 5))

	self:SetActiveStyle'Cynyr - Party'
	local party = self:SpawnHeader(nil, nil, 'raid,party,solo', 'showParty', cfg.showparty, 'showPlayer', cfg.showplayer, 'yOffset', -20)
	party:SetPoint("TOPLEFT", 30, -30)
end)

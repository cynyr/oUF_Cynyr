-----------------------------
-- INIT
-----------------------------

--get the addon namespace
local addon, ns = ...

--generate a holder for the config data
local cfg = CreateFrame("Frame")

-----------------------------
-- CONFIG
-----------------------------

--config variables
cfg.showplayer = false
cfg.showtarget = true
cfg.showtot = true
cfg.showpet = true
cfg.showfocus = true
cfg.showparty = false
cfg.showraid = false
cfg.allow_frame_movement = true
cfg.frames_locked = false 


cfg.texture = [=[Interface\ChatFrame\ChatFrameBackground]=]
cfg.backdrop = {
	bgFile = TEXTURE, insets = {top = -1, bottom = -1, left = -1, right = -1}
}
--cfg.backdrop_edge_texture = "Interface\\AddOns\\oUF_Simple\\media\\backdrop_edge"
cfg.font = "FONTS\\FRIZQT__.ttf"   

cfg.height = 27
cfg.width = 185

-----------------------------
-- HANDOVER
-----------------------------

--hand the config to the namespace for usage in other lua files (remember: those lua files must be called after the cfg.lua)
ns.cfg = cfg

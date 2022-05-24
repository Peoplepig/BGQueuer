--[[

Copyright 2022-∞ peoplepig (peoplepigflyhigh@gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.

Special thanks to everyone in WOW Taiwan realm.

]]-- 

local dbg = false;
local function dbgprint(str) if dbg then print(str) end end

BGQueuer = LibStub("AceAddon-3.0"):NewAddon("BGQueuer", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BGQueuer")

-- addon event handle --
function BGQueuer:OnInitialize()
	dbgprint("BGQueuer:OnInitialize()")
	self.defaults = {
		global = {
			global_addon_enable 		= {	enabled = true,	},
			ready_check_notification 	= {	enabled = true,	},
			role_check_notification 	= {	enabled = true,	},
			proposal_show_notification 	= {	enabled = true,	},
			battle_begin_notification 	= {	enabled = true,	},
			auto_leave_battlefield 		= {	enabled = true,	delay = 0,},
			auto_release 				= {	enabled = true,	},
			play_sound_on_mute 			= {	enabled = true,	}
		},
		char = {
			auto_role_confirmation		= { enabled = true, delay = 0 } ,
		}
	}

	self.db = LibStub("AceDB-3.0"):New("BGQueuerDB", self.defaults, true)
	dbgprint("db created")

	self.options = {
		name = 'BGQueuer',
		type = "group",
		dialogInline  = true,
		args = {
			global_addon_enable = {
				name = L["enable"],
				type = "toggle",
				set = 	(function (info, val)
							self.db.global.global_addon_enable.enabled = val;
							self.options.args.subgroupMajorOption.disabled = not val;
							self.options.args.subgroupSoundOption.disabled = not val;
							if val then self:OnEnable() else self:OnDisable() end
						end),
				get = 	(function (info)
				    		val = self.db.global.global_addon_enable.enabled;
				    		if val then self:OnEnable() else self:OnDisable() end
				    		return val 
						end),
				width = "full",
				order = 0
			},
			split = {
				type = "header",
				name = "",
				width = "full",
				order = 1,
			},
			subgroupMajorOption = {
				name = L["Major option"],
				type = "group",
				dialogInline = true,
				args = {
					auto_leave_battlefield = {
						type = "toggle",
						name = L["Auto leave BG/Arena if ended"],
						desc = L["Leave and play sound"],
						set = function(info, val) self.db.global.auto_leave_battlefield.enabled = val end,
						get = function(info) return self.db.global.auto_leave_battlefield.enabled end,
						order = 15,
						width = 1.5
					},
					delay = {
						type = "range",
						name = L["delay time"],
						desc = L["delay time to leave Battleground/Arena"],
						min = 0, max = 120, step = 1,
						set = function(info, val) self.db.global.auto_leave_battlefield.delay = val end,
						get = function(info) return self.db.global.auto_leave_battlefield.delay end,
						order = 15,
						width = 0.7
					},
					auto_role_confirmation = {
						type = "toggle",
						name = L["Auto Role Confirmation"],
						desc = L["Tank/healer/dps role"],
						set = function(info, val) self.db.char.auto_role_confirmation.enabled = val end,
						get = function(info) return self.db.char.auto_role_confirmation.enabled end,
						order = 16,
						width = 1.5,
					},
					auto_role_confirmation_delay = {
						type = "range",
						name = L["delay time"],
						desc = L["Delay time to auto role confirmation"],
						min = 0, max = 12, step = 1,
						set = function(info, val) self.db.char.auto_role_confirmation.delay = val end,
						get = function(info) return self.db.char.auto_role_confirmation.delay end,
						order = 16,
						width = 0.7
					},
					role_check_popup = {
						name = L["Confirm Role"],
						desc = L["Tank/healer/dps role"],
						type = "execute",
						func = function() StaticPopupSpecial_Show(LFDRoleCheckPopup) end,
						order = 16,
						width = 0.7,
					},
					auto_release = {
						type = "toggle",
						name = L["Auto Release when player was died"],
						set = function(info, val) self.db.global.auto_release.enabled = val end,
						get = function(info) return self.db.global.auto_release.enabled end,
						width = "full",
						order = 17,
					}
				}
			},
			subgroupSoundOption = {
				name = L["Play sound"],
				type = "group",
				guiInline = true,
				args = {
					play_sound_on_mute = {
						type = "toggle",
						name = L["Play sound even in mute mode"],
						set = function(info, val) self.db.global.play_sound_on_mute.enabled = val end,
						get = function(info) return self.db.global.play_sound_on_mute.enabled end,
						width = "full",
						order = 10, -- always first
					},
					ready_check_notification = {
						name = L["Play sound when a leader initiated a ready check"],
						type = "toggle",
						set = function(info, val) self.db.global.ready_check_notification.enabled = val end,
						get = function(info) return self.db.global.ready_check_notification.enabled end,
						width = "full",
						order = 11,
					},
					role_check_notification = {
						type = "toggle",
						name = L["Play sound when a leader initiated a role check"],
						set = function(info, val) self.db.global.role_check_notification.enabled = val end,
						get = function(info) return self.db.global.role_check_notification.enabled end,
						width = "full",
						order = 12,
					},
					proposal_show_notification = {
						type = "toggle",
						name = L["Play sound when you are eligible to enter battle"],
						desc = L["Your battlefield group has been ready"],
						set = function(info, val) self.db.global.proposal_show_notification.enabled = val end,
						get = function(info) return self.db.global.proposal_show_notification.enabled end,
						width = "full",
						order = 13,
					},
					battle_begin_notification = {
						type = "toggle",
						name = L["Play sound when battle countdown almost ends"],
						desc = L["About 5 seconds before"],
						set = function(info, val) self.db.global.battle_begin_notification.enabled = val end,
						get = function(info) return self.db.global.battle_begin_notification.enabled end,
						width = "full",
						order = 14,
					},
				}
			},
			newline1 = {
				type = "input",
				name = "",
				arg = "",
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 101,
				dialogControl = "SFX-Info",
			},
			split = {
				type = "header",
				name = L["About"],
				width = "full",
				order = 102,
			},
			newline2 = {
				type = "input",
				name = "",
				arg = "",
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 105,
				dialogControl = "SFX-Info",
			},
			intro = {
				type = "description",
				name = L["An addon that help you queue for battlefield by play sound and \nnot to miss the eligibility to join/leave battlefield battle anymore."],
				order = 112,
				disabled = false,
			},
			version = {
				type = "input",
				name = L["Version"],
				arg = GetAddOnMetadata("BGQueuer", "Version"),
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 113,
				disabled = false,
				dialogControl = "SFX-Info",
			},
			author = {
				type = "input",
				name = L["Author"],
				desc = L["peoplepigflyhigh"],
				arg = GetAddOnMetadata("BGQueuer", "Author"),
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 114,
				disabled = false,
				dialogControl = "SFX-Info",
			},
			mail = {
				type = "input",
				name = "Email",
				arg = GetAddOnMetadata("BGQueuer", "X-Email"),
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 115,
				disabled = false,
				dialogControl = "SFX-Info-URL",
			},
			license = {
				type = "input",
				name = "License",
				arg = GetAddOnMetadata("BGQueuer", "X-License"),
				get = (function (info) return info.arg end),
				set = (function () end),
				order = 116,
				dialogControl = "SFX-Info",
			},
		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("BGQueuer", self.options)
	local interfaceFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions('BGQueuer',"BGQueuer")
end

function BGQueuer:OnEnable()
	self:RegisterEvent("LFG_PROPOSAL_SHOW");
	self:RegisterEvent("READY_CHECK");		
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
	self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSE_MATCH");
	self:RegisterEvent("LFG_ROLE_CHECK_SHOW");
	self:RegisterEvent("START_TIMER");
	self:RegisterEvent("PLAYER_DEAD")
end

function BGQueuer:OnDisable()
	self:UnregisterAllEvents()
end

-- registered event handle --
function BGQueuer:LFG_PROPOSAL_SHOW()
	dbgprint("LFG_PROPOSAL_SHOW")
	if self.db.global.proposal_show_notification.enabled then
		self:SondAlert()
		self:ProposolSoundAlert()
	end
end

function BGQueuer:PET_BATTLE_QUEUE_PROPOSE_MATCH()
	if self.db.global.proposal_show_notification.enabled then
		self:SondAlert()
	end
end

function BGQueuer:READY_CHECK()
	dbgprint("READY_CHECK()")
	if self.db.global.ready_check_notification.enabled then
		self:SondAlert()
	end
end

function BGQueuer:LFG_ROLE_CHECK_SHOW()
	dbgprint("LFG_ROLE_CHECK_SHOW()")
	if self.db.global.role_check_notification.enabled then
		self:SondAlert()
	end

	if self.db.char.auto_role_confirmation.enabled then
		C_Timer.After(self.db.char.auto_role_confirmation.delay, function() CompleteLFGRoleCheck(true) end)
	end
end

function BGQueuer:PLAYER_DEAD()
	if self.db.global.auto_release.enabled then
		RepopMe()
	end
end

function BGQueuer:BgTimerHandler()
	if BGQueuer.db.global.battle_begin_notification.enabled then
		BGQueuer:SondAlert()
	end
end

function BGQueuer:START_TIMER(self, event, ...)
	local timerType, timeRemaining, totalTime = ...;
	
	if (nil == totalTime) then
		timeRemaining = timerType
	end

	dbgprint("timer triggered! after n seconds" .. timeRemaining)
	C_Timer.After(timeRemaining - 5, BGQueuer.BgTimerHandler)
end

function BGQueuer:UPDATE_BATTLEFIELD_STATUS()
	for i = 1, GetMaxBattlefieldID() do
		local status = GetBattlefieldStatus(i)
	
		if (status == "confirm") then
			dbgprint("bg confirm")
			if self.db.global.proposal_show_notification.enabled then
				self:SondAlert()
				self:ProposolSoundAlert()
			end
			break
		end
		i = i + 1
	end

	if (GetBattlefieldWinner()) then
		dbgprint("GetBattlefieldWinner")
		if self.db.global.auto_leave_battlefield.enabled then
			self:SondAlert()
			C_Timer.After(self.db.global.auto_leave_battlefield.delay, function() LeaveBattlefield() end)
		end
	end
end

-- utils --
function BGQueuer:SondAlert()
	local channel = self.db.global.play_sound_on_mute.enabled and "Master" or nil
    PlaySound(8960, channel)
end

function BGQueuer:ProposolSoundAlert() -- bg role or confirm
	local channel = self.db.global.play_sound_on_mute.enabled and "Master" or nil
	PlaySound(67788, channel)
	PlaySound(31756, channel)
	C_Timer.After(0.2, (function() PlaySound(10338, channel) end))
end
﻿local E, L, V, P, G = unpack(select(2, ...));
local DT = E:GetModule("DataTexts");

local PAPERDOLLFRAME_TOOLTIP_FORMAT = PAPERDOLLFRAME_TOOLTIP_FORMAT;
local CR_CRIT_SPELL = CR_CRIT_SPELL;
local CR_CRIT_SPELL_TOOLTIP = CR_CRIT_SPELL_TOOLTIP;
local SPELL_CRIT_CHANCE = SPELL_CRIT_CHANCE;
local RANGED_CRIT_CHANCE = RANGED_CRIT_CHANCE;
local CR_CRIT_RANGED_TOOLTIP = CR_CRIT_RANGED_TOOLTIP;
local CR_CRIT_RANGED = CR_CRIT_RANGED;
local MELEE_CRIT_CHANCE = MELEE_CRIT_CHANCE;
local CR_CRIT_MELEE_TOOLTIP = CR_CRIT_MELEE_TOOLTIP;
local CR_CRIT_MELEE = CR_CRIT_MELEE;
local CRIT_ABBR = CRIT_ABBR;

local critRating;
local displayModifierString = "";
local lastPanel;
local join = string.join;
local format = string.format;

local function OnEvent(self, event, ...)
	local critRating;
	if(E.Role == "Caster")then
		critRating = GetSpellCritChance(2);
	else
		if(E.myclass == "HUNTER")then
			critRating = GetRangedCritChance();
		else
			critRating = GetCritChance();
		end
	end
	self.text:SetFormattedText(displayModifierString, CRIT_ABBR, critRating);
	lastPanel = self;
end

local function OnEnter(self)
	DT:SetupTooltip(self);
	
	local text, tooltip;
	if(E.Role == "Caster") then
		text = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, SPELL_CRIT_CHANCE).." "..format("%.2F%%", GetSpellCritChance(2));
		tooltip = format(CR_CRIT_SPELL_TOOLTIP, GetCombatRating(CR_CRIT_SPELL), GetCombatRatingBonus(CR_CRIT_SPELL));
	else
		if(E.myclass == "HUNTER") then
			text = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, RANGED_CRIT_CHANCE).." "..format("%.2F%%", GetRangedCritChance());
			tooltip = format(CR_CRIT_RANGED_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED));
		else
			text = format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MELEE_CRIT_CHANCE).." "..format("%.2F%%", GetCritChance());
			tooltip = format(CR_CRIT_MELEE_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE));
		end
	end
	
	DT.tooltip:AddLine(text, 1, 1, 1);
	DT.tooltip:AddLine(tooltip, nil, nil, nil, true);
	DT.tooltip:Show();
end

local function ValueColorUpdate(hex, r, g, b)
	displayModifierString = join("", "%s: ", hex, "%.2f%%|r");
	
	if(lastPanel ~= nil) then
		OnEvent(lastPanel);
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true;

DT:RegisterDatatext(CRIT_ABBR, { "UNIT_AURA", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_DAMAGE_DONE_MODS" }, OnEvent, nil, nil, OnEnter);
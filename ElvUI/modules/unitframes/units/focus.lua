local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

local _, ns = ...;
local ElvUF = ns.oUF;
assert(ElvUF, "ElvUI was unable to locate oUF.");
local tinsert = table.insert;

function UF:Construct_FocusFrame(frame)	
	frame.Health = self:Construct_HealthBar(frame, true, true, "RIGHT");
	frame.Health.frequentUpdates = true;
	frame.Power = self:Construct_PowerBar(frame, true, true, "LEFT", false);
	frame.Name = self:Construct_NameText(frame);
	frame.Portrait3D = self:Construct_Portrait(frame, "model");
	frame.Portrait2D = self:Construct_Portrait(frame, "texture");
	frame.Castbar = self:Construct_Castbar(frame, "LEFT", L["Focus Castbar"]);
	frame.Castbar.SafeZone = nil;
	frame.Castbar.LatencyTexture:Hide();
	frame.Buffs = self:Construct_Buffs(frame);
	frame.Debuffs = self:Construct_Debuffs(frame);
	frame.AuraBars = self:Construct_AuraBarHeader(frame);
	frame.RaidIcon = UF:Construct_RaidIcon(frame);
	frame.Range = UF:Construct_Range(frame);
	frame.Threat = UF:Construct_Threat(frame);
	
	frame:Point("BOTTOMRIGHT", ElvUF_Target, "TOPRIGHT", 0, 220);
	E:CreateMover(frame, frame:GetName().."Mover", L["Focus Frame"], nil, nil, nil, "ALL,SOLO");
end

function UF:Update_FocusFrame(frame, db)
	frame.db = db;
	if(frame.Portrait) then
		frame.Portrait:Hide();
		frame.Portrait:ClearAllPoints();
		frame.Portrait.backdrop:Hide();
	end
	
	frame.Portrait = db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D;
	local BORDER = E.Border;
	local SPACING = E.Spacing;
	local UNIT_WIDTH = db.width;
	local UNIT_HEIGHT = db.height;
	local SHADOW_SPACING = E.PixelMode and 3 or 4;
	local USE_POWERBAR = db.power.enable;
	local USE_MINI_POWERBAR = db.power.width == "spaced" and USE_POWERBAR;
	local USE_INSET_POWERBAR = db.power.width == "inset" and USE_POWERBAR;
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR;
	local POWERBAR_OFFSET = db.power.offset;
	local POWERBAR_HEIGHT = db.power.height;
	local POWERBAR_WIDTH = db.width - (BORDER*2);
	
	local USE_PORTRAIT = db.portrait.enable;
	local USE_PORTRAIT_OVERLAY = db.portrait.overlay and USE_PORTRAIT;
	local PORTRAIT_WIDTH = db.portrait.width;
	
	local unit = self.unit;
	frame:RegisterForClicks(self.db.targetOnMouseDown and "AnyDown" or "AnyUp");
	frame.colors = ElvUF.colors;
	frame:Size(UNIT_WIDTH, UNIT_HEIGHT);
	_G[frame:GetName().."Mover"]:Size(frame:GetSize());
	
	frame:SetAttribute("type3", "macro");
	frame:SetAttribute("macrotext", "/clearfocus");
	
	do
		if(not USE_POWERBAR) then
			POWERBAR_HEIGHT = 0;
		end	
		
		if(USE_PORTRAIT_OVERLAY or not USE_PORTRAIT) then
			PORTRAIT_WIDTH = 0;	
		end
		
		if(USE_MINI_POWERBAR) then
			POWERBAR_WIDTH = POWERBAR_WIDTH / 2;
		end
	end
	
	do
		local health = frame.Health;
		health.Smooth = self.db.smoothbars;
		
		local x, y = self:GetPositionOffset(db.health.position);
		health.value:ClearAllPoints();
		health.value:Point(db.health.position, health, db.health.position, x + db.health.xOffset, y + db.health.yOffset);
		frame:Tag(health.value, db.health.text_format);
		
		health.colorSmooth = nil;
		health.colorHealth = nil;
		health.colorClass = nil;
		health.colorReaction = nil;
		if(self.db["colors"].healthclass ~= true) then
			if(self.db["colors"].colorhealthbyvalue == true) then
				health.colorSmooth = true;
			else
				health.colorHealth = true;
			end		
		else
			health.colorClass = true;
			health.colorReaction = true;
		end
		
		if(self.db["colors"].forcehealthreaction == true) then
			health.colorClass = false;
			health.colorReaction = true;
		end
		
		health:ClearAllPoints();
		health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER);
		
		if(USE_POWERBAR_OFFSET) then
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -(BORDER+POWERBAR_OFFSET), -BORDER);
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER+POWERBAR_OFFSET);
		elseif(USE_INSET_POWERBAR or POWERBAR_DETACHED) then
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER);
		elseif(USE_MINI_POWERBAR) then
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + (POWERBAR_HEIGHT/2));
		else
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, (USE_POWERBAR and ((BORDER + SPACING)*2) or BORDER) + POWERBAR_HEIGHT);
		end
		
		health.bg:ClearAllPoints();
		if(not USE_PORTRAIT_OVERLAY) then
			health:Point("TOPLEFT", PORTRAIT_WIDTH+BORDER, -BORDER);
			health.bg:SetParent(health);
			health.bg:SetAllPoints();
		else
			health.bg:Point("BOTTOMLEFT", health:GetStatusBarTexture(), "BOTTOMRIGHT");
			health.bg:Point("TOPRIGHT", health);
			health.bg:SetParent(frame.Portrait.overlay);
		end
	end
	
	UF:UpdateNameSettings(frame);
	
	do
		local power = frame.Power;
		if(USE_POWERBAR) then
			if(not frame:IsElementEnabled("Power")) then
				frame:EnableElement("Power");
				power:Show();
			end
			
			power.Smooth = self.db.smoothbars;
			
			local x, y = self:GetPositionOffset(db.power.position);
			power.value:ClearAllPoints();
			power.value:Point(db.power.position, frame.Health, db.power.position, x + db.power.xOffset, y + db.power.yOffset);
			frame:Tag(power.value, db.power.text_format);
			
			power.colorClass = nil;
			power.colorReaction = nil;
			power.colorPower = nil;
			if(self.db["colors"].powerclass) then
				power.colorClass = true;
				power.colorReaction = true;
			else
				power.colorPower = true;
			end
			
			power:ClearAllPoints();
			if(USE_POWERBAR_OFFSET) then
				power:Point("TOPRIGHT", frame.Health, "TOPRIGHT", POWERBAR_OFFSET, -POWERBAR_OFFSET);
				power:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", POWERBAR_OFFSET, -POWERBAR_OFFSET);
				power:SetFrameStrata("LOW");
				power:SetFrameLevel(2);
			elseif(USE_INSET_POWERBAR) then
				power:Height(POWERBAR_HEIGHT);
				power:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", BORDER + (BORDER*2), BORDER + (BORDER*2));
				power:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(BORDER + (BORDER*2)), BORDER + (BORDER*2));
				power:SetFrameStrata("MEDIUM");
				power:SetFrameLevel(frame:GetFrameLevel() + 3);
			elseif(USE_MINI_POWERBAR) then
				power:Width(POWERBAR_WIDTH - BORDER*2);
				power:Height(POWERBAR_HEIGHT);
				power:Point("RIGHT", frame, "BOTTOMRIGHT", -(BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2));
				power:SetFrameStrata("MEDIUM");
				power:SetFrameLevel(frame:GetFrameLevel() + 3);
			else
				power:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", BORDER, -(E.PixelMode and 0 or (BORDER + SPACING)));
				power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER, BORDER);
			end
		elseif(frame:IsElementEnabled("Power")) then
			frame:DisableElement("Power");
			power:Hide();
		end
	end
	
	do
		local threat = frame.Threat;
		if(db.threatStyle ~= "NONE" and db.threatStyle ~= nil) then
			if(not frame:IsElementEnabled("Threat")) then
				frame:EnableElement("Threat");
			end
			
			if(db.threatStyle == "GLOW") then
				threat:SetFrameStrata("BACKGROUND");
				threat.glow:ClearAllPoints();
				threat.glow:SetBackdropBorderColor(0, 0, 0, 0);
				threat.glow:Point("TOPLEFT", frame.Health.backdrop, "TOPLEFT", -SHADOW_SPACING, SHADOW_SPACING);
				threat.glow:Point("TOPRIGHT", frame.Health.backdrop, "TOPRIGHT", SHADOW_SPACING, SHADOW_SPACING);
				threat.glow:Point("BOTTOMLEFT", frame.Power.backdrop, "BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
				threat.glow:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
				
				if(USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or USE_INSET_POWERBAR) then
					threat.glow:Point("BOTTOMLEFT", frame.Health.backdrop, "BOTTOMLEFT", -SHADOW_SPACING, -SHADOW_SPACING);
					threat.glow:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", SHADOW_SPACING, -SHADOW_SPACING);
				end
			elseif(db.threatStyle == "ICONTOPLEFT" or db.threatStyle == "ICONTOPRIGHT" or db.threatStyle == "ICONBOTTOMLEFT" or db.threatStyle == "ICONBOTTOMRIGHT" or db.threatStyle == "ICONTOP" or db.threatStyle == "ICONBOTTOM" or db.threatStyle == "ICONLEFT" or db.threatStyle == "ICONRIGHT") then
				threat:SetFrameStrata("HIGH");
				local point = db.threatStyle;
				point = point:gsub("ICON", "");
				
				threat.texIcon:ClearAllPoints();
				threat.texIcon:SetPoint(point, frame.Health, point);
			end
		elseif(frame:IsElementEnabled("Threat")) then
			frame:DisableElement("Threat");
		end
	end
	
	do
		local portrait = frame.Portrait;
		if(USE_PORTRAIT) then
			if(not frame:IsElementEnabled("Portrait")) then
				frame:EnableElement("Portrait");
			end
			
			portrait:ClearAllPoints();
			if(USE_PORTRAIT_OVERLAY) then
				if(db.portrait.style == "3D") then
					portrait:SetFrameLevel(frame.Health:GetFrameLevel() + 1);
				end
				
				portrait:SetAllPoints(frame.Health);
				portrait:SetAlpha(0.3);
				portrait:Show();
				portrait.backdrop:Hide();
			else
				portrait:SetAlpha(1);
				portrait:Show();
				portrait.backdrop:Show();
				portrait.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT");
				
				if(db.portrait.style == "3D") then
					portrait:SetFrameLevel(frame:GetFrameLevel() + 5);
				end
				
				if(USE_MINI_POWERBAR or USE_POWERBAR_OFFSET or not USE_POWERBAR or USE_INSET_POWERBAR or POWERBAR_DETACHED) then
					portrait.backdrop:Point("BOTTOMRIGHT", frame.Health.backdrop, "BOTTOMLEFT", E.PixelMode and 1 or -SPACING, 0);
				else
					portrait.backdrop:Point("BOTTOMRIGHT", frame.Power.backdrop, "BOTTOMLEFT", E.PixelMode and 1 or -SPACING, 0);
				end
				
				portrait:Point("BOTTOMLEFT", portrait.backdrop, "BOTTOMLEFT", BORDER, BORDER);
				portrait:Point("TOPRIGHT", portrait.backdrop, "TOPRIGHT", -BORDER, -BORDER);			
			end
		else
			if(frame:IsElementEnabled("Portrait")) then
				frame:DisableElement("Portrait");
				portrait:Hide();
				portrait.backdrop:Hide();
			end
		end
	end
	
	do
		if(db.debuffs.enable or db.buffs.enable) then
			if(not frame:IsElementEnabled("Aura")) then
				frame:EnableElement("Aura");
			end	
		else
			if(frame:IsElementEnabled("Aura")) then
				frame:DisableElement("Aura");
			end			
		end
		
		frame.Buffs:ClearAllPoints();
		frame.Debuffs:ClearAllPoints();
	end
	
	do
		local buffs = frame.Buffs;
		local rows = db.buffs.numrows;
		
		if(USE_POWERBAR_OFFSET) then
			buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET);
		else
			buffs:SetWidth(UNIT_WIDTH);
		end
		
		buffs.forceShow = frame.forceShowAuras;
		buffs.num = db.buffs.perrow * rows;
		buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows);
		
		if(db.buffs.sizeOverride and db.buffs.sizeOverride > 0) then
			buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride);
		end
		
		local x, y = E:GetXYOffset(db.buffs.anchorPoint);
		local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo);
		
		buffs:Point(E.InversePoints[db.buffs.anchorPoint], attachTo, db.buffs.anchorPoint, x + db.buffs.xOffset, y + db.buffs.yOffset + (E.PixelMode and (db.buffs.anchorPoint:find("TOP") and -1 or 1) or 0));
		buffs:Height(buffs.size * rows);
		buffs["growth-y"] = db.buffs.anchorPoint:find("TOP") and "UP" or "DOWN";
		buffs["growth-x"] = db.buffs.anchorPoint == "LEFT" and "LEFT" or  db.buffs.anchorPoint == "RIGHT" and "RIGHT" or (db.buffs.anchorPoint:find("LEFT") and "RIGHT" or "LEFT");
		buffs.initialAnchor = E.InversePoints[db.buffs.anchorPoint];

		if(db.buffs.enable) then			
			buffs:Show();
			UF:UpdateAuraIconSettings(buffs);
		else
			buffs:Hide();
		end
	end
	
	do
		local debuffs = frame.Debuffs;
		local rows = db.debuffs.numrows;
		
		if(USE_POWERBAR_OFFSET) then
			debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET);
		else
			debuffs:SetWidth(UNIT_WIDTH);
		end
		
		debuffs.forceShow = frame.forceShowAuras;
		debuffs.num = db.debuffs.perrow * rows;
		debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows);
		
		if(db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0) then
			debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride);
		end
		
		local x, y = E:GetXYOffset(db.debuffs.anchorPoint);
		local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.debuffs.attachTo == "BUFFS" and db.buffs.attachTo == "DEBUFFS");
		
		debuffs:Point(E.InversePoints[db.debuffs.anchorPoint], attachTo, db.debuffs.anchorPoint, x + db.debuffs.xOffset, y + db.debuffs.yOffset);
		debuffs:Height(debuffs.size * rows);
		debuffs["growth-y"] = db.debuffs.anchorPoint:find("TOP") and "UP" or "DOWN";
		debuffs["growth-x"] = db.debuffs.anchorPoint == "LEFT" and "LEFT" or  db.debuffs.anchorPoint == "RIGHT" and "RIGHT" or (db.debuffs.anchorPoint:find("LEFT") and "RIGHT" or "LEFT");
		debuffs.initialAnchor = E.InversePoints[db.debuffs.anchorPoint];

		if(db.debuffs.enable) then			
			debuffs:Show();
			UF:UpdateAuraIconSettings(debuffs);
		else
			debuffs:Hide();
		end
	end	
	
	do
		local castbar = frame.Castbar;
		castbar:Width(db.castbar.width - (BORDER * 2));
		castbar:Height(db.castbar.height);
		castbar.Holder:Width(db.castbar.width);
		castbar.Holder:Height(db.castbar.height + (E.PixelMode and 2 or (BORDER * 2)));
		castbar.Holder:GetScript("OnSizeChanged")(castbar.Holder);
		
		if(db.castbar.icon) then
			castbar.Icon = castbar.ButtonIcon;
			castbar.Icon.bg:Width(db.castbar.height + (E.Border * 2));
			castbar.Icon.bg:Height(db.castbar.height + (E.Border * 2));
			
			castbar:Width(db.castbar.width - castbar.Icon.bg:GetWidth() - (E.PixelMode and 1 or 5));
			castbar.Icon.bg:Show();
		else
			castbar.ButtonIcon.bg:Hide();
			castbar.Icon = nil;
		end

		if(db.castbar.spark) then
			castbar.Spark:Show();
		else
			castbar.Spark:Hide();
		end

		if(db.castbar.enable and not frame:IsElementEnabled("Castbar")) then
			frame:EnableElement("Castbar");
		elseif(not db.castbar.enable and frame:IsElementEnabled("Castbar")) then
			frame:DisableElement("Castbar");
		end			
	end
	
	do
		local RI = frame.RaidIcon;
		if(db.raidicon.enable) then
			frame:EnableElement("RaidIcon");
			RI:Show();
			RI:Size(db.raidicon.size);
			
			local x, y = self:GetPositionOffset(db.raidicon.attachTo);
			RI:ClearAllPoints();
			RI:Point(db.raidicon.attachTo, frame, db.raidicon.attachTo, x + db.raidicon.xOffset, y + db.raidicon.yOffset);
		else
			frame:DisableElement("RaidIcon");
			RI:Hide();
		end
	end
	
	do
		local auraBars = frame.AuraBars;
		if(db.aurabar.enable) then
			if(not frame:IsElementEnabled("AuraBars")) then
				frame:EnableElement("AuraBars");
			end
			auraBars:Show();
			auraBars.friendlyAuraType = db.aurabar.friendlyAuraType;
			auraBars.enemyAuraType = db.aurabar.enemyAuraType;
			
			local buffColor = UF.db.colors.auraBarBuff;
			local debuffColor = UF.db.colors.auraBarDebuff;
			
			local attachTo = frame;
			
			if(db.aurabar.attachTo == "BUFFS") then
				attachTo = frame.Buffs;
			elseif(db.aurabar.attachTo == "DEBUFFS") then
				attachTo = frame.Debuffs;
			end
			
			local anchorPoint, anchorTo = "BOTTOM", "TOP";
			if(db.aurabar.anchorPoint == "BELOW") then
				anchorPoint, anchorTo = "TOP", "BOTTOM";
			end
			
			local yOffset = 0;
			if(E.PixelMode) then
				if(db.aurabar.anchorPoint == "BELOW") then
					yOffset = 1;
				else
					yOffset = -1;
				end
			end
			
			auraBars.auraBarHeight = db.aurabar.height;
			
			auraBars:ClearAllPoints();
			auraBars:SetPoint(anchorPoint.."LEFT", attachTo, anchorTo.."LEFT", POWERBAR_OFFSET, yOffset);
			auraBars:SetPoint(anchorPoint.."RIGHT", attachTo, anchorTo.."RIGHT", -POWERBAR_OFFSET, yOffset);

			auraBars.buffColor = {buffColor.r, buffColor.g, buffColor.b};
			if(UF.db.colors.auraBarByType) then
				auraBars.debuffColor = nil;
				auraBars.defaultDebuffColor = {debuffColor.r, debuffColor.g, debuffColor.b};
			else
				auraBars.debuffColor = {debuffColor.r, debuffColor.g, debuffColor.b};
				auraBars.defaultDebuffColor = nil;
			end
			
			if(db.aurabar.sort == "TIME_REMAINING") then
				auraBars.sort = true;
			elseif(db.aurabar.sort == "TIME_REMAINING_REVERSE") then
				auraBars.sort = UF.SortAuraBarReverse;
			elseif(db.aurabar.sort == "TIME_DURATION") then
				auraBars.sort = UF.SortAuraBarDuration;
			elseif(db.aurabar.sort == "TIME_DURATION_REVERSE") then
				auraBars.sort = UF.SortAuraBarDurationReverse;
			elseif(db.aurabar.sort == "NAME") then
				auraBars.sort = UF.SortAuraBarName;
			else
				auraBars.sort = nil;
			end
			
			auraBars.down = db.aurabar.anchorPoint == "BELOW";
			auraBars.maxBars = db.aurabar.maxBars;
			auraBars.forceShow = frame.forceShowAuras;
			auraBars:SetAnchors();
		else
			if(frame:IsElementEnabled("AuraBars")) then
				frame:DisableElement("AuraBars");
				auraBars:Hide();
			end
		end
	end
	
	do
		local range = frame.Range;
		if(db.rangeCheck) then
			if(not frame:IsElementEnabled("Range")) then
				frame:EnableElement("Range");
			end

			range.outsideAlpha = E.db.unitframe.OORAlpha;
		else
			if(frame:IsElementEnabled("Range")) then
				frame:DisableElement("Range");
			end				
		end
	end		
	
	if(db.customTexts) then
		local customFont = UF.LSM:Fetch("font", UF.db.font);
		for objectName, _ in pairs(db.customTexts) do
			if(not frame[objectName]) then
				frame[objectName] = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY");
			end
			
			local objectDB = db.customTexts[objectName];
			if(objectDB.font) then
				customFont = UF.LSM:Fetch("font", objectDB.font);
			end
			
			frame[objectName]:FontTemplate(customFont, objectDB.size or UF.db.fontSize, objectDB.fontOutline or UF.db.fontOutline);
			frame:Tag(frame[objectName], objectDB.text_format or "");
			frame[objectName]:SetJustifyH(objectDB.justifyH or "CENTER");
			frame[objectName]:ClearAllPoints();
			frame[objectName]:SetPoint(objectDB.justifyH or "CENTER", frame, objectDB.justifyH or "CENTER", objectDB.xOffset, objectDB.yOffset);
		end
	end
	
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentHealth, frame.Health, frame.Health.bg, true);
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Power, frame.Power.bg);
	
	frame:UpdateAllElements();
end

tinsert(UF["unitstoload"], "focus");
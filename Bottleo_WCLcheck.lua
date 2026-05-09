local ADDON_NAME = ...
local REGION = "us" -- OCE realms use the US Warcraft Logs region.

-- Converts a realm name into the format Warcraft Logs expects.
-- Example: "Frostmourne" stays "frostmourne", "Area 52" becomes "area52".
local function NormaliseRealm(realm)
    if realm == nil or realm == "" then
        realm = GetRealmName()
    end

    realm = realm:gsub("%s+", "")
    realm = realm:lower()

    return realm
end

-- Splits a full character name into character name and realm.
-- Example: "Chappys-Frostmourne" becomes "Chappys", "Frostmourne".
local function SplitNameAndRealm(fullName)
    if fullName == nil or fullName == "" then
        return nil, nil
    end

    local name, realm = strsplit("-", fullName)

    if realm == nil or realm == "" then
        realm = GetRealmName()
    end

    return name, realm
end

-- Builds the Warcraft Logs character URL.
local function BuildWarcraftLogsURL(fullName)
    local name, realm = SplitNameAndRealm(fullName)

    if name == nil or realm == nil then
        return nil
    end

    realm = NormaliseRealm(realm)

    return "https://www.warcraftlogs.com/character/" .. REGION .. "/" .. realm .. "/" .. name .. "?zone=47"
end

-- Popup window used to display the URL.
-- WoW addons generally cannot copy directly to clipboard, so the URL is highlighted for Ctrl + C.
StaticPopupDialogs["BOTTLEO_WCLCHECK"] = {
    text = "Copy this Warcraft Logs URL:",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 420,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,

    OnShow = function(self, data)
        local editBox = self.editBox or self.EditBox

        if editBox == nil then
            return
        end

        local textToShow = "Invalid character name"

        if data ~= nil and data.fullName ~= nil then
            local url = BuildWarcraftLogsURL(data.fullName)

            if url ~= nil then
                textToShow = url
            end
        end

        editBox:SetText(textToShow)
        editBox:SetFocus()
        editBox:HighlightText()
    end,

    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,

    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end
}

-- Shows the copy popup for a specific character.
local function ShowWarcraftLogsPopup(fullName)
    StaticPopup_Show("BOTTLEO_WCLCHECK", nil, nil, { fullName = fullName })
end

-- Gets only the character name from a Character-Realm string.
-- Example: "Chappys-Frostmourne" becomes "Chappys".
local function GetShortName(fullName)
    if fullName == nil then
        return nil
    end

    local name = strsplit("-", fullName)

    return name
end

-- Gets the full Character-Realm name from Blizzard's LFG applicant API.
local function GetApplicantFullName(applicantID)
    if applicantID == nil then
        return nil
    end

    local fullName = C_LFGList.GetApplicantMemberInfo(applicantID, 1)

    return fullName
end

-- Builds a lookup table of visible names to full names.
-- Example:
-- applicantNames["Chappys"] = "Chappys-Frostmourne"
-- This fixes the issue where visible rows and applicant indexes do not always match.
local function BuildApplicantNameLookup()
    local applicantNames = {}
    local applicants = C_LFGList.GetApplicants()

    if applicants == nil then
        return applicantNames
    end

    for _, applicantID in ipairs(applicants) do
        local fullName = GetApplicantFullName(applicantID)

        if fullName ~= nil and fullName ~= "" then
            local shortName = GetShortName(fullName)

            if shortName ~= nil and shortName ~= "" then
                applicantNames[shortName] = fullName
            end
        end
    end

    return applicantNames
end

-- Searches a visible LFG applicant row for a player name.
-- It checks the row's text regions and child frames until it finds a name from applicantNames.
local function FindMatchingNameOnFrame(frame, applicantNames)
    if frame == nil or applicantNames == nil then
        return nil
    end

    local regions = { frame:GetRegions() }

    for _, region in ipairs(regions) do
        if region ~= nil and region.GetText ~= nil then
            local text = region:GetText()

            if text ~= nil and applicantNames[text] ~= nil then
                return applicantNames[text]
            end
        end
    end

    local children = { frame:GetChildren() }

    for _, child in ipairs(children) do
        local foundName = FindMatchingNameOnFrame(child, applicantNames)

        if foundName ~= nil then
            return foundName
        end
    end

    return nil
end

-- Adds or updates the WCL button on one applicant row.
local function AddButtonToApplicantFrame(applicantFrame, applicantNames)
    if applicantFrame == nil then
        return
    end

    -- Resolve the correct full Character-Realm name from the visible row.
    local fullName = FindMatchingNameOnFrame(applicantFrame, applicantNames)

    if fullName == nil or fullName == "" then
        if applicantFrame.BottleoWCLButton ~= nil then
            applicantFrame.BottleoWCLButton:Hide()
            applicantFrame.BottleoWCLButton.fullName = nil
        end

        return
    end

    -- If the button already exists, just update the stored name.
    if applicantFrame.BottleoWCLButton ~= nil then
        applicantFrame.BottleoWCLButton.fullName = fullName
        applicantFrame.BottleoWCLButton:Show()
        return
    end

    -- Create the WCL button.
    local button = CreateFrame("Button", nil, applicantFrame, "UIPanelButtonTemplate")
    button:SetSize(35, 18)
    button:SetText("WCL")
    button:SetPoint("RIGHT", applicantFrame, "RIGHT", -150, 0)
    button:SetFrameStrata("HIGH")

    -- When clicked, open the popup for the specific row's character.
    button:SetScript("OnClick", function(self)
        if self.fullName == nil or self.fullName == "" then
            print("|cffff0000Bottleo WCL Check: Could not read applicant name.|r")
            return
        end

        ShowWarcraftLogsPopup(self.fullName)
    end)

    button.fullName = fullName
    applicantFrame.BottleoWCLButton = button
end

-- Hides old buttons before refreshing the applicant list.
-- This prevents reused Blizzard row frames from keeping old applicant data.
local function HideOldButtons(scrollBox)
    if scrollBox == nil or scrollBox.GetFrames == nil then
        return
    end

    local frames = scrollBox:GetFrames()

    for _, applicantFrame in ipairs(frames) do
        if applicantFrame.BottleoWCLButton ~= nil then
            applicantFrame.BottleoWCLButton:Hide()
            applicantFrame.BottleoWCLButton.fullName = nil
        end
    end
end

-- Refreshes all WCL buttons in the LFG applicant list.
local function UpdateApplicantButtons()
    if LFGListFrame == nil then
        return
    end

    if LFGListFrame.ApplicationViewer == nil then
        return
    end

    local scrollBox = LFGListFrame.ApplicationViewer.ScrollBox

    if scrollBox == nil or scrollBox.GetFrames == nil then
        return
    end

    local applicantNames = BuildApplicantNameLookup()

    HideOldButtons(scrollBox)

    local frames = scrollBox:GetFrames()

    for _, applicantFrame in ipairs(frames) do
        AddButtonToApplicantFrame(applicantFrame, applicantNames)
    end
end

-- Manual test command.
-- Example: /bwcl Chappys-Frostmourne
SLASH_BOTTLEOWCL1 = "/bwcl"

SlashCmdList["BOTTLEOWCL"] = function(msg)
    if msg == nil or msg == "" then
        print("|cffffff00Usage: /bwcl Character-Realm|r")
        return
    end

    ShowWarcraftLogsPopup(msg)
end

-- Manual refresh command for LFG applicant buttons.
SLASH_BOTTLEOWCLREFRESH1 = "/wclcheck"

SlashCmdList["BOTTLEOWCLREFRESH"] = function()
    UpdateApplicantButtons()
    print("|cff00ff00Bottleo WCL Check: Refreshed LFG applicant buttons.|r")
end

-- Register events so the addon updates when applicants change.
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")

eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0.2, UpdateApplicantButtons)
end)

print("|cff00ff00Bottleo WCL Check loaded. Use /bwcl Character-Realm to test, or /wclcheck in LFG.|r")
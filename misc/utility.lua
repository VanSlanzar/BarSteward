local BS = _G.BarSteward

function BS.SecondsToTime(seconds, hideDays, hideHours, hideSeconds, format, hideDaysWhenZero)
    local time = ""
    local days = math.floor(seconds / 86400)
    local remaining = seconds
    local hideWhenZeroDays = hideDaysWhenZero == true and days == 0

    hideDays = hideDays or hideWhenZeroDays

    if (days > 0) then
        remaining = seconds - (days * 86400)
    end

    local hours = math.floor(remaining / 3600)

    if (hours > 0) then
        remaining = remaining - (hours * 3600)
    end

    local minutes = math.floor(remaining / 60)

    if (minutes > 0) then
        remaining = remaining - (minutes * 60)
    end

    remaining = math.floor(remaining)

    if ((format or "01:12:04:10") ~= "01:12:04:10" and format ~= "01:12:04") then
        if (hideSeconds) then
            if (hideDays) then
                time = ZO_CachedStrFormat(_G.BARSTEWARD_TIMER_FORMAT_TEXT_NO_DAYS, hours, minutes)
            else
                time = ZO_CachedStrFormat(_G.BARSTEWARD_TIMER_FORMAT_TEXT, days, hours, minutes)
            end
        else
            if (hideDays) then
                time =
                    ZO_CachedStrFormat(_G.BARSTEWARD_TIMER_FORMAT_TEXT_WITH_SECONDS_NO_DAYS, hours, minutes, remaining)
            else
                time = ZO_CachedStrFormat(_G.BARSTEWARD_TIMER_FORMAT_TEXT_WITH_SECONDS, days, hours, minutes, remaining)
            end
        end
    else
        if (not hideDays) then
            time = string.format("%02d", days) .. ":"
        end

        if (not hideHours) then
            time = time .. string.format("%02d", hours) .. ":"
        end

        time = time .. string.format("%02d", minutes)

        if (not hideSeconds) then
            time = time .. ":" .. string.format("%02d", remaining)
        end
    end

    return time
end

function BS.SetLockState(frame, lock)
    local lockNormal = "/esoui/art/miscellaneous/unlocked_up.dds"
    local lockPressed = "/esoui/art/miscellaneous/unlocked_down.dds"
    local lockMouseOver = "/esoui/art/miscellaneous/unlocked_over.dds"

    if (lock) then
        lockNormal = "/esoui/art/miscellaneous/locked_up.dds"
        lockPressed = "/esoui/art/miscellaneous/locked_down.dds"
        lockMouseOver = "/esoui/art/miscellaneous/locked_over.dds"
    end

    frame.lock:SetNormalTexture(lockNormal)
    frame.lock:SetPressedTexture(lockPressed)
    frame.lock:SetMouseOverTexture(lockMouseOver)
end

-- from https://wowwiki-archive.fandom.com/wiki/USERAPI_ColorGradient
function BS.Gradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select("#", ...) - 2, ...)
        return r, g, b
    elseif perc <= 0 then
        local r, g, b = ...
        return r, g, b
    end

    local num = select("#", ...) / 3

    local segment, relperc = math.modf(perc * (num - 1))
    local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)

    return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

-- Return a formatted time
-- from https://esoui.com/forums/showthread.php?t=4507
function BS.FormatTime(format, timeString, tamrielTime)
    -- split up default timestamp
    local hours, minutes, seconds

    if (tamrielTime) then
        hours, minutes, seconds = tamrielTime.hour, tamrielTime.minute, tamrielTime.second

        if (tostring(minutes):len() == 1) then
            minutes = "0" .. minutes
        end

        if (tostring(seconds):len() == 1) then
            seconds = "0" .. seconds
        end
    else
        timeString = timeString or GetTimeString()
        hours, minutes, seconds = timeString:match("([^%:]+):([^%:]+):([^%:]+)")
    end

    local hoursNoLead = tonumber(hours) -- hours without leading zero
    local hours12NoLead = (hoursNoLead - 1) % 12 + 1
    local hours12

    if (hours12NoLead < 10) then
        hours12 = "0" .. hours12NoLead
    else
        hours12 = hours12NoLead
    end

    local pUp = "AM"
    local pLow = "am"

    if (hoursNoLead >= 12) then
        pUp = "PM"
        pLow = "pm"
    end

    -- create new one
    local time = format
    time = time:gsub("HH", hours)
    time = time:gsub("H", hoursNoLead)
    time = time:gsub("hh", hours12)
    time = time:gsub("h", hours12NoLead)
    time = time:gsub("m", minutes)
    time = time:gsub("s", seconds)
    time = time:gsub("A", pUp)
    time = time:gsub("a", pLow)

    return time
end

function BS.ToPercent(qty, total)
    local pc = tonumber(qty) / tonumber(total)
    pc = math.floor(pc * 100)

    return pc
end

-- from LibEventHandler
-- avoids requiring the library (addon is already released)
-- needed to allow multiple functions to be registered against an event
local eventFunctions = {}

local function callEventFunctions(event, ...)
    if (#eventFunctions[event] == 0) then
        return
    end

    for i = 1, #eventFunctions[event] do
        eventFunctions[event][i](event, ...)
    end
end

local function registerForEvent(event, func)
    if (event == nil or func == nil) then
        return
    end

    if (not eventFunctions[event]) then
        eventFunctions[event] = {}
    end

    if (#eventFunctions[event] ~= 0) then
        local numOfFuncs = #eventFunctions[event]

        for i = 1, numOfFuncs do
            if (eventFunctions[event][i] == func) then
                return false
            end
        end

        eventFunctions[event][numOfFuncs + 1] = func

        return false
    else
        eventFunctions[event][1] = func

        return true
    end
end

function BS.RegisterForEvent(event, func)
    local needsRegistration = registerForEvent(event, func)

    if (needsRegistration) then
        EVENT_MANAGER:RegisterForEvent(BS.Name, event, callEventFunctions)
    end
end

local function unregisterForEvent(event, func)
    if (event == nil or func == nil) then
        return
    end

    if (#eventFunctions[event] ~= 0) then
        local numOfFuncs = #eventFunctions[event]
        for i = 1, numOfFuncs, 1 do
            if eventFunctions[event][i] == func then
                eventFunctions[event][i] = eventFunctions[event][numOfFuncs]
                eventFunctions[event][numOfFuncs] = nil

                numOfFuncs = numOfFuncs - 1

                if numOfFuncs == 0 then
                    return true
                end

                return false
            end
        end

        return false
    else
        return false
    end
end

function BS.UnregisterForEvent(event, func)
    local needsUnregistration = unregisterForEvent(event, func)

    if (needsUnregistration) then
        EVENT_MANAGER:UnregisterForEvent(BS.Name, event)
    end
end

--- end events

-- timers
-- simplifies enabling/disabling all timers at once
local timerFunctions = {}

local function callTimerFunctions(time)
    if (#timerFunctions[time] == 0) then
        return
    end

    for i = 1, #timerFunctions[time] do
        timerFunctions[time][i]()
    end
end

local function registerForUpdate(time, func)
    if (time == nil or func == nil) then
        return
    end

    if (not timerFunctions[time]) then
        timerFunctions[time] = {}
    end

    if (#timerFunctions[time] ~= 0) then
        local numOfFuncs = #timerFunctions[time]

        for i = 1, numOfFuncs do
            if (timerFunctions[time][i] == func) then
                return false
            end
        end

        timerFunctions[time][numOfFuncs + 1] = func

        return false
    else
        timerFunctions[time][1] = func

        return true
    end
end

function BS.RegisterForUpdate(time, func)
    local needsRegistration = registerForUpdate(time, func)

    if (needsRegistration) then
        EVENT_MANAGER:RegisterForUpdate(
            BS.Name .. tostring(time),
            time,
            function()
                callTimerFunctions(time)
            end
        )
    end
end

local function unregisterForUpdate(time, func)
    if (time == nil or func == nil) then
        return
    end

    if (#timerFunctions[time] ~= 0) then
        local numOfFuncs = #timerFunctions[time]
        for i = 1, numOfFuncs, 1 do
            if (timerFunctions[time][i] == func) then
                timerFunctions[time][i] = timerFunctions[time][numOfFuncs]
                timerFunctions[time][numOfFuncs] = nil

                numOfFuncs = numOfFuncs - 1

                if (numOfFuncs == 0) then
                    return true
                end

                return false
            end
        end

        return false
    else
        return false
    end
end

function BS.UnregisterForUpdate(time, func)
    local needsUnregistration = unregisterForUpdate(time, func)

    if (needsUnregistration) then
        EVENT_MANAGER:UnregisterForUpdate(BS.Name .. tostring(time), time)
    end
end

function BS.DisableUpdates()
    for time, funcs in pairs(timerFunctions) do
        if (#funcs ~= 0) then
            EVENT_MANAGER:UnregisterForUpdate(string.format("%s%s", BS.Name, tostring(time)))
        end
    end
end

function BS.EnableUpdates()
    for time, funcs in pairs(timerFunctions) do
        if (#funcs ~= 0) then
            EVENT_MANAGER:RegisterForUpdate(
                string.format("%s%s", BS.Name, tostring(time)),
                time,
                function()
                    callTimerFunctions(time)
                end
            )
        end
    end
end
-- end timers

function BS.CheckPerformance(inCombat)
    if (BS.Vars.DisableTimersInCombat) then
        if (inCombat == nil) then
            inCombat = IsUnitInCombat("player")
        end

        if (inCombat and BS.disabledTimers == nil) then
            BS.DisableUpdates()
            BS.disabledTimers = true
        elseif (BS.disabledTimers ~= nil) then
            BS.EnableUpdates()
            BS.disabledTimers = nil
        end
    else
        if (BS.disabledTimers ~= nil) then
            BS.EnableUpdates()
            BS.disabledTimers = nil
        end
    end
end

function BS.ARGBConvert(argb)
    local r = string.format("%02x", math.floor(argb[1] * 255))
    local g = string.format("%02x", math.floor(argb[2] * 255))
    local b = string.format("%02x", math.floor(argb[3] * 255))

    return "|c" .. r .. g .. b
end

function BS.ARGBConvert2(argb)
    return BS.ARGBConvert({argb.r, argb.g, argb.b})
end

function BS.GetAnchorFromText(text, adjust)
    if (text == GetString(_G.BARSTEWARD_LEFT)) then
        if (adjust) then
            return TOPLEFT
        end

        return LEFT
    end

    if (text == GetString(_G.BARSTEWARD_RIGHT)) then
        if (adjust) then
            return TOPRIGHT
        end

        return RIGHT
    end

    if (text == GetString(_G.BARSTEWARD_TOP)) then
        return TOP
    end

    if (text == GetString(_G.BARSTEWARD_BOTTOM)) then
        return BOTTOM
    end

    return CENTER
end

function BS.AddSeparators(number)
    local grouping = tonumber(GetString(_G.BARSTEWARD_NUMBER_GROUPING))
    local separator = BS.Vars.NumberSeparator or GetString(_G.BARSTEWARD_NUMBER_SEPARATOR)

    if type(number) ~= "number" or number < 0 or number == 0 or not number then
        return number
    else
        local t = {}
        local int = math.floor(number)

        if int == 0 then
            t[#t + 1] = 0
        else
            local digits = math.log10(int)
            local segments = math.floor(digits / grouping)
            local groups = 10 ^ grouping
            t[#t + 1] = math.floor(int / groups ^ segments)
            for i = segments - 1, 0, -1 do
                t[#t + 1] = separator
                t[#t + 1] = ("%0" .. grouping .. "d"):format(math.floor(int / groups ^ i) % groups)
            end
        end

        local s = table.concat(t)

        return s
    end
end

-- based on Wykkyd toolbar
function BS.NudgeCompass()
    local bar1Top = _G[BS.Name .. "_bar_1"]:GetTop()

    if (bar1Top <= 80) then
        if (ZO_CompassFrame:GetTop() ~= bar1Top + 70) then
            ZO_CompassFrame:ClearAnchors()
            ZO_CompassFrame:SetAnchor(TOP, GuiRoot, TOP, 0, bar1Top + 70)
            ZO_TargetUnitFramereticleover:ClearAnchors()
            ZO_TargetUnitFramereticleover:SetAnchor(TOP, GuiRoot, TOP, 0, bar1Top + 118)
        end
    elseif (bar1Top <= 100) then
        ZO_TargetUnitFramereticleover:ClearAnchors()
        ZO_TargetUnitFramereticleover:SetAnchor(TOP, GuiRoot, TOP, 0, bar1Top + 50)
    else
        if ZO_CompassFrame:GetTop() ~= 40 then
            ZO_CompassFrame:ClearAnchors()
            ZO_CompassFrame:SetAnchor(TOP, GuiRoot, TOP, 0, 40)
            ZO_TargetUnitFramereticleover:ClearAnchors()
            ZO_TargetUnitFramereticleover:SetAnchor(TOP, GuiRoot, TOP, 0, 88)
        end
    end
end

function BS.IsTraitResearchComplete(craftingType)
    local complete = true

    for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do
        local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)

        for traitIndex = 1, numTraits do
            local _, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)

            if (not known) then
                return false
            end
        end
    end

    return complete
end

function BS.Split(s, delimiter)
    local result = {}

    delimiter = delimiter or ","

    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end

    return result
end

function BS.Join(values)
    local outputTable = {}

    for value, _ in pairs(values) do
        table.insert(outputTable, ZO_FormatUserFacingCharacterName(value))
    end

    return table.concat(outputTable, ", ")
end

function BS.Announce(header, message, widgetIconNumber, lifespan, sound, otherIcon)
    local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(_G.CSA_CATEGORY_LARGE_TEXT)

    messageParams:SetSound(sound or "Justice_NowKOS")
    messageParams:SetText(header or "Test Header", message or "Test Message")
    messageParams:SetLifespanMS(lifespan or 6000)
    messageParams:SetCSAType(_G.CENTER_SCREEN_ANNOUNCE_TYPE_SYSTEM_BROADCAST)

    if (widgetIconNumber) then
        messageParams:SetIconData(
            otherIcon or BS.widgets[widgetIconNumber].icon,
            "/esoui/art/achievements/achievements_iconbg.dds"
        )
    end

    CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
end

-- ensure all widget ordering is in a continuous
-- ordered sequence within the bar
function BS.CleanUpBarOrder(barNumber)
    local barTable = {}
    local controls = BS.Vars.Controls

    for key, control in pairs(controls) do
        if (control.Bar == barNumber) then
            table.insert(barTable, {key = key, control = control})
        end
    end

    table.sort(
        barTable,
        function(a, b)
            return a.control.Order < b.control.Order
        end
    )

    -- resequence the controls
    local index = 1
    for _, controlData in pairs(barTable) do
        controls[controlData.key].Order = index
        index = index + 1
    end
end

function BS.GetFont(vars)
    local font = BS.FONTS[BS.Vars.Font]
    local size = BS.Vars.FontSize

    if (vars) then
        if (vars.Font) then
            font = BS.FONTS[vars.Font]
        end

        if (vars.FontSize) then
            size = vars.FontSize
        end
    end

    local hasShadow = "|soft-shadow-thin"

    if (font and size) then
        return font .. "|" .. size .. hasShadow
    else
        return ""
    end
end

function BS.AddToScenes(sceneType, barIndex, bar, override)
    local group = BS[sceneType:upper() .. "_SCENES"]

    sceneType = "ShowWhilst" .. sceneType

    if (BS.Vars.Bars[barIndex][sceneType] or override) then
        for _, scene in ipairs(group) do
            SCENE_MANAGER:GetScene(scene):AddFragment(bar.fragment)
        end
    end
end

function BS.RemoveFromScenes(sceneType, bar)
    local group = BS[sceneType:upper() .. "_SCENES"]

    for _, scene in ipairs(group) do
        SCENE_MANAGER:GetScene(scene):RemoveFragment(bar.fragment)
    end
end

function BS.VersionDelta(version)
    local currentVersion = BS.VERSION:gsub("%.", "")
    local checkVersion = version:gsub("%.", "")

    return tonumber(currentVersion) - tonumber(checkVersion)
end

function BS.RefreshWidget(widgetIndex)
    if (BS.Vars.Controls[widgetIndex].Bar ~= 0) then
        local widget = _G[BS.Name .. "_Widget_" .. BS.widgets[widgetIndex].name]

        if (widget ~= nil) then
            BS.widgets[widgetIndex].update(widget.ref, "initial")
        end
    end
end

function BS.RefreshBar(widgetIndex)
    if (BS.Vars.Controls[widgetIndex].Bar ~= 0) then
        local widget = _G[BS.Name .. "_Widget_" .. BS.widgets[widgetIndex].name]

        if (widget ~= nil) then
            local bar = widget.ref.control:GetParent().ref
            local metadata = BS.widgets[widgetIndex]
            metadata.widget = widget.ref
            bar:DoUpdate(metadata)
        end
    end
end

function BS.RefreshAll()
    for widgetIndex in pairs(BS.Vars.Controls) do
        BS.RefreshWidget(widgetIndex)
    end
end

function BS.Repeat(input, times)
    local output = {}

    for _ = 1, times do
        table.insert(output, input)
    end

    return output
end

function BS.MakeItemLink(itemId, name)
    return ZO_LinkHandler_CreateLink(name or "", nil, _G.ITEM_LINK_TYPE, itemId, unpack(BS.Repeat(0, 20)))
end

function BS.Trim(stringValue)
    return stringValue:gsub("^%s*(.-)%s*$", "%1")
end

function BS.MergeTables(t1, t2)
    local output = {}

    for _, value in ipairs(t1) do
        output[#output + 1] = value
    end

    for _, value in ipairs(t2) do
        output[#output + 1] = value
    end

    return output
end

function BS.Filter(t, filterFunc)
    local out = {}

    for k, v in pairs(t) do
        if (filterFunc(v, k, t)) then
            table.insert(out, v)
        end
    end

    return out
end

function BS.ResizeBar(barIndex)
    if ((barIndex or 0) == 0) then
        return
    end

    local bar = _G[BS.Name .. "_bar_" .. barIndex].ref.bar

    bar:SetResizeToFitDescendents(false)
    bar:SetDimensions(0, 0)
    bar:SetResizeToFitDescendents(true)

    -- check for hidden widgets
    local allHidden = true

    for index, widget in pairs(BS.Vars.Controls) do
        if (widget.Bar == barIndex) then
            local w = _G[string.format("%s_Widget_%s", BS.Name, BS.widgets[index].name)]

            if (w and not w.ref.isHidden) then
                allHidden = false
                break
            end
        end
    end

    -- if the bar is hidden, hide the border
    if (allHidden) then
        bar.border:SetEdgeTexture("", 128, 2)
        bar.border:SetEdgeColor(0, 0, 0, 0)
    elseif (bar.ToggleState ~= "hidden") then
        if ((BS.Vars.Bars[barIndex].Border or 99) ~= 99) then
            bar.border:SetEdgeTexture(unpack(BS.BORDERS[BS.Vars.Bars[barIndex].Border]))
            bar.border:SetEdgeColor(1, 1, 1, 1)
        end
    end
end

local itemColours = {}

do
    for quality = _G.ITEM_DISPLAY_QUALITY_TRASH, _G.ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE do
        itemColours[quality] = {GetInterfaceColor(_G.INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)}
    end
end

function BS.ColourToQuality(r, g, b)
    for quality, rgba in pairs(itemColours) do
        local rc, gc, bc = math.floor(rgba[1] * 100), math.floor(rgba[2] * 100), math.floor(rgba[3] * 100)
        local ri, gi, bi = math.floor(r * 100), math.floor(g * 100), math.floor(b * 100)

        if (rc == ri and gc == gi and bc == bi) then
            return quality
        end
    end
end

function BS.ColourToIcon(r, g, b)
    local quality = BS.ColourToQuality(r, g, b, 1)

    return BS.ITEM_COLOUR_ICON[quality or 1]
end

local function setSubjectAndBody(subject, body, recipient)
    local bodyField, subjectField, recipientField

    if (IsInGamepadPreferredMode()) then
        bodyField = MAIL_MANAGER_GAMEPAD:GetSend().mailView.bodyEdit.edit
        subjectField = MAIL_MANAGER_GAMEPAD:GetSend().mailView.subjectEdit.edit
        recipientField = MAIL_MANAGER_GAMEPAD:GetSend().mailView.addressEdit.edit
    else
        bodyField = ZO_MailSendBodyField
        subjectField = ZO_MailSendSubjectField
        recipientField = ZO_MailSendToField
    end

    recipientField:SetText(recipient)
    subjectField:SetText(subject)
    bodyField:SetText(bodyField:GetText() .. body)
end

local function composeMail(subject, body, recipient)
    local mailManager

    if (IsInGamepadPreferredMode()) then
        mailManager = MAIL_MANAGER_GAMEPAD:GetSend()
        BS.mailScene = "mailManagerGamepad"
    else
        mailManager = MAIL_SEND
        BS.mailScene = "mailSend"
    end

    mailManager:ClearFields()

    if (SCENE_MANAGER:IsShowing(BS.mailScene)) then
        setSubjectAndBody(subject, body, recipient)
    else
        mailManager:ComposeMailTo(recipient or "")
        SCENE_MANAGER:CallWhen(
            BS.mailScene,
            _G.SCENE_SHOWN,
            function()
                setSubjectAndBody(subject, body, recipient)
            end
        )
    end

    return mailManager
end

function BS.SendMail(subject, body, recipient)
    local mailManager = composeMail(subject, body, recipient)

    zo_callLater(
        function()
            mailManager:Send()
            zo_callLater(
                function()
                    BS.CloseMail()
                end,
                500
            )
        end,
        500
    )
end

function BS.CloseMail()
    if (SCENE_MANAGER:IsShowing(BS.mailScene)) then
        SCENE_MANAGER:Hide(BS.mailScene)
    end
end

-- get then next unused index number from the table's values
function BS.GetNextIndex(t)
    local nextIndex = 1

    table.sort(
        t,
        function(a, b)
            return a < b
        end
    )

    for _, value in pairs(t) do
        if (value ~= nextIndex) then
            return nextIndex
        end
        nextIndex = nextIndex + 1
    end

    return nextIndex
end

function BS.GetByValue(t, v)
    for key, value in pairs(t) do
        if (type(value) == "table") then
            if (ZO_IsElementInNumericallyIndexedTable(value, v)) then
                return key
            end
        elseif (value == v) then
            return key
        end
    end
end

function BS.GetWritType(itemId)
    for key, itemIds in pairs(BS.WRITS) do
        for _, id in pairs(itemIds) do
            if (id == itemId) then
                return key
            end
        end
    end

    return 0
end

function BS.ToWritFields(item_link)
    local parsedLink = {ZO_LinkHandler_ParseLink(item_link)}
    local bsValues = {
        itemId = tonumber(parsedLink[4]),
        writType = BS.GetWritType(tonumber(parsedLink[4])),
        subType = tonumber(parsedLink[5]),
        itemType = BS.GetByValue(BS.WRIT_ITEM_TYPES, tonumber(parsedLink[10])) or 0,
        itemQuality = tonumber(parsedLink[12]),
        motifNumber = tonumber(parsedLink[15])
    }

    return bsValues
end

function BS.Format(value, ...)
    local text = value

    if (type(value) == "number") then
        text = GetString(value)
    end

    return ZO_CachedStrFormat("<<C:1>>", text, ...)
end

-- https://gist.github.com/tylerneylon/81333721109155b2d244
local function deepCopy(obj, seen)
    if (type(obj) ~= "table") then
        return obj
    end

    if (seen and seen[obj]) then
        return seen[obj]
    end

    local s = seen or {}
    local res = {}

    s[obj] = res

    for k, v in pairs(obj) do
        res[deepCopy(k, s)] = deepCopy(v, s)
    end

    return setmetatable(res, getmetatable(obj))
end

function BS.SimpleTableCompare(t1, t2)
    return table.concat(t1) == table.concat(t2)
end

function BS.CompareColours(c1, c2)
    local colours = {c1, c2}

    -- just compare colours down to 3 decimal places
    for _, colour in ipairs(colours) do
        for idx, value in pairs(colour) do
            local rounded = tonumber(string.format("%.3g", value))
            colour[idx] = rounded
        end
    end

    return BS.SimpleTableCompare(c1, c2)
end

function BS.Count(input, searchFor)
    local _, count = input:gsub(searchFor, "")

    return count
end

local function addQuotes(value, sub)
    return '"' .. GetString(value, sub) .. '"'
end

local function cleanseAndEncode(input)
    local output = input

    output = output:gsub("#true%^", "#t%^")
    output = output:gsub("#false%^", "#f%^")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_VERTICAL), "#v")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_HORIZONTAL), "#h")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_LEFT), "#l")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_RIGHT), "#r")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_TOP), "#to")
    output = output:gsub("#" .. addQuotes(_G.BARSTEWARD_BOTTOM), "#b")

    for bg = 1, 14 do
        output = output:gsub("#" .. addQuotes("BARSTEWARD_BACKGROUND_STYLE_", bg), "#bg" .. tostring(bg))

        if (bg < 8) then
            output = output:gsub("#" .. addQuotes("BARSTEWARD_BORDER_STYLE_", bg), "#bo" .. tostring(bg))
        end
    end

    return output
end

local function decode(input)
    local output = input:gsub("#t%^", "#true%^")

    output = output:gsub("#f%^", "#false%^")
    output = output:gsub("#v", "#" .. addQuotes(_G.BARSTEWARD_VERTICAL))
    output = output:gsub("#h", "#" .. addQuotes(_G.BARSTEWARD_HORIZONTAL))
    output = output:gsub("#l", "#" .. addQuotes(_G.BARSTEWARD_LEFT))
    output = output:gsub("#r", "#" .. addQuotes(_G.BARSTEWARD_RIGHT))
    output = output:gsub("#to", "#" .. addQuotes(_G.BARSTEWARD_TOP))
    output = output:gsub("#b", "#" .. addQuotes(_G.BARSTEWARD_BOTTOM))

    for bg = 1, 14 do
        output = output:gsub("#bg" .. tostring(bg), "#" .. addQuotes("BARSTEWARD_BACKGROUND_STYLE_", bg))

        if (bg < 8) then
            output = output:gsub("#bo" .. tostring(bg), "#" .. addQuotes("BARSTEWARD_BORDER_STYLE_", bg))
        end
    end

    for keyword, abbr in pairs(BS.ENCODING) do
        output = output:gsub("::" .. abbr .. "#", "::" .. keyword .. "#")
        output = output:gsub("%^" .. abbr .. "#", "%^" .. keyword .. "#")
    end

    return output
end

local function convert(value)
    if (not value) then
        return
    end

    if (value == "true") then
        return true
    end

    if (value == "false") then
        return false
    end

    local count = BS.Count(value, "%-")

    if (count == 3) then
        local array = BS.Split(value, "%-")

        for index, val in pairs(array) do
            val = val:gsub("%%", "")
            array[index] = tonumber(val)
        end

        return array
    end

    if (tonumber(value)) then
        return tonumber(value)
    end

    return value
end

local function generateTable(input)
    assert(input:sub(1, 3) == "b::", GetString(_G.BARSTEWARD_IMPORT_ERROR_BAR))
    assert(input:sub(-1) == "^", GetString(_G.BARSTEWARD_IMPORT_ERROR_DATA))
    assert(input:find("w::"), GetString(_G.BARSTEWARD_IMPORT_ERROR_WIDGET))

    local widgetStartPos = input:find("w::")
    local barData = BS.Split(input:sub(4, widgetStartPos - 1), "%^")
    local widgetData = BS.Split(input:sub(widgetStartPos + 3), "%^")

    local barObject = {}

    -- convert bar data to a table
    for _, token in pairs(barData) do
        local info = BS.Split(token, "#")

        if (info[1]) then
            -- check for backdrop.colour
            if (info[1] == string.format("%s_%s", BS.ENCODING["Backdrop"], BS.ENCODING["Colour"])) then
                -- check for backdrop.show
                barObject.Backdrop = {Colour = convert(info[2])}
            elseif (info[1] == string.format("%s_%s", BS.ENCODING["Backdrop"], BS.ENCODING["Show"])) then
                barObject.Backdrop = {Show = convert(info[2])}
            else
                barObject[info[1]] = convert(info[2])
            end
        end
    end

    -- convert widget data to a table
    local currentWidget
    local widgetsObject = {}

    for _, token in pairs(widgetData) do
        local info = BS.Split(token, "#")

        if (info[1] and info[1] ~= "%") then
            if (info[1]:sub(1, 1) == "@") then
                currentWidget = tonumber(info[1]:sub(2))
                widgetsObject[currentWidget] = {}
            elseif (currentWidget) then
                widgetsObject[currentWidget][info[1]] = convert(info[2])
            end
        end
    end

    return {
        Bar = barObject,
        Widgets = widgetsObject
    }
end

function BS.ExportBar(barNumber)
    local destBar = deepCopy(BS.Vars.Bars[barNumber])

    -- remove any default values, no point keeping those
    for k, v in pairs(destBar) do
        if (type(v) ~= "table") then
            if (v == BS.Defaults.Bars[1][k]) then
                destBar[k] = nil
            end
        end
    end

    if (destBar.Backdrop.Colour) then
        if (BS.SimpleTableCompare(destBar.Backdrop.Colour, BS.Defaults.Bars[1].Backdrop.Colour)) then
            destBar.Backdrop.Colour = nil
        end
    end

    if (destBar.Backdrop.Show) then
        if (destBar.Backdrop.Show == BS.Defaults.Bars[1].Backdrop.Show) then
            destBar.Backdrop.Show = nil
        end
    end

    if (destBar.CombatColour) then
        if (BS.SimpleTableCompare(destBar.CombatColour, BS.Defaults.DefaultCombatColour)) then
            destBar.CombatColour = nil
        end
    end

    -- don't copy unneeded values
    destBar.Position = nil
    destBar.Name = nil
    destBar.ToggleState = nil
    destBar.HideBarEnable = nil
    destBar.Disable = nil

    local forExport = {
        Bar = destBar,
        Controls = {}
    }

    -- copy the widgets
    for widgetIndex, widgetSettings in pairs(BS.Vars.Controls) do
        -- ignore housing widgets - they are too client specific
        if (widgetIndex < 1000) then
            if (widgetSettings.Bar == barNumber) then
                forExport.Controls[widgetIndex] = deepCopy(widgetSettings)
                forExport.Controls[widgetIndex].Bar = nil
                forExport.Controls[widgetIndex].Exclude = nil

                -- remove any default values, no point keeping those
                for k, v in pairs(forExport.Controls[widgetIndex]) do
                    if (type(v) ~= "table") then
                        if (v == BS.Defaults.Controls[widgetIndex][k]) then
                            forExport.Controls[widgetIndex][k] = nil
                        end
                    end
                end
            end
        end
    end

    local output = "b::"

    -- add bar info
    for key, value in pairs(forExport.Bar) do
        if (key == "Backdrop") then
            if (forExport.Bar.Backdrop.Colour) then
                output =
                    output ..
                    string.format(
                        "%s_%s#%.3g-%.3g-%.3g-%.3g^",
                        BS.ENCODING["Backdrop"],
                        BS.ENCODING["Colour"],
                        forExport.Bar.Backdrop.Colour[1],
                        forExport.Bar.Backdrop.Colour[2],
                        forExport.Bar.Backdrop.Colour[3],
                        forExport.Bar.Backdrop.Colour[4]
                    )
            end

            if (forExport.Bar.Backdrop.Show) then
                output =
                    output ..
                    string.format(
                        "%s_%s#%s",
                        BS.ENCODING["Backdrop"],
                        BS.ENCODING["Show"],
                        tostring(forExport.Bar.Backdrop.Show)
                    )
            end
        elseif (key == "CombatColour") then
            if (forExport.Bar.CombatColour) then
                output =
                    output ..
                    string.format(
                        "%s#%.3g-%.3g-%.3g-%.3g^",
                        BS.ENCODING["CombatColour"],
                        forExport.Bar.CombatColour[1],
                        forExport.Bar.CombatColour[2],
                        forExport.Bar.CombatColour[3],
                        forExport.Bar.CombatColour[4]
                    )
            end
        else
            output = output .. string.format("%s#%s^", BS.ENCODING[key] or key, tostring(value))
        end
    end

    -- add widget info
    output = output .. "w::"

    for widgetIndex, widgetInfo in pairs(forExport.Controls) do
        output = output .. string.format("@%d^", widgetIndex)

        for key, value in pairs(widgetInfo) do
            if (key:sub(-6) == "Colour" and key ~= "NoLimitColour") then
                output =
                    output ..
                    string.format(
                        "%s#%.3g-%.3g-%.3g-%.3g^",
                        BS.ENCODING[key],
                        forExport.Controls[widgetIndex][key][1],
                        forExport.Controls[widgetIndex][key][2],
                        forExport.Controls[widgetIndex][key][3],
                        forExport.Controls[widgetIndex][key][4]
                    )
            else
                output = output .. string.format("%s#%s^", BS.ENCODING[key] or key, tostring(value))
            end
        end
    end

    output = cleanseAndEncode(output)

    return output
end

local function cleanAssert(message)
    message = message:gsub("assert: ", "")

    local stacktraceStart = message:find("stack traceback")

    message = message:sub(1, stacktraceStart - 1)

    return message
end

local function validate(data)
    local status, decoded = pcall(decode, data)

    if (not status) then
        BS.ExportFrame.error:SetText(cleanAssert(decoded))
        return
    end

    local tableStatus, importTable = pcall(generateTable, decoded)

    if ((not tableStatus) or type(importTable) ~= "table") then
        BS.ExportFrame.error:SetText(cleanAssert(importTable))
        return
    end

    if (importTable.Bar == nil or importTable.Widgets == nil) then
        BS.ExportFrame.error:SetText(GetString(_G.BARSTEWARD_IMPORT_ERROR_WIDGET_OR_BAR))
        return
    end

    BS.ExportFrame.fragment:SetHiddenForReason("disabled", true)

    return importTable
end

function BS.DoImport()
    local data = BS.ImportData
    local bars = BS.Vars.Bars
    local newBarId = #bars + 1
    local barname = zo_strformat(GetString(_G.BARSTEWARD_NEW_BAR_DEFAULT_NAME), newBarId)
    local x, y = GuiRoot:GetCenter()

    BS.Vars.Bars[newBarId] = {
        Orientation = GetString(_G.BARSTEWARD_HORIZONTAL),
        Position = {X = x, Y = y},
        Name = barname,
        Backdrop = {
            Show = data.Bar.Backdrop and data.Bar.Backdrop.Show or true,
            Colour = data.Bar.Backdrop and data.Bar.Backdrop.Colour or {0.23, 0.23, 0.23, 0.7}
        },
        TooltipAnchor = GetString(_G.BARSTEWARD_BOTTOM),
        ValueSide = GetString(_G.BARSTEWARD_RIGHT)
    }

    for key, value in pairs(data.Bar) do
        if (key ~= "Backdrop") then
            BS.Vars.Bars[newBarId][key] = value
        end
    end

    -- add widgets to the bar
    for widgetIndex, widgetData in pairs(data.Widgets) do
        BS.Vars.Controls[widgetIndex].Bar = newBarId

        for key, value in pairs(widgetData) do
            BS.Vars.Controls[widgetIndex][key] = value
        end
    end

    --reload ui
    zo_callLater(
        function()
            ZO_Dialogs_ShowDialog(BS.Name .. "Reload")
        end,
        500
    )
end

function BS.ImportBar(data)
    local importTable = validate(data)

    if (importTable) then
        -- check widget movement
        local widgetCount = 0

        for widgetIndex, _ in pairs(importTable.Widgets) do
            if (BS.Vars.Controls[widgetIndex].Bar ~= 0) then
                widgetCount = widgetCount + 1
            end
        end

        BS.ImportData = importTable

        if (widgetCount > 0) then
            BS.MovingWidgets = widgetCount
            ZO_Dialogs_ShowDialog(BS.Name .. "Import")
        else
            BS.DoImport()
        end
    end
end

function BS.GetNearest(input, factor)
    local remaining = input % factor
    local lower = input - remaining
    local upper = lower + factor
    local result = lower

    if ((input - lower) > (upper - input)) then
        result = upper
    end

    return result
end

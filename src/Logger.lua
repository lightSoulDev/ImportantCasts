Global("LOGGER", {})

local function log(message, class)
    message = string.format("[%s]: %s", LOGGER.name, message)

    local textFormat = string.format("<html fontsize='16'><rs class='class'>%s</rs></html>", message)
    local VT = common.CreateValuedText()
    VT:SetFormat(ToWS(textFormat))
    if class == nil then
        class = "LogColorWhite"
    end
    VT:SetClassVal("class", class)
    local chatContainer = stateMainForm:GetChildUnchecked("ChatLog", false):GetChildUnchecked("Area", false)
        :GetChildUnchecked("Panel02", false):GetChildUnchecked("Container", false)
    chatContainer:PushFrontValuedText(VT)
end

function LOGGER.Init()
    LOGGER.name = common.GetAddonName()
    LOGGER.enabled = true
end

function Log(message)
    if LOGGER.enabled then
        log(message, nil)
    end
end

function Err(message)
    if LOGGER.enabled then
        log(message, "LogColorRed")
    end
end

function Warn(message)
    if LOGGER.enabled then
        log(message, "LogColorYellow")
    end
end

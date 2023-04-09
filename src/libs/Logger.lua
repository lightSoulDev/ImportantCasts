Global("LOGGER", {})

local function log(message, class)
    message = string.format("[%s]: %s", common.GetAddonName(), message)

    local textFormat = string.format("<html fontsize='16'><rs class='class'>%s</rs></html>", message)
    local VT = common.CreateValuedText()
    VT:SetFormat(userMods.ToWString(textFormat))
    if class == nil then
        class = "LogColorWhite"
    end
    VT:SetClassVal("class", class)
    local chatContainer = stateMainForm:GetChildUnchecked("ChatLog", false):GetChildUnchecked("Area", false)
        :GetChildUnchecked("Panel02", false):GetChildUnchecked("Container", false)
    chatContainer:PushFrontValuedText(VT)
end

function Log(message)
    log(message, nil)
end

function Err(message)
    log(message, "LogColorRed")
end

function Warn(message)
    log(message, "LogColorYellow")
end

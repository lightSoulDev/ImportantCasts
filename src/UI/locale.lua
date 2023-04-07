Global("LOCALES", {})

-- ger
-- fra
-- tr

function GetLocaleText(name)
    local lang = LANG or "rus"

    local l = LOCALES[lang]

    if l then
        return l[name] or name
    else
        return name
    end
end

LOCALES = {
    ["rus"] = {
        ["DMG_FALL"] = "�������",
        ["DMG_BARRIER"] = "�� �������",

        ["ButtonAccept"] = "�������",
        ["ButtonRestore"] = "��������",
        ["ButtonAdd"] = "��������",
        ["ButtonDelete"] = "�������",

        ["TAB_Common"] = "��������",
        ["TAB_Visual"] = "�����",
        ["TAB_Ignored"] = "�����.",
        ["TAB_ShowOnly"] = "�����.",

        ["GROUP_PanelSettings"] = "��������� �������",
        ["SETTING_IsClickable"] = "��������������",
    },
    ["eng_eu"] = {
        ["DMG_FALL"] = "Fall",
        ["DMG_BARRIER"] = "From barrier",
        ["ButtonAccept"] = "Accept",
        ["ButtonRestore"] = "Restore",
        ["ButtonAdd"] = "Add",
        ["ButtonDelete"] = "Delete",

        ["TAB_Common"] = "Common",
        ["TAB_Visual"] = "Colors",
        ["TAB_Ignored"] = "Ignore",

        ["GROUP_PanelSettings"] = "Panel settings",
        ["SETTING_IsClickable"] = "Enable clicking",
    }
}

LOCALES["eng"] = LOCALES["eng_eu"]

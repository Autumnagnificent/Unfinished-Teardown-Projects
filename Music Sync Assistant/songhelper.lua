#include "Automatic.lua"
#include "main.lua"

function ShowTrack(Song, t)
    UiPush()
        UiTranslate(UiCenter(), UiHeight() - 128)
        UiAlign('center middle')
        
        UiRect(3, 128)
    UiPop()
    
    for i, label in pairs(Song) do
        DrawOnScreen(label)
    end
end


function InbetweenLabel(label, lead)
    local ahead = label.From <= SongTime
    local behind = label.To + lead >= SongTime

    return ahead and behind
end

function DrawOnScreen(label)
    local TPFrom = label.From - SongTime
    local TPTo = label.To - SongTime
    local SPFrom = TPFrom * StretchUI + UiCenter()
    local SPTo = TPTo * StretchUI + UiCenter()

    if InbetweenLabel(label, 0.025) then
        UiColor(1, 1, 0, 1)
    else
        UiColor(0, 0, 0, 1)
    end

    UiAlign('center middle')

    -- From Dot
    UiPush()
        UiTranslate(SPFrom, UiHeight() - 128)
        AutoMarker(2, false)
    UiPop()
    
    -- To Dot
    UiPush()
        UiTranslate(SPTo, UiHeight() - 128)
        AutoMarker(2, false)
    UiPop()

    -- Fill
    UiPush()
        local size = 16
        UiTranslate(SPFrom, UiHeight() - 128 - size / 2)

        UiRect(AutoDist(SPFrom, SPTo), size)
    UiPop()
end

function TextToTrack(Text)
    local Track = {}
    
    local token = 
    for _, line in ipairs(Lines) do
        local split = AutoSplit(line, '\t')

        Track[#Track+1] = {
            From = tonumber(split[1]),
            To = tonumber(split[2]),
            Name = split[3],
        }
    end

    return Track
end
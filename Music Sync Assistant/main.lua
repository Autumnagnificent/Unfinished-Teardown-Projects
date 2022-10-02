#include "Automatic.lua"
#include "songhelper.lua"
#include "SongLabels.lua"

-- SONG PARAMS

LoadedSong = TextToTrack(TestA)

-- UI PARAM
StretchUI = 128

-- MEMORY
SongTime = 0

function init()
    UiSound('MOD/Songs/' .. 'TestA' .. '.ogg')
end

function draw(dt)
    ShowTrack(LoadedSong, SongTime)

    SongTime = SongTime + dt
end
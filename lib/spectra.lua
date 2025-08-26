-- Midi Fighter Spectra support.

local G = require "printer-jam-norns.lib.global"

local BASE_PITCH = 36

-- Colour table: e.g. `COLOURS.yellow.lo`. Each colour
-- maps to two MIDI velocities: `lo` and `hi`.

local COLOURS = { }

do
    local names = {
        "red", "orange", "yellow", "lime",
        "green", "cyan", "blue", "purple",
        "pink", "white"
    }

    for i = 1, #names do
        COLOURS[names[i]] = 1 + i * 12      -- Base pitch if we're doing vari-colour.
    end
end

-- x and y are 1..4, from top.
-- pos is 1..16, from bottom.

local function xy_to_pos(x, y)
    return (4 - y) * 4 + x
end

local function pos_to_xy(pos)
    local x = (pos - 1) % 4 + 1
    local row = 1 + math.floor((pos - 1) / 4)
    local y = 5 - row
    return x, y
end

--[[
    LED ring. `pos` is 1..16 (indexed from lower left
    of device). `colour` is MIDI velocity value for
    full colour. `level` is brightness, 0..15.
]]

local function light(pos, colour, level)
    local mf = G.midi.devices[G.midi.mf_target]
    local p = (pos + BASE_PITCH - 1)
    mf:note_on(p, colour, 3)
    mf:note_on(p, 18 + level, 4)
end

local function underside(how)
    local mf = G.midi.devices[G.midi.mf_target]
    
    for i = 16, 19 do      -- Pitches designating LEDs.
        if how then
            mf:note_on(i, 33, 4)
        else
            mf:note_on(i, 18, 4) -- There's no "off', just minimal "on".
        end
    end
end

return {
    BASE_PITCH = BASE_PITCH,        --  Start pitch of MIDI notes.
    COLOURS = COLOURS,
    pos_to_xy = pos_to_xy,
    xy_to_pos = xy_to_pos,
    light = light,
    underside = underside
}

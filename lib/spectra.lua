-- Midi Fighter Spectra support.

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

local function light(G, pos, colour, level)
    local mf = G.midi.devices[G.midi.mf_target]
    local p = (pos + BASE_PITCH - 1)
    print(">>> note_on p=" .. p .. " v=" .. colour .. " ch=3")
    mf:note_on(p, colour, 3)
    -- Level is 0..15.
    mf:note_on(p, 18 + level, 4)
end

local function underside(G, how)
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
    light = light,
    underside = underside
}

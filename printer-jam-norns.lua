-- ## printer-jam-norns
-- Driver for MIDI Fighter and arc 4
-- to generate controller bindings.
-- NOTE: requires _shado_.
--
-- Nick Rothwell, nick@cassiel.com.

--[[
    This is a norns port of some Max code which takes MIDI Fighter/arc
    input and generates banks of controller outputs (and some hard-wired
    notes).

    Input: one MIDI Fighter Spectra, one monome arc 4. There are six banks of
    four controller outputs, hence 72 outputs. The rest of the Spectra
    is relatively ad-hoc note output.
    
    We assume the Spectra is on Bank 1, default MIDI output. We will
    probably also get note input from the side buttons, which we ignore.
    
    Output: feedback to the Spectra and arc, and outward MIDI to DAW.
    
    Implementation: we rig up a custom shado renderer which drives
    the Spectra at three levels (full white, half white, off).
    Scheme to be used for colour rendering TBC.
]]

--[[
    Processing from Spectra:
    - Any held notes should fire underside lights (not properly
      tracked in Max).
    - Notes 44-51 incl are looper control. 44-47 are lower row,
      48-51 are upper. These are direct clip triggers in Bitwig
      (the clips just send very low notes to loopers, quantised).
    - The looper groups (each row of 4) have mutually exclusive
      lighting: red/orange/blue/green, full intensity.
    - Third row, 3+4: scene select. Also: something is fudging
      a C-1 for scene launch on chording. (Max, with 100ms delay.)
    - Remaining buttons: 6 stacks of 8 controllers. Current in
      low red, "shift" selection (held) bright red. We could also
      add some eye candy here when the arc does something.
]]

-- Development: purge lib on reload:

for k, _ in pairs(package.loaded) do
    if k:find("printer-jam-norns.", 1, true) == 1 then
        print("purge " .. k)
        package.loaded[k] = nil
    end
end

local ports = require "printer-jam-norns.lib.ports"

-- All state globals:
G = { }

BASE_PITCH = 36
NUM_BANKS = 6       -- Number of controller banks (currently 6)

-- Colour table: e.g. COLOURS.yellow.lo

do
    local names = {
        "red", "orange", "yellow", "lime",
        "green", "cyan", "blue", "purple",
        "pink", "white"
    }

    COLOURS = { }
    
    for i = 1, #names do
        local v_lo = (i - 1) * 12 + 13
        local v_hi = (i - 1) * 12 + 7
        if v_lo > 120 then v_lo = 1 end
        COLOURS[names[i]] = {lo = v_lo, hi = v_hi}
    end
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

--[[
    Deal with notes from the device designated as Spectra. We
    don't care about MIDI channel and there's no velocity
    variation.
]]

local function process_note(pitch, is_on)
    -- print("NOTE " .. pitch .. " mode " .. (is_on and "ON" or "OFF"))
        
    G.num_held_notes = (G.num_held_notes or 0) + (is_on and 1 or -1)
    
    local daw = G.midi.devices[G.midi.daw_target]
    local button0 = pitch - BASE_PITCH
    
    if button0 >= 0 and button0 < 16 then   -- Protection against out-of-range notes.
                                            -- (We should also filter on MIDI channel.)
        --[[
            Nudge controls, looper controls. Just echo the notes
            through (with fudged velocity and channel) before we
            do any LED driving.
        ]]

        if button0 >= NUM_BANKS then
            -- MIDI Fighter can't do velocity, so just default it:
            if is_on then
                daw:note_on(pitch, 64, 1)
            else
                daw:note_off(pitch, 64, 1)
            end
        end        
    
        underside(G.num_held_notes > 0)
    end
end

function init()
    ports.setup(G, {process_note = process_note})
end

function redraw()
end

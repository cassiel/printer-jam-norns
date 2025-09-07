-- ## printer-jam-norns
-- Driver for MIDI Fighter and arc 4
-- to generate controller bindings.
-- NOTE: requires _shado_.
--
-- Nick Rothwell, nick@cassiel.com.

--[[
    This is a norns port of some Max code which takes MIDI Fighter and arc
    input and generates banks of controller outputs (and some hard-wired
    note messages).

    Input: one MIDI Fighter Spectra, one monome arc 4. There are six banks of
    4 + 4 controller outputs, hence 48 outputs. The rest of the Spectra
    is relatively ad-hoc note output.
    
    We assume the Spectra is on Bank 1, default MIDI output. We will
    probably also get note input from the side buttons, which we ignore.
    (We can render to the remaining banks 2..4, but tracking button
    input is more tricky since the pitch values change.)
    
    Output: feedback to the Spectra and arc, and outward MIDI to DAW.
    
    It's possible to drive the Spectra at 16 levels of brightness
    (including 0), so we can do full greyscale shado.
    We'll hard-wire any colours in our custom renderer, post-shado.
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

local G = require "printer-jam-norns.lib.global"
local ports = require "printer-jam-norns.lib.ports"
local spectra = require "printer-jam-norns.lib.spectra"
local visuals = require "printer-jam-norns.lib.visuals"

-- All state globals (maybe this could be a shared package?):
-- G = { }

NUM_BANKS = 6       -- Number of controller banks (currently 6)

--[[
    Deal with notes from the device designated as Spectra. We
    don't care about MIDI channel and there's no velocity
    variation.
]]

local function process_note(pitch, is_on)
    -- print("NOTE " .. pitch .. " mode " .. (is_on and "ON" or "OFF")).
    -- NOTE: should filter on chan=3.
        
    G.num_held_notes = (G.num_held_notes or 0) + (is_on and 1 or -1)
    
    local daw = G.midi.devices[G.midi.daw_target]
    local button0 = pitch - spectra.BASE_PITCH
    
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
    
        spectra.underside(G.num_held_notes > 0)
        visuals.test(is_on)
    end
end

function init()
    ports.setup({process_note = process_note})
    G.reset_state()
end

function redraw()
end

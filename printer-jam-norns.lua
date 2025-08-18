-- ## printer-jam-norns
-- Driver for MIDI Fighter and arc 4
-- to generate controller bindings.
-- NOTE: will require _shado_.
--
-- Nick Rothwell, nick@cassiel.com.

--[[
    This is a norns port of some Max code which takes MIDI Fighter/arc
    input and generates banks of controller outputs (and some hard-wired
    notes).

    Input: one MIDI Fighter Spectra, one monome arc 4. There are six banks of
    four controller outputs, hence 72 outputs. The rest of the Spectra
    is relatively ad-hoc note output (or that might even be directly mapped
    from Spectra to DAW, in which case we need to echo it).
    
    Output: feedback to the Spectra and arc, and outward MIDI to DAW.
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
      low red, "shift" selection (held) bright red.
]]

-- All globals:
G = { }

BASE_PITCH = 36
NUM_BANKS = 6       -- Number of controller banks (currently 6)

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
    G.num_held_notes = (G.num_held_notes or 0) + (is_on and 1 or -1)
    
    local daw = G.midi.devices[G.midi.daw_target]
    
    --[[
        For all except the first N buttons, we pass through the note
        event, but on MIDI channel 1.
    ]]

    if pitch >= BASE_PITCH + NUM_BANKS then
        -- MIDI Fighter can't do velocity, so just default it:
        if is_on then
            daw:note_on(pitch, 64, 1)
        else
            daw:note_off(pitch, 64, 1)
        end
    end
    
    print("NOTE " .. pitch .. " mode " .. (is_on and "ON" or "OFF"))
    
    underside(G.num_held_notes > 0)
end

local function setup_midi()
    --[[
        Set up MIDI endpoints via virtual ports (so the devices
        here might not actually be connected, and/or a script
        reload might be needed).
    ]]

    -- Arrays indexed by vport:
    local devices = { }
    local names = { }
    
    for i = 1, #midi.vports do
        devices[i] = midi.connect(i)
        -- The trim is mainly for the parameter page. (Perhaps we should
        -- have a second table with longer names for the script page.)
        table.insert(
            names,
            "port "..i..": "..util.trim_string_to_width(devices[i].name, 40)
        )
        
        devices[i].event =
            function (x)
                print("PORT [" .. i .. "]")
                if i == G.midi.mf_target then
                    local msg = midi.to_msg(x)
                    process_note(msg.note, (msg.type == "note_on"))
                end
            
                tab.print(midi.to_msg(x))
            end
    end
    
    params:add_option("mf", "MIDI Fighter", names, 1)
    params:set_action("mf", function(x) G.midi.mf_target = x end)
    
    params:add_option("daw", "DAW", names, 2)
    params:set_action("daw", function(x) G.midi.daw_target = x end)
    
    G.midi = {
        devices = devices,
        names = names,
        mf_target = 1,          -- Hope that fires before the param callback?
        daw_target = 2
    }
end

local function setup_arcs()
    --[[
        We are unlikely to connect more than one arc, but let's follow
        the MIDI template, connecting to all ports and
        and having a menu selection param for the one we're using.
    ]]

    -- Arrays indexed by vport:
    local devices = { }
    local names = { }
    
    for i = 1, #arc.vports do
        devices[i] = arc.connect(i)
        -- The trim is mainly for the parameter page. (Perhaps we should
        -- have a second table with longer names for the script page.)
        table.insert(
            names,
            "port "..i..": "..util.trim_string_to_width(devices[i].name, 40)
        )
        
        devices[i].delta =
            function (n, d)
                print("port " .. i .. " enc " .. n .. " delta " .. d)
            end
            
        devices[i].key =
            function (n, z)
                print("port " .. i .. " enc " .. n .. " key " .. z)
            end
    end
    
    params:add_option("arc", "arc 4", names, 1)
    params:set_action("arc", function(x) G.arcs.target = x end)
    
    G.arcs = {
        devices = devices,
        names = names,
        target = 1
    }

end

function init()
    params:add_separator("The Printer Jam")
    setup_midi()
    setup_arcs()
end

function redraw()
end

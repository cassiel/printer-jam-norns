-- Setting up MIDI and device ports via prefs.

local G = require "printer-jam-norns.lib.global"
local spectra = require "printer-jam-norns.lib.spectra"
local visuals = require "printer-jam-norns.lib.visuals"

local function setup_midi(callbacks)
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
                    callbacks.process_note(msg.note, (msg.type == "note_on"))
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

local function setup(callbacks)
    tab.print(callbacks)
    params:add_separator("The Printer Jam: Ports")
    setup_midi(callbacks)
    setup_arcs()
end

return {
    setup = setup
}

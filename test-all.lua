-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local G = require "printer-jam-norns.lib.global"
local spectra = require "printer-jam-norns.lib.spectra"
local visuals = require "printer-jam-norns.lib.visuals"

local function mock_MIDI()
    local midi_log = { }

    G.midi = {
        devices = {
            mf = {
                note_on = function (_self, p, v, ch)
                    table.insert(midi_log, {type="+", p=p, v=v, ch=ch})
                end,

                note_off = function (_self, p, v, ch)
                    table.insert(midi_log, {type="-", p=p, v=v, ch=ch})
                end
            }
        },

        mf_target = "mf"        -- In the live code this is an index.
    }

    G.midi_log = midi_log
end

test_Start = {
    test_Start = function ()
        lu.assertEquals(1, 1)
        lu.assertEquals({1, 2}, {1, 2})
        lu.assertEquals({A=1, B=2}, {B=2, A=1})
    end
}

test_Mapping = {
    -- Next step: incorporate multiple banks.
    test_xy_to_pos = function ()
        lu.assertEquals(spectra.xy_to_pos(1, 1), 13)
        lu.assertEquals(spectra.xy_to_pos(4, 4), 4)
        lu.assertEquals(spectra.xy_to_pos(2, 3), 6)
    end,

    test_pos_to_xy = function ()
        lu.assertEquals({spectra.pos_to_xy(1)}, {1, 4})
        lu.assertEquals({spectra.pos_to_xy(16)}, {4, 1})
        lu.assertEquals({spectra.pos_to_xy(6)}, {2, 3})
    end
}

test_Lighting = {
    setUp = function ()
        mock_MIDI()
    end,

    test_Light = function ()
        spectra.light(1, 1, 100, 5)
        spectra.light(2, 16, 120, 10)

        lu.assertEquals(#G.midi_log, 4)

        lu.assertEquals(G.midi_log[1], {type="+", p=36, v=100, ch=3})
        lu.assertEquals(G.midi_log[2], {type="+", p=36, v=23, ch=4})

        lu.assertEquals(G.midi_log[3], {type="+", p=67, v=120, ch=3})
        lu.assertEquals(G.midi_log[4], {type="+", p=67, v=28, ch=4})
    end,

    test_Underside_ON = function ()
        spectra.underside(true)
        lu.assertEquals(#G.midi_log, 4)
        for i = 1, 4 do
            lu.assertEquals(G.midi_log[i], {type="+", p=15 + i, v=33, ch=4})
        end
    end,

    test_Underside_OFF = function ()
        spectra.underside(false)
        lu.assertEquals(#G.midi_log, 4)
        for i = 1, 4 do
            lu.assertEquals(G.midi_log[i], {type="+", p=15 + i, v=18, ch=4})
        end
    end

}

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")

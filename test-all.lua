-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"

local G = require "printer-jam-norns.lib.global"
local spectra = require "printer-jam-norns.lib.spectra"
local visuals = require "printer-jam-norns.lib.visuals"
local buttons = require "printer-jam-norns.lib.buttons"

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderers = require "shado.lib.renderers"
local manager = require "shado.lib.manager"

local function mock_MIDI()
    local midi_log = { }

    G.midi = {
        devices = {
            mf = {
                note_on = function (self, p, v, ch)
                    table.insert(midi_log, {type="+", p=p, v=v, ch=ch})
                end,

                note_off = function (self, p, v, ch)
                    table.insert(midi_log, {type="-", p=p, v=v, ch=ch})
                end
            }
        },

        mf_target = "mf"        -- In the live code this is a numeric index.
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

test_Dependencies = {
    test_Have_SHADO = function ()
        lu.assertNotNil(types)
        lu.assertNotNil(blocks)
        lu.assertNotNil(frames)
        lu.assertNotNil(renderers)
        lu.assertNotNil(manager)
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

    --[[
        Underside lighting: channel 4, pitches 16..19, velocity 33 for on
        (or maximum), 18 for off (or minimum).
    ]]

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

test_Presses = {
    setUp = function ()
        mock_MIDI()
    end,

    test_Press = function ()
        --[[
            Set up a shado-based responder, then press a button,
            check that shado has responded.
        ]]
        local hit = false
        local block = blocks.Block:new(4, 4)

        block.press = function (self, x, y, how)
            if  x == 1 and y == 1 and how == 1 then
                hit = true
            end
        end

        local buttoner = buttons.Buttons:new(block)
        buttoner:press(48, 127, 3)    -- Top left button on (default) bank 1.
        lu.assertTrue(hit)
    end,

    test_Release = function ()
        local hit = "none"
        local block = blocks.Block:new(4, 4)

        block.press = function (self, x, y, how)
            if  x == 1 and y == 1 then
                hit = (how == 1 and "on" or "off")
            end
        end

        local buttoner = buttons.Buttons:new(block)
        buttoner:press(48, 127, 3)
        buttoner:press(48, 0, 3)
        lu.assertEquals(hit, "off")
    end,

    test_Press_across_Banks = function ()
        --[[
            Set up a shado-based responder, then press a button,
            then mimick a bank switch (mock incoming message),
            then release the same button (with different pitch),
            check that shado has responded.
        ]]
        local hit = "none"
        local block = blocks.Block:new(4, 4)

        block.press = function (self, x, y, how)
            if  x == 1 and y == 1 then
                hit = (how == 1 and "on" or "off")
            end
        end

        local buttoner = buttons.Buttons:new(block)
        buttoner:press(48, 127, 3)      -- Press button.
        buttoner:press(0, 0, 4)         -- Bank 1 deselect.
        buttoner:press(1, 127, 4)       -- Bank 2 select.
        buttoner:press(48 + 16, 0, 3)   -- And... release button when in bank 2.
        lu.assertEquals(hit, "off")
    end,

    test_Press_in_Higher_Bank = function ()
        local hit = false
        local block = blocks.Block:new(8, 4)        -- Cover banks 1 and 2

        block.press = function (self, x, y, how)
            if  x == 5 and y == 1 and how == 1 then
                hit = true
            end
        end

        local buttoner = buttons.Buttons:new(block)
        buttoner:press(0, 0, 4)            -- Bank 1 deselect.
        buttoner:press(1, 127, 4)          -- Bank 2 select.
        buttoner:press(48 + 16, 127, 3)    -- Top left button on bank 1.
        lu.assertTrue(hit)
    end
}

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")

--[[
    Shado forms.
]]

local G = require "printer-jam-norns.lib.global"

local spectra = require "printer-jam-norns.lib.spectra"

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local manager = require "shado.lib.manager"

local function underside()
    --[[
        A 4x4 transparent block whose only purpose is to
        activate the underside lights. Note: it has to
        pass through presses to the main system.
    ]]

    local block = blocks.Block:new(4, 4):fill(types.LampState.THRU)
    
    block.num_held = 0
    
    function block:press(x, y, how)
        print("Underside press")
        block.num_held = block.num_held + ((how == 1) and 1 or -1)
        spectra.underside(block.num_held > 0)
        
        return false        --  Let presses be passed through.
    end
    
    return block
end

local function looper_buttons()
    --[[
        Create a 4-by-2 block which sends MIDI notes on press,
        matching the actual MIDI notes which came in (since
        we've already bound those in Bitwig). Behaviour:
        two 4-item radio button rows.
    ]]

    local block = blocks.Block:new(4, 2):fill(types.LampState:new(G.const.DIM, 0))
    
    function block:press(x, y, how)
        print("looper press x=" .. x .. " y=" .. y .. " how=" .. how)
    end
    
    return block
end

local function main_form()
    local f = frames.Frame:new()
    f:add(looper_buttons(), 1, 1)
    f:add(underside(), 1, 1)
    return manager.PressManager:new(f)
end

return {
    main_form = main_form
}

-- Visuals.

local types = require "shado.lib.types"
local blocks = require "shado.lib.blocks"
local frames = require "shado.lib.frames"
local renderer = require "printer-jam-norns.lib.renderer"

local function test(how)
    local f = frames.Frame:new()
    
    if how then
        local block = blocks.Block:new(4, 4):fill(types.LampState:new(0.25, 0))
        f:add(block, 1, 1)
        block = blocks.Block:new(2, 2):fill(types.LampState.OFF)
        f:add(block, 2, 3)
    else
        local block = blocks.Block:new(2, 2):fill(types.LampState.ON)
        f:add(block, 2, 1)
    end

    renderer.render(f)
end

return {
    test = test
}

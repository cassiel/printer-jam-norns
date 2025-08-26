-- Renderer to drive the Spectra from a shado component.
-- Very similar to shado's `VariableBlockRenderer`.
-- Implicitly refers to Spectra in globals.
-- For now: only render in monochrome.

local spectra = require "printer-jam-norns.lib.spectra"

local function render(renderable)
    for x = 1, 4 do
        for y = 1, 4 do
            local level = renderable:getLamp(x, y):againstBlack()
            level = math.floor(level * 15.0)        -- Maybe nudge that up?
            
            -- pos==1 is lower left:
            local pos = spectra.xy_to_pos(x, y)
            spectra.light(pos, spectra.COLOURS.red, level)
        end
    end
end

return {
    render = render
}

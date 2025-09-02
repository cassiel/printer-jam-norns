--[[
    Raw button handling, MIDI direct from Spectra.
]]

--[[
    We're going OO here, because the button responder
    needs to be able to inject into the shado component
    (which we assume is already monkey-patched into
    the renderer and other outputs).
]]

local Buttons = { }

function Buttons:new(shado_component)
    local result = {
        shado_component = shado_component
    }

    self.__index = self
    return setmetatable(result, self)
end

function Buttons:press(pitch, vel, chan)
    --[[
        If chan=4, then pitch is 0..3 for bank select (v=127).
        If chan=3, then pitch starts at 36..83 for button
        presses on first bank, then skips up 16 at a time.
        (So - sanity check - we could guess the bank
        from the pitch.)
    ]]
end

return {
    Buttons = Buttons
}

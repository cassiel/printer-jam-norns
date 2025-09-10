--[[
    Raw button handling, MIDI direct from Spectra.
]]

local G = require "printer-jam-norns.lib.global"
local spectra = require "printer-jam-norns.lib.spectra"

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
        (Deselect for previous bank comes in first.)
        We're using vel==0 for note-off, although norns
        has distinct note-on and note-off messages.
        If chan=3, then pitch starts at 36..83 for button
        presses on first bank, then skips up 16 at a time.
        (So - sanity check - we could guess the bank
        from the pitch.)
    ]]
    if chan == 4 then
        if vel > 0 then     -- Ignore bank defocus.
            G.state.spectra_bank = pitch + 1
        end
    elseif chan == 3 then
        local bank0 = G.state.spectra_bank - 1
        local pos = pitch - spectra.BASE_PITCH - (bank0 * 16) + 1
        local x, y = spectra.pos_to_xy(pos)
        print("PRESS " .. x .. ", " .. y .. " vel=" .. vel)

        -- Issue: we might bank-switch while holding a button. So we
        -- remember the state of "pos" (its bank) on note-on and use
        -- that on note-off.

        if vel > 0 then
            print("SHADO PRESS " .. x + bank0 * 4 .. ", " .. y .. " into shado " .. tostring(self.shado_component))
            self.shado_component:press(x + bank0 * 4, y, 1)
            G.state.spectra_bank_when_held[pos] = G.state.spectra_bank
        else
            local original_bank = G.state.spectra_bank_when_held[pos]
            self.shado_component:press(x + (original_bank - 1) * 4, y, 0)
        end
    end
end

return {
    Buttons = Buttons
}

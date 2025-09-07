-- Shared global values. Anything global should go here.

local G = { }

function G.reset_state ()     -- Used in unit tests.
    G.state = {
        spectra_bank = 1,
        spectra_bank_when_held = { }  -- pos -> bank when held (1..4).
    }
end

return G

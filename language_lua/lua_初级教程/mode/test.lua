require('lua_add')

local function add_ab()
        local INPUT_FILE = 10
        local OUTPUT_FILE = 20
        
        interface.lua_add(INPUT_FILE, OUTPUT_FILE)
end

do 
        add_ab();
end

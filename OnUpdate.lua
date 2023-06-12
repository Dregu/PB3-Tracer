local state = GetGameState()

if enabled and debug_enabled then
    for id,fn in pairs(debug) do
        local name = "debug_"..id
        UpdateTextString(name, tostring(id)..": "..fn())
    end
end

if enabled and state ~= "MAIN_MENU" then
    update_cars()
    if state == "SIM" and last_state ~= "SIM" then
        on_sim()
    end
    if state == "BUILD" and last_state ~= "BUILD" then
        on_build()
    end
    for k,dot in pairs(dots) do
        if dot.v > 0 then
            local spos = WorldToScreenPos({dot.x, dot.y, 0})
            UpdateTextScreenPos(dot.name, spos[1], spos[2])
            if color == "speed" then
                UpdateTextColor(dot.name, lerp_colors[math.min(255, math.floor(dot.v / max_speed * 255))])
            end
        end
    end
else
    clear_dots()
end
last_state = state

local state = GetGameState()
if IsSimulatingWithoutPassOrFail() then
    last_sim_frame = GetFrameCount()
end
if enabled and (IsSimulatingWithoutPassOrFail() or GetFrameCount() - last_sim_frame < 60) and state ~= "MAIN_MENU" then
    for i,id in pairs(GetVehicleIds()) do
        if not car or car == i then
            local pos = GetVehiclePosition(id)
            local vel = GetVehicleSpeed(id)
            if vel > min_speed and car_moved(id, pos) then
                add_dot(id, pos, vel)
            end
        end
    end
end

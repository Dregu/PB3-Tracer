function tracer(args)
    enabled = not enabled
    if not enabled then
        for k,dot in pairs(dots) do
            UpdateTextString(dot.name, "")
        end
        for id,fn in pairs(debug) do
            local name = "debug_"..id
            UpdateTextString(name, "")
        end
    end
    ConsoleLog("Tracer " .. (enabled and "ENABLED" or "DISABLED"))
end

function tracer_min_speed(args) min_speed = tonumber(args[1]) or defaults.min_speed end
function tracer_max_speed(args) max_speed = tonumber(args[1]) or defaults.max_speed end
function tracer_min_distance(args) min_distance = tonumber(args[1]) or defaults.min_distance end
function tracer_size(args) size = tonumber(args[1]) or defaults.size end
function tracer_opacity(args) opacity = tonumber(args[1]) or defaults.opacity end

function tracer_color(args)
    if args[1] == "car" then
        color = "car"
    elseif #args[1] == 6 then
        color = args[1]
    else
        color = "speed"
    end
end

function tracer_char(args)
    if args[1] == "car" then
        char = "car"
    else
        char = args[1]:sub(1, 1) or defaults.char
    end
end

function tracer_dots(args)
    local old_dots = max_dots
    max_dots = tonumber(args[1]) or defaults.max_dots
    if max_dots > old_dots then
        for i=old_dots+1,max_dots do
            init_dot(i)
        end
    end
end

function tracer_car(args)
    local arg = args[1]
    local num = tonumber(arg) or (string.byte(arg) - 64)
    if #arg == 1 and num > 0 then
        car = num
    else
        car = nil
        return
    end
end

function tracer_debug(args)
    debug_enabled = not debug_enabled
    if not debug_enabled then
        for id,fn in pairs(debug) do
            local name = "debug_"..id
            UpdateTextString(name, "")
        end
    end
end

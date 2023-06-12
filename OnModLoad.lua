defaults = {
    enabled = true,
    debug = false,
    max_dots = 1000,
    max_speed = 10,
    min_speed = 0.1,
    min_distance = 0.2,
    color = "speed",
    size = 12,
    opacity = 0.5,
    char = "car"
}

frame = 1
char = defaults.char
enabled = defaults.enabled
debug_enabled = defaults.debug
max_dots = defaults.max_dots
max_speed = defaults.max_speed
min_speed = defaults.min_speed
min_distance = defaults.min_distance
color = defaults.color
size = defaults.size
opacity = defaults.opacity
car = nil
last_state = nil
last_sim_frame = 0
dots = {}
car_hash = ""
car_pos = {}
car_color = {}
car_num = {}
colors = {
    --{ r=0x00, g=0x9f, b=0xff },
    --{ r=0xec, g=0x2f, b=0x4b }
    { r=0x33, g=0x33, b=0x99 },
    { r=0xff, g=0x00, b=0xcc }
}
lerp_colors = {}
debug = {}

car_chars = {
    "❶", "❷", "❸", "❹", "❺", "❻", "❼", "❽", "❾", "❿",
    "⓫", "⓬", "⓭", "⓮", "⓯", "⓰", "⓱", "⓲", "⓳", "⓴"
}

EnableDebugConsole()
AddDebugConsoleCommand("tracer", "Toggle car tracer", 0)
AddDebugConsoleCommand("tracer_debug", "Toggle tracer debug info (default: "..tostring(debug_enabled)..")", 0)
AddDebugConsoleCommand("tracer_color", "Color of the dots in hex <RRGGBB>, <car> for random color per car or <speed> for gradient (default: speed)", 1)
AddDebugConsoleCommand("tracer_size", "Size of the dots (default: "..tostring(size)..")", 1)
AddDebugConsoleCommand("tracer_opacity", "Opacity of the dots (default: "..tostring(opacity)..")", 1)
AddDebugConsoleCommand("tracer_max_speed", "Max speed used in velocity-color calculation (default: "..tostring(max_speed)..")", 1)
AddDebugConsoleCommand("tracer_min_speed", "Min speed for car to draw a new dot (default: "..tostring(min_speed)..")", 1)
AddDebugConsoleCommand("tracer_min_distance", "Min distance for car to move to draw a new dot (default: "..tostring(min_distance)..")", 1)
AddDebugConsoleCommand("tracer_dots", "Max dots to draw (default: "..tostring(max_dots)..")", 1)
AddDebugConsoleCommand("tracer_char", "Character used to plot (default: "..tostring(char)..")", 1)
AddDebugConsoleCommand("tracer_car", "Trace a specific car <A/B/1/2/...> or <0/all> (all)", 1)

function add_debug(id, fn)
    local n = 0
    for k,v in pairs(debug) do
        n = n + 1
    end
    debug[id] = fn
    local name = "debug_"..id
    CreateTextObject(name, 800, 20)
    UpdateTextScreenPos(name, 0.05, 1.0-(0.07+(n*0.02)))
    UpdateTextFontSize(name, 16)
    UpdateTextColor(name, "#FFFFFF99")
    UpdateTextAlignment(name, "Left", "Top")
    UpdateTextPivot(name, 0, 1)
    if debug_enabled then
        UpdateTextString(name, tostring(id) .. ": " .. fn())
    end
end

add_debug("state", GetGameState)
add_debug("sim", function() return tostring(IsSimulatingWithoutPassOrFail()) end)
add_debug("dot", function() return tostring(frame) .. "/" .. tostring(max_dots) end)
--add_debug("gameframe", function() return tostring(GetFrameCount()) end)
--add_debug("delta", function() return tostring(GetUnscaledDeltaTime()) end)

function init_dot(i)
    if not dots[i] then
        local name = "dot"..tostring(i)
        CreateTextObject(name, 20, 20)
        dots[i] = {
            name = name,
            x = 0,
            y = 0,
            v = 0
        }
    end
end

for i=1,max_dots do
    init_dot(i)
end

function lerp_color(val)
    local r = colors[1].r + (colors[2].r - colors[1].r) * val
    local g = colors[1].g + (colors[2].g - colors[1].g) * val
    local b = colors[1].b + (colors[2].b - colors[1].b) * val
    return string.format("#%02X%02X%02X%02X", math.floor(r), math.floor(g), math.floor(b), math.floor(opacity*255))
end

for i=0,255 do
    lerp_colors[i] = lerp_color(i/255)
end

function speed_median(t)
    local temp={}
    for k,dot in pairs(t) do
        if type(dot.v) == 'number' and dot.v > 0 then
            table.insert(temp, dot.v)
        end
    end
    table.sort(temp)
    if math.fmod(#temp,2) == 0 then
        return (temp[#temp/2] + temp[(#temp/2)+1]) / 2
    else
        return temp[math.ceil(#temp/2)]
    end
end

function get_color(id, vel)
    if #color == 6 then
        return "#" .. color .. string.format("%02X", math.floor(opacity*255))
    elseif color == "car" then
        if car_color[id] then return car_color[id] end
        local seed = 0
        for i=1,#id-1 do
            seed = seed + string.byte(id:sub(i,i+1))
        end
        math.randomseed(seed)
        local r = math.random()*0.7+0.3
        local g = math.random()*0.7+0.3
        local b = math.random()*0.7+0.3
        if b < g then
            b = b * 0.2
        elseif g < r then
            g = g * 0.2
        else
            r = r * 0.2
        end
        local col = string.format("#%02X%02X%02X%02X", math.floor(r*255), math.floor(g*255), math.floor(b*255), math.floor(opacity*255))
        car_color[id] = col
        return col
    else
        local n = math.min(max_speed, vel) / max_speed
        return lerp_color(n)
        --[[local r = 0
        local g = 0
        local b = 0
        if n < 0.5 then
            g = 2 * n
            r = 1
        else
            g = 1
            r = 1 - 2 * (n - 0.5)
        end
        return string.format("#%02X%02X%02X%02X", math.floor(r*255), math.floor(g*255), math.floor(b*255), math.floor(opacity*255))]]
    end
end

function add_dot(id, pos, vel)
    local name = "dot"..tostring(frame)
    local spos = WorldToScreenPos(pos)
    UpdateTextScreenPos(name, spos[1], spos[2])
    local str = char
    if str == "car" and car_num[id] then
        if car_num[id] <= #car_chars then
            str = car_chars[car_num[id]]
        else
            str = "⓿"
        end
    end
    UpdateTextString(name, str)
    UpdateTextPivot(name, 0.5, 0.5)
    UpdateTextAlignment(name, "Center", "Middle")
    UpdateTextFontSize(name, size)
    UpdateTextColor(name, get_color(id, vel))
    dots[frame].x = pos[1]
    dots[frame].y = pos[2]
    dots[frame].v = vel
    frame = (frame % max_dots) + 1
end

function clear_dots()
    for k,dot in pairs(dots) do
        UpdateTextString(dot.name, "")
        dot.x = 0
        dot.y = 0
        dot.v = 0
    end
    frame = 1
end

function update_cars()
    local str = ""
    for i,id in pairs(GetVehicleIds()) do
        str = str .. " " .. id
    end
    if car_hash ~= str and GetGameState() ~= "SANDBOX" then
        on_level()
    end
    car_hash = str
end

function distance (x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt (dx * dx + dy * dy)
end

function car_moved(id, pos)
    local last_pos = car_pos[id]
    if not last_pos then
        car_pos[id] = pos
        return true
    end
    local moved = distance(pos[1], pos[2], car_pos[id][1], car_pos[id][2]) > min_distance
    if moved then
        car_pos[id] = pos
    end
    return moved
end

function on_build()
    if frame ~= 1 then
        max_speed = speed_median(dots)*1.2
    end
end

function on_sim()
    if frame ~= 1 then
        max_speed = speed_median(dots)*1.2
    end
    clear_dots()
end

function on_level()
    max_speed = 10
    clear_dots()
    car_num = {}
    for i,id in pairs(GetVehicleIds()) do
        car_num[id] = i
    end
end

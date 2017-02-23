require "imgui"
lunajson = require "lunajson"

filename = ""
mode = "idle"
waypoints = {}
selected = 0
next_waypoint = 1
runways = {}
next_runway = 1
selected_runway = 0
selected_runway_point = 0
local runway_drag_offset

local font

dimensions = {50, 50}

love.load = ->
    font = love.graphics.newFont('3270Medium.ttf', 20)
    love.graphics.setFont(font)
    love.window.setMode(0, 0)

love.update = ->
    imgui.NewFrame!

love.draw = ->
    imgui.Begin('Main')
    _, filename = imgui.InputText("Filename", filename, 64)
    _, dimensions[1], dimensions[2] = imgui.DragFloat2(
        "Boundary Dimensions", dimensions[1], dimensions[2])
    if dimensions[1] < 0.0
        dimensions[1] = 0.0
    if dimensions[2] < 0.0
        dimensions[2] = 0.0

    if imgui.Button('Export')
        f = io.open(filename, 'w')
        io.output(f)
        io.write(lunajson.encode({
            width: dimensions[1],
            height: dimensions[2],
            waypoints: [{
                name: wp.name,
                x: wp.x,
                y: dimensions[2] - wp.y
            } for _, wp in pairs waypoints]
            runways: [{
                names: rw.names,
                points: [{x: point.x, y: dimensions[2] - point.y} for _, point in ipairs rw.points]
            } for _, rw in pairs runways]
        }))
        io.close(f)

    if imgui.Button('Load')
        f = io.open(filename, 'r')
        io.input(f)
        obj = lunajson.decode(io.read("*all"))
        dimensions = {obj.width, obj.height}
        waypoints = [{
            name: wp.name,
            x: wp.x,
            y: dimensions[2] - wp.y
        } for _, wp in pairs obj.waypoints]
        runways = [{
            names: rw.names,
            points: [{x: point.x, y: dimensions[2] - point.y} for _, point in ipairs rw.points]
        } for _, rw in pairs obj.runways]
        io.close(f)

    imgui.End!

    if selected != 0
        wp = waypoints[selected]
        imgui.Begin('Edit Waypoint')
        _, wp.name = imgui.InputText("Name", wp.name, 8)
        if imgui.Button('Delete Waypoint')
            waypoints[selected] = nil
            selected = 0
        imgui.End!
    
    if selected_runway != 0
        rw = runways[selected_runway]
        imgui.Begin('Edit Runway')
        for i, name in ipairs rw.names
            _, name.name = imgui.InputText("Name "..i, name.name, 8)
            _, name.offset.angle = imgui.DragFloat("Name "..i.." Angle", name.offset.angle)
            _, name.distance = imgui.DragFloat("Name "..i.." Distance", name.distance)
            name.offset.x = name.distance * math.cos(name.offset.angle)
            name.offset.y = name.distance * math.sin(name.offset.angle)
        if imgui.Button('Delete Runway')
            runways[selected_runway] = nil
            selected_runway = 0
        imgui.End!

    love.graphics.clear(89, 142, 111, 255)
    for id, wp in pairs waypoints
        love.graphics.setColor(16, 71, 20)
        love.graphics.circle("fill", wp.x, wp.y, 10, 50)
        if selected == id
            love.graphics.setColor(208, 232, 210)
        else
            love.graphics.setColor(100, 153, 107)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", wp.x, wp.y, 10, 50)
    for _, wp in pairs waypoints
        love.graphics.setColor(16, 71, 20)
        love.graphics.print(wp.name, wp.x + 10, wp.y + 10)

    for id, rw in pairs runways
        love.graphics.setLineWidth(3)
        love.graphics.setColor(16, 71, 20)
        love.graphics.line(rw.points[1].x, rw.points[1].y, rw.points[2].x, rw.points[2].y)
        if id == selected_runway
            love.graphics.setColor(208, 232, 210)

        for i, name in ipairs rw.names
            love.graphics.printf(name.name,
                rw.points[i].x + name.offset.x - 200,
                rw.points[i].y + name.offset.y - font\getHeight() / 2,
                400,
                'center')

    love.graphics.setLineWidth(3)
    love.graphics.setColor(208, 232, 210)
    love.graphics.rectangle("line", 2, 2, dimensions[1], dimensions[2])

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0, 0, 0)
    y = love.graphics.getHeight()
    love.graphics.line(20, y - 20, 20 + 100, y - 20)
    love.graphics.print("5 km", 20, y - 40)

    love.graphics.setColor(255, 255, 255, 255)
    imgui.Render()

love.quit = ->
    imgui.ShutDown!

love.textinput = (t) ->
    imgui.TextInput(t)

love.keypressed = (k) ->
    imgui.KeyPressed(k)

love.keyreleased = (k) ->
    imgui.KeyReleased(k)

snap = (x, y, sx, sy) ->
    dx = x - sx
    dy = y - sy
    if math.sqrt(dx * dx + dy * dy) < 8
        return sx, sy
    return x, y

snapRunway = (x, y, i) ->
    sel = runways[selected_runway]
    dx = sel.points[i].x - x
    dy = sel.points[i].y - y
    dist = math.sqrt(dx * dx + dy * dy)
    sqrt2 = math.sqrt(2) / 2
    --90 deg
    x, y = snap(x, y, x, sel.points[i].y)
    x, y = snap(x, y, sel.points[i].x, y)
    --45 deg
    x, y = snap(x, y, sel.points[i].x + dist * sqrt2, sel.points[i].y + dist * sqrt2)
    x, y = snap(x, y, sel.points[i].x - dist * sqrt2, sel.points[i].y + dist * sqrt2)
    x, y = snap(x, y, sel.points[i].x + dist * sqrt2, sel.points[i].y - dist * sqrt2)
    x, y = snap(x, y, sel.points[i].x - dist * sqrt2, sel.points[i].y - dist * sqrt2)
    for id, rw in pairs runways
        if id != selected_runway
            --parallel
            dx = rw.points[2].x - rw.points[1].x
            dy = rw.points[2].y - rw.points[1].y
            len = math.sqrt(dx * dx + dy * dy)
            dx /= len
            dy /= len
            x, y = snap(x, y, sel.points[i].x + dist * dx, sel.points[i].y + dist * dy)
            x, y = snap(x, y, sel.points[i].x - dist * dx, sel.points[i].y - dist * dy)

            x, y = snap(x, y, sel.points[i].x + dist * dy, sel.points[i].y - dist * dx)
            x, y = snap(x, y, sel.points[i].x - dist * dy, sel.points[i].y + dist * dx)
    return x, y

snapWaypoint = (x, y) ->
    for id, rw in pairs runways
        --colinear
        rx1, ry1 = rw.points[1].x, rw.points[1].y
        rx2, ry2 = rw.points[2].x, rw.points[2].y
        dx = rx2 - rx1
        dy = ry2 - ry1
        dx2, dy2 =  -dy, dx
        x2 = x + dx2
        y2 = y + dy2
        xi = ((rx1 * ry2 - ry1 * rx2) * (x - x2) - (rx1 - rx2) * (x * y2 - y * x2)) /
            ((rx1 - rx2) * (y - y2) - (x - x2) * (ry1 - ry2))
        yi = ((rx1 * ry2 - ry1 * rx2) * (y - y2) - (ry1 - ry2) * (x * y2 - y * x2)) /
            ((rx1 - rx2) * (y - y2) - (x - x2) * (ry1 - ry2))
        x, y = snap(x, y, xi, yi)
    return x, y


love.mousemoved = (x, y) ->
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse!
        switch mode
            when "dragging"
                x, y = snapWaypoint(x, y)
                waypoints[selected].x = x
                waypoints[selected].y = y
            when "placing_runway"
                x, y = snapRunway(x, y, 1)
                runways[selected_runway].points[2].x = x
                runways[selected_runway].points[2].y = y
            when "editing_runway"
                x, y = snapRunway(x, y, if selected_runway_point == 1 then 2 else 1)
                runways[selected_runway].points[selected_runway_point].x = x
                runways[selected_runway].points[selected_runway_point].y = y
            when "dragging_runway"
                runways[selected_runway].points[2].x = x + runway_drag_offset.x +
                    runways[selected_runway].points[2].x - runways[selected_runway].points[1].x
                runways[selected_runway].points[2].y = y + runway_drag_offset.y +
                    runways[selected_runway].points[2].y - runways[selected_runway].points[1].y
                runways[selected_runway].points[1].x = x + runway_drag_offset.x
                runways[selected_runway].points[1].y = y + runway_drag_offset.y

love.mousepressed = (x, y, button) ->
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse!
        switch mode
            when "placing_runway"
                mode = "idle"
            when "editing_runway"
                mode = "idle"
            when "dragging_runway"
                mode = "idle"
            when "idle"
                for id, wp in pairs waypoints
                    dx = x - wp.x
                    dy = y - wp.y
                    if math.sqrt(dx * dx + dy * dy) < 10
                        if button == 2
                            if selected == id
                                selected = 0
                            waypoints[id] = nil
                        else
                            selected = id
                            mode = "dragging"
                        return
                for id, rw in pairs runways
                    x1, y1 = rw.points[1].x, rw.points[1].y
                    x2, y2 = rw.points[2].x, rw.points[2].y

                    dx, dy = x - x1, y - y1
                    if math.sqrt(dx * dx + dy * dy) < 10
                        selected_runway = id
                        selected_runway_point = 1
                        mode = "editing_runway"
                    dx, dy = x - x2, y - y2
                    if math.sqrt(dx * dx + dy * dy) < 10
                        selected_runway = id
                        selected_runway_point = 2
                        mode = "editing_runway"

                    px = x2 - x1
                    py = y2 - y1
                    lsq = px * px + py * py
                    u = ((x - x1) * px + (y - y1) * py) / lsq
                    if u > 1
                        u = 1
                    if u < 0
                        u = 0
                    xx = x1 + u * px
                    yy = y1 + u * py
                    dx = x - xx
                    dy = y - yy
                    dist = math.sqrt(dx * dx + dy * dy)
                    if dist < 12
                        selected_runway = id
                        mode = "dragging_runway"
                        runway_drag_offset = {
                            x: rw.points[1].x - x
                            y: rw.points[1].y - y
                        }
                        return
                if button == 1
                    if love.keyboard.isDown("lshift")
                        runways[next_runway] = 
                            names: {
                                {
                                    name: "1C"
                                    distance: 20
                                    offset: {
                                        angle: 0
                                        x: 10
                                        y: 0
                                    }
                                },
                                {
                                    name: "1C"
                                    distance: 20
                                    offset: {
                                        angle: 0
                                        x: 10
                                        y: 0
                                    }
                                }
                            }
                            points: {
                                {
                                    x: x
                                    y: y
                                },
                                {
                                    x: x
                                    y: y
                                }
                            }
                        selected_runway = next_runway
                        selected = 0
                        next_runway += 1
                        mode = "placing_runway"
                    else
                        x, y = snapWaypoint(x, y)
                        waypoints[next_waypoint] =
                            x: x
                            y: y
                            name: "NWPT"
                        selected = next_waypoint
                        next_waypoint += 1

love.mousereleased = (x, y, button) ->
    imgui.MouseReleased(button)
    switch mode
        when "dragging"
            mode = "idle"

love.wheelmoved = (x, y) ->
    imgui.WheelMoved(y)

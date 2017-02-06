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

dimensions = {50, 50}

love.load = ->
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
            waypoints: [ wp for _, wp in ipairs waypoints ]
            runways: [ runway for _, runway in ipairs runways ]
        }))
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
        love.graphics.setColor(16, 71, 20)
        love.graphics.line(rw.points[1].x, rw.points[1].y, rw.points[2].x, rw.points[2].y)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(208, 232, 210)
    love.graphics.rectangle("line", 2, 2, dimensions[1], dimensions[2])
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

snapRunway = (x, y) ->
    sel = runways[selected_runway]
    dx = sel.points[1].x - x
    dy = sel.points[1].y - y
    dist = math.sqrt(dx * dx + dy * dy)
    sqrt2 = math.sqrt(2) / 2
    --90 deg
    x, y = snap(x, y, x, sel.points[1].y)
    x, y = snap(x, y, sel.points[1].x, y)
    --45 deg
    x, y = snap(x, y, sel.points[1].x + dist * sqrt2, sel.points[1].y + dist * sqrt2)
    x, y = snap(x, y, sel.points[1].x - dist * sqrt2, sel.points[1].y + dist * sqrt2)
    x, y = snap(x, y, sel.points[1].x + dist * sqrt2, sel.points[1].y - dist * sqrt2)
    x, y = snap(x, y, sel.points[1].x - dist * sqrt2, sel.points[1].y - dist * sqrt2)
    for id, rw in pairs runways
        if id != selected_runway
            --parallel
            dx = rw.points[2].x - rw.points[1].x
            dy = rw.points[2].y - rw.points[1].y
            len = math.sqrt(dx * dx + dy * dy)
            dx /= len
            dy /= len
            x, y = snap(x, y, sel.points[1].x + dist * dx, sel.points[1].y + dist * dy)
            x, y = snap(x, y, sel.points[1].x - dist * dx, sel.points[1].y - dist * dy)

            x, y = snap(x, y, sel.points[1].x + dist * dy, sel.points[1].y - dist * dx)
            x, y = snap(x, y, sel.points[1].x - dist * dy, sel.points[1].y + dist * dx)
    return x, y

love.mousemoved = (x, y) ->
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse!
        switch mode
            when "dragging"
                waypoints[selected].x = x
                waypoints[selected].y = y
            when "placing_runway"
                x, y = snapRunway(x, y)
                runways[selected_runway].points[2].x = x
                runways[selected_runway].points[2].y = y

love.mousepressed = (x, y, button) ->
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse!
        switch mode
            when "placing_runway"
                mode = "idle"
            when "idle"
                if button == 1
                    mode = "dragging"
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
                        return
                if button == 1
                    if love.keyboard.isDown("lshift")
                        runways[next_runway] = 
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

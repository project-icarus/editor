require "imgui"
lunajson = require "lunajson"

filename = ""
drag = false
waypoints = {}
selected = 0
next_waypoint = 1

dimensions = {50, 50}

love.load = ->
    love.window.setMode(1366, 768)

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

love.mousemoved = (x, y) ->
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse!
        if drag
            waypoints[selected].x = x
            waypoints[selected].y = y

love.mousepressed = (x, y, button) ->
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse!
        if button == 1
            drag = true
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
            waypoints[next_waypoint] =
                x: x
                y: y
                name: "NWPT"
            selected = next_waypoint
            next_waypoint += 1

love.mousereleased = (x, y, button) ->
    imgui.MouseReleased(button)
    drag = false

love.wheelmoved = (x, y) ->
    imgui.WheelMoved(y)

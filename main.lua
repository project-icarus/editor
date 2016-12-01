require("imgui")
local lunajson = require("lunajson")
local filename = ""
local drag = false
local waypoints = { }
local selected = 0
local next_waypoint = 1
local dimensions = {
  50,
  50
}
love.load = function()
  return love.window.setMode(0, 0)
end
love.update = function()
  return imgui.NewFrame()
end
love.draw = function()
  imgui.Begin('Main')
  local _
  _, filename = imgui.InputText("Filename", filename, 64)
  _, dimensions[1], dimensions[2] = imgui.DragFloat2("Boundary Dimensions", dimensions[1], dimensions[2])
  if dimensions[1] < 0.0 then
    dimensions[1] = 0.0
  end
  if dimensions[2] < 0.0 then
    dimensions[2] = 0.0
  end
  if imgui.Button('Export') then
    local f = io.open(filename, 'w')
    io.output(f)
    io.write(lunajson.encode({
      width = dimensions[1],
      height = dimensions[2],
      waypoints = (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _, wp in ipairs(waypoints) do
          _accum_0[_len_0] = wp
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()
    }))
    io.close(f)
  end
  imgui.End()
  if selected ~= 0 then
    local wp = waypoints[selected]
    imgui.Begin('Edit Waypoint')
    _, wp.name = imgui.InputText("Name", wp.name, 8)
    if imgui.Button('Delete Waypoint') then
      waypoints[selected] = nil
      selected = 0
    end
    imgui.End()
  end
  love.graphics.clear(89, 142, 111, 255)
  for id, wp in pairs(waypoints) do
    love.graphics.setColor(16, 71, 20)
    love.graphics.circle("fill", wp.x, wp.y, 10, 50)
    if selected == id then
      love.graphics.setColor(208, 232, 210)
    else
      love.graphics.setColor(100, 153, 107)
    end
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", wp.x, wp.y, 10, 50)
  end
  for _, wp in pairs(waypoints) do
    love.graphics.setColor(16, 71, 20)
    love.graphics.print(wp.name, wp.x + 10, wp.y + 10)
  end
  love.graphics.setLineWidth(3)
  love.graphics.setColor(208, 232, 210)
  love.graphics.rectangle("line", 2, 2, dimensions[1], dimensions[2])
  love.graphics.setColor(255, 255, 255, 255)
  return imgui.Render()
end
love.quit = function()
  return imgui.ShutDown()
end
love.textinput = function(t)
  return imgui.TextInput(t)
end
love.keypressed = function(k)
  return imgui.KeyPressed(k)
end
love.keyreleased = function(k)
  return imgui.KeyReleased(k)
end
love.mousemoved = function(x, y)
  imgui.MouseMoved(x, y)
  if not imgui.GetWantCaptureMouse() then
    if drag then
      waypoints[selected].x = x
      waypoints[selected].y = y
    end
  end
end
love.mousepressed = function(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    if button == 1 then
      drag = true
    end
    for id, wp in pairs(waypoints) do
      local dx = x - wp.x
      local dy = y - wp.y
      if math.sqrt(dx * dx + dy * dy) < 10 then
        if button == 2 then
          if selected == id then
            selected = 0
          end
          waypoints[id] = nil
        else
          selected = id
        end
        return 
      end
    end
    if button == 1 then
      waypoints[next_waypoint] = {
        x = x,
        y = y,
        name = "NWPT"
      }
      selected = next_waypoint
      next_waypoint = next_waypoint + 1
    end
  end
end
love.mousereleased = function(x, y, button)
  imgui.MouseReleased(button)
  drag = false
end
love.wheelmoved = function(x, y)
  return imgui.WheelMoved(y)
end

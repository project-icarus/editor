require("imgui")
local drag = false
local waypoints = { }
local selected = 0
local next_waypoint = 1
love.load = function() end
love.update = function()
  return imgui.NewFrame()
end
love.draw = function()
  if selected ~= 0 then
    local wp = waypoints[selected]
    imgui.Begin('Edit Waypoint')
    local _
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
    love.graphics.circle("line", wp.x, wp.y, 10, 50)
  end
  for _, wp in pairs(waypoints) do
    love.graphics.setColor(16, 71, 20)
    love.graphics.print(wp.name, wp.x + 10, wp.y + 10)
  end
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

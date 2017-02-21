require("imgui")
local lunajson = require("lunajson")
local filename = ""
local mode = "idle"
local waypoints = { }
local selected = 0
local next_waypoint = 1
local runways = { }
local next_runway = 1
local selected_runway = 0
local selected_runway_point = 0
local runway_drag_offset
local font
local dimensions = {
  50,
  50
}
love.load = function()
  font = love.graphics.newFont('3270Medium.ttf', 20)
  love.graphics.setFont(font)
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
        for _, wp in pairs(waypoints) do
          _accum_0[_len_0] = {
            name = wp.name,
            x = wp.x,
            y = dimensions[2] - wp.y
          }
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(),
      runways = (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _, rw in pairs(runways) do
          _accum_0[_len_0] = {
            names = rw.names,
            points = (function()
              local _accum_1 = { }
              local _len_1 = 1
              for _, point in ipairs(rw.points) do
                _accum_1[_len_1] = {
                  x = point.x,
                  y = dimensions[2] - point.y
                }
                _len_1 = _len_1 + 1
              end
              return _accum_1
            end)()
          }
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)()
    }))
    io.close(f)
  end
  if imgui.Button('Load') then
    local f = io.open(filename, 'r')
    io.input(f)
    local obj = lunajson.decode(io.read("*all"))
    dimensions = {
      obj.width,
      obj.height
    }
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _, wp in pairs(obj.waypoints) do
        _accum_0[_len_0] = {
          name = wp.name,
          x = wp.x,
          y = dimensions[2] - wp.y
        }
        _len_0 = _len_0 + 1
      end
      waypoints = _accum_0
    end
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _, rw in pairs(obj.runways) do
        _accum_0[_len_0] = {
          names = rw.names,
          points = (function()
            local _accum_1 = { }
            local _len_1 = 1
            for _, point in ipairs(rw.points) do
              _accum_1[_len_1] = {
                x = point.x,
                y = dimensions[2] - point.y
              }
              _len_1 = _len_1 + 1
            end
            return _accum_1
          end)()
        }
        _len_0 = _len_0 + 1
      end
      runways = _accum_0
    end
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
  if selected_runway ~= 0 then
    local rw = runways[selected_runway]
    imgui.Begin('Edit Runway')
    for i, name in ipairs(rw.names) do
      _, name.name = imgui.InputText("Name " .. i, name.name, 8)
      _, name.offset.angle = imgui.DragFloat("Name " .. i .. " Angle", name.offset.angle)
      _, name.distance = imgui.DragFloat("Name " .. i .. " Distance", name.distance)
      name.offset.x = name.distance * math.cos(name.offset.angle)
      name.offset.y = name.distance * math.sin(name.offset.angle)
    end
    if imgui.Button('Delete Runway') then
      runways[selected_runway] = nil
      selected_runway = 0
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
  for id, rw in pairs(runways) do
    love.graphics.setLineWidth(3)
    love.graphics.setColor(16, 71, 20)
    love.graphics.line(rw.points[1].x, rw.points[1].y, rw.points[2].x, rw.points[2].y)
    if id == selected_runway then
      love.graphics.setColor(208, 232, 210)
    end
    for i, name in ipairs(rw.names) do
      love.graphics.printf(name.name, rw.points[i].x + name.offset.x - 200, rw.points[i].y + name.offset.y - font:getHeight() / 2, 400, 'center')
    end
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
local snap
snap = function(x, y, sx, sy)
  local dx = x - sx
  local dy = y - sy
  if math.sqrt(dx * dx + dy * dy) < 8 then
    return sx, sy
  end
  return x, y
end
local snapRunway
snapRunway = function(x, y, i)
  local sel = runways[selected_runway]
  local dx = sel.points[i].x - x
  local dy = sel.points[i].y - y
  local dist = math.sqrt(dx * dx + dy * dy)
  local sqrt2 = math.sqrt(2) / 2
  x, y = snap(x, y, x, sel.points[i].y)
  x, y = snap(x, y, sel.points[i].x, y)
  x, y = snap(x, y, sel.points[i].x + dist * sqrt2, sel.points[i].y + dist * sqrt2)
  x, y = snap(x, y, sel.points[i].x - dist * sqrt2, sel.points[i].y + dist * sqrt2)
  x, y = snap(x, y, sel.points[i].x + dist * sqrt2, sel.points[i].y - dist * sqrt2)
  x, y = snap(x, y, sel.points[i].x - dist * sqrt2, sel.points[i].y - dist * sqrt2)
  for id, rw in pairs(runways) do
    if id ~= selected_runway then
      dx = rw.points[2].x - rw.points[1].x
      dy = rw.points[2].y - rw.points[1].y
      local len = math.sqrt(dx * dx + dy * dy)
      dx = dx / len
      dy = dy / len
      x, y = snap(x, y, sel.points[i].x + dist * dx, sel.points[i].y + dist * dy)
      x, y = snap(x, y, sel.points[i].x - dist * dx, sel.points[i].y - dist * dy)
      x, y = snap(x, y, sel.points[i].x + dist * dy, sel.points[i].y - dist * dx)
      x, y = snap(x, y, sel.points[i].x - dist * dy, sel.points[i].y + dist * dx)
    end
  end
  return x, y
end
love.mousemoved = function(x, y)
  imgui.MouseMoved(x, y)
  if not imgui.GetWantCaptureMouse() then
    local _exp_0 = mode
    if "dragging" == _exp_0 then
      waypoints[selected].x = x
      waypoints[selected].y = y
    elseif "placing_runway" == _exp_0 then
      x, y = snapRunway(x, y, 1)
      runways[selected_runway].points[2].x = x
      runways[selected_runway].points[2].y = y
    elseif "editing_runway" == _exp_0 then
      x, y = snapRunway(x, y, (function()
        if selected_runway_point == 1 then
          return 2
        else
          return 1
        end
      end)())
      runways[selected_runway].points[selected_runway_point].x = x
      runways[selected_runway].points[selected_runway_point].y = y
    elseif "dragging_runway" == _exp_0 then
      runways[selected_runway].points[2].x = x + runway_drag_offset.x + runways[selected_runway].points[2].x - runways[selected_runway].points[1].x
      runways[selected_runway].points[2].y = y + runway_drag_offset.y + runways[selected_runway].points[2].y - runways[selected_runway].points[1].y
      runways[selected_runway].points[1].x = x + runway_drag_offset.x
      runways[selected_runway].points[1].y = y + runway_drag_offset.y
    end
  end
end
love.mousepressed = function(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    local _exp_0 = mode
    if "placing_runway" == _exp_0 then
      mode = "idle"
    elseif "editing_runway" == _exp_0 then
      mode = "idle"
    elseif "dragging_runway" == _exp_0 then
      mode = "idle"
    elseif "idle" == _exp_0 then
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
            mode = "dragging"
          end
          return 
        end
      end
      for id, rw in pairs(runways) do
        local x1, y1 = rw.points[1].x, rw.points[1].y
        local x2, y2 = rw.points[2].x, rw.points[2].y
        local dx, dy = x - x1, y - y1
        if math.sqrt(dx * dx + dy * dy) < 10 then
          selected_runway = id
          selected_runway_point = 1
          mode = "editing_runway"
        end
        dx, dy = x - x2, y - y2
        if math.sqrt(dx * dx + dy * dy) < 10 then
          selected_runway = id
          selected_runway_point = 2
          mode = "editing_runway"
        end
        local px = x2 - x1
        local py = y2 - y1
        local lsq = px * px + py * py
        local u = ((x - x1) * px + (y - y1) * py) / lsq
        if u > 1 then
          u = 1
        end
        if u < 0 then
          u = 0
        end
        local xx = x1 + u * px
        local yy = y1 + u * py
        dx = x - xx
        dy = y - yy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 12 then
          selected_runway = id
          mode = "dragging_runway"
          runway_drag_offset = {
            x = rw.points[1].x - x,
            y = rw.points[1].y - y
          }
          return 
        end
      end
      if button == 1 then
        if love.keyboard.isDown("lshift") then
          runways[next_runway] = {
            names = {
              {
                name = "1C",
                distance = 20,
                offset = {
                  angle = 0,
                  x = 10,
                  y = 0
                }
              },
              {
                name = "1C",
                distance = 20,
                offset = {
                  angle = 0,
                  x = 10,
                  y = 0
                }
              }
            },
            points = {
              {
                x = x,
                y = y
              },
              {
                x = x,
                y = y
              }
            }
          }
          selected_runway = next_runway
          selected = 0
          next_runway = next_runway + 1
          mode = "placing_runway"
        else
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
  end
end
love.mousereleased = function(x, y, button)
  imgui.MouseReleased(button)
  local _exp_0 = mode
  if "dragging" == _exp_0 then
    mode = "idle"
  end
end
love.wheelmoved = function(x, y)
  return imgui.WheelMoved(y)
end

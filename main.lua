-- Doug the Bug in Reality
-- Meta Quest 3 Mixed Reality + Grabbing + Flying animation

local bugPos = { x = 0, y = 1.5, z = -2 }
local bugScale = 0.8  -- kisebb bogár
local grabState = { left = false, right = false }
local grabbingHand = nil
local grabOffset = { x = 0, y = 0, z = 0 }

local flyAnim = {
  time = 0,
  -- Több irány: X, Y, Z tengely mind mozog
  speedX = 0.17,
  speedY = 0.11,
  speedZ = 0.13,
  ampX   = 1.0,
  ampY   = 0.35,
  ampZ   = 0.5,
  baseX  = 0,
  baseY  = 1.5,
  baseZ  = -2,
  -- Előző pozíció a forgáshoz
  prevX  = 0,
  prevZ  = -2,
}

local bugRotY = 0  -- jelenlegi forgás szög (radiánban)

function lovr.load()
  model = lovr.graphics.newModel('doug_the_bug.glb')

  if lovr.headset then
    lovr.headset.setPassthrough(true)
  end
end

function lovr.update(dt)
  flyAnim.time = flyAnim.time + dt

  if not grabbingHand then
    local prevX = bugPos.x
    local prevZ = bugPos.z

    -- 3D mozgás: X, Y, Z mind szinuszos, különböző sebességgel
    bugPos.x = flyAnim.baseX + math.sin(flyAnim.time * flyAnim.speedX * math.pi * 2) * flyAnim.ampX
    bugPos.y = flyAnim.baseY + math.sin(flyAnim.time * flyAnim.speedY * math.pi * 2) * flyAnim.ampY
    bugPos.z = flyAnim.baseZ + math.sin(flyAnim.time * flyAnim.speedZ * math.pi * 2) * flyAnim.ampZ

    -- Forgás: amerre mozdul, arra nézzen (X-Z síkban)
    local dx = bugPos.x - prevX
    local dz = bugPos.z - prevZ
    if math.abs(dx) > 0.0001 or math.abs(dz) > 0.0001 then
      bugRotY = math.atan2(dx, dz)
    end
  end

  -- Kontroller grabbing
  for _, hand in ipairs({ 'left', 'right' }) do
    local gripValue = lovr.headset.getAxis(hand, 'grip')

    if gripValue and gripValue > 0.7 then
      if not grabState[hand] then
        grabState[hand] = true

        local hx, hy, hz = lovr.headset.getPosition(hand)
        local dist = math.sqrt(
          (hx - bugPos.x)^2 +
          (hy - bugPos.y)^2 +
          (hz - bugPos.z)^2
        )

        if dist < 0.5 and not grabbingHand then
          grabbingHand = hand
          grabOffset.x = bugPos.x - hx
          grabOffset.y = bugPos.y - hy
          grabOffset.z = bugPos.z - hz
        end
      end

      if grabbingHand == hand then
        local hx, hy, hz = lovr.headset.getPosition(hand)
        local prevX = bugPos.x
        local prevZ = bugPos.z

        bugPos.x = hx + grabOffset.x
        bugPos.y = hy + grabOffset.y
        bugPos.z = hz + grabOffset.z

        local dx = bugPos.x - prevX
        local dz = bugPos.z - prevZ
        if math.abs(dx) > 0.0001 or math.abs(dz) > 0.0001 then
          bugRotY = math.atan2(dx, dz)
        end

        flyAnim.baseX = bugPos.x
        flyAnim.baseY = bugPos.y
        flyAnim.baseZ = bugPos.z
        flyAnim.time  = 0
      end

    else
      if grabState[hand] then
        grabState[hand] = false
        if grabbingHand == hand then
          grabbingHand = nil
        end
      end
    end
  end
end

function lovr.draw(pass)
  -- Pozíció + Y tengely körüli forgás
  local transform = lovr.math.newMat4()
  transform:translate(bugPos.x, bugPos.y, bugPos.z)
  transform:rotate(bugRotY, 0, 1, 0)
  transform:scale(bugScale)

  pass:draw(model, transform)
end
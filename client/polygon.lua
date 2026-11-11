Polygon = { active = false }

local KEYS = { add = 191, undo = 194, finish = 47, forward = 32, back = 33, left = 34, right = 35, up = 22, down = 36, fast = 21, slow = 19 }

local function camForward(cam)
    local rot = GetCamRot(cam, 2)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

function Polygon.DrawOutline(poly, z, r, g, b, height)
    if not poly or #poly < 2 then return end
    height = height or 2.0
    for i = 1, #poly do
        local a = poly[i]
        local c = poly[i % #poly + 1]
        if i < #poly or #poly >= 3 then
            DrawLine(a.x, a.y, z, c.x, c.y, z, r, g, b, 255)
            DrawLine(a.x, a.y, z + height, c.x, c.y, z + height, r, g, b, 120)
        end
        DrawLine(a.x, a.y, z, a.x, a.y, z + height, r, g, b, 160)
    end
end

function Polygon.Show(poly, z, ms)
    CreateThread(function()
        local untilAt = GetGameTimer() + (ms or 8000)
        while GetGameTimer() < untilAt do
            Polygon.DrawOutline(poly, z, 45, 212, 191, 2.0)
            Wait(0)
        end
    end)
end

function Polygon.Draw(opts)
    if Polygon.active then return nil end
    opts = opts or {}
    Polygon.active = true
    local ped = PlayerPedId()
    local origin = opts.origin or GetEntityCoords(ped)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, origin.x, origin.y, origin.z + 12.0)
    SetCamRot(cam, -55.0, 0.0, GetEntityHeading(ped), 2)
    SetCamFov(cam, 60.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 300, true, true)
    FreezeEntityPosition(ped, true)
    local corners = {}
    for _, c in ipairs(opts.start or {}) do corners[#corners + 1] = { x = c.x, y = c.y, z = c.z or origin.z } end
    local minZ, maxZ = math.huge, -math.huge
    local result = nil
    lib.showTextUI(Text('poly_hint', { label = opts.label or Text('poly_area') }), { position = 'left-center' })
    local speeds = (Config.Builder or {}).cameraSpeed or { normal = 6.0, fast = 18.0, slow = 1.5 }
    while Polygon.active do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, KEYS.add, true)
        EnableControlAction(0, KEYS.undo, true)
        local pos = GetCamCoord(cam)
        local rot = GetCamRot(cam, 2)
        SetCamRot(cam, math.max(-89.0, math.min(89.0, rot.x - GetDisabledControlNormal(0, 2) * 6.0)), 0.0, rot.z - GetDisabledControlNormal(0, 1) * 6.0, 2)
        local speed = speeds.normal
        if IsDisabledControlPressed(0, KEYS.fast) then speed = speeds.fast end
        if IsDisabledControlPressed(0, KEYS.slow) then speed = speeds.slow end
        speed = speed * GetFrameTime()
        local fwd = camForward(cam)
        local right = vector3(fwd.y, -fwd.x, 0.0)
        local move = vector3(0.0, 0.0, 0.0)
        if IsDisabledControlPressed(0, KEYS.forward) then move = move + fwd end
        if IsDisabledControlPressed(0, KEYS.back) then move = move - fwd end
        if IsDisabledControlPressed(0, KEYS.right) then move = move + right end
        if IsDisabledControlPressed(0, KEYS.left) then move = move - right end
        if IsDisabledControlPressed(0, KEYS.up) then move = move + vector3(0.0, 0.0, 1.0) end
        if IsDisabledControlPressed(0, KEYS.down) then move = move - vector3(0.0, 0.0, 1.0) end
        if #move > 0.0 then
            pos = pos + move * speed
            SetCamCoord(cam, pos.x, pos.y, pos.z)
        end
        SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
        local to = pos + fwd * 80.0
        local ray = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, to.x, to.y, to.z, 1 + 16, ped, 4)
        local _, hit, at = GetShapeTestResult(ray)
        local cursor = (hit == true or hit == 1) and at or nil
        local baseZ = (#corners > 0 and corners[1].z) or (cursor and cursor.z) or origin.z
        Polygon.DrawOutline(corners, baseZ, 45, 212, 191, 2.0)
        if cursor then
            DrawMarker(28, cursor.x, cursor.y, cursor.z + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 245, 165, 36, 200, false, false, 2, false)
            if #corners > 0 then
                local last, first = corners[#corners], corners[1]
                DrawLine(last.x, last.y, baseZ, cursor.x, cursor.y, cursor.z, 245, 165, 36, 255)
                DrawLine(first.x, first.y, baseZ, cursor.x, cursor.y, cursor.z, 245, 165, 36, 120)
            end
        end
        if IsDisabledControlJustPressed(0, KEYS.add) and cursor then
            corners[#corners + 1] = { x = cursor.x, y = cursor.y, z = cursor.z }
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        end
        if IsDisabledControlJustPressed(0, KEYS.undo) then
            if #corners == 0 then break end
            table.remove(corners)
        end
        if IsDisabledControlJustPressed(0, KEYS.finish) and #corners >= 3 then
            for _, c in ipairs(corners) do
                if c.z < minZ then minZ = c.z end
                if c.z > maxZ then maxZ = c.z end
            end
            result = { poly = {}, minZ = minZ - 2.0, maxZ = maxZ + (opts.height or 6.0) }
            for _, c in ipairs(corners) do result.poly[#result.poly + 1] = { x = Util.Round(c.x, 2), y = Util.Round(c.y, 2) } end
            break
        end
    end
    lib.hideTextUI()
    RenderScriptCams(false, true, 300, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    ClearFocus()
    FreezeEntityPosition(ped, false)
    Polygon.active = false
    return result
end

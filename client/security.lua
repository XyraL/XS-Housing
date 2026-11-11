Security = { viewing = false, alarms = {} }

local function v3(p) return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0) end

local NO_GLOVES = {
    male = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [18] = true, [26] = true, [52] = true, [53] = true, [54] = true, [55] = true, [56] = true, [57] = true, [58] = true, [59] = true, [60] = true, [61] = true, [62] = true, [112] = true, [113] = true, [114] = true, [118] = true, [125] = true, [132] = true },
    female = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [19] = true, [59] = true, [60] = true, [61] = true, [62] = true, [63] = true, [64] = true, [65] = true, [66] = true, [67] = true, [68] = true, [69] = true, [70] = true, [71] = true, [129] = true, [130] = true, [131] = true, [135] = true, [142] = true, [149] = true, [153] = true, [157] = true, [161] = true, [165] = true },
}

function Security.BareHands()
    local ok, gloved = pcall(function()
        local core = Framework.core or exports['qb-core']:GetCoreObject()
        return core.Functions.IsWearingGloves()
    end)
    if ok and type(gloved) == 'boolean' then return not gloved end
    local ped = PlayerPedId()
    local list = GetEntityModel(ped) == joaat('mp_m_freemode_01') and NO_GLOVES.male or NO_GLOVES.female
    return list[GetPedDrawableVariation(ped, 3)] == true
end

local function leavePrint(p, bare)
    if not Config.BreakIns.evidence or not bare then return end
    if GetResourceState('XS-PoliceSystem') == 'started' or GetResourceState('qb-policejob') ~= 'started' then return end
    local door = Housing.DoorOf(p)
    if door then TriggerServerEvent('evidence:server:CreateFingerDrop', v3(door)) end
end

function Security.InspectLock(p)
    local at = tonumber(p.forced)
    if not at then return Util.Notify(Text('lock_looks_fine'), 'inform') end
    local mins = math.max(1, math.floor((Util.Now() - at) / 60))
    local ago = mins < 120 and Text('ago_minutes', { n = mins }) or Text('ago_hours', { n = math.floor(mins / 60) })
    Util.Notify(Text('lock_forced_seen', { ago = ago }), 'inform')
end

function Security.BreakIn(p)
    local ok, info = Housing.Call('breakInCheck', p.id)
    if not ok then return Util.Notify(info or Text('err_failed'), 'error') end
    local ped = PlayerPedId()
    local dict, clip = 'mp_common_heist', 'pick_door'
    if Util.LoadDict(dict) then TaskPlayAnim(ped, dict, clip, 3.0, 3.0, -1, 49, 0.0, false, false, false) end
    local passed = lib.skillCheck(info.difficulty or { 'medium' }, { 'w', 'a', 's', 'd' })
    StopAnimTask(ped, dict, clip, 1.0)
    local bare = Security.BareHands()
    leavePrint(p, bare)
    local done, msg = Housing.Call('breakInResult', p.id, passed == true, bare)
    if done then
        Util.Notify(Text('breakin_success', { m = Config.BreakIns.openMinutes }), 'success')
    else
        Util.Notify(msg or Text('lockpick_failed'), 'error')
    end
end

function Security.Raid(p)
    local ped = PlayerPedId()
    local ok = lib.progressCircle({
        duration = 4500, label = Text('raid_breaching'), position = 'bottom', useWhileDead = false, canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missheistfbi3b_ig7', clip = 'lift_fibagent_loop' },
    })
    ClearPedTasks(ped)
    if not ok then return end
    local done, err = Housing.Call('raid', p.id)
    if done then
        Util.Notify(Text('raid_open', { m = Config.Raids.openMinutes }), 'success')
        PlaySoundFromCoord(-1, 'Barge_Door_Metal', p.door.x, p.door.y, p.door.z, 'DLC_Security_Door_Barge_Sounds', false, 0, false)
    else
        Util.Notify(err or Text('err_failed'), 'error')
    end
end

local function camRotation(c)
    return vector3(c.rx or -10.0, 0.0, c.w or 0.0)
end

function Security.Cameras(id)
    if Security.viewing then return end
    local ok, list = Housing.Call('cameras', id)
    if not ok then return Util.Notify(list or Text('err_failed'), 'error') end
    if type(list) ~= 'table' or #list == 0 then return Util.Notify(Text('no_cameras'), 'error') end
    Security.viewing = true
    local index = 1
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local function show(i)
        local c = list[i]
        SetCamCoord(cam, c.x + 0.0, c.y + 0.0, c.z + 0.0)
        local r = camRotation(c)
        SetCamRot(cam, r.x, r.y, r.z, 2)
        SetCamFov(cam, 70.0)
        SetFocusPosAndVel(c.x + 0.0, c.y + 0.0, c.z + 0.0, 0.0, 0.0, 0.0)
    end
    show(index)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetTimecycleModifier('CAMERA_secuirity')
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    local panX, panZ = 0.0, 0.0
    while Security.viewing do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 249, true)
        local c = list[index]
        local text = ('%s  %d/%d\n%s'):format(c.label or Text('camera_n', { n = index }), index, #list, Text('camera_hint'))
        SetTextFont(4)
        SetTextScale(0.0, 0.42)
        SetTextColour(255, 255, 255, 230)
        SetTextOutline()
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(0.03, 0.04)
        local dx, dy = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
        panZ = math.max(-70.0, math.min(70.0, panZ - dx * 4.0))
        panX = math.max(-45.0, math.min(35.0, panX - dy * 4.0))
        local base = camRotation(c)
        SetCamRot(cam, base.x + panX, 0.0, base.z + panZ, 2)
        if IsDisabledControlJustPressed(0, 175) or IsDisabledControlJustPressed(0, 24) then
            index = index % #list + 1
            panX, panZ = 0.0, 0.0
            show(index)
        elseif IsDisabledControlJustPressed(0, 174) or IsDisabledControlJustPressed(0, 25) then
            index = (index - 2) % #list + 1
            panX, panZ = 0.0, 0.0
            show(index)
        elseif IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
            break
        end
    end
    Security.viewing = false
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    ClearFocus()
    FreezeEntityPosition(ped, false)
end

RegisterNetEvent('XS-Housing:client:alarm', function(id, door)
    if not door then return end
    local key = tostring(id)
    if Security.alarms[key] then return end
    local untilAt = GetGameTimer() + 60000
    Security.alarms[key] = true
    CreateThread(function()
        local sound = GetSoundId()
        PlaySoundFromCoord(sound, 'Burglar_Bell', door.x + 0.0, door.y + 0.0, door.z + 0.0, 'Generic_Alarms', false, 0, false)
        while GetGameTimer() < untilAt do
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - v3(door)) < 60.0 then
                DrawLightWithRange(door.x + 0.0, door.y + 0.0, door.z + 1.5, 255, 40, 40, 6.0, (GetGameTimer() % 800 < 400) and 4.0 or 0.5)
                Wait(0)
            else
                Wait(500)
            end
        end
        StopSound(sound)
        ReleaseSoundId(sound)
        Security.alarms[key] = nil
    end)
end)

RegisterNetEvent('XS-Housing:client:knockSound', function(door, knock)
    if not door then return end
    local pos = GetEntityCoords(PlayerPedId())
    local inside = Inside.state ~= nil
    if not inside and #(pos - v3(door)) > 25.0 then return end
    if knock then
        PlaySoundFrontend(-1, 'Generic_Door_Closed', 'GTAO_Script_Doors_Sounds', true)
    else
        PlaySoundFrontend(-1, 'DOOR_BUZZ', 'MP_PLAYER_APARTMENT', true)
    end
end)

RegisterNetEvent('XS-Housing:client:ring', function(data)
    if type(data) ~= 'table' then return end
    local title = data.knock and Text('knock_title') or Text('ring_title')
    local body = Text(data.knock and 'knock_body' or 'ring_body', { name = data.name or Text('someone'), place = data.place or '' })
    if not data.inside then PlaySoundFrontend(-1, 'DOOR_BUZZ', 'MP_PLAYER_APARTMENT', true) end
    if not data.inside and not data.remote then
        Util.Notify(body, 'inform')
        return
    end
    CreateThread(function()
        local answer = lib.alertDialog({ header = title, content = body .. '\n\n' .. Text('let_in_ask'), centered = true, cancel = true, labels = { confirm = Text('let_in_yes'), cancel = Text('let_in_no') } })
        if answer == 'confirm' then Util.Result(Housing.Call('letIn', data.id, data.from)) end
    end)
end)

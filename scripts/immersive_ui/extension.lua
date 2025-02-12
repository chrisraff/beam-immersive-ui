local M = {}
M.logTag = 'immersive_ui'
M.tick = 0

M.settings = {
    enterImmersionSpeed = 10 / 3.6, -- 10 kph in m/s
    exitImmersionSpeed = 1 / 3.6,  -- 1 kph in m/s
    exitImmersionWaitTime = 1.0, -- seconds
    immersiveUiEnabled = true
}

M.uiState = ''
M.exitImmersionTimer = 0
M.immersed = false
M.wasControllingImmersion = false

local function onExtensionLoaded()
    log('I', M.logTag, '>>>>>>>>>>>>>>>>>>>>> onExtensionLoaded from sopo imm. ui')

    setExtensionUnloadMode(M, 'manual')

    -- load the settings
    local settingsFile = jsonReadFile('settings/beam_immersive_ui/settings.json')
    if settingsFile then
        for key, value in pairs(M.settings) do
            if settingsFile[key] == nil then
                log('I', M.logTag, 'populating ' .. key .. ' from default')
                settingsFile[key] = value
            end
        end
        M.settings = settingsFile
    end
end

local function setVisibility(visible)
    if visible == nil then
        ui_visibility.toggle()
        return
    end

    if visible and not ui_visibility.get() then
        ui_visibility.toggle()
    elseif not visible and ui_visibility.get() then
        ui_visibility.toggle()
    end
end

local function updateUIVisibility()
    local veh = be:getPlayerVehicle(0)
    if not veh then return end

    local speed = veh:getVelocity():length()
    local isInReplay = core_replay.state.state == "playback"
    local isPlaying = M.uiState == "play"
    local isDriverCam = core_camera.getActiveCamName() == "driver"
    local isPaused = simTimeAuthority.getPause()

    -- log('I', M.logTag, 'speed: ' .. speed .. ' isInReplay: ' .. tostring(isInReplay) .. ' isPlaying: ' .. tostring(isPlaying))

    local shouldControlImmersion = M.settings.immersiveUiEnabled and isPlaying and isDriverCam and not isInReplay and not isPaused

    -- track immersion exit timer
    if M.immersed and speed < M.settings.exitImmersionSpeed then
        M.exitImmersionTimer = M.exitImmersionTimer + 0.1
    else
        M.exitImmersionTimer = 0
    end

    -- compute immersion
    local newImmersed = M.immersed

    if speed > M.settings.enterImmersionSpeed then
        newImmersed = true
    elseif speed < M.settings.exitImmersionSpeed and M.exitImmersionTimer >= M.settings.exitImmersionWaitTime then
        newImmersed = false
    end

    if shouldControlImmersion then
        -- only update if the state has changed
        if not (M.immersed == newImmersed) or not (M.wasControllingImmersion == shouldControlImmersion) then
            setVisibility(not newImmersed)
        end
    elseif M.wasControllingImmersion then
        setVisibility(true)
    end

    M.immersed = newImmersed

    M.wasControllingImmersion = shouldControlImmersion
end

local function onUiChangedState(curState, prevState)
    M.uiState = curState
    M.updateUIVisibility()
end

local function onUpdate(dt)
    M.tick = M.tick + dt

    -- only perform logic at 10hz
    if M.tick < 0.1 then return end

    M.tick = M.tick - 0.1

    M.updateUIVisibility()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUiChangedState = onUiChangedState
M.updateUIVisibility = updateUIVisibility
M.onUpdate = onUpdate

return M

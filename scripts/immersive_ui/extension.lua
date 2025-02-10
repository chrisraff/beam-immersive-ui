M = {}
M.logTag = 'immersive_ui'
M.tick = 0

M.hideThreshold = 10 / 3.6 -- 10 kph in m/s
M.showThreshold = 1 / 3.6  -- 1 kph in m/s
M.immersionExitTimeout = 1.0 -- seconds

M.uiState = ''
M.immersionExitTimer = 0
M.immersiveUiEnabled = true
M.immersed = false
M.wasControllingImmersion = false

local function onExtensionLoaded()
    log('I', M.logTag, '>>>>>>>>>>>>>>>>>>>>> onExtensionLoaded from sopo imm. ui')

    setExtensionUnloadMode(M, 'manual')
end

local function setVisibility(visible)
    if visible == nil then
        ui_visibility.toggle()
        return
    end

    if visible and not ui_visibility.get() then
        log('I', M.logTag, 'Showing UI')
        ui_visibility.toggle()
    elseif not visible and ui_visibility.get() then
        log('I', M.logTag, 'Hiding UI')
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

    local shouldControlImmersion = M.immersiveUiEnabled and isPlaying and isDriverCam and not isInReplay and not isPaused

    -- track immersion exit timer
    if M.immersed and speed < M.showThreshold then
        M.immersionExitTimer = M.immersionExitTimer + 0.1
    else
        M.immersionExitTimer = 0
    end

    -- compute immersion
    local newImmersed = M.immersed

    if speed > M.hideThreshold then
        newImmersed = true
    elseif speed < M.showThreshold and M.immersionExitTimer >= M.immersionExitTimeout then
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

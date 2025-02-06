M = {}
M.logTag = 'immersive_ui'
M.tick = 0

M.uiState = ''
M.hideThreshold = 10 / 3.6 -- 10 kph in m/s
M.showThreshold = 1 / 3.6  -- 1 kph in m/s
M.immersiveUiEnabled = true
M.immersed = false
M.wasControlingImmersion = false

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
    local isPaused = simTimeAuthority.getPause()

    -- log('I', M.logTag, 'speed: ' .. speed .. ' isInReplay: ' .. tostring(isInReplay) .. ' isPlaying: ' .. tostring(isPlaying))

    local shouldControlImmersion = M.immersiveUiEnabled and isPlaying and not isInReplay and not isPaused

    if shouldControlImmersion then
        local newImmersed = false
        if speed > M.hideThreshold then
            newImmersed = true
        elseif speed < M.showThreshold then
            newImmersed = false
        end
        -- only update if the state has changed
        if not M.immersed == newImmersed or not M.wasControlingImmersion == shouldControlImmersion then
            M.immersed = newImmersed
            setVisibility(not M.immersed)
        end
    elseif M.wasControlingImmersion then
        setVisibility(true)
    end

    M.wasControlingImmersion = shouldControlImmersion
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

local function test()
    ui_visibility.toggle()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUiChangedState = onUiChangedState
M.updateUIVisibility = updateUIVisibility
M.onUpdate = onUpdate
M.test = test
return M

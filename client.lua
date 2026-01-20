local PromptCamera, PromptSnap, PromptFx, PromptExit
local PromptZoomIn, PromptZoomOut
local PromptGroup = GetRandomIntInRange(0, 0xffffff)

local isPhotoModeActive = false
local currentFilterIndex = 1
local isProcessing = false

local currentFov = 50.0
local lastEquipTime = 0
local zoomSpeed = 1.0

local WEAPON_CAMERA_HASH = -1016714371
local WEAPON_CAMERA_ADVANCED_HASH = 332793555

local scriptCam = nil
local cameraProp = nil
local CAMERA_PROP_HASH = -1721993797

local currentUIState = "idle"
local basePedHeading = 0.0
local activeCameraType = nil
local wasHoldingCamera = false

local currentCamRot = vector3(0.0, 0.0, 0.0)

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function IsHoldingRegularCamera()
    return Citizen.InvokeNative(0x8425C5F057012DAB, PlayerPedId()) == WEAPON_CAMERA_HASH
end

local function IsHoldingAdvancedCamera()
    return Citizen.InvokeNative(0x8425C5F057012DAB, PlayerPedId()) == WEAPON_CAMERA_ADVANCED_HASH
end

CreateThread(function()
    while true do
        Wait(3000) 
        if isPhotoModeActive and activeCameraType == "REGULAR" then return end 

        local ped = PlayerPedId()
        local props = GetGamePool('CObject')
        local holdingRegular = IsHoldingRegularCamera()
        
        for i=1, #props do
            local obj = props[i]
            if IsEntityAttachedToEntity(obj, ped) and GetEntityModel(obj) == CAMERA_PROP_HASH then
                if not holdingRegular then DeleteObject(obj) end
            end
        end
    end
end)

CreateThread(function()
    Wait(1000) 
    
    PromptZoomIn = PromptRegisterBegin()
    PromptSetControlAction(PromptZoomIn, Config.ZoomPlusKey)
    PromptSetText(PromptZoomIn, CreateVarString(10, 'LITERAL_STRING', Config.LocaleZoomPlus))
    PromptSetEnabled(PromptZoomIn, 0)
    PromptSetVisible(PromptZoomIn, 0)
    PromptSetStandardMode(PromptZoomIn, 1)
    PromptSetGroup(PromptZoomIn, PromptGroup)
    PromptRegisterEnd(PromptZoomIn)

    PromptZoomOut = PromptRegisterBegin()
    PromptSetControlAction(PromptZoomOut, Config.ZoomMinusKey)
    PromptSetText(PromptZoomOut, CreateVarString(10, 'LITERAL_STRING', Config.LocaleZoomMinus))
    PromptSetEnabled(PromptZoomOut, 0)
    PromptSetVisible(PromptZoomOut, 0)
    PromptSetStandardMode(PromptZoomOut, 1)
    PromptSetGroup(PromptZoomOut, PromptGroup)
    PromptRegisterEnd(PromptZoomOut)

    PromptFx = PromptRegisterBegin()
    PromptSetControlAction(PromptFx, Config.CameraFiltersKey)
    PromptSetText(PromptFx, CreateVarString(10, 'LITERAL_STRING', Config.LocaleCameraFilters))
    PromptSetEnabled(PromptFx, 0)
    PromptSetVisible(PromptFx, 0)
    PromptSetStandardMode(PromptFx, 1)
    PromptSetGroup(PromptFx, PromptGroup)
    PromptRegisterEnd(PromptFx)

    PromptSnap = PromptRegisterBegin()
    PromptSetControlAction(PromptSnap, Config.TakePhotoKey)
    PromptSetText(PromptSnap, CreateVarString(10, 'LITERAL_STRING', Config.LocaleTakePhoto))
    PromptSetEnabled(PromptSnap, 0)
    PromptSetVisible(PromptSnap, 0)
    PromptSetStandardMode(PromptSnap, 1)
    PromptSetGroup(PromptSnap, PromptGroup)
    PromptRegisterEnd(PromptSnap)

    PromptExit = PromptRegisterBegin()
    PromptSetControlAction(PromptExit, Config.ExitCameraModeKey)
    PromptSetText(PromptExit, CreateVarString(10, 'LITERAL_STRING', Config.LocaleExitCameraMode))
    PromptSetEnabled(PromptExit, 0)
    PromptSetVisible(PromptExit, 0)
    PromptSetStandardMode(PromptExit, 1)
    PromptSetGroup(PromptExit, PromptGroup)
    PromptRegisterEnd(PromptExit)

    PromptCamera = PromptRegisterBegin()
    PromptSetControlAction(PromptCamera, Config.CameraModeKey)
    PromptSetText(PromptCamera, CreateVarString(10, 'LITERAL_STRING', Config.LocaleCameraMode))
    PromptSetEnabled(PromptCamera, 0)
    PromptSetVisible(PromptCamera, 0) 
    PromptSetStandardMode(PromptCamera, 1)
    PromptSetGroup(PromptCamera, PromptGroup)
    PromptRegisterEnd(PromptCamera)
end)

CreateThread(function()
    while true do
        local time = GetGameTimer()
        local isReg = IsHoldingRegularCamera()
        local isAdv = IsHoldingAdvancedCamera()
        local isHolding = isReg or isAdv
        
        if isHolding and not wasHoldingCamera then
            lastEquipTime = time
        end
        wasHoldingCamera = isHolding

        local targetUIState = "idle"
        if isPhotoModeActive then
            targetUIState = "active"
        elseif isHolding and (time - lastEquipTime > 1500) then
            targetUIState = "holding"
        end

        if targetUIState ~= currentUIState then
            currentUIState = targetUIState
            
            if targetUIState == "active" then
                PromptSetEnabled(PromptCamera, 0)
                PromptSetVisible(PromptCamera, 0)
                PromptSetEnabled(PromptSnap, 1)
                PromptSetVisible(PromptSnap, 1)
                PromptSetEnabled(PromptExit, 1)
                PromptSetVisible(PromptExit, 1)
                
                if activeCameraType == "ADVANCED" then
                    PromptSetEnabled(PromptFx, 1)
                    PromptSetVisible(PromptFx, 1)
                    PromptSetEnabled(PromptZoomIn, 1)
                    PromptSetVisible(PromptZoomIn, 1)
                    PromptSetEnabled(PromptZoomOut, 1)
                    PromptSetVisible(PromptZoomOut, 1)
                else
                    PromptSetEnabled(PromptFx, 0)
                    PromptSetVisible(PromptFx, 0)
                    PromptSetEnabled(PromptZoomIn, 0)
                    PromptSetVisible(PromptZoomIn, 0)
                    PromptSetEnabled(PromptZoomOut, 0)
                    PromptSetVisible(PromptZoomOut, 0)
                end

            elseif targetUIState == "holding" then
                PromptSetEnabled(PromptCamera, 1)
                PromptSetVisible(PromptCamera, 1)
                PromptSetEnabled(PromptSnap, 0)
                PromptSetVisible(PromptSnap, 0)
                PromptSetEnabled(PromptFx, 0)
                PromptSetVisible(PromptFx, 0)
                PromptSetEnabled(PromptExit, 0)
                PromptSetVisible(PromptExit, 0)
                PromptSetEnabled(PromptZoomIn, 0)
                PromptSetVisible(PromptZoomIn, 0)
                PromptSetEnabled(PromptZoomOut, 0)
                PromptSetVisible(PromptZoomOut, 0)

            else
                PromptSetEnabled(PromptCamera, 0)
                PromptSetVisible(PromptCamera, 0)
                PromptSetEnabled(PromptSnap, 0)
                PromptSetVisible(PromptSnap, 0)
                PromptSetEnabled(PromptFx, 0)
                PromptSetVisible(PromptFx, 0)
                PromptSetEnabled(PromptExit, 0)
                PromptSetVisible(PromptExit, 0)
                PromptSetEnabled(PromptZoomIn, 0)
                PromptSetVisible(PromptZoomIn, 0)
                PromptSetEnabled(PromptZoomOut, 0)
                PromptSetVisible(PromptZoomOut, 0)
            end
        end

        if isPhotoModeActive then
            Wait(0) 
            
            DisableAllControlActions(0)
            EnableControlAction(0, `INPUT_FRONTEND_PAUSE_ALTERNATE`, true) 
            EnableControlAction(0, `INPUT_MP_TEXT_CHAT_ALL`, true)       
            EnableControlAction(0, `INPUT_LOOK_LR`, true)
            EnableControlAction(0, `INPUT_LOOK_UD`, true)
            EnableControlAction(0, `INPUT_FRONTEND_ACCEPT`, true)  
            EnableControlAction(0, `INPUT_FRONTEND_CANCEL`, true)   
            EnableControlAction(0, `INPUT_ATTACK`, true)           
            EnableControlAction(0, Config.ExitCameraModeKey, true) 

            EnableControlAction(0, Config.ZoomPlusKey, true)
            EnableControlAction(0, Config.ZoomMinusKey, true)
            EnableControlAction(0, Config.CameraFiltersKey, true)

            if not isHolding then 
                StopPhotoMode()
            else
                if activeCameraType == "ADVANCED" then
                    if IsDisabledControlPressed(0, Config.ZoomPlusKey) then
                        currentFov = currentFov - zoomSpeed
                    elseif IsDisabledControlPressed(0, Config.ZoomMinusKey) then
                        currentFov = currentFov + zoomSpeed
                    end
                    
                    currentFov = clamp(currentFov, 10.0, 60.0)
                    SetCamFov(scriptCam, currentFov)
                end

                if scriptCam then
                    local rawRot = GetGameplayCamRot(2)
                    
                    local targetPitch = clamp(rawRot.x, -45.0, 45.0)
                    
                    local targetYawRaw = rawRot.z
                    local yawDiff = targetYawRaw - basePedHeading
                    
                    while yawDiff > 180.0 do yawDiff = yawDiff - 360.0 end
                    while yawDiff < -180.0 do yawDiff = yawDiff + 360.0 end
                    yawDiff = clamp(yawDiff, -45.0, 45.0)
                    local targetYaw = basePedHeading + yawDiff

                    local smoothFactor = Config.CameraSmoothness
                    
                    local newX = currentCamRot.x + (targetPitch - currentCamRot.x) * smoothFactor
                    local newZ = currentCamRot.z + (targetYaw - currentCamRot.z) * smoothFactor
                    currentCamRot = vector3(newX, 0.0, newZ)

                    SetCamRot(scriptCam, currentCamRot.x, 0.0, currentCamRot.z, 2)
                end

                PromptSetActiveGroupThisFrame(PromptGroup, CreateVarString(10, 'LITERAL_STRING', Config.LocaleCameraMode))

                if not isProcessing then
                    if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptSnap) then
                        TakePhoto()
                    elseif activeCameraType == "ADVANCED" then
                        if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptFx) then
                            ChangeFilter(1)
                        elseif Citizen.InvokeNative(0xC92AC953F0A982AE, PromptExit) then
                            StopPhotoMode()
                        end
                    elseif Citizen.InvokeNative(0xC92AC953F0A982AE, PromptExit) then
                        StopPhotoMode()
                    end
                end
            end

        elseif isHolding then
            Wait(5) 
            PromptSetActiveGroupThisFrame(PromptGroup, CreateVarString(10, 'LITERAL_STRING', 'Камера'))

            if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptCamera) then 
                if isReg then StartRegularMode() elseif isAdv then StartAdvancedMode() end
            end

        else
            Wait(200)
        end
    end
end)

function StartRegularMode()
    local ped = PlayerPedId()
    activeCameraType = "REGULAR"
    
    ClearPedTasks(ped)
    RequestAnimDict("mech_weapons_special@camera@base@sweep@")
    local timeout = 0
    while not HasAnimDictLoaded("mech_weapons_special@camera@base@sweep") and timeout < 50 do
        Citizen.Wait(50)
        timeout = timeout + 1
    end
    TaskPlayAnim(ped, "mech_weapons_special@camera@base@sweep", "aim_med_0", 8.0, -8.0, -1, 3, 0, true, 0, false, 0, false)
    Wait(300) 
    
    basePedHeading = GetEntityHeading(ped)
    
    TriggerEvent("vorp:showUi", false)
    DisplayRadar(false)
    FreezeEntityPosition(ped, true)
    
    local initialRot = GetGameplayCamRot(2)
    currentCamRot = vector3(initialRot.x, 0.0, initialRot.z)
    
    scriptCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1) 
    AttachCamToPedBone(scriptCam, ped, 21030, 0.0, 0.2, 0.0, true)
    SetCamNearClip(scriptCam, 0.25)
    currentFov = 50.0
    SetCamFov(scriptCam, currentFov)
    RenderScriptCams(1, 0, scriptCam, true, true)
    
    isPhotoModeActive = true
    AnimpostfxPlay("CameraViewfinderStudioPosse")
end

function StartAdvancedMode()
    local ped = PlayerPedId()
    activeCameraType = "ADVANCED"
    
    ClearPedTasks(ped)
    RequestAnimDict("mech_weapons_special@camera@base@sweep@")
    local timeout = 0
    while not HasAnimDictLoaded("mech_weapons_special@camera@base@sweep") and timeout < 50 do
        Citizen.Wait(50)
        timeout = timeout + 1
    end
    TaskPlayAnim(ped, "mech_weapons_special@camera@base@sweep", "aim_med_0", 8.0, -8.0, -1, 3, 0, true, 0, false, 0, false)
    Wait(300) 
    
    basePedHeading = GetEntityHeading(ped)
    
    TriggerEvent("vorp:showUi", false)
    DisplayRadar(false)
    FreezeEntityPosition(ped, true)
    
    local initialRot = GetGameplayCamRot(2)
    currentCamRot = vector3(initialRot.x, 0.0, initialRot.z)
    
    scriptCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1) 
    AttachCamToPedBone(scriptCam, ped, 21030, 0.0, 0.2, 0.0, true)
    SetCamNearClip(scriptCam, 0.25)
    currentFov = 50.0
    SetCamFov(scriptCam, currentFov)
    
    RenderScriptCams(1, 0, scriptCam, true, true)
    isPhotoModeActive = true
    
    AnimpostfxStop(Config.Filters[currentFilterIndex].effect)
    AnimpostfxPlay("CameraViewfinderStudioPosse")

    UpdateFilterPromptText()
end

function StopPhotoMode()
    local ped = PlayerPedId()
    
    if scriptCam then
        DestroyCam(scriptCam, false)
        RenderScriptCams(0, 0, 0, true, false)
        scriptCam = nil
    end
    
    if cameraProp then
        SetEntityAlpha(cameraProp, 255, false)
        cameraProp = nil
    end
    
    FreezeEntityPosition(ped, false)
	
    ClearPedTasks(ped)
    
    AnimpostfxStop("CameraViewfinderStudioPosse")
    if activeCameraType == "ADVANCED" and Config.Filters[currentFilterIndex].effect ~= "" then
        AnimpostfxStop(Config.Filters[currentFilterIndex].effect)
    end
    
    TriggerEvent("vorp:showUi", true)
    DisplayRadar(true)
    
    isPhotoModeActive = false
    activeCameraType = nil
end

function UpdateFilterPromptText()
    if PromptFx then
        local label = Config.LocaleFilterString .. Config.Filters[currentFilterIndex].name
        PromptSetText(PromptFx, CreateVarString(10, 'LITERAL_STRING', label))
    end
end

function ChangeFilter(direction)
    local oldEffect = Config.Filters[currentFilterIndex].effect
    AnimpostfxStop(oldEffect)
    AnimpostfxStop("CameraViewfinderStudioPosse")

    currentFilterIndex = currentFilterIndex + direction
    if currentFilterIndex > #Config.Filters then currentFilterIndex = 1 end
    if currentFilterIndex < 1 then currentFilterIndex = #Config.Filters end
    
    local newEffect = Config.Filters[currentFilterIndex].effect
    if newEffect ~= "" then AnimpostfxPlay(newEffect) else AnimpostfxPlay("CameraViewfinderStudioPosse") end
    
    UpdateFilterPromptText()
end

function TakePhoto()
    isProcessing = true
    
    PrepareSoundWithEntity("Take_Photo", PlayerPedId(), "CAMERA_SOUNDSET", -2)
    PlaySoundFromEntity("Take_Photo", PlayerPedId(), "CAMERA_SOUNDSET", false, 0, 0)
    
    AnimpostfxPlay("CameraTransitionFlash")
    Wait(600)

    if Config.UseScreenshotBasic then
        exports['screenshot-basic']:requestScreenshotUpload(Config.DiscordWebhook or "files", Config.PhotoItemName or "photo", function(data)
            TriggerServerEvent('vorp_camera:processPhoto', nil)
        end)
    else
        Citizen.InvokeNative(0xD45547D8396F002A)
        Citizen.InvokeNative(0xA15BFFC0A01B34E1)
        Citizen.InvokeNative(0xFA91736933AB3D93,true)
        Citizen.InvokeNative(0x8B3296278328B5EB,2)
        Citizen.InvokeNative(0x2705D18C11B61046,false)
        Citizen.InvokeNative(0xD1031B83AC093BC7,"SetRegionPhotoTakenStat")
        Citizen.InvokeNative(0x9937FACBBF267244,"SetDistrictPhotoTakenStat")
        Citizen.InvokeNative(0x8952E857696B8A79,"SetStatePhotoTakenStat")
        Citizen.InvokeNative(0x57639FD876B68A91,0)
        LaunchAppWithEntry("social_club_feed", "launch_to_photos")
    end
    
    AnimpostfxStop("CameraTransitionFlash")
    
    isPhotoModeActive = false
    isProcessing = false
    Wait(200)
    StopPhotoMode()
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    local ped = PlayerPedId()
    if scriptCam then
        DestroyCam(scriptCam, false)
        RenderScriptCams(0, 0, 0, true, false)
    end
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    AnimpostfxStop("CameraViewfinderStudioPosse")
    AnimpostfxStop(Config.Filters[currentFilterIndex].effect)
    DisplayRadar(true)
    TriggerEvent("vorp:showUi", true)
end)
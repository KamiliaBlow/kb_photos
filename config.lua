Config = {}

--Config.PhotoItemName = "photo_developed" 
Config.DiscordWebhook = ""

Config.CamOffset = {x = 0.0, y = 0.1, z = 0.0} 
Config.UseScreenshotBasic = false 

-- --- Camera setting ---
Config.CameraSmoothness = 0.15

-- --- Translate ---
Config.LocaleCameraMode = "Photo mode"
Config.LocaleTakePhoto = "Take photo"
Config.LocaleZoomPlus = "Zoom +"
Config.LocaleZoomMinus = "Zoom -"
Config.LocaleCameraFilters = "Filter"
Config.LocaleExitCameraMode = "Back"
Config.LocaleFilterString = "Filter: "

Config.LocalePrompt = 'Camera'

-- --- Control Keys (Hashes) ---
Config.CameraModeKey = 0xE8342FF2 -- LEFT ALT
Config.TakePhotoKey = 0x07CE1E61 -- LMB
Config.ZoomPlusKey = 0x62800C92 -- SCROLL UP
Config.ZoomMinusKey = 0x8BDE7443 -- SCROLL DOWN
Config.CameraFiltersKey = 0xCEE12B50 -- MMB
Config.ExitCameraModeKey = 0xF84FA74F -- RMB

-- Effects list
Config.Filters = {
    {name = "Regular", effect = ""},
    {name = "Sepia 1", effect = "PhotoMode_FilterVintage01"},
    {name = "Sepia 2", effect = "PhotoMode_FilterVintage02"},
    {name = "B&W", effect = "PhotoMode_FilterGame04"},
    {name = "Bright", effect = "PhotoMode_FilterGame02"},
    {name = "Dark", effect = "PhotoMode_FilterVintage10"},
    {name = "Movie", effect = "PhotoMode_FilterModern01"},
    {name = "Old", effect = "PhotoMode_FilterVintage05"}
}
function createFonts(scale)
    print("Creating fonts...")
    
    surface.CreateFont("plyNickFont", {
        font = "D-DIN",
        size = 72 * scale,
        weight = 600
    })
    surface.CreateFont("textFont", {
        font = "D-DIN",
        size = 32 * scale
    })
    surface.CreateFont("textSmallFont", {
        font = "D-DIN",
        size = 12 * scale
    })
    surface.CreateFont("TLOU_Font_Ammo_Small", {
        font = "D-DIN",
        size = 26 * scale,
        weight = 500,
    })
    surface.CreateFont("TLOU_Font_Ammo_Big", {
        font = "D-DIN", 
        size = 36 * scale,
        weight = 500,
    })
    surface.CreateFont("jf_parts_counter", {
        font = "D-DIN",
        size = 36 * scale,
        weight = 600,
    })
    surface.CreateFont("jf_radar_lives", {
        font = "D-DIN",
        size = 32 * scale,
        weight = 500,
    })
    surface.CreateFont("jf_radar_lives_big", {
        font = "D-DIN",
        size = 46 * scale,
        weight = 500,
    })
    surface.CreateFont("jf_teammate_name", {
        font = "D-DIN",
        size = 16 * scale,
        weight = 600,
    })
end
createFonts(ScrH() / 1080)

hook.Add("OnScreenSizeChanged", "jf_create_fonts", function()
    createFonts(ScrH() / 1080)
end)
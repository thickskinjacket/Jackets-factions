function createFonts()
    print("Creating fonts...")
    
    surface.CreateFont("plyNickFont", {
        font = "D-DIN",
        size = 72 * (ScrW() / 1600) 
    })
    surface.CreateFont("textFont", {
        font = "D-DIN",
        size = 32 * (ScrW() / 1600)
    })
    surface.CreateFont("textSmallFont", {
        font = "D-DIN",
        size = 12 * (ScrW() / 1600)
    })
    surface.CreateFont("TLOU_Font_Ammo_Small", {
        font = "Roboto",
        size = 26 * scale,
        weight = 500,
    })

    surface.CreateFont("TLOU_Font_Ammo_Big", {
        font = "Roboto", 
        size = 36 * scale,
        weight = 500,
    })
end
createFonts(ScrH() / 1080)

hook.Add("OnScreenSizeChanged", "jf_create_fonts", function()
    createFonts(ScrH() / 1080)
end)
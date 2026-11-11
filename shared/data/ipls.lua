local CLUTTER_HI = {
    'Apart_Hi_Strip_A', 'Apart_Hi_Strip_B', 'Apart_Hi_Strip_C',
    'Apart_Hi_Booze_A', 'Apart_Hi_Booze_B', 'Apart_Hi_Booze_C',
    'Apart_Hi_Smokes_A', 'Apart_Hi_Smokes_B', 'Apart_Hi_Smokes_C'
}

local CULL_DEL_PERRO = { 'sm_14_emissive', 'hei_sm_14_bld2' }
local CULL_INTEGRITY = { 'hei_dt1_03_build1x', 'DT1_Emissive_DT1_03_b1', 'dt1_03_dt1_Emissive_b1' }
local CULL_RICHARDS = { 'hei_bh1_08_bld2', 'bh1_emissive_bh1_08', 'bh1_08_bld2_LOD', 'bh1_08_em' }
local CULL_TINSEL = { 'apa_ss1_02_building01', 'SS1_02_Building01_LOD' }

local function penthouseStyles(suffix, ids)
    local names = {
        { 'modern', 'Modern' }, { 'moody', 'Moody' }, { 'vibrant', 'Vibrant' }, { 'sharp', 'Sharp' },
        { 'monochrome', 'Monochrome' }, { 'seductive', 'Seductive' }, { 'regal', 'Regal' }, { 'aqua', 'Aqua' }
    }
    local out = {}
    for i = 1, #names do
        out[i] = { id = names[i][1], label = names[i][2], ipl = ('apa_v_mp_h_0%d_%s'):format(i, suffix), interiorId = ids[i] }
    end
    return out
end

local function officeStyles(prefix, ids)
    local names = {
        { 'warm', 'Old Spice Warm', '01a' }, { 'classical', 'Old Spice Classical', '01b' }, { 'vintage', 'Old Spice Vintage', '01c' },
        { 'contrast', 'Executive Contrast', '02a' }, { 'rich', 'Executive Rich', '02b' }, { 'cool', 'Executive Cool', '02c' },
        { 'ice', 'Power Broker Ice', '03a' }, { 'conservative', 'Power Broker Conservative', '03b' }, { 'polished', 'Power Broker Polished', '03c' }
    }
    local out = {}
    for i = 1, #names do
        out[i] = { id = names[i][1], label = names[i][2], ipl = prefix .. names[i][3], interiorId = ids[i] }
    end
    return out
end

local OFFICE_EXTRAS = { 'office_chairs', 'office_booze' }

local CEO_GARAGE_DECOR = {
    { id = 'concrete', label = 'Concrete', sets = { 'garage_decor_01' } },
    { id = 'plain', label = 'Plain', sets = { 'garage_decor_02' } },
    { id = 'marble', label = 'Marble', sets = { 'garage_decor_03' } },
    { id = 'wooden', label = 'Wooden', sets = { 'garage_decor_04' } }
}
local CEO_GARAGE_EXTRAS = {
    'lighting_option01', 'lighting_option02', 'lighting_option03', 'lighting_option04', 'lighting_option05',
    'lighting_option06', 'lighting_option07', 'lighting_option08', 'lighting_option09',
    'numbering_style01_n1', 'numbering_style01_n2', 'numbering_style01_n3'
}

local function agencyStyles()
    local out = {}
    for i = 1, 9 do
        out[i] = { id = 'wallpaper_' .. i, label = 'Wallpaper ' .. i, sets = { 'Entity_Set_Wpaper_' .. i } }
    end
    return out
end
local AGENCY_EXTRAS = { 'Entity_Set_Standard_Office', 'Entity_Set_Tint_AG', 'Entity_Set_Art_1', 'Entity_Set_Art_2', 'Entity_Set_Art_3', 'Entity_Set_Armoury', 'Entity_Set_Player_Desk', 'Entity_Set_Player_Seats', 'Entity_Set_Spare_Seats' }

local MANSION_STYLES = {
    { id = 'cali', label = 'Cali', sets = { 'set_style_cali', 'set_elev_cali', 'set_art_coastal', 'set_trophy_planter', 'set_shelving_planter' } },
    { id = 'loft', label = 'Loft', sets = { 'set_style_loft', 'set_elev_loft', 'set_art_loft', 'set_loft_trophy_planter', 'set_loft_shelving_planter' } },
    { id = 'holly', label = 'Hollywood Regency', sets = { 'set_style_holly', 'set_elev_holly', 'set_art_regency', 'set_reg_shelving_planter', 'set_reg_trophy_planter' } }
}
local MANSION_EXTRAS = {
    'set_style_cali_tint',
    'set_wallpaper_rustic', 'set_wallpaper_deco', 'set_wallpaper_coastal', 'set_wallpaper_subtle', 'set_wallpaper_safari', 'set_wallpaper_popart'
}

local CLUBHOUSE_STYLES = {
    { id = 'brick', label = 'Brick walls', sets = { 'walls_01' } },
    { id = 'plain', label = 'Plain walls', sets = { 'walls_02' } }
}

Interiors = Interiors or {}
Interiors.Ipls = {

    {
        id = 'del_perro_heights_apt_4', label = 'Del Perro Heights, Apt 4', kind = 'apartment',
        spawn = vec4(-1453.02, -539.5, 74.04, 35.33),
        center = vec3(-1462.281, -539.6276, 72.44434),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo_' },
        interiorId = 145921, styles = nil, extras = CLUTTER_HI, cull = CULL_DEL_PERRO
        },
    {
        id = 'richards_majestic_apt_2', label = 'Richards Majestic, Apt 2', kind = 'apartment',
        spawn = vec4(-913.99, -365.81, 114.27, 115.17),
        center = vec3(-914.9026, -374.8731, 112.6748),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo__1' },
        interiorId = 146177, styles = nil, extras = CLUTTER_HI, cull = CULL_RICHARDS
        },
    {
        id = 'tinsel_towers_apt_42', label = 'Tinsel Towers, Apt 42', kind = 'apartment',
        spawn = vec4(-604.06, 58.99, 98.2, 91.45),
        center = vec3(-609.5669, 51.28212, 96.60023),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo__2' },
        interiorId = 146689, styles = nil, extras = CLUTTER_HI, cull = CULL_TINSEL
        },
    {
        id = 'eclipse_towers_apt_3', label = 'Eclipse Towers, Apt 3', kind = 'apartment',
        spawn = vec4(-784.8, 323.63, 211.99, 263.39),
        center = vec3(-778.5061, 331.316, 210.3972),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo__3' },
        interiorId = 146945, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'integrity_way_apt_28', label = '4 Integrity Way, Apt 28', kind = 'apartment',
        spawn = vec4(-30.58, -595.4, 80.03, 246.95),
        center = vec3(-22.61353, -590.1432, 78.43091),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo__4' },
        interiorId = 147201, styles = nil, extras = CLUTTER_HI, cull = CULL_INTEGRITY
        },
    {
        id = 'high_life_spare_underground', label = 'High Life apartment (unused copy under Tinsel Towers)', kind = 'apartment',
        spawn = vec4(-609.5669, 51.28212, -183.9808, 0.0),
        center = vec3(-609.5669, 51.28212, -183.9808),
        needs = 'bob74_ipl', ipls = { 'mpbusiness_int_placement_interior_v_mp_apt_h_01_milo__5' },
        interiorId = 147457, styles = nil, extras = CLUTTER_HI,
        unverified = true
    },

    {
        id = 'integrity_way_apt_30', label = '4 Integrity Way, Apt 30', kind = 'apartment',
        spawn = vec4(-17.41, -588.17, 90.11, 338.23),
        center = vec3(-35.31277, -580.4199, 88.71221),
        needs = nil, ipls = nil, interiorId = 141313, styles = nil, extras = CLUTTER_HI, cull = CULL_INTEGRITY
        },
    {
        id = 'del_perro_heights_apt_7', label = 'Del Perro Heights, Apt 7', kind = 'apartment',
        spawn = vec4(-1449.98, -525.8, 56.93, 29.66),
        center = vec3(-1477.14, -538.7499, 55.5264),
        needs = nil, ipls = nil, interiorId = 145665, styles = nil, extras = CLUTTER_HI, cull = CULL_DEL_PERRO
        },
    {
        id = 'del_perro_heights_apt_20', label = 'Del Perro Heights, Apt 20', kind = 'apartment',
        spawn = vec4(-1449.93, -525.76, 69.55, 30.2), center = vec3(-1449.93, -525.76, 69.55),
        needs = nil, ipls = nil, styles = nil, cull = CULL_DEL_PERRO,
        unverified = true
    },
    {
        id = 'integrity_way_apt_35', label = '4 Integrity Way, Apt 35', kind = 'apartment',
        spawn = vec4(-25.51, -607.33, 100.24, 241.47), center = vec3(-25.51, -607.33, 100.24),
        needs = nil, ipls = nil, styles = nil, cull = CULL_INTEGRITY,
        unverified = true
    },
    {
        id = 'richards_majestic_apt_4', label = 'Richards Majestic, Apt 4', kind = 'apartment',
        spawn = vec4(-922.99, -378.56, 85.48, 217.47), center = vec3(-922.99, -378.56, 85.48),
        needs = nil, ipls = nil, styles = nil, cull = CULL_RICHARDS,
        unverified = true
    },
    {
        id = 'richards_majestic_apt_51', label = 'Richards Majestic, Apt 51', kind = 'apartment',
        spawn = vec4(-907.13, -372.43, 109.44, 23.43), center = vec3(-907.13, -372.43, 109.44),
        needs = nil, ipls = nil, styles = nil, cull = CULL_RICHARDS,
        unverified = true
    },
    {
        id = 'tinsel_towers_apt_29', label = 'Tinsel Towers, Apt 29', kind = 'apartment',
        spawn = vec4(-604.99, 51.2, 93.63, 169.52), center = vec3(-604.99, 51.2, 93.63),
        needs = nil, ipls = nil, styles = nil, cull = CULL_TINSEL,
        unverified = true
    },
    {
        id = 'tinsel_towers_apt_45', label = 'Tinsel Towers, Apt 45', kind = 'apartment',
        spawn = vec4(-596.4, 56.1, 108.2, 356.6), center = vec3(-596.4, 56.1, 108.2),
        needs = nil, ipls = nil, styles = nil, cull = CULL_TINSEL,
        unverified = true
    },
    {
        id = 'eclipse_towers_apt_5', label = 'Eclipse Towers, Apt 5', kind = 'apartment',
        spawn = vec4(-774.12, 331.18, 207.62, 356.29), center = vec3(-774.12, 331.18, 207.62),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'eclipse_towers_apt_9', label = 'Eclipse Towers, Apt 9', kind = 'apartment',
        spawn = vec4(-781.83, 326.1, 176.81, 179.2), center = vec3(-781.83, 326.1, 176.81),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'eclipse_towers_apt_31', label = 'Eclipse Towers, Apt 31', kind = 'apartment',
        spawn = vec4(-774.61, 331.51, 160.0, 356.7), center = vec3(-774.61, 331.51, 160.0),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'eclipse_towers_apt_40', label = 'Eclipse Towers, Apt 40', kind = 'apartment',
        spawn = vec4(-781.99, 326.06, 223.25, 169.69), center = vec3(-781.99, 326.06, 223.25),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'weazel_plaza_apt_26', label = 'Weazel Plaza, Apt 26', kind = 'apartment',
        spawn = vec4(-890.69, -452.86, 95.46, 286.55), center = vec3(-890.69, -452.86, 95.46),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'weazel_plaza_apt_70', label = 'Weazel Plaza, Apt 70', kind = 'apartment',
        spawn = vec4(-890.67, -436.73, 121.6, 23.89), center = vec3(-890.67, -436.73, 121.6),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'weazel_plaza_apt_101', label = 'Weazel Plaza, Apt 101', kind = 'apartment',
        spawn = vec4(-907.69, -453.55, 126.53, 211.15), center = vec3(-907.69, -453.55, 126.53),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'alta_street_3_apt_10', label = '3 Alta Street, Apt 10', kind = 'apartment',
        spawn = vec4(-273.23, -967.3, 77.23, 247.85), center = vec3(-273.23, -967.3, 77.23),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'alta_street_3_apt_57', label = '3 Alta Street, Apt 57', kind = 'apartment',
        spawn = vec4(-269.87, -941.05, 92.51, 65.59), center = vec3(-269.87, -941.05, 92.51),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'san_andreas_ave_302_apt_1', label = '302 San Andreas Ave, Apt 1', kind = 'apartment',
        spawn = vec4(-468.07, -689.57, 53.4, 92.59), center = vec3(-468.07, -689.57, 53.4),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'san_andreas_ave_302_apt_2', label = '302 San Andreas Ave, Apt 2', kind = 'apartment',
        spawn = vec4(-467.52, -708.72, 77.09, 271.91), center = vec3(-467.52, -708.72, 77.09),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },

    {
        id = 'eclipse_tower_penthouse_1', label = 'Eclipse Towers Penthouse Suite 1', kind = 'apartment',
        spawn = vec4(-786.82, 315.78, 217.63, 272.12),
        center = vec3(-787.7805, 334.9232, 215.8384),
        needs = 'bob74_ipl', ipls = { 'apa_v_mp_h_01_a' },
        styles = penthouseStyles('a', { 227329, 228097, 228865, 229633, 230401, 231169, 231937, 232705 }),
        extras = CLUTTER_HI
        },
    {
        id = 'eclipse_tower_penthouse_2', label = 'Eclipse Towers Penthouse Suite 2 (bob74 numbering)', kind = 'apartment',
        spawn = vec4(-774.32, 341.98, 196.68, 94.64),
        center = vec3(-773.2258, 322.8252, 194.8862),
        needs = 'bob74_ipl', ipls = { 'apa_v_mp_h_01_b' },
        styles = penthouseStyles('b', { 227585, 228353, 229121, 229889, 230657, 231425, 232193, 232961 }),
        extras = CLUTTER_HI
        },
    {
        id = 'eclipse_tower_penthouse_3', label = 'Eclipse Towers Penthouse Suite 3 (bob74 numbering)', kind = 'apartment',
        spawn = vec4(-786.78, 315.74, 187.92, 270.71),
        center = vec3(-787.7805, 334.9232, 186.1134),
        needs = 'bob74_ipl', ipls = { 'apa_v_mp_h_01_c' },
        styles = penthouseStyles('c', { 227841, 228609, 229377, 230145, 230913, 231681, 232449, 233217 }),
        extras = CLUTTER_HI
        },

    {
        id = 'low_end_apartment', label = 'Low-end apartment (studio)', kind = 'apartment',
        spawn = vec4(265.97, -1003.11, -99.01, 21.68),
        center = vec3(261.4586, -998.8196, -99.00863),
        needs = nil, ipls = nil, interiorId = 149761, styles = nil,
        extras = { 'Studio_Lo_Strip_A', 'Studio_Lo_Strip_B', 'Studio_Lo_Strip_C', 'Studio_Lo_Booze_A', 'Studio_Lo_Booze_B', 'Studio_Lo_Booze_C', 'Studio_Lo_Smoke_A', 'Studio_Lo_Smoke_B', 'Studio_Lo_Smoke_C' }
        },
    {
        id = 'medium_apartment', label = 'Medium apartment', kind = 'apartment',
        spawn = vec4(346.76, -1011.52, -99.2, 358.57),
        center = vec3(347.2686, -999.2955, -99.19622),
        needs = nil, ipls = nil, interiorId = 148225, styles = nil,
        extras = { 'Apart_Mid_Strip_A', 'Apart_Mid_Strip_B', 'Apart_Mid_Strip_C', 'Apart_Mid_Booze_A', 'Apart_Mid_Booze_B', 'Apart_Mid_Booze_C', 'Apart_Mid_Smoke_A', 'Apart_Mid_Smoke_B', 'Apart_Mid_Smoke_C' }
        },

    {
        id = 'stilt_3655_wild_oats', label = '3655 Wild Oats Drive', kind = 'house',
        spawn = vec4(-174.33, 497.53, 137.67, 190.77), center = vec3(-169.286, 486.4938, 137.4436),
        needs = nil, ipls = nil, interiorId = 207105, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2044_north_conker', label = '2044 North Conker Avenue', kind = 'house',
        spawn = vec4(341.75, 437.58, 149.39, 122.12), center = vec3(340.9412, 437.1798, 149.3925),
        needs = nil, ipls = nil, interiorId = 206081, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2045_north_conker', label = '2045 North Conker Avenue', kind = 'house',
        spawn = vec4(373.55, 423.36, 145.91, 164.03), center = vec3(373.023, 416.105, 145.7006),
        needs = nil, ipls = nil, interiorId = 206337, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2862_hillcrest', label = '2862 Hillcrest Avenue', kind = 'house',
        spawn = vec4(-682.05, 592.23, 145.39, 217.49), center = vec3(-676.127, 588.612, 145.1698),
        needs = nil, ipls = nil, interiorId = 208129, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2868_hillcrest', label = '2868 Hillcrest Avenue', kind = 'house',
        spawn = vec4(-758.81, 618.9, 144.15, 111.08), center = vec3(-763.107, 615.906, 144.1401),
        needs = nil, ipls = nil, interiorId = 207617, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2874_hillcrest', label = '2874 Hillcrest Avenue', kind = 'house',
        spawn = vec4(-859.85, 690.9, 152.86, 186.09), center = vec3(-857.798, 682.563, 152.6529),
        needs = nil, ipls = nil, interiorId = 207361, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_3677_whispymound', label = '3677 Whispymound Drive', kind = 'house',
        spawn = vec4(117.26, 559.51, 184.3, 184.5), center = vec3(120.5, 549.952, 184.097),
        needs = nil, ipls = nil, interiorId = 206593, styles = nil, extras = CLUTTER_HI
        },
    {
        id = 'stilt_2113_mad_wayne_thunder', label = '2113 Mad Wayne Thunder Drive', kind = 'house',
        spawn = vec4(-1289.82, 449.37, 97.9, 177.79), center = vec3(-1288.0, 440.748, 97.69459),
        needs = nil, ipls = nil, interiorId = 208385, styles = nil, extras = CLUTTER_HI
        },

    {
        id = 'garage_2_car', label = '2-car garage (low end)', kind = 'garage',
        spawn = vec4(178.95, -1000.05, -99.0, 184.87),
        center = vec3(173.2903, -1003.6, -99.65707),
        needs = nil, ipls = nil, styles = nil
        },
    {
        id = 'garage_6_car', label = '6-car garage (medium)', kind = 'garage',
        spawn = vec4(198.39, -1002.87, -99.0, 357.4),
        center = vec3(197.8153, -1002.293, -99.65749),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'garage_10_car', label = '10-car garage (high end)', kind = 'garage',
        spawn = vec4(239.86, -1004.71, -99.0, 88.55),
        center = vec3(229.9559, -981.7928, -99.66071),
        needs = nil, ipls = nil, styles = nil
        },
    {
        id = 'ceo_garage_arcadius', label = 'Arcadius Business Centre CEO garage', kind = 'garage',
        spawn = vec4(-198.13, -580.68, 136.0, 282.8),
        center = vec3(-191.0133, -579.1428, 135.0),
        needs = 'bob74_ipl', ipls = { 'imp_dt1_02_cargarage_a' },
        parts = {
            { id = 'garage1', ipl = 'imp_dt1_02_cargarage_a', interiorId = 253441, center = vec3(-191.0133, -579.1428, 135.0) },
            { id = 'garage2', ipl = 'imp_dt1_02_cargarage_b', interiorId = 253697, center = vec3(-117.4989, -568.1132, 135.0) },
            { id = 'garage3', ipl = 'imp_dt1_02_cargarage_c', interiorId = 253953, center = vec3(-136.078, -630.1852, 135.0) },
            { id = 'modshop', ipl = 'imp_dt1_02_modgarage', interiorId = 254209, center = vec3(-146.6166, -596.6301, 166.0) }
        },
        styles = CEO_GARAGE_DECOR, extras = CEO_GARAGE_EXTRAS
    },
    {
        id = 'ceo_garage_maze_bank_tower', label = 'Maze Bank Tower CEO garage', kind = 'garage',
        spawn = vec4(-91.33, -821.34, 222.0, 251.88),
        center = vec3(-84.2193, -823.0851, 221.0),
        needs = 'bob74_ipl', ipls = { 'imp_dt1_11_cargarage_a' },
        parts = {
            { id = 'garage1', ipl = 'imp_dt1_11_cargarage_a', interiorId = 254465, center = vec3(-84.2193, -823.0851, 221.0) },
            { id = 'garage2', ipl = 'imp_dt1_11_cargarage_b', interiorId = 254721, center = vec3(-69.8627, -824.7498, 221.0) },
            { id = 'garage3', ipl = 'imp_dt1_11_cargarage_c', interiorId = 254977, center = vec3(-80.4318, -813.2536, 221.0) },
            { id = 'modshop', ipl = 'imp_dt1_11_modgarage', interiorId = 255233, center = vec3(-73.9039, -821.6204, 284.0) }
        },
        styles = CEO_GARAGE_DECOR, extras = CEO_GARAGE_EXTRAS
    },
    {
        id = 'ceo_garage_lombank_west', label = 'Lombank West CEO garage', kind = 'garage',
        spawn = vec4(-1585.95, -561.92, 86.5, 218.17),
        center = vec3(-1581.112, -567.245, 85.5),
        needs = 'bob74_ipl', ipls = { 'imp_sm_13_cargarage_a' },
        parts = {
            { id = 'garage1', ipl = 'imp_sm_13_cargarage_a', interiorId = 255489, center = vec3(-1581.112, -567.245, 85.5) },
            { id = 'garage2', ipl = 'imp_sm_13_cargarage_b', interiorId = 255745, center = vec3(-1568.739, -562.0455, 85.5) },
            { id = 'garage3', ipl = 'imp_sm_13_cargarage_c', interiorId = 256001, center = vec3(-1563.557, -574.4314, 85.5) },
            { id = 'modshop', ipl = 'imp_sm_13_modgarage', interiorId = 256257, center = vec3(-1578.023, -576.4251, 104.2) }
        },
        styles = CEO_GARAGE_DECOR, extras = CEO_GARAGE_EXTRAS
    },
    {
        id = 'ceo_garage_maze_bank_west', label = 'Maze Bank West CEO garage', kind = 'garage',
        spawn = vec4(-1395.9, -480.69, 49.1, 286.12),
        center = vec3(-1388.86, -478.7574, 48.1),
        needs = 'bob74_ipl', ipls = { 'imp_sm_15_cargarage_b' },
        parts = {
            { id = 'garage1', ipl = 'imp_sm_15_cargarage_a', interiorId = 256513, center = vec3(-1388.84, -478.7402, 56.1) },
            { id = 'garage2', ipl = 'imp_sm_15_cargarage_b', interiorId = 256769, center = vec3(-1388.86, -478.7574, 48.1) },
            { id = 'garage3', ipl = 'imp_sm_15_cargarage_c', interiorId = 257025, center = vec3(-1374.682, -474.3586, 56.1) },
            { id = 'modshop', ipl = 'imp_sm_15_modgarage', interiorId = 257281, center = vec3(-1391.245, -473.9638, 77.2) }
        },
        styles = CEO_GARAGE_DECOR, extras = CEO_GARAGE_EXTRAS
    },

    {
        id = 'ceo_office_maze_bank_tower', label = 'Maze Bank Tower CEO office', kind = 'office',
        spawn = vec4(-75.46, -827.14, 242.5, 67.2),
        center = vec3(-75.8466, -826.9893, 243.3859),
        needs = 'bob74_ipl', ipls = { 'ex_dt1_11_office_01a' },
        styles = officeStyles('ex_dt1_11_office_', { 238593, 238849, 239105, 239361, 239617, 239873, 240129, 240385, 240641 }),
        extras = OFFICE_EXTRAS
        },
    {
        id = 'ceo_office_arcadius', label = 'Arcadius Business Centre CEO office', kind = 'office',
        spawn = vec4(-141.4, -621.01, 167.9, 275.04),
        center = vec3(-141.1987, -620.913, 168.8205),
        needs = 'bob74_ipl', ipls = { 'ex_dt1_02_office_03c' },
        styles = officeStyles('ex_dt1_02_office_', { 236289, 236545, 236801, 237057, 237313, 237569, 237825, 238081, 238337 }),
        extras = OFFICE_EXTRAS
        },
    {
        id = 'ceo_office_lombank_west', label = 'Lombank West CEO office', kind = 'office',
        spawn = vec4(-1579.3, -564.77, 107.7, 301.98),
        center = vec3(-1579.756, -565.0661, 108.523),
        needs = 'bob74_ipl', ipls = { 'ex_sm_13_office_03b' },
        styles = officeStyles('ex_sm_13_office_', { 240897, 241153, 241409, 241665, 241921, 242177, 242433, 242689, 242945 }),
        extras = OFFICE_EXTRAS
    },
    {
        id = 'ceo_office_maze_bank_west', label = 'Maze Bank West CEO office', kind = 'office',
        spawn = vec4(-1392.67, -480.18, 71.2, 2.53),
        center = vec3(-1392.667, -480.4736, 72.04217),
        needs = 'bob74_ipl', ipls = { 'ex_sm_15_office_02c' },
        styles = officeStyles('ex_sm_15_office_', { 243201, 243457, 243713, 243969, 244225, 244481, 244737, 244993, 245249 }),
        extras = OFFICE_EXTRAS
    },

    {
        id = 'agency_rockford_hills', label = 'Agency, Rockford Hills', kind = 'office',
        spawn = vec4(-1033.35, -434.92, 63.86, 296.08),
        center = vec3(-1021.86084, -427.74564, 68.95764),
        needs = 'bob74_ipl', ipls = { 'sf_fixeroffice_bh1_05' }, interiorId = 287489,
        styles = agencyStyles(), extras = AGENCY_EXTRAS, cull = { 'bh1_05_build1', 'bh1_05_em' }, build = 2545
    },
    {
        id = 'agency_hawick', label = 'Agency, Hawick', kind = 'office',
        spawn = vec4(370.34, -56.36, 103.36, 253.34),
        center = vec3(383.4156, -59.878227, 108.4595),
        needs = 'bob74_ipl', ipls = { 'sf_fixeroffice_hw1_08' }, interiorId = 288257,
        styles = agencyStyles(), extras = AGENCY_EXTRAS, cull = { 'hei_hw1_08_hotplaz01', 'hw1_08_hotplaz_rail', 'hw1_08_emissive_c' }, build = 2545
    },
    {
        id = 'agency_vespucci_canals', label = 'Agency, Vespucci Canals', kind = 'office',
        spawn = vec4(-1002.99, -774.63, 61.89, 1.79),
        center = vec3(-1004.23035, -761.2084, 66.99069),
        needs = 'bob74_ipl', ipls = { 'sf_fixeroffice_kt1_05' }, interiorId = 288001,
        styles = agencyStyles(), extras = AGENCY_EXTRAS, cull = { 'hei_kt1_05_01', 'kt1_05_glue_b', 'kt1_05_kt_emissive_kt1_05' }, build = 2545
    },
    {
        id = 'agency_little_seoul', label = 'Agency, Little Seoul', kind = 'office',
        spawn = vec4(-587.87213, -716.84937, 118.10156, 0.0),
        center = vec3(-587.87213, -716.84937, 118.10156),
        needs = 'bob74_ipl', ipls = { 'sf_fixeroffice_kt1_08' }, interiorId = 287745,
        styles = agencyStyles(), extras = AGENCY_EXTRAS, cull = { 'hei_kt1_08_buildingtop_a', 'hei_kt1_08_kt1_emissive_ema' }, build = 2545,
        unverified = true
    },

    {
        id = 'diamond_casino_penthouse', label = 'Diamond Casino Master Penthouse', kind = 'apartment',
        spawn = vec4(969.82, 63.1, 112.56, 244.2),
        center = vec3(976.636, 70.295, 115.164),
        needs = 'bob74_ipl', ipls = { 'vw_casino_penthouse' }, interiorId = 274689, build = 2060,
        styles = {
            { id = 'default', label = 'Default', sets = { 'Set_Pent_Tint_Shell' }, color = 0 },
            { id = 'sharp', label = 'Sharp', sets = { 'Set_Pent_Tint_Shell' }, color = 1 },
            { id = 'vibrant', label = 'Vibrant', sets = { 'Set_Pent_Tint_Shell' }, color = 2 },
            { id = 'timeless', label = 'Timeless', sets = { 'Set_Pent_Tint_Shell' }, color = 3 }
        },
        extras = { 'Set_Pent_Pattern_01', 'Set_Pent_Pattern_02', 'Set_Pent_Pattern_03', 'Set_Pent_Pattern_04', 'Set_Pent_Pattern_05', 'Set_Pent_Pattern_06', 'Set_Pent_Pattern_07', 'Set_Pent_Pattern_08', 'Set_Pent_Pattern_09' }
    },
    {
        id = 'mansion_vinewood_residence', label = 'The Vinewood Residence', kind = 'house',
        spawn = vec4(543.852, 712.754, 201.0, 0.0), center = vec3(543.852, 712.754, 201.0),
        needs = 'bob74_ipl',
        ipls = { 'm25_2_ch2_04_mansion_interior_a', 'm25_2_ch2_04_mansion_interior_b', 'm25_2_ch2_04_mansion_interior_c', 'apa_ch2_04_mansion_shared', 'apa_ch2_04_mansion_private', 'apa_ch2_04_mansion_furniture', 'apa_ch2_04_mansion_firepit', 'apa_ch2_04_mansion_railings_p', 'm25_2_east_mansion_gym', 'm25_2_east_dog_house', 'm25_2_mansion_props', 'hei_ch1_roads_mansion', 'apa_ch2_04_mansion_shared_distantlights', 'apa_ch2_04_mansion_shared_lodlights' },
        interiorId = 304385, styles = MANSION_STYLES, extras = MANSION_EXTRAS, build = 'DLC mp2025_02',
        unverified = true
    },
    {
        id = 'mansion_richman_villa', label = 'Richman Villa', kind = 'house',
        spawn = vec4(-1630.434, 470.852, 128.0, 0.0), center = vec3(-1630.434, 470.852, 128.0),
        needs = 'bob74_ipl',
        ipls = { 'hei_ch1_06e_mansion_shared', 'hei_ch1_06f_mansion_shared', 'm25_2_ch1_06e_mansion_interior_a', 'm25_2_ch1_06e_mansion_interior_b', 'm25_2_ch1_06e_mansion_interior_c', 'hei_ch1_06e_mansion_private', 'hei_ch1_06e_mansion_furniture', 'hei_ch1_06e_mansion_firepit', 'hei_ch1_06e_mansion_railings_p', 'm25_2_mansion_gym', 'm25_2_dog_house', 'm25_2_mansion_props', 'hei_ch1_roads_mansion', 'hei_ch1_06e_mansion_shared_distantlights', 'hei_ch1_06e_mansion_shared_lodlights' },
        interiorId = 302593, styles = MANSION_STYLES, extras = MANSION_EXTRAS, build = 'DLC mp2025_02',
        unverified = true
    },
    {
        id = 'mansion_tongva_estate', label = 'The Tongva Estate', kind = 'house',
        spawn = vec4(-2601.712, 1874.826, 166.0, 0.0), center = vec3(-2601.712, 1874.826, 166.0),
        needs = 'bob74_ipl',
        ipls = { 'hei_ch1_09_mansion_shared', 'm25_2_ch1_09_mansion_interior_a', 'm25_2_ch1_09_mansion_interior_b', 'm25_2_ch1_09_mansion_interior_c', 'hei_ch1_09_mansion_private', 'hei_ch1_09_mansion_furniture', 'hei_ch1_09_mansion_firepit', 'hei_ch1_09_mansion_railings_p', 'm25_2_tongva_mansion_gym', 'm25_2_tongva_dog_house', 'm25_2_mansion_props', 'hei_ch1_roads_mansion', 'hei_ch1_09_mansion_shared_distantlights', 'hei_ch1_09_mansion_shared_lodlights' },
        interiorId = 303617, styles = MANSION_STYLES, extras = MANSION_EXTRAS, build = 'DLC mp2025_02',
        unverified = true
    },

    {
        id = 'michael_house', label = "Michael's house (Rockford Hills)", kind = 'house',
        spawn = vec4(-815.354, 178.479, 72.84, 279.4),
        center = vec3(-802.311, 175.056, 72.8446),
        needs = nil, ipls = nil, interiorId = 166657,
        styles = {
            { id = 'normal', label = 'Tidy', sets = { 'V_Michael_bed_tidy', 'V_Michael_M_items', 'V_Michael_D_items', 'V_Michael_S_items', 'V_Michael_L_Items' } },
            { id = 'moved', label = 'Moved out', sets = { 'V_Michael_bed_Messy', 'V_Michael_M_moved', 'V_Michael_D_Moved', 'V_Michael_L_Moved', 'V_Michael_S_items_swap', 'V_Michael_M_items_swap' } }
        },
        extras = { 'V_Michael_Scuba', 'Michael_premier', 'V_Michael_FameShame', 'V_Michael_plane_ticket', 'V_Michael_JewelHeist', 'burgershot_yoga' },
        unverified = true
    },
    {
        id = 'franklin_house_vinewood', label = "Franklin's house (Vinewood Hills)", kind = 'house',
        spawn = vec4(7.76, 538.44, 175.06, 192.4),
        center = vec3(-4.69, 522.28, 174.63),
        needs = nil, ipls = nil, interiorId = 206849,
        styles = {
            { id = 'empty', label = 'Empty', sets = {} },
            { id = 'unpacking', label = 'Unpacking', sets = { 'franklin_unpacking' } },
            { id = 'settled', label = 'Settled', sets = { 'franklin_unpacking', 'franklin_settled' } },
            { id = 'showhome', label = 'Boxes (show home)', sets = { 'showhome_only' } }
        },
        extras = { 'unlocked', 'locked', 'progress_flyer', 'progress_tux', 'progress_tshirt', 'bong_and_wine' },
        unverified = true
    },
    {
        id = 'franklin_aunt_house', label = "Franklin's aunt's house (Forum Drive)", kind = 'house',
        spawn = vec4(-9.96562, -1438.54, 31.1015, 0.0),
        center = vec3(-9.96562, -1438.54, 31.1015),
        needs = nil, ipls = nil, interiorId = 197889,
        styles = {
            { id = 'empty', label = 'Default', sets = {} },
            { id = 'franklin', label = "Franklin's stuff", sets = { 'V_57_FranklinStuff' } },
            { id = 'franklin_left', label = 'Franklin moved out', sets = { 'V_57_Franklin_LEFT' } }
        },
        extras = { 'V_57_GangBandana', 'V_57_Safari' },
        unverified = true
    },
    {
        id = 'floyd_apartment', label = "Floyd's apartment (Vespucci Beach)", kind = 'apartment',
        spawn = vec4(-1150.68, -1520.84, 10.633, 75.7),
        center = vec3(-1150.703, -1520.713, 10.633),
        needs = nil, ipls = nil, interiorId = 171777,
        styles = {
            { id = 'normal', label = 'Clean', sets = { 'swap_clean_apt', 'layer_debra_pic', 'layer_whiskey', 'swap_sofa_A' } },
            { id = 'messed_up', label = 'Trashed', sets = { 'layer_mess_A', 'layer_mess_B', 'layer_mess_C', 'layer_sextoys_a', 'swap_sofa_B', 'swap_wade_sofa_A', 'layer_wade_shit', 'layer_torture' } }
        },
        extras = { 'swap_mrJam_A', 'swap_mrJam_B', 'swap_mrJam_C' },
        unverified = true
    },
    {
        id = 'trevor_trailer', label = "Trevor's trailer (Sandy Shores)", kind = 'house',
        spawn = vec4(1973.19, 3816.42, 33.42, 338.2),
        center = vec3(1985.48132, 3828.76757, 32.5),
        needs = 'bob74_ipl', ipls = { 'TrevorsTrailerTrash' }, interiorId = 2562,
        styles = {
            { id = 'tidy', label = 'Tidy', ipl = 'trevorstrailertidy' },
            { id = 'trash', label = 'Trashed', ipl = 'TrevorsTrailerTrash' }
        },
        extras = { 'V_26_Trevor_Helmet3', 'V_24_Trevor_Briefcase3', 'V_26_Michael_Stay3' },
        unverified = true
    },
    {
        id = 'lester_house', label = "Lester's house (El Burro Heights)", kind = 'house',
        spawn = vec4(1274.197, -1719.683, 54.771, 339.7),
        center = vec3(1273.9, -1719.305, 54.77141),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },
    {
        id = 'motel_room', label = 'Motel room (GTA Online)', kind = 'apartment',
        spawn = vec4(151.326, -1007.764, -99.0, 358.0),
        center = vec3(152.2605, -1004.471, -98.99999),
        needs = nil, ipls = nil, styles = nil,
        unverified = true
    },

    {
        id = 'biker_clubhouse_1', label = 'Biker clubhouse (warehouse layout)', kind = 'other',
        spawn = vec4(1121.05, -3152.13, -37.07, 355.17),
        center = vec3(1107.04, -3157.399, -37.51859),
        needs = 'bob74_ipl', ipls = { 'bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo' }, interiorId = 246273,
        styles = CLUBHOUSE_STYLES, extras = { 'furnishings_01', 'furnishings_02' }
        },
    {
        id = 'biker_clubhouse_2', label = 'Biker clubhouse (bar layout)', kind = 'other',
        spawn = vec4(997.25, -3158.1, -38.91, 268.83),
        center = vec3(998.4809, -3164.711, -38.90733),
        needs = 'bob74_ipl', ipls = { 'bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo' }, interiorId = 246529,
        styles = CLUBHOUSE_STYLES, extras = { 'furnishings_01', 'furnishings_02', 'lower_walls_default' }
    }
}

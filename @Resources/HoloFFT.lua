function Initialize()
    mFFT = {} -- array of FFT measures
    FFT = {} -- array of FFT history
    point = {} -- array of points
    xyScale = 0 -- scale of display and model
    dispR = tonumber(SKIN:GetVariable('DispR')) -- half of display width
    shift = tonumber(SKIN:GetVariable('Shift')) -- shift up off-screen
    filter = tonumber(SKIN:GetVariable('Filter')) and true or false -- filter silence
    bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
    rows = tonumber(SKIN:GetVariable('Rows')) -- depth of FFT history
    theta = tonumber(SKIN:GetVariable('Theta')) -- pitch angle
    phi = tonumber(SKIN:GetVariable('Phi')) -- roll angle
    psi = tonumber(SKIN:GetVariable('Psi')) -- yaw angle
    omega = tonumber(SKIN:GetVariable('Omega')) -- delta of yaw angle (angular velocity)
    perspective = tonumber(SKIN:GetVariable('Perspective'))
    style = tonumber(SKIN:GetVariable('Style'))
    scroll = 0 -- preset selection list scroll position
    lock = false -- lock hiding of mouseover controls
    if not SKIN:GetMeter('B0R1') then
        GenMeasures()
        GenMeters()
        SKIN:Bang('!Refresh')
        return
    end
    for b = 0, bands - 1 do
        mFFT[b], FFT[b], point[b] = SKIN:GetMeasure('mFFT'..b), {}, {}
        for r = 1, rows do
            FFT[b][r], point[b][r] = 0, SKIN:GetMeter('B'..b..'R'..r)
        end
    end
    mFFT.peak, FFT.peak = SKIN:GetMeasure('mFFTPeak'), {}
    os.remove(SKIN:GetVariable('@')..'Measures.inc')
    os.remove(SKIN:GetVariable('@')..'Meters.inc')
    LoadPreset()
    SetChannel(SKIN:GetVariable('Channel'))
    SetStyle(style)
    Scale(0)
    SKIN:Bang('[!SetOption AttackSlider X '..(68 + tonumber(SKIN:GetVariable('Attack')) * 0.09)..'][!SetOption DecaySlider X '..(62 + tonumber(SKIN:GetVariable('Decay')) * 0.09)..'][!SetOption SensSlider X '..(95 + tonumber(SKIN:GetVariable('Sens')) * 0.9)..'][!SetOption Filter'..(filter and 1 or 0)..' SolidColor FF0000][!SetOption Filter'..(filter and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption ShiftSlider X '..(127 - shift * 50)..'][!SetOption PerspectiveSlider X '..(101 + perspective * 90)..'][!SetOption OmegaSlider X '..(130 + omega * 2250)..'][!SetOption OmegaVal Text '..(omega * 250)..']')
    if SKIN:GetVariable('ShowSet') ~= '' then
        SKIN:Bang('[!ShowMeterGroup Control][!ShowMeterGroup Set][!WriteKeyValue Variables ShowSet "" "#@#Settings.inc"]')
    end
end

function Update()
    psi = (psi + omega) % 6.28
    local sinTheta, cosTheta, sinPhi, cosPhi, sinPsi, cosPsi = math.sin(theta), math.cos(theta), math.sin(phi), math.cos(phi), math.sin(psi), math.cos(psi)
    for r = 1, rows do
        local passVal = r ~= rows and true or false
        for b = 0, bands - 1 do
            FFT[b][r] = passVal and FFT[b][r + 1] or mFFT[b]:GetValue()
            FFT.peak[r] = passVal and FFT.peak[r + 1] or mFFT.peak:GetValue()
            -- Convert FFT data to Cartesian coordinates
            local x, y, z = Preset(bands, b, rows, r, FFT[b][r], FFT.peak[r])
            if FFT[b][r] == 0 and filter then
                z = 0/0
            end
            -- Project to screen space
            local zDepthScale = 1 - ((z * cosPhi - (x * cosPsi + y * sinPsi) * sinPhi) * -sinTheta + (y * cosPsi - x * sinPsi) * cosTheta) * 0.577 * perspective
            point[b][r]:SetX((z * sinPhi + (x * cosPsi + y * sinPsi) * cosPhi) * xyScale * zDepthScale + dispR)
            point[b][r]:SetY(((z * cosPhi - (x * cosPsi + y * sinPsi) * sinPhi) * cosTheta + (y * cosPsi - x * sinPsi) * sinTheta) * -xyScale * zDepthScale + dispR * shift)
        end
    end
end

function Pitch(n)
    theta = math.floor((theta + n) % 6.3 * 10 + 0.5) * 0.1
    SKIN:Bang('!WriteKeyValue Variables Theta '..theta..' "#@#Settings.inc"')
end

function Roll(n)
    phi = math.floor((phi + n) % 6.3 * 10 + 0.5) * 0.1
    SKIN:Bang('!WriteKeyValue Variables Phi '..phi..' "#@#Settings.inc"')
end

function Yaw(n)
    psi = math.floor((psi + n) % 6.3 * 10 + 0.5) * 0.1
    SKIN:Bang('!WriteKeyValue Variables Psi '..psi..' "#@#Settings.inc"')
end

function Scale(n)
    if dispR + n >= 70 and dispR + n <= tonumber(SKIN:GetVariable('SCREENAREAWIDTH')) / 2 then
        dispR = dispR + n
        xyScale = dispR * 0.577 -- max radius is square root of 3
        SKIN:Bang('[!MoveMeter '..(dispR * 2)..' '..(dispR * 2)..' Spacer][!SetOption Handle W '..(dispR * 2)..'][!SetOption Handle H '..(dispR * 2)..'][!WriteKeyValue Variables DispR '..dispR..' "#@#Settings.inc"]')
    end
end

function HideControls()
    if not lock then
        SKIN:Bang('[!HideMeterGroup Control][!HideMeterGroup Set]')
    end
end

function GenMeasures()
    local file = io.open(SKIN:GetVariable('@')..'Measures.inc', 'w')
    for b = 0, bands - 1 do
        file:write('[mFFT'..b..']\nMeasure=Plugin\nPlugin=AudioLevel\nParent=mFFTPeak\nType=Band\nBandIdx='..b..'\nGroup=mFFT\n')
    end
    file:close()
end

function GenMeters()
    local file = io.open(SKIN:GetVariable('@')..'Meters.inc', 'w')
    for r = 1, rows do
        for b = 0, bands - 1 do
            file:write('[B'..b..'R'..r..']\nMeter=Image\nMeterStyle=P\n')
        end
    end
    file:close()
end

function LoadPreset(n)
    local file
    if n then
        file = SKIN:GetMeasure('mPreset'..n):GetStringValue()
        SKIN:Bang('[!SetOption PresetSet Text "'..file..'"][!SetVariable Preset "'..file..'"][!WriteKeyValue Variables Preset "'..file..'" "#@#Settings.inc"]')
    else
        file = SKIN:GetVariable('Preset')
    end
    -- Create function from file
    Preset = assert(loadfile(SKIN:GetVariable('@')..'Presets\\'..file..'.lua'))
end

function InitScroll()
    presetCount = SKIN:GetMeasure('mPresetCount'):GetValue()
    SKIN:GetMeter('PresetScroll'):SetH(math.min(186, 1900 / presetCount - 4))
end

function ScrollList(n, m)
    if m then
        local n = m * 0.01 > (scroll + 5) / presetCount and 1 or -1
        for i = 1, 3 do
            ScrollList(n)
        end
    elseif scroll + n >= 0 and scroll + n + 10 <= presetCount then
        scroll = scroll + n
        SKIN:GetMeter('PresetScroll'):SetY(190 / (presetCount - 10) * (1 - 10 / presetCount) * scroll + 148)
        SKIN:Bang('!CommandMeasure mPreset1 Index'..(n > 0 and 'Down' or 'Up'))
    end
end

function SetAttack(n, m)
    local attack = tonumber(SKIN:GetVariable('Attack'))
    if m then
        attack = math.floor(m * 0.11) * 100
    elseif attack + n >= 0 and attack + n <= 1000 then
        attack = math.floor((attack + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('AttackSlider'):SetX(68 + attack * 0.09)
    SKIN:Bang('[!SetOption mFFTPeak PeakAttack '..attack..'][!SetOption mFFTPeak FFTAttack '..attack..'][!SetOption AttackVal Text '..attack..'][!SetVariable Attack '..attack..'][!WriteKeyValue Variables Attack '..attack..' "#@#Settings.inc"]')
end

function SetDecay(n, m)
    local decay = tonumber(SKIN:GetVariable('Decay'))
    if m then
        decay = math.floor(m * 0.11) * 100
    elseif decay + n >= 0 and decay + n <= 1000 then
        decay = math.floor((decay + n) * 0.01 + 0.5) * 100
    else return end
    SKIN:GetMeter('DecaySlider'):SetX(62 + decay * 0.09)
    SKIN:Bang('[!SetOption mFFTPeak PeakDecay '..decay..'][!SetOption mFFTPeak FFTDecay '..decay..'][!SetOption DecayVal Text '..decay..'][!SetVariable Decay '..decay..'][!WriteKeyValue Variables Decay '..decay..' "#@#Settings.inc"]')
end

function SetSens(n, m)
    local sens = tonumber(SKIN:GetVariable('Sens'))
    if m then
        sens = math.floor(m * 0.11) * 10
    elseif sens + n >= 0 and sens + n <= 100 then
        sens = math.floor((sens + n) * 0.1 + 0.5) * 10
    else return end
    SKIN:GetMeter('SensSlider'):SetX(95 + sens * 0.9)
    SKIN:Bang('[!SetOption mFFTPeak Sensitivity '..sens..'][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
end

function SetFilter(n)
    SKIN:Bang('[!SetOption Filter'..(filter and 1 or 0)..' SolidColor 505050E0][!SetOption Filter'..(filter and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Filter'..(n or 0)..' SolidColor FF0000][!SetOption Filter'..(n or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!WriteKeyValue Variables Filter '..(n or '""')..' "#@#Settings.inc"]')
    filter = tonumber(n) and true or false
end

function SetChannel(n)
    local name = {[0]='Left','Right','Center','Subwoofer','Back Left','Back Right','Side Left','Side Right'}
    if n == 'Stereo' then
        -- Split bands between L and R channels
        for b = 0, bands / 2 - 1 do
            SKIN:Bang('[!SetOption mFFT'..b..' Channel L][!SetOption mFFT'..b..' BandIdx '..(bands - b * 2 - 2)..']')
        end
        for b = bands / 2, bands - 1 do
            SKIN:Bang('[!SetOption mFFT'..b..' Channel R][!SetOption mFFT'..b..' BandIdx '..(b * 2 - bands - 2)..']')
        end
    else
        SKIN:Bang('!SetOptionGroup mFFT Channel '..n)
        for b = 0, bands - 1 do
            SKIN:Bang('!SetOption mFFT'..b..' BandIdx '..b)
        end
    end
    SKIN:Bang('[!SetOption ChannelSet Text "'..(name[tonumber(n)] or n)..'"][!SetVariable Channel '..n..'][!WriteKeyValue Variables Channel '..n..' "#@#Settings.inc"]')
end

function SetRes(r)
    local res = tonumber(SKIN:GetVariable('ResSet'))
    if res and res > 0 then
        SKIN:Bang('[!WriteKeyValue Variables '..r..' '..res..' "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
    else
        lock = false
    end
end

function SetPixS()
    local pixS = tonumber(SKIN:GetVariable('PixSSet'))
    if pixS and pixS > 0 then
        SKIN:Bang('[!SetOptionGroup P W "#PixSSet#"][!SetOptionGroup P H "#PixSSet#"][!SetOption PixSSet Text "#PixSSet#"][!SetVariable PixS "#PixSSet#"][!WriteKeyValue Variables PixS "#PixSSet#" "#@#Settings.inc"]')
        lock = false
    end
end

function SetShift(n, m)
    if m then
        shift = 1 - math.floor(m * 0.2) * 0.1
    elseif shift + n <= 1 and shift + n >= -0.9 then
        shift = math.floor((shift + n) * 10 + 0.5) * 0.1
    else return end
    SKIN:GetMeter('ShiftSlider'):SetX(125 - shift * 47.5)
    SKIN:Bang('!WriteKeyValue Variables Shift '..shift..' "#@#Settings.inc"')
end

function SetPerspective(n, m)
    if m then
        perspective = math.floor(m * 0.11) * 0.1
    elseif perspective + n >= 0 and perspective + n <= 1 then
        perspective = math.floor((perspective + n) * 10 + 0.5) * 0.1
    else return end
    SKIN:GetMeter('PerspectiveSlider'):SetX(101 + perspective * 90)
    SKIN:Bang('[!SetOption PerspectiveVal Text '..perspective..'][!WriteKeyValue Variables Perspective '..perspective..' "#@#Settings.inc"]')
end

function SetColor(n)
    if SKIN:GetVariable('ColorSet') ~= '' then
        SKIN:Bang('[!SetOption Color'..n..'Set Text "#ColorSet#"][!SetVariable Color'..n..' "#ColorSet#"][!WriteKeyValue Variables Color'..n..' "#ColorSet#" "#@#Settings.inc"]')
        lock = false
        if style < 4 then
            SetStyle(style)
        end
    end
end

function SwapColor()
    SKIN:Bang('[!SetOption Color1Set Text "#Color2#"][!SetOption Color2Set Text "#Color1#"][!SetVariable Color1 "#Color2#"][!SetVariable Color2 "#Color1#"][!WriteKeyValue Variables Color1 "#Color2#" "#@#Settings.inc"][!WriteKeyValue Variables Color2 "#Color1#" "#@#Settings.inc"]')
    if style < 4 then
        SetStyle(style)
    end
end

function SetStyle(n)
    if style ~= n and style >= 2 and n >= 2 then
        -- Handle combined styles
        if style >= 6 and (style - n == 4 or n == 4) then
            n = style - n
        elseif style == 4 or n == 4 then
            n = style + n
        end
    end
    if n == 0 then
        -- Style: None
        SKIN:Bang('!SetOptionGroup P SolidColor "#Color1#"')
    elseif n == 2 or n == 3 then
        -- Style: Fade In/Out
        local color = (function(color)
            -- Convert color to RGB and strip alpha component
            if not string.match(color, ',') then
                color = string.gsub(color, '%x%x', function(s) return tonumber(s, 16)..',' end)
            end
            return string.match(color, '%d+[,%s]+%d+[,%s]+%d+')..','
        end)(SKIN:GetVariable('Color1'))
        for r = 1, rows do
            local alpha = n == 2 and (1 - r / rows) * 255 or r / rows * 255
            for b = 0, bands - 1 do
                SKIN:Bang('!SetOption B'..b..'R'..r..' SolidColor "'..color..alpha..'"')
            end
        end
    elseif n == 1 then
        -- Style: Gradient
        local RGBA = {{}, {}}
        for i = 1, 2 do
            -- Split color into RGBA components
            local color = SKIN:GetVariable('Color'..i)
            local hex = not string.match(color, ',') and true or false
            for val in string.gmatch(color, hex and '%x%x' or '%d+') do
                if val then
                    RGBA[i][#RGBA[i] + 1] = hex and tonumber(val, 16) or val
                end
            end
            RGBA[i][4] = RGBA[i][4] or 255
        end
        for r = 1, rows do
            local row = rows == 1 and 1 or (r - 1) / (rows - 1)
            local colorGrad = (RGBA[2][1] + (RGBA[1][1] - RGBA[2][1]) * row)..','..
            (RGBA[2][2] + (RGBA[1][2] - RGBA[2][2]) * row)..','..
            (RGBA[2][3] + (RGBA[1][3] - RGBA[2][3]) * row)..','..
            (RGBA[2][4] + (RGBA[1][4] - RGBA[2][4]) * row)
            for b = 0, bands - 1 do
                SKIN:Bang('!SetOption B'..b..'R'..r..' SolidColor '..colorGrad)
            end
        end
    else
        -- Style: Spectrum
        for b = 0, bands - 1 do
            local color = (function(n)
                if n < 0.6 then
                    return ((0.4 - n) * 1275)..','..(n * 1275)..','..((n - 0.4) * 1275)..','
                else
                    return ((n - 0.8) * 1275)..','..((0.8 - n) * 1275)..',255,'
                end
            end)(b / bands)
            for r = 1, rows do
                -- Combine fade
                SKIN:Bang('!SetOption B'..b..'R'..r..' SolidColor '..color..(n == 6 and (1 - r / rows) * 255 or n == 7 and r / rows * 255 or 255))
            end
        end
    end
    style = n
    SKIN:Bang('[!SetOptionGroup Style SolidColor 505050E0][!SetOptionGroup Style MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"]')
    SKIN:Bang('[!SetOptionGroup '..n..' SolidColor FF0000][!SetOptionGroup '..n..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!UpdateMeterGroup Style][!WriteKeyValue Variables Style '..n..' "#@#Settings.inc"]')
end

function SetOmega(n, m)
    -- Set angular velocity
    if m then
        omega = math.floor(m * 0.11) * 0.004 - 0.02
    elseif omega + n <= 0.02 and omega + n >= -0.02 then
        omega = math.floor((omega + n) * 250 + 0.5) * 0.004
    else return end
    SKIN:GetMeter('OmegaSlider'):SetX(130 + omega * 2250)
    SKIN:Bang('[!SetOption OmegaVal Text '..(omega * 250)..'][!WriteKeyValue Variables Omega '..omega..' "#@#Settings.inc"]')
end

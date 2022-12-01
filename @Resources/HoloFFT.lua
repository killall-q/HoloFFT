function Initialize()
  mFFT = {} -- array of FFT measures
  FFT = {} -- array of FFT history
  point = {} -- array of points
  xyScale = 0 -- scale of display and model
  dispR = tonumber(SKIN:GetVariable('DispR')) -- half of display width
  shift = tonumber(SKIN:GetVariable('Shift')) -- shift up off-screen
  filter = SKIN:GetVariable('Filter') == '1' -- filter silence
  bands = tonumber(SKIN:GetVariable('Bands')) -- number of FFT bands
  rows = tonumber(SKIN:GetVariable('Rows')) -- depth of FFT history
  theta = tonumber(SKIN:GetVariable('Theta')) -- pitch angle
  phi = tonumber(SKIN:GetVariable('Phi')) -- roll angle
  psi = tonumber(SKIN:GetVariable('Psi')) -- yaw angle
  omega = tonumber(SKIN:GetVariable('Omega')) -- delta of yaw angle (angular velocity)
  perspective = tonumber(SKIN:GetVariable('Perspective'))
  style = tonumber(SKIN:GetVariable('Style'))
  scroll = 0 -- preset selection list scroll position
  isLocked = false -- lock hiding of mouseover controls
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
  SKIN:Bang('[!SetOption AttackSlider X '..(tonumber(SKIN:GetVariable('Attack')) * 0.09)..'r][!SetOption DecaySlider X '..(tonumber(SKIN:GetVariable('Decay')) * 0.09)..'r][!SetOption SensSlider X '..(tonumber(SKIN:GetVariable('Sens')) * 0.9)..'r][!SetOption Filter'..(filter and 1 or 0)..' SolidColor FF0000][!SetOption Filter'..(filter and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!SetOption ShiftSlider X '..(50 - shift * 50)..'r][!SetOption PerspectiveSlider X '..(perspective * 90)..'r][!SetOption OmegaSlider X '..(45 + omega * 2250)..'r][!SetOption OmegaVal Text '..(omega * 250)..']')
  if SKIN:GetVariable('ShowSet') == '1' then
    SKIN:Bang('[!ShowMeterGroup Control][!ShowMeterGroup Set][!WriteKeyValue Variables ShowSet 0 "#@#Settings.inc"]')
  end
end

function Update()
  psi = (psi + omega) % 6.28
  local sinTheta, cosTheta, sinPhi, cosPhi, sinPsi, cosPsi = math.sin(theta), math.cos(theta), math.sin(phi), math.cos(phi), math.sin(psi), math.cos(psi)
  for r = 1, rows do
    local passVal = r ~= rows
    FFT.peak[r] = passVal and FFT.peak[r + 1] or mFFT.peak:GetValue()
    for b = 0, bands - 1 do
      FFT[b][r] = passVal and FFT[b][r + 1] or mFFT[b]:GetValue()
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

function Pitch(n, reset)
  theta = reset and 0 or math.floor((theta + n) % 6.3 * 10 + 0.5) * 0.1
  SKIN:Bang('!WriteKeyValue Variables Theta '..theta..' "#@#Settings.inc"')
end

function Roll(n, reset)
  phi = reset and 0 or math.floor((phi + n) % 6.3 * 10 + 0.5) * 0.1
  SKIN:Bang('!WriteKeyValue Variables Phi '..phi..' "#@#Settings.inc"')
end

function Yaw(n, reset)
  psi = reset and 0 or math.floor((psi + n) % 6.3 * 10 + 0.5) * 0.1
  SKIN:Bang('!WriteKeyValue Variables Psi '..psi..' "#@#Settings.inc"')
end

function Scale(n)
  if dispR + n < 70 and tonumber(SKIN:GetVariable('SCREENAREAWIDTH')) / 2 < dispR + n then return end
  dispR = dispR + n
  xyScale = dispR * 0.577 -- max radius is square root of 3
  SKIN:Bang('[!MoveMeter '..(dispR * 2)..' '..(dispR * 2)..' Spacer][!SetOption Handle W '..(dispR * 2)..'][!SetOption Handle H '..(dispR * 2)..'][!WriteKeyValue Variables DispR '..dispR..' "#@#Settings.inc"]')
end

function HideControls()
  if isLocked then return end
  SKIN:Bang('[!HideMeterGroup Control][!HideMeterGroup Set]')
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
  elseif 0 <= scroll + n and scroll + n + 10 <= presetCount then
    scroll = scroll + n
    SKIN:Bang('[!SetOption PresetScroll Y '..(190 / (presetCount - 10) * (1 - 10 / presetCount) * scroll + 2)..'r][!CommandMeasure mPreset1 Index'..(n > 0 and 'Down' or 'Up')..']')
  end
end

function SetAttack(n, m)
  local attack = tonumber(SKIN:GetVariable('Attack'))
  if m then
    attack = math.floor(m * 0.11) * 100
  elseif 0 <= attack + n and attack + n <= 1000 then
    attack = math.floor((attack + n) * 0.01 + 0.5) * 100
  else return end
  SKIN:Bang('[!SetOption mFFTPeak PeakAttack '..attack..'][!SetOption mFFTPeak FFTAttack '..attack..'][!SetOption AttackSlider X '..(attack * 0.09)..'r][!SetOption AttackVal Text '..attack..'][!SetVariable Attack '..attack..'][!WriteKeyValue Variables Attack '..attack..' "#@#Settings.inc"]')
end

function SetDecay(n, m)
  local decay = tonumber(SKIN:GetVariable('Decay'))
  if m then
    decay = math.floor(m * 0.11) * 100
  elseif 0 <= decay + n and decay + n <= 1000 then
    decay = math.floor((decay + n) * 0.01 + 0.5) * 100
  else return end
  SKIN:Bang('[!SetOption mFFTPeak PeakDecay '..decay..'][!SetOption mFFTPeak FFTDecay '..decay..'][!SetOption DecaySlider X '..(decay * 0.09)..'r][!SetOption DecayVal Text '..decay..'][!SetVariable Decay '..decay..'][!WriteKeyValue Variables Decay '..decay..' "#@#Settings.inc"]')
end

function SetSens(n, m)
  local sens = tonumber(SKIN:GetVariable('Sens'))
  if m then
    sens = math.floor(m * 0.11) * 10
  elseif 0 <= sens + n and sens + n <= 100 then
    sens = math.floor((sens + n) * 0.1 + 0.5) * 10
  else return end
  SKIN:Bang('[!SetOption mFFTPeak Sensitivity '..sens..'][!SetOption SensSlider X '..(sens * 0.9)..'r][!SetOption SensVal Text '..sens..'][!SetVariable Sens '..sens..'][!WriteKeyValue Variables Sens '..sens..' "#@#Settings.inc"]')
end

function SetFilter(n)
  SKIN:Bang('[!SetOption Filter'..(filter and 1 or 0)..' SolidColor 505050E0][!SetOption Filter'..(filter and 1 or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor 505050E0"][!SetOption Filter'..(n or 0)..' SolidColor FF0000][!SetOption Filter'..(n or 0)..' MouseLeaveAction "!SetOption #*CURRENTSECTION*# SolidColor FF0000"][!WriteKeyValue Variables Filter '..(n or 0)..' "#@#Settings.inc"]')
  filter = n == 1
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

function SetRes(res)
  local set = tonumber(SKIN:GetVariable('Set'))
  if set and set > 0 then
    SKIN:Bang('[!WriteKeyValue Variables '..res..' #Set# "#@#Settings.inc"][!WriteKeyValue Variables ShowSet 1 "#@#Settings.inc"][!Refresh]')
  else
    isLocked = false
  end
end

function SetPixS()
  local set = tonumber(SKIN:GetVariable('Set'))
  if not set or set <= 0 then return end
  SKIN:Bang('[!SetOptionGroup P W #Set#][!SetOptionGroup P H #Set#][!SetOption PixSSet Text "#Set# px"][!SetVariable PixS #Set#][!WriteKeyValue Variables PixS #Set# "#@#Settings.inc"]')
  isLocked = false
end

function SetShift(n, m)
  if m then
    shift = 1 - math.floor(m * 0.2) * 0.1
  elseif -0.9 <= shift + n and shift + n <= 1 then
    shift = math.floor((shift + n) * 10 + 0.5) * 0.1
  else return end
  SKIN:Bang('[!SetOption ShiftSlider X '..(50 - shift * 50)..'r][!WriteKeyValue Variables Shift '..shift..' "#@#Settings.inc"]')
end

function SetPerspective(n, m)
  if m then
    perspective = math.floor(m * 0.11) * 0.1
  elseif 0 <= perspective + n and perspective + n <= 1 then
    perspective = math.floor((perspective + n) * 10 + 0.5) * 0.1
  else return end
  SKIN:Bang('[!SetOption PerspectiveSlider X '..(perspective * 90)..'r][!SetOption PerspectiveVal Text '..perspective..'][!WriteKeyValue Variables Perspective '..perspective..' "#@#Settings.inc"]')
end

function SetColor(n)
  if SKIN:GetVariable('Set') == '' then return end
  SKIN:Bang('[!SetOption Color'..n..'Set Text "#Set#"][!SetVariable Color'..n..' "#Set#"][!WriteKeyValue Variables Color'..n..' "#Set#" "#@#Settings.inc"]')
  isLocked = false
  if style < 4 then
    SetStyle(style)
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
      if not color:find(',') then
        color = color:gsub('%x%x', function(s) return tonumber(s, 16)..',' end)
      end
      return color:match('%d+[,%s]+%d+[,%s]+%d+')..','
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
      local hex = not color:find(',')
      for val in color:gmatch(hex and '%x%x' or '%d+') do
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
  elseif -0.02 <= omega + n and omega + n <= 0.02 then
    omega = math.floor((omega + n) * 250 + 0.5) * 0.004
  else return end
  SKIN:Bang('[!SetOption OmegaSlider X '..(45 + omega * 2250)..'r][!SetOption OmegaVal Text '..(omega * 250)..'][!WriteKeyValue Variables Omega '..omega..' "#@#Settings.inc"]')
end

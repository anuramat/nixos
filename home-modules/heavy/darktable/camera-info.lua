-- image information fields for in-camera settings that darktable's exiv2 can't read
local dt = require "darktable"

local tags = {
  "Nikon:WhiteBalance", "ColorTemperatureAuto", "WhiteBalanceFineTune", "PictureControlName", "PictureControlBase",
  "ActiveD-Lighting", "HighISONoiseReduction", "VignetteControl", "DiffractionCompensation", "AutoDistortionControl",
}
local cache = {}

-- tag name -> value, "-" if missing
local function read(img)
  local file = img.path .. "/" .. img.filename
  if not cache[file] then
    local cmd = "@exiftool@ -config @exiftoolConfig@ -s -s -f -" .. table.concat(tags, " -") .. " '" .. file:gsub("'", "'\\''") .. "'"
    local p, v = io.popen(cmd), {}
    for line in p:lines() do
      local k, val = line:match("^(%S+): (.*)$")
      if k then v[k] = val end
    end
    p:close()
    cache[file] = v
  end
  return cache[file]
end

local function field(name, format)
  dt.gui.libs.metadata_view.register_info(name, function(img) return format(read(img)) end)
end

field("camera white balance", function(v)
  local wb = v.WhiteBalance
  if v.ColorTemperatureAuto ~= "-" then wb = wb .. ", " .. v.ColorTemperatureAuto .. "K" end
  if v.WhiteBalanceFineTune ~= "-" and v.WhiteBalanceFineTune ~= "0 0" then
    wb = wb .. ", fine tune " .. v.WhiteBalanceFineTune
  end
  return wb
end)

field("picture control", function(v)
  local name, base = v.PictureControlName, v.PictureControlBase
  return (base == "-" or base == name) and name or name .. " (" .. base .. ")"
end)

field("active d-lighting", function(v) return v["ActiveD-Lighting"] end)
field("high ISO NR", function(v) return v.HighISONoiseReduction end)
field("vignette control", function(v) return v.VignetteControl end)
field("diffraction compensation", function(v) return v.DiffractionCompensation end)
field("auto distortion control", function(v) return v.AutoDistortionControl end)

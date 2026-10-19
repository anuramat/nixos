-- strip the metadata that darktable exports regardless of the export metadata
-- options: the raw's own XMP and IPTC, the original filename, the rating, and
-- the capture time (written to XMP when EXIF is off)
local dt = require "darktable"

-- tags darktable removes from the raw's copy and writes per the options
local controlled = { "^XMP%-dc:", "^XMP%-lr:", "^XMP%-darktable:", "^XMP%-acdsee:", "^XMP%-xmpMM:PreservedFileName$", "^XMP%-exif:GPS" }

local function quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

dt.register_event("strip-metadata", "intermediate-export-image", function(_, img, file)
  local args = { "-XMP-xmpMM:DerivedFrom=", "-XMP-xmp:Rating=", "-XMP-exif:DateTimeOriginal=" }
  local p = io.popen("@exiftool@ -a -G1 -s -s -XMP:all -IPTC:all " .. quote(img.path .. "/" .. img.filename))
  for line in p:lines() do
    local group, name = line:match("^%[(.-)%] (.-):")
    local tag = group and group .. ":" .. name
    for _, pat in ipairs(controlled) do
      if tag and tag:match(pat) then tag = nil end
    end
    if tag then args[#args + 1] = quote("-" .. tag .. "=") end
  end
  p:close()
  os.execute("@exiftool@ -q -overwrite_original " .. table.concat(args, " ") .. " " .. quote(file))
end)

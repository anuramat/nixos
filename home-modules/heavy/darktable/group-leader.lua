-- swap the leaders of the selected RAW+JPEG groups: JPEG leaders make culling
-- show the JPEG instead of processing the raw
local dt = require "darktable"

local function jpeg(img) return img.filename:lower():match("%.jpe?g$") ~= nil end

local function action(name, label, pred, tooltip)
  dt.gui.libs.image.register_action(name, label, function(_, images)
    for _, img in ipairs(images) do
      if pred(img) and img.group_leader.id ~= img.id then img:make_group_leader() end
    end
  end, tooltip)
end

action("jpeg-leader", "JPEG leader", jpeg, "make the selected JPEGs the leaders of their groups")
action("raw-leader", "raw leader", function(img) return img.is_raw end, "make the selected raws the leaders of their groups")

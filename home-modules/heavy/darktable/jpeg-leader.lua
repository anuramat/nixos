-- make the JPEG the leader of each selected group, so that culling
-- RAW+JPEG pairs shows the JPEG instead of processing the raw
local dt = require "darktable"

dt.gui.libs.image.register_action("jpeg-leader", "JPEG leader", function(_, images)
  for _, img in ipairs(images) do
    if img.filename:lower():match("%.jpe?g$") and img.group_leader.id ~= img.id then img:make_group_leader() end
  end
end, "make the selected JPEGs the leaders of their groups")

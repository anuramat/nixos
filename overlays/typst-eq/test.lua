-- End-to-end check of the plugin, in a neovim without a UI; needs snacks, the typst parser and
-- imagemagick, and SNACKS_GHOSTTY=true, so that snacks places images.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "#let norm(x) = $lr(|| #x ||)$" }, dir .. "/defs.typ")
vim.fn.writefile({ "On disk: $x$." }, dir .. "/main.typ")

vim.api.nvim_set_hl(0, "Normal", { fg = "#ff0000" })
require("snacks").setup({ image = { enabled = true } })
require("typst-eq").setup({ match_colors = true })
vim.cmd("filetype plugin on")
vim.cmd.edit(dir .. "/main.typ")
vim.wo.conceallevel = 2
local buf = vim.api.nvim_get_current_buf()

local function marks()
  local ns = vim.api.nvim_create_namespace("snacks.image")
  return vim.iter(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }))
end

-- where the images are, the text they stand for, and whether they are shown
local function images()
  return marks()
    :filter(function(mark)
      -- the others stand for images that are still loading, or for the further lines of one
      return (mark[4].end_col or 0) > 0
    end)
    :map(function(mark)
      local row, col, details = mark[2], mark[3], mark[4]
      local text = vim.api.nvim_buf_get_text(buf, row, col, details.end_row, details.end_col, {})
      return ("%d:%d %s %s"):format(row, col, text[1], details.virt_text and "shown" or "hidden")
    end)
    :totable()
end

local function expect(want)
  local ok = vim.wait(10000, function()
    return vim.deep_equal(images(), want)
  end, 50)
  assert(ok, ("want %s, got %s"):format(vim.inspect(want), vim.inspect(images())))
end

-- the cursor is on the equation
expect({ "0:9 $x$ hidden" })

-- unsaved text, with an import relative to the file; snacks renders none of the math itself
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '#import "defs.typ": norm',
  "",
  "Unsaved: $norm(x) <= 1$ and",
  "",
  "$ e^(i pi) + 1 = 0 $",
})
expect({ "2:9 $norm(x) <= 1$ shown", "4:0 $ e^(i pi) + 1 = 0 $ shown" })

vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
expect({ "2:9 $norm(x) <= 1$ hidden", "4:0 $ e^(i pi) + 1 = 0 $ shown" })

-- an error keeps the images, and the next good text updates them
vim.api.nvim_buf_set_text(buf, 4, 20, 4, 20, { " #unknown" })
vim.wait(1000)
expect({ "2:9 $norm(x) <= 1$ hidden", "4:0 $ e^(i pi) + 1 = 0 $ shown" })
vim.api.nvim_buf_set_lines(buf, 4, 5, false, { "and $a^2$" })
expect({ "2:9 $norm(x) <= 1$ hidden", "4:4 $a^2$ shown" })

-- without conceal there are no images, and they come back with it
vim.wo.conceallevel = 0
expect({})
vim.wo.conceallevel = 2
expect({ "2:9 $norm(x) <= 1$ hidden", "4:4 $a^2$ shown" })

-- an image with fewer rows than its source hides the other lines, but not under the cursor
local function hides_lines()
  return marks():any(function(mark)
    return mark[4].conceal_lines
  end)
end
vim.api.nvim_buf_set_lines(buf, 4, 5, false, { "$", "  a", "$" })
expect({ "2:9 $norm(x) <= 1$ hidden", "4:0 $ shown" })
assert(hides_lines())
vim.api.nvim_win_set_cursor(0, { 5, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
expect({ "2:9 $norm(x) <= 1$ shown", "4:0 $ hidden" })
assert(not hides_lines())

-- match_colors: the ink is the foreground color
local pngs = vim.fn.glob(vim.fs.dirname(vim.fn.tempname()) .. "/*/*.png", false, true)
assert(#pngs == 5, vim.inspect(pngs))
for _, png in ipairs(pngs) do
  local channels = vim.fn.system({ "magick", png, "-format", "%[fx:maxima.r] %[fx:maxima.g]", "info:" })
  assert(channels == "1 0", png .. ": " .. channels)
end

-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local kbds = require "systems.key_bindings"
local ssa = require "systems.ssa"
local ext = require "utility.extension"

local function default_line_conv(line)
	return line
end

local LineSelect = {}
LineSelect.__index = LineSelect

function LineSelect:move_sel(dir)
	local new_pos = self.active + dir
	if new_pos < 1 or #self.lines < new_pos then return end
	self.active = new_pos
	self:update()
end

function LineSelect:delete_sel()
	table.remove(self.lines, self.active)
	self.active = ext.num_limit(self.active, 1, #self.lines)
	self:update()
end

function LineSelect:new(lines, line_conv, sel_conv, update_handler, limit, init)
	if not line_conv then line_conv = default_line_conv end
	if not sel_conv then sel_conv = line_conv end
	local ls
	ls = {
		_overlay = mp.create_osd_overlay("ass-events"),
		lines = lines,
		line_conv = line_conv,
		sel_conv = sel_conv,
		update_handler = update_handler,
		limit = limit,
		active = ext.num_limit(init, 1, #lines),
		bindings = {
			group = "line_select",
			{
				id = "prev",
				default = "UP",
				action = function() ls:move_sel(-1) end,
				repeatable = true
			},
			{
				id = "next",
				default = "DOWN",
				action = function() ls:move_sel(1) end,
				repeatable = true
			},
		}
	}
	return setmetatable(ls, LineSelect)
end

function LineSelect:show()
	kbds.add(self.bindings)
	self:update()
end

function LineSelect:hide()
	kbds.remove(self.bindings)
	self._overlay:remove()
end

function LineSelect:selection()
	return self.lines[self.active], self.active
end

function LineSelect:finish()
	self:hide()
	return self:selection()
end

function LineSelect:update()
	-- all lines were deleted
	if #self.lines == 0 then
		self:hide()
		return
	end

	if self.update_handler then self.update_handler(self.lines[self.active], self.active) end

	local first, last
	if not self.limit or self.limit >= #self.lines then
		first, last = 1, #self.lines
	else
		first = math.ceil(self.active - self.limit / 2)
		if first < 1 then first = 1 end

		last = math.floor(self.active + self.limit / 2) - (self.limit + 1) % 2
		if last > #self.lines then last = #self.lines end

		if first == 1 then
			last = self.limit
		elseif last == #self.lines then
			first = #self.lines - self.limit + 1
		end
	end

	local ssa_definition = {
		style = "line_select",
		full_style = true
	}
	if first ~= 1 then
		table.insert(ssa_definition, {
			newline = true,
			"..."
		})
	end

	for i = first, last do
		local line = self.lines[i]
		local active = i == self.active
		local conv = active and self.sel_conv or self.line_conv

		local ssa_str_def = {
			newline = true,
			conv(line)
		}
		if active then
			ssa_str_def.style = {"line_select", "selection"}
		end

		table.insert(ssa_definition, ssa_str_def)
	end

	if last ~= #self.lines then
		table.insert(ssa_definition, "...")
	end

	self._overlay.data = ssa.generate(ssa_definition)
	self._overlay:update()
end

return LineSelect

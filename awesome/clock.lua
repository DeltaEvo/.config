-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
-- Widget and layout library
local wibox = require("wibox")

local lgi = require("lgi")
local Pango = lgi.Pango
local PangoCairo = lgi.PangoCairo
local glib = require("lgi").GLib

local clock = {}

local gold = gears.color("#FFD700")
local text_color = gears.color("#3d94ae")
local hours = {"XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"}
local colors = {
	gears.color("#282A36"),
	gears.color("#F37F97"),
	gears.color("#5ADECD"),
	gears.color("#F2A272"),
	gears.color("#8897F4"),
	gears.color("#C574DD"),
	gears.color("#79E6F3"),
	gears.color("#FDFDFD"),
	gears.color("#414458"),
	gears.color("#FF4971"),
	gears.color("#18E3C8"),
	gears.color("#FF8037")
}

function draw_clock_pointer(cr, radius, p)
	cr:move_to(0, 0)
	cr:line_to(0, -radius / p + 50)
	cr:move_to(-cr:get_line_width() / 4, -radius / p)
	cr:curve_to(
		25, -radius / p + 40,
		25, -radius / p + 70,
		0, -radius / p + 50
	)
	cr:move_to(cr:get_line_width() / 4, -radius / p)
	cr:curve_to(
		-25, -radius / p + 40,
		-25, -radius / p + 70,
		0, -radius / p + 50
	)
	cr:stroke()
	cr:set_line_width(2)
	cr:move_to(0, -radius / p + 50)
	cr:line_to(0, -radius / p)
	cr:stroke()
end

function clock:draw(_, cr, width, height)
    -- Find the maximum square available
	local m = math.min(width, height) - 100
	local x_gap = (width - m) / 2;
	local y_gap = (height - m) / 2;
	-- cr:set_source(gears.color("#FF0000"))
	-- cr:rectangle(x_gap, y_gap, width - x_gap * 2, height - y_gap * 2)
	-- cr:fill()
	local radius = m / 2
	cr:translate(x_gap + radius, y_gap + radius)
	cr:set_line_width(3)
	cr:set_source(gold)
	cr:arc(0, 0, radius, 0, math.pi * 2)
	cr:stroke()
	cr:arc(0, 0, radius - 20, 0, math.pi * 2)
	cr:stroke()
	cr:arc(0, 0, radius / 1.5, 0, math.pi * 2)
	cr:stroke()
	cr:arc(0, 0, radius / 4, 0, math.pi * 2)
	cr:stroke()
	cr:set_line_width(1.5)
	local time = glib.DateTime.new_now(glib.TimeZone.new_local())
	for i=0,59 do
		local length = 20
		if i % 5 == 0 then
			length = radius - radius / 1.5
		end
		if i % 15 == 0 then
			length = radius - radius / 4
		end
		cr:rotate(i / 60 * math.pi * 2);
		cr:set_source(gold)
		cr:move_to(0, -radius)
		cr:line_to(0, -radius + length)
		cr:stroke()
		cr:identity_matrix()
		cr:translate(x_gap + radius, y_gap + radius)
		if i % 5 == 0 then
			local l = radius - radius / 1.5
			local m = gears.matrix.identity:rotate(i / 60 * math.pi * 2)

			self._private.layout.text = hours[i / 5 + 1]
			self._private.layout.font_description = Pango.FontDescription.from_string("sans 50")
			self._private.layout.width = Pango.units_from_double(l)
			self._private.layout.height = Pango.units_from_double(l / 2)

			local x, y = m:transform_point(0, -radius + l / 2)
			local l_width, l_height = self._private.layout:get_pixel_size()

			cr:move_to(x - l_width / 2, y - l_height / 2)
			cr:set_source(colors[i / 5 + 1])
			cr:update_layout(self._private.layout)
			cr:show_layout(self._private.layout)
		end
	end

	-- Minutes
	local minutes = time:get_minute() + time:get_seconds() / 60
	cr:set_line_width(5)
	cr:rotate(minutes / 60 * math.pi * 2);
	cr:set_source(gold)
	draw_clock_pointer(cr, radius, 1.4)
	cr:identity_matrix()
	cr:translate(x_gap + radius, y_gap + radius)

	-- Hours
	local hours = time:get_hour() + minutes / 60
	cr:set_line_width(6)
	cr:rotate(hours / 12 * math.pi * 2);
	cr:set_source(gold)
	draw_clock_pointer(cr, radius, 2)
	cr:identity_matrix()
	cr:translate(x_gap + radius, y_gap + radius)

	cr:arc(0, 0, 20, 0, math.pi * 2)
	cr:fill()
end

local function new_clock()
	local widget = wibox.widget.base.make_widget(nil, "clock", {enable_properties = true})

	gears.table.crush(widget, clock, true)


    widget._private.ctx = PangoCairo.font_map_get_default():create_context()
	widget._private.layout = Pango.Layout.new(widget._private.ctx)
	
	widget._private.timer = gears.timer.start_new(2.5, function()
		widget:emit_signal("widget::redraw_needed")
		return true
	end)
	widget._private.timer:start()

	return widget
end

awful.screen.connect_for_each_screen(function(s)
	local box = wibox({
		screen = s,
		visible = true,
		widget = new_clock(),
		bg = "#00000000"
	})

	awful.placement.maximize(box, {
	    attach = true,
	})
end)
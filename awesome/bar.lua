-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
-- Widget and layout library
local wibox = require("wibox")

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local clock = wibox.widget.textclock(' <span font_desc="sans 12" weight="bold">%H:%M</span>:%S ', 1)

local background = "#00000000"
local foreground = "#ffffff"
-- https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=5E35B1
local margin = "#5e35b1"


local base = wibox.widget.base

local border = {}


function border:fit(context, width, height)
	local extra_w = self.left + self.rigth;
	local w, h = base.fit_widget(self, context, self.child, width - extra_w, height)

	return w + extra_w, h
end

function border:layout(_, width, height)
	return { base.place_widget_at(self.child, self.left, 0, width - self.left - self.rigth, height) }
end

function border:draw(_, cr, width, height)
	cr:set_source(gears.color(margin))
	cr:rectangle(self.left, 0, width - self.left - self.rigth, height)
	cr:fill()
	cr:move_to(0, 0)
	cr:line_to(self.left, height)
	cr:line_to(self.left, 0)
	cr:fill()
	cr:move_to(width, 0)
	cr:line_to(width - self.rigth, height)
	cr:line_to(width - self.rigth, 0)
	cr:fill()
end

local function new_border(child, left, rigth)
	local widget = base.make_widget(nil, "border", {enable_properties = true})

	gears.table.crush(widget, border, true)

	widget.child = child
	widget.left = left
	widget.rigth = rigth

	return widget
end

local border_size = 15;

awful.screen.connect_for_each_screen(function(s)
    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.noempty,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = wibox({
		screen = s,
		visible = true,
		height = 20,
		ontop = true,
		bg = background,
		fg = foreground,
		widget = wibox.widget {
			layout = wibox.layout.align.horizontal,
			expand = "outside",
			wibox.widget { -- Left widgets
				layout = wibox.layout.align.horizontal,
				new_border(s.mytaglist, 0, border_size),
				nil,
				nil
			},
			new_border(clock, border_size, border_size), -- Middle widget
			{ -- Right widgets
				layout = wibox.layout.align.horizontal,
				nil,
				nil,
				new_border(wibox.widget { -- Align left
					layout = wibox.layout.fixed.horizontal,
					mykeyboardlayout,
					wibox.widget.systray(),
					mytextclock,
					s.mylayoutbox,
				}, border_size, 0)
			},
		}
	})
	awful.placement.maximize_horizontally(s.mywibox, {
	    attach = true,
	})
	awful.placement.top(s.mywibox, {
	    attach = true,
	    update_workarea = true,
	})
end)

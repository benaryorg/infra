{ lib, fetchurl, writeTextFile
, alacritty
, tmux
, alock
, gscreenshot
, enablePatchage ? false, patchage
, alsa-utils
}:
let
  background-image = fetchurl
  {
    url = "https://www.exocomics.com/downloads/desktop/17_Ramen/EXO_Ramen_1920_1080.jpg";
    hash = "sha256-lqVzjF95rLCMPDnDGJOE935HoHtXf3VbKnT7Os+fqjU=";
  };
in
  writeTextFile
  {
    name = "benaryorg-awesome-configuration";
    destination = "/rc.lua";
    text =
    ''
      -- Standard awesome library
      local gears = require("gears")
      local awful = require("awful")
      local remote = require("awful.remote")
      require("awful.autofocus")
      -- Widget and layout library
      local wibox = require("wibox")
      -- Theme handling library
      local beautiful = require("beautiful")
      -- Notification library
      local naughty = require("naughty")
      local menubar = require("menubar")
      local hotkeys_popup = require("awful.hotkeys_popup").widget
      -- Enable VIM help for hotkeys widget when client with matching name is opened:
      require("awful.hotkeys_popup.keys.vim")

      -- {{{ Error handling
      -- Check if awesome encountered an error during startup and fell back to
      -- another config (This code will only ever execute for the fallback config)
      if awesome.startup_errors then
          naughty.notify({ preset = naughty.config.presets.critical,
                           title = "Oops, there were errors during startup!",
                           text = awesome.startup_errors })
      end

      -- Handle runtime errors after startup
      do
          local in_error = false
          awesome.connect_signal("debug::error", function (err)
              -- Make sure we don't go into an endless error loop
              if in_error then return end
              in_error = true

              naughty.notify({ preset = naughty.config.presets.critical,
                               title = "Oops, an error happened!",
                               text = tostring(err) })
              in_error = false
          end)
      end
      -- }}}

      -- {{{ X Property registration
      awesome.register_xproperty("STEAM_GAME", "number")
      -- }}}

      -- {{{ Variable definitions
      -- Themes define colours, icons, font and wallpapers.
      gfs = require("gears.filesystem")
      beautiful.init(gfs.get_themes_dir() .. "default/theme.lua")
      beautiful.font = "monospace"
      beautiful.wallpaper = "${background-image}"

      -- This is used later as the default terminal and editor to run.
      terminal = "${alacritty}/bin/alacritty"
      terminal_cmd = terminal .. " -e ${tmux}/bin/tmux new-session -t work -f active-pane"
      lockscreen = "${alock}/bin/alock -auth pam -bg none -cursor glyph"
      editor = os.getenv("EDITOR") or "vi"
      editor_cmd = terminal .. " -e " .. editor
      screenshot = "${gscreenshot}/bin/gscreenshot -c -s"
      ${lib.optionalString enablePatchage ''patchage = "${patchage}/bin/patchage"''}
      volume = "${alsa-utils}/bin/amixer sset 'Master'"
      volume_amount = "1%"
      volume_up = volume .. " " .. volume_amount .. "+"
      volume_down = volume .. " " .. volume_amount .. "-"

      -- Default modkey.
      -- Usually, Mod4 is the key with a logo between Control and Alt.
      -- If you do not like this or do not have such a key,
      -- I suggest you to remap Mod4 to another key using xmodmap or other tools.
      -- However, you can use another modifier like Mod1, but it may interact with others.
      modkey = "Mod4"

      -- Table of layouts to cover with awful.layout.inc, order matters.
      awful.layout.layouts = {
          awful.layout.suit.fair,
          awful.layout.suit.fair.horizontal,
          awful.layout.suit.floating,
          -- awful.layout.suit.tile,
          -- awful.layout.suit.tile.left,
          -- awful.layout.suit.tile.bottom,
          -- awful.layout.suit.tile.top,
          -- awful.layout.suit.fair,
          -- awful.layout.suit.fair.horizontal,
          -- awful.layout.suit.spiral,
          -- awful.layout.suit.spiral.dwindle,
          -- awful.layout.suit.max,
          -- awful.layout.suit.max.fullscreen,
          -- awful.layout.suit.magnifier,
          -- awful.layout.suit.corner.nw,
          -- awful.layout.suit.corner.ne,
          -- awful.layout.suit.corner.sw,
          -- awful.layout.suit.corner.se,
      }
      -- }}}

      -- {{{ Helper functions
      local function client_menu_toggle_fn()
          local instance = nil

          return function ()
              if instance and instance.wibox.visible then
                  instance:hide()
                  instance = nil
              else
                  instance = awful.menu.clients({ theme = { width = 250 } })
              end
          end
      end

      local function prevtag(s)
        local tag = s.selected_tag
        local target = awful.tag.find_by_name(s, tostring((tonumber(tag.name) + 9) % 10))
        if not target then
          target = awful.tag.find_by_name(s, tostring((tonumber(tag.name) + 8) % 10))
        end
        return target
      end

      local function nexttag(s)
        local tag = s.selected_tag
        local target = awful.tag.find_by_name(s, tostring((tonumber(tag.name) + 1) % 10))
        if not target then
          target = awful.tag.find_by_name(s, tostring((tonumber(tag.name) + 2) % 10))
        end
        return target
      end
      -- }}}

      -- {{{ Menu
      -- Create a launcher widget and a main menu
      myawesomemenu = {
         { "hotkeys", function() return false, hotkeys_popup.show_help end},
         { "manual", terminal .. " -e man awesome" },
         { "edit config", editor_cmd .. " " .. awesome.conffile },
         { "restart", awesome.restart },
         { "quit", function() awesome.quit() end}
      }

      mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                          { "open terminal", terminal_cmd }
                                        }
                              })

      -- mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
      --                                     menu = mymainmenu })

      -- Menubar configuration
      menubar.utils.terminal = terminal -- Set the terminal for applications that require it
      -- }}}

      -- Keyboard map indicator and switcher
      mykeyboardlayout = awful.widget.keyboardlayout()

      -- {{{ Wibar
      -- Create a textclock widget
      mytextclock = wibox.widget.textclock("%a %Y-%m-%d %H:%M:%S",0.5)

      -- Create a wibox for each screen and add it
      local taglist_buttons = gears.table.join(
                          awful.button({ }, 1, function(t) t:view_only() end),
                          awful.button({ modkey }, 1, function(t)
                                                    if client.focus then
                                                        client.focus:move_to_tag(t)
                                                    end
                                                end),
                          -- TODO: maybe middle click to move the tag to the other screen?
                          -- awful.button({ }, 2, function(t) end),
                          awful.button({ }, 3, awful.tag.viewtoggle),
                          awful.button({ modkey }, 3, function(t)
                                                    if client.focus then
                                                        client.focus:toggle_tag(t)
                                                    end
                                                end),
                          awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                          awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                      )

      local tasklist_buttons = gears.table.join(
                           awful.button({ }, 1, function (c)
                                                    if c == client.focus then
                                                        c.minimized = true
                                                    else
                                                        -- Without this, the following
                                                        -- :isvisible() makes no sense
                                                        c.minimized = false
                                                        if not c:isvisible() and c.first_tag then
                                                            c.first_tag:view_only()
                                                        end
                                                        -- This will also un-minimize
                                                        -- the client, if needed
                                                        client.focus = c
                                                        c:raise()
                                                    end
                                                end),
                           awful.button({ }, 3, client_menu_toggle_fn()),
                           awful.button({ }, 4, function ()
                                                    awful.client.focus.byidx(1)
                                                end),
                           awful.button({ }, 5, function ()
                                                    awful.client.focus.byidx(-1)
                                                end))

      local function set_wallpaper(s)
          -- Wallpaper
          if beautiful.wallpaper then
              local wallpaper = beautiful.wallpaper
              -- If wallpaper is a function, call it with the screen
              if type(wallpaper) == "function" then
                  wallpaper = wallpaper(s)
              end
              gears.wallpaper.maximized(wallpaper, s, true)
          end
      end

      -- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
      screen.connect_signal("property::geometry", set_wallpaper)

      awful.screen.connect_for_each_screen(function(s)
          -- Wallpaper
          set_wallpaper(s)

        if s == screen.primary then
          awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
        else
          awful.tag({ "0" }, s, awful.layout.layouts[1])
        end

          -- Create a promptbox for each screen
          s.mypromptbox = awful.widget.prompt()
          -- Create an imagebox widget which will contains an icon indicating which layout we're using.
          -- We need one layoutbox per screen.
          s.mylayoutbox = awful.widget.layoutbox(s)
          s.mylayoutbox:buttons(gears.table.join(
                                 awful.button({ }, 1, function () awful.layout.inc( 1) end),
                                 awful.button({ }, 3, function () awful.layout.inc(-1) end),
                                 awful.button({ }, 4, function () awful.layout.inc( 1) end),
                                 awful.button({ }, 5, function () awful.layout.inc(-1) end)))
          -- Create a taglist widget
          s.mytaglist = awful.widget.taglist {
            screen = s,
            buttons = taglist_buttons,
            filter  = awful.widget.taglist.filter.all,
            source = function(s)
                tags = s.tags
                table.sort(tags, function(a, b) return a.name < b.name end)
                return tags
              end,
          }

          -- Create a tasklist widget
          s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

          -- Create the wibox
          s.mywibox = awful.wibar({ position = "top", screen = s, height = 20, })

          -- Add widgets to the wibox
          s.mywibox:setup {
              layout = wibox.layout.align.horizontal,
              { -- Left widgets
                  layout = wibox.layout.fixed.horizontal,
                  -- mylauncher,
                  s.mypromptbox,
              },
              s.mytasklist, -- Middle widget
              { -- Right widgets
                  layout = wibox.layout.fixed.horizontal,
                  mykeyboardlayout,
                  wibox.widget.systray(),
            s.mytaglist,
                  mytextclock,
                  s.mylayoutbox,
              },
          }
      end)
      -- }}}

      -- {{{ Mouse bindings
      root.buttons(gears.table.join(
          awful.button({ }, 3, function () mymainmenu:toggle() end),
          awful.button({ }, 4, function()
            local primary = screen.primary
            local s = mouse.screen
            if not s == primary then return end
            local tag = prevtag(s)
            if tag then
              tag:view_only()
            end
          end),
          awful.button({ }, 5, function()
            local primary = screen.primary
            local s = mouse.screen
            if not s == primary then return end
            local tag = nexttag(s)
            if tag then
              tag:view_only()
            end
          end)
      ))
      -- }}}

      -- {{{ Key bindings
      globalkeys = gears.table.join(
          awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
                    {description="show help", group="awesome"}),
          awful.key({ modkey,           }, "Left", function()
            local primary = screen.primary
            local s = mouse.screen
            if not s == primary then return end
            local tag = prevtag(s)
            if tag then
              tag:view_only()
            end
          end,
          {description = "view previous", group = "tag"}),
          awful.key({ modkey,           }, "Right", function()
            local primary = screen.primary
            local s = mouse.screen
            if not s == primary then return end
            local tag = nexttag(s)
            if tag then
              tag:view_only()
            end
          end,
          {description = "view next", group = "tag"}),

          awful.key({ modkey,           }, "Tab",
              function ()
                  awful.client.focus.byidx( 1)
              end,
              {description = "focus next by index", group = "client"}
          ),
          awful.key({ modkey, "Shift",  }, "Tab",
              function ()
                  awful.client.focus.byidx(-1)
              end,
              {description = "focus previous by index", group = "client"}
          ),

          -- Layout manipulation
          awful.key({ modkey,           }, "a", awful.client.urgent.jumpto,
                    {description = "jump to urgent client", group = "client"}),

          -- Standard program
          awful.key({ modkey,           }, "l", function () awful.spawn(lockscreen) end,
                    {description = "lock the screen", group = "client"}),
          awful.key({ modkey,           }, "Return", function () awful.spawn(terminal_cmd) end,
                    {description = "open a terminal", group = "launcher"}),
          awful.key({ modkey, "Shift"   }, "s", function () awful.spawn(screenshot) end,
                    {description = "take a screenshot", group = "launcher"}),
          awful.key({ modkey, "Shift",  }, "r", awesome.restart,
                    {description = "reload awesome", group = "awesome"}),
          awful.key({ modkey, "Shift"   }, "q", awesome.quit,
                    {description = "quit awesome", group = "awesome"}),

          -- Volume
          awful.key({ modkey,           }, "Up", function () awful.spawn(volume_up) end,
                    {description = "volume up", group = "launcher"}),
          awful.key({ modkey,           }, "Down", function () awful.spawn(volume_down) end,
                    {description = "volume down", group = "launcher"}),
      ${lib.optionalString enablePatchage ''
          awful.key({ modkey,           }, "p", function () awful.spawn(patchage) end,
                    {description = "patchage", group = "launcher"}),
      ''}
          -- Layout
          awful.key({ modkey, "Shift"   }, "t", function () awful.spawn("setxkbmap us") end,
                    {description = "keyboard layout us", group = "desktop"}),
          awful.key({ modkey, "Shift"   }, "l", function () awful.spawn("setxkbmap de neo") end,
                    {description = "keyboard layout neo", group = "desktop"}),

          -- Menubar
          awful.key({ modkey }, "r", function() menubar.show() end,
                    {description = "show the menubar", group = "launcher"})
      )

      clientkeys = gears.table.join(
          awful.key({ modkey,           }, "f",
              function (c)
                  c.fullscreen = not c.fullscreen
                  c:raise()
              end,
              {description = "toggle fullscreen", group = "client"}),
          awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
                    {description = "close", group = "client"}),
          awful.key({ modkey,           }, "space",  awful.client.floating.toggle                     ,
                    {description = "toggle floating", group = "client"}),
          awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
                    {description = "toggle keep on top", group = "client"}),
          awful.key({ modkey,           }, "n",
              function (c)
                  -- The client currently has the input focus, so it cannot be
                  -- minimized, since minimized clients can't have the focus.
                  c.minimized = true
              end ,
              {description = "minimize", group = "client"}),
          awful.key({ modkey,           }, "m",
              function (c)
                  c.maximized = not c.maximized
                  c:raise()
              end ,
              {description = "(un)maximize", group = "client"}),
        -- Move client to left.
        awful.key({ modkey, "Shift" }, "Left",
          function (c)
            local index = c.first_tag.index
            local new_index = (index == 1) and (9) or (index - 1)
            local tag = c.screen.tags[new_index]
            if tag then
                c:move_to_tag(tag)
            end
          end,
          {description = "move focused client to left", group = "client"}),
        -- Move client to right.
        awful.key({ modkey, "Shift" }, "Right",
          function (c)
            local index = c.first_tag.index
            local new_index = (index == 9) and (1) or (index + 1)
            local tag = c.screen.tags[new_index]
            if tag then
                c:move_to_tag(tag)
            end
          end,
          {description = "move focused client to right", group = "client"})
      )

      -- Bind all key numbers to tags.
      -- Be careful: we use keycodes to make it work on any keyboard layout.
      -- This should map on the top row of your keyboard, usually 1 to 9.
      for i = 1, 9 do
          globalkeys = gears.table.join(globalkeys,
              -- View tag only.
              awful.key({ modkey }, "#" .. i + 9,
            function ()
              local primary = screen.primary
              local secondary = ((screen[1] == primary) and screen[2]) or screen[1]
              local s = awful.screen.focused()
              local tag = awful.tag.find_by_name(primary, tostring(i))
              if primary == s then
                if tag then
                  tag:view_only()
                else
                  tag = awful.tag.find_by_name(secondary, tostring(i))
                  local zero = awful.tag.find_by_name(primary, "0")
                  tag:swap(zero)
                  tag:view_only()
                  zero:view_only()
                end
              else
                if tag then
                  local other = secondary.tags[1]
                  local selected = primary.selected_tags
                  for k, v in pairs(selected) do
                    if v.name == tostring(i) then
                      selected[k] = other
                    end
                  end
                  tag:swap(other)
                  tag:view_only()
                  awful.tag.viewnone(primary)
                  awful.tag.viewmore(selected, primary)
                end
              end
            end,
            {description = "view tag #"..i, group = "tag"}),
              -- Toggle tag display.
              awful.key({ modkey, "Control" }, "#" .. i + 9,
            function ()
              local primary = screen.primary
              local s = awful.screen.focused()
              local secondary = ((screen[1] == primary) and screen[2]) or screen[1]
              if s == primary then
                local tag = awful.tag.find_by_name(s, tostring(i))
                if tag then
                  awful.tag.viewtoggle(tag)
                else
                  tag = awful.tag.find_by_name(secondary, tostring(i))
                  local zero = awful.tag.find_by_name(primary, "0")
                  local selected = primary.selected_tags
                  for k, v in pairs(selected) do
                    if v.name == tostring(i) then
                      selected[k] = zero
                    end
                  end
                  table.insert(selected, tag)
                  tag:swap(zero)
                  zero:view_only()
                  awful.tag.viewnone(primary)
                  awful.tag.viewmore(selected, primary)
                end
              end
            end,
            {description = "toggle tag #" .. i, group = "tag"}),
              -- Move client to tag.
              awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function ()
              if client.focus then
                local tag = awful.tag.find_by_name(s, tostring(i))
                if tag then
                  client.focus:move_to_tag(tag)
                end
               end
            end,
            {description = "move focused client to tag #"..i, group = "tag"}),
              -- Toggle tag on focused client.
              awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function ()
              if client.focus then
                local tag = awful.tag.find_by_name(s, tostring(i))
                if tag then
                  client.focus:toggle_tag(tag)
                end
              end
            end,
            {description = "toggle focused client on tag #" .. i, group = "tag"})
          )
      end

      clientbuttons = gears.table.join(
          awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
          awful.button({ modkey }, 1, awful.mouse.client.move),
          awful.button({ modkey }, 3, awful.mouse.client.resize))

      -- Set keys
      root.keys(globalkeys)
      -- }}}

      -- {{{ Rules
      -- Rules to apply to new clients (through the "manage" signal).
      awful.rules.rules = {
          -- All clients will match this rule.
          { rule = { },
            properties = { border_width = beautiful.border_width,
                           border_color = beautiful.border_normal,
                           focus = awful.client.focus.filter,
                           raise = true,
                           keys = clientkeys,
                           buttons = clientbuttons,
                           screen = awful.screen.preferred,
                           placement = awful.placement.no_overlap+awful.placement.no_offscreen
           }
          },

          -- Floating clients.
          { rule_any = {
              instance = {
                "DTA",  -- Firefox addon DownThemAll.
                "copyq",  -- Includes session name in class.
              },
              class =
              { "Arandr"
              , "Gpick"
              , "Kruler"
              , "MessageWin"  -- kalarm.
              , "Sxiv"
              , "Wpa_gui"
              , "pinentry"
              , "veromix"
              , "xtightvncviewer"
              },

              name = {
                "Event Tester",  -- xev.
              },
              role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
              }
            }, properties = { floating = true }},

          { rule = { class = "Edmarketconnector" }, properties = { floating = true, above = true } },

          { rule = { class = "qutebrowser" }, properties = { screen = 1, tag = "2" } },
          { rule = { class = "Firefox" }, properties = { screen = 1, tag = "2" } },
          { rule = { class = "firefox" }, properties = { screen = 1, tag = "2" } },
          { rule = { class = "Nightly" }, properties = { screen = 1, tag = "2" } },
          { rule = { class = "Mumble" }, properties = { screen = 1, tag = "5" } },
          { rule = { class = "discord" }, properties = { screen = 1, tag = "5" } },
          { rule = { class = "Pidgin" }, properties = { screen = 1, tag = "3" } },
          { rule = { class = "Gajim" }, properties = { screen = 1, tag = "3" } },
          { rule = { class = "Mattermost" }, properties = { screen = 1, tag = "3" } },
          { rule = { class = "Thunderbird" }, properties = { screen = 1, tag = "4" } },
          { rule = { class = "thunderbird" }, properties = { screen = 1, tag = "4" } },
          { rule = { class = "Earlybird" }, properties = { screen = 1, tag = "4" } },
          { rule = { class = "Music" }, properties = { screen = 1, tag = "5" } },
          { rule = { class = "Patchage" }, properties = { screen = 1, tag = "6" } },
          { rule = { class = "Google-chrome" }, properties = { screen = 1, tag = "6" } },
          { rule = { class = "gdlauncher" }, properties = { screen = 1, tag = "7" } },
          { rule = { class = "Minecraft" }, properties = { screen = 1, tag = "8" } },
          { rule = { class = "upc.exe" }, properties = { screen = 1, tag = "9" } },
          { rule = { class = "Lutris" }, properties = { screen = 1, tag = "9" } },
          { rule = { class = "galaxyclient.exe" }, properties = { screen = 1, tag = "9", floating=false } },
      }
      -- }}}

      -- {{{ Signals
      -- Signal function to execute when a new client appears.
      client.connect_signal("manage", function (c)
          -- Set the windows at the slave,
          -- i.e. put it at the end of others instead of setting it master.
          -- if not awesome.startup then awful.client.setslave(c) end

          if awesome.startup and
            not c.size_hints.user_position
            and not c.size_hints.program_position then
              -- Prevent clients from being unreachable after screen count changes.
              awful.placement.no_offscreen(c)
          end

          -- move steam games to tag 8, steam itself to tag 9
          local steam = c.get_xproperty(c, "STEAM_GAME")
          local steam_handlers =
          {
              ["default"] = function()
                  c:tags({ awful.tag.find_by_name(nil, "8") })
                  c.fullscreen = true
              end,
              [769] = function()
                  c:tags({ awful.tag.find_by_name(nil, "9") })
                  c.fullscreen = false
              end,
              [459820] = function()
                  c:tags({ awful.tag.find_by_name(nil, "8") })
                  c.fullscreen = false
                  c.maximized  = true
              end,
          }
          if steam then
              local handler = steam_handlers[steam] or steam_handlers["default"]
              handler()
          end
      end)

      -- Add a titlebar if titlebars_enabled is set to true in the rules.
      client.connect_signal("request::titlebars", function(c)
          -- buttons for the titlebar
          local buttons = gears.table.join(
              awful.button({ }, 1, function()
                  client.focus = c
                  c:raise()
                  awful.mouse.client.move(c)
              end),
              awful.button({ }, 3, function()
                  client.focus = c
                  c:raise()
                  awful.mouse.client.resize(c)
              end)
          )

          awful.titlebar(c) : setup {
              { -- Left
                  awful.titlebar.widget.iconwidget(c),
                  buttons = buttons,
                  layout  = wibox.layout.fixed.horizontal
              },
              { -- Middle
                  { -- Title
                      align  = "center",
                      widget = awful.titlebar.widget.titlewidget(c)
                  },
                  buttons = buttons,
                  layout  = wibox.layout.flex.horizontal
              },
              { -- Right
                  awful.titlebar.widget.floatingbutton (c),
                  awful.titlebar.widget.maximizedbutton(c),
                  awful.titlebar.widget.stickybutton   (c),
                  awful.titlebar.widget.ontopbutton    (c),
                  awful.titlebar.widget.closebutton    (c),
                  layout = wibox.layout.fixed.horizontal()
              },
              layout = wibox.layout.align.horizontal
          }
      end)

      -- Enable sloppy focus, so that focus follows mouse.
      client.connect_signal("mouse::enter", function(c)
          if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
              and awful.client.focus.filter(c) then
              client.focus = c
          end
      end)

      client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
      client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
      -- }}}
    '';
  }

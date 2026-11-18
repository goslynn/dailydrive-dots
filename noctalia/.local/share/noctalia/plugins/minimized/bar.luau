--!nonstrict
-- One icon per window on special:minimized; click one to restore it, or pick
-- one from the keyboard with the alt+tab switcher (SUPER+TAB, see
-- hypr/conf.d/minimize.lua for the protocol).
--
-- The pill has a fixed size: VISIBLE slots, newest window first, with a
-- chevron at each end that lights up when there is more to that side. Past
-- VISIBLE windows the strip scrolls: mouse wheel or chevron clicks, and the
-- switcher keeps its selection in view.
--
-- Restoring goes back through Hyprland's own Lua (minimize.lua's M.restore via
-- `hyprctl eval`) so the "move to the workspace you are on, then focus" logic
-- lives in one place.
--
-- With nothing minimized the widget hides and the bar is hidden too
-- (bar-hide / bar-show on bar.bottombar), so no empty pill is left behind.

local WORKSPACE = "special:minimized"
local BAR = "bottombar"
local ICON_SIZE = 20
local SLOT = 30 -- icon plus its selection padding
local VISIBLE = 6
local GAP = 6

local icons = {} -- class -> icon path (or false when nothing resolves)
local windows = {} -- { address, class, title }, newest first
local seq = {} -- address -> when this widget first saw it minimized
local nextSeq = 0
local barShown = nil -- last state sent to bar-show / bar-hide
local viewStart = 1 -- index of the leftmost visible window

-- Keyboard switcher. Hyprland sends "<session>:<seq>:<offset>", offset
-- counted from the newest window; only the highest seq of a session counts,
-- so out-of-order IPC still lands right.
local switchSession = nil -- session being shown, nil when not switching
local switchSeq = 0
local switchOffset = 0
local endedSession = 0 -- highest session committed or cancelled

-- A cache miss in appIconPath scans the icon directories. For a class with
-- no desktop entry that scan can blow noctalia's per-callback CPU budget on
-- its own, and the error aborts whatever callback it ran in. So render()
-- never looks icons up: it shows the fallback glyph for unknown classes and
-- queues them, and each one is resolved in a callback of its own (pcall'd;
-- a failed lookup just keeps the glyph), followed by a fresh render.
local iconQueue = {} -- classes waiting for a lookup, in order
local queued = {} -- class -> true while in iconQueue
local resolving = false
local render

local function resolveNextIcon()
  local class = table.remove(iconQueue, 1)
  if not class then
    resolving = false
    return
  end
  queued[class] = nil
  local ok, path = pcall(noctalia.appIconPath, class, ICON_SIZE * 2)
  icons[class] = (ok and path) or false
  noctalia.runAsync({ "true" }, function()
    render()
    noctalia.runAsync({ "true" }, resolveNextIcon)
  end)
end

local function iconFor(class)
  local cached = icons[class]
  if cached == nil then
    if not queued[class] then
      queued[class] = true
      table.insert(iconQueue, class)
    end
    if not resolving then
      resolving = true
      noctalia.runAsync({ "true" }, resolveNextIcon)
    end
    return nil
  end
  return cached or nil
end

local function noctaliaMsg(...)
  noctalia.runAsync({ "noctalia", "msg", ... })
end

-- Runs fn after the bar's own auto_hide_delay_ms, so anything this widget
-- puts away lingers exactly as long as after a hover. A newer call cancels
-- an older one still waiting. `first` (a noctalia msg command such as
-- bar-show) runs before the wait, in the same process, so it cannot land
-- after fn.
local delayGen = 0
local function afterDelay(fn, first)
  delayGen += 1
  local mine = delayGen
  local delayMs = tonumber(noctalia.getSetting(`bar.{BAR}.auto_hide_delay_ms`)) or 600
  local seconds = string.format("%.3f", delayMs / 1000)
  local wait = { "sleep", seconds }
  if first then
    wait = { "sh", "-c", `noctalia msg {first} "$1" && sleep {seconds}`, "sh", BAR }
  end
  noctalia.runAsync(wait, function()
    if mine == delayGen and not switchSession then
      fn()
    end
  end)
end

-- bar-show (and the switcher's reveal) leaves the bar up, since auto-hide
-- only reacts to the pointer leaving it. Toggling auto-hide off and on puts
-- it away without touching the mouse; the bottom edge still reveals it.
local function tuckAway(first)
  afterDelay(function()
    noctalia.runAsync({
      "sh", "-c", 'noctalia msg bar-auto-hide-set off "$1" && noctalia msg bar-auto-hide-set on "$1"', "sh", BAR,
    })
  end, first)
end

local function setBarShown(shown)
  if barShown == shown then
    return
  end
  barShown = shown
  if shown then
    tuckAway("bar-show")
  else
    noctaliaMsg("bar-hide", BAR)
  end
end

local function restore(address)
  -- Addresses come from hyprctl, but keep anything but hex out of the eval.
  if not string.match(address, "^0x%x+$") then
    return
  end
  noctalia.runAsync({ "hyprctl", "eval", `require("minimize").restore("{address}")` })
end

-- Offset 0 is the newest (leftmost) window, positive goes right, wrapping.
local function selectedIndex(offset)
  local count = #windows
  if count == 0 then
    return nil
  end
  return (offset % count) + 1
end

local function clampView()
  viewStart = math.max(1, math.min(viewStart, #windows - VISIBLE + 1))
end

local function slotFor(w, selected)
  local onClick = function()
    restore(w.address)
  end
  local icon
  local path = iconFor(w.class)
  if path then
    icon = ui.image({ path = path, width = ICON_SIZE, height = ICON_SIZE, fit = "contain", tooltip = w.title })
  else
    icon = ui.glyph({ name = "app-window", size = ICON_SIZE - 2, color = "on_surface_variant" })
  end
  return ui.row({
    key = w.address,
    onClick = onClick,
    width = SLOT,
    height = SLOT,
    align = "center",
    justify = "center",
    radius = 8,
    -- nil would leave the previous fill in place; clear it explicitly.
    fill = if selected then "primary/0.35" else "primary/0",
  }, { icon })
end

-- Always present so the pill keeps its size; invisible when there is
-- nothing further that way. A click pages by a full view.
local function chevron(glyph, active, step)
  return ui.row({
    key = glyph,
    width = 14,
    height = SLOT,
    align = "center",
    justify = "center",
    opacity = if active then 1 else 0,
    onClick = function()
      if active then
        viewStart += step
        render()
      end
    end,
  }, { ui.glyph({ name = glyph, size = 12, color = "on_surface_variant" }) })
end

function render()
  local count = #windows
  if count == 0 then
    if barShown then
      -- Restored the last one: keep the empty pill up for the usual delay
      -- instead of vanishing under the pointer, then put the bar away.
      afterDelay(function()
        if #windows == 0 then
          barWidget.setVisible(false)
          setBarShown(false)
        end
      end)
    else
      barWidget.setVisible(false)
      setBarShown(false)
    end
  else
    barWidget.setVisible(true)
    setBarShown(true)
  end

  local selected = if switchSession then selectedIndex(switchOffset) else nil
  if selected then
    if selected < viewStart then
      viewStart = selected
    elseif selected >= viewStart + VISIBLE then
      viewStart = selected - VISIBLE + 1
    end
  end
  clampView()

  local items = { chevron("chevron-left", viewStart > 1, -VISIBLE) }

  -- Fewer than VISIBLE windows: the room of the missing slots (each a SLOT
  -- plus its GAP) goes to two equal spacers, one per side, so the icons stay
  -- centred and the pill keeps its width. Each spacer brings a GAP of its own.
  local missing = math.max(0, VISIBLE - count)
  local spacer = missing * (SLOT + GAP) / 2 - GAP
  local function pad(key)
    if missing > 0 then
      -- ui.box paints black without a fill.
      table.insert(items, ui.box({ key = key, width = spacer, height = SLOT, fill = "primary/0" }))
    end
  end

  pad("pad-left")
  for i = viewStart, math.min(count, viewStart + VISIBLE - 1) do
    table.insert(items, slotFor(windows[i], i == selected))
  end
  pad("pad-right")
  table.insert(items, chevron("chevron-right", viewStart + VISIBLE <= count, VISIBLE))

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = GAP, align = "center" }, items))
end

local function refresh()
  noctalia.runAsync({ "hyprctl", "clients", "-j" }, function(result)
    if result.exitCode ~= 0 then
      return
    end
    local clients = noctalia.json.decode(result.stdout)
    if type(clients) ~= "table" then
      return
    end

    windows = {}
    local seen = {}
    for _, c in ipairs(clients) do
      if c.workspace and c.workspace.name == WORKSPACE then
        if not seq[c.address] then
          nextSeq += 1
          seq[c.address] = nextSeq
        end
        seen[c.address] = true
        table.insert(windows, {
          address = c.address,
          class = c.class or "",
          title = if c.title ~= "" then c.title else c.class,
        })
      end
    end
    for address in pairs(seq) do
      if not seen[address] then
        seq[address] = nil
      end
    end
    -- Newest minimized first, like alt+tab: hyprctl lists by focus history,
    -- which would shuffle the icons on every refresh.
    table.sort(windows, function(a, b)
      return seq[a.address] > seq[b.address]
    end)
    render()
  end)
end

-- Only the first tick matters (initial list after noctalia starts); after
-- that Hyprland pushes "refresh" over IPC.
local started = false
function update()
  noctalia.setUpdateInterval(60000)
  if not started then
    started = true
    refresh()
  end
end

-- Wheel down / right scrolls towards older windows.
function onScroll(_axis, steps)
  if #windows <= VISIBLE then
    return
  end
  viewStart += if steps > 0 then 1 else -1
  render()
end

local function parseSwitch(payload)
  local s, q, o = string.match(payload or "", "^(%d+):(%d+):(%-?%d+)$")
  if not s then
    return nil
  end
  return tonumber(s), tonumber(q), tonumber(o)
end

function onIpc(event, payload)
  if event == "refresh" then
    refresh()
    return
  end

  local session, q, offset = parseSwitch(payload)
  if not session or session <= endedSession then
    return
  end

  if event == "select" then
    if session ~= switchSession then
      switchSession, switchSeq = session, 0
    end
    if q < switchSeq then
      return
    end
    local first = switchSeq == 0
    switchSeq, switchOffset = q, offset
    render()
    -- Reveal the auto-hidden bar while picking.
    if first and #windows > 0 then
      noctaliaMsg("bar-show", BAR)
    end
  elseif event == "commit" or event == "cancel" then
    endedSession = session
    switchSession = nil
    local i = selectedIndex(offset)
    if event == "commit" and i then
      restore(windows[i].address)
    end
    render()
    if #windows > 0 then
      tuckAway()
    end
  end
end

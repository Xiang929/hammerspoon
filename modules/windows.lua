-- window management
local application = require "hs.application"
local hotkey = require "hs.hotkey"
local window = require "hs.window"
local layout = require "hs.layout"
local grid = require "hs.grid"
local hints = require "hs.hints"
local screen = require "hs.screen"
local alert = require "hs.alert"
local fnutils = require "hs.fnutils"
local geometry = require "hs.geometry"
local mouse = require "hs.mouse"

-- default 0.2
window.animationDuration = 0
switcher = hs.window.switcher.new(
   hs.window.filter.new()
      :setCurrentSpace(true):setDefaultFilter{}, -- make emacs window show in switcher list
   {
      showTitles = false,		-- don't show window title
      thumbnailSize = 200,		-- window thumbnail size
      showSelectedThumbnail = false,	-- don't show bigger thumbnail
      backgroundColor = {0, 0, 0, 0.8}, -- background color
      highlightColor = {0.3, 0.3, 0.3, 0.8}, -- selected color
   }
)


-- left half
hotkey.bind(hyper, "H", function()
    if window.focusedWindow() then
        window.focusedWindow():moveToUnit(layout.left50)
    else
        alert.show("No active window")
    end
end)

-- right half
hotkey.bind(hyper, "L", function()
    window.focusedWindow():moveToUnit(layout.right50)
end)

-- top half
hotkey.bind(hyper, "K", function()
    window.focusedWindow():moveToUnit '[0,0,100,50]'
end)

-- bottom half
hotkey.bind(hyper, "J", function()
    window.focusedWindow():moveToUnit '[0,50,100,100]'
end)

-- left top quarter
hotkey.bind(hyperAlt, "H", function()
    local win = window.focusedWindow()
	local axApp = hs.axuielement.applicationElement(win:application())
	local wasEnhanced = axApp.AXEnhancedUserInterface
	if wasEnhanced then
	    axApp.AXEnhancedUserInterface = false
	end
    win:moveToUnit '[0,0,50,50]'
	if wasEnhanced then
	    axApp.AXEnhancedUserInterface = true
	end
end)

-- right bottom quarter
hotkey.bind(hyperAlt, "L", function()

    window.focusedWindow():moveToUnit '[50,50,100,100]'
end)

-- right top quarter
hotkey.bind(hyperAlt, "K", function()
    window.focusedWindow():moveToUnit '[50,0,100,50]'
end)

-- left bottom quarter
hotkey.bind(hyperAlt, "J", function()
    window.focusedWindow():moveToUnit '[0,50,50,100]'
end)

-- full screen
hotkey.bind(hyper, 'F', function()
    window.focusedWindow():toggleFullScreen()
end)

-- center window
hotkey.bind(hyper, 'C', function()
    window.focusedWindow():centerOnScreen()
end)

-- maximize window
hotkey.bind(hyper, 'M', function()
    toggle_maximize()
end)

-- defines for window maximize toggler
local frameCache = {}
-- toggle a window between its normal size, and being maximized
function toggle_maximize()
    local win = window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
		local axApp = hs.axuielement.applicationElement(win:application())
		local wasEnhanced = axApp.AXEnhancedUserInterface
		if wasEnhanced then
		    axApp.AXEnhancedUserInterface = false
		end
		win:setFrame(win:screen():fullFrame()) -- or win:moveToScreen(someScreen), etc.
		if wasEnhanced then
		    axApp.AXEnhancedUserInterface = true
		end
    end
end

-- move active window to previous monitor
hotkey.bind(hyperShift, "H", function()
    window.focusedWindow():moveOneScreenWest()
end)

-- move active window to next monitor
hotkey.bind(hyperShift, "L", function()
    window.focusedWindow():moveOneScreenEast()
end)

-- move cursor to previous monitor
hotkey.bind(hyperCtrl, "H", function()
    focusScreen(window.focusedWindow():screen():previous())
end)

-- move cursor to next monitor
hotkey.bind(hyperCtrl, "L", function()
    focusScreen(window.focusedWindow():screen():next())
end)

-- Predicate that checks if a window belongs to a screen
function isInScreen(screen, win)
    return win:screen() == screen and win:title() ~= "Window"
end

function focusScreen(screen)
    -- Get windows within screen, ordered from front to back.
    -- If no windows exist, bring focus to desktop. Otherwise, set focus on
    -- front-most application window.
    local windows = fnutils.filter(window.orderedWindows(), fnutils.partial(isInScreen, screen))
    local windowToFocus = #windows > 0 and windows[1] or window.desktop()
    windowToFocus:focus()

    -- move cursor to center of screen
    local pt = geometry.rectMidPoint(screen:fullFrame())
    mouse.setAbsolutePosition(pt)

end

-- maximized active window and move to selected monitor
moveto = function(win, n)
    local screens = screen.allScreens()
    if n > #screens then
        alert.show("Only " .. #screens .. " monitors ")
    else
        local toWin = screen.allScreens()[n]:name()
        alert.show("Move " .. win:application():name() .. " to " .. toWin)

        layout.apply({{nil, win:title(), toWin, layout.maximized, nil, nil}})

    end
end

-- move cursor to monitor 1 and maximize the window
hotkey.bind(hyperShift, "1", function()
    local win = window.focusedWindow()
    moveto(win, 1)
end)

hotkey.bind(hyperShift, "2", function()
    local win = window.focusedWindow()
    moveto(win, 2)
end)

hotkey.bind(hyperShift, "3", function()
    local win = window.focusedWindow()
    moveto(win, 3)
end)

hs.hotkey.bind(hyperShift, "K", function()
    local app = hs.application.frontmostApplication() -- 	local windows = app:allWindows()
    local windows = app:allWindows()

    local nextWin = nil

    -- Finder somehow has one more invisible window, so don't take it into account
    -- (only tested on Yosemite 10.10.1)
    if app:bundleID() == "com.apple.finder" then
        nextWin = windows[#windows - 1]
    else
        nextWin = windows[#windows]
    end

    if nextWin:isMinimized() == true then
        nextWin:unminimize()
    else
        nextWin:focus()
    end
end)

hs.hotkey.bind(hyperShift, "J", function()
    local app = hs.application.frontmostApplication()
    local windows = app:allWindows()

    local previousWin = nil

    -- Finder somehow has one more invisible window, so don't take it into account
    -- (only tested on Yosemite 10.10.1)
    if app:bundleID() == "com.apple.finder" then
        previousWin = windows[#windows - 1]
    else
        previousWin = windows[#windows - 1]
    end

    if previousWin:isMinimized() == true then
        previousWin:unminimize()
    else
        previousWin:focus()
    end
end)

_fuzzyChoices = nil
_fuzzyChooser = nil
_fuzzyLastWindow = nil

function fuzzyQuery(s, m)
    s_index = 1
    m_index = 1
    match_start = nil
    while true do
        if s_index > s:len() or m_index > m:len() then
            return -1
        end
        s_char = s:sub(s_index, s_index)
        m_char = m:sub(m_index, m_index)
        if s_char == m_char then
            if match_start == nil then
                match_start = s_index
            end
            s_index = s_index + 1
            m_index = m_index + 1
            if m_index > m:len() then
                match_end = s_index
                s_match_length = match_end - match_start
                score = m:len() / s_match_length
                return score
            end
        else
            s_index = s_index + 1
        end
    end
end

function _fuzzyFilterChoices(query)
    if query:len() == 0 then
        _fuzzyChooser:choices(_fuzzyChoices)
        return
    end
    pickedChoices = {}
    for i, j in pairs(_fuzzyChoices) do
        fullText = (j["text"] .. " " .. j["subText"]):lower()
        score = fuzzyQuery(fullText, query:lower())
        if score > 0 then
            j["fzf_score"] = score
            table.insert(pickedChoices, j)
        end
    end
    local sort_func = function(a, b)
        return a["fzf_score"] > b["fzf_score"]
    end
    table.sort(pickedChoices, sort_func)
    _fuzzyChooser:choices(pickedChoices)
end

function _fuzzyPickWindow(item)
    if item == nil then
        if _fuzzyLastWindow then
            -- Workaround so last focused window stays focused after dismissing
            _fuzzyLastWindow:focus()
            _fuzzyLastWindow = nil
        end
        return
    end
    id = item["windowID"]
    window = hs.window.get(id)
    window:focus()
end

function windowFuzzySearch()
    windows = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)
    -- windows = hs.window.orderedWindows()
    _fuzzyChoices = {}
    for i, w in pairs(windows) do
        title = w:title()
        app = w:application():name()
        item = {
            ["text"] = app,
            ["subText"] = title,
            -- ["image"] = w:snapshot(),
            ["windowID"] = w:id()
        }
        -- Handle special cases as necessary
        -- if app == "Safari" and title == "" then
        -- skip, it's a weird empty window that shows up sometimes for some reason
        -- else
        table.insert(_fuzzyChoices, item)
        -- end
    end
    _fuzzyLastWindow = hs.window.focusedWindow()
    _fuzzyChooser = hs.chooser.new(_fuzzyPickWindow):choices(_fuzzyChoices):searchSubText(true)
    _fuzzyChooser:queryChangedCallback(_fuzzyFilterChoices) -- Enable true fuzzy find
    _fuzzyChooser:show()
end

-- fuzzy search
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "J", function()
    windowFuzzySearch()
end)

function doubleLeftClick(point)
    local clickState = hs.eventtap.event.properties.mouseEventClickState
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):post()
    hs.timer.usleep(1000)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):post()
end

-- double click
hotkey.bind(hyperShift, "F", function()
    doubleLeftClick(hs.mouse.absolutePosition())
end)

-- kill window
hotkey.bind(hyperCtrl, "K", function()
    window.focusedWindow():application():kill()
end)

function brightness0()
    screens = hs.screen.allScreens()
    for i,s in pairs(screens) do
        print(s:name())
        s:setBrightness(0)
    end
end

function brightness60()
    screens = hs.screen.allScreens()
    for i,s in pairs(screens) do
        s:setBrightness(0.6)
    end
end

function brightnesstest()
end

hotkey.bind(hyper, ";", function()
    brightness0()
end)

hotkey.bind(hyper, "'", function()
    brightness60()
end)

hotkey.bind(hyper, "0", function()
    local windows = fnutils.filter(window.orderedWindows(), fnutils.partial(isInScreen, window.focusedWindow():screen()))
    for i, w in pairs(windows) do
        print(windows[i]:title())
        print(windows[i]:id())
        print(windows[i]:size())
        print(windows[i]:role())
    end
end)

AutoReload = {
    watcher = nil
};

function AutoReload:reloadConfig(files)
    print("reload")
    local doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end

    if doReload then
        hs.reload()
    end
end

function AutoReload:init()
  self.watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(paths)
        AutoReload:reloadConfig(paths)
    end):start()
  hs.alert.show("Hammerspoon Config Reloaded")
end

return AutoReload

local cloneref = (cloneref or clonereference or function(instance) return instance end)

local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))

local SaveManager = {
    Folder = nil,
    Path = nil,
    Settings = {},
    Initialized = false,
}

local function canUseFiles()
    return not RunService:IsStudio()
        and type(isfile) == "function"
        and type(readfile) == "function"
        and type(writefile) == "function"
end

function SaveManager:Init(options)
    options = options or {}
    local folder = options.Folder or (options.Window and options.Window.Folder) or "WindUI"
    local file = options.File or options.Filename or "settings.json"

    self.Folder = tostring(folder)
    self.Path = options.Path or ("WindUI/" .. self.Folder .. "/" .. tostring(file))
    self.Settings = {}
    self.Initialized = true

    local directory = self.Path:match("^(.*)[/\\][^/\\]+$")
    if directory and type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(directory) then
        pcall(makefolder, directory)
    end

    self:Load()
    return self
end

function SaveManager:Load()
    if not self.Initialized or not canUseFiles() or not isfile(self.Path) then
        return false, "SaveManager is unavailable or the settings file does not exist"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(self.Path))
    end)
    if ok and type(data) == "table" then
        self.Settings = data
        return true, data
    end
    return false, "Failed to parse settings file"
end

function SaveManager:Save()
    if not self.Initialized or not canUseFiles() then
        return false, "SaveManager is unavailable in this environment"
    end

    local ok, json = pcall(function() return HttpService:JSONEncode(self.Settings) end)
    if not ok then return false, "Failed to encode settings" end

    local written, err = pcall(writefile, self.Path, json)
    if written then return true end
    return false, tostring(err)
end

function SaveManager:SaveValue(key, value)
    if type(key) ~= "string" or key == "" then
        return false, "A non-empty string key is required"
    end
    self.Settings[key] = value
    return self:Save()
end

function SaveManager:LoadValue(key, default)
    if self.Settings[key] ~= nil then return self.Settings[key] end
    return default
end

function SaveManager:HasValue(key)
    return self.Settings[key] ~= nil
end

function SaveManager:RemoveValue(key)
    self.Settings[key] = nil
    return self:Save()
end

function SaveManager:Clear()
    self.Settings = {}
    return self:Save()
end

function SaveManager:GetAll()
    return self.Settings
end

return SaveManager

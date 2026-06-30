-- Anetia's decompiler.
-- If you see this, Congrats! You found our decompiler :)
-- With love, lucef
assert(getscriptbytecode, "exploit does not support getscriptbytecode.")
local httpservice = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local function base64_encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,byte = '',x:byte()
        for i=8,1,-1 do
            r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and '1' or '0')
        end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i=1,6 do
            c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
        end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data % 3 + 1])
end
getgenv().decompile = function(script)
    scriptName  "Unknown script"
    local ok, bytecode = pcall(getscriptbytecode, script)
    if not ok then
        return "-- Failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
    end
    if not bytecode or #bytecode == 0 then
        return "-- Empty bytecode\n--[[\nScript: " .. scriptName .. "\n--]]"
    end
    local encoder = base64_encode
    if base64 and base64.encode then
        encoder = base64.encode
    elseif _G.base64_encode then
        encoder = _G.base64_encode
    end
    
    local encoded = encoder(bytecode)
    if not encoded or #encoded == 0 then
        return "-- Failed to encode bytecode"
    end
    
    local response = request({
        Url = "http://127.0.0.1:3000/decompile",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "text/plain",
            ["X-Script-Name"] = scriptName
        },
        Body = encoded
    })
    
    if not response then
        return "-- No response from decompiler server\n"
    end
    
    if response.StatusCode ~= 200 then
        return "-- Decompiler error (HTTP " .. response.StatusCode .. ")\n--[[\n" .. (response.Body or "Unknown error") .. "\n--]]"
    end
    
    local decompiled = response.Body
    local header = "-- Decompiled by Anetia\n"
    local firstLineEnd = decompiled:find("\n")
    if firstLineEnd then
        local rest = decompiled:sub(firstLineEnd + 1)
        return header .. rest
    end
    
    return header .. decompiled
end
getgenv().decompile_print = function(script, scriptName)
    local result = getgenv().decompile(script, scriptName)
    print(result)
    return result
end
getgenv().decompile_save = function(script, filename)
    filename = filename or (script.Name or "decompiled") .. ".lua"
    local result = getgenv().decompile(script, script.Name)
    
    if writefile then
        writefile(filename, result)
        print("Saved decompiled script to: " .. filename)
    else
        print("writefile not available. Use decompile_print() instead.")
        print(result)
    end
    
    return result
end
getgenv().decompile_folder = function(folder, outputFolder)
    outputFolder = outputFolder or "decompiled"
    
    if not folder or not folder:IsA("Folder") then
        error("Expected a Folder instance", 2)
    end
    
    if isfolder and not isfolder(outputFolder) and makefolder then
        makefolder(outputFolder)
    end
    
    local count = 0
    local failed = 0
    
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") or child:IsA("LocalScript") then
            local filename = outputFolder .. "/" .. child.Name .. ".lua"
            local result = getgenv().decompile(child)
            
            if writefile then
                writefile(filename, result)
                print("✓ Decompiled: " .. child.Name)
                count = count + 1
            else
                print("✗ Failed to save: " .. child.Name)
                failed = failed + 1
            end
        end
    end
    
  --  print(string.format("\nDecompiled %d scripts (%d failed)", count, failed))
end

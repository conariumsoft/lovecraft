--- Importer system, adds _G.using to global namespace.
-- @copyright Conarium Software


--[[
    NOTE: this script needs to simply be required once (1x) by the main control script of the platform.
--]]


local engine_root = game.ReplicatedStorage.Lovecraft

----------------------------------------------------------------

local module_database = {
    ["Lovecraft.VRHand"] = {
        identifier = "VRHand",
        reference = engine_root.VRHand,
    },
    ["Lovecraft.Networking"] = {
        identifier = "Networking",
        reference = engine_root.Networking,
    },
    ["Lovecraft.CollisionMasking"] = {
        identifier = "CollisionMasking",
        reference = engine_root.CollisionMasking
    },
    ["Lovecraft.VRHead"] = {
        identifier = "VRHead",
        reference = engine_root.VRHead,
    },
    ["Lovecraft.BaseClass"] = {
        identifier = "BaseClass",
        reference = engine_root.BaseClass,
    },
    ["Lovecraft.SoftWeld"] = {
        identifier = "SoftWeld",
        reference = engine_root.SoftWeld,
    },
    ["Lovecraft.Lib.RotatedRegion3"] = {
        identifier = "RotatedRegion3",
        reference = engine_root.Lib.RotatedRegion3,
    },
    ["Game.Data.ItemMetadata"] = {
        identifier = "ItemMetadata",
        reference = game.ReplicatedStorage.ItemMetadata,
    },

}

local function confirm(eval, message)
    if not eval then
        error("LovecraftVR: "..message, 2)
    end
end


----------------------------------------------------------------


--- UNIX-style module init. Allows imporation of modules and ROBLOX services.
-- Intended to reduce ugly overhead of requiring modules, as well as having to keep track of module file paths.
-- @name _G.using
-- @class function
-- @param md_signature string - module or service to import
-- @param recache bool - should a new copy of the module be imported (ROBLOX module cache)
-- @usage _G.using "RBX.RunService" -- adds RunService to environment without need for local variable
_G.using = function(md_signature, recache)
    
    -- Errare humanum est.
    confirm(md_signature, "modulename cannot be nil")
    confirm(type(md_signature) == "string", "modulesignature must be type string")

    local md_instance
    
    if (md_signature:sub(1, 3) == "RBX") then -- is a service
        md_instance = game:GetService(md_signature:sub(5))

        local caller_env = getfenv(2)
        caller_env[md_signature:sub(5)] = md_instance
        setfenv(2, caller_env)

        return
    end -- otherwise, it's a module.

    local md_metadata = module_database[md_signature]

    confirm(md_metadata,   "Import database nonexistent for "..md_signature)

    local md_identifier = md_metadata.identifier
    local md_reference = md_metadata.reference

    confirm(md_identifier, "Import database missing identifier for "..md_signature)
    confirm(md_reference,  "Import database missing moduleref for "..md_signature)
    
    if (md_reference:IsA("ModuleScript")) then
        if recache then -- do we need to discard old cache?
            md_instance = require(md_reference:Clone())
        else
            md_instance = require(md_reference)
        end
    else
        confirm(false, "Module reference linked to non-modulescript object! Cannot import "..md_signature) 
    end
    confirm(md_instance, "Could not find source file for "..md_signature.." , ModuleScript most likely does not exist in the datamodel!")

    local caller_env = getfenv(2)
    caller_env[md_identifier] = md_instance
    setfenv(2, caller_env)
    return
end

local Importer = {}

return Importer

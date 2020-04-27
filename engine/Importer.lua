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
    ["Game.Data.InteractiveObjectMetadata"] = {
        identifier = "InteractiveObjectMetadata",
        reference = game.ReplicatedFirst.HandAnimations,
    },
    ["Game.Data.HandAnimations"] = {
        identifier = "HandAnimations",
        reference = game.ReplicatedStorage.HandAnimations
    },
}

----------------------------------------------------------------
_G.using = function(md_signature, recache)
    
    assert(md_signature, "")
    assert(type(md_signature) == "string", "")

    local md_instance

    if (md_signature:sub(1, 3) == "RBX") then -- is a service
        md_instance = game:GetService(md_signature:sub(5))


        local caller_env = getfenv(2)
        caller_env[md_signature:sub(5)] = md_instance
        setfenv(2, caller_env)

        return
    end -- otherwise, it's a module.

    local md_metadata = module_database[md_signature]
    local md_identifier = md_metadata.identifier
    local md_reference = md_metadata.reference

    assert(md_identifier, "")
    assert(md_reference, "")
    assert(md_metadata, "")
    
    if (md_reference:IsA("ModuleScript")) then
        if recache then -- do we need to discard old cache?
            md_instance = require(md_reference:Clone())
        else
            md_instance = require(md_reference)
        end
    else
        error("") -- shouldn't be anything else, eh?
    end

    local caller_env = getfenv(2)
    caller_env[md_identifier.identifier] = md_instance
    setfenv(2, caller_env)
    return
end

local Importer = {}



return Importer

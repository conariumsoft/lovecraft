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
    ["Lovecraft.BaseClass"] = {
        identifier = "BaseClass",
        reference = engine_root.BaseClass,
    },
    ["Namespace.Namespace.Class"] = {
        identifier = "LocalVariableName",
        reference  = game.ReplicatedStorage.SomeModule,
    },
    ["RBX.RunService"] = {
        identifier = "RunService",
    },
    ["RBX.VRService"] = {

    },
    ["RBX.ReplicatedStorage"] = {

    },
}

----------------------------------------------------------------

--[[ examples:
using "Lovecraft.VRHand"
 <is equivalent to>
local VRHand = require(blah.blah.blah.VRHand)

--

using "RBX.RunService" -- is equivalent to
 <is equivalent to>
local RunService = game:GetService("RunService")

]]

_G.using = function(md_signature, recache)
    
    assert(md_signature, "")
    assert(type(md_signature) == "string", "")

    local md_metadata = module_database[md_signature]

    assert(md_metadata, "")

    local caller_env = getfenv(2)

    local md_identifier = md_metadata.identifier
    local md_reference = md_metadata.reference
    local md_instance

    if (md_reference:IsA("ModuleScript")) then
        if recache then -- do we need to discard old cache?
            md_instance = require(md_reference:Clone())
        else
            md_instance = require(md_reference)
        end
    else -- assume attempting to import a service?
        md_instance = game:GetService(md_metadata.identifier)
    end


    --return md_instance

    

    caller_env[md_metadata.identifier] = md_instance
    setfenv(2, caller_env)
end

local Importer = {}



return Importer

--[[
    For class modules:
        -- classes provide interface.
        local myClass = ClassModule:subclass()

        function myClass:__ctor()

        end

        function myClass:PerformOperations(...)

        end

        return myClass


    For singleton modules:
        local myModule = StaticModule:create()

        function myModule.PerformOperations(...)

        end

        return myModule
]]

local LCModule = BaseClass:subclass()


local function Using(module_signature, force_new)
    
end

_G.using = Using



local Lovecraft = {}




return Lovecraft
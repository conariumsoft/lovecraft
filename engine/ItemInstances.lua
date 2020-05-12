_G.using "Game.Data.ItemMetadata"

local items = {

}

local Module = {}

function Module.GetClassInstance(model_to_find)
    for model, data in pairs(items) do
        if model == model_to_find then
            return data
        end
    end

    --return Module.CreateClassInstance(model, )
end

function Module.CreateClassInstance(model, class)
    if Module.GetClassInstance(model) then
        error("Already exists retard!")
    end
    items[model] = class:new(model)
    return items[model]
end

return Module
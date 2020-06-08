local item_db = {}

local Module = {}

function Module.GetClassInstance(model_to_find)
    for model, data in pairs(item_db) do
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
    item_db[model] = class:new(model)
    return item_db[model]
end

return Module
local Module = {}

local items = {}

function Module.GenerateEntry(instance)
    items[instance] = {
        owner = nil,
        Left = false,
        Right = false
    }
end

function Module.HasEntry(instance)
    return (items[instance] ~= nil)
end

function Module.GetEntry(instance, generate_if_nonexistant)

    if generate_if_nonexistant then
        if items[instance] == nil then
            Module.GenerateEntry(instance)
        end
        return items[instance]
    end

    return items[instance]
end

function Module.SetEntryOwner(model, player)
    local entry = Module.GetEntry(model, true)

    entry.owner = player
end

function Module.SetEntryState(model, hand, value)
    local entry = Module.GetEntry(model, false)
    entry[hand] = value
end

function Module.ReportData()
    print("itemrefs:")
    for index, value in pairs(items) do
        print(string.format("modl: %s, owner: %s, l: %s, r:%s", index.Name, value.owner, tostring(value.left), tostring(value.right)))
    end
end

return Module
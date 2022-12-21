local VORPcore = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Buy New Boats
RegisterServerEvent('oss_boats:BuyBoat')
AddEventHandler('oss_boats:BuyBoat', function(buyData, location)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    local name = buyData.boatName
    local model = buyData.boatModel
    local currencyType = buyData.currencyType
    local buyPrice = buyData.buyPrice

    if currencyType == "cash" then
        local money = Character.money
        if money >= buyPrice then
            Character.removeCurrency(0, buyPrice)
            VORPcore.NotifyRightTip(_source, _U("bought") .. name .. _U("frcash") .. buyPrice, 4000)

            local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model }
            exports.ghmattimysql:execute("INSERT INTO boats ( `identifier`, `charid`, `location`, `name`, `model` ) VALUES ( @identifier, @charid, @location, @name, @model )", Parameters)
        else
            VORPcore.NotifyRightTip(_source, _U("shortCash"), 4000)
        end

    elseif currencyType == "gold" then
        local gold = Character.gold
        if gold >= buyPrice then
            Character.removeCurrency(1, buyPrice)
            VORPcore.NotifyRightTip(_source, _U("bought") .. name .. _U("fr") .. buyPrice .. _U("ofgold"), 4000)

            local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model }
            exports.ghmattimysql:execute("INSERT INTO boats ( `identifier`, `charid`, `location`, `name`, `model` ) VALUES ( @identifier, @charid, @location, @name, @model )", Parameters)
        else
            VORPcore.NotifyRightTip(_source, _U("shortGold"), 4000)
        end
    end
end)

-- Get List of Owned Boats
RegisterServerEvent('oss_boats:GetOwnedBoats')
AddEventHandler('oss_boats:GetOwnedBoats', function(location, shopId)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local identifier = Character.identifier
    local charid = Character.charIdentifier

    exports["ghmattimysql"]:execute("SELECT name, model, location FROM boats WHERE identifier = @identifier AND charid = @charid AND location = @location",
    { ["@identifier"] = identifier, ["@charid"] = charid, ["@location"] = location }, function(result)

        if result[1] then
            TriggerClientEvent("oss_boats:OwnedBoatsMenu", _source, result, shopId)
        else
            VORPcore.NotifyRightTip(_source, _U("noBoats"), 4000)
        end
    end)
end)

-- Sell Owned Boats
RegisterServerEvent('oss_boats:SellBoat')
AddEventHandler('oss_boats:SellBoat', function(ownedData, boatData)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    local name = ownedData.name
    local model = ownedData.model
    local location = ownedData.location
    local sellPrice = boatData.sellPrice
    local currencyType = boatData.currencyType

    if currencyType == "cash" then
        Character.addCurrency(0, sellPrice)
        VORPcore.NotifyRightTip(_source, _U("sold") .. name .. _U("frcash") .. sellPrice, 4000)

        local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model }
        exports.ghmattimysql:execute("DELETE FROM boats WHERE identifier = @identifier AND charid = @charid AND location = @location AND name = @name AND model = @model LIMIT 1", Parameters)

    elseif currencyType == "gold" then
        Character.addCurrency(1, sellPrice)
        VORPcore.NotifyRightTip(_source, _U("sold") .. name .. _U("fr") .. sellPrice .. _U("ofgold"), 4000)

        local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model }
        exports.ghmattimysql:execute("DELETE FROM boats WHERE identifier = @identifier AND charid = @charid AND location = @location AND name = @name AND model = @model LIMIT 1", Parameters)
    end
end)

-- Transfer Owned Boats Between Shops
RegisterServerEvent('oss_boats:TransferBoat')
AddEventHandler('oss_boats:TransferBoat', function(ownedData, transferLocation, transferMode, boatData, shopName)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local identifier = Character.identifier
    local charid = Character.charIdentifier
    local name = ownedData.name
    local model = ownedData.model
    local location = ownedData.location
    if transferMode == "menuTransfer" then
        local currencyType = boatData.currencyType
        local transferPrice = boatData.transferPrice
        if currencyType == "cash" then
            local money = Character.money
            if money >= transferPrice then
                Character.removeCurrency(0, transferPrice)
                VORPcore.NotifyRightTip(_source, _U("transferred") .. name .. _U("to") .. shopName .. _U("frcash") .. transferPrice, 4000)

                local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model, ['transferLocation'] = transferLocation }
                exports.ghmattimysql:execute("UPDATE boats SET location = @transferLocation WHERE identifier = @identifier AND charid = @charid AND location = @location AND name = @name AND model = @model LIMIT 1", Parameters)
            else
                VORPcore.NotifyRightTip(_source, _U("shortCash"), 4000)
            end

        elseif currencyType == "gold" then
            local gold = Character.gold
            if gold >= transferPrice then
                Character.removeCurrency(1, transferPrice)
                VORPcore.NotifyRightTip(_source, _U("transferred") .. name .. _U("to") .. shopName .. _U("fr") .. transferPrice .. _U("ofgold"), 4000)

                local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model, ['transferLocation'] = transferLocation }
                exports.ghmattimysql:execute("UPDATE boats SET location = @transferLocation WHERE identifier = @identifier AND charid = @charid AND location = @location AND name = @name AND model = @model LIMIT 1", Parameters)
            else
                VORPcore.NotifyRightTip(_source, _U("shortGold"), 4000)
            end
        end

    elseif transferMode == "driveTransfer" then
        local Parameters = { ['identifier'] = identifier, ['charid'] = charid, ['location'] = location, ['name'] = name, ['model'] = model, ['transferLocation'] = transferLocation }
        exports.ghmattimysql:execute("UPDATE boats SET location = @transferLocation WHERE identifier = @identifier AND charid = @charid AND location = @location AND name = @name AND model = @model LIMIT 1", Parameters)
    end
end)

-- Prevent NPC Boat Spawns
if Config.blockNpcBoats then
    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) == 2 then
            if GetVehicleType(entity) == "boat" then
                if GetEntityPopulationType(entity) ~= 7 and GetEntityPopulationType(entity) ~= 8 then
                    CancelEvent()
                end
            end
        end
    end)
end

-- Check Player Job and Job Grade
RegisterServerEvent('oss_boats:getPlayerJob')
AddEventHandler('oss_boats:getPlayerJob', function()
    local _source = source
    if _source then
        local Character = VORPcore.getUser(_source).getUsedCharacter
        local CharacterJob = Character.job
        local CharacterGrade = Character.jobGrade

        TriggerClientEvent('oss_boats:sendPlayerJob', _source, CharacterJob, CharacterGrade)
    end
end)

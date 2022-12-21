local VORPcore = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Prompts (start)
local OpenShops
local CloseShops
local OpenReturn
local CloseReturn
local ShopPrompt1 = GetRandomIntInRange(0, 0xffffff)
local ShopPrompt2 = GetRandomIntInRange(0, 0xffffff)
local ReturnPrompt1 = GetRandomIntInRange(0, 0xffffff)
local ReturnPrompt2 = GetRandomIntInRange(0, 0xffffff)
--Prompts (end)

local PlayerJob
local JobName
local JobGrade
local InMenu = false
local IsBoating = false
local MyBoat
local BoatHome
local BoatName
local BoatModel
local TransferAllow
MenuData = {}

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

-- Start Boats
Citizen.CreateThread(function()
    ShopOpen()
    ShopClosed()
    ReturnOpen()
    ReturnClosed()

    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true
        local dead = IsEntityDead(player)
        local hour = GetClockHours()

        if InMenu == false and not dead then
            for shopId, shopConfig in pairs(Config.boatShops) do
                if shopConfig.shopHours then
                    if hour >= shopConfig.shopClose or hour < shopConfig.shopOpen then
                        if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                            AddBlip(shopId)
                        end
                        if Config.boatShops[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, GetHashKey(shopConfig.blipColorClosed)) -- BlipAddModifier
                        end
                        if shopConfig.NPC then
                            DeleteEntity(shopConfig.NPC)
                            DeletePed(shopConfig.NPC)
                            SetEntityAsNoLongerNeeded(shopConfig.NPC)
                            shopConfig.NPC = nil
                        end
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local coordsBoat = vector3(shopConfig.boatx, shopConfig.boaty, shopConfig.boatz)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopClosed = CreateVarString(10, 'LITERAL_STRING', _U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"))
                            PromptSetActiveGroupThisFrame(ShopPrompt2, shopClosed)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, CloseShops) then -- UiPromptHasStandardModeCompleted

                                Wait(100)
                                VORPcore.NotifyRightTip(_U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"), 3000)
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnClosed = CreateVarString(10, 'LITERAL_STRING', _U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"))
                            PromptSetActiveGroupThisFrame(ReturnPrompt2, returnClosed)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, CloseReturn) then -- UiPromptHasStandardModeCompleted

                                Wait(100)
                                VORPcore.NotifyRightTip(_U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"), 3000)
                            end
                        end
                    elseif hour >= shopConfig.shopOpen then
                        if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                            AddBlip(shopId)
                        end
                        if Config.boatShops[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, GetHashKey(shopConfig.blipColorOpen)) -- BlipAddModifier
                        end
                        if not shopConfig.NPC and shopConfig.npcAllowed then
                            SpawnNPC(shopId)
                        end
                        if not next(shopConfig.allowedJobs) then
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                            local coordsBoat = vector3(shopConfig.boatx, shopConfig.boaty, shopConfig.boatz)
                            local distanceShop = #(coordsDist - coordsShop)
                            local distanceBoat = #(coordsDist - coordsBoat)

                            if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                    MainMenu(shopId)
                                    DisplayRadar(false)
                                    TaskStandStill(player, -1)
                                end
                            elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                                sleep = false
                                local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                    local currentLocation = shopConfig.location
                                    if currentLocation == BoatHome then
                                        ReturnBoat(shopId)
                                    else
                                        if TransferAllow then
                                            local driveTransfer = "driveTransfer"
                                            TriggerServerEvent("oss_boats:TransferBoat", BoatName, BoatModel, BoatHome, currentLocation, driveTransfer)
                                            ReturnBoat(shopId)
                                            VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("available"),5000)
                                        else
                                            ReturnBoat(shopId)
                                            VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("returned") .. BoatHome,5000)
                                        end
                                    end
                                end
                            end
                        else
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                            local coordsBoat = vector3(shopConfig.boatx, shopConfig.boaty, shopConfig.boatz)
                            local distanceShop = #(coordsDist - coordsShop)
                            local distanceBoat = #(coordsDist - coordsBoat)

                            if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                    TriggerServerEvent("oss_boats:getPlayerJob")
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                MainMenu(shopId)
                                                DisplayRadar(false)
                                                TaskStandStill(player, -1)
                                            else
                                                VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                end
                            elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                                sleep = false
                                local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                    TriggerServerEvent("oss_boats:getPlayerJob")
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                local currentLocation = shopConfig.location
                                                if currentLocation == BoatHome then
                                                    ReturnBoat(shopId)
                                                else
                                                    if TransferAllow then
                                                        local driveTransfer = "driveTransfer"
                                                        TriggerServerEvent("oss_boats:TransferBoat", BoatName, BoatModel, BoatHome, currentLocation, driveTransfer)
                                                        ReturnBoat(shopId)
                                                        VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("available"),5000)
                                                    else
                                                        ReturnBoat(shopId)
                                                        VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("returned") .. BoatHome,5000)
                                                    end
                                                end
                                            else
                                                VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                end
                            end
                        end
                    end
                else
                    if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                        AddBlip(shopId)
                    end
                    if Config.boatShops[shopId].BlipHandle then
                        Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, GetHashKey(shopConfig.blipColorOpen)) -- BlipAddModifier
                    end
                    if not shopConfig.NPC and shopConfig.npcAllowed then
                        SpawnNPC(shopId)
                    end
                    if not next(shopConfig.allowedJobs) then
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local coordsBoat = vector3(shopConfig.boatx, shopConfig.boaty, shopConfig.boatz)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                MainMenu(shopId)
                                DisplayRadar(false)
                                TaskStandStill(player, -1)
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                local currentLocation = shopConfig.location
                                if currentLocation == BoatHome then
                                    ReturnBoat(shopId)
                                else
                                    if TransferAllow then
                                        local driveTransfer = "driveTransfer"
                                        TriggerServerEvent("oss_boats:TransferBoat", BoatName, BoatModel, BoatHome, currentLocation, driveTransfer)
                                        ReturnBoat(shopId)
                                        VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("available"),5000)
                                    else
                                        ReturnBoat(shopId)
                                        VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("returned") .. BoatHome,5000)
                                    end
                                end
                            end
                        end
                    else
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local coordsBoat = vector3(shopConfig.boatx, shopConfig.boaty, shopConfig.boatz)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                TriggerServerEvent("oss_boats:getPlayerJob")
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            MainMenu(shopId)
                                            DisplayRadar(false)
                                            TaskStandStill(player, -1)
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                end
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted
                                TriggerServerEvent("oss_boats:getPlayerJob")
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            local currentLocation = shopConfig.location
                                            if currentLocation == BoatHome then
                                                ReturnBoat(shopId)
                                            else
                                                if TransferAllow then
                                                    local driveTransfer = "driveTransfer"
                                                    TriggerServerEvent("oss_boats:TransferBoat", BoatName, BoatModel, BoatHome, currentLocation, driveTransfer)
                                                    ReturnBoat(shopId)
                                                    VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("available"),5000)
                                                else
                                                    ReturnBoat(shopId)
                                                    VORPcore.NotifyRightTip(_U("your") .. BoatName .. _U("returned") .. BoatHome,5000)
                                                end
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                end
                            end
                        end
                    end
                end
            end
        end
        if sleep then
            Citizen.Wait(1000)
        end
    end
end)

-- Main Boats Menu
function MainMenu(shopId)
    MenuData.CloseAll()
    InMenu = true
    local elements = {
        {
            label = _U("buyBoat"),
            value = "buy",
            desc = _U("newBoat")
        },
        {
            label = _U("own"),
            value = "own",
            desc = _U("owned")
        }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title = Config.boatShops[shopId].shopName,
        subtext = _U("mainMenu"),
        align = "top-left",
        elements = elements,
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger]()
        end
        if data.current.value == "buy" then
            BuyMenu(shopId)
        end
        if data.current.value == "own" then
            local location = Config.boatShops[shopId].location
            TriggerServerEvent('oss_boats:GetOwnedBoats', location, shopId)
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(PlayerPedId())
        DisplayRadar(true)
    end)
end

-- Buy Boats Menu
function BuyMenu(shopId)
    MenuData.CloseAll()
    InMenu = true
    local elements = {}

    for boat, boatConfig in pairs(Config.boatShops[shopId].boats) do
        elements[#elements + 1] = {
            label = boatConfig.boatName,
            value = boat,
            desc = _U("price") .. boatConfig.buyPrice .. " " .. boatConfig.currencyType,
            info = boatConfig,
        }
    end
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title = Config.boatShops[shopId].shopName,
        subtext = _U("buyBoat"),
        align = "top-left",
        elements = elements,
        lastmenu = 'MainMenu',
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger](shopId)
        end
        if data.current.value then
            local buyData = data.current.info
            local location = Config.boatShops[shopId].location

            TriggerServerEvent('oss_boats:BuyBoat', buyData, location)
            menu.close()
            InMenu = false
            ClearPedTasksImmediately(PlayerPedId())
            DisplayRadar(true)
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(PlayerPedId())
        DisplayRadar(true)
    end)
end

-- Menu to Manage Owned Boats at Shop Location
RegisterNetEvent("oss_boats:OwnedBoatsMenu")
AddEventHandler("oss_boats:OwnedBoatsMenu", function(ownedBoats, shopId)
    MenuData.CloseAll()
    InMenu = true
    local elements = {}

    for boat, ownedBoatData in pairs(ownedBoats) do
        elements[#elements + 1] = {
            label = ownedBoatData.name,
            value = boat,
            desc = _U("chooseBoat"),
            info = ownedBoatData,
        }
    end
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title = Config.boatShops[shopId].shopName,
        subtext = _U("own"),
        align = "top-left",
        elements = elements,
        lastmenu = 'MainMenu',
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger](shopId)
        end
        local ownedData = data.current.info
        if data.current.value then
            BoatMenu(ownedData, shopId)
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(PlayerPedId())
        DisplayRadar(true)
    end)
end)

-- Menu to Launch, Sell or Transfer Owned Boats
function BoatMenu(ownedData, shopId)
    MenuData.CloseAll()
    InMenu = true
    BoatName = ownedData.name
    BoatModel = ownedData.model
    BoatHome = ownedData.location
    local boatData = Config.boatShops[shopId].boats[BoatModel]
    local currencyType = boatData.currencyType
    local sellPrice = boatData.sellPrice
    TransferAllow = Config.transferAllow
    local player = PlayerPedId()
    local descSell
    local descTransfer

    if currencyType == "cash" then
        descSell = _U("sell") .. BoatName .. _U("frcash2") .. sellPrice

    elseif currencyType == "gold" then
        descSell = _U("sell") .. BoatName .. _U("fr2") .. sellPrice .. _U("ofgold2")
    end

    if TransferAllow then
        descTransfer = _U("transfer") .. BoatName .. _U("transferShop")
    else
        descTransfer = _U("transferDisabledMenu")
    end

    local elements = {
        {
            label = _U("launch"),
            value = "launch",
            desc = _U("launchBoat") .. BoatName
        },
        {
            label = _U("sellBoat"),
            value = "sell",
            desc = descSell
        },
        {
            label = _U("transferBoat"),
            value = "transfer",
            desc = descTransfer
        }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi' .. shopId,
    {
        title = Config.boatShops[shopId].shopName,
        subtext = BoatName,
        align = "top-left",
        elements = elements,
        lastmenu = 'MainMenu',
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger](shopId)
        end
        if data.current.value == "launch" then

            menu.close()
            InMenu = false
            ClearPedTasksImmediately(player)
            DisplayRadar(true)
            SpawnBoat(ownedData)

        elseif data.current.value == "sell" then

            TriggerServerEvent('oss_boats:SellBoat', ownedData, boatData)
            menu.close()
            InMenu = false
            ClearPedTasksImmediately(player)
            DisplayRadar(true)

        elseif data.current.value == "transfer" then

            if TransferAllow then
                TransferBoat(ownedData, boatData, shopId)
            else
                VORPcore.NotifyRightTip(_U("transferDisabled"),4000)
            end
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(player)
        DisplayRadar(true)
    end)
end

-- Menu to Choose Shop to Transfer Boat
function TransferBoat(ownedData, boatData, shopId)
    MenuData.CloseAll()
    InMenu = true
    local name = ownedData.name
    local model = ownedData.model
    local location = ownedData.location
    local currencyType = boatData.currencyType
    local transferPrice = boatData.transferPrice
    local descTransfer

    if currencyType == "cash" then
        descTransfer = _U("transfer") .. name .. _U("frcash2") .. transferPrice
    elseif currencyType == "gold" then
        descTransfer = _U("transfer") .. name .. _U("fr2") .. transferPrice .. _U("ofgold2")
    end

    local elements = {}

    for _, shopConfig in pairs(Config.boatShops) do
        elements[#elements + 1] = {
            label = shopConfig.shopName,
            value = shopConfig.location,
            desc = descTransfer
        }
    end
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
    {
        title = Config.boatShops[shopId].shopName,
        subtext = name,
        align = "top-left",
        elements = elements,
        lastmenu = 'MainMenu',
    },
    function(data, menu)
        if data.current == "backup" then
            _G[data.trigger](shopId)
        end
        local transferLocation = data.current.value
        if transferLocation then
            local menuTransfer = "menuTransfer"
            local jobLevel = Config.boatShops[transferLocation].jobGrade
            local shopName = Config.boatShops[transferLocation].shopName
            if transferLocation ~= location then
                if not next(Config.boatShops[transferLocation].allowedJobs) then
                    TriggerServerEvent("oss_boats:TransferBoat", ownedData, transferLocation, menuTransfer, boatData, shopName)
                    menu.close()
                    InMenu = false
                    ClearPedTasksImmediately(PlayerPedId())
                    DisplayRadar(true)
                else
                    TriggerServerEvent("oss_boats:getPlayerJob")
                    Wait(200)
                    if PlayerJob then
                        if CheckJob(Config.boatShops[transferLocation].allowedJobs, PlayerJob) then
                            if tonumber(Config.boatShops[transferLocation].jobGrade) <= tonumber(JobGrade) then
                                TriggerServerEvent("oss_boats:TransferBoat", ownedData, transferLocation, menuTransfer, boatData, shopName)
                                menu.close()
                                InMenu = false
                                ClearPedTasksImmediately(PlayerPedId())
                                DisplayRadar(true)
                            else
                                VORPcore.NotifyRightTip(_U("transferJob") .. JobName .. " " .. jobLevel,5000)
                            end
                        else
                            VORPcore.NotifyRightTip(_U("transferJob") .. JobName .. " " .. jobLevel,5000)
                        end
                    else
                        VORPcore.NotifyRightTip(_U("transferJob") .. JobName .. " " .. jobLevel,5000)
                    end
                end
            else
                VORPcore.NotifyRightTip(_U("noTransfer"),4000)
            end
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(PlayerPedId())
        DisplayRadar(true)
    end)
end

-- Boat Anchor Operation and Boat Return at Non-Shop Locations
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if IsControlJustReleased(0, Config.optionKey) then
            if IsPedInAnyBoat(PlayerPedId()) and IsBoating == true then
                    BoatOptionsMenu()
            else
                return
            end
        end
    end
end)

function BoatOptionsMenu()
    MenuData.CloseAll()
    InMenu = true
    local player = PlayerPedId()
    local elements = {
        {
            label = _U("anchorMenu"),
            value = "anchor",
            desc = _U("anchorAction")
        },
        {
            label = _U("returnMenu"),
            value = "return",
            desc = _U("returnAction")
        }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi', {
        title    = _U("boatMenu"),
        subtext  = _U("boatSubMenu"),
        align    = "top-left",
        elements = elements,
    }, function(data, menu)
        if data.current.value == "anchor" then
            if IsPedInAnyBoat(player) then
                local playerBoat = GetVehiclePedIsIn(player, true)
                if not isAnchored then
                    SetBoatAnchor(playerBoat, true)
                    SetBoatFrozenWhenAnchored(playerBoat, true)
                    isAnchored = true
                    VORPcore.NotifyRightTip(_U("anchorDown"),4000)
                else
                    SetBoatAnchor(playerBoat, false)
                    isAnchored = false
                    VORPcore.NotifyRightTip(_U("anchorUp"),4000)
                end
            end
            menu.close()
            InMenu = false
        elseif data.current.value == "return" then
            TaskLeaveVehicle(player, MyBoat, 0)
            menu.close()
            InMenu = false
            IsBoating = false
            Wait(15000)
            DeleteEntity(MyBoat)
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(player)
        DisplayRadar(true)
    end)
end

-- Spawn New or Owned Boat
function SpawnBoat(ownedData)
    if MyBoat then
        DeleteEntity(MyBoat)
    end
    local player = PlayerPedId()
    local name = ownedData.name
    local model = ownedData.model
    local location = ownedData.location
    local boatConfig = Config.boatShops[location]
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end
    MyBoat = CreateVehicle(model, boatConfig.boatx, boatConfig.boaty, boatConfig.boatz, boatConfig.boath, true, false)
    SetVehicleOnGroundProperly(MyBoat)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(MyBoat, 1)
    DoScreenFadeOut(500)
    Wait(500)
    SetPedIntoVehicle(player, MyBoat, -1)
    Wait(500)
    DoScreenFadeIn(500)
    local boatBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1749618580, MyBoat) -- BlipAddForEntity
    SetBlipSprite(boatBlip, GetHashKey("blip_canoe"), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, boatBlip, name) -- SetBlipName
    IsBoating = true
    VORPcore.NotifyRightTip(_U("boatMenuTip"),4000)
end

-- Return Boat Using Prompt at Shop Location
function ReturnBoat(shopId)
    local player = PlayerPedId()
    local shopConfig = Config.boatShops[shopId]
    local coords = vector3(shopConfig.playerx, shopConfig.playery, shopConfig.playerz)
    TaskLeaveVehicle(player, MyBoat, 0)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(player, coords.x, coords.y, coords.z)
    Wait(500)
    DoScreenFadeIn(500)
    IsBoating = false
    DeleteEntity(MyBoat)
end

-- Prevents Boat from Sinking
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        if IsPedInAnyBoat(player) then
            SetPedResetFlag(player, 364, 1)
        end
    end
end)

-- Menu Prompts
function ShopOpen()
    local str = _U("shopPrompt")
    OpenShops = PromptRegisterBegin()
    PromptSetControlAction(OpenShops, Config.shopKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenShops, str)
    PromptSetEnabled(OpenShops, 1)
    PromptSetVisible(OpenShops, 1)
    PromptSetStandardMode(OpenShops, 1)
    PromptSetGroup(OpenShops, ShopPrompt1)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, OpenShops, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(OpenShops)
end

function ShopClosed()
    local str = _U("shopPrompt")
    CloseShops = PromptRegisterBegin()
    PromptSetControlAction(CloseShops, Config.shopKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CloseShops, str)
    PromptSetEnabled(CloseShops, 1)
    PromptSetVisible(CloseShops, 1)
    PromptSetStandardMode(CloseShops, 1)
    PromptSetGroup(CloseShops, ShopPrompt2)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, CloseShops, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(CloseShops)
end

function ReturnOpen()
    local str = _U("returnPrompt")
    OpenReturn = PromptRegisterBegin()
    PromptSetControlAction(OpenReturn, Config.returnKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenReturn, str)
    PromptSetEnabled(OpenReturn, 1)
    PromptSetVisible(OpenReturn, 1)
    PromptSetStandardMode(OpenReturn, 1)
    PromptSetGroup(OpenReturn, ReturnPrompt1)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, OpenReturn, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(OpenReturn)
end

function ReturnClosed()
    local str = _U("returnPrompt")
    CloseReturn = PromptRegisterBegin()
    PromptSetControlAction(CloseReturn, Config.returnKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CloseReturn, str)
    PromptSetEnabled(CloseReturn, 1)
    PromptSetVisible(CloseReturn, 1)
    PromptSetStandardMode(CloseReturn, 1)
    PromptSetGroup(CloseReturn, ReturnPrompt2)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, CloseReturn, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(CloseReturn)
end

-- Blips
function AddBlip(shopId)
    local shopConfig = Config.boatShops[shopId]
    if shopConfig.blipAllowed then
        shopConfig.BlipHandle = N_0x554d9d53f696d002(1664425300, shopConfig.npcx, shopConfig.npcy, shopConfig.npcz) -- BlipAddForCoords
        SetBlipSprite(shopConfig.BlipHandle, shopConfig.blipSprite, 1)
        SetBlipScale(shopConfig.BlipHandle, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, shopConfig.BlipHandle, shopConfig.blipName) -- SetBlipName
    end
end

-- NPCs
function LoadModel(npcModel)
    local model = GetHashKey(npcModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(100)
    end
end

function SpawnNPC(shopId)
    local shopConfig = Config.boatShops[shopId]
    LoadModel(shopConfig.npcModel)
    if shopConfig.npcAllowed then
        local npc = CreatePed(shopConfig.npcModel, shopConfig.npcx, shopConfig.npcy, shopConfig.npcz, shopConfig.npch, false, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
        SetEntityCanBeDamaged(npc, false)
        SetEntityInvincible(npc, true)
        Wait(500)
        FreezeEntityPosition(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        Config.boatShops[shopId].NPC = npc
    end
end

-- Check if Player has Job
function CheckJob(allowedJob, playerJob)
    for _, jobAllowed in pairs(allowedJob) do
        JobName = jobAllowed
        if JobName == playerJob then
            return true
        end
    end
    return false
end

RegisterNetEvent("oss_boats:sendPlayerJob")
AddEventHandler("oss_boats:sendPlayerJob", function(Job, grade)
    PlayerJob = Job
    JobGrade = grade
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if InMenu == true then
        ClearPedTasksImmediately(PlayerPedId())
        PromptDelete(OpenShops)
        PromptDelete(CloseShops)
        PromptDelete(OpenReturn)
        PromptDelete(CloseReturn)
        MenuData.CloseAll()
    end

    if MyBoat then
        DeleteEntity(MyBoat)
    end

    for _, shopConfig in pairs(Config.boatShops) do
        if shopConfig.BlipHandle then
            RemoveBlip(shopConfig.BlipHandle)
        end
        if shopConfig.NPC then
            DeleteEntity(shopConfig.NPC)
            DeletePed(shopConfig.NPC)
            SetEntityAsNoLongerNeeded(shopConfig.NPC)
        end
    end
end)

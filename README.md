# Boats

#### Description
This is a basic boating script for RedM servers using the [VORP framework](https://github.com/VORPCORE). Boats can be bought, sold and transferred through shops. There are 6 shops configured, more shop locations may be added using the `config.lua` file.

#### Features
- Buy, sell and transfer boats through the boat shops
- Cash or gold may be used for payments
- Shop hours may be set individually for each shop or disabled to allow the shop to remain open
- Boats are available to use in the shop where purchased
- Boats can be transferred to other shops by menu (configurable transfer fee) or by driving boat to the new shop and returning it there.
- Shop blips are colored and changeable per shop location
- Blips can change color reflecting if shop is open or closed
- Shop access can be limited by job and jobgrade
- Boats can be returned at the shop location via prompt or remotely using the in-boat menu after parking/beaching the boat somewhere
- In-boat menu for anchor operation and remote boat return
- Config setting to prevent the spawning of NPC boats
- Boats can be driven across the map without sinking

#### Configuration
Settings can be changed in the `config.lua` file. Here is an example of one shop:
```lua
    lagras = {
        shopName = "Lagras Boats", -- Name of Shop on Menu
        location = "lagras", -- DON'T CHANGE / Used for Location in Database
        promptName = "Lagras Boats", -- Text Below the Prompt Button
        blipAllowed = true, -- Turns Blips On / Off
        blipName = "Lagras Boats", -- Name of the Blip on the Map
        blipSprite = 2005921736, -- 2005921736 = Canoe / -1018164873 = Tugboat
        blipColorOpen = "BLIP_MODIFIER_MP_COLOR_32", -- Shop Open - Blip Colors Shown Below
        blipColorClosed = "BLIP_MODIFIER_MP_COLOR_10", -- Shop Closed - Blip Colors Shown Below
        npcx = 2123.95, npcy = -551.63, npcz = 41.53, npch = 113.62, -- Blip and NPC Positions
        boatx = 2122.8, boaty = -544.76, boatz = 40.55, boath = 46.69, -- Boat Spawn and Return Positions
        playerx = 2121.31, playery = -552.65, playerz = 42.7, playerh = 316.34, -- Player Return Teleport Position
        distanceShop = 2.0, -- Distance from NPC to Get Menu Prompt
        distanceReturn = 6.0, -- Distance from Shop to Get Return Prompt
        npcAllowed = true, -- Turns NPCs On / Off
        npcModel = "A_M_M_UniBoatCrew_01", -- Sets Model for NPCs
        allowedJobs = {}, -- Empty, Everyone Can Use / Insert Job to limit access - ex. "police"
        jobGrade = 0, -- Enter Minimum Rank / Job Grade to Access Shop
        shopHours = false, -- If You Want the Shops to Use Open and Closed Hours
        shopOpen = 7, -- Shop Open Time / 24 Hour Clock
        shopClose = 21, -- Shop Close Time / 24 Hour Clock
        boats = { -- Change ONLY These Values: boatName, currencyType, buyPrice, sellPrice and transferPrice
            canoetreetrunk = { boatName = "Dugout Canoe",   boatModel = "canoetreetrunk", currencyType = "cash", buyPrice = 25,   sellPrice = 15,  transferPrice = 5  },
            canoe          = { boatName = "Canoe",          boatModel = "canoe",          currencyType = "cash", buyPrice = 40,   sellPrice = 25,  transferPrice = 5  },
            pirogue        = { boatName = "Pirogue Canoe",  boatModel = "pirogue",        currencyType = "cash", buyPrice = 50,   sellPrice = 30,  transferPrice = 5  },
            pirogue2       = { boatName = "Pirogue2 Canoe", boatModel = "pirogue2",       currencyType = "cash", buyPrice = 50,   sellPrice = 30,  transferPrice = 5  },
            rowboat        = { boatName = "Rowboat",        boatModel = "rowboat",        currencyType = "cash", buyPrice = 100,  sellPrice = 70,  transferPrice = 10 },
            rowboatSwamp   = { boatName = "Swamp Rowboat",  boatModel = "rowboatSwamp",   currencyType = "cash", buyPrice = 100,  sellPrice = 70,  transferPrice = 10 },
            keelboat       = { boatName = "Keelboat",       boatModel = "keelboat",       currencyType = "cash", buyPrice = 800,  sellPrice = 600, transferPrice = 20 },
            boatsteam02x   = { boatName = "Steamboat",      boatModel = "boatsteam02x",   currencyType = "cash", buyPrice = 1200, sellPrice = 900, transferPrice = 20 },
        },
    },
```

#### Dependencies
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [menuapi](https://github.com/outsider31000/menuapi)
- [oxmysql](https://github.com/overextended/oxmysql)

#### Installation
- Ensure that the dependancies are added and started
- Add `oss_boats` folder to your resources folder
- Add `ensure oss_boats` to your `resources.cfg`
- Run the included database file `boats.sql`

#### Credits
- kcrp_boats
- vorp_stores
- Hobbs
- SavSin

#### GitHub
- https://github.com/JusCampin/oss_boats
<h1 align="center">XS-Housing</h1>

<p align="center">Houses, apartments, MLOs, offices and motel rooms for <strong>QBox</strong> and <strong>QBCore</strong>, all built in game.</p>

---

XS-Housing is the whole housing system in one resource. Staff build every place from an in-game builder, players buy, rent or take a mortgage, and owners run their home from a smart-home panel on the wall.

Every interior is a private copy, so one shell or GTA interior can sit behind any number of front doors.

## Features

- QBox and QBCore support
- In-game builder with a place editor, an overview of what still needs doing, bulk edits, Ctrl+K search and every setting live, no restart
- Street houses: a front door that leads into a shell or a GTA interior, and a yard drawn as a square, hexagon, circle or your own corners
- MLO houses: pick the real doors and draw the rooms. Locks go through your door lock script
- Apartment buildings: one lobby door, as many apartments as you want, each with its own owner
- Offices, motel rooms and garages, plus places only a job or a crew can buy
- 190 shells and 66 GTA interiors to pick from, with décor styles owners can change. The builder shows which shells your server has
- Every place gets its own private copy of its inside, so any number of places can use the same shell or GTA interior
- Quick place: walk down a street and make a house at every door you aim at
- Buy outright, rent, or take a mortgage with a deposit and a payment plan
- Rent and mortgage payments come out on their own, with grace days, late fees, eviction and repossession
- Optional property tax, power and water bills, and home insurance
- Starter apartments for new characters, made on the spot when the building runs out
- Real estate job: agents list places, set prices within a range, and sign buyers for a commission. Players buy at the For Sale sign when no agent is working
- Listing with photo, tours inside before buying, and a mortgage calculator
- Open houses: owners, or agents for places on the market, open the door for 15 minutes so anyone can walk in, with a map blip
- Smart-home panel on the wall: lock, lights, music, doorbell, alarm, cameras, keys, payments, storage and décor. `/house` opens it from anywhere
- Keys for co-owners, tenants and guests, with guest keys that run out
- Furniture for inside and the yard: storage, safes, beds, seats, lamps, speakers and TVs that work once placed
- Music and TVs play YouTube, Twitch and direct links, in sync for everyone in the room, quieter further away. No sound script needed
- Storage that grows with upgrades, a wardrobe, and storage left behind waiting at the agency after you move out
- Fridges that keep food fresh four times longer (ox_inventory items with decay)
- Doorbell and knocking, with a phone alert and letting people in from afar
- Break-ins with a lockpick, harder behind better locks, and safes that stay shut
- Break-ins leave evidence: a fingerprint at the door when no gloves are worn, and a forced lock police can inspect until the owner repairs it
- Alarms that call the police and the owner, and cameras you watch from the panel
- Police raids, with a warrant check through XS-MDT
- Garages added to your garage script at every place that has one
- Logging out inside a house puts you back inside on login
- Holiday decorations for Halloween, the winter holidays and the Fourth of July. They follow the calendar or staff switch them on, and hide again when the season ends
- Logs for sales, rent, keys, break-ins, raids and staff changes, with Discord webhooks

## Requirements

- QBox or QBCore
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)

Optional:

- A target script (ox_target or qb-target). Without one, every door uses E prompts
- [bob74_ipl](https://github.com/Bob74/bob74_ipl) for GTA interiors with décor styles
- [screenshot-basic](https://github.com/citizenfx/screenshot-basic) to take listing photos and interior pictures in the builder
- XS-PoliceSystem or qb-policejob for break-in fingerprints
- Game build 2944 or newer for the Halloween pumpkins and bats, 3095 for the snow fort
- Shell packs. 23 of the shells are free in K4MB1's starter pack, the rest need their pack streamed on your server. K4MB1's newer `K4MB1-StarterShells` pack works too. A pack whose models are not in the list still works: type the model name on the place's Interior tab. That includes the 6 shells from `envi_starter_shell_pack`: their inside door is not known, so place it once in the builder for each place

## Installation

1. Put `XS-Housing` in your resources folder.
2. Add it to `server.cfg` after its dependencies:

   ```cfg
   ensure ox_lib
   ensure oxmysql
   ensure XS-Housing
   ```

3. Give your staff the builder:

   ```cfg
   add_ace group.admin xs.housing.admin allow
   ```

4. Restart the server. The tables make themselves on the first start.
5. Join, type `/housebuilder`, and build your first place.

Break-ins use the `lockpick` item that comes with qb-core and ox_inventory, or an `advancedlockpick`. Change them in Settings › Break-ins.

Police raids need the `police_stormram` item. Most QBCore servers already have it. If yours does not, paste `items/ox_inventory.lua` into `ox_inventory/data/items.lua`, or `items/qb_core.lua` into `qb-core/shared/items.lua`. To raid without an item, empty Ram item in Settings › Raids.

If you use another housing script, stop it before players use the new places. The Tools page in the builder can bring over houses, owners and keys from qb-houses, qbx_properties and ps-housing.

## Commands

| Command | Who | What |
| --- | --- | --- |
| `/housebuilder` | Staff | Opens the builder |
| `/house` | Owners and key holders | Opens the smart-home panel. At a place it opens that one, anywhere else it lists your places. Furnishing still needs you there |
| `/housetablet` | Estate agents on duty | Opens the agent tablet |
| `/housediag` | Staff | Prints what XS-Housing found on your server. Run in game, it also shows which shell packs your game can see |

## Works with

| | |
| --- | --- |
| Door locks | XS-DoorLock, ox_doorlock, mri_Qdoorlock, qb-doorlock, rcore_doorlock, qs-doorlock-creator, doors_creator, cd_doorlock, or its own built-in lock |
| Garages | XS-Garages, jg-advancedgarages, qbx_garages, qb-garages, cd_garage, okokGarage |
| Inventories | ox_inventory, qb-inventory, qs-inventory, ps-inventory, codem-inventory, core_inventory |
| Clothing | XS-Appearance, illenium-appearance, qb-clothing |
| Phones | XS-Phone, lb-phone, qs-smartphone, npwd, gksphone, okokPhone, yseries, high-phone, roadphone, 17mov_Phone, qb-phone |
| Dispatch | XS-Dispatch, ps-dispatch, qs-dispatch, cd_dispatch, core_dispatch, rcore_dispatch, linden_outlawalert |
| Banking | Renewed-Banking, qb-banking, okokBanking, tgg-banking, wasabi_banking, fd_banking, qb-management |
| Weather | Renewed-Weathersync, qb-weathersync, cd_easytime |

XS-Phone's Home app lists XS-Housing places, locks and unlocks them, and hands out keys.

XS-MultiCharacter lists XS-Housing places in its spawn picker, and skips its own apartment picker while Starter apartments are on here.

Police use the Stormram from their inventory at a house door to raid it, or pick Raid at the door. A lockpick used at a house door through another script (anything that fires `lockpicks:UseLockpick`, like qb-vehiclekeys) starts a break-in here. Radial menus and police scripts can call the client events `XS-Housing:client:raid` and `XS-Housing:client:breakIn`, or the exports below, to do the same at the nearest door.

## Configuration

Everything is in `config.lua`, and almost all of it can also be changed in game from the builder's Settings page. Those changes are live for everyone and override `config.lua`.

Text is in `locales/en.lua`.

## Exports

Server:

```lua
exports['XS-Housing']:GetHomes(source)              -- every place the player owns or has keys to
exports['XS-Housing']:HasKey(source, propertyId)
exports['XS-Housing']:GetRole(source, propertyId)   -- 'owner', 'coowner', 'tenant', 'guest' or nil
exports['XS-Housing']:GetProperty(propertyId)
exports['XS-Housing']:GetPlayerProperties(citizenid)
exports['XS-Housing']:IsInside(source)
exports['XS-Housing']:GetInside(source)             -- the place id the player is inside
exports['XS-Housing']:SetLocked(source, propertyId, locked)
exports['XS-Housing']:SetKeys(source, propertyId, added, removed)
exports['XS-Housing']:Spawns(source)                -- home spawn points for a spawn selector
exports['XS-Housing']:EnterProperty(source, propertyId)
exports['XS-Housing']:Raid(source, propertyId)      -- the same checks as a raid at the door, then opens it for police
exports['XS-Housing']:OpenForPolice(propertyId, minutes)   -- opens it for police with no checks, for MDT or warrant scripts
exports['XS-Housing']:IsRaided(propertyId)
```

Client:

```lua
exports['XS-Housing']:Raid()                        -- raids the nearest house door, as if the Stormram was used
exports['XS-Housing']:BreakIn()                     -- starts a break-in at the nearest house door
exports['XS-Housing']:NearestDoor(maxDistance)      -- { id, label, type, distance } or nil
```

## Support

Join the [Discord](https://discord.gg/XRURAw4TM2) for help.

## License

See [LICENSE](LICENSE).

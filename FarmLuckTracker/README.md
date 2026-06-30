# FarmLuckTracker

FarmLuckTracker is a minimal WoW Classic farming tracker. It tracks kills, mining taps, skins, item loot, two-stage container farms, target progress, expected attempts remaining, observed item rates, and luck. The window shifts from deep red to gold as the session moves below or above the configured odds.

## Install

Put the `FarmLuckTracker` folder in:

`World of Warcraft/_classic_era_/Interface/AddOns/`

For another Classic client, use that client's `Interface/AddOns` folder and update the TOC interface number if the addon list marks it out of date.

## Use

1. Open the addon with `/flt`.
2. Search for an item, select a farm, set the target amount, adjust odds if your server/version uses different rates, then press `Begin`.
3. Farm normally. Looted target items are tracked from your loot chat. Mob kills are tracked by pairing combat XP messages with `PLAYER_XP_UPDATE`, following the same high-confidence approach used by HardcoreLlama. Mining taps and some skinning/herbalism attempts are tracked from successful profession casts. Clam openings are tracked when the relevant clam item is used.
4. Search results prefer farms near your current player level when level bands are known. For example, a level 31 search for Iridescent Pearl should prefer the Thick-shelled Clam route over the 40+ Big-mouth Clam route.
5. Use the manual `+` and `-` buttons if WoW misses an event, you join a group, farm grey mobs that give no XP, or you want to backfill attempts.
6. Press `End` to stop the session.

## Slash Commands

- `/flt` toggles the window.
- `/flt show`
- `/flt hide`
- `/flt lock`
- `/flt unlock`
- `/flt reset`
- `/flt scale 1.2`
- `/flt end`

## Notes

WoW addons cannot search the web from inside the game. The addon uses a local, sourced starter database and lets you edit odds per farm before each session. The database includes basic cloth tiers, pearls, elemental essences, specialty silks, high-end leather/scales, mining gems, raid materials, crafted cooldown materials, Bloodvine, Frozen Runes, and Naxxramas scraps. SavedVariables keep your window size, position, scale, custom odds, and active session.

# FarmLuckTracker

FarmLuckTracker is a minimal WoW Classic farming tracker. It tracks kills, mining taps, skins, item loot, two-stage container farms, target progress, expected attempts remaining, observed item rates, and luck. The window shifts from deep red to gold as the session moves below or above the configured odds.

## Install

Put the `FarmLuckTracker` folder in:

`World of Warcraft/_classic_era_/Interface/AddOns/`

For another Classic client, use that client's `Interface/AddOns` folder and update the TOC interface number if the addon list marks it out of date.

## Use

1. Open the addon with `/flt`.
2. Search for an item, select a farm, set the target amount, adjust odds if your server/version uses different rates, then press `Begin`.
3. Farm normally. Looted target items are tracked from loot chat. Mob kills are tracked from combat log `PARTY_KILL`. Mining taps and some skinning/herbalism attempts are tracked from successful profession casts. Clam openings are tracked when the Big-mouth Clam item is used.
4. Use the manual `+` and `-` buttons if WoW misses an event, you join a group, or you want to backfill attempts.
5. Press `End` to stop the session.

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

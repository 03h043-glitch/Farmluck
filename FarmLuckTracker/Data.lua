local addonName, ns = ...

ns.DataVersion = 3
ns.Farms = {}

local LEVELS = {
    ["linen-cloth"] = { 5, 16 }, ["wool-cloth"] = { 16, 29 }, ["silk-cloth"] = { 28, 40 }, ["mageweave-cloth"] = { 40, 50 }, ["runecloth"] = { 50, 60 }, ["felcloth"] = { 50, 60 },
    ["spiders-silk"] = { 20, 30 }, ["thick-spiders-silk"] = { 35, 45 }, ["shadow-silk"] = { 40, 50 }, ["ironweb-spider-silk"] = { 55, 60 }, ["wildvine"] = { 30, 50 }, ["powerful-mojo"] = { 50, 60 },
    ["elemental-fire"] = { 25, 56 }, ["elemental-earth"] = { 35, 58 }, ["elemental-air"] = { 28, 58 }, ["elemental-water"] = { 35, 60 }, ["heart-of-fire"] = { 45, 56 }, ["core-of-earth"] = { 35, 56 }, ["breath-of-wind"] = { 28, 58 }, ["globe-of-water"] = { 35, 60 },
    ["essence-of-fire"] = { 50, 60 }, ["essence-of-air"] = { 50, 60 }, ["essence-of-earth"] = { 50, 60 }, ["essence-of-water"] = { 50, 60 }, ["living-essence"] = { 50, 60 }, ["essence-of-undeath"] = { 50, 60 },
    ["small-flame-sac"] = { 20, 45 }, ["rugged-hide"] = { 50, 60 }, ["devilsaur-leather"] = { 54, 60 }, ["warbear-leather"] = { 50, 60 }, ["frostsaber-leather"] = { 55, 60 }, ["chimera-leather"] = { 50, 60 }, ["heavy-scorpid-scale"] = { 50, 60 },
    ["arcane-crystal"] = { 55, 60 }, ["dark-iron-ore"] = { 48, 60 }, ["azerothian-diamond"] = { 50, 60 }, ["blue-sapphire"] = { 50, 60 }, ["huge-emerald"] = { 50, 60 }, ["large-opal"] = { 40, 60 }, ["star-ruby"] = { 35, 60 },
}

local function split(text, sep)
    local out, pattern = {}, "([^" .. (sep or ",") .. "]+)"
    for value in string.gmatch(text or "", pattern) do
        value = value:gsub("^%s+", ""):gsub("%s+$", "")
        if value ~= "" then table.insert(out, value) end
    end
    return out
end

local function sources(...)
    local out = {}
    for i = 1, select("#", ...) do
        local itemId = select(i, ...)
        if itemId then table.insert(out, "https://www.wowhead.com/classic/item=" .. tostring(itemId)) end
    end
    return out
end

local function applyLevel(farm, minLevel, maxLevel, routeName)
    local r = minLevel and { minLevel, maxLevel } or LEVELS[farm.key]
    if r then farm.levelMin = r[1]; farm.levelMax = r[2] end
    if routeName then farm.routeName = routeName end
end

local function add(key, name, itemId, aliases, kind, sourceLabel, button, targetLabel, chance, chanceLabel, locations, note, gather, deterministic)
    local farm = {
        key = key,
        name = name,
        itemId = itemId,
        aliases = split(aliases),
        mode = "single",
        sourceKind = kind,
        sourceLabel = sourceLabel,
        attemptButton = button,
        targetLabel = targetLabel,
        chance = chance,
        chanceLabel = chanceLabel,
        locations = split(locations, "|"),
        oddsNote = note,
        sourceUrls = sources(itemId),
    }
    if gather then farm.gatherSpells = split(gather) end
    if deterministic then farm.deterministic = true end
    applyLevel(farm)
    table.insert(ns.Farms, farm)
end

local function twoClam(key, name, itemId, aliases, sourceItemId, sourceItemName, sourceLabel, stage1Chance, stage2Chance, minLevel, maxLevel, locations, note)
    local farm = {
        key = key,
        name = name,
        itemId = itemId,
        aliases = split(aliases),
        mode = "twoStage",
        sourceKind = "kill",
        sourceLabel = "Kills",
        attemptButton = "+ Kill",
        targetLabel = "Items",
        stage1 = { itemId = sourceItemId, name = sourceItemName, label = sourceLabel, chance = stage1Chance, chanceLabel = sourceLabel .. " / kill" },
        stage2 = { itemId = itemId, name = name, label = "Items", sourceItemId = sourceItemId, sourceItemName = sourceItemName, chance = stage2Chance, chanceLabel = name .. " / clam" },
        locations = split(locations, "|"),
        oddsNote = note,
        sourceUrls = sources(sourceItemId, itemId),
    }
    applyLevel(farm, minLevel, maxLevel, sourceItemName)
    table.insert(ns.Farms, farm)
end

local function two(key, name, itemId, aliases, stage1Chance, stage2Chance, locations, note)
    twoClam(key, name, itemId, aliases, 7973, "Big-mouth Clam", "Big-mouth Clams", stage1Chance, stage2Chance, 40, 60, locations, note)
end

twoClam("iridescent-pearl-thick", "Iridescent Pearl - Thick-shelled Clam", 5500, "iridescent pearl,thick-shelled clam,thick shelled clam,clam pearl,pearl,wetlands,hillsbrad,bluegill,snapjaw", 5524, "Thick-shelled Clam", "Thick clams", 0.42, 0.0257, 20, 32, "Wetlands - Bluegill Marsh murlocs north of Menethil Harbor; a strong fit around level 24-31.|Hillsbrad Foothills / Alterac edge - Snapjaw turtle shoreline near Dalaran and Lordamere.|Stranglethorn Vale - Vile Reef murlocs if you can handle underwater pulls.", "Level-aware Iridescent Pearl default for lower characters. Wowhead Classic points Iridescent Pearl and Thick-shelled Clams toward Wetlands or Hillsbrad murloc farms; Wowpedia notes Thick-shelled Clams from many level 20-32 beasts and humanoids.")
twoClam("small-lustrous-pearl-small", "Small Lustrous Pearl - Small Barnacled Clam", 5498, "small lustrous pearl,small barnacled clam,clam pearl,pearl,darkshore,bfd", 5523, "Small Barnacled Clam", "Small clams", 0.42, 0.055, 10, 24, "Darkshore - Ruins of Mathystra naga and nearby coast.|Blackfathom Deeps - naga and murloc-heavy clears.|The Barrens / Silverpine / Westfall coasts - low-level murloc and naga routes.", "Lower-level pearl route. Small Barnacled Clams are the relevant first stage; exact clam-per-kill rates vary heavily by mob.")
twoClam("small-lustrous-pearl-thick", "Small Lustrous Pearl - Thick-shelled Clam", 5498, "small lustrous pearl,thick-shelled clam,thick shelled clam,clam pearl,pearl,wetlands,hillsbrad", 5524, "Thick-shelled Clam", "Thick clams", 0.42, 0.050, 20, 32, "Wetlands - Bluegill Marsh murlocs.|Hillsbrad / Alterac - Snapjaw turtle shoreline.|Blackfathom Deeps or Stranglethorn lower routes if they match your level.", "Useful when farming Iridescent Pearls because the same clams can produce Small Lustrous Pearls.")

two("golden-pearl", "Golden Pearl - Big-mouth Clam", 13926, "gold pearl,golden pearl,big mouth clam,big-mouth clam,clam pearl,pearl", 0.52, 0.00509, "Swamp of Sorrows - Marsh murloc packs along the eastern coast.|Azshara - coastal naga and fishing routes for Big-mouth Clams.|Tanaris / Feralas / Hinterlands - fish Big-mouth Clams while moving between pools.", "Defaults use a high-clam mob route and Wowhead Classic container samples.")
two("black-pearl", "Black Pearl - Big-mouth Clam", 7971, "black pearl,big mouth clam,big-mouth clam,clam pearl,pearl", 0.52, 0.0405, "Swamp of Sorrows - Marsh murlocs for high Big-mouth Clam volume.|Azshara - coastal mobs and fishing routes.|Tanaris / Feralas - fishing Big-mouth Clams.", "Defaults use Wowhead Classic Big-mouth Clam container samples.")
two("iridescent-pearl", "Iridescent Pearl - Big-mouth Clam", 5500, "iridescent pearl,big mouth clam,big-mouth clam,clam pearl,pearl,azshara,tanaris", 0.52, 0.0300, "Swamp of Sorrows - Marsh murlocs for Big-mouth Clams.|Azshara / Tanaris / Feralas - fish Big-mouth Clams.|Hinterlands / Tanaris turtles and naga if you are in the 40+ band.", "Higher-level Iridescent Pearl route. At level 31, the Thick-shelled Clam route should sort ahead of this one.")

add("arcane-crystal", "Arcane Crystal", 12363, "rich thorium,rtv,thorium,mining", "mining", "Mining taps", "+ Tap", "Crystals", 0.0295, "Crystals / tap", "Winterspring - Rich Thorium circuits.|Eastern Plaguelands - Pestilent Scar, Noxious Glade and cave loops.|Azshara / Burning Steppes / Un'Goro - Rich Thorium routes.", "Default uses Wowhead Classic Rich Thorium Vein mined-from samples.", "Mining")
add("black-lotus", "Black Lotus", 13468, "lotus,herbalism,herb", "herbalism", "Lotus nodes", "+ Node", "Lotus", 1, "Lotus / node", "Burning Steppes - full zone circuit.|Silithus - perimeter and hive-adjacent routes.|Winterspring - Everlook and Frostsaber circuits.|Eastern Plaguelands - zone-wide herbing circuit.", "Spawn competition is not modeled; tracking is per Lotus node found.", "Herbalism,Herb Gathering", true)

add("linen-cloth", "Linen Cloth", 2589, "linen,cloth,tailoring", "kill", "Humanoid kills", "+ Kill", "Cloth", 0.55, "Cloth / kill", "Westfall - Defias camps and Moonbrook humanoids.|Loch Modan / Darkshore / Barrens - low-level humanoid camps.|Ragefire Chasm / Deadmines - dense early dungeon clears.", "Starter cloth farm. Rates vary by mob level and stack size.")
add("wool-cloth", "Wool Cloth", 2592, "wool,cloth,tailoring", "kill", "Humanoid kills", "+ Kill", "Cloth", 0.45, "Cloth / kill", "The Stockade - fast wool-heavy instance resets.|Shadowfang Keep - mixed Linen/Wool/Silk while clearing.|Redridge / Wetlands / Hillsbrad - level 20-30 humanoid camps.", "Editable average for level 20-30 humanoids.")
add("silk-cloth", "Silk Cloth", 4306, "silk,cloth,tailoring", "kill", "Humanoid kills", "+ Kill", "Cloth", 0.50, "Cloth / kill", "Scarlet Monastery - Graveyard, Library and Armory clears.|Arathi Highlands - Stromgarde Syndicate and ogres.|Stranglethorn Vale - Kurzen and Venture Co. humanoids.", "Starter rate assumes dense level 30-40 humanoid farming.")
add("mageweave-cloth", "Mageweave Cloth", 4338, "mageweave,cloth,tailoring", "kill", "Humanoid kills", "+ Kill", "Cloth", 0.46, "Cloth / kill", "Zul'Farrak - troll instance clears.|Tanaris - Wastewander pirates and bandits.|Feralas - Gordunni ogres and Grimtotem camps.", "Starter rate assumes level 40-50 humanoid farms.")
add("runecloth", "Runecloth", 14047, "rune cloth,runecloth,cloth,tailoring", "kill", "Humanoid kills", "+ Kill", "Cloth", 0.42, "Cloth / kill", "Eastern Plaguelands - Tyr's Hand Scarlet elites.|Burning Steppes - Blackrock Stronghold or Dreadmaul Rock.|Stratholme / Scholomance / Blackrock Spire - dungeon clears.", "Dungeon density often matters more than raw drop chance.")
add("felcloth", "Felcloth", 14256, "jadefire,legashi,satyr,demons,cloth", "kill", "Kills", "+ Kill", "Felcloth", 0.04, "Felcloth / kill", "Azshara - Legashi satyr camps.|Felwood - Jadefire Run and Jadefire Glen.|Dire Maul East - satyr trash.", "Classic reports vary; default is conservative and editable.")
add("mooncloth", "Mooncloth", 14342, "moon cloth,felcloth cooldown,tailoring cooldown", "craft", "Crafts", "+ Craft", "Mooncloth", 1, "Mooncloth / craft", "Tailoring - craft from Felcloth at a Moonwell.|Track output after farming Felcloth or buying mats.", "Deterministic crafted reagent.", nil, true)

add("arcanite-bar", "Arcanite Bar", 12360, "arcanite,arcane crystal,alchemy transmute", "craft", "Transmutes", "+ Craft", "Bars", 1, "Bars / transmute", "Alchemy - transmute Thorium Bar plus Arcane Crystal.|Farm Arcane Crystals from Rich Thorium Veins, then track transmutes here.", "Deterministic crafted reagent.", nil, true)
add("cured-rugged-hide", "Cured Rugged Hide", 15407, "rugged hide,salt shaker,leatherworking", "craft", "Cures", "+ Cure", "Hides", 1, "Hides / cure", "Leatherworking - cure Rugged Hide with Refined Deeprock Salt.|Farm Rugged Hide from high-level skinnable beasts.", "Deterministic crafted reagent.", nil, true)
add("refined-deeprock-salt", "Refined Deeprock Salt", 15409, "deeprock salt,salt shaker,salt", "craft", "Refines", "+ Refine", "Salt", 1, "Salt / refine", "Leatherworking - refine Deeprock Salt with a Salt Shaker.|Deeprock Salt drops from high-level earth elementals.", "Deterministic crafted reagent.", nil, true)
add("enchanted-leather", "Enchanted Leather", 12810, "enchanted leather,enchanting,leatherworking", "craft", "Crafts", "+ Craft", "Leather", 1, "Leather / craft", "Enchanting - convert rugged leather into Enchanted Leather.|Used by rare and epic profession recipes.", "Deterministic crafted reagent.", nil, true)
add("enchanted-thorium-bar", "Enchanted Thorium Bar", 12655, "enchanted thorium,thorium bar,enchanting", "craft", "Crafts", "+ Craft", "Bars", 1, "Bars / craft", "Enchanting - convert Thorium Bars into Enchanted Thorium Bars.|Used by high-end blacksmithing, engineering and weapon recipes.", "Deterministic crafted reagent.", nil, true)

add("elemental-fire", "Elemental Fire", 7068, "fire elemental,elemental,fire", "kill", "Elemental kills", "+ Kill", "Fire", 0.09, "Fire / kill", "Arathi Highlands - Circle of West Binding.|Un'Goro Crater - Fire Plume Ridge.|Searing Gorge / Burning Steppes - fire elemental packs.", "Common elemental reagent; editable route estimate.")
add("elemental-earth", "Elemental Earth", 7067, "earth elemental,elemental,earth", "kill", "Elemental kills", "+ Kill", "Earth", 0.10, "Earth / kill", "Badlands - Rock Elementals.|Arathi Highlands - Circle of Inner Binding.|Silithus / Un'Goro - higher-level earth routes.", "Common elemental reagent; adjust for your chosen mob.")
add("elemental-air", "Elemental Air", 7069, "air elemental,elemental,air", "kill", "Elemental kills", "+ Kill", "Air", 0.08, "Air / kill", "Arathi Highlands - Circle of Outer Binding.|Silithus - Dust Stormer and Whirling Invader routes.|Thousand Needles - lower-level air elemental camps.", "Common elemental reagent, often paired with Essence of Air farms.")
add("elemental-water", "Elemental Water", 7070, "water elemental,elemental,water", "kill", "Elemental kills", "+ Kill", "Water", 0.10, "Water / kill", "Arathi Highlands - Circle of East Binding.|Eastern Plaguelands - water elemental lakes.|Azshara - Patch of Elemental Water fishing.", "Common elemental reagent.")
add("heart-of-fire", "Heart of Fire", 7077, "heart fire,fire elemental,elemental", "kill", "Elemental kills", "+ Kill", "Hearts", 0.08, "Hearts / kill", "Un'Goro Crater - Fire Plume Ridge.|Searing Gorge - fire elementals.|Burning Steppes - fire elemental routes.", "Fire reagent used by higher-end recipes and transmutes.")
add("core-of-earth", "Core of Earth", 7075, "earth core,earth elemental,elemental", "kill", "Elemental kills", "+ Kill", "Cores", 0.06, "Cores / kill", "Badlands - earth elemental routes.|Un'Goro Crater - Stone Guardians.|Silithus - earth elemental areas.", "Uncommon earth reagent.")
add("breath-of-wind", "Breath of Wind", 7081, "wind,air elemental,elemental", "kill", "Elemental kills", "+ Kill", "Breaths", 0.07, "Breaths / kill", "Silithus - Dust Stormer routes.|Arathi Highlands - air elemental circle.|Thousand Needles - lower-level wind camps.", "Air reagent paired with Elemental Air and Essence of Air farms.")
add("globe-of-water", "Globe of Water", 7079, "water globe,water elemental,elemental", "kill", "Elemental kills", "+ Kill", "Globes", 0.09, "Globes / kill", "Eastern Plaguelands - water elemental lakes.|Azshara - elemental water fishing.|Arathi Highlands - water elemental circle.", "Water reagent paired with Elemental Water and Essence of Water farms.")
add("essence-of-fire", "Essence of Fire", 7078, "fire essence,essence,elemental fire", "kill", "Elemental kills", "+ Kill", "Essences", 0.04, "Essences / kill", "Un'Goro Crater - Fire Plume Ridge.|Burning Steppes / Searing Gorge - high-level fire elementals.|Elemental Invasion events when active.", "Rare elemental essence for high-end recipes.")
add("essence-of-air", "Essence of Air", 7082, "air essence,essence,dust stormer", "kill", "Elemental kills", "+ Kill", "Essences", 0.03, "Essences / kill", "Silithus - Dust Stormer routes.|Silithus - Whirling Invaders during invasions.|Transmute chains can convert other essences into Air.", "Rare elemental essence; reports vary by mob/version.")
add("essence-of-earth", "Essence of Earth", 7076, "earth essence,essence,desert rumbler", "kill", "Elemental kills", "+ Kill", "Essences", 0.035, "Essences / kill", "Silithus - Desert Rumblers.|Un'Goro Crater - Stone Guardians.|Elemental Invasion events when active.", "Rare elemental essence.")
add("essence-of-water", "Essence of Water", 7080, "water essence,toxic horror,blighted surge,elemental water", "kill", "Kills", "+ Kill", "Essences", 0.045, "Essences / kill", "Felwood - Toxic Horrors at Irontree Woods.|Eastern Plaguelands - water elementals.|Azshara - Patch of Elemental Water fishing.", "Midpoint of public Classic reports for water elementals.")
add("living-essence", "Living Essence", 12803, "essence of life,life essence,living", "kill", "Nature kills", "+ Kill", "Essences", 0.035, "Essences / kill", "Felwood - Toxic Horrors and nature mobs.|Dire Maul East - lashers and Warpwood trash.|Un'Goro Crater - tar and plant creatures.", "Rare life reagent for nature-resistance and high-end recipes.")
add("essence-of-undeath", "Essence of Undeath", 12808, "undeath essence,undead essence,stratholme,scholomance", "kill", "Undead kills", "+ Kill", "Essences", 0.035, "Essences / kill", "Stratholme - undead trash.|Scholomance - undead trash clears.|Western/Eastern Plaguelands - high-level undead camps.", "Rare undeath reagent.")

add("spiders-silk", "Spider's Silk", 3182, "spider silk,silk,spiders", "kill", "Spider kills", "+ Kill", "Silk", 0.08, "Silk / kill", "Duskwood - Raven Hill and Twilight Grove spiders.|Hillsbrad / Wetlands - mid-level spiders.|Shadowfang Keep - spider-heavy sections.", "Low-to-mid-level specialty silk.")
add("thick-spiders-silk", "Thick Spider's Silk", 4337, "thick spider silk,spider silk,silk", "kill", "Spider kills", "+ Kill", "Silk", 0.09, "Silk / kill", "Dustwallow Marsh - Darkmist spiders.|Arathi Highlands - spider routes.|Razorfen Downs / Uldaman - spider sections.", "Mid-level specialty silk.")
add("shadow-silk", "Shadow Silk", 10285, "shadow silk,spider silk,silk", "kill", "Spider kills", "+ Kill", "Silk", 0.05, "Silk / kill", "Swamp of Sorrows - shadow spider routes.|Dustwallow Marsh - higher-level spider camps.|Feralas / Hinterlands - dense spider areas.", "Uncommon spider reagent used by shadow themed gear.")
add("ironweb-spider-silk", "Ironweb Spider Silk", 14227, "ironweb,spider silk,silk", "kill", "Spider kills", "+ Kill", "Silk", 0.14, "Silk / kill", "Eastern Plaguelands - Plague Lurkers and carrion spiders.|Silithus - high-level spider routes.|Lower Blackrock Spire - spider sections.", "High-end spider silk.")
add("wildvine", "Wildvine", 8153, "wild vine,troll,herb", "kill", "Troll kills", "+ Kill", "Wildvine", 0.035, "Wildvine / kill", "The Hinterlands - Vilebranch trolls.|Stranglethorn Vale - Skullsplitter and Bloodscalp trolls.|Zul'Farrak - troll dungeon clears.", "Troll/herb reagent used by several rare recipes.")
add("powerful-mojo", "Powerful Mojo", 12804, "mojo,troll,powerful", "kill", "Troll kills", "+ Kill", "Mojo", 0.05, "Mojo / kill", "Eastern Plaguelands - Mossflayer trolls.|The Hinterlands - Vilebranch trolls.|Zul'Gurub / high-level troll areas.", "High-level mojo for rare and epic recipes.")
add("righteous-orb", "Righteous Orb", 12811, "orb,stratholme,crusader,righteous", "kill", "Scarlet kills", "+ Kill", "Orbs", 0.03, "Orbs / kill", "Stratholme Live - Scarlet trash.|Group runs are usually better than outdoor alternatives.", "Used by Crusader and several rare/epic crafts.")
add("guardian-stone", "Guardian Stone", 12809, "guardian,stone guardian,stone", "kill", "Guardian kills", "+ Kill", "Stones", 0.04, "Stones / kill", "Un'Goro Crater - Stone Guardians around the pylons.|High-level stone elemental routes.", "Rare stone reagent.")
add("larval-acid", "Larval Acid", 18512, "acid,larva,carrion grub,carrion devourer", "kill", "Larva kills", "+ Kill", "Acid", 0.08, "Acid / kill", "Eastern Plaguelands - Carrion Grubs and Carrion Devourers.|Western Plaguelands - carrion worm routes.", "Used in high-end tailoring and leatherworking crafts.")
add("demonic-rune", "Demonic Rune", 12662, "demonic rune,demon,satyr", "kill", "Demon kills", "+ Kill", "Runes", 0.06, "Runes / kill", "Felwood - Jadefire satyrs.|Azshara - Legashi satyrs.|Dire Maul East - demon and satyr trash.", "Often farmed alongside Felcloth.")
add("heart-of-the-wild", "Heart of the Wild", 10286, "heart wild,plant,nature,living", "kill", "Nature kills", "+ Kill", "Hearts", 0.05, "Hearts / kill", "Un'Goro Crater - tar beasts and plant creatures.|Felwood - corrupted plant routes.|Dire Maul East - lashers and Warpwood trash.", "Nature reagent used in rare recipes.")
add("huge-venom-sac", "Huge Venom Sac", 19441, "venom sac,poison,spider,scorpid", "kill", "Venom kills", "+ Kill", "Sacs", 0.08, "Sacs / kill", "Silithus - spiders and scorpids.|Eastern Plaguelands - high-level spiders.|Zul'Gurub / Ahn'Qiraj-adjacent farms.", "Poison reagent used by nature-resistance and consumable recipes.")
add("small-flame-sac", "Small Flame Sac", 4402, "flame sac,fire sac,whelp,dragonkin", "kill", "Kills", "+ Kill", "Sacs", 0.22, "Sacs / kill", "Wetlands - Adolescent Whelps and dragonkin.|Dustwallow Marsh - Searing Hatchlings.|Badlands - whelp routes.", "Default uses Wowhead Classic Adolescent Whelp samples.")

add("rugged-hide", "Rugged Hide", 8171, "rugged hide,hide,skinning", "skinning", "Skins", "+ Skin", "Hides", 0.10, "Hides / skin", "Winterspring - high-level beasts.|Un'Goro Crater - dinosaurs and gorillas.|Eastern Plaguelands / Burning Steppes - high-level beasts.", "Base hide for Cured Rugged Hide.", "Skinning")
add("devilsaur-leather", "Devilsaur Leather", 15417, "devilsaur,leather,skinning,un'goro", "skinning", "Devilsaur skins", "+ Skin", "Leather", 0.95, "Leather / skin", "Un'Goro Crater - Devilsaur patrol routes.|Track each successful skin.", "Near-deterministic specialty skin.", "Skinning")
add("warbear-leather", "Warbear Leather", 15419, "warbear,leather,skinning", "skinning", "Bear skins", "+ Skin", "Leather", 0.35, "Leather / skin", "Winterspring - shardtooth and ice thistle bear routes.|Western Plaguelands / Felwood - high-level bears.", "Specialty leather used by Warbear gear.", "Skinning")
add("frostsaber-leather", "Frostsaber Leather", 15422, "frostsaber,leather,skinning", "skinning", "Frostsaber skins", "+ Skin", "Leather", 0.35, "Leather / skin", "Winterspring - Frostsaber Rock and nearby cats.|Best tracked per successful skin.", "Specialty leather used by Frostsaber gear.", "Skinning")
add("chimera-leather", "Chimera Leather", 15423, "chimera,chimaera,leather,skinning", "skinning", "Chimera skins", "+ Skin", "Leather", 0.35, "Leather / skin", "Winterspring - chimaera near Frostwhisper Gorge.|Azshara / Feralas - chimaera camps.", "Specialty leather used by Chimeric gear.", "Skinning")
add("heavy-scorpid-scale", "Heavy Scorpid Scale", 15408, "scorpid scale,heavy scorpid,skinning", "skinning", "Scorpid skins", "+ Skin", "Scales", 0.45, "Scales / skin", "Silithus - Stonelash and desert scorpid routes.|Blasted Lands - high-level scorpid packs.", "Scale reagent for Heavy Scorpid mail.", "Skinning")
add("black-dragonscale", "Black Dragonscale", 15416, "black dragon scale,dragonscale,skinning", "skinning", "Dragonkin skins", "+ Skin", "Scales", 0.35, "Scales / skin", "Burning Steppes - black dragonkin routes.|Blackrock Spire - dragonkin trash.|Onyxia's Lair / Blackwing Lair - raid dragonkin.", "Used by Black Dragonscale crafted mail.", "Skinning")
add("red-dragonscale", "Red Dragonscale", 15414, "red dragon scale,dragonscale,skinning", "skinning", "Dragonkin skins", "+ Skin", "Scales", 0.25, "Scales / skin", "Wetlands - red dragonkin in the Dragonmaw area.|Grim Batol-adjacent red dragonkin routes.", "Specialty dragonscale reagent.", "Skinning")
add("blue-dragonscale", "Blue Dragonscale", 15415, "blue dragon scale,dragonscale,skinning", "skinning", "Dragonkin skins", "+ Skin", "Scales", 0.30, "Scales / skin", "Azshara - blue dragonkin elite areas.|Winterspring - Mazthoril blue dragonkin routes.", "Specialty dragonscale reagent.", "Skinning")
add("green-dragonscale", "Green Dragonscale", 15412, "green dragon scale,dragonscale,skinning", "skinning", "Dragonkin skins", "+ Skin", "Scales", 0.30, "Scales / skin", "Swamp of Sorrows - green whelps and dragonkin.|Feralas / Hinterlands - green dragonkin routes.", "Specialty dragonscale reagent.", "Skinning")
add("core-leather", "Core Leather", 17012, "core leather,molten core,skinning", "skinning", "Core hound skins", "+ Skin", "Leather", 0.80, "Leather / skin", "Molten Core - skin core hounds after raid kills.|Requires high Skinning and a group/raid route.", "Raid skinning reagent.", "Skinning")
add("primal-bat-leather", "Primal Bat Leather", 19767, "primal bat,zg,zul'gurub,skinning", "skinning", "Bat skins", "+ Skin", "Leather", 0.35, "Leather / skin", "Zul'Gurub - Bloodseeker Bat and bat pack routes.|Often farmed alongside Primal Tiger Leather.", "Zul'Gurub specialty leather.", "Skinning")
add("primal-tiger-leather", "Primal Tiger Leather", 19768, "primal tiger,zg,zul'gurub,skinning", "skinning", "Tiger skins", "+ Skin", "Leather", 0.35, "Leather / skin", "Zul'Gurub - Zulian Tiger skinning routes.|Group and stealth routes can both work.", "Zul'Gurub specialty leather.", "Skinning")

add("dark-iron-ore", "Dark Iron Ore", 11370, "dark iron,ore,mining,brd", "mining", "Mining taps", "+ Tap", "Ore", 1.20, "Ore / tap", "Blackrock Depths - Dark Iron Deposit routes.|Searing Gorge / Burning Steppes - outdoor Dark Iron nodes.|Molten Core - raid mining opportunities.", "Ore per tap can exceed one; adjust for route.", "Mining")
add("blood-of-the-mountain", "Blood of the Mountain", 11382, "blood mountain,dark iron,mining,molten core", "mining", "Mining taps", "+ Tap", "Blood", 0.006, "Blood / tap", "Blackrock Depths - rare Dark Iron Deposit result.|Molten Core - rare source from molten giants/destroyers and mining.", "Very rare reagent for legendary and epic fire-related crafting.", "Mining")
add("azerothian-diamond", "Azerothian Diamond", 12800, "diamond,azerothian,thorium,gem", "mining", "Mining taps", "+ Tap", "Gems", 0.018, "Gems / tap", "Rich Thorium Veins - Winterspring, Eastern Plaguelands, Azshara.|Ooze Covered Rich Thorium - Silithus and high-level caves.", "Rare gem from high-end mining.", "Mining")
add("blue-sapphire", "Blue Sapphire", 12361, "sapphire,blue gem,thorium,gem", "mining", "Mining taps", "+ Tap", "Gems", 0.018, "Gems / tap", "Rich Thorium Veins - Winterspring, Eastern Plaguelands, Azshara.|High-level gem bags and mining routes.", "Rare gem from high-end mining.", "Mining")
add("huge-emerald", "Huge Emerald", 12364, "emerald,huge gem,thorium,gem", "mining", "Mining taps", "+ Tap", "Gems", 0.018, "Gems / tap", "Rich Thorium Veins - Winterspring, Eastern Plaguelands, Azshara.|High-level mining routes and gem bags.", "Rare gem used by high-end recipes.", "Mining")
add("large-opal", "Large Opal", 12799, "opal,large gem,thorium,gem", "mining", "Mining taps", "+ Tap", "Gems", 0.018, "Gems / tap", "Rich Thorium Veins - Winterspring, Eastern Plaguelands, Azshara.|High-level mining and gem containers.", "Rare gem used by rare and epic crafts.", "Mining")
add("star-ruby", "Star Ruby", 7910, "ruby,star ruby,gem", "mining", "Mining taps", "+ Tap", "Gems", 0.018, "Gems / tap", "Mithril and Thorium mining routes.|Tanaris / Hinterlands / Searing Gorge - mid-to-high circuits.", "Rare gem used in mid/high-level blue recipes.", "Mining")
add("black-diamond", "Black Diamond", 11754, "black diamond,brd,gem", "kill", "Instance kills", "+ Kill", "Diamonds", 0.02, "Diamonds / kill", "Blackrock Depths - trash and boss clears.|Blackrock Spire - high-level Blackrock instance trash.", "Dungeon gem/reagent used by specialty recipes and turn-ins.")
add("pristine-black-diamond", "Pristine Black Diamond", 18335, "pristine diamond,black diamond,dire maul,scholomance", "kill", "Instance kills", "+ Kill", "Diamonds", 0.006, "Diamonds / kill", "Dire Maul - high-level boss and trash clears.|Scholomance / Stratholme - high-level dungeon clears.", "Very rare diamond used by high-end enchants and profession recipes.")
add("fiery-core", "Fiery Core", 17010, "fiery core,molten core,mc", "kill", "Raid kills", "+ Kill", "Cores", 0.10, "Cores / kill", "Molten Core - fire elemental and boss trash drops.|Track per relevant raid trash/boss kill.", "Raid reagent for epic fire-resistance and Thorium Brotherhood recipes.")
add("lava-core", "Lava Core", 17011, "lava core,molten core,mc", "kill", "Raid kills", "+ Kill", "Cores", 0.10, "Cores / kill", "Molten Core - lava elemental and giant trash drops.|Track per relevant raid trash/boss kill.", "Raid reagent for epic fire-resistance and Thorium Brotherhood recipes.")
add("bloodvine", "Bloodvine", 19726, "bloodvine,zg,zul'gurub,herbalism", "herbalism", "ZG herbs", "+ Herb", "Bloodvine", 0.15, "Bloodvine / herb", "Zul'Gurub - herbs inside the raid while carrying Blood Scythe.|Can also drop from select Hakkari mobs.", "ZG-specific reagent used by Bloodvine and Cenarion Circle crafts.", "Herbalism,Herb Gathering")
add("frozen-rune", "Frozen Rune", 22682, "frozen rune,naxx,naxxramas,frost resist", "gather", "Rune pickups", "+ Rune", "Runes", 1, "Runes / pickup", "Naxxramas - collect from wall runes with Word of Thawing.|Used for crafted frost-resistance gear.", "Deterministic pickup reagent; use manual correction if pickup is not detected.", nil, true)
add("wartorn-cloth-scrap", "Wartorn Cloth Scrap", 22376, "wartorn,cloth scrap,naxx,tier 3", "kill", "Naxx kills", "+ Kill", "Scraps", 0.16, "Scraps / kill", "Naxxramas - trash throughout the raid.|Used for Tier 3 cloth armor turn-ins.", "Quest/crafting-style raid reagent for Naxxramas Tier 3 progression.")
add("wartorn-leather-scrap", "Wartorn Leather Scrap", 22373, "wartorn,leather scrap,naxx,tier 3", "kill", "Naxx kills", "+ Kill", "Scraps", 0.16, "Scraps / kill", "Naxxramas - trash throughout the raid.|Used for Tier 3 leather armor turn-ins.", "Quest/crafting-style raid reagent for Naxxramas Tier 3 progression.")
add("wartorn-chain-scrap", "Wartorn Chain Scrap", 22374, "wartorn,chain scrap,mail scrap,naxx,tier 3", "kill", "Naxx kills", "+ Kill", "Scraps", 0.16, "Scraps / kill", "Naxxramas - trash throughout the raid.|Used for Tier 3 mail armor turn-ins.", "Quest/crafting-style raid reagent for Naxxramas Tier 3 progression.")
add("wartorn-plate-scrap", "Wartorn Plate Scrap", 22375, "wartorn,plate scrap,naxx,tier 3", "kill", "Naxx kills", "+ Kill", "Scraps", 0.16, "Scraps / kill", "Naxxramas - trash throughout the raid.|Used for Tier 3 plate armor turn-ins.", "Quest/crafting-style raid reagent for Naxxramas Tier 3 progression.")

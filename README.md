# Add Enchanted Variants To Leveled Lists

To put in plainly, this xEdit script will insert all selected equipment (which will be enchanted variants of equipment generated beforehand [with this script](https://www.nexusmods.com/skyrimspecialedition/mods/25395)) into the Vanilla, and any pre-determined plugin's enchantment equipment leveled lists, making sure they are in the correct list and are tiered correctly.

This is designed as a "sister script" to the above linked xEdit script, as it relies on the way it generates Enchanted Variants.

This script is primarily designed to insert these weapons into the leveled lists prefixed with `SublistEnch`. The script allows you to choose the fuzzy search parameter, but you will almost always want to insert `SublistEnch`

1) Select any amount of weapon or armor records, and run the script. Other record types are ignored, so you can select a plugin or an ARMO/WEAP GRUP instead.

2) Enter a fuzzy search parameter for leveled lists (i.e `SublistEnch`, `LItemEnch`)

3) The script will then iterate over leveled lists in all the vanilla game plugins, Thaumaturgy, and Serenity (if they exist!) as well as any added plugins, and find any with the fuzzy search parameter. These are placed in a list. Then, for each selected equipment record, we check all those pre-determined LVLIs, and add it to relevent LVLIs. It decides which list to add to based on the WeapType/ArmorX and WeapMaterial/ArmorMaterial keywords that are attached to the equipment, along with the enchantment effect it has.

4) Determine the correct level to add the weapon at based on weapon tiers from WACCF, and pre-existing leveled list entries. Armor pieces are always added at Level 1 per Bethesda's schema for Armor SublistEnch LVLIs.

## Weapon Keywords

This script relies on proper keywords on weapons it is adding. This means that is is important that any weapons this script runs on have proper `WeapType` and `WeapMaterial` keywords, as this is what is used to determine the proper leveled list to add to.

## Armor Keywords

This script relies on proper keywords on armor pieces it is adding. This means that is is important that any armor pieces this script runs on have proper `ArmorX` and `ArmorMaterialX` keywords, as this is what is used to determine the proper leveled list to add to.

## Leveled List Flags

All leveled lists that are overridden will have the following flags set, to ensure that all the equipment variants can be rolled for even if a modded variant doesn't reach the highest level. Without doing this. if you are level 43, you will get the highest tier enchantments for Ebony in your roll, but if all the variants only applied to the lower two tiers, you would only get the vanilla variant. Setting these flags ensures that you can still roll for the lower level enchantment, which makes sense anyways. The lower tier enchantment lists already have these flags set in vanilla.

- Calculate from all levels <= player's level
- Calculate for each item in count

## Situations when Weapons will not be added to a Leveled List

Dwarven Weapons are the first tier to have all three "Absorb" enchantment lists. Previous tiers do not have lists for Absorb enchantments, and won't be added to a leveled list.

Elven Weapons are the first tier to have a "Banish" enchantment list. Previous tiers do not have a list for Banish, and won't be added to a leveled list.

When using WACCF, Orcish Weapons are the first tier to have a "Paralyze" enchantment list rather than Elven. Elven weapons will be added to Orcish enchantment lists for Paralyze only along with Orcish weapons. Previous tiers before Elven do not and did not have a list for Paralyze, and won't be added to a leveled list.

Nordic and Stalhrim tiers are the only tiers to have a "Chaos" enchantment list. Only Nordic or Stalhrim tiered weapons with Chaos will be added to a leveled list.

The Thaumaturgy "Damage Construct" enchantment has no leveled lists for any tier, and is only used for specifically hand-placed Dwarven weapons. No weapons with Damage Construct will be added to a leveled list.

The Huntsman's Prowess enchantment has no leveled list, and is only applied to the Poacher's axe in the vanilla game on the one NPC it's placed on. No weapons with Huntsman's Prowess will be added to a leveled list.

The Lunar enchantment has no leveled lists in Vanilla. The "Serenity" mod adds many new lists with lunar weapons, however they do not follow Bethesda's schema for Sublist LVLI EditorIDs and as such will only be found with a fuzzy search parameter of "LItemEnch" rather than "SublistEnch". You would want to run this script a second time against Lunar weapons with the different parameter to add to the Lunar lists.

## Situations when Armor will not be added to a Leveled List

As you move up in armor tiers, lower enchantment tiers (i.e `01`) do not have a leveled listlist.

For instance, Glass armors only have `03`, `04` and `05` lists. Any Glass equipment with a magnitude < `03` or if it is `06` does not have a list to be placed in.

Steel and Iron have `01`,`02`and `03`, Daedric has `04` `05` and `06`, etc

Most edge cases are checked for (ImperialLight, ImperialIron, Scaled Shields), and are converted to be added to a proper list.

## Tier and equipment type conversions

If a weapon is a Bow and has Wood tier, the tier will be changed to Hunting

If a weapon is NOT a bow has Wood tier, the tier will be changed to Iron

If a weapon is a Bow and has Steel tier, the tier will be changed to Imperial

If an armor piece is ImperialLight, it will be added to Leather lists.
- If that armor piece is a Shield, it will be added to Elven lists instead.

If a Shield is Scaled tier, it will be added to Elven lists instead.

### New weapon type conversions. Any new weapon types will be put into lists for the vanilla weapon type they are under

Battleaxe
- Pike
- Halberd
- Scythe
- Quarterstaff/QtrStaff

Sword
- Rapier
- Katana
- CurvedSword

Dagger
- Claw

## Specifics about early Bow Leveled Lists

Long Bow does not have ANY enchantment lists.

Hunting Bow (Hunting) only has Vanilla lists for the following. Weapons with Hunting tier with an enchantment not listed below will not be added to a leveled list.
- Fear
- Fire
- Frost
- Magicka
- Shock
- Stamina
- Turn

Imperial Bow (Imperial) has the same as Hunting Bow, but also, the below from Thaumaturgy. Weapons with Imperial tier with an enchantment not listed below or under Hunting Bow above will not be added to a leveled list.
- Burden
- Damage Armor
- Damage Weapon
- Frenzy
- Poison
- Silence
- Sun
- Weakness To Fire
- Weakness To Frost
- Weakness To Poison
- Weakness To Shock

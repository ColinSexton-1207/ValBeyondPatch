# Val's DnD AIO Beyond Patch: Changes

This file lists what the patch overrides in the base DnD2024 mod. Add new changes at the top.

Path shorthand used below:
- `Public\…` = `src\Public\ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8\…` (mirrors the Toolkit's `Data\Public\…`)

How overriding works: the patch declares *DnD 5.5e All-in-One BEYOND* (`897914ef-5c96-053c-44af-0be823f895fe`) as a dependency, so it loads after it. Stats entries and spell sets are matched by name, and the later-loaded definition wins. Each overridden entry is written out in full, and each field being turned off is set to `""` on purpose. That way it works whether the game merges entries field by field or replaces them whole.

---

## 2026-10-22: Both features are toggle passives; Spell Freedom swaps out the rule passive; MCM dropped

### Why
In testing, neither feature worked and there was no toggle for short rests. Also, turning Spell Freedom on should remove the original rule passive from the character, not just make it harmless.

### Changes
| File | Entry | Change |
|---|---|---|
| `Public\Stats\Generated\Data\Passive.txt` | `VBP_VanillaShortRests` | Hidden marker → toggle passive (same pattern as `VBP_SpellFreedom`), which sets the status `VBP_VANILLA_SHORT_RESTS`. |
| same | `ShortResting` | Gating `HasPassive('VBP_VanillaShortRests')` → `HasStatus('VBP_VANILLA_SHORT_RESTS')`. |
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `VBP_VANILLA_SHORT_RESTS` | New permanent status that the toggle sets. No portrait icon. |
| `Mods\ScriptExtender\Lua\BootstrapServer.lua` | | Rewritten. It grants both toggles to every player character, iterating `DB_Players`, the same set the original grants its rule passive to. While `VBP_SPELL_FREEDOM` is active, it removes `OneSpellWithASpellSlotPerTurn`, and gives it back when the status is removed. That runs on `StatusApplied`/`StatusRemoved`, and is re-checked on every load in case the original's story goal re-adds it. Every step logs to the Script Extender console with a `[ValBeyondPatch]` prefix. |
| `Mods\ScriptExtender\Lua\BootstrapClient.lua`, `Mods\MCM_blueprint.json` | | Removed. MCM is no longer used. |
| `Mods\Localization\English\ValBeyondPatch_English.xml` | `h8e365957…` (new), `h7ebb1554…` (v2) | Name and description text for the short rest toggle. |

### Kept as-is
- **The `IF(not HasStatus('VBP_SPELL_FREEDOM'))` gating on `ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN`.** Divine Smite and Invoke Duplicity apply that status directly, without the passive, so the gating is still needed.
- **The original `ShortResting` passive stays on the character sheet.** It's the same passive that does vanilla healing and grants Hit Dice, so it can't be removed. Its description is the original's.

### How to test
- Turn on the Script Extender console (`"CreateConsole": true` in `bin\ScriptExtenderSettings.json`). On load you should see `[ValBeyondPatch] server script loaded` and `syncing N player characters`.
- Turn on Spell Freedom. The console logs `removed OneSpellWithASpellSlotPerTurn`, the passive disappears from the character sheet, and two slot spells per turn work. Turn it off, and the passive comes back.
- Turn on Vanilla Short Rests and short rest. Healing should match vanilla.

---

## 2026-10-22: Spell Freedom became a per-character toggle, plus two Swift Witchcraft fixes

### Why
- Spell Freedom is now chosen per character with a toggle on the passive bar, like Metamagic or Non-Lethal Attacks, instead of with a global MCM switch.
- Swift Witchcraft had two problems, flagged before testing:
  - `RemoveEvents "OnSpellCast"` could catch the Quicken action's own cast and remove the effect immediately.
  - The `HasPassive` gating might not swap the action until a reload.

### Changes
| File | Entry | Change |
|---|---|---|
| `Public\Stats\Generated\Data\Passive.txt` | `VBP_SpellFreedom` | Hidden marker → toggle passive: `IsToggled;ToggledDefaultAddToHotbar`, `ToggleOnFunctors ApplyStatus(VBP_SPELL_FREEDOM,100,-1)`, `ToggleOffFunctors RemoveStatus(VBP_SPELL_FREEDOM)`. Off by default. Modeled on vanilla `NonLethal`. |
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `VBP_SPELL_FREEDOM` | New permanent status that the toggle sets. No portrait icon. |
| same, and `Passive.txt` | `ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN`, `SwiftWitchcraft` | Gating `HasPassive('VBP_SpellFreedom')` → `HasStatus('VBP_SPELL_FREEDOM')`. Conditional boosts that check a status are re-evaluated when the status changes, the same way NonLethal's boost follows its status, so Swift Witchcraft should swap actions as soon as you toggle. |
| `Public\Stats\Generated\Data\Passive.txt` | `SwiftWitchcraft` | Added `StatsFunctorContext "OnCastResolved"` and `Conditions "IsSpell() and not SpellId('Shout_SwiftWitchcraft_Quicken') and HasStatus('SWIFT_WITCHCRAFT_QUICKEN',context.Source)"`, with `StatsFunctors "RemoveStatus(SELF,SWIFT_WITCHCRAFT_QUICKEN)"`. The Quicken ends after the next spell and ignores the action's own cast. With Spell Freedom off, the status never exists, so this never fires. |
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `SWIFT_WITCHCRAFT_QUICKEN` | Removed `RemoveEvents "OnSpellCast"`. It still expires at the end of the turn. |
| `Mods\ScriptExtender\Lua\BootstrapServer.lua` | | `spell_freedom` removed from the MCM features. The `VBP_SpellFreedom` toggle is now granted to every party member. |
| `Mods\ScriptExtender\Lua\BootstrapClient.lua` | | Spell Freedom text swaps removed. A global text swap can't follow a per-character toggle. |
| `Mods\MCM_blueprint.json` | | Only `vanilla_short_rests` remains. |
| `Mods\Localization\English\ValBeyondPatch_English.xml` | `h6dffd14f…` (new), `h4f61caef…` (v2) | Name and description text for the toggle. |

### Known limitation
- **The Swift Witchcraft feat text** in the feat picker and on the passive is now always the original text. The Quicken action and its status have their own correct text, and the Spell Freedom toggle's description explains the change.

### How to test
- **Toggle off (the default):** behaves exactly like the original, including Swift Witchcraft.
- **Toggle on for one character only:** that character can cast two slot spells per turn, and the others can't.
- **Swift Witchcraft, toggle on:** the Quicken action replaces the original action without a reload. Using it makes action spells glow. The first spell costs a bonus action, and the next one is back to normal.
- **Toggle off mid-turn after using Quicken:** the original action comes back.

---

## 2026-10-22: Feature switches (Script Extender + Mod Configuration Menu)

### Why
With both switches off, the patch should do nothing, and players turn each feature on or off in-game. The changes come as two bundles:
- **Spell Freedom:** removes the one-slot-spell rule and adds the Swift Witchcraft Quicken rework. They can't be separated, because the rework only makes sense once the rule is gone.
- **Vanilla Short Rests:** restores vanilla short rest healing and turns off the Hit Point Dice action.

### How it works
- **Lua never edits stats.** The Script Extender docs say `StatsFunctors` can't be modified at runtime, and two of the changes are functors.
- **The stat overrides are fixed and gated.** Each one checks for a hidden marker passive. With the passive, the patch's behavior applies. Without it, the original mod's behavior applies, copied verbatim inside the `not` branch.
- **Server Lua (`BootstrapServer.lua`) manages the marker passives.** It adds or removes `VBP_SpellFreedom` and `VBP_VanillaShortRests` on party members to match the MCM checkboxes. It runs on `LevelGameplayStarted`, on `CharacterJoinedParty`, and on MCM's `MCM_Setting_Saved`.
- **Client Lua (`BootstrapClient.lua`) swaps text.** It changes the original mod's rule text with `Ext.Loca.UpdateTranslatedString` while a switch is on, and restores the original text when it's off.

### Changes
`Mods\…` = `src\Mods\ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8\…`

| File | Entry | Change |
|---|---|---|
| `Public\Stats\Generated\Data\Passive.txt` | `VBP_SpellFreedom`, `VBP_VanillaShortRests` | New hidden marker passives. |
| same | `ShortResting` | The original entry in full. `StatsFunctors`: vanilla healing `IF(HasPassive('VBP_VanillaShortRests'))`, otherwise the original's `RegainHitPoints(1)` + `SHORT_RESTING`. The 3 `UnlockSpellVariant(Shout_HitPointDice…)` boosts are also gated with `not HasPassive(…)`. The 12 Hit Dice grants are unchanged. |
| same | `SwiftWitchcraft` | The original entry, but `Boosts` unlocks `Shout_SwiftWitchcraft` without the marker and `Shout_SwiftWitchcraft_Quicken` with it. |
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN` | The original entry, but each boost is wrapped in `IF(not HasPassive('VBP_SpellFreedom',context.Source))`. Once the wrappers are stripped, it's checked to be byte-identical to upstream `3a702257`. |
| same | `SWIFT_WITCHCRAFT_QUICKEN` | New status with the Quicken cost swap and `RemoveEvents "OnSpellCast"`. |
| `Public\Stats\Generated\Data\Spell_Shout.txt` | `Shout_SwiftWitchcraft_Quicken` | New spell, `using "Shout_SwiftWitchcraft"`, with `OncePerShortRest` and the new status. |
| `Mods\ScriptExtender\Config.json`, `Mods\ScriptExtender\Lua\Bootstrap*.lua` | | New, as described above. |
| `Mods\MCM_blueprint.json` | `spell_freedom`, `vanilla_short_rests` | Two checkboxes, both default `false`. |
| `Mods\Localization\English\ValBeyondPatch_English.xml` | `h4f61caef…`, `h7ebb1554…` | New text for the disabled one-spell rule and for vanilla short rests. |

### Removed (they changed behavior even with both switches off)
- **The `OneSpellWithASpellSlotPerTurn` passive override.** The passive keeps its original behavior, and with Spell Freedom on, the status it applies has no effect. Its description is replaced at runtime instead.
- **The `SHORT_RESTING` override.** It's never applied while Vanilla Short Rests is on.
- **The `Shout_SwiftWitchcraft` and `SWIFT_WITCHCRAFT` overrides.** They're replaced by the new `_Quicken` entries, so the original Swift Witchcraft works when the switch is off.
- **`SpellSet.txt`.** A spell list can't be conditional, so it can't be switched. With Vanilla Short Rests on, the "Use Hit Point Dice" action stays in Common Actions but is always greyed out, because `SHORT_RESTING` is never applied. This also removes the upstream-drift risk.
- **`Public\Feats\FeatDescriptions.lsx`.** The feat description is now swapped at runtime.

### Requirements
- BG3 Script Extender.
- Mod Configuration Menu (`755a8a72-407f-4f0d-9a33-274ac0f0b53d`) as a `meta.lsx` dependency. Add it in Toolkit Project Settings.

### How to test
- **Both switches off:** behaves exactly like the original. You can only cast one slot spell per turn, short rests heal 1 HP and unlock Use Hit Point Dice, and Swift Witchcraft shows its original text and behavior.
- **Spell Freedom on, then save and reload:** two slot spells per turn work. The One Spell passive text says it's turned off. Swift Witchcraft shows the Quicken text and action. Also check the earlier `OnSpellCast` note.
- **Vanilla Short Rests on:** short rest healing matches vanilla, the Short Resting text is updated, and Use Hit Point Dice is greyed out.
- **Toggle a switch off again:** the original behavior and text come back.
- **Swap a companion into the party:** they get the current switch state.

---

## 2026-10-22: Reworked Swift Witchcraft into a free Quicken

### Why
Swift Witchcraft only existed to bypass the one-slot-spell rule. Once the patch removed that rule, the feat became a +1 ability with a dead action and a description that no longer matched. A patch can't delete another mod's feat, so it now does something useful instead.

### New behavior
+1 Intelligence, Wisdom or Charisma (unchanged). Once per **Short Rest**, as a free action: the next spell you cast this turn that costs an action costs a bonus action instead. It uses the same cost swap as Sorcerer's Quickened Spell (`QuickenedSpellCheck()`), with no Sorcery Points.

### Changes
`Mods\…` = `src\Mods\ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8\…`

| File | Entry | Change |
|---|---|---|
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `SWIFT_WITCHCRAFT` | `Boosts`: `StatusImmunity(ONE_SPELL…)` → `UnlockSpellVariant(QuickenedSpellCheck(),ModifyUseCosts(Replace,BonusActionPoint,1,0,ActionPoint),ModifyIconGlow())`. `OnApplyFunctors` → `""`. Added `RemoveEvents "OnSpellCast"`, so the status is used up by the next spell. It still expires at the end of the turn (duration 1). New `Description`. |
| `Public\Stats\Generated\Data\Spell_Shout.txt` (new file) | `Shout_SwiftWitchcraft` | `Cooldown`: `OncePerRest` (long rest) → `OncePerShortRest`. New `Description`. `ExtraDescription` → `""` (it described the old rule). Still free, with no `UseCosts`: a bonus-action cost would defeat the point. |
| `Public\Stats\Generated\Data\Passive.txt` | `SwiftWitchcraft` | New `Description`. Otherwise copied unchanged from the original. |
| `Public\Feats\FeatDescriptions.lsx` (new file) | FeatDescription `8be164c5-…` (feat `4f8aaee9-…`) | Same node with the new `Description` handle, which overrides the original's by UUID. |
| `Mods\Localization\English\ValBeyondPatch_English.xml` (new file) | `h17df3e22…` (feat/passive/spell), `h1f104bca…` (status) | New English strings. The file name is unique on purpose, because a second `english.xml` could replace the original's whole string table when packed. |

### Deliberately left in place
- **`Feats.lsx`.** The feat node (its +1 ability selector and `PassivesAdded`) is unchanged, so it isn't overridden.
- **The other languages** still show the original "multiple slot spells" text for the feat and action. Only English is updated.

### How to test
- The feat picker shows Swift Witchcraft with the new description.
- In combat, use Swift Witchcraft. A leveled spell and a cantrip that cost an action now glow and cost a bonus action. Cast one, and the next spell is back to normal.
- **Watch for:** if the status disappears the moment you use Swift Witchcraft, then `OnSpellCast` is catching the action's own cast. In that case, remove the `RemoveEvents` line, so the effect lasts the rest of the turn.
- Short rest, and the action is available again.

---

## 2026-10-22: Initial patch (one-slot-spell rule and short rest Hit Point Dice)

### Why
These are the same two changes as Val's Variant (see that repo's `VAL_VARIANT_UPDATES.md`). They're shipped as a separate pak, so the original mod can be installed unmodified and updated on its own.

### Changes
| File | Entry | Change |
|---|---|---|
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN` | `Boosts` → `""`. **This is what lifts the rule.** The original's `Boosts` added a cost of 1 `OneSpellWithASpellSlotPerTurn` to every slot spell, and no character ever has that resource. The passive, Divine Smite and Invoke Duplicity still apply the status, but it now does nothing. |
| `Public\Stats\Generated\Data\Passive.txt` | `OneSpellWithASpellSlotPerTurn` | `Properties` → `IsHidden`. `StatsFunctorContext`, `Conditions` and `StatsFunctors` → `""`. No `using`. The original inherits from `EquippingWeapons` (an on-equip action point refund), and setting these fields explicitly makes sure nothing inherited from it fires. |
| same | `ShortResting` | Restored vanilla (`Shared`) behavior: `Properties` `IsHidden`, `StatsFunctorContext` `OnShortRest`, and vanilla's `StatsFunctors` (MaxHP/2, or MaxHP with Durable or the "short rest heals to full" setting). `Boosts` keeps the original's 12 `ActionResource(HitPointDice08,N,0)` grants for non-mod classes and drops its 3 `UnlockSpellVariant(Shout_HitPointDice…)` clauses. No `using`, because the original's `using "ShortResting"` points at vanilla, and in a patch it would point at the original's own override. |
| `Public\Stats\Generated\Data\Status_BOOST.txt` | `SHORT_RESTING` | `Boosts` → `""`. Defensive only, since the patched `ShortResting` no longer applies this status. |
| `Public\Stats\Generated\SpellSet.txt` | `CommonPlayerActions`, `CommonSummonActions` | Copied from the original at upstream `3a702257`, minus `Shout_HitPointDice`. |

### Deliberately left in place (not overridden)
- **`Shout_HitPointDice` and its `06`–`12` variants.** They're no longer on any spell list, and their `RequirementConditions` need `SHORT_RESTING`, which is never applied now. `Shout_SpeedyRecovery` (Durable) still inherits from `Shout_HitPointDice`, so it has to stay defined.
- **The Divine Smite and Invoke Duplicity `ApplyStatus(…ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN…)` calls.** They're harmless now that the status is empty. The status does still show up in Divine Smite's polymorph `EnableCondition` (`HasAnyStatus({…,'ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN'})`), which only matters while polymorphed. This differs slightly from the fork, where that check is always false.
- **The story goal that grants `OneSpellWithASpellSlotPerTurn`.** A patch can't remove another mod's story code, but the passive it grants is now hidden and empty.
- **The Swift Witchcraft feat.** At first it was left as-is. It was later reworked (see the entry above).
- **Cosmetic fields on `ShortResting`** (`DisplayName`, `Description`, `Icon`, `PriorityOrder`). The passive is `IsHidden`, so they're never shown.

### Upstream drift to watch
- `SpellSet.txt` is a full copy of two lists. If upstream changes either list, re-copy it and remove `Shout_HitPointDice` again.
- If upstream renames or reworks any of the five entries above, re-check this patch against the new definitions.

### How to test (disposable save, original + patch only)
- New character: the "One Spell With a Spell Slot Per Turn" passive isn't visible.
- In combat, cast Guiding Bolt with the action and Healing Word with the bonus action. Both should cast. Divine Smite, then a leveled spell on the same turn, should also be allowed.
- Take damage and short rest. Healing should match vanilla, including the "short rest heals to full" custom setting. There should be no "Use Hit Point Dice" action in Common Actions.
- Durable → Speedy Recovery in combat still spends a Hit Die and heals.
- Disable the patch, and the original rules come back.

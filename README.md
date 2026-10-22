# Val's DnD AIO Beyond Patch

A small override patch for the [`bg3dnd`](https://github.com/Yoonmoonsik/bg3dnd) mod (*DnD 5.5e All-in-One BEYOND*) for *Baldur's Gate 3*. It runs **alongside** the original mod and adds two toggle passives that switch off its rules per character. **Every switch is off by default, so out of the box the patch changes nothing.** Both are toggles on each character's passive bar.

> **Disclaimer:** All original code, assets, and design rights belong to the original author, **[Yoonmoonsik](https://github.com/Yoonmoonsik)**. This patch contains none of the original mod's content. It only redefines a handful of entries by name, and it does nothing without the original installed.

---

## 🪄 Mod Page Links
* **Mod.io:** [Mod.io - ValBeyondPatch](https://mod.io/g/baldursgate3/m/vals-dnd-aio-beyond-patch)
* **Nexus Mods:** [Nexus - ValBeyondPatch](https://www.nexusmods.com/baldursgate3/mods/25986?published=1)

---

## 🔗 Original Mod & Credits

* **Original Mod Repository:** [Yoonmoonsik/bg3dnd](https://github.com/Yoonmoonsik/bg3dnd)
* **Original Author:** [Yoonmoonsik](https://github.com/Yoonmoonsik)
* **Nexus Mods Profile:** [yoonmoonsik43](https://www.nexusmods.com/profile/yoonmoonsik43)
* **Support the Original Creator:** [Ko-fi](https://ko-fi.com/yoonmoonsik) | [PayPal](https://paypal.me/yoonmoonsick)

---

## 🛠️ Toggles

* **Spell Freedom** (a per-character toggle on the passive bar, off by default):
  * *Removes the "one spell with a spell slot per turn" rule for that character, so Sorcerers and Wizards can cast more than one leveled spell per turn again, like in vanilla.*
  * *Reworks the **Swift Witchcraft** feat, which only existed to get around that rule. It still gives +1 INT/WIS/CHA, and now, once per Short Rest as a free action, it makes the next spell you cast that turn that costs an action cost a bonus action instead (a free Quickened Spell). English text only, and the feat's own description still shows the original text.*
* **Vanilla Short Rests** (a per-character toggle on the passive bar, off by default): *Restores vanilla short rest healing. The original's short rest heals 1 HP and unlocks a "Use Hit Point Dice" action. With the toggle on, short rests heal like vanilla again, including the "short rest heals to full" custom setting. The "Use Hit Point Dice" action stays in Common Actions but is greyed out. The Hit Point Dice resources are still there for the features that spend them (Durable, Lifedrinker, Sangromancy, Dwarven Fortitude, etc.).*

See [CHANGES.md](CHANGES.md) for the exact entries that are overridden and why.

---

## 📦 Installation

1. Install the requirement: **[BG3 Script Extender](https://github.com/Norbyte/bg3se)**.
2. Install the original **DnD 5.5e All-in-One BEYOND** as normal (mod.io or in-game Mod Manager).
3. Install this patch's pak, `ValBeyondPatch_decf7761-c0ea-30aa-4845-d9b0a6968ad8.pak`.
4. **Load order: the patch must load *after* DnD 5.5e All-in-One BEYOND.** The patch declares it as a dependency, so BG3 Mod Manager will sort it for you.
5. Launch the game. Every party member gets **Spell Freedom** and **Vanilla Short Rests** toggles on the passive bar, both off. Turn them on for whoever should have them.

> **⚠️ Don't use this with *Val's Variant: DnD 5.5e All-In-One Beyond* (the full fork).** The fork already includes these changes and replaces the original mod outright. Use the original plus this patch instead.

---

## 💾 Save Compatibility

* **Adding the patch to an existing save:** safe. With both toggles off, nothing changes.
* **Turning a toggle on or off mid-campaign:** safe, and takes effect right away.
* **Removing the patch:** the original rules come back on the next load.
* As always, back up your save before changing your mod list.

---

## 🔄 When the Original Updates

The patch carries copies of three of the original's entries (`ShortResting`, `SwiftWitchcraft`, `ONE_SPELL_WITH_A_SPELL_SLOT_PER_TURN`), used whenever a toggle is off. If Yoonmoonsik changes any of them, those copies need refreshing. Otherwise the patch keeps the old versions.

---

## 📜 Usage & License

If you are interested in the base **BG3 DnD 5.5e Mod**, please visit and support the official repository created by **Yoonmoonsik** linked above.

> Note that AI is occassionally used to help track changes between versions and documentation.

---

## ⚖️ Legal

Val's DnD AIO Beyond Patch is unofficial Fan Content permitted under the [Fan Content Policy](https://company.wizards.com/en/legal/fancontentpolicy). Not approved/endorsed by Wizards. Portions of the materials used are property of Wizards of the Coast. ©Wizards of the Coast LLC.

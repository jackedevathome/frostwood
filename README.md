# Frostwood — a Nordic survival game (Godot 4)

Survive the winter in a snowy forest of Scots pines and Norway spruces. Chop wood, break stone,
hunt deer and hares, cook meat over a campfire, and keep the wolves at bay through the long nights.

## Running it
1. Install **Godot 4.3 or newer** (standard build, no C# needed) from https://godotengine.org.
2. Open Godot → **Import** → pick `project.godot` in this folder → **Import & Edit**.
3. Press **F5** (or the ▶ Play button).

The first time you open the project, Godot imports the audio files. This takes a few seconds.

## Controls
| Action | Key |
|---|---|
| Move | **W A S D** (or arrow keys) |
| Sprint | **Shift** |
| Aim | **Mouse** |
| Use item (chop, mine, attack, shoot, place) | **Left mouse** |
| Quick-eat best food | **Right mouse** |
| Select hotbar slot | **1–3** or **mouse wheel** (or click the hotbar) |
| Interact (cook meat, add wood to fire, pick berries) | **E** |
| Inventory & crafting | **I** (or **C**) |
| Skill tree | **K** |
| World map | **M** |
| Journal (goals) | **J** |
| Pause / close window | **Esc** |

You can rebind keys under **Settings → Controls**.

## Survival basics
- **Health, Hunger, Warmth, Stamina.** Hunger and warmth drain over time. At zero they start hurting you.
- **Cold** gets much worse at night. Stand near a **campfire** to warm up. A **torch** and a **fur cloak** slow the chill.
- **Food:** lingonberries from bushes; raw meat from deer, hares and wolves. Cook meat at a fire (press E). Raw meat makes you sick.
- **Wolves** hunt at night, and more of them come each day. They won't come near a burning fire and are wary of torches.
- **Crafting:** arrows, torch, campfire, spear, bow, fur cloak.
- Fires burn out. Press **E** next to one to add wood.
- Walking on frozen lakes is slippery.

## The wilderness
- **Trees:** Scots pines, Norway spruces and white winter **birches**. Birches give **birch bark**, and spruces sometimes drop **spruce tips**.
- **Iron ore:** red-veined boulders in the far woods (away from the start). Mine them for iron ore.
- **Animals:** wolves (hunt at night, fear fire), **brown bears** (rare, territorial and very dangerous; they drop a bear pelt),
  deer, hares and **foxes** (fox fur).
- **Rune stones:** six carved stones with pieces of lore. Reading one (E) gives XP.
- **Abandoned cabins:** four trapper cabins, each with a chest of supplies.
- **Ice fishing:** equip a fishing rod and click a frozen lake to cast. When the bobber dips and **!** appears, click to reel in.
- **Blizzards:** from day 2, blizzards can roll in. You lose warmth almost twice as fast and can see less.

## Crafting
Arrows, torch, campfire, spear, bow, fishing rod, birch bandages (heal over time), spruce-tip tea (no cold for 2 minutes),
fur cloak, fox fur hat, **lavvu shelter**, iron axe, iron pickaxe and bear pelt cloak.
Tea and iron tools need a **burning campfire** nearby. Raw meat and fish are cooked at a campfire with E.

**Sleeping:** place a shelter next to a campfire. At night, press E at the shelter to sleep until dawn
(restores health and stamina, costs some hunger, and wolves nearby wander off).

## Journal
The journal (J) has 14 goals, from "Gather 10 wood" to "Slay a brown bear" and "Survive seven days". Each pays out XP.
The next unfinished goal is shown under your stats.

## Inventory & hotbar
Everything you carry is in the **inventory** (I). The HUD has **3 hotbar slots**: drag an item from the
inventory onto a slot, hover an item and press 1–3, or use the Slot buttons in the item details.
Right-click a hotbar slot in the inventory to clear it. Crafting is on the right of the inventory window.
Crafting a campfire puts you straight into **placement mode**: left click to build it, right click to cancel.

## XP & skill tree
You earn XP for chopping, mining, foraging, hunting (hare 5, deer 12, wolf 25), crafting, cooking,
building fires and surviving each night (+40 at dawn). Every level gives a skill point to spend in the
skill tree (K). It has three branches:
- **Woodcraft:** Lumberjack, Stonebreaker, Firekeeper, Bountiful
- **Hunter:** Keen Edge, Marksman, Butcher, Wolfbane
- **Survivalist:** Thick Blood, Iron Stomach, Endurance, Vitality

## Map & waypoints
The minimap (top right) shows trees, lakes, campfires, animals and your waypoints; off-screen waypoints
point from the edge. The fullscreen map (M) pauses the game and reveals only what you have explored.
Left click to place a waypoint (up to 12), right click to remove one, scroll to zoom and drag to pan.
Each waypoint also plants a coloured flag in the world.

## Saving
There are **3 save slots**. From the main menu:
- **Continue** loads your most recent save.
- **New Game** lets you pick a slot. Picking a used slot asks before overwriting it.
- **Load Game** lists the slots with day, level, difficulty, play time and when you last saved. You can also delete a save there.

The game **autosaves every dawn** and when you choose **Save & Quit to Menu** or close the window. You can also save anytime
from the pause menu (Esc). If you die, you can load your last save or start a new game in the same slot.

A save stores the world seed plus everything that changed: felled trees, broken rocks, picked bushes, campfires and their fuel,
items on the ground, animals, the explored map, waypoints, time of day, and your stats, inventory, hotbar, XP and skills.
Saves are JSON files in Godot's user folder (`user://saves/`), which on Windows is
`%APPDATA%\Godot\app_userdata\Frostwood\saves`.

## Main menu & settings
Continue, New Game, Load Game, How to Play, Settings, Credits, Quit. Settings has four tabs:
- **Audio:** master, music, sound effects and ambience volume.
- **Video:** fullscreen, VSync, FPS counter, screen shake, night brightness.
- **Gameplay:** difficulty (Easy/Normal/Hard), damage numbers, your longest survival.
- **Controls:** key rebinding, with reset to defaults.

Settings and your best score are saved to `user://settings.cfg`.

## Audio
All music and sound is generated by `tools/generate_audio.py` (Python + numpy + scipy + ffmpeg).
- **Music:** separate menu, day and night themes, built from kantele-style plucked strings, drones, flute, birch-bark horn and frame drum in D minor. The music crossfades at dusk and dawn.
- **Ambience:** wind, forest birdsong and a woodpecker by day, and crackling campfires heard in 2D space.
- **Sound effects:** chopping, mining, swings, bow and arrows, snow footsteps, wolf howls and growls, eating, crafting, UI clicks, a dawn horn call, and more.

To regenerate the audio: `python3 tools/generate_audio.py` (or only some sounds: `python3 tools/generate_audio.py tree_fall level_up`)

## Project layout
```
scenes/            main_menu.tscn, game.tscn (thin scenes, built in code)
scripts/autoload/  settings.gd (options, buses, key bindings), audio.gd (sfx/music/ambience), fader.gd,
                   save_manager.gd (save slots)
scripts/ui/        main menu, animated aurora background, settings, pause menu, death screen, theme
scripts/game/      game (world gen, day/night, spawning), player, animals, trees, boulders, bushes,
                   campfire, arrows, item drops, HUD, ground, item & recipe database
assets/audio/      generated .ogg music/ambience and .wav effects
assets/fonts/      Cinzel + Alegreya Sans (OFL)
tools/             generate_audio.py
```
All graphics are vector shapes drawn in code, so there are no image files.

## Fonts
[Cinzel](https://fonts.google.com/specimen/Cinzel) (headings) and [Alegreya Sans](https://fonts.google.com/specimen/Alegreya+Sans)
(text), both under the SIL Open Font License. The licence files are in `assets/fonts/`.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.6 game project using **Maaack's Game Template** plugin. The template provides a complete menu system, options, pause functionality, credits, scene loading, and game state management.

Project name: "MainTitle"

## Running the Game

Open the project in Godot 4.6+ editor and press F5 to run. The main scene starts at `res://scenes/opening/opening.tscn`.

To run in headless mode or from command line:
```bash
godot --path . --headless
godot --path .  # Run with display
```

## Architecture

### Scene Flow
```
Opening (opening.tscn) 
  -> Main Menu (main_menu_with_animations.tscn)
    -> Game Scene (game_ui.tscn)
      -> End Credits (end_credits.tscn)
```

Scene paths are configured in `addons/maaacks_game_template/base/nodes/autoloads/app_config/app_config.tscn` under the AppConfig node.

### Autoloads (Singletons)
These are automatically loaded at game start and available globally:

- **AppConfig**: Configuration management, loads/saves settings from config file
- **SceneLoader**: Handles scene loading with optional loading screens
- **ProjectMusicController**: Manages background music transitions between scenes
- **ProjectUISoundController**: Automatically attaches sounds to UI elements

### Custom State Management
The project uses a state persistence system:

- **GameState** (`scripts/game_state.gd`): Tracks level progress, checkpoints, play time, and per-level states
- **LevelState** (`scripts/level_state.gd`): Stores level-specific data (color, tutorial read status, etc.)
- **LevelAndStateManager** (`scripts/level_and_state_manager.gd`): Extends template's LevelManager to sync with GameState

State is persisted via `GlobalState` autoload (from template).

### Directory Structure

- `scenes/` - All scene files (.tscn)
  - `opening/` - Opening sequence
  - `menus/` - Main menu, options menu, level select
  - `game_scene/` - Main game UI, levels, tutorials
  - `credits/`, `end_credits/` - Credits screens
  - `windows/` - Popup windows (win/lose, tutorials)
  - `loading_screen/` - Loading screens
- `scripts/` - GDScript files for custom game logic
- `assets/` - Visual assets (logos, images)
- `resources/` - Godot resources (themes, etc.)
- `addons/maaacks_game_template/` - The template plugin (don't modify directly)

## Internationalization/Localization

### Current Translations
The template includes English and French translations:
- `addons/maaacks_game_template/base/translations/menus_translations.csv` - Source translation file
- `addons/maaacks_game_template/base/translations/menus_translations.en.translation` - English
- `addons/maaacks_game_template/base/translations/menus_translations.fr.translation` - French

### Adding Chinese Translation

1. Edit `addons/maaacks_game_template/base/translations/menus_translations.csv` to add a `zh_CN` column
2. Generate the .translation file in Godot by reimporting the CSV
3. Add the new translation to `project.godot`:
   ```
   [internationalization]
   locale/translations=PackedStringArray(
       "res://addons/maaacks_game_template/base/translations/menus_translations.en.translation",
       "res://addons/maaacks_game_template/base/translations/menus_translations.fr.translation",
       "res://addons/maaacks_game_template/base/translations/menus_translations.zh_CN.translation"
   )
   ```

For custom game text outside the template, create your own translation CSV files in a `translations/` folder and add them to the project settings.

## Input System

The game supports both keyboard/mouse and gamepad input:

**Custom Game Actions** (defined in `project.godot`):
- `move_up` - W key / Left stick up
- `move_down` - S key / Left stick down
- `move_left` - A key / Left stick left
- `move_right` - D key / Left stick right
- `interact` - E key / A button (gamepad)

**UI Actions** (template-provided):
- `ui_accept`, `ui_cancel`, `ui_page_up`, `ui_page_down`

Input remapping is handled by the template's options menu.

## Template Integration

### Pause Menu
The PauseMenuController node (in game_ui.tscn) automatically loads `pause_menu_layer.tscn` when the player presses `ui_cancel` (Escape).

### Level Management
- **LevelLoader** node loads level scenes into a container
- **LevelManager** handles level progression, win/lose conditions
- Levels are in `scenes/game_scene/levels/`

### Tutorials
- Tutorial windows are in `scenes/game_scene/tutorials/`
- TutorialManager script controls when tutorials appear
- Tutorial state is saved per-level via LevelState

### Credits
The credits system auto-generates from `ATTRIBUTION.md` using markdown parsing. Edit that file to update credits.

## Key Template Features

**Scene Loading**: Use `SceneLoader.load_scene(path)` for background loading with loading screens

**Music Blending**: The music controller automatically blends AudioStreamPlayer nodes when scenes change

**UI Sound Effects**: Automatically applied to buttons, sliders, etc. by ProjectUISoundController

**Persistent Settings**: Video, audio, and input settings are saved automatically via AppConfig

## Configuration Files

- `project.godot` - Main Godot project configuration
- `override.cfg` - Project override settings
- `default_env.tres` - Default environment settings
- `default_bus_layout.tres` - Audio bus configuration

## Setup Wizard

The template provides a setup wizard at `Project > Tools > Run Maaack's Game Template Setup...` for initial configuration and updates.

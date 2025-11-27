# Sound Assets Guide

The KryptoClaw Theme Engine now supports theme-specific sound effects. To enable these sounds, please add audio files (mp3, wav, m4a, caf) to your Xcode project's main bundle with the following filenames.

## Global / Default Sounds
If a theme does not specify a sound, it defaults to `nil` (silent) or falls back to system sounds.

## Theme-Specific Sound Filenames

### Elite Dark
- **Button Press**: `elite_click.mp3` (Mechanical, heavy click)
- **Success**: `elite_success.mp3` (Subtle, premium chime)
- **Error**: `elite_error.mp3` (Low frequency thud)
- **Tab Change**: `elite_tab.mp3` (Soft slide)

### Cyberpunk
- **Button Press**: `cyber_click.mp3` (High-tech beep)
- **Success**: `cyber_success.mp3` (Digital power-up)
- **Error**: `cyber_error.mp3` (Glitch noise)
- **Tab Change**: `cyber_tab.mp3` (Servo motor)

### Fire & Ash
- **Button Press**: `fire_click.mp3` (Crackle pop)
- **Success**: `fire_success.mp3` (Ignition swoosh)
- **Error**: `fire_error.mp3` (Extinguish hiss)
- **Tab Change**: `fire_tab.mp3` (Flame flicker)

### Water & Ice
- **Button Press**: `water_click.mp3` (Bubble pop)
- **Success**: `water_success.mp3` (Splash/Flow)
- **Error**: `water_error.mp3` (Ice crack)
- **Tab Change**: `water_tab.mp3` (Water drop)

## Implementation Details
The `SoundManager` (Sources/KryptoClaw/Core/SoundManager.swift) handles playback.
- It automatically looks for files with extensions: `mp3`, `wav`, `m4a`, `caf`.
- If a file is missing, it logs a warning to the console and may play a default system sound (Tock) for button presses.

## How to Add Sounds
1. Drag and drop your audio files into the `Resources` folder in Xcode.
2. Ensure "Add to targets" is checked for `KryptoClaw`.
3. Build and run.

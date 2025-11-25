# Theme Visual Guide

## Quick Reference: Theme Characteristics

### 🎯 Elite Dark (Signature - Default)
```
Background: Pitch black with diamond pattern overlay
Animation: None (precision focus)
Typography: SF Pro Bold (44pt balance, 12pt monospace address)
Corner Radius: 2px (razor-sharp)
Accent: Polished titanium (#D2DEE9)
Vibe: Surgical precision, weaponized minimalism
```

### 💜 Cyberpunk (Classic)
```
Background: Deep violet with liquid refraction animation
Animation: Flowing neon blobs
Typography: Black monospace
Corner Radius: 3px
Accent: Hot magenta (#FF33BF)
Vibe: 80s retro-futuristic dystopia
```

### 🤍 Pure White (Minimalist)
```
Background: Warm white (#FCFAF7)
Animation: None (zen simplicity)
Typography: Rounded semibold
Corner Radius: 14px (soft curves)
Accent: Refined blue (#4085F4)
Vibe: Japanese minimalism, approachable luxury
```

### 👑 Luxury Monogram (Haute Couture)
```
Background: Deep cognac leather with diamond pattern
Animation: None (timeless elegance)
Typography: Serif medium
Corner Radius: 10px
Accent: 18K gold (#D9B340)
Vibe: Old-world opulence meets modern sophistication
```

### 🔥 Fire & Ash (Volcanic)
```
Background: Volcanic ash with ember particles
Animation: Fire particle drift
Typography: Heavy rounded
Corner Radius: 6px
Accent: Burning ember (#F25A1F)
Vibe: Intense, dramatic, smoldering power
```

### ❄️ Water & Ice (Aquatic)
```
Background: Deep ocean with flowing waves
Animation: Gentle water wave motion  
Typography: Light rounded (38pt)
Corner Radius: 20px (fluid organic)
Accent: Crystal blue (#5ABFEB)
Vibe: Serene depths, crystalline clarity
```

### 🌑 Obsidian Stealth (Ultra-Minimal)
```
Background: Pure black (#010101)
Animation: None (absolute stillness)
Typography: Thin monospace (32pt)
Corner Radius: 0px (no rounding)
Accent: Barely visible (#262626)
Vibe: Maximum stealth, invisible UI
```

### 🎖️ Stealth Bomber (Military HUD)
```
Background: Dark military green with diamond pattern
Animation: None (tactical focus)
Typography: Semibold monospace
Corner Radius: 1px
Accent: Radar green (#33FF33)
Vibe: Night-vision tactical interface
```

### 🌅 Golden Era (Vintage)
```
Background: Deep sepia with diamond pattern
Animation: None (timeless)
Typography: Serif
Corner Radius: 8px
Accent: Antique gold (#FFD700)
Vibe: 1920s luxury, aged elegance
```

### 🩸 Crimson Tide (Blood Red)
```
Background: Blood dark with liquid refraction
Animation: Flowing crimson waves
Typography: Heavy rounded
Corner Radius: 6px
Accent: Deep crimson (#E60033)
Vibe: Intense, visceral, powerful
```

### ⚡ Quantum Frost (Sci-Fi)
```
Background: Deep ice blue with water waves + diamond pattern
Animation: Crystalline wave motion
Typography: Ultra-light (36pt)
Corner Radius: 18px
Accent: Electric ice (#66D9FF)
Vibe: Futuristic, crystalline, quantum computing aesthetic
```

### 🌸 Neon Tokyo (Japanese Cyberpunk)
```
Background: Purple night with liquid refraction
Animation: Neon sign reflections
Typography: Black rounded
Corner Radius: 12px
Accent: Bright magenta (#FF0080)
Vibe: Shibuya crossing at midnight, neon overload
```

### ⚡ Cyberpunk Neon (Maximum Saturation)
```
Background: Pure black with fire particles
Animation: Electric particle storm
Typography: Black monospace (40pt)
Corner Radius: 2px
Accent: Electric yellow (#FFFF00)
Vibe: Maximum intensity, full neon assault
```

### 💚 Matrix Code (Terminal)
```
Background: Pure black
Animation: None (terminal stillness)
Typography: Regular monospace
Corner Radius: 0px
Accent: Matrix green (#33FF33)
Vibe: Hacker terminal, cascading code
```

### 🏢 Bunker Gray (Industrial)
```
Background: Concrete gray with diamond pattern
Animation: None (industrial stability)
Typography: Bold default
Corner Radius: 4px
Accent: Tan military (#B3A680)
Vibe: Fortified bunker, tactical operations
```

### 🍎 Apple Default (iOS Native)
```
Background: iOS gray (#F7F7F7)
Animation: None (system standard)
Typography: System semibold
Corner Radius: 10px
Accent: iOS blue (#007AFF)
Vibe: Familiar, comfortable, native iOS experience
```

---

## Animation Details

### Liquid Refraction
- **Used by**: Cyberpunk, Neon Tokyo, Crimson Tide
- **Effect**: 3 radial gradient blobs flowing in circular motion
- **Duration**: 20s loop
- **Performance**: GPU-accelerated, minimal CPU

### Fire Particles
- **Used by**: Fire & Ash, Cyberpunk Neon
- **Effect**: 15 glowing ember particles with varying opacity
- **Duration**: Static positions, subtle glow
- **Performance**: Lightweight, pre-rendered

### Water Waves
- **Used by**: Water & Ice, Quantum Frost
- **Effect**: 3 sine wave layers with phase shifting
- **Duration**: 8s loop per wave
- **Performance**: Path-based, hardware rendered

### Diamond Pattern
- **Used by**: Elite Dark, Luxury Monogram, Stealth Bomber, Golden Era, Bunker Gray, Quantum Frost
- **Effect**: Repeating diamond grid overlay
- **Opacity**: 3-5% accent color
- **Performance**: Shape-based, cached

---

## Theme Switching

Themes can be changed from:
1. **Settings** → Appearance → Select theme
2. Changes apply instantly with smooth opacity + scale transition
3. All views automatically update via `@EnvironmentObject`

---

## Design Philosophy

Each theme is designed as a **complete visual world**:
- Consistent personality from onboarding through every interaction
- Typography matches theme character (elegant serif vs tactical monospace)
- Animations enhance but never distract
- Corner radius communicates precision (sharp) vs approachability (soft)
- Color psychology reinforces theme emotion

The result: **10 distinct visual experiences** in one app.

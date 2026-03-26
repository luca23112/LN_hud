# LN Hyper Modern RP HUD (FiveM)

Modernes HUD für FiveM RP-Server mit Support für:
- ESX
- QBCore
- Standalone (`LocalPlayer.state`)

## Features
- Vitals: Leben, Rüstung, Ausdauer
- RP Needs: Hunger, Durst, Stress
- Identity: Job, Cash, Bank, ID, Ping
- World: Straße, Kreuzung, Richtung, Uhrzeit
- Vehicle: Geschwindigkeit + Sprit
- Voice: Sprechstatus + Reichweite
- `/hud` Command zum Ein-/Ausblenden

## Installation (txAdmin)
1. Ordnername exakt setzen: `ln_hyper_modern_rp_hud`.
2. Resource so ablegen, dass `fxmanifest.lua` **direkt im Resource-Root** liegt:
   ```
   resources/[hud]/ln_hyper_modern_rp_hud/fxmanifest.lua
   ```
3. In `server.cfg` hinzufügen:
   ```cfg
   ensure ln_hyper_modern_rp_hud
   ```
4. Server/txAdmin neu starten oder Resource neu scannen.

## Troubleshooting: "wird nicht als Resource erkannt"
- Prüfen, ob du **keinen zusätzlichen Unterordner** hast (z. B. `ln_hyper_modern_rp_hud/ln_hyper_modern_rp_hud/fxmanifest.lua`).
- Prüfen, ob `fxmanifest.lua` vorhanden ist.
- Für ältere Setups liegt zusätzlich `__resource.lua` als Fallback im Root.

## Data Sources
- QBCore: `PlayerData.metadata`, `PlayerData.money`
- ESX: `ESX.GetPlayerData().accounts` + `LocalPlayer.state`
- Standalone: `LocalPlayer.state`

## Preview
![HUD Preview](preview/hud_preview.svg)

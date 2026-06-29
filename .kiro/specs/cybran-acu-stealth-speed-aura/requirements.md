# Requirements Document

## Introduction

This feature adds a new enhancement (upgrade) for the Cybran Armored Command Unit (ACU, blueprint `URL0001`) for Supreme Commander: Forged Alliance Forever (FAF). The enhancement projects an **aura** around the Cybran ACU that benefits nearby allied units with two effects:

1. **Radar stealth** (equivalent to the Cybran personal stealth effect) applied to eligible allied units inside the aura radius.
2. A **movement speed boost** applied to eligible allied land and naval units, scaled inversely by tech tier (Tech 1 receives the largest boost, Tech 2 less, Tech 3 the smallest).

Eligibility rules differ by unit class: land and naval units receive both stealth and the speed boost; air units receive stealth only; Sub-Commanders (SACU) and Experimental units receive neither effect. The aura is a toggleable, energy-consuming enhancement modeled after existing ACU aura enhancements (the Seraphim `RegenAuraSeraphim` / `AdvancedRegenAuraSeraphim` family) and the existing Cybran personal stealth enhancement (`StealthGeneratorCybran`).

This document specifies the observable behavior of the enhancement. Concrete balance values (radius, speed-boost percentages per tier, energy upkeep, cost, build time, slot, prerequisite, and the chosen icon) are not yet decided and are captured as explicit assumptions and open questions in the final sections. Implementation details (blueprint edits, aura script, icon mapping, and localization) are recorded as context only and are not part of these requirements.

## Glossary

- **Cybran_ACU**: The Cybran Armored Command Unit, blueprint identifier `URL0001`.
- **Stealth_Speed_Aura**: The new enhancement defined by this feature, installable on the Cybran_ACU.
- **Aura**: The circular area centered on the Cybran_ACU within which the Stealth_Speed_Aura applies its effects, bounded by the Aura_Radius.
- **Aura_Radius**: The horizontal distance from the Cybran_ACU within which an allied unit is considered inside the Aura. Value is an open decision (see Open Questions).
- **Eligible_Ground_Unit**: An allied LAND or NAVAL unit of tech tier Tech 1, Tech 2, or Tech 3 that is not a Sub_Commander and not an Experimental_Unit.
- **Eligible_Air_Unit**: An allied AIR unit of tech tier Tech 1, Tech 2, or Tech 3 that is not a Sub_Commander and not an Experimental_Unit.
- **Sub_Commander**: A Support Armored Command Unit (SACU / SUBCOMMANDER category).
- **Experimental_Unit**: A unit belonging to the EXPERIMENTAL category.
- **Radar_Stealth**: The radar stealth intel effect (the `RadarStealth` intel toggle in the engine), which conceals a unit from enemy radar.
- **Speed_Boost**: A multiplicative increase applied to a unit's movement speed (and matching acceleration) via the engine speed multiplier, expressed as a positive percentage above the unit's base movement speed.
- **Tech_Tier**: The technology tier classification of a unit, one of Tech 1 (TECH1), Tech 2 (TECH2), or Tech 3 (TECH3).
- **Remove_Enhancement**: The companion uninstall enhancement that removes the Stealth_Speed_Aura from the Cybran_ACU and reverts its effects.
- **Energy_Upkeep**: The continuous energy consumption per second incurred by the Cybran_ACU while the Stealth_Speed_Aura is active.
- **Localization_String**: A `Unit_Description_XXXX` style localized text entry used for the enhancement name and description.

## Requirements

### Requirement 1: Enhancement availability on the Cybran ACU

**User Story:** As a Cybran player, I want a new aura enhancement available on my ACU, so that I can support nearby allied forces with stealth and increased mobility.

#### Acceptance Criteria

1. THE Cybran_ACU SHALL offer the Stealth_Speed_Aura as a selectable enhancement in its enhancement menu.
2. WHEN a player selects the Stealth_Speed_Aura and its build completes, THE Cybran_ACU SHALL install the Stealth_Speed_Aura and begin applying all Aura effects within 1 second of installation.
3. WHILE the Stealth_Speed_Aura is installed, THE Cybran_ACU SHALL offer a Remove_Enhancement that uninstalls the Stealth_Speed_Aura.
4. WHEN the Remove_Enhancement build completes, THE Cybran_ACU SHALL uninstall the Stealth_Speed_Aura and cease all Aura effects within 1 second of uninstallation.
5. WHERE prerequisite enhancements are configured for the Stealth_Speed_Aura, THE Cybran_ACU SHALL offer the Stealth_Speed_Aura only after all configured prerequisite enhancements are installed.
6. IF the Stealth_Speed_Aura build is canceled or interrupted before completion, THEN THE Cybran_ACU SHALL not install the Stealth_Speed_Aura and SHALL not apply any Aura effects.

### Requirement 2: Aura activation, deactivation, and energy upkeep

**User Story:** As a Cybran player, I want to toggle the aura on and off and understand its energy cost, so that I can manage my economy while supporting allies.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is installed, toggled on, and sufficient energy is available, THE Stealth_Speed_Aura SHALL apply its effects to eligible allied units inside the Aura.
2. WHILE the Stealth_Speed_Aura is installed and toggled on, THE Cybran_ACU SHALL consume the configured Energy_Upkeep per second.
3. WHEN the Stealth_Speed_Aura is toggled off, THE Stealth_Speed_Aura SHALL remove its Radar_Stealth effect from all affected allied units.
4. WHEN the Stealth_Speed_Aura is toggled off, THE Stealth_Speed_Aura SHALL remove its Speed_Boost effect from all affected allied units and restore their base movement speed.
5. WHEN the Stealth_Speed_Aura is toggled off, THE Cybran_ACU SHALL stop consuming the Energy_Upkeep associated with the Stealth_Speed_Aura.
6. IF available energy is insufficient to sustain the Energy_Upkeep, THEN THE Stealth_Speed_Aura SHALL remove its Radar_Stealth and Speed_Boost effects, stop consuming the Energy_Upkeep, and remain toggled on.
7. WHEN energy is restored to a sufficient level while the Stealth_Speed_Aura remains toggled on, THE Stealth_Speed_Aura SHALL resume applying its effects.

### Requirement 3: Radar stealth effect for allied ground and naval units

**User Story:** As a Cybran player, I want my nearby allied land and naval units to gain radar stealth, so that they are harder for the enemy to detect.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply Radar_Stealth to every Eligible_Ground_Unit whose horizontal distance from the Cybran_ACU is less than or equal to the Aura_Radius.
2. WHEN an Eligible_Ground_Unit enters the Aura while the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply Radar_Stealth to that unit within 1 second.
3. WHEN an Eligible_Ground_Unit leaves the Aura, THE Stealth_Speed_Aura SHALL remove the Aura-provided Radar_Stealth from that unit within 1 second.
4. IF an Eligible_Ground_Unit holds Radar_Stealth from another source when the Aura-provided Radar_Stealth is removed, THEN THE Stealth_Speed_Aura SHALL NOT remove the Radar_Stealth provided by that other source.

### Requirement 4: Radar stealth effect for allied air units

**User Story:** As a Cybran player, I want my nearby allied air units to gain radar stealth without a speed change, so that air support is concealed while remaining balanced.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply Radar_Stealth within 1 second to every Eligible_Air_Unit whose position is inside the Aura boundary.
2. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL leave the movement speed of every Eligible_Air_Unit inside the Aura unchanged from its base movement speed.
3. WHEN an Eligible_Air_Unit crosses from inside to outside the Aura boundary, THE Stealth_Speed_Aura SHALL remove the Aura-provided Radar_Stealth from that unit within 1 second.
4. WHEN the Stealth_Speed_Aura deactivates, THE Stealth_Speed_Aura SHALL remove the Aura-provided Radar_Stealth within 1 second from every Eligible_Air_Unit that received it.
5. IF a unit located inside the Aura boundary is not an Eligible_Air_Unit, THEN THE Stealth_Speed_Aura SHALL NOT apply Radar_Stealth to that unit.

### Requirement 5: Movement speed boost for allied ground and naval units

**User Story:** As a Cybran player, I want my nearby allied land and naval units to move faster, so that lower-tier forces can keep pace and maneuver effectively.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply a Speed_Boost to every Eligible_Ground_Unit located inside the Aura.
2. WHEN an Eligible_Ground_Unit enters the Aura while the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply the Speed_Boost to that unit.
3. WHEN an Eligible_Ground_Unit leaves the Aura, THE Stealth_Speed_Aura SHALL remove the Aura-provided Speed_Boost from that unit, leaving its movement speed equal to what it would be without the Stealth_Speed_Aura.
4. WHEN the Stealth_Speed_Aura is uninstalled or toggled off, THE Stealth_Speed_Aura SHALL remove the Aura-provided Speed_Boost from every previously affected Eligible_Ground_Unit, leaving each unit's movement speed equal to what it would be without the Stealth_Speed_Aura.

### Requirement 6: Inverse per-tier scaling of the speed boost

**User Story:** As a player concerned with balance, I want the speed boost to favor low-tier units, so that the enhancement helps early-game forces more than late-game forces.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply a Tech 1 Speed_Boost whose percentage value is strictly greater than the Tech 2 Speed_Boost percentage value by at least 1 percentage point.
2. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply a Tech 2 Speed_Boost whose percentage value is strictly greater than the Tech 3 Speed_Boost percentage value by at least 1 percentage point.
3. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply each per-tier Speed_Boost as a percentage of the affected Eligible_Ground_Unit's base movement speed that is strictly greater than 0% and no greater than 100%.
4. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL select the Speed_Boost percentage for a given Eligible_Ground_Unit solely from the Tech 1, Tech 2, or Tech 3 value that matches that unit's Tech_Tier.
5. IF an Eligible_Ground_Unit has no resolvable Tech_Tier among Tech 1, Tech 2, or Tech 3 while the Stealth_Speed_Aura is active, THEN THE Stealth_Speed_Aura SHALL apply no Speed_Boost to that unit and leave its base movement speed unchanged.

### Requirement 7: Excluded unit classes

**User Story:** As a player concerned with balance, I want command units and experimental units excluded from the aura, so that the enhancement does not become overpowered.

#### Acceptance Criteria

1. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL exclude every Sub_Commander from the Radar_Stealth effect, even while that Sub_Commander is located within the Stealth_Speed_Aura effect radius.
2. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL exclude every Sub_Commander from the Speed_Boost effect, even while that Sub_Commander is located within the Stealth_Speed_Aura effect radius.
3. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL exclude every Experimental_Unit from the Radar_Stealth effect, even while that Experimental_Unit is located within the Stealth_Speed_Aura effect radius.
4. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL exclude every Experimental_Unit from the Speed_Boost effect, even while that Experimental_Unit is located within the Stealth_Speed_Aura effect radius.
5. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply its effects only to units that belong to the Cybran_ACU owner or to players allied with the Cybran_ACU owner, and SHALL apply no effect to any enemy or neutral unit.
6. WHEN a unit currently receiving the Radar_Stealth effect or the Speed_Boost effect ceases to be allied with the Cybran_ACU owner, THE Stealth_Speed_Aura SHALL remove both the Radar_Stealth effect and the Speed_Boost effect from that unit.

### Requirement 8: Aura radius and balance bounds

**User Story:** As a player concerned with balance, I want the aura radius tuned to a sensible range, so that the enhancement is neither overpowered nor not worth building.

#### Acceptance Criteria

1. THE Stealth_Speed_Aura SHALL determine unit eligibility using the Aura_Radius measured as the horizontal distance, in the same distance units as the enhancement definition, from the Cybran_ACU position, disregarding any vertical height difference between the unit and the Cybran_ACU.
2. THE Aura_Radius SHALL be a fixed value greater than zero, configured in the enhancement definition, and SHALL remain unchanged for the entire duration that the Stealth_Speed_Aura is installed.
3. THE Aura_Radius SHALL be within the inclusive range of 20 to 40 (bounding the reference enhancement radii of 30 and 35).
4. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL apply effects only to eligible allied units whose horizontal distance from the Cybran_ACU is less than or equal to the Aura_Radius.
5. WHILE the Stealth_Speed_Aura is active, THE Stealth_Speed_Aura SHALL NOT apply any effect to a unit whose horizontal distance from the Cybran_ACU is greater than the Aura_Radius.

### Requirement 9: Bilingual localization

**User Story:** As a bilingual player and maintainer, I want the enhancement name and description available in Russian and English, so that the upgrade reads correctly in both supported languages.

#### Acceptance Criteria

1. THE Stealth_Speed_Aura SHALL provide a non-empty Localization_String for its name in Russian and a non-empty Localization_String for its description in Russian.
2. THE Stealth_Speed_Aura SHALL provide a non-empty Localization_String for its name in English and a non-empty Localization_String for its description in English.
3. THE Remove_Enhancement SHALL provide a non-empty Localization_String for its name and a non-empty Localization_String for its description in both Russian and English.
4. WHEN the enhancement interface displays the Stealth_Speed_Aura or the Remove_Enhancement while the active game language is Russian, THE enhancement interface SHALL show the Russian Localization_String for that enhancement's name and description.
5. WHEN the enhancement interface displays the Stealth_Speed_Aura or the Remove_Enhancement while the active game language is English, THE enhancement interface SHALL show the English Localization_String for that enhancement's name and description.
6. IF the Localization_String for the active game language is missing for the Stealth_Speed_Aura or the Remove_Enhancement, THEN THE enhancement interface SHALL display the English Localization_String for that enhancement.

### Requirement 10: Enhancement icon

**User Story:** As a player, I want the enhancement to display an icon in the ACU upgrade interface, so that I can recognize it among the other enhancements.

#### Acceptance Criteria

1. THE Stealth_Speed_Aura SHALL be assigned an icon identifier that references an icon already present in the game's existing enhancement icon set, without introducing a new icon asset.
2. WHEN the Stealth_Speed_Aura is displayed in the enhancement interface in any of its states (available, building, or installed), THE enhancement interface SHALL display the icon referenced by the assigned icon identifier.
3. IF the assigned icon identifier does not resolve to an icon in the existing enhancement icon set, THEN THE enhancement interface SHALL display a placeholder icon and SHALL keep the Stealth_Speed_Aura selectable.
4. THE Remove_Enhancement SHALL be assigned an icon identifier that references an icon already present in the game's existing enhancement icon set.
5. WHEN the Remove_Enhancement is displayed in the enhancement interface, THE enhancement interface SHALL display the icon referenced by its assigned icon identifier.

## Assumptions

- The enhancement reuses the established ACU aura mechanism (periodic scan of allied units within a radius and application of a buff), consistent with the Seraphim `RegenAuraSeraphim` family.
- Radar stealth is applied via the engine's existing radar-stealth intel mechanism, equivalent in effect to the Cybran personal stealth (`StealthGeneratorCybran`).
- The speed boost is applied via the engine's speed multiplier (the buff system's `MoveMult` affect, which sets both speed and acceleration multipliers).
- "Naval units" (the user's "ладки"/boats) refers to units in the NAVAL category; amphibious and hover land units are treated as land units for eligibility.
- Tech tiers in scope are Tech 1, Tech 2, and Tech 3; SACU and Experimental are explicitly out of scope for both effects.
- The aura applies only to allied units, consistent with the friendly-only targeting used by existing ACU auras.

## Open Questions (Decisions to Capture)

These items are not yet decided and must be resolved during design or balancing. Each will be confirmed before implementation values are finalized.

1. **Aura_Radius**: Exact value (reference points: Seraphim `RegenAuraSeraphim` Radius = 30, `AdvancedRegenAuraSeraphim` Radius = 35). Target a balanced value that is useful but not overpowered.
2. **Speed_Boost percentages per tier**: Exact Tech 1 / Tech 2 / Tech 3 percentages, all small and in strictly descending order (T1 > T2 > T3 > 0).
3. **Energy_Upkeep**: Energy consumed per second while active (reference: Cybran `StealthGeneratorCybran` = 50 e/s; aura enhancements consume more).
4. **Build cost** (mass and energy) and **build time** for both the Stealth_Speed_Aura and its Remove_Enhancement.
5. **Enhancement slot**: One of RCH, LCH, or Back.
6. **Prerequisite**: Whether the enhancement requires a prior enhancement (and which), or has none.
7. **Icon**: Which existing icon identifier to assign (user will choose later).
8. **Stealth detail**: Whether the aura grants radar stealth only, or also sonar stealth for naval units (the Cybran personal stealth enhancement toggles both RadarStealth and SonarStealth). Current scope assumes radar stealth only unless decided otherwise.

## Implementation Context (Non-Normative)

The following files are expected to be touched during implementation and are listed for reference only; they are not requirements:

- `units/URL0001/URL0001_unit.bp` — Enhancements block: add the Stealth_Speed_Aura and its Remove variant.
- `units/URL0001/URL0001_script.lua` — `ProcessEnhancement...` handlers plus an aura scan/apply thread, modeled on `units/XSL0001/XSL0001_script.lua` (`RegenBuffThread`, `GetUnitsToBuff`, `ProcessEnhancementRegenAuraSeraphim`).
- `lua/sim/Buff.lua` — existing `MoveMult` affect handles the speed multiplier.
- `lua/ui/help/unitdescription.lua` — icon mapping for the new enhancement.
- `loc/RU/strings_db.lua` and `loc/US/strings_db.lua` — `Unit_Description_XXXX` localization strings (Russian and English).

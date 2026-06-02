# Phase 3 Build Plan — Dungeon-Crawler Extraction Roguelike

**Status:** Build plan drafted 2026-06-02. Maps the locked design in `dungeon-crawler-direction.md` onto concrete Godot scenes/scripts **against the existing Phase 1/2 codebase** (which is more complete than the design doc assumes — see §0).

**How to read this:** §0 is what already exists (don't rebuild it). §1 is the design→code delta. §2 is the handful of decisions that must be settled before/while building. §3 is the proposed file layout. §4 is the milestone sequence (vertical-slice-first). §5 is cross-cutting work. §6 is the first PR.

**The one invariant, restated for the build:** every answer a player gives — in a normal encounter, an elite, the extraction gauntlet, the boss — routes through `GameState.review_scheduler.record_review(card_id, challenge_type, rating, now)` on the **first attempt**, win or lose. That call is the honest FSRS commit. No combat shortcut, no retry, ever bypasses it. Build everything else around that line.

---

## 0. Reality Check — What Already Exists (reuse, don't rebuild)

The Phase 1/2 spine is production-grade and directly reusable. Key APIs (verified in-tree):

| System | Files | Reusable API surface |
|---|---|---|
| **FSRS core** | `src/srs/fsrs_algorithm.gd`, `card_state.gd`, `review_scheduler.gd`, `pack_curator.gd`, `srs_config.gd` | `ReviewScheduler.record_review(card_id, challenge_type, rating, now)` ← **the honest commit**; `get_due_cards(now)`, `get_about_to_forget_cards(now)`, `select_challenge_type(card_id)`, `get_loot_rarity(...)`, `serialize_all()/deserialize_all()`. `CardState.states` already tracks **per-challenge-type** FSRS (meaning/character/pinyin/tone) and exposes `get_weakest_challenge_type()`, `get_retrievability()`, `get_max_stability()`. |
| **Global SRS instance** | `src/autoload/game_state.gd` | `GameState.review_scheduler` (the live scheduler), `GameState.character_db`, `GameState.radical_db`. Registered on boot. |
| **Data layer** | `src/database/character_data.gd`, `character_database.gd`, `radical_*.gd`, `data_loader.gd` | `CharacterData{character,pinyin,tone,meaning,hsk_level,radicals,components,is_radical,frequency_rank}`; `CharacterDatabase` indexes by char/hsk/radical/tone/pinyin **and ships distractor helpers**: `get_same_radical_characters()`, `get_similar_pinyin_characters()`, `get_same_tone_characters()`, `get_random_same_level()`. Data for **HSK 2–5 already exists** under `data/`. |
| **Collection / binder** | `src/progression/collection_grid.gd`, `player_profile.gd`, `collection_enums.gd` | `CollectionGrid` = the binder (LOCKED→…→LEGENDARY tier per char, derived live from SRS stability). `PlayerProfile` tracks mastery %, runs, accuracy. **No card-instance or PSA-grade layer exists** — tiers are computed, not stored (see D3). |
| **Answer input** | `src/swipe/swipe_detector.gd`, `answer_generator.gd`, `card_display.gd`, `challenge_enums.gd` | `SwipeDetector.swipe_completed(direction)`; `AnswerGenerator.generate_answers(card_data, challenge_type) → {up,down,left,right,correct_direction,correct_answer}` with semantic distractors; `CardDisplay.setup_for_challenge()` + the tested-field-hidden visibility contract + correct/wrong/animate feedback. **This is the reusable "answer a card" widget for all combat.** |
| **Challenge + bonus chain** | `src/swipe/challenge_presenter.gd`, `src/bonus/bonus_round_manager.gd`, `bonus_trigger.gd`, `bonus_enums.gd` | `ChallengePresenter` orchestrates present→swipe→rate→(bonus chain)→`card_resolved`. `BonusRoundManager.start()/next_stage()/record_stage_result()/get_boosts()` is a **generic multi-stage challenge-chain state machine** — the direct basis for **mob-HP-as-facet-chain** and elite/boss bars. |
| **Run / session / haul** | `src/run/run_manager.gd`, `session_data.gd`, `hand_card.gd`, `round_manager.gd` | `SessionData.hand_cards: Array[HandCard]` + `record_card_resolution()` = **the embryonic extraction haul**; `RunManager.start_run()/on_card_answered()/on_card_resolved()/end_run()/get_run_summary()`. Note: current run = **5 fixed rounds of a curated pack** (RoundManager), which the dungeon replaces (see D1). |
| **Power** | `src/power/power_calculator.gd`, `power_boost.gd`, `power_enums.gd` | `PowerCalculator.total_power(rarity, boosts)`. **Caution:** `PowerEnums.BASE_POWER` is an *inverted* curve (weaker SRS card = stronger board power) — a Triple-Triad artifact that **contradicts** the Phase-3 flat-base model (see D2). |
| **Infra** | `src/autoload/{signal_bus,save_manager,audio_manager,screen_navigator,accessibility_manager}.gd` | `SignalBus` (cross-system signals — add Phase-3 ones here); `ScreenNavigator` (`SignalBus.screen_transition_requested(name)` → `change_scene_to_file` via `SCREEN_PATHS`); `SaveManager` (`save_game()`, `save_srs_data()` — extend schema for instances/currency/unlocks); GdUnit4 tests mirror `src/` 1:1. |

**Implication:** Phase 3 is mostly *new screens + a combat layer + a persistent economy*, bolted onto an SRS/data/input/save spine we keep intact. The biggest *new* thing is combat; the biggest *new data* thing is card instances + the economy.

---

## 1. Design → Code Delta

| Locked design element | Verdict | Notes |
|---|---|---|
| Honest FSRS, per-challenge-type | **Reuse as-is** | `record_review` + `CardState.states`. Wire every combat answer to it. |
| Data + distractors | **Reuse as-is** | `CharacterDatabase` distractor helpers feed `AnswerGenerator` and the connection-set craft. |
| Answer-a-card widget | **Reuse, lightly refactor** | Extract a lean `AnswerInput` core from `ChallengePresenter` (swipe + generate + rate + feedback) free of bonus/power coupling — see D5. |
| Mob HP = facet chain; elite/boss bar | **Reuse pattern** | `BonusRoundManager` is already a generic challenge-chain; generalize it into a `ChallengeChain` that combat drives. |
| Binder (Pokédex) | **Reuse as-is** | `CollectionGrid` already = "permanent, one entry/char, never destroyed, tier from SRS." |
| Card **instances** + PSA **grades** + **shards** | **Build new** | The disposable/stakeable layer. No equivalent exists. New data model + persistence (D3). |
| Loadout = 5-card stake (2 passive/3 active) | **Build new** | New `Loadout` + POS split + stake-on-entry/lose-on-death. |
| Dungeon run-map, depth, branches, room types | **Build new** | New screen + run controller. Replaces `RoundManager`'s 5-round loop. |
| JRPG combat: mobs w/ HP, target choice, retaliation, ATB | **Build new** | The single biggest new scene. Reuses the answer widget + chain. |
| Extraction gate, carry cap, greed tax, hearts | **Build new** | New run-state (hearts, haul, cap) + extraction gauntlet (reuses combat/review). |
| Town hub + 4 buildings | **Build new** | New screens (town, home, crafter, shop). |
| Crafting/grading (match-3, connection→ability, mastery loads roll) | **Build new** | New craft system + connection-set data. |
| Power model (correct = trigger; passive whole-run, active dmg-per-correct) | **Build new** | New effect engine; **rework `PowerEnums`** (D2). |
| Linguistics→ability tiers (Tier 1/2/3) | **Build new + data** | Mostly derivable (radical/tone/POS already in data); Tier-1 is ~100–150 hand-tags. |
| Boss cloze gauntlet | **Build new + data** | New boss controller + pre-authored sentence bank (new tool + data). |
| Meta progression (knowledge-gates + town-buys + bench; un-loseable) | **Build new** | New persistent meta layer + carry-cap stat. |

---

## 2. Architectural Decisions & Risks (settle these)

- **D1 — Dungeon vs. the existing pack-study loop — RESOLVED 2026-06-02: (a) dungeon becomes the primary loop.** The dungeon draws cards live from FSRS each room, so it *is* the spaced-rep delivery vehicle and subsumes the daily pack. The old `game_screen` is retired as the main flow — repurpose it later as an optional in-town "free review" station if wanted. M2's run entry replaces the menu→pack path with menu/town→dungeon. (Rejected: pack-study-as-draft, and both-as-separate-modes — both add a parallel loop to maintain for no FSRS gain.)
- **D2 — `PowerEnums.BASE_POWER` is inverted and must be reworked.** Today weaker cards = more board power (Triple-Triad logic). Phase 3 locks **flat base per effect; rarity does not scale base; grade sets magnitude**. Rework `power_enums.gd`/`power_calculator.gd` to the new model when M5 lands; until then combat can use a flat placeholder.
- **D3 — Instances are a new persisted layer, distinct from the derived-tier binder.** `CollectionGrid` stays the binder (knowledge, never lost). A new `CardInstance` (character + rarity + grade + authored ability + provenance) is the disposable/stakeable object. Binder = computed from SRS; instances = stored in inventory and saved. Don't conflate them.
- **D4 — `HandCard.base_power` semantics change.** Today power is frozen-at-draft from loot rarity. In Phase 3 a haul card is a **raw instance** (no power until graded); power comes from a graded instance's authored ability. Keep `HandCard`/haul as "what you carried out," drop its power coupling (folds into D2).
- **D5 — Extract a reusable `AnswerInput` from `ChallengePresenter`.** The presenter currently hard-wires the bonus roll and emits `card_resolved` with `base_power/boosts`. Combat wants only: present a (card, challenge_type) → capture swipe → rate → feedback → `answered(correct, rating)`. Extract that core so combat, extraction, and boss share it; let the old study flow keep the bonus wrapper.
- **D6 — Combat miss-handling / turn-order is tuning, but the honest invariant is fixed.** Whether a missed facet ends a mob chain, just costs a heart, or advances the ATB is open (logged in the design doc's "Encounter tuning"). Regardless, the **first attempt always `record_review`s**. Build the combat controller so the SRS commit is independent of the combat resolution rule.

---

## 3. Proposed Source Layout (new dirs alongside existing)

```
src/
  combat/      CombatController, Mob, ChallengeChain (generalized BonusRoundManager),
               TargetSelector, AtbClock        — the JRPG fight
  dungeon/     DungeonRun (run lifecycle: hearts, haul, depth, cap), RunMap,
               RoomNode, RoomType, DepthDraw (depth-biased FSRS draw)
  cards/       CardInstance, Inventory (the bench), GradeBand, RarityMap (HSK→rarity)
  economy/     Currency (shards), CraftSystem (match-3 grade), ConnectionSet, Shop
  loadout/     Loadout (5 slots, 2 passive/3 active, POS split), Stake
  abilities/   Effect, PassiveEffect, ActiveEffect, AbilityAuthor (connection→tier→ability)
  boss/        BossController, SentenceBank (cloze loader), ClozePrompt
  meta/        MetaProgress (unlocks, carry-cap, slot growth), KnowledgeMilestones
  swipe/       + AnswerInput (extracted core, D5)
scenes/screens/  town.tscn, home.tscn, crafter.tscn, shop.tscn,
                 dungeon_map.tscn, combat.tscn, boss.tscn   (+ register in ScreenNavigator.SCREEN_PATHS)
scenes/components/  mob.tscn, hp_bar.tscn, room_node.tscn, instance_card.tscn, loadout_slot.tscn
data/  sentences/ (cloze bank, per HSK), connections/ (phonetic series, semantic fields, tier-1 tags)
tools/  build_sentence_bank.py, build_connection_sets.py   (+ extend validate_data.py)
tests/  mirror every new src/ file (CLAUDE.md rule: every src/ file has a test)
```

---

## 4. Milestones — Vertical-Slice First

Sequenced so the **biggest unknown (combat) is proven first** and there is *something playable and FSRS-honest* after M1. Each milestone is a shippable increment.

### M1 — Combat vertical slice *(the de-risking milestone)*
**Goal:** fight one room of 1–3 HP mobs, honest FSRS, hearts, collect a haul. Hardcoded entry (no town/map yet), cards drawn flat from `get_due_cards`.
- **New:** `scenes/screens/combat.tscn` + `CombatController`; `Mob` (bound to a character, HP); `mob.tscn` + `hp_bar.tscn`; `TargetSelector` (tap/focus a mob); `ChallengeChain` (generalize `BonusRoundManager` — each HP point = a distinct facet); `AnswerInput` (extracted per D5).
- **Reuse:** `AnswerGenerator`, `SwipeDetector`, `CardDisplay`, `GameState.review_scheduler.record_review`, `SessionData.hand_cards`/`HandCard` for the haul, hearts as a simple int on a new `DungeonRun`.
- **Proves:** the JRPG loop (pick target → answer facet → 1 HP off → mob drops card; miss → retaliate, lose heart, no retry) and that combat answers commit to FSRS correctly.
- **Tests:** `ChallengeChain` (facet order, no-massing), `CombatController` (hit/retaliate/death/haul), `record_review` called once per first attempt.

### M2 — Run structure: dungeon map + extraction
**Goal:** a full run on the one pre-rendered map — segments → elite → extract gate → boss slot — with hearts, haul, depth, and a (fixed) carry cap.
- **New:** `dungeon_map.tscn` + `RunMap` (hand-built node graph, telegraphed branch icons), `RoomNode`/`RoomType` (encounter/trial/cache/elite/boss), `DungeonRun` (lifecycle: enter → traverse → extract-or-die), `DepthDraw` (deeper rooms pull lower-stability cards + harder challenge types via the scheduler), extraction gauntlet (reuses combat/review), carry-cap triage UI.
- **Reuse:** combat from M1 (elite = one bigger bar, N total hits); `RunManager`/`SessionData` shape for the haul + summary; `ResultsScreen` for the post-run debrief; `ScreenNavigator`.
- **Replaces:** `RoundManager`'s 5-round loop (per D1).
- **Proves:** push-your-luck (extract vs. descend), death = lose haul, depth gating.
- **Tests:** `RunMap` traversal/branching, `DepthDraw` bias, `DungeonRun` extract/death outcomes.

### M3 — Persistent economy: instances, grades, shards, inventory
**Goal:** the haul becomes **raw instances**; shards exist; inventory persists; death loses staked + haul instances.
- **New:** `CardInstance`, `Inventory` (bench), `RarityMap` (HSK→common/uncommon/rare/epic), `GradeBand`, `Currency` (shards); `SaveManager` schema bump (instances + shards + unlocks).
- **Reuse:** binder (`CollectionGrid`) unchanged; raw instance = `CharacterData` + rarity + ungraded.
- **Proves:** the two-layer model (D3) and the loss floor = instances, never binder.
- **Tests:** instance lifecycle, inventory save/load round-trip, death-loss rules.

### M4 — Town + loadout + crafting/grading
**Goal:** the hub loop — outfit a 5-card stake, grade via match-3, shatter for shards, shop for known-char instances/consumables.
- **New:** `town.tscn` + `home.tscn`/`crafter.tscn`/`shop.tscn`; `Loadout` (5 slots, 2 passive/3 active, POS split from `CharacterData` part-of-speech), `Stake`; `CraftSystem` (pick target + 3 connected instances + shard fee → PSA roll where **mastery loads the band**, **connection authors the ability**), `ConnectionSet`, `Shop`.
- **Reuse:** distractor helpers + `radical_db` to validate connection sets; binder for "already-encountered" shop gating; `PlayerProfile` mastery for the roll odds + the teaching-hook odds display.
- **Proves:** loadout = stake, grading-as-craft, the grade-band ceiling = `min(rarity-cap, mastery-cap)`.
- **Tests:** loadout POS split + stake assembly, craft roll within band, connection-set validity, shop "never new chars / never grades" rule.

### M5 — Abilities & power in combat
**Goal:** equipped power actually does something — passives = whole-run stats, actives = damage-per-correct-answer.
- **New:** `Effect`/`PassiveEffect`/`ActiveEffect`; `AbilityAuthor` (connection axis → Tier 1/2/3 → concrete effect); wire effects into `DungeonRun` (passives) and `CombatController` (actives). **Rework `PowerEnums`/`PowerCalculator`** to flat-base + grade-magnitude (D2).
- **Reuse:** radical/tone/POS already in `CharacterData` drives Tier 2/3 for free; Tier-1 needs the ~100–150 tag set (data).
- **Proves:** correct-answer-as-trigger; set-bonus identity (radical/tone decks); knowledge still the wall.
- **Tests:** effect application, flat-base power math, active damage = correct-answer-scaled.

### M6 — Boss: cloze gauntlet
**Goal:** the climax — fill blanks from your haul, selection-not-generation, review mixed in.
- **New + data:** `tools/build_sentence_bank.py` → `data/sentences/` indexed by blank-fill; `SentenceBank` loader; `BossController` (query haul-solvable sentences, min-haul gate → fall back to haul-review + binder distractors, blanks scale 2→5 by HSK), `ClozePrompt`; word-chaining super (validate against known-word dict).
- **Reuse:** combat HP-bar grammar (correct fill = hit); `AnswerInput`; haul as the answer bank.
- **Proves:** production-recall climax, the loop closure (haul = ammo), honest logging of every fill.
- **Tests:** bank query/indexing, min-haul fallback, blank-count scaling, chaining validation.

### M7 — Meta progression
**Goal:** the "why keep playing" ratchet — and the un-loseable guarantee.
- **New:** `MetaProgress` (persistent unlocks: slots, depth tiers, carry-cap raises), `KnowledgeMilestones` (binder/mastery thresholds gate unlocks), town-buys (meta-currency → slot/heart/cap/odds), bench-as-buffer. Carry cap becomes a real growing stat (M2's fixed cap reads from here).
- **Reuse:** `PlayerProfile`/`CollectionGrid` for milestone signals; `SaveManager` for persistence.
- **Proves:** death never touches binder/mastery/unlocks (the rage-quit killer); the three-axis blend.
- **Tests:** milestone→unlock gating, town-buy spend, **invariant test: a simulated death preserves binder + mastery + unlocks**.

---

## 5. Cross-Cutting Work

- **SignalBus additions** (keep cross-system comms going through it): `run_extracted(haul)`, `run_died(lost)`, `heart_lost(remaining)`, `mob_defeated(card_id)`, `instance_graded(instance, grade)`, `loadout_changed(loadout)`, `meta_unlocked(id)`, `room_entered(room_type, depth)`.
- **Save schema** (`SaveManager`): bump version; add `inventory` (instances), `shards`/meta-currency, `loadout`, `meta_unlocks`, `carry_cap`. SRS save stays its own file, untouched.
- **Data tooling**: `build_sentence_bank.py` (cloze), `build_connection_sets.py` (phonetic series + semantic fields + Tier-1 tags), extend `validate_data.py` to check the new sets and that every cloze answer exists in the char DB.
- **Tests**: every new `src/` file gets a `tests/` mirror (CLAUDE.md rule). Priority invariant tests: (1) every first-answer hits `record_review`; (2) death preserves binder/mastery/unlocks; (3) shop never sells new chars or grades; (4) grade band respects `min(rarity-cap, mastery-cap)`.
- **Scope guard (HSK 3):** load only HSK 1–3 for the rarity/ability mapping; HSK 4 = the epic stretch; 4–6 parked.

---

## 6. First PR — Start Here

**M1, narrowed to its spine**, in one branch:
1. Extract `AnswerInput` from `ChallengePresenter` (D5) — pure refactor, keep the study flow green.
2. Generalize `BonusRoundManager` → `ChallengeChain` (facet sequence, no-massing guarantee).
3. `CombatController` + `combat.tscn` + `mob.tscn`/`hp_bar.tscn`: one room, 1–3 mobs, target → answer facet → HP/retaliate → drop card, hearts, haul into `SessionData.hand_cards`.
4. Hardcode entry from a debug button; reuse `ResultsScreen` to show the haul.
5. Tests for `ChallengeChain` + `CombatController` + the `record_review` invariant.

That yields a **playable, FSRS-honest combat room** with zero new persistence — the riskiest piece de-risked first, everything else layered on a proven core.

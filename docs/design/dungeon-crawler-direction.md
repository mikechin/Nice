# Phase 3 Direction — Dungeon-Crawler Extraction Roguelike

**Status:** Design in progress (riffed 2026-06-02). Supersedes the Triple Triad board-game phase.
**Scope (locked 2026-06-02):** build target is **HSK 3** (~600 cumulative characters). HSK 4 is a stretch only where words stay concrete/straightforward; HSK 4–6 is parked. Locking low keeps the linguistics→mechanics mapping clean — phonetic series and radicals are densely populated, words stay 1–2 characters, and the collection is shippable/tunable.
**Relationship to `planning.md`:** The collection-first, SRS-as-engine, pack-opening core is unchanged. This document replaces the *Phase 3 board game* (Triple Triad) and **reverses one philosophy line**: `planning.md` says *"Learning first, game second."* The current direction is **game-first with an honest FSRS backend** (see Guiding Principle). Treat this doc as authoritative for Phase 3.

---

## Guiding Principle

> **Build a game with an FSRS backend, not a learning tool with game paint.**

Exactly one thing is non-negotiable: **the review signal feeding FSRS stays honest.** The instant the player answers a card, FSRS records the real result — win, lose, die, retry, whatever. Everything stacked on top (hearts, loss, random grades, staking) can be as gamey and punishing as the design wants. That clean signal is what makes the backend *real* instead of decorative, and it's the source of the long-term retention hook.

- **Missing a card = losing that chance for the card** in the run — **no retry; you move on (resolved 2026-06-02).** The FSRS grade logs that one attempt, always. Misses being final is what makes an encounter a *hunt* (defeat the mob, loot the card) instead of a combo-grind.
- FSRS remains the single source of truth for what a card is and how strong it is.

---

## The Core Loop

```
TOWN ──▶ enter dungeon ──▶ room-by-room (FSRS-drawn cards) ──▶ extract points ──▶ BOSS
  ▲                              │ miss = lose a heart                  │
  │                              │ 0 hearts = die = lose haul + stake   │
  │                         correct = stash a raw card copy             │
  │                                                                     │
  └──◀── grade / shatter / equip ◀── EXTRACT (answer your way out) ◀────┘
```

1. **Enter a run** with a loadout (equipped graded cards) and optionally **staked** graded instances to access deeper floors.
2. **Crawl room by room.** Each room is an FSRS-drawn card challenge (reusing `src/swipe/`). Correct → stash a *raw* (ungraded) copy. Miss → lose a heart.
3. **Hearts = mistakes allowed.** Lose them all → die → **lose the haul + any staked instances.** (FSRS still recorded every answer.)
4. **Extract only at extract points** (between depths) or by beating the boss — never mid-depth. This prevents bailing before the SRS-needed cards surface.
5. **Extraction = "answer your way out," up to your carry cap.** You can only extract your best **N** cards — the cap is a gear/meta stat that grows (see **Meta Progression**); triage the rest at the door. The escape is a review gauntlet over what you keep, with a **greed tax**: the fuller your bag toward the cap, the harder the escape (cap = the hard ceiling, greed tax = the cost curve up to it). Anti-hoarding + final tension spike + SRS reinforcement on the just-earned cards. You can die *at the door*.
6. **Back in town:** grade keepers (costs currency), shatter junk (yields currency), manage loadout, view the binder.

**Target run length:** 10–20 min ≈ 50–100 card answers — a large FSRS study session wearing a crawl costume.

**Rooms in a run (lean — not every type every run):** mostly encounter rooms, with occasional **elites** (HP-bar fights built on the existing bonus-round multi-stage chain), telegraphed **branch choices**, **extract points**, and a **boss** — see **Dungeon Structure** below. **Shops, rest, and the grade station live in TOWN**, not the dungeon. Keep the dungeon focused on the core verb: *answer a card, choose risk.*

---

## Dungeon Structure — One Hand-Built Run, Live-Drawn Cards

**Resolved 2026-06-02.** The "dungeon" is a **roguelike run-map** (Slay the Spire / FTL / Hades) wearing a Zelda *A Link to the Past* costume — discrete rooms, pick-a-door — **not** a spatial crawler. This is the right structure for a card game *and* far cheaper to ship. (The user arrived at this independently; naming it confirms it.)

**Ship 1.0 with ONE pre-rendered dungeon.** The *layout* is hand-built and fixed; the *cards filling each room are drawn live from FSRS every run.* Replayability is real without procedural generation — your due cards, loadout, branch picks, and chosen depth all vary run-to-run. **Procedural layout is unnecessary because the scheduler already procedurally selects the content.** This de-risks 1.0 enormously. More dungeons = post-1.0 themed content (a radical-themed floor, an HSK sub-band floor).

**Room = a space with a mob encounter; each card answered = one FSRS review.** A room holds an FF7-style battle of 1–3 mobs (see **Encounters**); each mob/card is one honest FSRS commit. The *card* is the atomic unit, not the room.

**Run shape:** `TOWN → enter → segment → elite → [extract gate: leave or push] → segment → elite → … → boss`. A *segment* is a few encounter rooms; **elites escalate 3 → 5 → 7** hits to clear (exact counts = playtest). After every elite: bank the haul and go home, or descend. **Depth = position along the fixed path** — later rooms pull lower-stability cards + harder challenge types (the locked depth-biases-the-draw rule). **Forward-only; no backtracking** — matches extraction tension (you extract or push, never retreat).

**Branching = telegraphed icons (LOCKED).** At a fork you see 2–3 exits, each previewing what's down it — card-type, shard cache, timed trial, the elite. The choice is **informed risk/reward** (the Slay-the-Spire map), which is where roguelike decisions get their teeth.

**In-dungeon room types (lean — town holds shops/rest/grade):**

| Room | What happens |
|---|---|
| **Encounter** | An FF7-style battle vs. 1–3 mobs that *are* the answer options (see **Encounters**). Strike the right mob → it drops its card; wrong → it hits you (lose a heart). |
| **Trial** (timed) | An encounter with a *soft* countdown (pressure, not instant-fail). Better reward. Where the `+timer` passive earns its slot. |
| **Cache** | A small shard / bonus-raw pickup (telegraphed). |
| **Elite** | HP-bar fight (below). Gateway to an extract point. |
| **Boss** | The cloze finale (see The Boss). Ends the run. |

**Elite fight — N *total* correct hits (LOCKED 2026-06-02).** The elite has an HP bar sized to **3 / 5 / 7** correct answers (escalating per elite; playtest exact). **Each correct answer = one hit on the bar; each wrong answer = you take damage (lose a heart).** No combo/streak requirement — it's a *cumulative total*, not consecutive, so a single slip doesn't wipe progress. Win = bar emptied → extract or continue; lose = hearts hit zero → die (lose haul + stake). FSRS logs every first attempt regardless. *(Future idea, parked: make elites fight in a structurally distinct way — not just "a longer regular room.")*

**Timer = a per-room property, not a global clock (LOCKED).** Most rooms are calm; trial rooms (and optionally elites) carry the soft countdown. This keeps the baseline pressure-free, makes timed rooms a real tension spike, and gives the `+answer-timer` passive clear situational value — confirming the user's "a timer on *some* rooms" instinct.

---

## Two Card Layers: Binder vs. Instances

- **Binder (the Pokédex):** permanent collection, one entry per character, SRS-backed, **never destroyed**.
  - **Greyed** = encountered (seen in a dungeon, even if you whiffed and died).
  - **Colored** = you've extracted at least one copy. Permanent — you lose *instances*, never *discovery*.
  - **Grade badge** shows your *best* PSA grade for that character → the binder is also a trophy case (chase "PSA-10 你").
- **Instances:** disposable graded copies — the consumable, spendable, **stakeable** game objects. You stake/burn/fuse *instances*, never characters. Instances are re-farmable (review the character again → pull another copy), so any loss floor is **time, not permanent progress** — which is what makes the aggressive stake-on-death model survivable.

---

## Economy: Cards Are Everything

Extracted cards serve as **passive power, active abilities, and currency.** A raw (ungraded) instance has three fates:

1. **Grade it** → a **craft**: surround the target with a set of its linguistic family + pay shards → becomes equippable, gains an upward power tier (see Grading and **Crafting & Currency**).
2. **Shatter it** → yields **shards** (the generic currency).
3. **Feed it into a craft** as an ingredient — a common that shares a radical/phonetic/tone with a keeper is worth more as a *recipe ingredient* than as raw shard-fodder.
4. Leave it raw.

The loop closes itself: **commons** (front-loaded easy FSRS cards — weak by design) are **fuel** → shatter most for shards, save the linguistically-connected ones as craft ingredients → spend both to **grade the keepers.** Weak cards aren't useless; they're either currency or family.

---

## Power Model

- **Base power = a flat baseline per effect** — *not* mastery-derived and *not* depth-derived (a raw heart-card = +1 heart for everyone). This keeps the two principles below clean: depth never hands out power, and mastery's contribution is realized at the grading station, not baked into the raw card.
- **Mastery (FSRS stability) gates power *through the grade roll*, not the base.** A well-mastered card doesn't start stronger — it *grades better* (see Grading). Demonstrated, sustained learning shows up as better PSA odds, so a hard card just learned at depth 5 (low stability) grades poorly and stays weak even when graded; front-loaded easy cards likewise stay weak. ✅ (intended — the property survives, just routed through grading)
- **Depth gates access/rarity only** — deeper = rarer, less-seen characters and harder challenge types. Depth biases the FSRS *draw*; it hands out neither base power nor grade odds.
- **Rarity = HSK tier (intrinsic, fixed per character).** common = HSK 1, uncommon = HSK 2, rare = HSK 3, epic = HSK 4. Rarity is *what the card is* — it sets drop depth, shard/craft value, the ability-family pool, and **the grade-band ceiling** (see Grading). It does **not** scale base power: two cards with the same effect share a base and differ only in how high they can grade. A card's identity is **rarity × grade** (TCG-style: a pristine PSA-10 common and a beat-up rare both exist). *(At the HSK-3 launch scope you ship common→rare; **epic rides in with the HSK-4 stretch.**)*
- **Grade = the fast/fun variance layer.** Base is flat and honest; the **PSA roll** (loaded by mastery) is the instant dopamine that sets a card's real strength. Base = floor, grade roll = excitement and ceiling.

---

## Loadout & Staking — The 5-Card Kit

**Resolved 2026-06-02 (loadout shape revised same day: 5 fixed slots, was 3 free).** Extraction-shooter model: **your loadout *is* your stake.** There is no separate collateral pool — the cards you bring are exactly the cards on the line.

- **Loadout = 5 graded instances in a fixed split: 2 passive + 3 active** (slots can grow via meta later). Passive slots take statives (nouns/adjectives), active slots take verbs — **the grammar split *is* the loadout UI**, so equipping teaches POS. The active trio is where set-bonus identity lives: 3× same-radical (flood synergy) or 3× tone-4 (crit build) is a real, committed choice.
- **All 5 cards are the stake.** Die in the dungeon → lose the whole kit (+ the haul). Extract alive → it comes home (keep-your-kit). Re-farmable, so the loss floor is **time, not permanent progress**. (Risking five graded cards is steep — intended; that's the extraction tension. Softening to *only actives at risk* is the obvious dial if it bites too hard.)
- **Loadout grade-weight = depth ceiling.** Each card's final power (base × PSA grade) sums to a loadout total; each depth gate has an ascending threshold. Bring five high-grade cards → punch deep; bring commons → cap shallow. **To reach the rare deep cards you must bring — and therefore risk — your best.**
- **Staking happens at the gate (push-your-luck).** At every extract point: bank the haul and keep your kit, or descend one more depth. A run ends two ways — you *choose* to extract, or you *hit your ceiling* (loadout can't clear the next gate → forced out). The greed tax grows the deeper you push, so pressing on raises both the reward and the cost of escape.

**Emergent win — self-smoothing difficulty (no knob):** a new player's loadout is weak (low stability, few grades) → only shallow runs → which surface easy due reviews, exactly what a beginner needs. As stability grows over real spaced time, reach extends on its own. Depth-access *tracks genuine mastery* with zero hand-set difficulty dial.

**Mastery-as-key loop:** deep floors draw *low*-stability cards (the struggle/loot), but the *key* to reach them is your *high*-stability loadout (the mastered champions). You spend what you know to face what you don't — and the two classes play opposite roles: champions are key + stake, strangers are haul.

**Knock-on (tightens two earlier decisions):** the locked loss-model's "staked instances" = the equipped loadout (one pool, not two). And **commons revert to a single clean role — pure currency / shatter-fodder** — since collateral-feeding is gone; the five-card kit carries power, key, and stake together.

---

## Where Power Lands — The Fight Model

**The core move: a correct answer is the trigger.** Equipped power never fires on its own and never bypasses knowing the card — it only *amplifies a correct answer*. This is the answer to "abilities should tie into matching the card correctly": they are correctness-conditional amplifiers, so the only way to spend power is to know the answer.

- **Normal rooms — JRPG mob encounters (see Encounters).** 1–3 mobs with HP; pick a target, answer its facets to drop it, loot its card; miss → it retaliates (lose a heart). Your **2 passives** live here as always-on whole-run stats — but since mobs now carry HP, your **3 actives** matter here too: damage-per-correct-answer thins mobs faster (less retaliation, more haul survives).
- **Elites & boss — a bigger HP bar.** Same grammar scaled up: each **correct answer deals damage = your active power**; a miss costs a heart. Burn the bar down before it burns you. Normal-room mobs are just small versions of this same fight, with target choice and loot drops.

**Two classes, two distinct sinks:**

| Class | Slots | Sink | Examples | Grade scales… |
|---|---|---|---|---|
| **Passive** (statives) | 2 | Survival + economy, whole run | +1 heart, +answer-timer, −greed tax, +shatter yield | the magnitude (+1 → +2 hearts at PSA 9) |
| **Active** (verbs) | 3 | Damage-per-correct-answer, set-pieces | hit harder (flat ×), radical-multiplier (×N when the answer's radical matches), tone crit | the magnitude (bigger ×, higher crit) |

- **No mana/cooldown UI for damage actives — the correct answer *is* the charge.** This also resolves the active-ability economy for offense: you cast by answering right. (Pure *utility* actives — reveal-a-hint, skip-a-card — would still want limited charges; that's the only piece left open here.)
- **Knowledge stays the true wall.** Power decides how *fast* correct answers resolve a fight; it never answers for you. Deep cards are low-stability (hard), so even a maxed kit can't burn the boss without actually knowing the deep cards — power amplifies skill, it doesn't replace it.
- **`+answer-timer` → a per-*room* soft clock (RESOLVED 2026-06-02).** The timer is a **room property**, not global: trial rooms (and optionally elites) carry a *soft* countdown (pressure, not instant-fail); most rooms are calm. The 慢 *slow* passive extends the clock exactly there, giving it clear situational value. See **Dungeon Structure**.

---

## Encounters — JRPG Mob Battles (HP, Targets, Loot Drops)

**Revised 2026-06-02 — pivoted from one-shot "mobs = options" to a JRPG combat layer.** Normal rooms are **FF7-style battles vs. 1–3 mobs**, lightly **timed** (ATB pressure, not instant-fail). Each mob is a real combat target with **HP** and is **bound to a character** — the card it drops when it dies. This is a deliberate trade: it gives up the zero-code "mobs ARE the answer options" reskin in exchange for **kill-order tactics**, which is exactly what makes a *capped haul* (see Meta Progression) matter — focus-fire the rare-drop mob before the ATB clock or a miss costs you.

**The loop:**
1. **1–3 mobs** appear, each showing the character/loot it guards and its **HP** (a small bar = a few correct answers).
2. **Pick a target** — the mob you want to bring down. You're quizzed on **that mob's character**, and each HP point is a **different facet** of it (meaning → pinyin → tone), so a multi-HP mob is the existing **bonus-round chain** turned into a health bar. Distinct facet per hit = **no massing** → the FSRS signal stays honest.
3. **Answer via the swipe MC** (`src/swipe/card_display.gd` — the 4-option recognition input is reused intact, now as the *answer* widget rather than the mobs themselves). Correct → one HP off the targeted mob. Wrong → a mob **retaliates (lose a heart)** — no retry; FSRS logs the one attempt.
4. A mob at **0 HP dies and drops its card** into your field bag. Clear the encounter's 1–3 mobs → 1–3 cards → pick a telegraphed exit.

**What's reused vs. net-new:**
- **Reused:** the swipe MC answer input (and its visibility contract), the **bonus-round multi-stage chain** (now a mob's HP bar), the challenge-type variety.
- **Net-new (the JRPG layer):** mob sprites with HP bars, **target selection**, mob **retaliation**, and the ATB clock. This is real new combat code — the accepted cost of target tactics.

**Why the pivot earns its cost:**
- **Target choice is the tactic.** With a capped haul you can't take everything; deciding *which* mob to kill first (the rare-drop, before it flees or the clock runs out) is the moment-to-moment game. One-shot recognition had no such decision.
- **Actives now matter everywhere.** Mob HP means **damage-per-correct-answer (your 3 actives)** speeds normal encounters too, not just elites/boss — kill faster = less retaliation = more haul survives. Your offense stat is always live.
- **Still honest.** You only loot by answering correctly; each HP hit is a distinct facet; a miss is final.

**Tuning (open):** turn order (pick-target-then-answer, as above, vs. answer-a-shared-prompt-then-assign-the-strike); mob HP sizing per rarity; mobs-per-encounter distribution; ATB clock length; decoys in the swipe options so picks aren't trivial; visible-roaming vs. random-on-walk presentation. *(Parked optional layer: mob **type** = challenge type — a 'tone' mob tests tone.)*

---

## Grading (PSA) — in Town, Not Free

- Happens **back in town** (forces extraction; adds a "bring the loot home" beat).
- **Is a craft, not a purchase** — you spend **shards** *and* a set of linguistically-related ingredient cards (see **Crafting & Currency**). The connection you craft along authors the resulting ability and loads the roll.
- **Raw card = its flat base effect** (e.g. +1 heart). **Graded card = a higher magnitude tier** set by the PSA roll (+2 hearts at PSA 9, etc.). Grading only ever *increases* power.
- **FSRS mastery loads the PSA roll.** Higher stability shifts the roll toward higher grades — *"not determined, but the chances are better."* Mastery never changes the base and never *guarantees* a grade; it bends the odds.
- **Two caps on the band: rarity sets the *ceiling*, mastery sets the *reach* within it. LOCKED.** **Rarity (HSK tier) caps how high a card can ever grade** — a common (HSK 1) tops out low, an epic (HSK 4) can reach PSA 10. **Mastery (FSRS stability) sets where in that range you actually land** — low stability can't approach the ceiling even on a rare card; the craft's RNG rolls within. Effective top = `min(rarity-cap, mastery-cap)`, so **PSA 10 needs both a rare card *and* real mastery** — that's the min/max chase. Preserves "easy/new cards stay weak even when graded," now from two directions. (Band-over-soft-odds + rarity-as-ceiling both confirmed 2026-06-02.)
- **Teaching hook — show the odds.** The grading screen previews your chances (*"your mastery of 水 → 60% PSA 8+"*), making the learn→reward link visible and nudging players to do more reps before grading. The honest backend becomes a *visible* motivator.

---

## Crafting & Currency — Grade by Surrounding a Card with Its Family

**Resolved 2026-06-02.** Grading isn't a vending machine — it's a **craft** that makes you manipulate your collection along *linguistic* lines (which is the study behavior we want, disguised as a workbench).

**Currency = shards.** Source: shatter commons/dupe instances (the firehose) + small run drops. Sinks: the per-craft **shard fee** (table stakes), the **ingredients** consumed in the recipe (the real sink), and town services (heal / restock / re-enter — TBD).

**The craft (match-3 → grade):**
1. Pick a **target** binder character to grade.
2. Assemble a **set of 3 instances** that share a **connection with the target** — feed 请 its phonetic-series mates 清/晴/情; feed a water card three 氵 mates.
3. Pay the **shard fee**.
4. **Roll.** Mastery sets the band (locked); **the connection loads the roll within the band AND authors the ability family** (the three locked rules below).

**Three locked rules:**
- **Connection loads the roll + authors the ability** — *not* just an eligibility gate. The axis you craft along decides what the card *does* and biases where it lands in your band.
- **Flat match-3** — always 3 ingredients. Scaling (more ingredients to push higher) is a later dial, not v1.
- **Safe within band** — you always get an in-band grade for your ingredients. The gamble lives in the dungeon, not the workbench; crafting is always progress, never punishment.

**The connection axes — and the tier each one authors** (this unifies crafting with the linguistics hierarchy already in this doc — the axis you craft along *selects which tier* defines the ability):

| Connection (craft along…) | Set scarcity → reward | Authors ability via | HSK≤3 example |
|---|---|---|---|
| **Phonetic series (声旁)** ⭐ | scarce → top-of-band + **pick your tier** (the prestige/wildcard craft) | player's choice of Tier 2 or 3 | 青 → 请・清・晴・情 |
| **Semantic radical (部首)** | medium → mid-band | **Tier 2** radical family (氵 → flow/hit-multiple) | 氵 → 河・湖・海・洗 |
| **Semantic field** (theme/synonym/antonym) | medium → mid-band | **Tier 1** meaning-keyword (leans passive/utility) | 大/小/多/少 |
| **Homophone** (same syllable+tone) | medium | **Tier 3** tone role (same sound) | shì → 是・事・市・室 |
| **Tone-pair / tone class** | trivial/huge → bottom-of-band (the floor) | **Tier 3** tone role (tone-4 set → burst) | mā/má/mǎ/mà |
| **Word-family** (shared char in compounds) | varies → mid | **Tier 1** + chaining (boss-super synergy) | 学 → 学生・学校・学习 |

**Self-balancing for free:** rarer connection = scarcer ingredients to gather = better band-loading. **Phonetic series is the "perfect craft"** — hardest to assemble, best payoff, *and* the single most powerful reading hack in Chinese, so the prestige reward is also the most pedagogically valuable behavior. The language supplies the difficulty curve; we don't hand-tune it.

**Why this closes the "do abilities even tie to the card?" worry:** the ability is *born from the linguistic relationship you built it out of* — you crafted a radical-multiplier *by gathering radical-mates* — and it still only fires on a correct answer. Knowledge stays the wall; crafting just decides which amplifier you earned.

---

## Linguistics → Mechanics (reading drives function)

Goal: **the reading/meaning of the card has stake in what it does**, reinforcing learning. Resolved via a **hierarchy of specificity** — the most meaningful property that applies wins; tone is the universal floor so nothing is ever undefined.

### Passive vs. Active = Stative vs. Action (grammar-driven)
- **Stative** (noun / adjective / state) → **passive** bonus. e.g. 大, 好, 山, 心, 红.
- **Action** (verb) → **active** ability. e.g. 打, 跑, 吃, 看, 说.
- Derivable from the **part-of-speech tag** in HSK data; bonus: teaches the player each word's POS.

### Tier 1 — Meaning keyword (curated ~100–150 cards, highest impact)
Hand-tagged set where *meaning IS the mechanic*. Bounded, not exhaustive.

| Group | Meaning → mechanic |
|---|---|
| 一 二 三 十 百 (numbers) | Multipliers (scale an effect ×N) |
| 大 / 小 | Amplify / reduce magnitude or cost |
| 多 / 少 | More targets / cheaper |
| 上 下 左 右 里 外 | Targeting (which mob/row) |
| 快 / 慢 | Haste / cooldown |
| 火 水 风 山 | Elemental damage types |
| 头 手 脚 眼 | Hit specific "slots" |
| 加 / 力 | Flat power boost |

### Tier 2 — Semantic radical (procedural, big coverage)
For transparent phono-semantic characters, the radical sets the **effect family** via a ~30–40 row table (no per-card work). Not every character has a *semantically transparent* radical — those fall through to Tier 3.

| Radical | Family | Lean |
|---|---|---|
| 氵 water | flow / cleanse / hit-multiple | active |
| 火 灬 fire | burn / DoT | active |
| 扌 hand | strike / grab / steal | active |
| 口 mouth | shout (AoE) / consume | active |
| 辶 walk | dodge / reposition / speed | active |
| 心 忄 heart | buff / fear-debuff / heal | mixed |
| 木 wood | growth / shield / regen | passive |
| 钅 metal | armor / currency-find | passive |
| 目 eye | reveal hint / scout | active-utility |

### Tier 3 — Tone (universal floor)
Every syllable has a tone → guarantees a defined behavior for every card AND forces tone attention (hardest skill for learners). Tone shapes the effect's *role*:

| Tone | Shape | Role |
|---|---|---|
| 1 (high flat) | sustained | shield / sustain |
| 2 (rising) | ramps up | buff / heal-over-time |
| 3 (dip-rise) | down then up | counter / parry / reversal |
| 4 (sharp fall) | sudden drop | burst damage |
| neutral | light | cheap utility / fast |

### Player choice = deckbuilding identity (set bonuses)
The radical-vs-tone choice lives at the **loadout layer**, not per card: build a **radical deck** (5× 氵 = flood synergy) or a **tonal deck** (all tone-4 = crit build). Same cards, two synergy axes.

### Data note
Tier 1 is real but **bounded** data work (~100–150 tags). Tiers 2–3 derive from data the pipeline already parses (radical, pinyin/tone, POS). We are explicitly **not** categorizing the meaning of all ~1,350 characters.

### Scaling with HSK level (the hierarchy degrades on purpose)
Low-HSK vocab is concrete and single-character (打, 口, 水) — Tier 1/2 fire cleanly. Higher-HSK vocab is abstract and largely **two-character words** (经济, 决定, 环境) where meaning-keyword and single-radical mechanics blur. The hierarchy is built to absorb this:

- **Everything falls through to tone (Tier 3), which is always defined.** As vocab gets abstract, more cards resolve by tone — by design, not failure. For multi-character words, tone becomes the **tone *pattern*** of the word.
- **The emphasis shift is pedagogically correct.** Low HSK = recognition mechanics (meaning, radical); high HSK = **production mechanics** (tone, word-chaining, cloze) — exactly the skills that are hard *at that level* (advanced learners read fine but mistone). The game leans hardest on what's hard to learn.
- **POS for words:** HSK data tags words' parts of speech. Flex words (决定 = decide/decision) default to **active if they carry any verb sense** (verbs make better abilities); otherwise primary POS. Exact tie-break = tuning.
- **Which character drives a compound's mechanic:** default to the **tone pattern**; optionally Tier 2 if a constituent has a salient semantic radical. Exact rule = open/tuning.

---

## The Boss — Sentence Builder (Cloze Gauntlet)

**Detailed 2026-06-02.** Climax = **production** (the hardest skill), fueled by the run's haul. **Hard constraint: no free-form sentence generation/validation** (validating arbitrary Mandarin grammar is a research problem). The boss is **selection, never generation.**

**The cloze gauntlet (the finale):**
- **Pre-authored HSK sentence bank, indexed by the word that fills each blank.** At the boss, query the bank for sentences whose blanks are **fillable from your haul** — so the run's collected cards literally *are* the answer bank. Validation = match the known answer. Authored, never generated.
- **Haul = ammo (loop closure).** Bigger / more diverse haul → more solvable sentences → richer boss. The extraction greed tax now feeds the climax: hoard more = better-armed boss, but you risked more to carry it home. The whole run points at this moment.
- **Minimum-haul gate.** A "certain amount" of cards is needed for cloze to function. Below it: too few fillable sentences → the boss leans on **review of the haul** (binder cards padding the wrong-answer options). Above it: real production. It always functions — a thin haul just yields a more review-flavored boss.
- **Blanks scale with HSK (the difficulty dial):** ~2 blanks at low level → up to ~5 at HSK 3–4.
- **Combat = identical to the elite:** each correct fill = one hit on the boss; each miss = you take a hit. HP bar ≈ 5–10 answers (the longest fight; exact = playtest).
- **Review mixed in (variety + reinforcement):** between cloze prompts, plain reviews of haul cards — paces the fight *and* lands a dense spaced-rep burst on exactly the cards just earned. Every blank-fill is a *production* recall and every answer logs to FSRS, so the boss is the most pedagogically valuable room in the game — production is where the linguistics hierarchy says the climax belongs.

**Word/phrase-chaining (recurring "super attack"):** in any fight, optionally chain collected characters into a valid word (你+好, 中+国) for bonus damage. Validated against a dictionary of known words — no grammar engine.

Ship both: chaining as the recurring super, the cloze gauntlet as the boss. Assemble/complete from a known bank — never *generate*.

---

## Town — The Hub Between Runs

**Resolved 2026-06-02.** Town is a Zelda-overworld-style hub with **four buildings** — everything that isn't the dungeon: prep, economy, collection.

| Building | Function |
|---|---|
| **Crafter** | **Shard** (instance → shards) and **grade** (the match-3 craft — surround a target with 3 linguistic mates + a shard fee). The *only* place grading happens. |
| **Home** | **Outfit your hero** — assemble the 5-card loadout (2 passive + 3 active = your stake) — and **view the binder** (Pokédex + PSA trophy case). |
| **Shop** | Rotating, shards-priced stock: **raw instances of already-encountered characters** (craft-ingredient smoothing — buy the 3rd 氵 mate — + loadout filler) **and** ingredient bundles / shard deals / one-shot consumables (a dungeon hint, a revive). **Never new/undiscovered characters and never grades.** |
| **Exit** | Enter the dungeon with the current loadout (= the stake). |

- **Shop stock = a mix of "known-instances" + "consumables," explicitly NOT new-character unlocks (LOCKED 2026-06-02).** You cannot buy knowledge and cannot buy your way past the craft — it sells only *raw* instances of characters you've already met, so it **feeds the crafter, never bypasses it.** The shop just smooths the RNG of *finding* the right ingredient. This preserves *binder = genuinely learned.*
- **Hearts reset to full each run** (extraction-roguelike standard) → no heal building; the four above are complete. *(If hearts ever persist between runs, a rest/heal service slots in — parked.)*
- **Shard sinks now concrete:** the **crafter** (shard fee + ingredients consumed) and the **shop** (instances, bundles, consumables). The currency loop is closed.

---

## Meta Progression — What Persists Between Runs

**Resolved 2026-06-02.** The "why keep playing" layer is a **blend of three ratchets**, layered so they reinforce instead of compete. The loop the player feels: *more runs → better cards → better stats (carry cap, hearts, damage) → deeper content → better cards.*

**The un-loseable principle (north star):** in a learning game with permadeath, the one thing that must *never* die with you is **what you actually learned.** A catastrophic run loses your instances (loadout + bench + haul) but **never your binder, your mastery, or your permanent unlocks.** Total wipeout sets you back in *gear and time* — never in *knowledge or ceiling*. The rage-quit failure mode is designed out while the stakes stay real.

**1. Knowledge gates the ceiling (the spine).** Binder/mastery milestones — characters colored, PSA badges earned, an HSK band cleared, a radical family completed — **unlock** the next loadout slot, the next depth tier, and carry-cap raises. You can't *buy* slot 6; you *learn* your way to eligibility. Real Chinese is the progression axis, which keeps the meta honest. *(For 1.0's single dungeon, "stronger content" = deeper along the fixed path; literal new dungeons are post-1.0.)*

**2. Town-buys fill it in (the dopamine).** Under that knowledge ceiling, a meta-currency buys the incremental permanent upgrades — **slot +1, heart +1, carry-cap +1, better craft odds** (Hades-mirror style). Reliable, frequent, between-milestone reward. *(Open: whether town-buys spend shards — creating a craft-vs-upgrade economy tension — or a scarcer premium meta-currency dropped by elites/bosses.)*

**3. The card bench is the buffer (the stash).** Your stable of graded instances deepens over runs; a deep bench means a death stings less (re-equip from reserves) — the Tarkov-stash safety net. Progress you can *feel* as inventory depth, and the volatile layer that makes stakes bite without being ruinous.

**Carry cap = the headline meta stat.** How many cards you can extract is a gear/meta number that grows along all three axes (a knowledge milestone unlocks the raise, a town-buy realizes it, a deep bench lets you afford the risk to fill it). It's the cleanest knob: bigger cap = more haul = better-armed cloze boss + richer crafting — but a fuller bag = a harder escape (greed tax). It also gives the JRPG target-choice its teeth: when you can't take everything, *which mob you kill first* is the decision.

---

## What Survives From Prior Work

| Keep | Role in new design |
|---|---|
| `src/srs/review_scheduler.gd` (FSRS) | Sacred core / source of truth. Untouched. |
| `src/swipe/` swipe-or-tap input | The dungeon encounter interaction. |
| 5 challenge types (meaning, character, pinyin, tone, recall_pinyin) | Room/encounter variety; harder types at depth. |
| Bonus-round multi-stage chain | Elite & boss multi-stage fights. |
| `SessionData.hand_cards` + `RunManager.get_run_summary()` | Already an embryonic extraction haul. |

**Discarded:** Triple Triad board placement in `game_screen`.

---

## Locked Decisions
- Scope: build target **HSK 3** (~600 chars); HSK 4 stretch only where concrete; 4–6 parked.
- Loss model: stake graded **instances** + run haul; both lost on death. FSRS ledger always committed.
- Economy: **binder (permanent characters)** + **instances (disposable graded copies)**.
- Grading: **in town**, **costs currency**, graded = base × random upward multiplier.
- Power: base = FSRS stability; depth = access not power; grade = variance layer.
- Passive vs. active: stative (noun/adj) = passive, action (verb) = active.
- Card function: meaning-keyword → radical → tone hierarchy; tone is the universal floor.
- Currency: **shards** (shatter raw/dupe instances → shards; small run drops). Sinks: per-craft shard fee + ingredients consumed + town services.
- Crafting / grading recipe: **match-3** — surround a target with **3 instances sharing a linguistic connection** + pay shards. **Connection loads the roll within the mastery band AND authors the ability family** (radical→Tier 2, tone/homophone→Tier 3, meaning/word-family→Tier 1, **phonetic series 声旁 = prestige craft → top-of-band + pick your tier**). **Safe within band** (no whiff). Rarer connection = scarcer ingredients = bigger payoff — the language self-balances the curve.
- Boss: **cloze gauntlet** — pre-authored HSK bank indexed by blank-fill, queried for **haul-solvable** sentences (haul = the answer bank; **selection, not generation**); **min-haul gate** (below → haul-review + binder distractors); **blanks scale 2→5 with HSK**; combat = elite model (correct = hit, miss = take a hit), HP ≈ 5–10 answers; **review mixed in** for pacing + reinforcement. Word-chaining = recurring super. No generative grammar.
- Loadout: **5 graded instances — fixed 2 passive + 3 active** (slots grow via meta). **Loadout = stake** (extraction-shooter — all 5 brought are all 5 risked). The loss-model's "staked instances" = the equipped loadout (one pool).
- Depth: gated by **loadout grade-weight** (a ceiling); descend via **at-the-gate push-your-luck** (leave vs. one more depth). Self-smooths difficulty — weak loadout → shallow runs → easy due cards.
- Power sink: **a correct answer is the trigger** — power amplifies correct answers, never bypasses them. Passives = whole-run survival/economy stats; actives = damage-per-correct-answer in elite/boss **HP-bar** fights. Knowledge stays the wall.
- Grading/power: **base = flat per effect** (not mastery/depth/rarity-derived); **grade sets effect magnitude** (+1 → +2 hearts) via the PSA roll. **The grade band has two caps: rarity (HSK tier) sets the ceiling, mastery (FSRS stability) sets the reach within it** — top = `min(rarity-cap, mastery-cap)`, so PSA 10 needs a rare card *and* mastery.
- Rarity: **= HSK tier, intrinsic & fixed** (common HSK1 / uncommon HSK2 / rare HSK3 / epic HSK4). Drives drop depth, value, ability pool, and the grade-band ceiling — **not** base power. Card identity = **rarity × grade** (TCG rarity × condition). Revises the old Phase-1 "rarity = mastery" into two axes. The **min/max meta** = chase rare HSK-3/4 cards × grade them high × build synergy. Launch ships common→rare; epic = HSK-4 stretch.
- No retry: **a miss is final — you move on** (FSRS logs the one attempt). Makes an encounter a hunt (defeat mob → loot card), not a combo-grind.
- Encounters (normal rooms): **JRPG-style timed battles vs. 1–3 mobs with HP** (revised 2026-06-02 from one-shot "mobs = options"). Each mob is **bound to its loot card**; pick a target → answer that character's facets (HP = the bonus-round chain, distinct facet per hit = no massing) → 0 HP drops the card; a miss → the mob retaliates (lose a heart), no retry. The swipe MC is reused as the *answer* input; net-new = mob HP, target selection, retaliation, ATB. **Target choice is the tactic** that makes a capped haul matter. 1–3 mobs → 1–3 cards.
- Dungeon: **one pre-rendered run-map for 1.0** (Slay-the-Spire structure in a Zelda *ALttP* costume); fixed layout, **cards drawn live from FSRS** so replayability needs no procedural gen. Room = one card. Run = segments → elites → extract gates → boss; **depth = position along the path**; forward-only. More dungeons = post-1.0 themed content.
- Branching: **telegraphed icons** — each fork previews its room type (informed risk/reward).
- Elite: **HP bar of N *total* correct hits (3/5/7, escalating; playtest)** — correct = a hit, wrong = take damage/lose a heart; **no streak/combo**. Clear → extract or continue.
- Timer: **per-room property, not global** — trial rooms (and optionally elites) carry a *soft* countdown (pressure, not instant-fail); the `+timer` passive extends it there.
- Town: **four-building Zelda hub** — **Crafter** (shard + grade; grading is town-exclusive), **Home** (assemble loadout = stake + view binder), **Shop** (shards-priced **raw instances of already-encountered chars** + ingredient/consumable deals; **never new/undiscovered chars, never grades** — feeds the crafter, never bypasses it), **Exit**. Hearts reset to full per run → no heal building.
- Combat model: **JRPG HP + target choice (LOCKED 2026-06-02)** — mobs/elites/boss are HP bars; a correct answer deals damage, a miss costs a heart; for normal mobs you pick which to focus. Actives (damage-per-correct-answer) now matter in every fight, not just elite/boss. Accepted cost: a real combat layer over the old free reskin.
- Carry cap: **the haul is capped, and the cap is a meta stat that grows (LOCKED 2026-06-02).** Extract only your best N; triage the rest at the door. Cap = hard ceiling (gear/meta), greed tax = the soft cost curve up to it. Bigger cap = richer boss + more crafting, but a harder escape.
- Meta progression: **a blend of three ratchets (LOCKED 2026-06-02)** — (1) **knowledge gates the ceiling** (binder/mastery milestones unlock slots, depth, cap), (2) **town-buys fill it in** (meta-currency → slot/heart/cap/odds upgrades, Hades-mirror), (3) **the graded-card bench is the buffer** (Tarkov stash). **Un-loseable principle: death never costs knowledge, mastery, or permanent unlocks** — only instances. Carry cap is the headline stat all three feed.

## Still Open (next riffs)
- **Utility-active charges** — offense actives are correct-answer-triggered (resolved); pure-utility actives (reveal-hint, skip-card) still need a charge/refresh rule.
- **Meta-progression tuning** — model locked 2026-06-02 (knowledge-gates + town-buys + bench buffer; carry cap as headline stat). Residual: the meta-currency source (shards vs. a premium elite/boss drop), which binder/mastery milestones gate which unlocks, the slot-growth thresholds, the carry-cap growth curve, and the depth-threshold curve against loadout grade-weight.
- **Timed-room tuning** — timer model locked (per-room soft clock on trial/elite rooms; resolved 2026-06-02). Residual: countdown length, exactly which rooms carry it, how much the `+timer` passive extends it.
- **Economy tuning** — the numbers: shard fee/yield, the grade cost curve per band, shop stock size + refresh cadence, and consumable/instance prices. (Model locked; values TBD.)
- **Boss tuning** — HP (target answer count, ~5–10), the cloze:review ratio, the minimum-haul threshold, and the 2→5 blank curve per HSK band.
- **Boss gimmicks** — beyond cloze: themed-radical gauntlet, sudden-death, "wrong answer heals boss."
- **Connection-set details** — exact pool/membership data per axis (esp. curated phonetic-series and semantic-field sets), and whether crafts can *re-craft* an already-graded instance to push higher. Radical "set" *deck-level* bonuses (5× 氵 in loadout) still open.
- **Dungeon tuning & content** — structure locked (one pre-rendered run-map; resolved 2026-06-02). Residual: segment length, room counts per segment, number of elites before the boss, the exact branch-icon menu, and the roster of post-1.0 themed dungeons.
- **Distinct elite combat** — v1 elites are "a regular room you must clear N times." Future: give elites a structurally different fight (not merely longer). Parked per user.
- **Encounter tuning** — model revised 2026-06-02 to **JRPG HP + target choice** (see Encounters). Residual: turn order (pick-then-answer vs. answer-then-assign-strike), mob HP sizing per rarity, mobs-per-encounter distribution, ATB clock length, decoys in the swipe options, visible-roaming vs. random-on-walk presentation. *(Parked optional layer: mob-type = challenge-type. Retry-on-miss resolved: misses are final.)*
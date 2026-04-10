# Planning Doc — Chinese Character Learning Game

## Vision

An SRS-powered Chinese character learning app disguised as a card-collecting game. The spaced repetition algorithm isn't just the engine — **SRS is the game.** The collection is the game state, SRS is the economy, and pack-opening is the delivery mechanism. Characters you learn become collectible cards whose rarity and visual richness reflect your actual mastery.

Full game design document: `docs/game-design-doc.docx`

## Design Philosophy

Learning first, game second. The app's primary purpose is to make Chinese character memorization effective. The game mechanics exist to solve Anki's core problem: the science works, but nobody wants to use it. Every game system must either directly support learning or drive daily retention. If a mechanic doesn't do one of those two things, it gets cut.

**No degradation.** Cards only go up. A mastered card stays mastered visually. SRS handles review scheduling invisibly — when it's time to recall a card again, SRS puts it back in your pack. The player never feels punished for taking a day off; they feel rewarded for showing up.

**SRS decides, not the player.** What's in each pack, when a card graduates, when a mastered card returns, when a struggling card keeps appearing, pacing of new introductions — all SRS. The player decides when to study and (possibly) what HSK level to focus on. That's it.

## Target Audience

HSK 2-5 learners (~1,350 characters). Past tourist phrases, hitting the memorization wall where brute force fails. Motivated enough to study but need a better tool, not more motivation.

## Content Scope

The top 100 characters cover ~42% of all written Chinese text; the top 300 cover ~64%. Users entering at HSK 2 already recognize the most common characters. The app catches them at the dropout cliff where volume overwhelms rote memorization.

---

## Core Loop

### The Collection

The player has a collection grid of all HSK 2-5 characters (~1,350). Everything starts locked/greyed out. As characters are learned through SRS, they appear in the collection as cards. A card's visual richness reflects SRS mastery — new cards are basic, well-known cards are visually evolved. The collection is the primary progression surface and the thing players care about.

### Pack Opening

SRS delivers characters to study as **packs of cards.** Opening a pack is the core daily ritual. Pack composition on a typical day for an active learner (~200 learned characters):

| Type | % of pack | What it is | Feel |
|---|---|---|---|
| **Common** (routine reviews) | ~70% | Cards you know well, intervals expired, maintenance | Fast, rhythmic, satisfying to rip through |
| **Struggling** (low stability) | ~15-20% | Cards you've gotten wrong recently, keep returning | The grind |
| **New** (first introduction) | ~5-10% | Characters you've never seen — limited per day by SRS | Dopamine hit, full reveal animation |
| **Returning Mastered** (long absence) | ~1-5% | High-stability cards returning after weeks/months | Epic pull — the card you've been wanting |

Commons flip fast with small satisfying sounds. The pack slows down when a rare pull appears — new card reveal, returning mastered card with full animation. Exactly how real card pack openings work.

### The Study Interaction

**TBD — the core gameplay mechanic for answering/reviewing cards has not been finalized.** Candidates include swipe-based, JRPG battle, drag-to-match, or something else entirely. What matters: the interaction must feel good for commons (fast, rhythmic) and special for rares (weighty, rewarding).

### Card Rarity = SRS Mastery

There is no separate upgrade or building mechanic. A card's rarity/visual tier IS its SRS state:

| SRS State | Card Tier | Visual Treatment |
|---|---|---|
| New (just introduced) | New | Basic art, fresh — but exciting reveal |
| Learning (early reviews) | Common | Standard art |
| Stable (medium intervals) | Uncommon | Enhanced art |
| Well-known (long intervals) | Rare | Rich art, effects |
| Mastered (very long intervals) | Epic/Legendary | Full art, animation, glow |

You don't grind a card to legendary through a game mechanic. You learn it. SRS promotes it. That's more honest and more satisfying than an XP bar.

### Maxed Card Spend

**TBD — when a card reaches full mastery, there should be a powerful "spend" mechanic.** The card is consumed in a big dopamine moment (think Destiny supers — built up through gameplay, unleashed, then gone). After spending, the card exits your active collection until SRS determines your memory is fading and puts it back in a future pack at a lower state. The cycle repeats.

Candidates for the spend mechanic:
- Fuse two maxed character cards into a word card (电 + 影 = 电影) — teaches vocabulary composition
- Shatter for a large currency burst — flashy, funds next pack or cosmetic
- Unlock a new pack or content area — mastery opens doors
- Power up another struggling card — mentor mechanic

### What SRS Decides (not the player)

- What's in each pack
- When a card graduates between tiers
- When a mastered card returns after long absence
- When a struggling card keeps reappearing
- Pacing of new card introductions
- Challenge type per card (meaning, pinyin, tone, character, recall)

### What the Player Decides

- When to study (session timing)
- Which HSK level to focus on (possibly)
- How to spend maxed cards (TBD)

---

## Game Mechanic — Two-Phase Session (Resolved)

The session is split into two phases: a **draft phase** (pack opening with SRS challenges) and an optional **board game phase** (Triple Triad-style card placement). The draft phase is the learning core. The board game is a retention draw — fun, optional, and rewards collection.

### Design Priorities

1. **Commons must feel fast and rhythmic.** 70% of reviews are routine. If these are tedious, the app dies.
2. **Rares must feel special.** New cards and returning mastered cards need a distinct, weighty interaction.
3. **Wrong answers must provide learning feedback** without feeling punishing.
4. **Sessions should be 5-10 minutes.** Draft ~3-5 min, board game ~2-3 min.
5. **The board game is optional.** Pack opening must stand on its own as a complete, satisfying session. The board game is a bonus for players who want more.
6. **Bottom line:** This is a learning tool that is more interesting than Anki. Foil cards, parallax cards, and the board game are retention draws that make the tool meaningful but are skippable for casual learners.

### Phase 1 — Draft Phase (Pack Opening)

A sealed pack of 10-15 cards, SRS-curated. The player opens them one at a time — the card-pack-opening experience.

**Base power is inversely related to SRS mastery tier:**

| SRS State | Card Tier | Base Power | Board Game Role |
|---|---|---|---|
| New | Epic/Legendary | Very strong | High risk, high reward — hardest to answer correctly, strongest if you do |
| Learning | Rare | Strong | Still challenging, powerful cards |
| Stable | Uncommon | Medium | Reliable mid-range |
| Well-known | Common | Low | Easy to earn, weak on the board |
| Mastered | Common | Weakest | Guaranteed in hand, filler — you know these cold |

**Why inverted?** New words are the dopamine hit — flashy reveals, exciting additions to your collection. They should also be powerful on the board, rewarding players for engaging with new material. Mastered cards are routine maintenance — fast, rhythmic, but not board game winners. This creates natural risk/reward tension: your strongest cards are the ones you know least well.

**Challenge flow per card:**

- **Common cards:** Single challenge (meaning recognition). Quick, rhythmic. No additional power-up stages. Commons are filler by design — fast to get through, lowest board game power.
- **Rare/Epic cards:** Single challenge, BUT have a random chance to trigger a **bonus round** (slot-machine style). When bonus round triggers, the player gets additional challenge stages to boost the card's power further:
  - Meaning correct → +boost
  - Character recognition → +boost
  - Pinyin correct → +boost
  - Tone correct → +boost
  - Miss at any stage → stop boosting, move to next card
- **Bonus rounds are exciting, not exhausting.** They should feel like a slot machine bonus game — "Yes! Bonus round! More power possible!" Not every rare/epic gets one. The randomness creates anticipation.

**Draft rules:**
- **Get the challenge right** → card goes to your hand for the board game
- **Get it wrong** → card disappears. No punishment, no retry. SRS schedules it for a future pack.
- **Draft ends when the pack is empty.**
- **Multiple packs per day** if the player wants. SRS has enough due cards to serve. But one pack = one complete, satisfying session.
- **Random chance for any card to be a bordered (foil) variant.** Visual distinction for collection purposes. Purely cosmetic.

Pack composition follows the SRS rarity curve (see Pack Opening section above): ~70% commons (fast, rhythmic), ~15-20% struggling, ~5-10% new (full reveal animation), ~1-5% returning mastered (epic pull). Most packs are quick routine reviews with occasional exciting reveals — exactly like opening a real card pack.

**Why fixed pack over open-ended queue:** Anki's "187 reviews due" is a motivation killer. A sealed pack you rip through in minutes is digestible and fun. You always know when the session starts and ends. Inspired by Duolingo's fixed lesson structure, not Anki's open queue.

**Beginner / cold start consideration:** New players have mostly new/learning cards. The SRS algorithm will disproportionately expose beginners to rares and epics as the algorithm settles, so visual dopamine is front-loaded. If a player is really struggling, consider a "boost mode" where you keep all cards in the deck and get to play the board game regardless. Also consider including HSK 1 level words as guaranteed easy wins for beginners.

### Phase 2 — Board Game (Optional, Triple Triad-Style)

After the draft phase, the player can optionally play a board game using the cards they earned.

**Core rules (Triple Triad):**
- 3x3 grid
- Place a card → compare values against adjacent cards
- Higher number on the touching side wins (captures the adjacent card)
- Most cards on the board at the end wins
- Dead simple. A child can learn it in one round.

**Hand requirements:**
- **Minimum 5 cards** from draft to unlock the board game
- **More than 5** → choose your best 5 to play
- **Less than 5** → pack-only session, no board game available. Draft is still a complete experience.

**Card values on the board:**
- Base power comes from SRS mastery tier
- Bonus round boosts add +1 or +2
- Radical matchup advantages add +1 or +2
- Values should be visible and intuitive — player must be able to make strategic placement decisions, not guess

**Radical group = element/type (strategic axis):**
- Radical groups form a circular strength/weakness cycle (like rock-paper-scissors but across 6-8 groups)
- Some matchups are strong, some are weak, most are neutral
- Player must recognize the radical group of their cards AND the opponent's cards to play strategically
- Example: Water > Fire > Nature > Water (exact cycle TBD based on radical group finalization)
- This teaches radical recognition as a tactical skill — "I see 氵, this is a water card, strong against fire"

**Sound group synergy (rime bonus):**
- If two cards from the same rime family are placed adjacent to each other → synergy power boost (+1 or +2)
- Visually rewarding — the two cards could combine/glow when placed together
- Teaches phonetic grouping: "these characters sound similar, I should play them together"
- **Design concern:** Triggering this requires multiple same-rime cards in hand AND strategic adjacent placement. May rarely activate in practice. Needs playtesting. Consider making the bonus generous enough to be worth chasing.

**Computer opponent:**
- Plays from the player's own SRS deck (knows the same characters)
- Computer hand is assigned random values and random rarity (like other players in FFVIII)
- Some computer cards have a chance to be **parallax variants** — if captured and game is won, the parallax card is added to the player's collection
- Difficulty levels or open-world exploration with different opponents (see Open World section below)

**Why play the board game?**
- Capture parallax card variants for your collection
- Earn bonus coins/currency
- The board game gives the draft phase *stakes* — "I need to nail these challenges so my cards are strong enough to win"
- Fun — the reward for studying is getting to play

### Card Variants & Collection

Two visual variants exist, distinguished by acquisition path:

| Variant | How to Get | Visual Treatment |
|---|---|---|
| **Standard** | Draft (SRS pack opening) | Normal card art, evolves with mastery tier |
| **Foil/Bordered** | Random chance during any draft | Special border or foil effect |
| **Parallax** | Capture from computer in board game | Parallax/animated depth effect |

- Same character, same learning value — variants are purely visual/collectible
- A player can own standard, foil, and parallax versions of the same card
- The collection grid shows which variants you own per character
- Foil gives pack-only players something to chase
- Parallax gives board game players something to chase
- Neither is required for learning progression

### Open World / Opponent Variety (Future — Phase 3+)

Inspired by FFVIII's open world where you walk around finding card game opponents. Different NPCs teach different mechanics through their rule sets:

| Opponent Type | Rules Active | Teaches |
|---|---|---|
| Beginner NPCs | Just values, no special rules | Basic board game strategy |
| Mid-tier NPCs | Radical matchups active | Radical group recognition |
| Advanced NPCs | Rime synergies active | Phonetic pattern recognition |
| Boss NPCs | Everything active, harder hands | Full mastery |

This serves as a natural tutorial system disguised as exploration — players opt into complexity when they're ready. No forced tutorial, no beginner mode toggle.

**Practice mode:** A no-stakes board game mode where you can practice freely. No chance for foil/parallax rewards, but no risk of a frustrating session either. Solves bad-beat protection for players who get unlucky pack compositions.

### Survival / Challenge Mode (Future — Phase 4+)

High-stakes mode for players who have mastered the base game and want a true challenge:

- Risk your card collection — you can lose gained cards
- Keep cards you capture from opponents
- True Triple Triad stakes
- Could be the basis for ranked/online multiplayer if the game builds a large enough player base
- Stakes are largely artificial (losing a visual variant, not SRS progress) — the learning data is never at risk
- **Open question:** What makes the stakes feel real enough to be exciting but not punishing enough to drive players away?

### Card Type Systems

Each character card has two type axes — one semantic, one phonetic. These are coarser groupings of the underlying linguistic data, designed to be learnable as game types (like Pokémon types or MTG colors) while still reinforcing real Chinese knowledge.

#### Radical Groups (~6-8 categories, semantic axis)

Grouping ~40-50 high-frequency radicals into intuitive categories. The grouping is an abstraction for game balance — individual radical knowledge is still taught through SRS.

| Group | Example Radicals | Feel |
|---|---|---|
| Water | 氵(water), 雨 (rain), 冫(ice) | Fluid, flowing |
| Nature | 木 (wood), 艹 (grass), 禾 (grain), 土 (earth) | Growth, ground |
| People | 人/亻(person), 女 (woman), 子 (child) | Human, social |
| Body/Action | 扌(hand), 足 (foot), 口 (mouth), 目 (eye) | Physical, doing |
| Built | 宀 (roof), 门 (gate), 囗 (enclosure) | Structures, shelter |
| Language/Mind | 言/讠(speech), 心/忄(heart/mind) | Thought, communication |

Possible 7th/8th groups depending on coverage analysis: Metal/Craft (金, 刂), Fire/Light (火, 日).

#### Sound Groups (~8-12 categories, phonetic axis)

Grouping phonetic components by shared final sound (rime family). This IS real Chinese linguistics — characters with the same phonetic component often rhyme. The match is approximate, not exact (tones and initials vary), but the pattern recognition is genuinely useful.

| Group | Final | Example Components | Example Characters |
|---|---|---|---|
| -ing | -ing | 青 (qīng), 生 (shēng), 令 (líng), 丁 (dīng) | 清情请, 星性姓, 领零冷 |
| -ang | -ang | 方 (fāng), 昌 (chāng), 长 (cháng) | 放房访, 唱场常 |
| -an | -an | 反 (fǎn), 占 (zhàn), 干 (gān) | 返饭板, 站店点 |
| -ao | -ao | 包 (bāo), 交 (jiāo), 召 (zhào) | 抱跑饱, 校较饺 |
| -ou | -ou | 又 (yòu), 口 (kǒu) | 对观欢, 扣叩 |
| -i | -i | 寺 (sì), 里 (lǐ), 己 (jǐ) | 时诗特, 理哩, 记起 |
| -en | -en | 分 (fēn), 门 (mén) | 份粉纷, 们闷问 |
| -ong | -ong | 中 (zhōng), 工 (gōng), 同 (tóng) | 种钟忠, 功攻红, 洞铜筒 |

Additional groups to be determined by data analysis: -uo, -ai, -ei, -u, etc.

**Note:** Phonetic components are less reliable than radicals — 青 is qīng but 猜 contains 青 and is cāi. For game purposes, "rhyme-ish" is fine. Exceptions become learning moments, not bugs.

#### Why This Works at Hand Size

With ~6-8 radical groups and ~8-12 sound groups, a 15-card hand is very likely to contain multiple matches on both axes. Compare: with 40-50 individual radicals and a 15-card hand, matches would be rare and the game unplayable.

### Challenge Types (likely retained regardless of mechanic)

| Type | Prompt | Player Produces | Notes |
|---|---|---|---|
| Meaning | English meaning | Correct character | Recognition |
| Character | Character displayed | Identify from options | Recognition |
| Pinyin | Pinyin text | Correct character | Recognition |
| Tone | Character + toneless pinyin | Correct tone | Recognition |
| Recall Pinyin | Character (no options) | Type correct pinyin | Production — unlocks for well-known cards only |

SRS tracks per-card, per-type accuracy independently. A player who recognizes a character visually but can't recall its pinyin gets more pinyin challenges for that card. Zero configuration needed.

---

## Economy (TBD)

Economy design depends on the core game mechanic and the maxed-card spend mechanic. Previous iteration used dual currencies (coins + tiles) tied to a battle/shop loop — tiles have been removed; see Appendix A for reference.

What's likely retained:
- Coins earned through correct reviews
- A shop or unlock system for spending them
- Economy scaling by HSK level (harder characters = richer reward)
- The "one or two more sessions" tension — player is always slightly short of what they need next

What's uncertain:
- What currency buys (was: card upgrades, radical forging, shop items)
- How the maxed-card spend mechanic interacts with economy

---

## Radicals

Radicals are a natural grouping mechanism for the collection. ~80-90% of Chinese characters are semantic-phonetic compounds (radical + phonetic component). High-frequency radical coverage:
- 氵 (water): 没, 法, 河, 湖, 海, 洗, 清, 活, 流, 深, 温, 满, 游, 注 — 15+
- 言/讠 (speech): 说, 话, 语, 读, 请, 让, 记, 认, 识, 词, 课, 谈 — 14+
- 忄 (heart): 想, 思, 意, 感, 忙, 快, 慢, 怕, 情, 愿, 忘, 惯 — 14+
- 扌 (hand): 打, 找, 把, 拿, 拉, 推, 提, 换, 接, 搬 — 13+

~40-50 high-frequency radicals cover the vast majority of HSK 2-5 characters. Characters without decomposable radicals (水, 人, 大, 山, 火) stand alone.

### Role in the Game (Resolved)

Radicals serve as the **strategic axis** in the board game — the elemental type system. Each radical group has strengths and weaknesses against other groups in a circular matchup cycle (like rock-paper-scissors extended to 6-8 groups).

**What the player learns:** Radical recognition as a real Chinese literacy skill. In Chinese, most characters contain a radical that hints at meaning. The game teaches this by making radical recognition a tactical requirement — you need to know a card's radical group to play it effectively on the board.

**How it works in gameplay:**
- Each card belongs to a radical group based on its primary radical
- Radical groups have a circular strength/weakness cycle: some beat others, some lose, most are neutral
- Playing a card with radical advantage against an adjacent card gives a power bonus
- Playing into a weakness gives a penalty
- The player who understands radical relationships plays better

**Design note:** The matchup cycle should feel somewhat intuitive where possible (Water > Fire makes sense) but some matchups will be arbitrary since the groups are linguistic, not elemental. Not every group needs a strong/weak matchup — many can be neutral. The cycle exists for strategic depth, not as a full type chart.

**Learning payoff:** The player starts to decode unfamiliar characters — "I don't know this character but it has 氵, so it's water-related." This is exactly how literate Chinese readers use radicals in practice. The game teaches this skill as a side effect of strategic play.

**Sound groups serve as the power axis** — a card's sound group influences its base strength and enables synergy bonuses when same-rime cards are placed adjacent on the board. This teaches phonetic component recognition: many characters sharing a phonetic component sound similar (青 qīng → 清 qīng, 请 qǐng, 情 qíng).

Together, the two axes mirror the actual structure of Chinese characters: **radical hints at meaning, phonetic component hints at sound.** The player who masters both axes is learning the two fundamental decoding strategies for the Chinese writing system.

---

## Card Progression

Cards progress through SRS mastery alone — no separate upgrade mechanic. Visual tier reflects genuine knowledge state (see Card Rarity = SRS Mastery table in Core Loop).

### Word Fusion (likely retained)

Fusing two mastered character cards into a multi-character word card (电 + 影 = 电影) is a strong candidate for the maxed-card spend mechanic. It teaches vocabulary composition and creates a satisfying collection moment. Details depend on the spend mechanic decision.

### Daily & Weekly Goals (removed — revisit later)

- **Daily Goal:** SRS-curated pack with a themed focus. Completing awards streak increment.
- **Weekly Challenge:** Larger goal revealed Monday. Gives the week structure and direction. Significantly larger reward.
- **Status:** Source code removed. Revisit when session flow is finalized.

---

## Mastery Milestones

Permanent rewards earned through demonstrated learning — milestone achievements that reflect genuine accomplishment.

### Examples

| Milestone | Trigger | Reward |
|---|---|---|
| Tone Mastery | 50 correct fourth-tone reviews | TBD — cosmetic, currency, or collection bonus |
| HSK Level Mastery | 90% of HSK 3 characters at stable retention | TBD |
| Radical Mastery | All water-radical cards at rare+ tier | TBD |
| Streak Mastery | 30-day study streak | TBD |
| Fusion Mastery | Fuse 10 word cards | TBD |

Milestones should be achievable but not trivial — each represents a genuine learning accomplishment. Reward specifics depend on economy and game mechanic decisions.

---

## SRS Engine (The Core)

The SRS algorithm is the product. Everything else is presentation. Implementation: FSRS (Free Spaced Repetition Scheduler), the algorithm adopted by Anki. Open-source, well-documented, current state of the art.

### Invisibility Principle

Player never sees intervals, scheduling numbers, difficulty ratings, ease factors, forgetting curves, or review counts. They experience card rarity: new cards have basic art, well-known cards are visually rich and animated. The algorithm controls pack contents, challenge types, and card tier.

### Per-Card, Per-Type Tracking

SRS tracks each character across all five challenge types independently (meaning, character, pinyin, tone, recall pinyin). Per-card, per-type accuracy means targeted review with zero configuration.

### SRS as Pack Curator

SRS doesn't just schedule reviews — it curates packs. A daily pack is composed to balance:
- Routine maintenance (commons) — the bulk, keeps known cards fresh
- Struggling cards — need more reps, show up frequently
- New introductions — limited per day to avoid overwhelm (FSRS controls pacing)
- Returning mastered cards — haven't been seen in weeks/months, the "epic pull"

The composition shifts as the player progresses. Early on, packs are mostly new cards. At HSK 4 with 500+ learned characters, packs are mostly maintenance with rare new introductions.

---

## Shop (TBD)

Whether a shop exists and what it sells depends on the economy and game mechanic. Previous iteration had a rotating shop with radicals, boosts, HP, and card packs (see Appendix A).

---

## Progression & Retention

### HSK Level Tracking

Player sets starting HSK level on first launch. Level advances when SRS mastery threshold is met (e.g., 85% of characters at stable long-term retention). Cannot be gamed — reflects genuine knowledge.

### Collection Grid

Visual grid of all characters in current HSK range. Characters start greyed out, fill in as learned. Card visual richness reflects SRS mastery tier. The collection is the primary progression surface — opening it should feel like looking at a card binder that's filling up over time.

### Streaks and Daily Engagement

Three goal layers:
- **Short-term:** Today's daily pack
- **Medium-term:** This week's challenge
- **Long-term:** HSK level progression + card collection completion

---

## Dopamine Map

| Moment | Frequency | Intensity | Driver |
|---|---|---|---|
| Common card reviewed correctly | Every few seconds | Low | Quick flip, satisfying sound, rhythm |
| Struggling card finally nailed | Several per session | Medium | Relief, card stabilizes |
| New card revealed in pack | 1-3 per session | High | Full reveal animation, new addition to collection |
| Returning mastered card appears | 0-2 per session | High | Epic pull — "I haven't seen this in weeks" |
| Card tier promotion (SRS upgrade) | A few per week | High | Visual evolution, collection grid updates |
| Word fusion (maxed card spend) | Rare | Very High | Fusion animation, new word card, vocabulary learned |
| Daily pack complete | Once per day | Medium-High | Streak increment, session summary |
| Weekly challenge complete | Once per week | Very High | Major reward, sense of mastery |
| Mastery milestone unlock | Rare | Very High | Permanent reward, pride |
| HSK level advancement | Very rare | Very High | Major progression marker |

The SRS algorithm generates the rarity curve. Cards aren't randomly rare — they're visually rich because you've truly learned them. A legendary card in your collection represents genuine mastery, not grinding.

---

## Build Phases

### Phase 1: Foundation
Get the SRS engine, data pipeline, and collection working. No game mechanic yet — just the core systems.

1. FSRS algorithm — port from ts-fsrs to GDScript as standalone module
2. HSK 2-5 character database with radical mappings, pinyin, tone, meaning
3. Character/radical database loaders and query logic
4. SRS pack curator — compose daily packs from SRS state (commons, struggling, new, returning)
5. Card state system — SRS mastery maps to visual tier (common through legendary)
6. Collection grid — browse all characters, see mastery state, locked/unlocked
7. Answer generator (plausible wrong answers per challenge type)
8. Game state management (session tracking, SRS state persistence)
9. Save/load system
10. Main menu, collection screen, pack opening screen (.tscn scenes + scripts)
11. Debug/dev tools — SRS state viewer, card inspector, pack composition debugger

**Phase 1 is a working SRS flashcard app with a collection and pack-opening loop.**

### Phase 2: Draft Phase & Core Game Feel
Add the core interaction that makes reviewing cards feel like a game.

1. Challenge type system — meaning, character, pinyin, tone
2. Session flow — open pack → review cards → session summary
3. Bonus round system — slot-machine-style power-up stages for rare/epic cards
4. Card power calculation — base power from SRS tier + bonus round boosts
5. Pack-opening animation — commons flip fast, rares get full reveal
6. Bonus round animation and UI — distinct, exciting, "YES!" feeling
7. Card tier promotion animation — visual evolution when SRS upgrades a card
8. Foil variant system — random chance on any card, visual treatment, collection tracking
9. Streak tracking and UI
10. Daily/weekly goal system (code removed — revisit when session flow is decided)

**Phase 2 makes it a game, not just flashcards.**

### Phase 3: Board Game & Collection Depth
The optional board game phase and systems that give the game long-term structure.

1. Board game — 3x3 grid, Triple Triad rules, card placement, adjacency comparison
2. Radical matchup cycle — strength/weakness resolution between radical groups
3. Rime synergy system — adjacent same-rime cards get power boost
4. Computer opponent — hand construction, AI placement logic, difficulty scaling
5. Parallax card capture system — computer cards can be parallax variants, captured on win
6. Card variant collection tracking — standard, foil, parallax per character
7. Hand selection UI — choose best 5 from drafted cards
8. Practice mode — no-stakes board game, no rewards, no risk
9. Economy and currency system
10. Achievement/badge system — definitions, unlock tracking, gallery screen
11. Statistics dashboard — session history, accuracy over time, per-character stats
12. Character/card detail view — tap collection grid cell for deep dive (shows variants owned)
13. Mastery milestones
14. Maxed card spend mechanic (TBD — fusion, shatter, unlock, or other)

**Phase 3 adds the board game and long-term goals.**

### Phase 4: Polish, Endgame & Expansion
1. Open world / opponent exploration — FFVIII-style map, NPCs with different rule sets
2. Beginner/mid/advanced/boss NPCs as natural tutorial progression
3. Survival / challenge mode — high-stakes, risk your collection
4. Recall Pinyin challenge type (unlocks for well-known cards)
5. Notification system — SRS-driven reminders, push notification bridge
6. Economy tuning and balance pass
7. Accessibility — font scaling, color blind mode, haptic feedback
8. Save data migration system
9. Art, audio, VFX polish
10. Word fusion system (if that's the maxed card spend mechanic)

**Phase 4 adds endgame content, polish, and expansion. Each phase is independently shippable.**

---

## File Inventory

File inventory will be updated once the core game mechanic is decided. Phase 1 systems are stable regardless of mechanic choice:

### Stable (Phase 1 — build now)

**Autoloads (5):** signal_bus.gd, game_state.gd, save_manager.gd, audio_manager.gd, accessibility_manager.gd

**SRS (6):** fsrs_algorithm.gd, card_state.gd, review_scheduler.gd, srs_config.gd, srs_enums.gd, pack_curator.gd

**Database (4):** character_database.gd, radical_database.gd, data_loader.gd, word_database.gd

**Collection (4):** collection_grid.gd, collection_cell.gd, card_tier_calculator.gd, collection_enums.gd

**Challenge (3):** answer_generator.gd, challenge_presenter.gd, challenge_enums.gd

**Progression (3):** player_profile.gd, streak_tracker.gd, milestone_tracker.gd

**Resource Types (6+):** character_data.gd, radical_data.gd, card_visual_state.gd, pack_data.gd, achievement_data.gd, session_data.gd

**Scene Scripts (~15):** main_menu, collection_screen, pack_opening_screen, session_summary_screen, settings_screen, card_detail_screen, debug_screen + component scripts (collection_cell, card_display, pack_card, streak_display, etc.)

**Debug (3):** debug_overlay.gd, card_inspector.gd, srs_state_viewer.gd

**Save/Migration (2):** migration_manager.gd, migration_registry.gd

**Tests (~40+):** mirrors src/ structure + integration tests

**Data (12+):** HSK 2-5 character JSONs, radical map, word fusion rules (daily goals and weekly challenge data removed)

**Python Tools (6+):** parse_hsk_data.py, build_radical_map.py, build_word_fusion_map.py, generate_goals.py, validate_data.py, analyze_economy.py

### Phase 2 Files (Draft Phase & Game Feel)

**Bonus Round (4):** bonus_trigger.gd, bonus_round_manager.gd, bonus_challenge_sequencer.gd, bonus_enums.gd

**Card Power (3):** power_calculator.gd, power_boost.gd, power_enums.gd

**Card Variants (3):** variant_tracker.gd, variant_enums.gd, foil_roller.gd

**Scene Scripts (~8):** bonus_round_screen.gd, power_up_display.gd, bonus_challenge_card.gd, foil_reveal.gd, session_summary_screen.gd (update), pack_opening_screen.gd (update), card_display.gd (update), card_component.gd (update)

**Effects (3):** foil_shader.gd, bonus_burst.gd, power_up_effect.gd

**Tests (~10):** mirrors above

### Phase 3 Files (Board Game & Collection Depth)

**Board Game (8):** board_manager.gd, board_grid.gd, board_cell.gd, adjacency_resolver.gd, capture_logic.gd, hand_selector.gd, board_enums.gd, board_config.gd

**Computer Opponent (4):** opponent_ai.gd, opponent_hand_builder.gd, opponent_difficulty.gd, opponent_enums.gd

**Radical Matchups (4):** radical_cycle.gd, matchup_resolver.gd, matchup_table.gd, radical_game_enums.gd

**Rime Synergy (3):** rime_detector.gd, rime_synergy_calculator.gd, rime_enums.gd

**Capture/Variants (3):** parallax_roller.gd, capture_manager.gd, variant_collection.gd

**Scene Scripts (~12):** board_game_screen.gd, board_cell_component.gd, hand_selection_screen.gd, opponent_display.gd, capture_reveal.gd, practice_mode_screen.gd, variant_showcase.gd, card_detail_screen.gd (update), collection_screen.gd (update), collection_cell.gd (update), plus component scripts

**Effects (4):** parallax_shader.gd, capture_effect.gd, rime_synergy_effect.gd, radical_matchup_effect.gd

**Tests (~15):** mirrors above

### Phase 4 Files (Endgame & Expansion)

**Open World (6):** world_map.gd, npc_manager.gd, npc_data.gd, encounter_manager.gd, npc_rule_sets.gd, world_enums.gd

**Survival Mode (4):** survival_manager.gd, survival_stakes.gd, survival_opponent_scaler.gd, survival_enums.gd

**Scene Scripts (~8):** world_map_screen.gd, npc_encounter_screen.gd, survival_screen.gd, survival_results.gd, plus component scripts

**Tests (~8):** mirrors above

### Architecture: Component-Based Design

This project follows Godot-idiomatic component-based architecture:

- **One script per scene node** — each node owns its behavior, composed in scene trees
- **Custom Resource types** — typed data structures (`extends Resource`) rather than raw dictionaries
- **Shared enum/constant files** — one per system directory for cross-file type safety
- **Composition over inheritance** — small focused scripts wired together, not deep class hierarchies
- **Tests mirror src/** — every logic file gets a corresponding test; integration tests for cross-system flows

---

## Built Ahead of Phase

The following systems were implemented during the initial Phase 1 build but belong to later phases or the previous JRPG iteration (Appendix A). They exist in the codebase, compile, and have tests — but are **not wired into the Phase 1 core loop**. They can be adapted or replaced when their phase arrives.

### From Appendix A (JRPG battler artifacts)
These were built based on the previous iteration's design. Most have been removed to keep Phase 1 lean. They'll be rebuilt when their phase arrives.

- **`src/economy/`** — **Removed.** Was: CoinManager, EconomyScaler, DropCalculator. Coin-based economy from the JRPG iteration. Economy design is TBD per planning doc.
- **`src/shop/`** — **Removed.** Was: ShopManager, ShopRotation, ShopItem. Rotating shop selling radicals. Shop design is TBD.
- **`src/run/`** — RunManager, DifficultyManager, RoundManager. Difficulty scaling. Maps to the JRPG battle flow, not the pack-opening flow. (ComboManager removed — combos no longer fit the design.)
- **`src/radicals/`** — **Removed.** Was: RadicalActivator, RadicalBonusCalculator, RadicalManager. Radical equip/activate/bonus system from the battler. Radicals' actual Phase 3 role is as the board game's strategic axis. Radical *data* (`src/database/radical_data.gd`, `radical_database.gd`) is retained.
- **`src/database/word_database.gd`** — **Removed.** Was an unused word lookup for future fusion. Rebuild when word fusion lands in Phase 3+.

### Phase 2+ systems (built early)
These are directionally correct but premature for Phase 1.

- **`src/sentences/`** — **Removed.** Was: SentenceBuilder, SentenceValidator, BossRoundManager, DailyGoalManager, WeeklyTrialManager. Sentence building and boss rounds belong to Phase 2+ when the session flow is fleshed out. Rebuild from scratch when needed.
- **`src/swipe/swipe_detector.gd`, `card_display.gd`** — Swipe-based interaction. The core challenge mechanic is TBD (might be swipe, might be something else). AnswerGenerator and ChallengePresenter are usable regardless of mechanic.
- **`scenes/screens/run_select.gd`** — Screen script for features not in Phase 1. (boss_round_screen and daily_weekly_screen removed.)

### Removed scene scripts and components
- `scenes/screens/shop_screen.gd` — **Removed** with shop system.
- `scenes/components/coin_counter.gd` — **Removed** with coin system.
- `scenes/components/shop_item_card.gd` — **Removed** with shop system.
- `scenes/components/radical_badge.gd` — **Removed.** Was a rarity-tinted equipped-state UI badge tied to the equip system.
- `scenes/components/combo_counter.gd` — **Removed.** Combo system no longer fits the design.
- `scenes/components/sentence_slot.gd`, `tile_slot.gd` — **Removed.** Were sentence builder UI components.

### What IS Phase 1 (wired and working)
- FSRS algorithm (`src/srs/`) — full FSRS-6 port
- Card state + tier mapping (`card_state.gd`, `card_tier_calculator.gd`, `card_visual_state.gd`)
- Pack curator (`pack_curator.gd`, `pack_data.gd`)
- Character/radical databases (`src/database/`)
- Collection grid (`collection_grid.gd`, `collection_enums.gd`)
- Answer generator (`answer_generator.gd`, `challenge_enums.gd`)
- Game state + save/load (`src/autoload/`)
- Debug tools (`src/debug/`)
- **Missing: all .tscn scene files** — nothing is runnable in Godot yet

---

## FSRS Algorithm Notes

Port from ts-fsrs (TypeScript). Key concepts:
- Each card has a **state** (New, Learning, Review, Relearning)
- Each card tracks **stability** (how long before 90% recall probability) and **difficulty** (0-10 scale)
- On review, the algorithm computes next interval based on rating (Again, Hard, Good, Easy)
- We track per-card, per-challenge-type (meaning/character/pinyin/tone/recall_pinyin) independently
- SRS mastery determines card visual tier — stability maps to collection rarity
- SRS curates daily packs — balances maintenance, struggling, new, and returning cards
- Source repo: https://github.com/open-spaced-repetition/ts-fsrs

---

## Data Format Reference

### Character Entry
```json
{
  "character": "清",
  "pinyin": "qing",
  "tone": 1,
  "meaning": "clear, pure",
  "hsk_level": 3,
  "radicals": ["氵"],
  "components": ["氵", "青"],
  "is_radical": false,
  "is_standalone": true,
  "frequency_rank": 412
}
```

### Radical Entry
```json
{
  "radical": "氵",
  "meaning": "water",
  "rarity_tier": "common",
  "shop_cost": 50,
  "characters": ["没", "法", "河", "湖", "海", "洗", "清", "活", "流", "深", "温", "满", "游", "注"],
  "display_name": "Water (three drops)"
}
```

### Word Fusion Entry
```json
{
  "word": "电影",
  "pinyin": "diànyǐng",
  "meaning": "movie",
  "components": ["电", "影"],
  "hsk_level": 2
}
```

---

## Open Questions

### Resolved
- [x] **Core game mechanic** — Two-phase session: draft (SRS pack opening with challenges) + optional board game (Triple Triad-style 3x3 grid placement). See Game Mechanic section.
- [x] **Radical role in game** — Radical groups form a circular strength/weakness cycle on the board game. Strategic axis.
- [x] **Sound group role in game** — Sound groups determine power and enable adjacency synergy bonuses. Power axis.
- [x] **Card variants** — Two collectible visual variants: foil (random chance in draft) and parallax (captured in board game).
- [x] **Board game motivation** — Capture parallax card variants, earn bonus currency, gives draft phase stakes.
- [x] **Pack-only viability** — Pack opening stands alone as a complete session. Board game is optional.

### Open
- [ ] **Maxed card spend mechanic** — what happens when a card reaches full mastery? Fusion, shatter, unlock, or other?
- [ ] **Economy** — one currency or two? What does it buy?
- [ ] **Exact radical cycle** — which groups beat which? How many neutral matchups? Should it feel intuitive (Water > Fire) or is arbitrary acceptable?
- [ ] **Rime synergy balance** — how often does it realistically trigger? Is the bonus generous enough to chase? Needs data analysis of rime family distribution across HSK 2-5.
- [ ] **Pack size** — 10 or 15 cards? 15 may create sessions that are too long (15-60 interactions in draft alone). Needs playtesting. Leaning toward 10-12.
- [ ] **Computer opponent hand construction** — how are values assigned? Always max power? Random? Scaled to player? Directly affects difficulty and fairness.
- [ ] **Bonus round trigger rate** — how often should rare/epic cards trigger the slot-machine-style power-up bonus? Too frequent = exhausting, too rare = forgettable.
- [ ] **Board game card power visibility** — how much math is shown to the player? Base power + boosts + radical matchup + rime synergy = potentially opaque. Needs clean UI solution.
- [ ] **Bad beat protection** — what happens when SRS gives you 12 commons and 3 struggling cards you fumble? Practice mode helps, but should there be pack composition guarantees?
- [ ] **Beginner onboarding for board game** — new players don't understand radical groups yet. Beginner NPCs in open world mode solve this, but what about before open world is built?
- [ ] **Endgame** — what happens when most cards are mastered? Collection is full, packs are trivial, board game is easy. Survival/challenge mode? New HSK levels? Word fusion as endgame content?
- [ ] **Session length variance** — struggling players get longer, more punishing sessions. Same problem as Anki. Need guardrails or session length caps?
- [ ] Monetization model (premium, freemium, subscription) — educational audience favors non-predatory
- [ ] Traditional vs Simplified character support — HSK uses simplified; affects data pipeline; Phase 1 blocker if both
- [ ] Native speaker audio for characters — significant learning enhancement, requires licensing/recording
- [ ] Art direction (pixel art, minimalist, illustrated) — must feel distinct from Duolingo
- [ ] Multiplayer/social features (leaderboards, shared weekly trial rankings, friend challenges) — retention boost but large scope increase
- [ ] Game title

### Deferred (Explore Later)
- [ ] **Open world / FFVIII-style opponent exploration** — walk around finding opponents with different rule sets. Natural tutorial system. Large scope increase. Phase 3+.
- [ ] **Survival / challenge mode** — high-stakes mode risking card collection. Could be ranked/multiplayer. Phase 4+.
- [ ] **Blockchain / NFT cards** — tradeable cards between players. Fundamentally changes scope, audience, legal requirements. Interesting but would polarize audience. Explore only if the game builds a significant player base.
- [ ] **Social network for buddies** — deterministic AI personas spawned from player profiles that socialize autonomously (Stardew Valley meets Claude Code /buddy). Fun concept, separate project scope. See Design Inspirations section.
- [ ] **Power-ups and special abilities** — cards with unique abilities beyond base stats. Could layer onto board game later.
- [ ] **Two visual variants may not be enough** — foil and parallax are two things to chase across 1,350 characters. Compare Marvel Snap's 8+ visual tiers per card. May need more variants for long-term collection motivation.

---

## Design Questions to Resolve

### 1. Recall challenge type
**Resolved.** Fifth challenge type: **Recall Pinyin.** Character appears with no options, player types pinyin. Only triggers for well-known cards. SRS tracks independently. Unlocks once player has enough mastered pinyin cards. Phase 4 feature.

### 2. Wrong-answer feedback
**Unresolved.** Depends on core game mechanic. The correct answer needs to be shown briefly without breaking flow. Options depend on whether the mechanic is swipe, battle, or something else.

### 3. HSK level progression pacing
**Partially resolved.** Collection completion percentage is now a more natural progression metric than HSK level alone. HSK level could be a milestone marker rather than the primary number. Collection grid filling up IS the progression.

### 4. SRS algorithm serving too many roles
**Identified risk.** The SRS algorithm determines: what you learn, when you learn it, pack composition, card rarity, card power, AND what the board game feels like. If you tweak SRS for better learning, you might break game balance. If you tweak for game feel, you might compromise learning science. **Resolution:** Establish a clear hierarchy — SRS learning comes first, game feel is shaped around it, never the other way around. Pack composition may need separate constraints on top of SRS (e.g., guaranteeing at least 1 rare per pack for game viability even if SRS wouldn't naturally schedule one).

### 5. Power curve inversion over time
**Identified risk.** As players learn more, their formerly-rare cards graduate to common (mastered). Late-game players have decks full of "weak" commons. The power curve deflates as you get better — opposite of most games. **Possible resolutions:** Endgame content (survival mode, word fusion, new HSK levels), or accept that completing the collection = completing the app. The dopamine should shift from card power to collection completion and challenge mastery.

### 6. Target audience tension
**Identified risk.** The game targets HSK 2-5 learners who want SRS AND enjoy card games AND want collection mechanics AND will learn radical/rime systems as gameplay. That's narrow. **Resolution:** The primary audience is learners who find Anki boring. The card game is the hook, not the requirement. Every game mechanic must be optional for players who just want better flashcards. Foil/parallax and the board game are retention draws, not core requirements.

---

## Design Inspirations

### Triple Triad (FFVIII)
Core board game reference. Dead simple mechanics (place card, compare adjacent values, higher wins) with high replayability through positional strategy. The appeal is simplicity — a child can learn it in one round, but placement decisions create depth. Our board game phase aims for this same simplicity: the learning happens in the draft, the board game is the fun reward.

### Marvel Snap
Two-axis card design reference. Every card has Cost (energy, when you play it) and Power (strength). Our equivalent: Radical Group (what it does / type matchup) and Sound Group / SRS Mastery (how strong it is). Marvel Snap's depth comes from abilities that bend the cost/power relationship — our depth comes from radical matchups and rime synergies that bend raw power.

### Claude Code /buddy (Anthropic)
Deterministic character generation reference. Hashes user account UUID + salt → seeds PRNG → draws species, rarity, stats, cosmetics. Same character every time, no cheating. "Bones vs Soul" architecture: deterministic traits recomputed every session, LLM-generated personality stored permanently. This approach could inform:
- **Card art generation:** Hash character + radicals + tone + frequency → deterministic visual properties per card (color palette, effects, border style). Every character looks distinct without hand-crafting 1,350 art assets.
- **Radical group visual theming:** Each group gets a deterministic aesthetic generated from group properties. Cards inherit visual DNA from their radical group — you can *see* the linguistic relationships.
- **Future social features:** Player personas spawned from profile data that socialize autonomously. "Send your buddy into the commons, recall them to hear stories." Stardew Valley energy — passive, cozy, check-in-based.

### Stardew Valley
Retention and tone reference. Low-stakes autonomy — show up, do whatever you want, everything gently rewards you. The "one more day" loop. "My parsnips grew" is somehow compelling — same energy as "my card evolved" or "my agent made a friend." The lesson: not every part of the game needs to teach. Some parts just need to make you open the app.

### Anki / FSRS
The science underneath everything. Spaced repetition works. The problem is nobody wants to use it. Average Anki session: 10-15 minutes. Our draft phase targets the same review volume wrapped in pack-opening dopamine. Same learning, same time, doesn't feel like Anki.

---

## Appendix A: Previous Iteration — JRPG Card Battler

The following systems were designed for a JRPG card battler framing. This iteration has been set aside while the core game mechanic is reconsidered, but these ideas may be revisited or adapted.

### Battle Mechanic

JRPG-style battle scene. Enemies appear on one side, player's hand of character cards on the other. Each enemy displays a possible answer. Player drags the correct card onto the matching enemy to attack. HP system (50-100 HP per run), wrong answers cause enemy attacks.

### Deck Building

Player builds a 20-30 card deck before each run from their collection. Balances mastery (strong cards) against review needs (weak cards). Equips radicals for elemental synergies. Run types: Easy (free, comfortable) or Challenge (costs coins, harder, richer rewards).

### Combo System (removed)

Consecutive correct plays build a combo multiplier. Wrong answer halves combo (not reset). "About to Forget" cards don't break combo on miss. Combo counter is the moment-to-moment engagement driver. **Status:** Source code removed. The pack-opening + draft direction doesn't lean on streak-based pressure.

### Radical Elements

Radicals as elemental affinities (MTG colors equivalent). Playing same-element cards in sequence triggers synergy bonuses. Two activation modes: elemental synergy (common) and radical attach (special event). Radical rarity tiers: Common (12-15+ chars, 40-50 coins), Rare (7-11 chars, 100-120 coins), Epic (3-6 chars, 300-350 coins).

### Currency Economy

- **Coins**: earned per correct play, spent on card upgrades, word fusion, radical forging, challenge run entry fees, rotating shop (radicals, planet boosts, HP, card packs)
- Economy scaling by HSK level (harder cards = richer reward)

### Card Upgrades

Spend coins to level up card battle stats. 4 levels, unlocks card ability at max. Separate from SRS state.

### Rotating Shop

Small curated selection between runs. Radicals, planet boosts, extra HP, card packs. Rotates to create urgency.

### SRS-Driven Card Power (Battle Version)

| State | Card Appearance | Battle Effect | Coin Multiplier |
|---|---|---|---|
| Mastered | Full art, solid glow | Full attack power | 1x |
| Stable | Standard | Normal attack | 1x |
| Fading | Cracks, dimming | Reduced attack | 1.5x |
| About to Forget | Pulsing glow, urgent audio | Weakened but 3-5x coins | 3-5x |
| New | Discovery animation | Low stats, high potential | 2x |

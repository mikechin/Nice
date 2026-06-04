#!/usr/bin/env python3
"""Apply the curated combat `effect` field to HSK 2-3 character data (Phase 3, M5).

Each character maps to ONE of the six EffectEnums.Kind archetypes by MEANING — the
hand-curated pass the EffectPalette was built to consume (resolution step 1, ahead of
the per-glyph override, the meaning-keyword scan, and the code-point fallback). Writing
it here makes the kit's ability layer authored data instead of inferred, so the palette
no longer leans on keyword guesses for these two levels.

The six kinds (see src/power/effect_enums.gd):
  strike  passive  +attack            big / strong / force / quantity / aggression
  ward    passive  +max HP & block    safe / home / walls / clothing / containment / endure
  focus   passive  +crit              perception / mind / knowledge / language / precision
  surge   passive  +ATB & accuracy    speed / movement / travel / directions
  burn    active   dmg on a correct   fire / heat / sun / light / warm colors
  mend    active   heal on a correct  water / food / drink / rest / nature / nurture

Curated values for the iconic glyphs match EffectPalette.CHAR_OVERRIDE so the two
sources never disagree. Re-runnable and idempotent: it rewrites the field in place,
preserving the file's key order (effect sits right after meaning), 2-space indent and
raw CJK.

    python tools/apply_effects.py            # apply + report
    python tools/apply_effects.py --check    # validate only, write nothing (CI-friendly)
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

VALID_KINDS = {"strike", "ward", "focus", "surge", "burn", "mend"}

# Where the field is inserted in each character dict (keeps the files readable).
INSERT_AFTER = "meaning"

DATA_FILES = ["godot-project/data/hsk2/characters.json", "godot-project/data/hsk3/characters.json"]

# character -> effect kind. Curated by meaning; 310 entries across HSK 2-3.
# Grouped by kind for review, applied as a flat map (a glyph shared across levels
# resolves identically in both).
CURATION: dict[str, str] = {}


def _add(kind: str, chars: str) -> None:
    for ch in chars.split():
        if ch in CURATION:
            raise SystemExit(f"duplicate curation entry for {ch}")
        CURATION[ch] = kind


# -- strike: force, magnitude, quantity, aggression -------------------------------
_add("strike", "百 长 打 大 男 千 手 踢 张 最 做")
_add("strike", "把 搬 办 成 除 担 干 刚 高 广 害 汉 坏 极 举 拿 努 双 死 太 提 更 多 力 锻 牛")

# -- ward: shelter, containment, body, clothing, endurance, family kin ------------
_add("ward", "别 宾 穿 等 弟 房 非 服 哥 公 共 狗 孩 黑 后 姐 慢 妹 门 旁 铅 请 身 体 晚 姓 阴")
_add("ward", "安 包 被 层 城 迟 冬 根 关 久 旧 客 口 裤 老 楼 帽 难 胖 皮 裙 容 伞 世 结 地 护")

# -- focus: perception, mind, knowledge, language, precision, number/order --------
_add("focus", "吧 白 报 比 错 得 第 懂 对 该 告 贵 会 件 教 介 考 可 课 两 零 买 卖 每 您")
_add("focus", "时 事 说 虽 它 题 条 同 完 为 问 希 习 现 知 准 找 着 真 正 要 也 已 意 因")
_add("focus", "啊 半 鼻 表 才 差 词 聪 答 当 调 短 段 方 费 分 附 感 管 或 记 季 检 简 见 角")
_add("focus", "解 句 决 刻 历 练 亮 明 片 其 奇 然 认 如 试 算 特 听 了 接 画 号 眼 耳 年")

# -- surge: speed, movement, travel, directions, flight ---------------------------
_add("surge", "唱 出 次 从 到 过 还 回 机 进 近 就 开 快 离 路 旅 马 忙 跑 便 票 起")
_add("surge", "去 上 外 玩 往 先 向 新 远 运 再 早 左 走 瘦")
_add("surge", "北 变 带 东 动 发 放 换 脚 经 空 南 鸟 爬 骑 轻 声 辆 超 船")

# -- burn: fire, heat, sun, light, warm colors -----------------------------------
_add("burn", "红 火 日")
_add("burn", "灯 光 黄 热")

# -- mend: water, food, drink, rest, nature, nurture, healing --------------------
_add("mend", "帮 病 给 好 花 欢 鸡 觉 妈 面 女 妻 生 送 笑 休 雪 游 鱼 洗 清 让")
_add("mend", "冰 菜 草 蛋 饿 果 河 健 节 苦 筷 蓝 累 冷 李 礼 林 绿 满 米 奶 盘")
_add("mend", "啤 瓶 秋 树 疼 甜 春")

# -- rebalancing: the first pass funnelled too many abstract/cognitive words into
# FOCUS (a third of the pool). These each have a defensible home OUT of focus — a
# re-reading, not a random spread — flattening the palette so kits feel varied.
# Particles stay focus by rule (mastering grammar = precision); these are content
# words that read better elsewhere.
for _ch, _kind in {
    "方": "surge", "找": "surge",            # direction / active search
    "完": "ward", "附": "ward", "件": "ward",  # whole-intact / attached / goods
    "接": "ward", "贵": "ward",               # catch-intercept / precious-guarded
    "练": "strike", "要": "strike", "决": "strike",  # drill / demand / decisive
    "季": "mend", "希": "mend",               # season-cycle / hope-uplift
    "亮": "burn",                            # radiance
}.items():
    CURATION[_ch] = _kind


def load(path: Path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))


def with_effect(char: dict, kind: str) -> dict:
    """Rebuild the dict so `effect` sits right after `meaning`, order otherwise kept."""
    out: dict = {}
    for key, value in char.items():
        if key == "effect":
            continue  # drop a stale one; re-inserted at the canonical spot
        out[key] = value
        if key == INSERT_AFTER:
            out["effect"] = kind
    if "effect" not in out:  # no meaning key (shouldn't happen) -> append
        out["effect"] = kind
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="validate only; write nothing")
    args = ap.parse_args()

    root = Path(__file__).resolve().parent.parent  # repo root (tools/ lives here)
    missing: list[str] = []
    bad_kind = [c for c, k in CURATION.items() if k not in VALID_KINDS]
    if bad_kind:
        print(f"ERROR: invalid kind for {bad_kind}", file=sys.stderr)
        return 1

    dist: Counter[str] = Counter()
    per_file: dict[str, int] = {}
    updates: list[tuple[Path, list[dict]]] = []

    for rel in DATA_FILES:
        path = root / rel
        chars = load(path)
        new_chars = []
        for c in chars:
            glyph = c["character"]
            kind = CURATION.get(glyph)
            if kind is None:
                missing.append(f"{rel}:{glyph} ({c.get('meaning','')})")
                new_chars.append(c)
                continue
            new_chars.append(with_effect(c, kind))
            dist[kind] += 1
        per_file[rel] = len(chars)
        updates.append((path, new_chars))

    if missing:
        print(f"ERROR: {len(missing)} character(s) have no curated effect:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        return 1

    # Curation entries not present in either data file -> likely a typo in the map.
    present = {c["character"] for _, chars in updates for c in chars}
    stray = sorted(set(CURATION) - present)
    if stray:
        print(f"WARNING: {len(stray)} curated glyph(s) not in HSK 2-3 data: {' '.join(stray)}",
              file=sys.stderr)

    if not args.check:
        for path, chars in updates:
            path.write_text(json.dumps(chars, ensure_ascii=False, indent=2), encoding="utf-8")

    verb = "would set" if args.check else "set"
    total = sum(dist.values())
    print(f"{verb} effect on {total} characters across {len(DATA_FILES)} files")
    for rel, n in per_file.items():
        print(f"  {rel}: {n} characters")
    print("distribution:")
    for kind in ("strike", "ward", "focus", "surge", "burn", "mend"):
        n = dist[kind]
        bar = "#" * round(n / 2)
        print(f"  {kind:<7} {n:>3}  {bar}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

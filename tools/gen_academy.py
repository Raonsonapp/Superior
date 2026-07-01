#!/usr/bin/env python3
"""
Superior AI Academy — курс-генератор.

Папкаҳои дарсро (аз zip) ба JSON asset табдил медиҳад, ки барнома мехонад.

Формати вуруд (ҳар қисм як папка):
    Superior_AI_Academy_Volume1_Part19/
        00_READ_FIRST.txt      -> Topic: ... / Goal: ...
        01_...txt ... 08_...txt -> дарсҳо (sections)
        09_Quiz.txt            -> тест (quiz)

Истифода:
    python3 tools/gen_academy.py <src_dir> [out_json]

Мисол:
    python3 tools/gen_academy.py ./SUPERIOR_AI assets/academy/volume1.json
"""
import os
import re
import sys
import json
import glob


def title_from_filename(fn: str) -> str:
    name = os.path.splitext(fn)[0]
    name = re.sub(r"^\d+_", "", name)  # рақами пешванд
    return name.replace("_", " ").strip()


def read(path: str) -> str:
    with open(path, encoding="utf-8", errors="ignore") as f:
        return f.read().strip()


def build(src: str) -> dict:
    parts = []
    part_dirs = sorted(
        glob.glob(os.path.join(src, "*Part*")),
        key=lambda x: int(re.search(r"Part(\d+)", x).group(1)),
    )
    for d in part_dirs:
        if not os.path.isdir(d):
            continue
        pid = int(re.search(r"Part(\d+)", d).group(1))
        topic, goal = f"Part {pid}", ""
        rf = os.path.join(d, "00_READ_FIRST.txt")
        if os.path.exists(rf):
            txt = read(rf)
            m = re.search(r"Topic:\s*(.+)", txt)
            if m:
                topic = m.group(1).strip()
            m = re.search(r"Goal:\s*(.+)", txt, re.S)
            if m:
                goal = " ".join(m.group(1).split())

        sections, quiz = [], []
        for fn in sorted(os.listdir(d)):
            if fn == "00_READ_FIRST.txt" or not fn.endswith(".txt"):
                continue
            body = read(os.path.join(d, fn))
            t = title_from_filename(fn)
            if t.lower() == "quiz":
                quiz = [
                    re.sub(r"^\s*\d+[\.\)]\s*", "", ln).strip()
                    for ln in body.splitlines()
                    if ln.strip() and not ln.strip().lower().startswith("quiz")
                ]
                quiz = [q for q in quiz if q]
            else:
                sections.append({"title": t, "body": body})

        if not sections:
            continue  # қисмҳои холиро истисно мекунем
        parts.append(
            {"id": pid, "topic": topic, "goal": goal,
             "sections": sections, "quiz": quiz}
        )

    return {
        "volume": 1,
        "title": "Superior AI Academy — Volume 1",
        "parts": parts,
    }


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "assets/academy/volume1.json"
    data = build(src)
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    total = sum(len(p["sections"]) for p in data["parts"])
    print(f"✅ {out}: {len(data['parts'])} parts, {total} sections")


if __name__ == "__main__":
    main()

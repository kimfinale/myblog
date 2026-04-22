#!/usr/bin/env python3
"""
verify_citations.py — check .bib DOIs against CrossRef metadata.

Usage:
    python scripts/verify_citations.py blog/posts/my-post/references.bib
    python scripts/verify_citations.py blog/posts/*/references.bib

For each entry that has a DOI, the script queries CrossRef and flags:
  - AUTHOR mismatch  (first-author surname differs)
  - JOURNAL mismatch (container title doesn't match)
  - YEAR mismatch    (publication year differs)

Entries without a DOI are skipped (marked SKIP).
"""

import sys
import re
import time
import json
import urllib.request
import urllib.parse

CROSSREF_URL = "https://api.crossref.org/works/{doi}"
MAILTO       = "kimfinale@gmail.com"   # CrossRef polite pool


# ── BibTeX parsing ────────────────────────────────────────────────────────────

def parse_bib(path: str) -> list[dict]:
    """Return a list of entry dicts: key, doi, author, title, journal, year."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    entries = []
    for block in re.split(r"(?=@\w+\{)", text):
        block = block.strip()
        if not block:
            continue
        key_m = re.match(r"@\w+\{([^,\s]+)", block)
        if not key_m:
            continue

        def field(name):
            # Matches  name  =  { ... }  including nested braces
            m = re.search(
                rf"{name}\s*=\s*\{{((?:[^{{}}]|\{{[^{{}}]*\}})*)\}}",
                block, re.I | re.S
            )
            return m.group(1).strip() if m else ""

        entries.append({
            "key":     key_m.group(1).strip(),
            "doi":     field("doi"),
            "author":  field("author"),
            "title":   field("title"),
            "journal": field("journal"),
            "year":    field("year"),
        })
    return entries


# ── CrossRef lookup ───────────────────────────────────────────────────────────

def crossref_lookup(doi: str) -> dict:
    url = CROSSREF_URL.format(doi=urllib.parse.quote(doi, safe="/()+"))
    req = urllib.request.Request(
        url,
        headers={"User-Agent": f"VerifyCitations/1.0 (mailto:{MAILTO})"},
    )
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            return json.load(resp).get("message", {})
    except urllib.error.HTTPError as e:
        return {"_error": f"HTTP {e.code}"}
    except Exception as e:
        return {"_error": str(e)}


def cr_first_author(msg: dict) -> str:
    authors = msg.get("author", [])
    return authors[0].get("family", "").strip() if authors else ""


def cr_journal(msg: dict) -> str:
    ct = msg.get("container-title", [])
    return ct[0].strip() if ct else ""


def cr_year(msg: dict) -> str:
    for key in ("published", "published-print", "published-online"):
        dp = msg.get(key, {})
        if dp:
            parts = dp.get("date-parts", [[]])
            if parts and parts[0]:
                return str(parts[0][0])
    return ""


# ── BibTeX first-author extraction ────────────────────────────────────────────

def bib_first_author(author_str: str) -> str:
    """Return the first author's family name from a BibTeX author string."""
    first = author_str.split(" and ")[0].strip()
    # Strip LaTeX: \" etc.
    first = re.sub(r"\\[\"'`^~]{([^}]*)}", r"\1", first)
    if "," in first:
        return first.split(",")[0].strip()
    parts = first.split()
    return parts[-1] if parts else ""


# ── Comparison ────────────────────────────────────────────────────────────────

def normalise(s: str) -> str:
    return s.lower().replace("-", " ").replace("&", "and").strip()


def check_entry(entry: dict) -> tuple[str, list[str], dict]:
    """
    Returns (status, issues, cr_meta) where status is 'OK'|'MISMATCH'|'ERROR'|'SKIP'.
    """
    if not entry["doi"]:
        return "SKIP", [], {}

    msg = crossref_lookup(entry["doi"])
    if "_error" in msg:
        return "ERROR", [msg["_error"]], {}

    issues = []

    # Author
    bib_a = bib_first_author(entry["author"])
    cr_a  = cr_first_author(msg)
    if bib_a and cr_a and normalise(bib_a) != normalise(cr_a):
        issues.append(f"AUTHOR  bib={bib_a!r}  crossref={cr_a!r}")

    # Journal
    bib_j = entry["journal"]
    cr_j  = cr_journal(msg)
    if bib_j and cr_j:
        if normalise(cr_j) not in normalise(bib_j) and \
           normalise(bib_j) not in normalise(cr_j):
            issues.append(f"JOURNAL bib={bib_j!r}  crossref={cr_j!r}")

    # Year
    bib_y = entry["year"]
    cr_y  = cr_year(msg)
    if bib_y and cr_y and bib_y != cr_y:
        issues.append(f"YEAR    bib={bib_y!r}  crossref={cr_y!r}")

    status = "MISMATCH" if issues else "OK"
    cr_meta = {
        "author":  cr_a,
        "journal": cr_j,
        "year":    cr_y,
        "title":   (msg.get("title") or [""])[0][:90],
    }
    return status, issues, cr_meta


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    paths = sys.argv[1:]
    if not paths:
        print(__doc__)
        sys.exit(0)

    total_ok = total_miss = total_err = total_skip = 0

    for bib_path in paths:
        print(f"\n{'='*64}")
        print(f"  {bib_path}")
        print(f"{'='*64}")

        try:
            entries = parse_bib(bib_path)
        except FileNotFoundError:
            print(f"  ERROR: file not found")
            continue

        for e in entries:
            status, issues, meta = check_entry(e)
            tag = f"[{e['key']}]"

            if status == "SKIP":
                print(f"  {tag:<30} SKIP  (no DOI)")
                total_skip += 1
            elif status == "ERROR":
                print(f"  {tag:<30} ERROR  {issues[0]}")
                total_err += 1
            elif status == "OK":
                print(f"  {tag:<30} OK    (author={meta['author']!r})")
                total_ok += 1
            else:  # MISMATCH
                print(f"  {tag:<30} MISMATCH")
                for iss in issues:
                    print(f"    ! {iss}")
                if meta["title"]:
                    print(f"    CrossRef title: {meta['title']}")
                total_miss += 1

            if status not in ("SKIP",):
                time.sleep(0.4)   # respect CrossRef rate limits

    grand = total_ok + total_miss + total_err + total_skip
    print(f"\n{'─'*64}")
    print(f"  Grand total: {grand} entries — "
          f"{total_ok} OK, {total_miss} mismatches, "
          f"{total_err} errors, {total_skip} skipped (no DOI)")
    print(f"{'─'*64}")

    sys.exit(1 if (total_miss or total_err) else 0)


if __name__ == "__main__":
    main()

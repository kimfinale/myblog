# Verify bibliography citations

Audit a Quarto post's `references.bib` for hallucinated or incorrect entries.
Run this after writing any post that contains an AI-generated bibliography.

## What to audit

If the user specified a path (e.g. `/verify-citations blog/posts/my-post/`), use that directory.
Otherwise use the post currently open in the IDE, or ask the user which post to check.

## Steps

1. **Run the script** to do all CrossRef lookups in one shot:
   ```
   python scripts/verify_citations.py <path>/references.bib
   ```
   The script checks every DOI against CrossRef and prints a compact report:
   `OK`, `MISMATCH` (with details), `ERROR`, or `SKIP` (no DOI) for each entry.

2. **For SKIP entries** (no DOI), web-search the title to confirm the paper exists.

3. **For MISMATCH or ERROR entries**, investigate only those:
   - If the DOI resolved to a completely different paper, web-search the correct paper
     by title + first author to find the real DOI.
   - If it is a metadata mismatch (author/journal/year off by one), prefer CrossRef's
     values as authoritative unless the bib's journal-issue year is clearly correct
     (online-first vs print publication).

4. **Read the post's `index.qmd`** and find every place an author name is mentioned
   explicitly in prose (e.g. "Smith et al. showed…"). Verify those names match the
   corrected bib.

5. **Produce a verdict table** with columns: `key | status | problem | correct value`.
   Statuses: ✅ OK · ⚠️ MISMATCH · ❌ HALLUCINATED · ⬛ NO DOI.

6. **Fix automatically**: rewrite `references.bib` with all corrections applied.
   - For hallucinated entries that *are cited* in the text: replace with the real paper
     and update the citation key in `index.qmd`.
   - For hallucinated entries that are *not cited*: remove them.
   - Fix any in-text author mentions in `index.qmd` that are now wrong.

7. **Re-render** the post:
   ```
   quarto render <path>/index.qmd
   ```

8. **Report** a summary: how many entries were OK, how many fixed, how many removed.

## Notes

- The script queries CrossRef with a polite User-Agent (mailto set to the user's email).
- CrossRef `author[0].family` is authoritative for first-author surname.
- Common hallucination pattern: correct title + wrong DOI — the DOI resolves to a
  completely different paper in the same journal.
- For entries without a DOI (`@misc`, arXiv preprints), the script skips them;
  manually web-search the title to confirm existence if the entry looks suspicious.

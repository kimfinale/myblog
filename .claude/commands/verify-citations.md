# Verify bibliography citations

Audit a Quarto post's `references.bib` for hallucinated or incorrect entries.
Run this after writing any post that contains an AI-generated bibliography.

## What to audit

If the user specified a path (e.g. `/verify-citations blog/posts/my-post/`), use that directory.
Otherwise use the post currently open in the IDE, or ask the user which post to check.

## Steps

1. **Read the `references.bib`** for the target post.

2. **For every entry**, check:
   - Does a real paper with this DOI exist? (fetch `https://api.crossref.org/works/<DOI>` or web-search the title + first author)
   - Does the **first author's surname** match what CrossRef / Google Scholar returns?
   - Does the **journal name** match?
   - Does the **year** match?
   - For entries without a DOI, web-search the title to check it exists.

3. **Also read the post's `index.qmd`** and find every place an author name is mentioned explicitly in the prose (e.g. "Smith et al. showed…"). Verify those names match the corrected bib.

4. **Produce a verdict table** with columns: `key | status | problem | correct value`.
   Statuses: ✅ OK · ⚠️ MISMATCH · ❌ HALLUCINATED · ⬛ NO DOI.

5. **Fix automatically**: rewrite `references.bib` with all corrections applied.
   - For hallucinated entries that *are cited* in the text: replace with the real paper.
   - For hallucinated entries that are *not cited*: remove them.
   - Fix any in-text author mentions in `index.qmd` that are now wrong.

6. **Re-render** the post with `quarto render <path>/index.qmd` so the bibliography HTML is rebuilt.

7. **Report** a summary: how many entries were OK, how many fixed, how many removed.

## Tips for verification

- CrossRef API: `https://api.crossref.org/works/<DOI>` returns JSON with `author`, `container-title`, `published`, `title`.
- For entries where the DOI resolves but the author is wrong, the CrossRef `author[0].family` field is authoritative.
- For entries without a DOI (e.g. `@misc` for FDA guidance), web-search the title to confirm it exists.
- Common hallucination pattern: correct title + correct DOI, but **fabricated first author** — the DOI resolves to a completely different person.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Quarto website** for Jong-Hoon Kim's personal homepage on disease modeling for public health, deployed via GitHub Pages at `www.jonghoonk.com`. Output goes to `docs/`.

## Build Commands

```bash
quarto preview          # Local dev server with live reload
quarto render           # Full site build to docs/
quarto render blog/posts/some-post/index.qmd   # Render a single post
```

The site is deployed by pushing the `docs/` directory to the `master` branch — GitHub Pages serves from `docs/`.

## Architecture

### Content Structure
- `index.qmd` — Homepage (About)
- `blog/index.qmd` — Blog listing page
- `blog/posts/<post-name>/index.qmd` — Individual posts (~60+ posts)
- `research/index.qmd` — Publications page (Python executable, reads `research/papers.yml`)
- `cv/index.qmd` — CV page

### Key Config
- `_quarto.yml` — Site-level config: output dir, navbar, theme
- `blog/posts/_metadata.yml` — Defaults for all posts: `freeze: true`, Utterances comments
- `html/mytheme.scss` — Custom SCSS theme extending the `cosmo` Bootstrap theme

### Frozen Outputs
Posts use `freeze: true` (set in `blog/posts/_metadata.yml`). This means **code is not re-executed on render** unless explicitly re-run. Frozen outputs are cached in `_freeze/`. To re-execute a post's code, run `quarto render` on that specific file, or delete its entry in `_freeze/`.

### Post Format
Posts are `.qmd` (Quarto Markdown) files using R code chunks via knitr. Typical frontmatter:
```yaml
---
title: "Post title"
author: "Jong-Hoon Kim"
date: "YYYY-MM-DD"
categories: [R, topic]
image: "image.png"
---
```

### Publications
`research/papers.yml` is the data source for publications. `research/index.qmd` uses a Python/Jupyter kernel to parse and render the publication list.

### Output
All rendered HTML goes to `docs/`. The `docs/` directory is committed to git and served by GitHub Pages. The `CNAME` file in `docs/` points to `www.jonghoonk.com`.

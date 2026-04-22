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

---

## Author Profile and Blog Mission

### Who Jong-Hoon Kim is

Jong-Hoon Kim is an **infectious disease modeler and public health researcher** with deep expertise in:
- Compartmental epidemic models (SEIR and variants)
- Ensemble Kalman Filter (EnKF) data assimilation
- Bayesian inference and statistical modeling
- R programming (primary language, expert level)
- Digital twin systems for epidemic forecasting

He is **exploring a business opportunity** to commercialize his disease modeling expertise as a SaaS product — a digital twin platform for health departments that provides real-time epidemic tracking, scenario forecasting, and decision support.

### Goal of the Blog

The blog serves two purposes simultaneously:
1. **Personal learning log**: working through the technical skills needed to build and run a SaaS business built on epidemic modeling
2. **Portfolio and thought leadership**: demonstrating expertise to potential clients (health department epidemiologists, public health agencies, grant reviewers)

### Target reader

Posts should be written for a **technically sophisticated public health professional** — someone who understands epidemiology but may be new to software engineering or cloud infrastructure. Assume comfort with R and statistics; explain software/DevOps concepts from first principles.

---

## Active Blog Series

### Series 1: Building Digital Twin Systems (`dt_software_*`)
8-post series covering the full technical stack for production epidemic digital twins:
1. `dt_software_seir` — SEIR simulation in R
2. `dt_software_bayes` — Bayesian parameter estimation
3. `dt_software_scenario` — Scenario forecasting
4. `dt_software_enkf` — Ensemble Kalman Filter
5. `dt_software_surrogate` — Gaussian Process surrogate models
6. `dt_software_database` — TimescaleDB schema design
7. `dt_software_cloud` — AWS deployment (EC2, RDS, ALB, Terraform)
8. `dt_software_dashboard` — Streamlit dashboard

### Series 2: Business Skills for the Digital Twin Entrepreneur (`biz_*`)
20-post series covering the technical business skills needed to run a health-tech SaaS:
`biz_cicd`, `biz_sensitivity`, `biz_reporting`, `biz_data_validation`, `biz_forecasting`, `biz_spatial`, `biz_monitoring`, `biz_r_sdk`, `biz_caching`, `biz_api_versioning`, `biz_multitenancy`, `biz_data_lake`, `biz_websockets`, `biz_iac`, `biz_secrets`, `biz_async`, `biz_auth`, `biz_db_migrations`, `biz_billing`, `biz_compliance`

---

## Post Authoring Standards

### Frontmatter template
```yaml
---
title: "Descriptive title"
subtitle: "One sentence on why this matters for the business. Skill N of 20."
author: "Jong-Hoon Kim"
date: "YYYY-MM-DD"
categories: [relevant, tags]
bibliography: references.bib
csl: https://www.zotero.org/styles/vancouver
format:
  html:
    toc: true
    toc-depth: 3
    number-sections: true
    code-fold: false
execute:
  echo: true
  warning: false
  message: false
---
```

### Citations
- Every post has its own `references.bib` in the post folder
- Use Vancouver style (`csl: https://www.zotero.org/styles/vancouver`)
- Cite 2–4 real, verifiable references per post (RFCs, official docs, foundational papers)
- End every post with `## References` and `::: {#refs} :::`
- **Never fabricate citations** — only cite sources that actually exist

### R code constraints
Only these packages can be assumed installed: **base R, ggplot2, dplyr, tidyr**.
- Do NOT use: `testthat`, `ggrepel`, `base64enc`, `jose`, or any other specialty package in executed R chunks
- If a package is needed for illustration only, use `eval: false` on that chunk
- Implement functionality from scratch in base R when needed (e.g., use `stopifnot()` instead of `testthat`)
- Use `stats::filter()` explicitly when `dplyr` is loaded (avoids masking)

### Python, SQL, YAML, shell code
Show as fenced code blocks without execution — these are conceptual illustrations:
````
```python
# ... conceptual code, not executed
```
````

### Figure standards
- Each post should have 1–2 rendered ggplot2 figures
- Include `#| fig-cap:` label on figure chunks
- Use `theme_minimal()`, `steelblue`/`firebrick` color palette by default

### Structure
Each post should follow this pattern:
1. **Why this matters** (business motivation, 1–2 paragraphs)
2. **Concept explained** (text + diagram or code snippet)
3. **Working R implementation** (executable, produces output)
4. **Practical takeaway** (what to actually do)
5. **References**

Posts should be **self-contained** — a reader who arrives directly can follow along without reading prior posts.

---

## Post Creation Workflow

1. Create folder `blog/posts/<post-name>/`
2. Write `index.qmd` and `references.bib` in that folder
3. Render: `quarto render blog/posts/<post-name>/index.qmd`
4. Fix any render errors before committing
5. Commit source files: `git add blog/posts/<post-name>/ _freeze/blog/posts/<post-name>/`
6. Commit rendered output: `git add docs/blog/posts/<post-name>/`
7. Push to master: `git push origin master`

Render errors from other posts listed in the blog index are ignorable — they resolve once all posts in the series are rendered.

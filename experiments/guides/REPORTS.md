# Experiment reports — claude.ai artifacts — guide

Interactive HTML reports published as **claude.ai Artifacts** (private hosted
pages, shareable by link) — the presentation layer on top of the markdown
record. The plan/notebook markdown stays the record of record, in git; a
report is a **derived view**, rebuilt from run outputs, never edited by hand
and never the only home of a number.

## Division of labor

| layer | lives | role |
|---|---|---|
| `PLANS.md` / `NOTEBOOKS.md` | git | record of record: design + append-only round log (tables + bullets) |
| PNG plots (per `HP_SWEEP.md`) | `$ARTIFACT_DIR/exp_NNN/` | what the agent reads while iterating |
| report artifact | claude.ai | interactive view for humans — explore, share |
| `CONCLUSIONS.md` | git | collaborative conclusions — stays markdown, unchanged |

## Cadence & identity

- **One artifact per experiment**, updated at each round close — redeploy the
  same file so the URL stays stable; use a version label per round (e.g.
  `R2-close`). Keep the favicon stable per experiment.
- Record the artifact URL in that round's `### Conclusion` in `NOTEBOOKS.md`.
- Cross-experiment milestone reports are separate artifacts, made on request.

## Data contract (what makes reports rebuildable)

Each run writes under `$ARTIFACT_DIR/exp_NNN/<run_id>/`:

- `summary.json` — config, best/final metrics, status (`done` / `diverged` / …), throughput
- `metrics.jsonl` — one `{step, split, name, value}` record per line

The report is generated from these files only. Keep dumping decision-driving
PNGs regardless — the agent reads PNGs, not HTML.

## Page blueprint

Header (EXP id, the question, status, commit, data provenance) → stat tiles
(best metric + delta, best config, run count, compute) → sortable results
table (the control surface; best row highlighted; status as icon + label) →
tabbed charts → round history mirroring the notebook sections → provenance
footer (source paths, env, pointer back to the record of record).

Interactions that earn their place:

- hover tooltips carrying the **full run config** (the main win over PNGs)
- click a table row to pin that run across every chart; legend group toggles
- metric switcher and log/linear toggle on curve charts
- parallel-coordinates brushing that dims the table and other charts to match
- slider + play animation **only where step/time is the axis of interest**
  (training dynamics, generalization-gap formation) — never decoration
- every value reachable by hover is also in a table (tooltips enhance, never gate)

## Constraints (claude.ai artifacts)

- **Self-contained under a strict CSP:** no CDN scripts, fonts, or remote
  images — inline everything. Hand-rolled SVG/JS is far lighter than inlining
  plotly.js (`include_plotlyjs="inline"` works but costs ~4 MB).
- ≤ 16 MB rendered page, embedded data included.
- Theme-aware (light + dark via CSS tokens) and responsive; wide tables/charts
  scroll inside their own container.
- Label synthetic or partial data explicitly. Never hand-edit numbers into a
  report — regenerate it from the run outputs.

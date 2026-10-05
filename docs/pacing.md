<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Pacing

How fast the science tree climbs (brief §13). Written by
`python tools/pacing.py`; the model is rewritten every run, and each
measured session keeps its own section until it is measured again.

**Measure, don't guess.** The model below is the tree's arithmetic against the
income §13 aims for. It is a target, not a finding. A finding is a real
session: play with `pacing_log` on (Progress's default), then

    python tools/pacing.py --log <the server's log>

and read each hour's income against its tier's target. Then change
`config.lua` (what discoveries, studies and toys pay) or `tree.lua` (what
nodes cost), and nothing else.

## The model

| Tier | Whole tier (insight) | On the spine | Target income / hour | Hours, whole tier | Hours, spine |
|---|---|---|---|---|---|
| 3 | 2,450 | 1,460 | 450 | 5.4 | 3.2 |
| 4 | 4,110 | 2,440 | 600 | 6.8 | 4.1 |
| 5 | 11,250 | 4,850 | 1,000 | 11.2 | 4.8 |
| 6 | 17,300 | 11,300 | 1,150 | 15.0 | 9.8 |
| 7 | 31,700 | 20,000 | 1,600 | 19.8 | 12.5 |
| **all** | **66,810** | **40,050** | | **58.4** | **34.5** |

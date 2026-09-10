# Big Data Lab 2 — Football League Match Analysis using Hadoop MapReduce & Apache Pig

**CSE 4346 — Big Data Analytics Lab**
Abrar Faisal · ID 2104010202286

Analysis of English Premier League and Spanish La Liga 2024-25 match data using three Java MapReduce jobs on Apache Hadoop, and five Pig Latin scripts on Apache Pig.

**Built with:** ![Java](https://img.shields.io/badge/Java-8-orange) ![Hadoop](https://img.shields.io/badge/Hadoop-3.2.4-yellow) ![Pig](https://img.shields.io/badge/Pig-0.18.0-green) ![HDFS](https://img.shields.io/badge/HDFS-storage-blue)

---

## Problem Statement

Select a real-world dataset and analyze it using two Big Data processing paradigms — Java MapReduce on Hadoop, and Pig Latin on Apache Pig — covering aggregation, filtering, sorting, joining, and multi-metric summarization.

## Dataset

- **Source:** [football-data.co.uk](https://www.football-data.co.uk/) (mirrored via datahub.io)
- **Files:** `epl_2425.csv` (380 EPL matches), `laliga_2425.csv` (380 La Liga matches) — 2024-25 season, 760 matches total
- **Schema (22 columns):** `Date, HomeTeam, AwayTeam, FTHG, FTAG, FTR, HTHG, HTAG, HTR, Referee, HomeShots, AwayShots, HomeShotsTarget, AwayShotsTarget, HomeFouls, AwayFouls, HomeCorners, AwayCorners, HomeYellow, AwayYellow, HomeRed, AwayRed`

## Repository Structure

```
├── dataset/           EPL and La Liga source CSVs
├── java-src/          3 Java MapReduce jobs (.java + compiled .jar)
├── pig-scripts/       5 Pig Latin scripts
├── output/            Result outputs for all 8 tasks
├── screenshots/        Execution and result screenshots
└── .gitignore
```

## MapReduce Analysis (Java)

| # | Task | Technique |
|---|------|-----------|
| 1 | Total goals scored per team | Aggregation (Map + Combine + Reduce) |
| 2 | Win / draw / loss count per team | Composite-key aggregation |
| 3 | EPL vs. La Liga goals-per-match comparison | Multi-file input, `FileSplit`-based tagging |

## Pig Analysis

| # | Task | Technique |
|---|------|-----------|
| 1 | High-scoring matches (> 4 goals) | `FILTER` + `UNION` |
| 2 | Total goals per team | `GROUP` + `SUM` |
| 3 | Top 10 scoring teams | `ORDER` + `LIMIT` |
| 4 | Matches with country attached | `JOIN` against a derived lookup table |
| 5 | Full team summary (W/D/L, GF, GA, GD) | `GROUP` + nested `FOREACH` |

## Key Results

- **Barcelona** led all 40 teams with **102 goals** scored and the best goal difference (**+63**)
- The **EPL averaged 2.93 goals/match**, higher-scoring than **La Liga's 2.62**
- Java and Pig implementations of the same computation (total goals per team) produced **identical results**, cross-validating both pipelines

## Running It

```
# Java tasks (HDFS input/output)
hadoop jar java-src/TotalGoalsPerTeam.jar TotalGoalsPerTeam /bigdatalab2/input /bigdatalab2/output/task1

# Pig tasks (local mode)
pig -x local -f pig-scripts/task1_filter_high_scoring.pig
```

Full write-up with code walkthroughs, execution logs, and results: see the accompanying lab report.

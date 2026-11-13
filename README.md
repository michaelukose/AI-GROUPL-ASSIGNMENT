# Exam Timetabling AI: Dual-Paradigm Optimization System

[![Language: Common Lisp](https://img.shields.io/badge/Language-Common%20Lisp%20(SBCL)-blue.svg)](http://www.sbcl.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests: Passing](https://img.shields.io/badge/Tests-11%2F11%20Passing-brightgreen.svg)](tests/)
[![Architecture: CSP & GA](https://img.shields.io/badge/Architecture-CSP%20%2B%20Genetic%20Algorithm-purple.svg)]()

> **CPP 4103: Artificial Intelligence Programming**  
> *Faculty of Computing & Information Management, Department of Software Development & Information Systems*  
> **Topic:** Automated University Examination Timetabling via Constraint Satisfaction & Genetic Algorithms.

---

## Executive Overview

Scheduling university examinations is an **NP-complete** combinatorial optimization problem reducible to Graph Vertex Coloring ($k$-colorability). This system implements a dual-engine architecture in **ANSI Common Lisp (SBCL)** comparing exact constraint reasoning with stochastic evolutionary search:

1. **Method A: Constraint Satisfaction Problem (CSP) Backtracking**
   - **Variable Ordering:** Minimum Remaining Values (MRV / "Fail-First") with Degree Heuristic tie-breaking.
   - **Value Ordering:** Least Constraining Value (LCV) heuristic.
   - **Inference & Pruning:** Forward Checking (FC) coupled with room-capacity domain pruning.
   - **Guarantee:** Complete and sound (guaranteed to find a feasible solution if one exists, or definitively prove unsatisfiability).

2. **Method B: Genetic Algorithm (GA)**
   - **Representation:** Integer chromosome encoding assigning exams to candidate time slots.
   - **Selection:** Tournament selection ($k=3$).
   - **Recombination:** Single-point crossover ($p_c = 0.85$).
   - **Mutation:** Gene-wise random slot perturbation ($p_m = 0.15$).
   - **Survival:** Strict elitism preserving the best individual across generations.
   - **Multi-Objective Cost:** Dual-tier penalty function combining hard clash avoidance and soft constraint distribution.

3. **Stage 2: Deterministic Best-Fit Decreasing (BFD) Room Allocation**
   - Post-slot room assignment matching exam sizes to room capacities to minimize seat wastage and guarantee physical venue feasibility.

---

## Performance Benchmark Summary

Empirical results across bundled benchmark datasets on Steel Bank Common Lisp (SBCL):

| Dataset | Exams | Slots | Rooms | Students | Conflict Edges | Backtracking Time | GA Time (150 gen) | GA Soft Score |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **`demo`** | 15 | 8 | 5 | 20 | 49 | **5.25 ms** | **384 ms** | 5 |
| **`medium`** | 20 | 8 | 6 | 50 | 112 | **11.40 ms** | **620 ms** | 14 |
| **`large`** | 30 | 12 | 8 | 70 | 115 | **80.28 ms** | **1,088 ms** | 33 |
| **`stress`** | 12 | 5 | 3 | 57 | 28 | **1.93 ms** | **310 ms** | 36 |
| **`unsolvable`** | 4 | 3 | 2 | 1 | 6 ($K_4$) | **0.31 ms** *(Proved Infeasible)* | **96 ms** *(Inconclusive)* | N/A |

*Key Takeaway:* CSP Backtracking is orders of magnitude faster at establishing feasibility and proving unsatisfiability. Genetic search excels at finding high-quality schedules that optimize soft preferences (e.g., student exam spacing) in large instances.

---

## Project Structure

```text
exam-timetable-ai/
├── data/
│   └── datasets/
│       ├── demo/            # 15 exams, 8 slots, 5 rooms, 20 students (balanced baseline)
│       ├── medium/          # 20 exams, 8 slots, 6 rooms, 50 students (inter-departmental)
│       ├── large/           # 30 exams, 12 slots, 8 rooms, 70 students (university scale)
│       ├── stress/          # 12 exams, 5 slots, 3 rooms, 57 students (dense chromatic clique)
│       └── unsolvable/      # 4 exams, 3 slots (4-clique K4 proving infeasibility)
├── src/                     # Common Lisp modules loaded in topological order
│   ├── package.lisp         # Package namespace definition and exports
│   ├── load.lisp            # Path resolver and dynamic loader
│   ├── data-structures.lisp # Exam, timeslot, exam-room, and solution records
│   ├── utils.lisp           # Hash-table helpers and deterministic RNG source
│   ├── csv-data.lisp        # RFC 4180-compliant CSV parser and loader
│   ├── conflict-graph.lisp  # Conflict graph builder, edge detection, and neighbor queries
│   ├── room-assignment.lisp # Stage 2 Best-Fit Decreasing room allocation
│   ├── evaluation.lisp      # Multi-tier cost function (Hard clashes + Soft penalties)
│   ├── backtracking.lisp    # CSP solver: MRV + Degree + LCV + Forward Checking
│   ├── genetic.lisp         # GA solver: Tournament + Crossover + Mutation + Elitism
│   ├── reporting.lisp       # ASCII timetable grid and comparative metric table
│   ├── experiment.lisp      # Dual-engine benchmark harness and execution pipeline
│   ├── scenarios.lisp       # Auto-discovery and scenario runner
│   └── main.lisp            # CLI entry point and argument dispatcher
├── tests/
│   ├── test-suite.lisp      # 11 regression scenarios and invariants
│   └── run-tests.lisp       # Test launcher script
├── visualizer/
│   └── index.html           # Interactive HTML5/SVG conflict graph and timetable preview
├── run.cmd                  # Windows batch runner
├── run.ps1                  # PowerShell execution script
├── LICENSE                  # MIT License
└── README.md                # Project documentation
```

---

## Installation & Requirements

- **SBCL (Steel Bank Common Lisp)** version 2.0+ must be installed and accessible via `PATH`.
- **Python 3.8+** (Optional, for running the visualizer HTTP server or PowerPoint generation).

Verify SBCL installation:
```bash
sbcl --version
```

---

## Quick Start & Usage

### 1. Run Scenarios via Command Line
```powershell
# Run the default demo dataset
.\run.cmd

# Run specific bundled datasets
.\run.cmd demo
.\run.cmd medium
.\run.cmd large
.\run.cmd stress
.\run.cmd unsolvable

# Run all bundled datasets sequentially
.\run.cmd all

# List all available datasets
.\run.cmd list
```

### 2. Run the Automated Test Suite
```powershell
.\run.cmd test
# or
sbcl --script tests/run-tests.lisp
```

### 3. Interactive Web Visualizer
An interactive HTML5 visualizer with dynamic SVG graph rendering is provided in `visualizer/index.html`.

To view:
```powershell
python -m http.server 8000
```
Open [http://localhost:8000/visualizer/](http://localhost:8000/visualizer/) in your web browser.

---

## Algorithmic Details

### Method A: Constraint Satisfaction Problem (CSP)
- **Constraint Formulation:** $\langle X, D, C \rangle$ where variables $X = \{e_1, \dots, e_n\}$ are exams, domain $D = \{1, \dots, k\}$ are time slots, and $C$ comprises binary conflict constraints and room capacity bounds.
- **MRV Heuristic:** At each decision level, selects variable $e \in X$ with minimum $|D(e)|$. Ties broken by Degree Heuristic (maximum edges to unassigned variables).
- **LCV Heuristic:** Values $v \in D(e)$ ordered by minimizing domain eliminations across neighboring exams.
- **Forward Checking:** Instantaneous domain reduction upon assignment; triggers immediate backtrack when any neighbor domain becomes empty ($\emptyset$).

### Method B: Genetic Algorithm (GA)
- **Cost Function:**
  $$\text{Cost} = W_{\text{hard}} \cdot V_{\text{hard}} + W_{\text{soft}} \cdot V_{\text{soft}}$$
  where $W_{\text{hard}} = 1000$, $W_{\text{soft}} = 1$.
- **Hard Violations:** Student clashes in identical slots + room capacity deficits.
- **Soft Violations:** Back-to-back exams ($|s_1 - s_2| = 1$) + same-day exams for identical students.

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

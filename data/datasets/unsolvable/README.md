# Unsolvable / Unsatisfiable Dataset

A benchmark demonstrating the theoretical completeness difference between Method A (CSP Backtracking) and Method B (Genetic Algorithm).
- **4 Exams** forming a 4-clique (all mutually conflicting due to shared student)
- **3 Timeslots** (by the Pigeonhole Principle, at least 2 conflicting exams must share a slot)
- **Outcome**: Method A terminates and *proves* no feasible solution exists (YES to 'Can Prove Unsatisfiable?'). Method B runs for all generations and returns an infeasible solution with hard violations remaining (NO to 'Can Prove Unsatisfiable?').

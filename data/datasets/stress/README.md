# Stress Test Dataset

A tightly constrained 5-slot benchmark designed to stress test CSP search and genetic algorithm convergence.
- **12 Exams** densely interconnected across 5 color partitions (chromatic number $\chi = 5$)
- **5 Timeslots** providing zero slack (each slot must be used optimally)
- **3 Rooms** requiring careful room-fitting
- **57 Students** sitting cross-group exams, generating 57 pairwise conflict edges
- Tests the MRV (Minimum Remaining Values) and LCV (Least Constraining Value) heuristics under heavy constraint propagation

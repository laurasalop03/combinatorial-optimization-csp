# Combinatorial Optimization & Constraint Programming

A collection of mathematical models solving Constraint Satisfaction Problems (CSP) and Constrained Optimization Problems (COP) using MiniZinc. The repository demonstrates operational research techniques, focusing on search space reduction, symmetry breaking, and performance benchmarking.

### Tech Stack
MiniZinc, Constraint Logic Programming.

### Algorithmic & Engineering Highlights
* **Symmetry Breaking & Search Space Pruning:** Optimized matrix-based search spaces by enforcing strict lexicographical ordering constraints. This pruned isomorphic branches (reflections and rotations), collapsing 8 possible symmetries into a single representative to accelerate solver convergence[cite: 2].
* **Multi-Objective Optimization:** Transformed complex multi-objective knapsack problems into single-function Constrained Optimization Problems (COP) utilizing a weighted sum approach with order-of-magnitude scaling to enforce strict lexicographic priority[cite: 2].
* **Data Structure Optimization:** Re-architected time-based scheduling models (e.g., NBA back-to-back constraints, sequential assembly) to use 1D parallel arrays indexed by time variables instead of sparse 2D matrices, drastically reducing the search space and memory footprint[cite: 2].
* **Complexity & Scalability Benchmarking:** Profiled search heuristics (e.g., `first_fail`, `indomain_min`) and analyzed computational bottlenecks, documenting the exponential time complexity explosion for state spaces where $N \ge 5$[cite: 2].

# SVM optimization and matrix methods
## Binary teaching problem
Take up to 70 training blocks each from strong (y = −1) and light (y = +1) labels. The plotted coordinates are standardized intensity standard deviation and edge density. The program minimizes ½wᵀw + CΣξ with C = 1, subject to yᵢ(wᵀxᵢ + b) + ξᵢ ≥ 1 and ξᵢ ≥ 0. Slack permits margin violations and penalizes them linearly.

Stack z = [w₁,w₂,b,ξ₁,…,ξₙ]ᵀ. For MATLAB's ½zᵀHz + fᵀz, H is diagonal with two ones and remaining zeros and f has coefficient C only on slacks. The inequality matrix is [−diag(y)X, −y, −I], with right side −1. Lower bounds restrict only slacks. H is positive semidefinite, the constraints are affine and strictly feasible slacks exist. KKT conditions characterize optimality.

## Multiplier checks
Let α be the margin-constraint multipliers and μ the slack lower-bound multipliers. The Lagrangian adds Σαᵢ(1 − yᵢ(wᵀxᵢ+b) − ξᵢ) − Σμᵢξᵢ to the primal objective.

| Check | Numerical quantity |
|---|---|
| Primal feasibility | Largest positive violation of either inequality |
| Dual feasibility | Largest negative excursion of α or μ |
| Stationarity | Infinity norm of Hz + f + Aᵀα − λ_lower |
| Complementarity | Largest absolute αᵢ(mᵢ + ξᵢ − 1) or μᵢξᵢ |

Here mᵢ = yᵢ(wᵀxᵢ+b) is the functional margin. Geometric signed margins are mᵢ/‖w‖₂ and the distance between the two unit-margin lines is 2/‖w‖₂ for nonzero w. The support-vector count uses αᵢ > 10⁻⁵. Stationarity implies w = Σαᵢyᵢxᵢ, Σαᵢyᵢ = 0 and αᵢ + μᵢ = C. Residuals should be interpreted with numerical tolerance. Accuracy here is in-sample on the selected binary blocks. The main compressor instead reports held-out three-class ECOC accuracy.

## Norms and quantum edge analysis
MSE on one block is ‖B − B̂‖²_F / 64. The Frobenius norm is invariant under orthonormal left and right transforms, which enables the encoder's label calculation. The Euclidean weight norm controls the linear SVM margin. The infinity norm reports the worst stationarity component.

The simulated quantum circuit amplitude-encodes each 8 × 8 brightness block in six qubits. A Hadamard gate on a row or column address bit makes the difference of neighboring amplitudes observable. The map averages the two measurement probabilities. A black block is assigned zero contrast.

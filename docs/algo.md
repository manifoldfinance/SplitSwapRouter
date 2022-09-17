# Optimal Swap Split Algo for constant product AMM

Using math derived in [Optimal Split Math](math.md).

5 CPAMM pools are checked for each swap:
- Sushiswap
- Uniswap V2
- Uniswap V3 0.30%
- Uniswap V3 0.05%
- Uniswap V3 1.00%

## Step 1: Find best single swap price

In the first case, each of the 5 pools are checked and reserve state retreived. Expected amounts for single swaps can then be calculated. For example amounts out can be calculated with:

$$ \delta y = {(1000000 - fee) y \delta x \over 1000000 x + (1000000 - fee) \delta x} $$

Pools are then sorted by max amount out / min amount in. The top swap is assigned as default before checking for optimal splits.

## Step 2: Determine optimal number of splits

Using the ordered pools by best price, amounts in to sync values are calculated with the equation derived in [Optimal Split Math](math.md):

$$ \delta x = {x_1 (\sqrt{( fee^2 + {(4000000000000-4000000 fee) x_2 y_1 \over x_1 y_2}} - (2000000 - fee)) \over 2 (1000000 - fee)} $$

Note that after the first amount to sync, x1 and y1 will become the cumulative & updated reserves. When the cumulative amounts to sync exceed user amount in, the optimal number of splits have been reached.

## Step 3: Apply optimal routing

Using the ordered pools by best price, the optimal number of splits and the corresponding amounts to sync prices, an optimal routing equation can be applied in the following pattern:

### No Split (1 pool)

$$ \delta x_1 = A_{in} $$

where $A_{in}$ is the user amount in.

### Single Split (2 pools)

$$ \delta x_1 = A_1 + {(A_{in} - A_1) x'_1 \over x'_1 + x_2} $$

$$ \delta x_2 = {(A_{in} - A_1) x_2 \over x'_1 + x_2} $$

where $A_i$ denotes amount to sync prices and $x'_i$ is the updated reserve:

$$ x'_i = x_i + A_i $$

### Double Split (3 pools)

$$ \delta x_1 = A_1 + {A_2 x'_1 \over x'_1 + x_2} + {(A_{in} - A_1 - A_2) x''_1 \over x''_1 + x'_2 + x_3} $$

$$ \delta x_2 = {A_2 x_2 \over x'_1 + x_2} + {(A_{in} - A_1 - A_2) x'_2 \over x''_1 + x'_2 + x_3} $$

$$ \delta x_3 = {(A_{in} - A_1 - A_2) x_3 \over x''_1 + x'_2 + x_3} $$

### Tripple Split (4 pools)

$$ \delta x_1 = A_1 + {A_2 x'_1 \over x'_1 + x_2} + {A_3 x''_1 \over x''_1 + x'_2 + x_3} + {(A_{in} - A_1 - A_2 - A_3) x'''_1 \over x'''_1 + x''_2 + x'_3 + x_4} $$

$$ \delta x_2 = {A_2 x_2 \over x'_1 + x_2} + {A_3 x'_2 \over x''_1 + x'_2 + x_3} + {(A_{in} - A_1 - A_2 - A_3) x''_2 \over x'''_1 + x''_2 + x'_3 + x_4} $$

$$ \delta x_3 = {A_3 x_3 \over x''_1 + x'_2 + x_3} + {(A_{in} - A_1 - A_2 - A_3) x'_3 \over x'''_1 + x''_2 + x'_3 + x_4} $$

$$ \delta x_4 = {(A_{in} - A_1 - A_2 - A_3) x_4 \over x'''_1 + x''_2 + x'_3 + x_4} $$

### Quadruple Split (5 pools)

$$ \delta x_1 = A_1 + {A_2 x'_1 \over x'_1 + x_2} + {A_3 x''_1 \over x''_1 + x'_2 + x_3} + {A_4 x'''_1 \over x'''_1 + x''_2 + x'_3 + x_4} + {(A_{in} - A_1 - A_2 - A_3 - A_4) x''''_1 \over x''''_1 + x'''_2 + x''_3 + x'_4 + x_5}$$

$$ \delta x_2 = {A_2 x_2 \over x'_1 + x_2} + {A_3 x'_2 \over x''_1 + x'_2 + x_3} + {A_4 x''_2 \over x'''_1 + x''_2 + x'_3 + x_4} + {(A_{in} - A_1 - A_2 - A_3 - A_4) x'''_2 \over x''''_1 + x'''_2 + x''_3 + x'_4 + x_5} $$

$$ \delta x_3 = {A_3 x_3 \over x''_1 + x'_2 + x_3} + {A_4 x'_3 \over x'''_1 + x''_2 + x'_3 + x_4} + {(A_{in} - A_1 - A_2 - A_3 - A_4) x''_3 \over x''''_1 + x'''_2 + x''_3 + x'_4 + x_5} $$

$$ \delta x_4 = {A_4 x_4 \over x'''_1 + x''_2 + x'_3 + x_4} + {(A_{in} - A_1 - A_2 - A_3 - A_4) x'_4 \over x''''_1 + x'''_2 + x''_3 + x'_4 + x_5}$$

$$ \delta x_5 = {(A_{in} - A_1 - A_2 - A_3 - A_4) x_5 \over x''''_1 + x'''_2 + x''_3 + x'_4 + x_5} $$

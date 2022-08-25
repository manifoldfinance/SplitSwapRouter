# Optimal Swap Split for constant product AMM

Following optimal split algorithm presented in the [MEV paper by Liyi Zhou et al.](https://arxiv.org/pdf/2106.07371.pdf)

## Amount to sync prices

$$ {y_2 \over x_2} = {{x_1 y_1  \over {x_1 + \delta x (1 - fee)}} \over {x_1 + \delta x}} $$

For full integer math and Uniswap V3 consistency, we denote the fee as a fraction of 1,000,000.

$$ {y_2 \over x_2} = {1000000 x_1 y_1  \over {(1000000 x_1 + \delta x (1000000 - fee)) (\delta x + x_1)}} $$

Re-arranging and solving $ \delta x $ for positive roots via quadratic equation:

$$ \delta x = {\sqrt{x_1 y_2 ( fee^2 x_1 y_2 + (4000000000000-4000000 fee) x_2 y_1)} + fee x_1 y_2 - 2000000 x_1 y_2 \over 2 (1000000 - fee) y_2} $$

Simplifies to:

$$ \delta x = {x_1 (\sqrt{( fee^2 + {(4000000000000-4000000 fee) x_2 y_1 \over x_1 y_2}} - (2000000 - fee)) \over 2 (1000000 - fee)} $$

## Routing ratio

Given equal prices, swaps are optimally routed in ratio to their reserves.

$$ k = {x_1 \over x_1 + x_2} $$

## Appendix - Quadratic equation

When $a \ne 0$, there are two solutions to $(ax^2 + bx + c = 0)$ and they are 
$$ x = {-b \pm \sqrt{b^2-4ac} \over 2a} $$
# Model Specification

The public calculator implements the final two-part annual formal-care cost function.

## Part 1: Probability of Any Formal-Care Cost

Logistic regression:

```r
any_cost ~ state_uc + age_band + sex + ysdx + died
```

## Part 2: Positive Formal-Care Cost

Gamma generalized linear model with log link among observations with positive annual formal-care cost:

```r
cost_total ~ (age_band + sex + ysdx + state_uc) * died * inst_flag
```

## Expected Annual Cost

For a given covariate profile:

```text
expected annual cost = predicted probability of any cost * predicted mean positive cost
```

The app computes both linear predictors directly from the public coefficient tables and model matrices. It does not load fitted model objects or individual-level data.

## Reference Categories

- Dementia state: No dementia
- Age group: <65
- Sex: Female
- Years since diagnosis/index interval: 0
- Death during interval: Alive
- Institutionalized during interval: No

## Interpretation

Institutionalization and death are interval-level descriptors. They are included because economic models often specify care setting and death during a model cycle. The resulting predictions are conditional expected annual costs for specified interval profiles.

The model is not designed to estimate causal effects of dementia severity, institutionalization, or death.


## Public Implementation

The public repository includes coefficient-based prediction code and a model-development template. The template documents the final model structure but does not include the registry dataset used for estimation.

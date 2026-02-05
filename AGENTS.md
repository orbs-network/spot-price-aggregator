# AGENTS.md

These are hard requirements when generating or editing `config.json`. Treat them as invariants.

- The deployment scripts build the runtime token list as `tokens = [native, WNATIVE, ...connectors]` where `native` is `0x0000000000000000000000000000000000000000` and `WNATIVE` is the `WETH` env var.
- The deployment scripts build the runtime connector list as `connectors = [NONE, native, WNATIVE, ...connectors]` where `NONE` is `0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF`.
- `connectors` defines the base tokens only. Do not include `NONE`, `native`, or `WNATIVE` in `connectors`.
- Do not set `env.tokens`; it is no longer used.
- If `env.feeds` is present, its length must be `connectors.length + 2` and its order must align with `tokens = [native, WNATIVE, ...connectors]`.
- If `env.pyths` is present, its length must be `connectors.length + 2`, its order must align with `tokens = [native, WNATIVE, ...connectors]`, and `env.pyth` must be set to a non-zero address.
- If `env.denoms` is present (Sei), its length must be `connectors.length + 2` and its order must align with `tokens = [native, WNATIVE, ...connectors]`.
- Only one of `env.feeds`, `env.pyths`, or `env.denoms` should be set for any single chain entry.
- `adapters[i].name` must match an existing deploy script `script/adapter/Deploy${name}.s.sol` unless `adapters[i].env.address` is already set (then `AddOracleFromConfig` is used).
- When `adapters[i].env.address` is omitted, ensure the adapter `env` contains every required field expected by its deploy script.
- When set, `aggregator` must match `^0x111111` (case-insensitive) and `oracle` must match `^0xcee000` (case-insensitive), per the create2 prefix constraints in `script/deploy`.

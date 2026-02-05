# Spot Price Aggregator

This is a fork of the upstream 1inch Spot Price Aggregator. The original README is preserved at:

- [`README.upstream.md`](./README.upstream.md)

### Configuration

- [`config.json`](./config.json)

### Automatic base tokens

When deploying view USD oracles and aggregators, the scripts automatically prepend the native token and WETH:

- USD oracle token list: `tokens` is built as `[native, WETH, ...connectors]`.
- Connector list: `connectors` is built as `[NONE, native, WETH, ...connectors]`.

## `/contracts/view` overview

The `/contracts/view` entrypoints provide view-only USD pricing helpers meant for off-chain reads. They follow a simple flow:

- Prefer direct USD sources when configured for a token.
- Otherwise convert the token to a configured base asset via the offchain oracle, then convert that base to USD.
- Prices are normalized to a consistent 1e18 scale.

This fork keeps the full upstream documentation separate; use this README only for the fork-level view entrypoint overview.

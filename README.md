# Spot Price Aggregator

This is a fork of the upstream 1inch Spot Price Aggregator. The original README is preserved at:

- [`0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1README.upstream.md`](./README.md)

## `/contracts/view` overview

The `/contracts/view` entrypoints provide view-only USD pricing helpers meant for off-chain reads. They follow a simple flow:

- Prefer direct USD sources when configured for a token.
- Otherwise convert the token to a configured base asset via the offchain oracle, then convert that base to USD.
- Prices are normalized to a consistent 1e18 scale.

This fork keeps the full upstream documentation separate; use this README only for the fork-level view entrypoint overview.

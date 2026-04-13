# Fenstera

> **Note:** Fenstera is an independent community project and is not built by or affiliated with the OpenCode team.

Native iOS app to control [OpenCode](https://opencode.ai) agent sessions remotely.

Connect to any `opencode serve` instance from your iPhone — monitor sessions, send prompts, switch agents, and stream responses in real time.

## Requirements

- iOS 17.0+
- Xcode 16+
- An `opencode serve` instance running (local network, Tailscale, or VPN)

## Setup

1. Run `opencode serve` on your dev machine (optionally with `--hostname 0.0.0.0` for network access)
2. Open Fenstera on your iPhone
3. Enter the server URL and connect

## Build

```bash
xcodebuild -scheme OpenCodeController -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

Fenstera connects to the OpenCode HTTP API and SSE event stream. See [PRD.md](PRD.md) for full details.

## License

MIT

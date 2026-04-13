# Fenstera — OpenCode iOS Controller

> **Note:** Fenstera is an independent community project and is not built by or affiliated with the OpenCode team.

## Overview

Fenstera is a native iOS app that acts as a remote controller for [OpenCode](https://opencode.ai) coding agent sessions. It connects to an `opencode serve` instance via HTTP API and Server-Sent Events (SSE), letting you monitor and drive your coding agents from your iPhone — whether you're away from your desk, in a meeting, or want to check on long-running tasks.

## Problem

OpenCode runs as a terminal-based tool or desktop app on your dev machine. When you step away, you lose visibility and control over running agent sessions. Existing mobile options are limited to web wrappers or require VPN setups.

## Solution

A native SwiftUI iOS app that:
- Connects to any `opencode serve` instance over HTTP (local network, Tailscale, or VPN)
- Streams real-time events via SSE
- Lets you create sessions, send prompts, view responses, and manage agents
- Feels like a first-class iOS app (notifications, haptics, safe area, dark mode)

## Target Users

- Developers running OpenCode on a dev server or workstation
- Teams with shared OpenCode instances
- Anyone who wants to monitor long-running agent tasks remotely

## MVP Scope (v0.1)

### In Scope
- Server connection management (URL, optional HTTP basic auth)
- Session list (create, delete, view)
- Session chat view (send prompts, stream responses, view message history)
- Agent selection (switch between build/plan agents)
- Real-time event streaming (session status updates, message parts)
- Session abort
- Dark mode / light mode
- Biometric lock (Face ID / Touch ID) for stored credentials
- Pull-to-refresh

### Out of Scope (Future)
- File browsing and editing
- Shell command execution
- Share/unshare sessions
- Session forking
- Diff viewer
- Push notifications (would require a relay server)
- iPad-optimized layout
- Shortcuts / Siri integration
- Apple Watch companion

## Architecture

```
iOS App (SwiftUI)
  │
  ├── Models/       — Codable structs matching OpenCode API types
  ├── Services/
  │   ├── OpenCodeClient.swift   — HTTP API client
  │   ├── EventStream.swift      — SSE client
  │   └── KeychainService.swift  — Credential storage
  ├── ViewModels/
  │   ├── SessionListViewModel.swift
  │   ├── SessionChatViewModel.swift
  │   └── SettingsViewModel.swift
  ├── Views/
  │   ├── SessionListView.swift
  │   ├── SessionChatView.swift
  │   ├── SettingsView.swift
  │   └── AgentPicker.swift
  └── App/
      └── OpenCodeControllerApp.swift
       │
       ▼
  opencode serve (HTTP API on :4096)
```

## API Surface Used

| Endpoint | Purpose |
|---|---|
| `GET /global/health` | Server health check |
| `GET /session` | List sessions |
| `POST /session` | Create session |
| `GET /session/:id` | Get session details |
| `DELETE /session/:id` | Delete session |
| `GET /session/:id/message` | Get messages |
| `POST /session/:id/message` | Send prompt |
| `POST /session/:id/prompt_async` | Send async prompt |
| `POST /session/:id/abort` | Abort session |
| `GET /event` | SSE event stream |
| `GET /agent` | List agents |
| `GET /session/status` | All session statuses |
| `GET /config` | Get config |
| `PATCH /session/:id` | Update session title |

## Non-Functional Requirements

- iOS 17.0+
- Swift 6, strict concurrency
- Offline-resistant (graceful degradation when disconnected)
- Credentials stored in Keychain only
- No analytics or telemetry

## Naming

"Fenstera" is German for "windows" — a window into your OpenCode agents.

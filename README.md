# cc-auth-bridge

Beam Claude Code OAuth tokens to headless/remote machines via [LocalSend](https://github.com/localsend/localsend) — no SSH tunneling, no manual file copying, no API keys.

## Problem

Claude Code's subscription auth (`claude auth login`) requires a browser OAuth callback. On headless servers, VMs, or remote dev machines without a browser, this is impossible. `cc-auth-bridge` solves this by transferring the OAuth token from an authenticated machine over the local network using LocalSend.

## Quick Install

```bash
git clone https://github.com/zudsniper/cc-auth-bridge.git
cd cc-auth-bridge
./install.sh
```

Or manually:

```bash
cp cc-auth-bridge ~/.local/bin/
chmod +x ~/.local/bin/cc-auth-bridge
```

## Prerequisites

- **Claude Code CLI** — `npm install -g @anthropic-ai/claude-code`
- **LocalSend CLI** — see [install instructions](#installing-localsend-cli) below
- **jq** — `brew install jq` (macOS) or `sudo apt-get install jq` (Linux)

## Usage

### On the headless machine (receiver):

```bash
cc-auth-bridge listen
```

This prints the machine's local IP and waits for an incoming token.

### On the authenticated machine (sender):

```bash
cc-auth-bridge provide --target <headless-machine-ip>
```

This extracts your OAuth token (or runs `claude auth login` if needed) and sends it via LocalSend.

### Options

```
cc-auth-bridge listen [flags]
    --port PORT     LocalSend port (default: 53317)
    --no-verify     Skip post-transfer auth verification
    --dry-run       Print what would be done without writing

cc-auth-bridge provide [flags]
    --target IP       Target machine IP (prompted if not given)
    --port PORT       LocalSend port (default: 53317)
    --force-reauth    Re-run 'claude auth login' even if credentials exist
```

## Installing LocalSend CLI

### macOS

```bash
brew install localsend
```

### Linux x86_64 (Debian/Ubuntu)

Download the latest `.deb` from the [LocalSend releases](https://github.com/localsend/localsend/releases) page, or let `cc-auth-bridge` attempt automatic installation when it detects LocalSend is missing.

### Raspberry Pi / ARM Linux (headless)

The official LocalSend app requires a GUI (GTK/Flutter), which isn't practical on a headless Pi. `cc-auth-bridge` automatically detects ARM architecture and headless environments and installs [localsend-go](https://github.com/meowrain/localsend-go) instead — a lightweight Go implementation of the LocalSend protocol that works without a display.

This happens automatically when you run `cc-auth-bridge` and no LocalSend CLI is found. You can also install it manually:

```bash
# Download the latest ARM64 binary
curl -fsSL -o localsend-go \
  "$(curl -s https://api.github.com/repos/meowrain/localsend-go/releases/latest \
    | jq -r '.assets[] | select(.name | test("linux-arm64")) | .browser_download_url' | head -1)"
chmod +x localsend-go
mv localsend-go ~/.local/bin/

# Optional: enable device discovery
sudo setcap cap_net_raw=+ep ~/.local/bin/localsend-go
```

**Note:** `localsend-go` uses interactive device discovery when sending (no `--target` flag). For the typical use case — Pi as the receiver — this doesn't matter since receive mode auto-accepts all transfers.

### Other Linux

See the [LocalSend installation guide](https://github.com/localsend/localsend#install).

## How It Works

1. The **listener** starts a LocalSend receive session on the headless machine
2. The **provider** extracts the OAuth token from `~/.claude/.credentials.json` on the authenticated machine
3. The token is packaged as a JSON payload and sent via LocalSend over the LAN
4. The listener writes the token to `~/.claude/.credentials.json`, injects it into shell rc files, and verifies the auth works

## Troubleshooting

**"ANTHROPIC_API_KEY is set" warning**
Claude Code may use the API key instead of the OAuth token. Unset it: `unset ANTHROPIC_API_KEY`

**Verification fails after transfer**
The token may have expired. Run `cc-auth-bridge provide --force-reauth --target <ip>` to get a fresh token.

**LocalSend can't connect**
Ensure both machines are on the same LAN and no firewall is blocking the port (default: 53317).

**Token format not recognized**
The tool expects tokens matching `sk-ant-oat01-*`. If the format has changed, the token is still transferred but a warning is shown.

**Raspberry Pi / ARM: "localsend-go" device discovery not working**
Run `sudo setcap cap_net_raw=+ep ~/.local/bin/localsend-go` to grant network discovery capabilities. Direct IP-based send/receive still works without this.

## Security Notes

- Credentials are written with `chmod 600` (owner-only read/write)
- Existing credentials are backed up before overwriting
- Temp files are cleaned up on exit
- Tokens are sent over LocalSend's encrypted protocol on the local network
- No data leaves your LAN

## License

MIT

# MediaFusion Home Assistant Add-on

Self-hosted Stremio addon for streaming movies and TV shows via debrid services (Real-Debrid, AllDebrid, Premiumize).

## Overview

This add-on runs MediaFusion on your Home Assistant OS installation, providing:

- **Debrid-only streaming** - No torrenting from your IP; all content resolved via debrid services
- **Public indexer scraping** - Aggregates sources from Torrentio, Zilean, and other public sources
- **Stremio integration** - Works seamlessly with Stremio on all platforms
- **Optional VPN support** - Route MediaFusion traffic through WireGuard without affecting HA
- **Cloudflare Tunnel compatible** - Expose securely to your family via Cloudflare

## Requirements

- Home Assistant OS (amd64 architecture)
- At least 1GB RAM available for the add-on
- A debrid service account (Real-Debrid, AllDebrid, or Premiumize)
- Stremio app on viewing devices

## Installation

### Step 1: Add the Repository

1. Navigate to **Settings** → **Add-ons** → **Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add this repository URL:
   ```
   https://github.com/YOUR-USERNAME/mediafusion-ha-addon
   ```
4. Click **Add** → **Close**

### Step 2: Install the Add-on

1. Find **MediaFusion** in the add-on store
2. Click **Install**
3. Wait for the installation to complete (may take 5-10 minutes)

### Step 3: Configure the Add-on

Before starting, configure the essential options:

| Option | Description | Required |
|--------|-------------|----------|
| `host_url` | External URL for accessing MediaFusion | Yes |
| `secret_key` | Encryption key (auto-generated if empty) | Recommended |
| `api_password` | Password to protect the configuration UI | Recommended |
| `log_level` | Logging verbosity (INFO, DEBUG, WARNING, ERROR) | No |

### Step 4: Start the Add-on

1. Click **Start**
2. Check the **Log** tab for startup progress
3. Wait for "MediaFusion server started" message

## Configuration Options

### Basic Configuration

```yaml
host_url: "http://homeassistant.local:8000"
secret_key: ""  # Auto-generated if empty
api_password: "your-secure-password"
log_level: "INFO"
```

### Scraping Sources

Enable or disable various torrent indexer sources:

```yaml
enable_torrentio_scraping: true   # Scrape from Torrentio
enable_zilean_scraping: true      # Scrape from Zilean DMM
enable_mediafusion_scraping: true # Scrape from other MediaFusion instances
cache_ttl_minutes: 5              # Cache duration (1-60 minutes)
```

### Prowlarr Integration (Optional)

Connect to your Prowlarr instance for additional indexers:

```yaml
prowlarr_url: "http://192.168.1.100:9696"
prowlarr_api_key: "your-prowlarr-api-key"
```

### VPN Configuration (Optional)

Route MediaFusion traffic through WireGuard VPN:

```yaml
enable_vpn: true
wireguard_endpoint: "vpn.example.com:51820"
wireguard_private_key: "your-private-key"
wireguard_public_key: "server-public-key"
wireguard_address: "10.0.0.2/32"
wireguard_dns: "1.1.1.1"
vpn_kill_switch: true  # Block traffic if VPN disconnects
```

**Important VPN Notes:**
- VPN only affects MediaFusion traffic, not Home Assistant or NAS access
- Local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x) is always accessible
- Kill switch prevents data leaks if VPN disconnects

## Cloudflare Tunnel Setup

To expose MediaFusion securely to your family:

### Step 1: Install Cloudflared Add-on

1. Install the **Cloudflared** add-on from the Home Assistant add-on store
2. Configure your Cloudflare Tunnel

### Step 2: Configure Tunnel for MediaFusion

Add this to your Cloudflare Tunnel configuration:

```yaml
ingress:
  - hostname: mediafusion.yourdomain.com
    service: http://homeassistant.local:8000
  - service: http_status:404
```

### Step 3: Update MediaFusion Host URL

Set the `host_url` option to your Cloudflare Tunnel hostname:

```yaml
host_url: "https://mediafusion.yourdomain.com"
```

## Using with Stremio

### Step 1: Get the Manifest URL

After starting the add-on, your manifest URL will be:

```
http://YOUR-HA-IP:8000/manifest.json
```

Or via Cloudflare Tunnel:

```
https://mediafusion.yourdomain.com/manifest.json
```

### Step 2: Configure MediaFusion

1. Open your browser and navigate to:
   ```
   http://YOUR-HA-IP:8000/configure
   ```

2. Configure your preferences:
   - Enable desired catalogs (Movies, TV Shows, etc.)
   - **Important**: Configure your debrid provider:
     - Real-Debrid: Enter your API key
     - AllDebrid: Enter your API key
     - Premiumize: Enter your API key

3. Click **Install in Stremio** or copy the manifest URL

### Step 3: Add to Stremio

**Desktop/Mobile App:**
1. Click the "Install in Stremio" button
2. Stremio will open and prompt for installation
3. Click **Install**

**Web/iOS:**
1. Open Stremio
2. Go to **Addons** → **Community Addons**
3. Click the search icon
4. Paste your manifest URL
5. Click **Install**

### Step 4: Family Setup

For each family member:

1. Share the configure URL: `https://mediafusion.yourdomain.com/configure`
2. Have them configure their own debrid account
3. Install the addon with their personalized manifest URL

**Tip:** Each family member should have their own debrid account or use shared credentials.

## Debrid Service Setup

### Real-Debrid

1. Sign up at [real-debrid.com](https://real-debrid.com)
2. Purchase a subscription (Premium required)
3. Get your API key from [real-debrid.com/apitoken](https://real-debrid.com/apitoken)
4. Enter the API key in MediaFusion configuration

### AllDebrid

1. Sign up at [alldebrid.com](https://alldebrid.com)
2. Purchase a subscription
3. Get your API key from the AllDebrid dashboard
4. Enter the API key in MediaFusion configuration

### Premiumize

1. Sign up at [premiumize.me](https://premiumize.me)
2. Get your API key from account settings
3. Enter the API key in MediaFusion configuration

## Persistent Storage

Data is stored under `/data` in the add-on:

| Path | Description |
|------|-------------|
| `/data/postgres` | PostgreSQL database |
| `/data/redis` | Redis cache |
| `/data/cache` | Application cache |
| `/data/logs` | Log files |

**Note:** Data persists across add-on restarts and updates.

## Troubleshooting

### Add-on Won't Start

1. Check the **Log** tab for error messages
2. Ensure port 8000 is not in use by another service
3. Verify you have enough RAM (at least 1GB free)

### Can't Access MediaFusion

1. Verify the add-on is running (green indicator)
2. Check firewall settings
3. Try accessing via IP instead of hostname
4. Check if port 8000 is exposed in your router

### No Streams Found

1. Verify your debrid service is configured correctly
2. Test your debrid API key on the provider's website
3. Check if scraping sources are enabled
4. Try a popular movie/show to test

### VPN Issues

1. Verify WireGuard configuration is correct
2. Check VPN provider supports your configuration
3. Temporarily disable VPN to test connectivity
4. Check add-on logs for VPN-related errors

### High Resource Usage

1. Reduce workers (edit Dockerfile if building locally)
2. Increase cache TTL to reduce API calls
3. Disable unused scraping sources
4. Monitor with Home Assistant's System Monitor

## Security Considerations

### API Password

Always set an API password to prevent unauthorized configuration changes:

```yaml
api_password: "your-secure-password"
```

### Secret Key

Set a persistent secret key to maintain encrypted user data across restarts:

```yaml
secret_key: "generate-with-openssl-rand-hex-16"
```

Generate a secure key:
```bash
openssl rand -hex 16
```

### Cloudflare Tunnel

Using Cloudflare Tunnel provides:
- No exposed ports on your router
- DDoS protection
- SSL/TLS encryption
- Access controls (optional)

### VPN with Kill Switch

For maximum privacy:
- Enable VPN routing
- Enable kill switch to prevent leaks
- Verify your IP after VPN connection

## Legal Considerations (UK)

This add-on is configured for **debrid-only** operation:

- No torrenting/seeding occurs from your IP address
- All torrent resolution is handled by debrid services
- Debrid services operate from jurisdictions with different laws
- You are responsible for compliance with UK copyright law
- Personal/family use typically has lower legal risk

**Disclaimer:** This information is not legal advice. Consult a legal professional for specific concerns.

## Resource Usage

Optimized for MacBook Air / low-resource systems:

| Resource | Typical Usage |
|----------|---------------|
| RAM | 256-512 MB |
| CPU | 5-15% during searches |
| Storage | 100-500 MB (with database) |

## Support

- **GitHub Issues:** Report bugs or request features
- **Documentation:** Check the README for updates
- **Community:** Home Assistant community forums

## Changelog

### Version 1.0.0
- Initial release
- PostgreSQL and Redis embedded
- WireGuard VPN support
- Cloudflare Tunnel compatible
- Debrid-only operation
- Optimized for amd64/MacBook Air

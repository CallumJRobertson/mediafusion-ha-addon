# MediaFusion Home Assistant Add-on - Complete Installation Guide

This guide provides step-by-step instructions for deploying MediaFusion on Home Assistant OS running on an Intel MacBook Air.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Configuration](#configuration)
4. [Cloudflare Tunnel Setup](#cloudflare-tunnel-setup)
5. [Stremio Family Setup](#stremio-family-setup)
6. [VPN Integration](#vpn-integration)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
- **Architecture:** amd64 (Intel MacBook Air compatible)
- **RAM:** Minimum 1GB available for the add-on
- **Storage:** 500MB-1GB for database and cache

### Software Requirements
- Home Assistant OS (HAOS) installed and running
- Access to Home Assistant UI
- Network connectivity

### Accounts Required
- **Debrid Service** (at least one):
  - [Real-Debrid](https://real-debrid.com) - Recommended, ~€16/6 months
  - [AllDebrid](https://alldebrid.com)
  - [Premiumize](https://premiumize.me)

- **Cloudflare Account** (optional but recommended):
  - Free tier is sufficient
  - Required for secure external access

---

## Installation Methods

### Method 1: Add-on Repository (Recommended)

1. **Open Home Assistant**
   - Navigate to **Settings** → **Add-ons** → **Add-on Store**

2. **Add Repository**
   - Click the **⋮** menu (top right corner)
   - Select **Repositories**
   - Enter the repository URL:
     ```
     https://github.com/YOUR-USERNAME/mediafusion-ha-addon
     ```
   - Click **Add** → **Close**

3. **Install Add-on**
   - Refresh the page
   - Find **MediaFusion** in the list
   - Click on it → Click **Install**
   - Wait for installation (5-10 minutes)

### Method 2: Local Add-on (Development)

1. **Access Home Assistant via SSH or Samba**

2. **Copy Files**
   ```bash
   # Create local add-ons directory if it doesn't exist
   mkdir -p /addons/mediafusion

   # Copy the add-on files
   cp -r ha-addon/mediafusion/* /addons/mediafusion/
   ```

3. **Reload Add-ons**
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click **⋮** → **Check for updates**
   - MediaFusion should appear under "Local add-ons"

---

## Configuration

### Essential Configuration

1. **Open Add-on Configuration**
   - Go to **Settings** → **Add-ons** → **MediaFusion**
   - Click the **Configuration** tab

2. **Set Required Options**

   ```yaml
   # External URL - How you'll access MediaFusion
   # Option A: Direct IP (LAN only)
   host_url: "http://192.168.1.100:8000"

   # Option B: Via Cloudflare Tunnel (recommended for family access)
   host_url: "https://mediafusion.yourdomain.com"

   # Security (generate with: openssl rand -hex 16)
   secret_key: "your-32-character-hex-string"
   api_password: "choose-a-strong-password"

   # Logging
   log_level: "INFO"
   ```

3. **Configure Scraping Sources**

   ```yaml
   # Enable all for maximum content discovery
   enable_torrentio_scraping: true
   enable_zilean_scraping: true
   enable_mediafusion_scraping: true

   # Cache for 5 minutes (reduces API calls)
   cache_ttl_minutes: 5
   ```

4. **Save and Start**
   - Click **Save**
   - Go to **Info** tab
   - Click **Start**
   - Monitor the **Log** tab for startup progress

### Verify Installation

1. **Check Health**
   - Wait for startup to complete (1-2 minutes)
   - Access: `http://YOUR-HA-IP:8000/health`
   - Should return: `{"status": "ok"}`

2. **Open Configuration UI**
   - Navigate to: `http://YOUR-HA-IP:8000/configure`
   - You should see the MediaFusion configuration page

---

## Cloudflare Tunnel Setup

For secure family access without exposing ports on your router.

### Step 1: Install Cloudflared Add-on

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Search for **Cloudflared**
3. Install the add-on

### Step 2: Create Cloudflare Tunnel

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **Zero Trust** → **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Name it (e.g., "home-assistant")
5. Copy the tunnel token

### Step 3: Configure Cloudflared Add-on

1. Open Cloudflared add-on configuration
2. Enter your tunnel token
3. Add ingress rules:

   ```yaml
   tunnel: YOUR-TUNNEL-ID
   credentials-file: /data/tunnel-credentials.json

   ingress:
     # MediaFusion
     - hostname: mediafusion.yourdomain.com
       service: http://homeassistant.local:8000

     # Catch-all
     - service: http_status:404
   ```

4. Save and start Cloudflared

### Step 4: Update MediaFusion Configuration

```yaml
host_url: "https://mediafusion.yourdomain.com"
```

### Step 5: Verify External Access

- Open: `https://mediafusion.yourdomain.com/health`
- Should return: `{"status": "ok"}`

---

## Stremio Family Setup

### For Each Family Member

#### Step 1: Configure Debrid Provider

1. Open the configuration page:
   ```
   https://mediafusion.yourdomain.com/configure
   ```

2. Scroll to **Streaming Provider**

3. Select your debrid service:
   - **Real-Debrid**: Enter API key from [real-debrid.com/apitoken](https://real-debrid.com/apitoken)
   - **AllDebrid**: Enter API key from dashboard
   - **Premiumize**: Enter API key from account settings

4. Configure preferences:
   - Enable desired catalogs (Movies, TV Shows)
   - Set quality preferences
   - Configure language options

5. Click **Generate Manifest URL**

#### Step 2: Install in Stremio

**Desktop App (Windows/Mac/Linux):**
1. Click "Install in Stremio" button
2. Stremio opens automatically
3. Click **Install** in the prompt

**Mobile App (Android):**
1. Click "Install in Stremio" button
2. Or copy manifest URL and paste in Stremio

**Web / iOS:**
1. Copy the manifest URL
2. Open Stremio app
3. Go to **Addons**
4. Click **+** or search icon
5. Paste manifest URL
6. Click **Install**

#### Step 3: Start Streaming

1. Search for a movie or TV show
2. Click on it
3. Select a stream from MediaFusion
4. Enjoy!

### Family Sharing Options

**Option A: Shared Debrid Account**
- All family members use the same debrid API key
- Simpler setup
- Check debrid service ToS for device limits

**Option B: Individual Accounts**
- Each member configures their own debrid account
- Better for tracking usage
- Each gets their own manifest URL

---

## VPN Integration

### When to Use VPN

- Extra privacy layer
- Access geo-restricted debrid content
- Required by some ISPs

### WireGuard Configuration

1. **Get VPN Configuration**
   - Sign up for a VPN service with WireGuard support
   - Download/generate WireGuard configuration

2. **Configure in Add-on**

   ```yaml
   enable_vpn: true
   wireguard_endpoint: "vpn-server.example.com:51820"
   wireguard_private_key: "your-private-key-here"
   wireguard_public_key: "server-public-key-here"
   wireguard_address: "10.0.0.2/32"
   wireguard_dns: "1.1.1.1"
   vpn_kill_switch: true
   ```

3. **Important Notes**

   - VPN only affects MediaFusion traffic
   - Home Assistant UI remains accessible via local network
   - NAS access is not affected
   - Kill switch blocks MediaFusion traffic if VPN fails

### Verify VPN Connection

Check the add-on logs for:
```
VPN connected successfully
Public IP: xxx.xxx.xxx.xxx
```

---

## Troubleshooting

### Add-on Won't Start

**Check Logs:**
```
Settings → Add-ons → MediaFusion → Log
```

**Common Issues:**
1. **Port conflict**: Another service uses port 8000
   - Solution: Change the port in configuration

2. **Memory issues**: Not enough RAM
   - Solution: Free up memory or increase allocation

3. **Database initialization failed**:
   - Check if `/data` directory is writable
   - Try restarting the add-on

### No Streams Found

1. **Verify debrid configuration**
   - Test API key on debrid provider website
   - Check for error messages in configuration UI

2. **Check scraping sources**
   - Ensure at least one scraping source is enabled
   - Try a popular movie first

3. **Network issues**
   - Verify add-on can reach external services
   - Check VPN connection if enabled

### Slow Performance

1. **Increase cache TTL** to reduce API calls
2. **Disable unused scrapers**
3. **Check system resources** in HA's System Monitor

### VPN Issues

1. **Connection failed**
   - Verify endpoint, keys, and addresses
   - Check VPN service status

2. **No internet with VPN**
   - Disable kill switch temporarily
   - Verify local network exclusions

3. **Slow speeds**
   - Try different VPN server
   - Check VPN provider bandwidth limits

### Database Issues

1. **Reset database** (last resort):
   ```bash
   # SSH into Home Assistant
   rm -rf /data/addons/local/mediafusion/postgres/*
   rm -rf /data/addons/local/mediafusion/redis/*
   ```
   Then restart the add-on.

---

## Resource Optimization for MacBook Air

The add-on is optimized for limited resources:

| Setting | Value | Purpose |
|---------|-------|---------|
| Workers | 2 | Reduced from 4 |
| Max connections | 50 | PostgreSQL limit |
| Shared buffers | 64MB | PostgreSQL memory |
| Redis maxmemory | 64MB | Cache limit |
| Cache TTL | 5 min | Reduce API calls |

**Monitor Usage:**
- Install **System Monitor** integration in HA
- Watch CPU and memory during searches

---

## Support

- **GitHub Issues:** [Report bugs](https://github.com/mhdzumair/MediaFusion/issues)
- **Documentation:** Check DOCS.md for detailed reference
- **Community:** Home Assistant forums

---

## Legal Notice (UK)

This add-on operates in **debrid-only mode**:

- No torrenting occurs from your IP address
- All torrent resolution happens via debrid services
- Debrid services operate under their own jurisdiction
- You are responsible for compliance with applicable laws
- Private/family use typically carries lower legal risk

**This is not legal advice. Consult a legal professional for specific concerns.**

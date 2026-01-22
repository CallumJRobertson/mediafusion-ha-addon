# MediaFusion Home Assistant Add-on Repository

This repository contains the Home Assistant add-on for [MediaFusion](https://github.com/mhdzumair/MediaFusion) - a self-hosted Stremio addon for streaming movies and TV shows via debrid services.

## Add-ons in this Repository

### MediaFusion

![Supports amd64 Architecture](https://img.shields.io/badge/amd64-yes-green.svg)

Self-hosted Stremio addon that aggregates torrent sources and resolves them through debrid services (Real-Debrid, AllDebrid, Premiumize). No torrenting from your IP - all content is streamed via debrid.

**Features:**
- Debrid-only streaming (no torrenting from your IP)
- Public indexer scraping (Torrentio, Zilean, etc.)
- Stremio integration for all platforms
- Optional WireGuard VPN routing
- Cloudflare Tunnel compatible
- Optimized for low-resource systems

## Installation

1. Add this repository to your Home Assistant:

   [![Add Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FYOUR-USERNAME%2Fmediafusion-ha-addon)

   Or manually:
   - Navigate to **Settings** → **Add-ons** → **Add-on Store**
   - Click **⋮** (menu) → **Repositories**
   - Add: `https://github.com/YOUR-USERNAME/mediafusion-ha-addon`

2. Find **MediaFusion** in the add-on store and click **Install**

3. Configure and start the add-on

## Quick Start

1. Install the add-on
2. Configure `host_url` with your external URL
3. Start the add-on
4. Open `http://YOUR-HA-IP:8000/configure` in your browser
5. Set up your debrid provider (Real-Debrid, etc.)
6. Install in Stremio using the manifest URL

## Documentation

See the [full documentation](mediafusion/DOCS.md) for detailed setup instructions.

## Support

- [GitHub Issues](https://github.com/mhdzumair/MediaFusion/issues)
- [Home Assistant Community](https://community.home-assistant.io/)

## License

MIT License - See [LICENSE](LICENSE) for details.

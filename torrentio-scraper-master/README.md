# Torrentio

- [torrentio-addon](addon) - the Stremio addon which will query scraped entries and return Stremio stream results.

## Home Assistant OS (amd64) add-on

The `addon/` directory includes a Home Assistant add-on definition for HAOS amd64 that runs the Torrentio scraper locally with optional ingress and LAN access.

### Install (local repo)
1. In Home Assistant, go to **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Add the repository URL that contains this project.
3. Install **Torrentio Scraper** from the add-on store.

### Configuration
You can configure the add-on options in the UI:
- `port`: The internal HTTP port (default `7000`).
- `metrics_user` / `metrics_password`: Optional credentials for the swagger-stats metrics endpoint.
- `basic_auth_user` / `basic_auth_password`: Optional HTTP Basic Auth protecting all addon endpoints. Share these credentials with family members if you want to allow external access.

### Sharing with family
For sharing outside your home network, pair this add-on with Home Assistant’s remote access (e.g. Nabu Casa) and enable Basic Auth in the add-on configuration. Then share the external URL for `http(s)://<your-home-assistant-external-host>:7000/manifest.json` along with the Basic Auth credentials. If you only need LAN access, enable the `7000/tcp` port in the add-on and share your Home Assistant host IP instead.

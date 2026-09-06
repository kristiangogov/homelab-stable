# Homelab Stable Edition

Self-hosted services running on Docker Compose, fully managed by Ansible.


## Requirements

- Fedora Server host, SSH access with key added
- NAS reachable on the network with NFS exports for config and media
- A Cloudflare account, domain on Cloudflare DNS, and a Tunnel already created
- Tailscale, for services kept off the public internet entirely

Update `ansible/inventory/hosts.ini` and `ansible/inventory/group_vars/all/main.yaml` with your host and NAS info.

### Host prep

Installs Docker, mounts NAS exports, creates the shared `homelab` Docker network:

```bash
cd ansible
ansible-playbook playbooks/initial-setup.yaml
```

### Deploying a service

Each service lives under `services/<name>/` as a self-contained, portable `docker-compose.yaml`. Secrets go in a local `.env` next to it. Service-specific overrides go in an optional `services/<name>/vars.yaml`.

```bash
ansible-playbook playbooks/deploy.yaml -e service=<name>
```

### Exposing a new service

Services aren't exposed to the internet by default. To publish one via the existing Cloudflare Tunnel:

1. Add the service to the shared `homelab` Docker network in its compose file (`networks: - homelab`)
2. In the Cloudflare Zero Trust dashboard → Networks → Tunnels → your tunnel → Public Hostname, add an entry pointing to `http://<container-name>:<port>` (resolves via Docker's internal DNS on the shared network)
3. Add the matching CNAME DNS record if not already present

Services that shouldn't be reachable from the public internet (e.g. Frigate) are instead accessed only over Tailscale, using the host's MagicDNS name. No Cloudflare Tunnel entry is created for these.

## Tooling overview

### Hardware
| Logo | Device | Role |
|:-:|-----|-------------|
| ![Lenovo](https://cdn.simpleicons.org/lenovo?size=32) | Lenovo Thinkcentre M700 | Server |
| ![HP](https://cdn.simpleicons.org/hp?size=32) | HP EliteDesk 800 G2 SFF 2x1TB WD Red | NAS |

### Infrastructure
| Logo | Name | Description |
|:-:|-----|-------------|
| ![Fedora](https://cdn.simpleicons.org/fedora?size=32) | Fedora Server | Linux Distribution used on Server |
| ![TrueNAS](https://cdn.simpleicons.org/truenas?size=32) | TrueNAS | Operating System used on the NAS |
| ![Ansible](https://cdn.simpleicons.org/ansible/f00?size=32) | Ansible | Automation tool for configuration and orchestration |
| <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/cloudflare-zero-trust.png" width="32" height="32" />  | Cloudflare | Zero-Trust Tunnel for exposing services securely on a the internet |
| ![Tailscale](https://cdn.simpleicons.org/tailscale?size=32) | Tailscale | Private mesh network for services not exposed publicly |

### Monitoring

Proper monitoring solution will be implemented when time allows. The current setup relies on a mix of an Uptime Kuma instance hosted on the TrueNAS and Glance dashboard metrics displaying the status of docker containers and services.

### Services
| Logo | Name | Description |
|:-:|-----|-------------|
| ![Glance](https://cdn.simpleicons.org/glance?size=32) | Glance | A lightweight, highly customizable dashboard | 
| ![Jellyfin](https://cdn.simpleicons.org/jellyfin?size=32) | Jellyfin | Media streaming service | 
| <img src="https://repository-images.githubusercontent.com/459944886/a6e61d23-9090-4cc4-946d-c5d9c189240f" width="32" height="32" /> | SilverBullet.md | Programmable browser-based Markdown editor |
| ![Karakeep](https://cdn.simpleicons.org/karakeep?size=32) | Karakeep | Bookmark manager | 
| ![OpenWebUI](https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/open-webui-light.svg) | Open WebUI | Self-hosted AI Platform |
| <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/mqtt.svg" width="32" height="32" /> | Mosquitto | MQTT broker for Frigate/Home Assistant events |
| <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/frigate.svg" width="32" height="32" /> | Frigate | NVR with realtime object detection |
| <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg" width="32" height="32" /> | Home Assistant | Home automation hub, integrates with Frigate over MQTT |

### Frigate + Home Assistant integration

Frigate handles detection/recording; Home Assistant handles automations and phone notifications. They're wired together as follows:

1. **Mosquitto** is deployed first. Both Frigate and Home Assistant connect to it as `mqtt:1883`.
2. **Frigate** publishes every detection event to MQTT automatically once configured with `mqtt: host: mosquitto`.
3. **HACS** (Home Assistant Community Store) is installed inside the Home Assistant container, since the Frigate integration isn't part of HA's default integrations:
```bash
   docker exec home-assistant bash -c "wget -O - https://get.hacs.xyz | bash -"
   docker restart home-assistant
```
   Then in the HA UI: **Settings → Devices & Services → Add Integration → HACS**, and complete the GitHub device authorization flow.
4. Inside **HACS → Integrations**, search for **Frigate** (`blakeblackshear/frigate-hass-integration`) and download it, then restart Home Assistant again.
5. Add the integration itself: **Settings → Devices & Services → Add Integration → Frigate**, pointing at `http://frigate:5000` — Frigate's internal API port.
6. From there, Frigate's cameras/zones/detections surface as entities in Home Assistant, and can be used in automations (e.g. push notifications via the Home Assistant mobile app).

### Backup Strategy

The homelab follows a **3-2-1 backup strategy**:

| Logo | Name | Description |
|:-:|-----|-------------|
| ![TrueNAS](https://cdn.simpleicons.org/truenas?size=32) | TrueNAS | Primary local storage - 2x 1TB WD Red ZFS mirror |
| <img src="https://images.icon-icons.com/61/PNG/128/lightbrown_external_drive_usb_folder_12286.png" width="32" height="32" /> | External SSD | Secondary local copy for critical data |
| ![Backblaze](https://cdn.simpleicons.org/backblaze?size=32) | Backblaze B2 | Offsite cloud storage via TrueNAS Cloud Sync |

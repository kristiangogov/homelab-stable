# Homelab Stable Edition

Self-hosted services running on Docker Compose, fully managed by Ansible.


## Requirements

- Fedora Server host, SSH access with key added
- NAS reachable on the network with NFS exports for config and media
- A Cloudflare account, domain on Cloudflare DNS, and a Tunnel already created

Update `ansible/inventory/hosts.ini` and `ansible/inventory/group_vars/all/main.yaml` with your host and NAS info.

### Host prep

Installs Docker, mounts NAS exports, creates the shared `homelab` Docker network:

```bash
cd ansible
ansible-playbook playbooks/initial-setup.yaml
```

### Deploying a service

Each service lives under `services/<name>/` as a self-contained, portable `docker-compose.yaml`. Secrets go in a local `.env` next to it (not committed).

```bash
ansible-playbook playbooks/deploy.yaml -e service=<name>
```

### Exposing a new service

Services aren't exposed to the internet by default. To publish one via the existing Cloudflare Tunnel:

1. Add the service to the shared `homelab` Docker network in its compose file (`networks: - homelab`)
2. In the Cloudflare Zero Trust dashboard → Networks → Tunnels → your tunnel → Public Hostname, add an entry pointing to `http://<container-name>:<port>` (resolves via Docker's internal DNS on the shared network)
3. Add the matching CNAME DNS record if not already present

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

### Monitoring

To-be-implemented.

### Services
| Logo | Name | Description |
|:-:|-----|-------------|
| ![Jellyfin](https://cdn.simpleicons.org/jellyfin?size=32) | Jellyfin | Media streaming service | 
| <img src="https://repository-images.githubusercontent.com/459944886/a6e61d23-9090-4cc4-946d-c5d9c189240f" width="32" height="32" /> | SilverBullet.md | Programmable browser-based Markdown editor |
| ![Karakeep](https://cdn.simpleicons.org/karakeep?size=32) | Karakeep | Bookmark manager | 
| ![OpenWebUI](https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/open-webui-light.svg) | Open WebUI | Self-hosted AI Platform | 

> [!NOTE]
> Open WebUI connects to Ollama running natively on a separate GPU workstation (`192.168.0.110`), since neither the server nor NAS has a GPU. Ollama must be running and reachable on the LAN for chat to work; Open WebUI itself stays up independently.

### Backup Strategy

The homelab follows a **3-2-1 backup strategy**:

| Logo | Name | Description |
|:-:|-----|-------------|
| ![TrueNAS](https://cdn.simpleicons.org/truenas?size=32) | TrueNAS | Primary local storage - 2x 1TB WD Red ZFS mirror |
| <img src="https://images.icon-icons.com/61/PNG/128/lightbrown_external_drive_usb_folder_12286.png" width="32" height="32" /> | External SSD | Secondary local copy for critical data |
| ![Backblaze](https://cdn.simpleicons.org/backblaze?size=32) | Backblaze B2 | Offsite cloud storage via TrueNAS Cloud Sync |

## Goal
Stable host for my critical self-hosted services.
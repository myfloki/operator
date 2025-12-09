This repository offers a package to deploy a full node environment with an Electrum server, enhancing network security and supporting community expansion.

Included Components:
- Flokicoin node
- Electrum service

# Requirements

- make  
- Docker and Docker Compose

# Usage

```sh
make start
```

### Enable SSL/TLS (Let's Encrypt)

1. Point `ELECTRUM_SSL_DOMAIN` to this host's public IP and open ports **80** and **443**.
2. Set credentials in `.env`:
   ```env
   ELECTRUM_SSL_DOMAIN=electrum.example.com
   ELECTRUM_SSL_EMAIL=admin@example.com
   ```
3. Issue the cert (runs certbot in a disposable container and copies to `./data/electrum/ssl`):
   ```sh
   make ssl
   ```
4. Renew when needed:
   ```sh
   make renew
   ```
After issuance/renewal, restart the TLS proxy if it's already running:
```sh
docker compose restart electrum_ssl
```

**Optional: Enable Discord Alerts**  
To receive alerts when the Electrum server is down, set `DISCORD_WEBHOOK_URL` in your `.env` file:

```env
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your_webhook
```

If unset, Discord notifications are skipped.

### Health Check Cron

To automatically monitor and restart Electrum if unhealthy, register a cron job:

```sh
make register_cron
```

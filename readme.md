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
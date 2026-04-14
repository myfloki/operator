# Electrum Operator

Run your own Electrum server to boost wallet privacy, reduce reliance on public nodes, and help support the Flokicoin network.

## 🚀 Onboarding Steps

Follow these steps to set up your Electrum operator from scratch:

### 1. Initial Setup
Run the `setup.sh` script. This script will:
- Check for and install the `just` command runner if it's missing.
- Create necessary data directories (`data/peer`, `data/electrum`, `data/sockets`).
- Generate `.env` and `data/peer/lokid.conf` from sample files.

```bash
./setup.sh
```

### 2. Configuration (Optional)
Before starting the services, you can customize your installation:
- **`.env`**: Modify ports, discord webhook, or the docker image versions.
- **`data/peer/lokid.conf`**: Adjust peer-to-peer and RPC settings.

### 3. Start the Operator
Now that everything is configured, start the services:

```bash
just up
```

## 🛠️ Service Management

The operator uses `just` for common tasks:

| Command         | Description                                     |
| --------------- | ----------------------------------------------- |
| `just setup`    | Re-run the onboarding/setup script.             |
| `just up`       | Start all services in the background.           |
| `just down`     | Stop and remove all service containers.         |
| `just restart`  | Restart the services.                           |
| `just logs`     | Follow logs for all services.                   |
| `just logs-peer`| Follow logs specifically for the peer node.     |
| `just status`   | Check the status of the containers.             |

## 🔍 Troubleshooting

- **Logs**: If a service fails to start, check the logs: `just logs`.
- **Indexing**: Electrum requires a full transaction index (`txindex=1`). This is enabled by default in the sample config but may take time to build on the first run.
- **Data Persistence**: All configuration and blockchain data are stored in the `./data` directory.

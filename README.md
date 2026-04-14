# Operator Name

Description of the operator.

## 🚀 Onboarding Steps

Follow these steps to set up your operator from scratch:

### 1. Initial Setup
Run the `setup.sh` script. This script will:
- Check for and install the `just` command runner if it's missing.
- Create necessary data directories.
- Generate `.env` and configuration files from sample files.

```bash
./setup.sh
```

### 2. Configuration (Optional)
Before starting the services, you can customize your installation:
- **`.env`**: Modify the docker image version.
- **Config Files**: Adjust specific service settings.

> [!CAUTION]
> **IMPORTANT**: Review your configuration files (e.g., `.env`, `flnd.conf`, `lokid.conf`) and replace any placeholder credentials (like `YOUR_RPC_PASSWORD`) with secure, custom passwords before starting the services.

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
| `just up`       | Start the operator in the background.           |
| `just down`     | Stop and remove the containers.                 |
| `just restart`  | Restart the services.                           |
| `just logs`     | Follow the service logs.                        |
| `just status`   | Check the status of the containers.             |

## 🔍 Troubleshooting

- **Logs**: If a service fails to start, check the logs: `just logs`.
- **Data Persistence**: All configuration and blockchain data are stored in the `./data` directory.

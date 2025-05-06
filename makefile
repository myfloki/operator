
HEALTH_SCRIPT = healthmon.sh
HEALTH_LOG = /var/log/healthmon.log
HEALTH_CRON_SCHEDULE = */1 * * * *

clean:
	-rm -rf ./data/electrum/mainnet
stop:
	docker compose down
start:
	-docker compose pull
	docker compose up -d
	docker logs -f mainnet-flokicoin-peer
restart: stop start

restart_electrum:
	docker compose restart electrum -t 0

upgrade:
	-docker compose pull
	docker compose up -d

register_cron:
	@chmod +x $(HEALTH_SCRIPT)
	@CRON_CMD="cd $$(dirname $$(realpath $(lastword $(MAKEFILE_LIST)))) && ./$(HEALTH_SCRIPT) >> $(HEALTH_LOG) 2>&1"; \
	CRON_ENTRY="$(HEALTH_CRON_SCHEDULE) $$CRON_CMD"; \
	crontab -l 2>/dev/null | grep -F "$$CRON_ENTRY" >/dev/null || (crontab -l 2>/dev/null; echo "$$CRON_ENTRY") | crontab -
	@echo "[OK] cron registred"
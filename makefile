HEALTH_SCRIPT = ./ops/health-check.sh
HEALTH_LOG = /var/log/healthmon.log

SSL_SCRIPT = ./ops/ssl.sh

clean:
	-rm -rf ./data/electrum/mainnet
stop:
	docker compose down
start:
	@-docker compose pull
	@docker compose up -d
	@echo "Services started. Use 'make cron_install' to enable health monitoring."
	@docker logs -f mainnet-flokicoin-peer
	
restart: stop start

restart_electrum:
	docker compose restart electrum -t 0

upgrade:
	-docker compose pull
	docker compose up -d

cron_install:
	@bash ./ops/register-cron.sh

cron_uninstall:
	@bash ./ops/unregister-cron.sh

test:
	@bash ./ops/test-services.sh

ssl:
	@bash $(SSL_SCRIPT) ensure

renew:
	@bash $(SSL_SCRIPT) renew

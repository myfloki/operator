

clean:
	-rm -rf ./data/electrum/mainnet
stop:
	docker compose down
start:
	-docker compose pull
	docker compose up -d
restart: stop start

restart_electrum:
	docker compose restart electrum -t 0
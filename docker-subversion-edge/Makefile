STACK=svnedge
COMPOSE_FILE=docker-compose.yml
CONTAINER=${STACK}_svnedge_1


start:
	docker-compose -f ${COMPOSE_FILE} -p ${STACK} up -d
stop:
	docker-compose -p ${STACK} stop
remove:
	docker-compose -p ${STACK} down
logs:
	docker-compose -p ${STACK} logs -f
shell:
	docker exec -it ${CONTAINER} bash
	

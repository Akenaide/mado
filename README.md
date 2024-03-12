# mado
Card list for card game weiss schwarz

## Front
- https://flutter.dev 

## Database
- https://strawberry.rocks/docs GraphQl

## Python
- https://fastapi.tiangolo.com web framework
- https://pdm-project.org/latest/ package manager


## Local dev
- Docker compose v2.22 or later to use `watch`

### Env
- WEB_PORT: Fastapi will serve to this port.
- KIBANA_PASSWORD: Used by Kibana, don't use it to log in Kibana
- ELASTIC_PASSWORD: Use it to login in Kibana
- KIBANA_ENCRYPTION_KEY: Set 32+ characters
- CARDS_FOLDERS: path to cards files, it is used when you import card data

### Start
- Use `docker-compose watch` to start the project.
- Kibana: http://localhost:5601.
  - username: elastic
  - password: {ELASTIC_PASSWORD}

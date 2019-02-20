# Tarantool-test-task : Implement ket-value storage

Application: https://murmuring-castle-28701.herokuapp.com

API:
- POST /kv body: {"key": "test", "value": {SOME ARBITRARY JSON}}
- PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}
- GET kv/{id}
- DELETE kv/{id}

- POST возвращает 409 если ключ уже существует,
- POST, PUT возвращают 400 если боди некорректное
- PUT, GET, DELETE возвращает 404 если такого ключа нет
- все операции логируются

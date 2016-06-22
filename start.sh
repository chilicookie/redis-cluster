#!/bin/sh
docker run --name redis-cluster -p 20001-20006:20001-20006/tcp -d savepoint/redis-cluster

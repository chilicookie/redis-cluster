#!/bin/sh
REDIS_PATH="/santorini/benefit/redis"
mkdir -p $REDIS_PATH

echo "Configuring Redis Nodes..."
conf() {
	echo "################################ GENERAL  #####################################
daemonize yes
pidfile $REDIS_PATH/$1/redis.pid
logfile $REDIS_PATH/$1/redis.log
port $1
dir $REDIS_PATH/$1/data

tcp-backlog 511
timeout 0

tcp-keepalive 0
loglevel notice
databases 16
save 900 1
save 300 10
save 60 10000

################################ SNAPSHOTTING  ################################
save 900 1
save 300 10
save 60 10000

stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb

################################# REPLICATION #################################
# slaveof <masterip> <masterport>
slave-serve-stale-data yes
slave-read-only yes

repl-diskless-sync no
repl-diskless-sync-delay 5
# repl-ping-slave-period 10
# repl-timeout 60
repl-disable-tcp-nodelay no
# repl-backlog-size 1mb
# repl-backlog-ttl 3600
slave-priority 100
# min-slaves-to-write 3
# min-slaves-max-lag 10
############################## APPEND ONLY MODE ###############################
appendonly yes
appendfilename \"appendonly.aof\"

# appendfsync always
appendfsync everysec
# appendfsync no

no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes

################################ LUA SCRIPTING  ###############################
lua-time-limit 5000

################################ REDIS CLUSTER  ###############################
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
# cluster-slave-validity-factor 10
# cluster-migration-barrier 1
# cluster-require-full-coverage yes

################################## SLOW LOG ###################################
slowlog-log-slower-than 10000
slowlog-max-len 128

################################ LATENCY MONITOR ##############################
latency-monitor-threshold 0

############################# EVENT NOTIFICATION ##############################
notify-keyspace-events \"\"

############################### ADVANCED CONFIG ###############################
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

list-max-ziplist-entries 512
list-max-ziplist-value 64

set-max-intset-entries 512

zset-max-ziplist-entries 128
zset-max-ziplist-value 64

hll-sparse-max-bytes 3000

activerehashing yes

client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

hz 10

protected-mode no

aof-rewrite-incremental-fsync yes"
}
for port in 20001 20002 20003 20004 20005 20006
do
	cd $REDIS_PATH
	mkdir -p "$port/data"
	cd $port
	conf $port >> redis.conf
	cd ..
	redis-server "$port/redis.conf"
done
echo "Configuration Complete."

echo "Creating Redis Cluster..."
echo "yes" | redis-trib.rb create --replicas 1 127.0.0.1:20001 127.0.0.1:20002 127.0.0.1:20003 127.0.0.1:20004 127.0.0.1:20005 127.0.0.1:20006
echo "Cluster Creation Complete."


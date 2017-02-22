redis-cli save
redispassword=$(lua5.3 -e "print(require('configuration').redis.password)")
redisdb=$(lua5.3 -e "print(require('configuration').redis.db)")
redishost=$(lua5.3 -e "print(require('configuration').redis.host)")
redisport=$(lua5.3 -e "print(require('configuration').redis.port)")
redisbackup="mattata_"
redisbackup+=$(date +%s%N)
redisbackup+=".json"
if [ ! -d "backups/" ]; then
    mkdir backups
fi
cd backups/
redisquery="-u $redishost:$redisport -d $redisdb"
if [ ! $redispassword == 'nil' ]; then
    redisquery="-u :$redispassword@$redishost:$redisport -d $redisdb"
fi
redis-dump $redisquery > $redisbackup
echo "mattata's database has been saved to backups/$redisbackup!"
# Backup postgres installation

cd /mnt/storage/postgres

docker exec -t immich_postgres pg_dumpall -c -U postgres > ./immich_dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql

LOCATION=/mnt/storage/databases
FILECOUNT=0

FILES=$(find $LOCATION -type f)

for f in $FILES
	do
   		FILECOUNT=$[$FILECOUNT+1]
done

if [ $FILECOUNT -gt 10 ]
then
	stat --printf='%Y %n\0' ./* | sort -zn | sed -z 's/[^ ]\{1,\} //;q' | xargs -r0 rm
fi

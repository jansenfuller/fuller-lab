# Backup postgres installation

cat restore_dump.sql | sudo docker exec -i immich_postgres psql -U postgres

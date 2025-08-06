# Backup postgres installation

cat restore_dump.sql | sudo docker exec -i postgres-pgvecto-17-1 psql -U postgres

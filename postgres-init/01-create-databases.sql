-- Um database por servico, todos no mesmo container do PostgreSQL.
-- O NotificationsAPI nao tem banco.
-- Atencao: scripts de /docker-entrypoint-initdb.d so rodam na primeira
-- inicializacao do volume. Para recriar os databases, use `docker compose down -v`.
CREATE DATABASE fcg_users;
CREATE DATABASE fcg_catalog;
CREATE DATABASE fcg_payments;

-- Vitalis — setup inicial do banco local (PostgreSQL)
-- Execute no pgAdmin: Query Tool conectado ao servidor PostgreSQL
-- Ou via psql: psql -U postgres -f init-local.sql

-- 1. Role dedicada (recomendado — mesmo padrao da equipe e da Azure)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vitalis') THEN
    CREATE ROLE vitalis WITH LOGIN PASSWORD 'vitalis' CREATEDB;
  ELSE
    ALTER ROLE vitalis CREATEDB;
  END IF;
END
$$;

-- 2. Database
SELECT 'CREATE DATABASE vitalis OWNER vitalis'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'vitalis')\gexec

-- 3. Permissoes (conecte no database vitalis antes de rodar o bloco abaixo)
-- No pgAdmin: selecione o database vitalis e abra novo Query Tool

GRANT ALL ON SCHEMA public TO vitalis;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO vitalis;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO vitalis;

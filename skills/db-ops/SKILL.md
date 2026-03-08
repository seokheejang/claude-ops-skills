---
name: db-ops
description: Database read-only operations - query status, check connections, inspect schemas
argument-hint: "<database-name>"
allowed-tools: Bash, Read
---

# Database Operations Skill

데이터베이스 조회 전용 skill. READ-ONLY 쿼리만 실행.

## Safety Rules

- **SELECT, SHOW, DESCRIBE, EXPLAIN만 허용**
- **절대 금지**: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, GRANT, REVOKE
- 변경이 필요하면 SQL을 텍스트로 안내

## Arguments

`$ARGUMENTS` = 데이터베이스 식별자

## MySQL/MariaDB

```bash
mysql -h <host> -u <user> -p<pass> -e "SHOW DATABASES;"
mysql -h <host> -u <user> -p<pass> <db> -e "SHOW TABLES;"
mysql -h <host> -u <user> -p<pass> <db> -e "SHOW PROCESSLIST;"
mysql -h <host> -u <user> -p<pass> <db> -e "SHOW TABLE STATUS;"
```

## PostgreSQL

```bash
psql -h <host> -U <user> -d <db> -c "SELECT version();"
psql -h <host> -U <user> -d <db> -c "\dt"
psql -h <host> -U <user> -d <db> -c "SELECT * FROM pg_stat_activity;"
```

## Output Format

- 쿼리 결과 테이블 형식으로 정리
- 이상 메트릭 하이라이트 (높은 커넥션, 락 대기 등)

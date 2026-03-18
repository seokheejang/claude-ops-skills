---
name: db-ops
description: Database read-only operations - query status, check connections, inspect schemas
argument-hint: "<database-name>"
allowed-tools: Bash, Read
---

# Database Operations Skill

데이터베이스 조회 전용 skill. READ-ONLY 쿼리만 실행.

## Safety: READ-ONLY

허용: SELECT, SHOW, DESCRIBE, EXPLAIN. 금지: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, GRANT, REVOKE.
DML/DDL 필요시 SQL을 텍스트로 안내. 대량 SELECT는 LIMIT 사용.

## Arguments

`$ARGUMENTS` = 데이터베이스 식별자 (DB명 또는 접속 정보).

## Workflow

| 단계 | MySQL/MariaDB | PostgreSQL | 확인 사항 |
|------|---------------|------------|-----------|
| 연결/버전 | `mysql -e "SELECT version(); SHOW VARIABLES LIKE 'max_connections';"` | `psql -c "SELECT version();" -c "SHOW max_connections;"` | 버전, max_connections |
| DB/테이블 | `SHOW DATABASES; SHOW TABLES;` | `\dt` 또는 `pg_tables WHERE schemaname='public'` | 테이블 목록 |
| 커넥션 | `SHOW PROCESSLIST; SHOW STATUS LIKE 'Threads_connected';` | `pg_stat_activity GROUP BY state` | 활성 커넥션, state별 분포 |
| 슬로우/락 | `slow_query_log 변수`, `INNODB_LOCK_WAITS`, `INNODB STATUS` | `pg_stat_activity WHERE query_start < now()-30s`, `pg_locks` | 슬로우 쿼리, 락 대기 |
| 테이블 크기 | `information_schema.tables ORDER BY data_length DESC` | `pg_stat_user_tables ORDER BY pg_total_relation_size DESC` | 데이터/인덱스 크기, row count |

## Troubleshooting

- **커넥션 풀 부족**: 활성 vs max_connections 비교, idle 커넥션 많으면 앱 풀 설정 확인
- **락 대기**: 대기/차단 쿼리 식별, 차단 쿼리 kill 텍스트 안내
- **슬로우 쿼리**: EXPLAIN 실행 계획 분석, 인덱스 누락/full table scan 확인
- **디스크 증가**: 테이블별 크기 + row count, 오래된 데이터 정리 필요 여부

## Output

접속 DB 정보(호스트/DB명/엔진버전) 명시. 결과 테이블 형식. 이상 메트릭 **굵게**. 조치는 텍스트 안내.

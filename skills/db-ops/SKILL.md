---
name: db-ops
description: Database read-only operations - query status, check connections, inspect schemas
argument-hint: "<target-name>"
allowed-tools: Bash, Read
---

# Database Operations Skill

데이터베이스 조회 전용 skill. READ-ONLY 쿼리만 실행.

## Safety: READ-ONLY

허용: SELECT, SHOW, DESCRIBE, EXPLAIN. 금지: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, GRANT, REVOKE.
DML/DDL 필요시 SQL을 텍스트로 안내. 대량 SELECT는 LIMIT 사용.

## Target Resolution

`$ARGUMENTS` → `${CLAUDE_SKILL_DIR}/db-targets.yaml`에서 매칭 (정확→alias→부분). 미매칭시 targets 목록 표시.
인자 없으면 `default_target`. `db-targets.yaml` 없으면 `db-targets.yaml.example`을 복사하라고 안내.

db-targets.yaml 스키마:
- `engine`: `mysql` | `mariadb` | `postgresql`
- `host`, `port`, `user`, `database`
- `password_env`: 비밀번호가 담긴 **환경변수 이름** (값 아님). 파일에 비밀번호를 직접 저장 금지
- `aliases`, `sslmode`(pg만)

**비밀번호 해석**: `password_env`가 지정된 환경변수를 Bash 간접참조(`${!VAR}`)로 읽음. 환경변수 미설정이면 즉시 중단하고 사용자에게 설정 안내 (명령줄 `--password=` 금지: `ps`에 노출됨).

## 연결 패턴

**MySQL / MariaDB**:
```
MYSQL_PWD="${!PASSWORD_ENV}" mysql \
  -h <host> -P <port> -u <user> \
  --protocol=TCP --connect-timeout=10 \
  <database> -e "<query>"
```

**PostgreSQL**:
```
PGPASSWORD="${!PASSWORD_ENV}" psql \
  "host=<host> port=<port> user=<user> dbname=<database> sslmode=<sslmode> connect_timeout=10" \
  -c "<query>"
```

> 환경변수 방식은 `ps` 노출 위험이 명령줄 `--password=`보다 낮지만 0은 아님. 서버 공유 환경에서는 `~/.my.cnf`(mysql) 또는 `~/.pgpass`(pg) + `chmod 600` 권장. 이 경우 `password_env` 대신 `credentials_file: "~/.my.cnf"` 로 지정하고 `--defaults-extra-file`을 사용.

## Arguments

`$ARGUMENTS` = db-targets.yaml의 타겟 이름 또는 alias.

## Workflow

| 단계 | MySQL/MariaDB | PostgreSQL | 확인 사항 |
|------|---------------|------------|-----------|
| 연결/버전 | `SELECT version(); SHOW VARIABLES LIKE 'max_connections';` | `SELECT version();` + `SHOW max_connections;` | 버전, max_connections |
| DB/테이블 | `SHOW DATABASES; SHOW TABLES;` | `\dt` 또는 `pg_tables WHERE schemaname='public'` | 테이블 목록 |
| 커넥션 | `SHOW PROCESSLIST; SHOW STATUS LIKE 'Threads_connected';` | `pg_stat_activity GROUP BY state` | 활성 커넥션, state별 분포 |
| 슬로우/락 | `slow_query_log 변수`, `INNODB_LOCK_WAITS`, `INNODB STATUS` | `pg_stat_activity WHERE query_start < now()-30s`, `pg_locks` | 슬로우 쿼리, 락 대기 |
| 테이블 크기 | `information_schema.tables ORDER BY data_length DESC` | `pg_stat_user_tables ORDER BY pg_total_relation_size DESC` | 데이터/인덱스 크기, row count |

## Troubleshooting

- **커넥션 풀 부족**: 활성 vs max_connections 비교, idle 커넥션 많으면 앱 풀 설정 확인
- **락 대기**: 대기/차단 쿼리 식별, 차단 쿼리 kill 텍스트 안내
- **슬로우 쿼리**: EXPLAIN 실행 계획 분석, 인덱스 누락/full table scan 확인
- **디스크 증가**: 테이블별 크기 + row count, 오래된 데이터 정리 필요 여부
- **인증 실패**: `password_env` 환경변수 설정 여부 확인, readonly 계정 권한 확인
- **연결 타임아웃**: 방화벽/보안그룹, host/port 정확성, TLS 요구 여부 (pg는 `sslmode`)

## Output

타겟명, engine, 호스트, DB명, 버전 명시. 결과 테이블 형식. 이상 메트릭 **굵게**. 조치는 텍스트 안내.

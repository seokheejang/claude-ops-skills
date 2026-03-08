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
- DML/DDL 변경이 필요하면 SQL을 텍스트로 안내
- 대량 SELECT도 주의 (LIMIT 사용 권장)

## When to Use

- DB 연결 상태를 확인할 때
- 테이블 구조/스키마를 조회할 때
- 활성 커넥션/프로세스를 확인할 때
- 슬로우 쿼리나 락 상태를 진단할 때
- 테이블 크기/상태를 점검할 때

## Arguments

`$ARGUMENTS` = 데이터베이스 식별자 (DB명 또는 접속 정보)

## Step-by-Step Workflow

### Step 1: 연결 확인 + 버전 정보

**MySQL/MariaDB:**
```bash
mysql -h <host> -u <user> -p<pass> -e "SELECT version(); SHOW VARIABLES LIKE 'max_connections';"
```

**PostgreSQL:**
```bash
psql -h <host> -U <user> -d <db> -c "SELECT version();" -c "SHOW max_connections;"
```

### Step 2: 데이터베이스/테이블 목록

**MySQL/MariaDB:**
```bash
mysql -h <host> -u <user> -p<pass> -e "SHOW DATABASES;"
mysql -h <host> -u <user> -p<pass> <db> -e "SHOW TABLES;"
```

**PostgreSQL:**
```bash
psql -h <host> -U <user> -d <db> -c "\dt"
psql -h <host> -U <user> -d <db> -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public';"
```

### Step 3: 활성 커넥션/프로세스

**MySQL/MariaDB:**
```bash
mysql -h <host> -u <user> -p<pass> -e "SHOW PROCESSLIST;"
mysql -h <host> -u <user> -p<pass> -e "SHOW STATUS LIKE 'Threads_connected';"
```

**PostgreSQL:**
```bash
psql -h <host> -U <user> -d <db> -c "SELECT count(*) as total, state FROM pg_stat_activity GROUP BY state;"
psql -h <host> -U <user> -d <db> -c "SELECT pid, usename, state, query_start, query FROM pg_stat_activity WHERE state != 'idle' LIMIT 20;"
```

### Step 4: 슬로우 쿼리/락 확인

**MySQL/MariaDB:**
```bash
mysql -h <host> -u <user> -p<pass> -e "SHOW VARIABLES LIKE 'slow_query_log%';"
mysql -h <host> -u <user> -p<pass> -e "SELECT * FROM information_schema.INNODB_LOCK_WAITS;" 2>/dev/null
mysql -h <host> -u <user> -p<pass> -e "SHOW ENGINE INNODB STATUS\G" 2>/dev/null | head -50
```

**PostgreSQL:**
```bash
psql -h <host> -U <user> -d <db> -c "SELECT pid, age(clock_timestamp(), query_start), usename, query FROM pg_stat_activity WHERE state != 'idle' AND query_start < now() - interval '30 seconds' ORDER BY query_start LIMIT 10;"
psql -h <host> -U <user> -d <db> -c "SELECT blocked_locks.pid AS blocked_pid, blocking_locks.pid AS blocking_pid, blocked_activity.query AS blocked_query FROM pg_catalog.pg_locks blocked_locks JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype AND blocking_locks.relation = blocked_locks.relation AND blocking_locks.pid != blocked_locks.pid JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid WHERE NOT blocked_locks.granted LIMIT 10;"
```

### Step 5: 테이블 상태/크기

**MySQL/MariaDB:**
```bash
mysql -h <host> -u <user> -p<pass> <db> -e "SHOW TABLE STATUS;"
mysql -h <host> -u <user> -p<pass> <db> -e "SELECT table_name, ROUND(data_length/1024/1024,2) AS data_mb, ROUND(index_length/1024/1024,2) AS index_mb, table_rows FROM information_schema.tables WHERE table_schema='<db>' ORDER BY data_length DESC LIMIT 20;"
```

**PostgreSQL:**
```bash
psql -h <host> -U <user> -d <db> -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS total_size, n_live_tup AS row_count FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 20;"
```

## Troubleshooting

### 커넥션 풀 부족
1. 현재 활성 커넥션 수 vs max_connections 비교
2. idle 커넥션이 많으면 → 애플리케이션의 커넥션 풀 설정 확인
3. state별 커넥션 분포 확인

### 락 대기 (Lock Wait)
1. 대기 중인 쿼리와 차단하는 쿼리 식별
2. 차단 쿼리의 실행 시간 확인
3. 해결: 차단 쿼리 kill (명령어를 텍스트로 안내)

### 슬로우 쿼리
1. 실행 시간이 긴 쿼리 목록 확인
2. EXPLAIN으로 실행 계획 분석
3. 인덱스 누락, full table scan 여부 확인

### 디스크 사용량 증가
1. 테이블별 크기 확인
2. 큰 테이블의 row count 확인
3. 오래된 데이터 정리 필요 여부 판단

## Output Format

- 접속 DB 정보 명시 (호스트, DB명, 엔진 버전)
- 쿼리 결과 테이블 형식으로 정리
- 이상 메트릭 **굵게** 하이라이트 (높은 커넥션, 락 대기 등)
- 조치가 필요하면 SQL/명령어를 텍스트로 안내 (직접 실행 금지)

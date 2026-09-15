---
name: db-ops
description: Database read-only inspection - composes copy-paste SELECT/SHOW command bundles for the operator to run, then interprets the pasted output
argument-hint: "<target-name>"
allowed-tools: Bash, Read
---

# Database Operations Skill

DB 조회 전용. **READ-ONLY 쿼리만** (`SELECT`, `SHOW`, `DESCRIBE`, `EXPLAIN`).
금지: `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `CREATE`, `TRUNCATE`, `GRANT`, `REVOKE`. DML/DDL이 필요하면 SQL을 텍스트로만 안내.

## 이 스킬만의 규율

DB가 VPN 뒤에 있어 직접 닿지 않는다. 명령을 한 번에 묶어 내는 방식, 화면에 담기게 줄이는 규칙, 붙여넣은 출력을 실측으로 다루는 규칙, `(미확인)` 표기는 **글로벌 CLAUDE.md 「K8s·ArgoCD 등 프록시로 못 보는 것」을 따른다.** DB에만 해당하는 것은 아래 둘이다.

- **대량 SELECT는 반드시 `LIMIT`** — 컬럼도 필요한 것만 고른다
- **비밀번호는 절대 명령에 박아 넣지 않는다** — `$MY_DB_PW` 자리표시자로 두고 사용자가 자기 셸에서 export 하게 한다

## Arguments

`$ARGUMENTS` = `db-targets.yaml`의 타겟 이름 또는 alias. 인자가 없으면 `default_target`.

## Target Resolution

`$ARGUMENTS` → `${CLAUDE_SKILL_DIR}/db-targets.yaml`에서 매칭 (정확→alias→부분). 미매칭이면 타겟 목록을 보여준다. 파일이 없으면 `db-targets.yaml.example`을 복사하라고 안내하거나, host/port/user/database를 직접 묻는다.

스키마: `engine`(`mysql`|`mariadb`|`postgresql`), `host`, `port`, `user`, `database`, `password_env`, `aliases`, `sslmode`(pg).

**비밀번호는 파일에 저장하지 않는다.** `password_env`는 비밀번호가 담긴 **환경변수 이름**이고, 명령에는 `$MY_DB_PW` 형태로 남겨 사용자가 자기 셸에서 채우게 한다. 명령줄 `--password=`는 `ps`에 노출되므로 금지.

## 명령 묶음

**MySQL / MariaDB**
```bash
DBH="<host>"; DBP="<port>"; DBU="<user>"; DBN="<database>"   # ← 채우고, 비밀번호는 $MY_DB_PW 로 export
MYSQL_PWD="$MY_DB_PW" mysql -h $DBH -P $DBP -u $DBU --protocol=TCP --connect-timeout=10 $DBN -e "
SELECT version();
SHOW VARIABLES LIKE 'max_connections';
SHOW STATUS LIKE 'Threads_connected';
SELECT state, COUNT(*) FROM information_schema.PROCESSLIST GROUP BY state;
SELECT table_name, table_rows, ROUND(data_length/1024/1024) db_mb, ROUND(index_length/1024/1024) idx_mb
  FROM information_schema.tables WHERE table_schema='$DBN' ORDER BY data_length DESC LIMIT 10;"
```

**PostgreSQL**
```bash
PGPASSWORD="$MY_DB_PW" psql "host=<host> port=<port> user=<user> dbname=<db> sslmode=<mode> connect_timeout=10" -c "
SELECT version();
SHOW max_connections;
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;
SELECT relname, n_live_tup, pg_size_pretty(pg_total_relation_size(relid)) sz
  FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;"
```

**락/슬로우 쿼리** (증상 있을 때만 추가로)
- MySQL: `SHOW ENGINE INNODB STATUS\G`, `SELECT * FROM performance_schema.data_lock_waits LIMIT 10;`
- PG: `SELECT pid, state, now()-query_start AS dur, left(query,80) FROM pg_stat_activity WHERE state<>'idle' AND now()-query_start > interval '30s' ORDER BY dur DESC LIMIT 10;`

> 서버 공유 환경에서는 환경변수도 `ps` 노출 위험이 0은 아니다 — `~/.my.cnf` / `~/.pgpass` + `chmod 600` 후 `--defaults-extra-file`을 권장.

## Output

타겟명·engine·호스트·DB명·버전 명시. 결과는 테이블. 이상 메트릭 **굵게**. 미확인은 `(미확인)`. 조치는 텍스트 안내.

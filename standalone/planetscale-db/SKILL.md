---
name: planetscale-db
description: >
  PlanetScale database skill covering schema branching, non-blocking DDL migrations, query optimization, and MySQL-compatible operations. Use when the user mentions PlanetScale, schema branches, deploy requests, non-blocking schema changes, database branching workflows, Vitess, pscale CLI, or MySQL optimization in PlanetScale context. Also use for index design, query analysis, slow query identification, safe schema migrations, branch promotion, and connection string management in PlanetScale or PlanetScale-compatible (MySQL 8+/Postgres) databases.
user-invocable: true
license: MIT
---

# PlanetScale Database Skill

You are a PlanetScale database expert. Apply PlanetScale's schema branching model and best practices for all database work.

## Core Concepts

**Schema Branching:** PlanetScale treats schema changes like code — branched, reviewed, and merged. Never run DDL directly on production.

```
main branch (production) ←── deploy request ←── feature-branch
```

## pscale CLI Workflow

```bash
# Authenticate
pscale auth login

# Branch operations
pscale branch create <database> <branch-name>    # create schema branch
pscale branch list <database>
pscale branch delete <database> <branch-name>

# Connect to a branch
pscale connect <database> <branch-name> --port 3309
# Then use standard MySQL client: mysql -h 127.0.0.1 -P 3309 -u root

# Deploy requests (schema promotion)
pscale deploy-request create <database> <branch-name>
pscale deploy-request list <database>
pscale deploy-request deploy <database> <deploy-request-number>
pscale deploy-request diff <database> <deploy-request-number>   # review schema diff

# Backups
pscale backup create <database> <branch-name>
pscale backup list <database>
```

## Schema Migration Patterns

### Safe Column Addition (non-blocking)
```sql
-- ✓ Safe — PlanetScale handles this without locking
ALTER TABLE orders ADD COLUMN metadata JSON;
ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP NULL;
```

### Safe Index Addition (non-blocking via Vitess online DDL)
```sql
ALTER TABLE events ADD INDEX idx_user_created (user_id, created_at);
-- Runs as online DDL: no table lock, no downtime
```

### Column Rename (requires 3-phase deploy)
```sql
-- Phase 1: add new column
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);
-- Deploy, update app to write to BOTH columns
-- Phase 2: backfill
UPDATE users SET full_name = CONCAT(first_name, ' ', last_name) WHERE full_name IS NULL;
-- Phase 3: drop old columns after app fully migrated
ALTER TABLE users DROP COLUMN first_name, DROP COLUMN last_name;
```

## Query Optimization

### Index Design Principles
```sql
-- Composite index: put equality columns first, range column last
-- BAD for range queries: INDEX(created_at, user_id)
-- GOOD: INDEX(user_id, created_at)

-- Covering index — avoids table lookup
ALTER TABLE orders ADD INDEX idx_covering (user_id, status, created_at, total);
-- Query: SELECT user_id, status, created_at, total FROM orders WHERE user_id = ? AND status = 'paid'

-- Prefix index for long VARCHARs
ALTER TABLE products ADD INDEX idx_name_prefix (name(50));
```

### Query Analysis
```sql
-- Always EXPLAIN before deploying slow queries
EXPLAIN SELECT * FROM orders WHERE user_id = 123 AND status = 'pending' ORDER BY created_at DESC;
-- Look for: type=ref or range (good), type=ALL (bad — full scan)

-- Check for N+1 patterns — batch instead:
-- BAD: SELECT * FROM users WHERE id = ? (in a loop)
-- GOOD: SELECT * FROM users WHERE id IN (1, 2, 3, ...)
```

### Connection Pooling (PlanetScale + PlanetScale Boost)
```
DATABASE_URL=mysql://user:pass@host/dbname?connection_limit=10&pool_timeout=20
# PlanetScale Boost: enable query caching at the proxy layer
# Effective for repeated identical queries (dashboard counters, etc.)
```

## PlanetScale-Specific Constraints
- **No foreign key constraints** enforced at DB level (Vitess limitation) — enforce in application layer or use logical FK checks
- **No stored procedures or triggers** in production — handle in application
- **ENUM changes** are blocking — use VARCHAR + application-level validation instead
- **Row-level locks** still apply — keep transactions short

## Schema Branch Workflow (full cycle)
```bash
# 1. Create feature branch
pscale branch create mydb add-user-metadata

# 2. Connect and apply DDL
pscale connect mydb add-user-metadata --port 3309 &
mysql -h 127.0.0.1 -P 3309 -u root mydb < migration.sql

# 3. Create deploy request
pscale deploy-request create mydb add-user-metadata

# 4. Review diff
pscale deploy-request diff mydb 1

# 5. Deploy to production (non-blocking, Vitess online DDL)
pscale deploy-request deploy mydb 1

# 6. Cleanup
pscale branch delete mydb add-user-metadata
```

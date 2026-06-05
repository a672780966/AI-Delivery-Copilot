# Infra

包含 Docker Compose、PostgreSQL、Redis、数据库迁移和 seed 数据。

## 启动

```bash
cd infra
docker compose up --build
```

## 数据库迁移

示例迁移文件在 `infra/migrations/001_create_tables.sql`。可以在容器内或本地连接 PostgreSQL 执行该语句。

## 数据初始化

种子数据文件位于 `infra/seed_data.sql`。

## 迁移执行

使用迁移脚本自动执行数据库创建和种子数据导入：

```bash
cd infra
chmod +x apply_migrations.sh
./apply_migrations.sh
```

脚本会在 `db` 服务未运行时自动启动它，并依次执行 `infra/migrations/*.sql` 和 `infra/seed_data.sql`。

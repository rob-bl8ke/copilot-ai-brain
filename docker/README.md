

## Usage (`run-env.sh`)

Start all services (Docker, PostgreSQL, Kafka, Spring Boot backend, Angular frontend):

```bash
./run-env.sh
```

This starts everything in the background and returns your terminal immediately with a free prompt. You can then run commands while services run.

Stop everything (keeps databases):

```bash
./run-env.sh --down   # or: ./run-env.sh -d
```

Stop everything and delete all databases:

```bash
./run-env.sh --down-db
```

### Services & URLs

Once started, services are available at:

- **Frontend**: http://localhost:4200
- **Backend**: http://localhost:8080
- **AKHQ (Kafka UI)**: http://localhost:9099/ui

### Logs

Both backend and frontend log to files in `./logs/`:

```bash
# Watch backend logs in real-time
tail -f logs/backend.log

# Watch frontend logs in real-time
tail -f logs/frontend.log
```

### What the script handles

- **PostgreSQL initialization** — Waits for Postgres to be ready and ensures `shipping` database exists (even if the volume persisted from a previous run).
- **Kafka broker connectivity** — Sets `KAFKA_BOOTSTRAP_SERVERS=localhost:29092` (the external Docker advertised address) instead of the internal `:9092`, so the backend can reach Kafka from the host.
- **Process management** — Tracks all service PIDs so `./run-env.sh --down` cleanly kills the entire process tree (including forked JVMs), freeing ports and resources.

## Troubleshooting

### Databases persist after teardown

PostgreSQL and Kafka data are stored in Docker volumes that survive `docker compose down`. If you need a fresh database state:

```bash
./run-env.sh --down-db
```

This removes all volumes, so the next `./run-env.sh` will initialize fresh databases.

### Port 8080 still in use after `./run-env.sh --down`

Kill any lingering process on port 8080:

```bash
lsof -ti:8080 | xargs kill
```

### Check if a service is running on a port

```bash
lsof -i:8080
```

If no output, the port is free.

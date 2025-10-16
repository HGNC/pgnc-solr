# PGNC Solr Service

Apache Solr powers search for the PGNC (Plant Gene Nomenclature Committee) stack. This directory builds the Solr container, installs additional libraries, and packages the `pgnc` core configuration served inside `docker-compose.yml`.

## Layout

- `Dockerfile` – extends `solr:9.9.0` and adds the Jakarta Activation dependency required by the Data Import Handler
- `cores/` – mounted into `/var/solr/data` so the container boots with the `pgnc` core pre-configured
  - `data/pgnc/conf/` – schema, config, synonyms, stopwords, and DIH files
  - `data/security.json` – basic auth definition for admin/client roles
  - `log4j2.xml` and `logs/` – logging configuration and (optional) persisted logs
- `web.xml` – overrides shipped with Solr image when necessary
- `.dockerignore` – keeps build context lean

The directory is tracked as part of the main repository (not a submodule); ensure edits follow the AGPL licensing requirements.

## Runtime Integration

- `solr` service in `docker-compose.yml` mounts `./solr/cores/data:/var/solr/data` and exposes port `LOCALHOST_SOLR_PORT` (default 8983)
- Health check hits the core status endpoint using the admin credentials defined in `.env`
- `python` service populates the index via the Data Import Handler using the configuration in `data-config.xml`
- `solr-client` service proxies search traffic to the NestJS API and Angular frontend

## Starting the Service

```bash
# Build after configuration changes
docker compose build solr

# Launch Solr (dependencies handled automatically)
docker compose up -d solr

# Verify the core is online
curl -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
  "http://localhost:${LOCALHOST_SOLR_PORT:-8983}/solr/admin/cores?action=STATUS"
```

Visit `http://localhost:${LOCALHOST_SOLR_PORT:-8983}/solr` and log in with the admin credentials from `.env` to inspect the Admin UI.

## Configuration Highlights

- **Schema (`managed-schema`)** – defines fields for gene identifiers, names, locus metadata, cross references, and faceting. Analyzer chains are tuned for gene nomenclature via `protwords.txt`, `stopwords.txt`, and language-specific resources in `conf/lang/`.
- **Core Settings (`solrconfig.xml`)** – enables request handlers for search (`/select`), suggestions (`/suggest`), and data import (`/dataimport`). Cache implementations use Caffeine (default for Solr 9.x).
- **Data Import (`data-config.xml`)** – maps PostgreSQL queries to Solr documents. Credentials and JDBC connection information come from environment variables passed by Compose.
- **Security (`security.json`)** – defines basic-auth users (admin + client). Avoid checking in production credentials; use environment overrides when possible.
- **Overlay (`configoverlay.json`)** – provides runtime configuration adjustments that complement `solrconfig.xml`.

When modifying configuration files, keep the core directory structure intact so `solr` can start without manual intervention.

## Updating Schema or Config

1. Edit the relevant file under `cores/data/pgnc/conf/`.
2. Rebuild the container if new libraries or config files are introduced: `docker compose build solr`.
3. Restart the service: `docker compose restart solr`.
4. Reload the core to apply schema tweaks without restarting (when possible):

   ```bash
   curl -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
     "http://localhost:${LOCALHOST_SOLR_PORT:-8983}/solr/admin/cores?action=RELOAD&core=pgnc"
   ```

5. Trigger a full reindex using the Python data pipeline (see `python/bin/data-update`).

## Indexing Workflow

```bash
# Ensure database and Solr are running and healthy
docker compose up -d pgncdb solr

# Load canonical data
docker compose up python

# Perform incremental refreshes as needed
cd python/bin/data-update
python main.py --clear   # optional: wipe index
python main.py           # rebuild index
```

The DIH configuration expects environment variables (`DB_HOST`, `DB_USER`, etc.) provided by Compose; confirm they match your database before running the data loader.

## Operations

- **Health** – the Compose health check calls the core status endpoint. Manually test with `curl` as shown above.
- **Logs** – `docker compose logs -f solr` tails container logs; additional rolling logs live under `cores/logs/` if mounted.
- **Backups** – Use Solr’s replication API against a writable volume. Example:

  ```bash
  curl -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:${LOCALHOST_SOLR_PORT:-8983}/solr/pgnc/replication?command=backup&name=backup_$(date +%Y%m%d)"
  ```

- **Optimisation** – Run periodically if the index churns heavily:

  ```bash
  curl -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:${LOCALHOST_SOLR_PORT:-8983}/solr/pgnc/update?optimize=true"
  ```

- **Configuration Dump** – `docker compose exec solr solr zk ls /config/pgnc` (when running single-node ZK under the hood) or inspect `solrconfig.xml` directly in the repository.

## Troubleshooting

- **Authentication failures** – ensure `SOLR_ADMIN_USER` and `SOLR_ADMIN_PASSWORD` (and client equivalents) are set in `.env` and exported to the running service.
- **Core missing on startup** – check that `cores/data/pgnc/core.properties` is present and that the host volume is writable; remove stale `data/` directories if restoring from scratch.
- **Slow queries** – use the Admin UI > Query screen to profile; review field analyzers and cache hit ratios. Consider running the Python loader with `--clear` to remove deleted docs.
- **DIH errors** – tail logs while running `python main.py` and confirm JDBC driver dependencies are available (Jakarta Activation JAR is added by the Dockerfile for this purpose).

## Integration Pointers

- The `solr-client` service exposes a read-only interface for NestJS and Angular; keep credentials aligned between `solr` and `solr-client`.
- Nginx proxies `/ses/*` requests to the `solr-client` container (see `nginx/nginx.conf`).
- Environment defaults are documented in the root `sample.env`; adjust ports, usernames, and passwords centrally there.

## License

This directory inherits the repository’s AGPL-3.0 license. Review `LICENSE` at the repository root for full terms.

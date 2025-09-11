# PGNC Solr Search Engine

[![Apache Solr](https://img.shields.io/badge/Apache%20Solr-8.x-orange.svg)](https://solr.apache.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Overview

This repository contains the Apache Solr search configuration for the PGNC (Plant Gene Nomenclature Committee) project. Solr provides fast, scalable search functionality for plant gene nomenclature data, enabling efficient querying of gene symbols, names, locations, and cross-references.

## Current Configuration

- **Solr Version**: 8.x (Docker: `solr:8`)
- **Lucene Version**: 8.5.2
- **Core Name**: `pgnc`
- **Security**: BasicAuth enabled with admin/client user roles
- **Cache Implementation**: LRUCache and FastLRUCache (Solr 8.x compatible)

## Architecture

```
solr/
├── cores/                    # Solr cores configuration
│   ├── data/                # Core data and configuration
│   │   ├── pgnc/           # PGNC core configuration
│   │   │   ├── conf/       # Core configuration files
│   │   │   │   ├── managed-schema     # Schema definition
│   │   │   │   ├── solrconfig.xml     # Core configuration
│   │   │   │   ├── synonyms.txt       # Synonym mappings
│   │   │   │   └── data-config.xml    # Data import configuration
│   │   │   ├── data/       # Index data and logs
│   │   │   └── solr-import/ # Data import files
│   │   ├── security.json   # Authentication configuration
│   │   └── solr.xml       # Solr instance configuration
│   └── logs/               # Solr application logs
├── Dockerfile              # Container configuration (FROM solr:8)
└── web.xml                 # Web application configuration
```

## Key Features

### Search Capabilities

- **Full-text search** across gene symbols, names, and descriptions
- **Faceted search** by gene status, locus type, and chromosomal location
- **Autocomplete/suggest** functionality for gene symbols and names
- **Synonym support** for alternative gene nomenclature
- **Cross-reference search** across multiple databases (Ensembl, NCBI, UniProt)

### Performance Optimizations

- **LRU caching** optimized for Solr 8.x
- **Optimized field types** for different data types (text, string, location)
- **Efficient indexing** with proper field analysis and tokenization
- **Request handler optimization** for common query patterns

### Security Features

- **BasicAuth authentication** with role-based access control
- **Admin user** for full administrative access
- **Client user** for read-only search operations
- **Secure credential management** via environment variables

## Setup and Installation

### Prerequisites

- Docker or Podman with Compose support
- Environment file (`.env`) with Solr credentials
- Java 8+ (handled automatically in Docker container)

### Quick Start

1. **Build and start the container**:

   ```bash
   docker compose up -d solr
   ```

2. **Verify installation**:

   ```bash
   curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD \
     http://localhost:8983/solr/admin/cores?action=STATUS
   ```

3. **Access Solr Admin UI**:
   - URL: <http://localhost:8983/solr>
   - Login with admin credentials from `.env` file

### Data Loading

The PGNC core is automatically populated by the Python data loading service:

```bash
# Load initial data
docker compose up python

# Update search index
cd python/bin/data-update
python main.py --clear  # Clear existing index
python main.py          # Load fresh data
```

## Configuration Files

### managed-schema

Defines the document structure and field types for gene data:

- **Gene fields**: symbol, name, status, location
- **Cross-reference fields**: ensembl_id, ncbi_id, uniprot_id
- **Text analysis**: Custom analyzers for gene nomenclature
- **Field types**: Optimized for search and faceting

### solrconfig.xml

Core configuration including:

- **Cache settings**: LRUCache and FastLRUCache for Solr 8.x compatibility
- **Lucene version**: 8.5.2 match version
- **Request handlers**: Search, suggest, and data import handlers
- **Update processors**: Data transformation and validation
- **Security settings**: Authentication and authorization

### data-config.xml

Data import configuration for loading from PostgreSQL:

- **Database connection**: Direct connection to PGNC database
- **Entity mapping**: SQL queries to Solr documents
- **Field transformations**: Data formatting and enrichment

## Usage Examples

### Basic Search

```bash
# Search for genes containing "ABC"
curl "http://localhost:8983/solr/pgnc/select?q=ABC"

# Search specific field
curl "http://localhost:8983/solr/pgnc/select?q=symbol:ABC*"
```

### Faceted Search

```bash
# Get facets by gene status
curl "http://localhost:8983/solr/pgnc/select?q=*:*&facet=true&facet.field=status"
```

### Autocomplete

```bash
# Get suggestions for gene symbols
curl "http://localhost:8983/solr/pgnc/suggest?suggest.q=AB"
```

## Maintenance

### Index Optimization

```bash
# Optimize the index for better performance
curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD \
  "http://localhost:8983/solr/pgnc/update?optimize=true"
```

### Backup and Restore

```bash
# Create backup
curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD \
  "http://localhost:8983/solr/pgnc/replication?command=backup&name=backup_$(date +%Y%m%d)"

# Restore from backup
curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD \
  "http://localhost:8983/solr/pgnc/replication?command=restore&name=backup_20250101"
```

### Monitoring

- **Admin UI**: Monitor core statistics and performance
- **Logs**: Check `cores/logs/` for application logs
- **Health checks**: Automated health monitoring in Docker Compose

## Troubleshooting

### Common Issues

**Authentication Errors**: Verify credentials in `.env` file

```bash
echo "SOLR_ADMIN_USER: $SOLR_ADMIN_USER"
echo "SOLR_ADMIN_PASSWORD: $SOLR_ADMIN_PASSWORD"
```

**Index Issues**: Reload core configuration

```bash
curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD \
  "http://localhost:8983/solr/admin/cores?action=RELOAD&core=pgnc"
```

**Performance Issues**: Check cache statistics in Admin UI

- Navigate to Core Admin > pgnc > Statistics
- Monitor cache hit ratios and memory usage

### Log Analysis

```bash
# View recent logs
docker compose logs -f solr

# Check for specific errors
docker compose logs solr | grep ERROR
```

## Development

### Schema Changes

1. Edit `cores/data/pgnc/conf/managed-schema`
2. Reload the core: `curl -u $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD "http://localhost:8983/solr/admin/cores?action=RELOAD&core=pgnc"`
3. Reindex data if needed

### Configuration Updates

1. Modify `cores/data/pgnc/conf/solrconfig.xml`
2. Restart Solr service: `docker compose restart solr`
3. Verify changes in Admin UI

## Integration

The Solr service integrates with other PGNC components:

- **API**: NestJS 10.x API queries Solr via the solr-client service
- **Frontend**: Angular 19.1+ application uses API endpoints for search
- **Database**: Python 3.13+ scripts synchronize PostgreSQL 17.0 data with Solr index
- **Security**: Authentication integrated with overall application security

## Performance

Current performance characteristics:

- **Index size**: Optimized for ~50K+ gene records
- **Query response**: < 100ms for typical searches
- **Suggest response**: < 50ms for autocomplete
- **Memory usage**: ~2GB RAM for full dataset
- **Concurrent users**: Tested for 100+ simultaneous searches

## Upgrade Path

This project currently uses Solr 8.x. For future upgrades to Solr 9.x:

- Java 11+ requirement
- Cache implementation migration (LRUCache → CaffeineCache)
- Lucene version update (8.5.2 → 9.x)
- Configuration schema updates

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See the [LICENSE](../LICENSE) file for details.

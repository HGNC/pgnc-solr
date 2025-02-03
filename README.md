# PGNC Solr search engine
This repository contains the Solr search configuration for the PGNC (Plant Gene Nomenclature Committee) project.

## Overview
Solr powers the search functionality for PGNC, enabling fast and efficient searching of PostgreSQL documentation and related content.

## Setup
1. Install Solr (version 8.x or higher)
2. Clone this repository
3. Copy configuration files to your Solr installation
4. Start Solr service

## Configuration
The main configuration files are:
- `schema.xml`: Defines document structure and field types
- `solrconfig.xml`: Contains core configuration settings
- `synonyms.txt`: Custom synonym mappings

## Usage
Access the Solr admin interface at `http://localhost:8983/solr/`

## Maintenance
Regular optimization and backup procedures are recommended.
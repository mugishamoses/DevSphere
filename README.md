# DevSphere - MoMo SMS Data Processing System

## Team Information
**Team Name:** DevSphere

**Team Members:**
- [Member 1 Name] - [GitHub Username] - Mugisha Moses
- [Member 2 Name] - [GitHub Username] - Lisa Ineza
- [Member 3 Name] - [GitHub Username] - Nkingi Chris


## Project Description
DevSphere is an enterprise-level fullstack application designed to process, analyze, and visualize MoMo (Mobile Money) SMS transaction data. The system implements a robust ETL (Extract, Transform, Load) pipeline that:

- **Parses** XML-formatted MoMo SMS data
- **Cleans & Normalizes** transaction amounts, dates, and phone numbers
- **Categorizes** transactions by type (deposits, withdrawals, transfers, etc.)
- **Stores** processed data in a SQLite relational database
- **Visualizes** analytics through an interactive web dashboard
- **Provides** RESTful API endpoints for data access (bonus feature)

## System Architecture
High-Level Architecture Diagram:** [View Diagram](https://drive.google.com/file/d/1DGuZax9Q7vG3ZBcaDFQD7OxBJoXdOU2L/view?usp=sharing)

![Architecture Diagram](./docs/architecture.png)

### Architecture Overview
```
┌─────────────────┐
│   XML Input     │
│  (MoMo SMS)     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         ETL Pipeline (Python)           │
├─────────────────────────────────────────┤
│  1. Parse XML (ElementTree/lxml)        │
│  2. Clean & Normalize Data              │
│  3. Categorize Transactions             │
│  4. Load to Database                    │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  SQLite DB      │
│  (Relational)   │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
│  JSON Export    │  │  FastAPI     │  │  Frontend    │
│  (dashboard.json)│  │  REST API    │  │  Dashboard   │
└─────────────────┘  └──────────────┘  └──────────────┘
```

## Project Structure
```
.
├── README.md                         # Setup, run, overview
├── .env.example                      # DATABASE_URL or path to SQLite
├── .gitignore                        # Git ignore patterns
├── requirements.txt                  # lxml/ElementTree, dateutil, (FastAPI optional)
├── index.html                        # Dashboard entry (static)
├── web/
│   ├── styles.css                    # Dashboard styling
│   ├── chart_handler.js              # Fetch + render charts/tables
│   └── assets/                       # Images/icons (optional)
├── data/
│   ├── raw/                          # Provided XML input (git-ignored)
│   │   └── momo.xml
│   ├── processed/                    # Cleaned/derived outputs for frontend
│   │   └── dashboard.json            # Aggregates the dashboard reads
│   ├── db.sqlite3                    # SQLite DB file
│   └── logs/
│       ├── etl.log                   # Structured ETL logs
│       └── dead_letter/              # Unparsed/ignored XML snippets
├── etl/
│   ├── __init__.py
│   ├── config.py                     # File paths, thresholds, categories
│   ├── parse_xml.py                  # XML parsing (ElementTree/lxml)
│   ├── clean_normalize.py            # Amounts, dates, phone normalization
│   ├── categorize.py                 # Simple rules for transaction types
│   ├── load_db.py                    # Create tables + upsert to SQLite
│   └── run.py                        # CLI: parse -> clean -> categorize -> load -> export JSON
├── api/                              # Optional (bonus)
│   ├── __init__.py
│   ├── app.py                        # Minimal FastAPI with /transactions, /analytics
│   ├── db.py                         # SQLite connection helpers
│   └── schemas.py                    # Pydantic response models
├── scripts/
│   ├── run_etl.sh                    # python etl/run.py --xml data/raw/momo.xml
│   ├── export_json.sh                # Rebuild data/processed/dashboard.json
│   └── serve_frontend.sh             # python -m http.server 8000 (or Flask static)
├── tests/
│   ├── test_parse_xml.py             # Small unit tests
│   ├── test_clean_normalize.py
│   └── test_categorize.py
└── docs/
    └── architecture.png              # System architecture diagram
```
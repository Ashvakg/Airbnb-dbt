# Airbnb Analytics Engineering Platform
**Snowflake · dbt · AWS · Python**

## 1. Why I Built This

I designed this project to demonstrate how I **build and own analytics‑ready data platforms** that empower self‑service analysis while preserving **data correctness, historical truth, and operational safety**. Rather than focusing only on ingestion or tooling, it emphasises analytics engineering principles: clear modelling decisions, stable data contracts, business‑aligned transformations, robust data quality guarantees and safe change management through CI/CD.  
The goal is to show how I think about data systems in a production context—so that analysts and BI tools can answer questions **without needing to understand raw schemas or complex joins**, and so that the data team can confidently evolve the system over time.

## 2. Business Context & Use Cases

This platform is intentionally designed to support real‑world business questions—not just technical correctness.

*Example business questions enabled*:

- **How are bookings trending over time by location and listing type?**  
  Analysts can query the Gold fact table by date and category to track demand patterns without writing complex joins.
- **Which hosts or listings show declining performance?**  
  The SCD2 snapshots provide historical versions of hosts and listings to analyse changes in quality metrics over time.
- **How do price categories impact booking volume?**  
  A custom macro categorises nightly prices into low/medium/high buckets, making segmentation trivial.
- **What is the average lead time for bookings?**  
  Derived metrics in the Gold layer calculate booking lead times, enabling retention and forecasting analyses.

By encoding business logic once and exposing analytics‑ready datasets, the platform reduces repeated analyst effort, prevents inconsistent metric definitions and lowers the risk of incorrect conclusions.  This reflects how analytics engineering supports decision‑making at scale.

## 3. Intended Consumers & Data Guarantees

### Intended consumers

- **Analytics / Product analysts** – self‑service querying via analytics‑ready tables and a denormalised OBT (One Big Table).  
- **BI tools** – stable Gold‑layer models optimised for dashboarding and reporting.  
- **Data teams** – tested, version‑controlled transformations with clear lineage and contracts.

### Data guarantees

- **Stable grain** at the Gold layer (one row per booking, listing or host).  
- **Historical correctness** via SCD Type  2 modelling for slowly changing dimensions.  
- **Breaking changes detected** before deployment through CI/CD and dbt tests.  
- **Consistent business logic** applied centrally so metrics do not drift across teams.

## 4. High‑Level Architecture

```
Raw source CSVs (bookings, hosts, listings)
      |
      ▼
AWS S3 → Snowflake (staging tables)
      |
      ▼
Bronze models    – Raw, minimally transformed data
      |
      ▼
Silver models    – Cleaned, typed, validated datasets
      |
      ▼
Gold models      – Analytics‑ready facts, dimensions, OBT & metrics
      |
      ▼
BI / Analytics / Ad‑hoc SQL
```

The architecture follows a **Medallion** (Bronze → Silver → Gold) pattern to separate raw ingestion from cleaned data and analytical contracts.  Snowflake serves as the cloud warehouse, AWS S3 provides object storage for initial uploads and dbt orchestrates all transformations.

## 5. Technology Stack

| Component                   | Purpose                                                     |
|----------------------------|--------------------------------------------------------------|
| **Snowflake**              | Cloud data warehouse for storage and compute                |
| **dbt** (core, Snowflake)  | Transformation & modelling framework; manages schemas, tests |
| **AWS S3**                 | Staging area for raw CSV uploads                            |
| **Python**                 | Automation / orchestration (e.g., `main.py`)                |
| **Git & GitHub Actions**   | Version control and CI/CD for safe deployment               |

## 6. Data Modelling Strategy & Grain Decisions

### Core design principle

Every model has an **explicit grain**, and that grain is enforced consistently across layers to avoid ambiguity and double‑counting.

### Grain definitions

- **Bookings** – one row per `booking_id` (event‑level fact).  
- **Listings** – one row per `listing_id`, modelled historically as a slowly changing dimension (SCD Type  2).  
- **Hosts** – one row per `host_id`, also tracked historically with SCD Type  2 snapshots.

### Why this matters

- Clear grains prevent analytical errors and double counting.  
- Historical modelling enables point‑in‑time analysis for trending and auditing.  
- Downstream consumers can trust the data without re‑validating business logic in each query.

## 7. Bronze / Silver / Gold Responsibilities

### 🥉 Bronze layer – Raw representation

The bronze models mirror the staging tables with minimal transformations.  They preserve source fidelity and act as an audit/debug layer.  Examples: `bronze_bookings`, `bronze_hosts`, `bronze_listings`.

### 🥈 Silver layer – Correctness boundary

Silver models enforce data typing, validation and standardisation.  Duplicates and invalid records are removed, and fields are cast to consistent data types.  These models are business‑agnostic but opinionated about correctness.  Examples: `silver_bookings`, `silver_hosts`, `silver_listings`.

### 🥇 Gold layer – Analytics contracts

Gold models encode business logic and provide stable, analytics‑ready tables.  They include:

- **Fact tables** (e.g., `fact_bookings`) with one row per event.  
- **Dimensions** (e.g., `dim_listings`, `dim_hosts`) modelled with SCD Type  2 snapshots to track historical changes.  
- **One Big Table (OBT)** – a denormalised table joining bookings, listings and hosts for ad‑hoc analysis and simplified querying.  

The Gold layer changes slowly and is treated as a contract between the data team and consumers.

## 8. Analytics Layer & One Big Table (OBT)

To optimise analyst productivity, the platform provides both dimensional models and a **denormalised One Big Table**.

- **Why an OBT exists** – Reduces join complexity for analysts, improves usability in BI tools and trades storage efficiency for clarity and speed.  
- The OBT is built **on top of validated Silver models**, ensuring correctness while prioritising ease of use.  
- Dynamic SQL generation using Jinja loops keeps join logic maintainable and extensible as new entities are added.

## 9. Slowly Changing Dimensions (SCD Type 2)

Listings and hosts are modelled using SCD Type 2 snapshots to preserve historical truth.  Each snapshot tracks `valid_from` and `valid_to` timestamps, enabling point‑in‑time analysis and preventing loss of historical attributes.  This approach is critical for auditing changes in host status, listing characteristics and price categories over time.

## 10. Incremental Processing & Performance

Incremental materialisations are used where appropriate to minimise compute costs and scale with growing datasets.  For example:

```sql
{{ config(materialized='incremental') }}

{% if is_incremental() %}
    WHERE created_at > (SELECT COALESCE(MAX(created_at), '1900-01-01') FROM {{ this }})
{% endif %}
```

This pattern mirrors production analytics workloads, ensuring that only new or changed data is processed while historical data remains intact.

## 11. Data Quality, Testing & Trust

Data quality is a **first‑class concern** in this platform.

- **Source validation & freshness** – All sources are declared with freshness expectations in `sources.yml` and tested via dbt.  
- **Primary key uniqueness & not‑null checks** – Each table enforces uniqueness and non‑null constraints on critical fields.  
- **Referential integrity tests** – Foreign keys are validated between fact tables and dimensions.  
- **Custom business rule tests** – Domain‑specific checks (e.g., price thresholds, date ranges) ensure that business logic is upheld.  

Failed tests block deployment via CI/CD, so issues are detected before reaching BI tools.  dbt’s lineage graph also tracks dependencies, enabling safe refactoring and impact analysis.

## 12. CI/CD & Operational Readiness

The repository uses **GitHub Actions** to ensure safe, repeatable deployments:

- On every push or pull request, dependencies are installed and `dbt build` is executed to run models, tests and snapshots.  
- If tests fail or compilation errors occur, the pipeline stops and highlights the issue before merge.  
- Small, reviewable changes enable collaboration across data teams and prevent broken models from reaching production.  

This mirrors real‑world analytics engineering workflows, where trust in the pipeline is critical.

## 13. Repository Structure

```
Airbnb-dbt/
│
├── .vscode/                     # IDE settings (ignored in analytics build)
├── DBT_AE/                      # Core dbt project (renamed from aws_dbt_snowflake_project)
│   │
│   ├── dbt_project.yml          # dbt project configuration
│   ├── README.md                # dbt-specific getting-started guide (default)
│   │
│   ├── models/                  # dbt models organised by layer
│   │   ├── sources/             # Source declarations & freshness tests
│   │   ├── bronze/              # Bronze raw representations
│   │   ├── silver/              # Silver cleaned & validated datasets
│   │   └── gold/                # Gold analytic contracts, fact tables & OBT
│   │       └── …
│   │
│   ├── snapshots/               # SCD Type 2 configurations
│   ├── macros/                  # Reusable Jinja macros
│   ├── tests/                   # Additional data quality tests
│   └── analyses/                # Ad‑hoc exploration queries
│
├── Sourcedata/                 # Raw CSV files for initial load
├── logs/                       # Log files generated by Python/CI
├── main.py                    # Orchestration script for local runs
├── pyproject.toml             # Python dependencies
├── uv.lock                    # Dependency lock file
├── .gitignore                 # Excluded files
├── .python-version            # Python runtime version
└── README.md                  # This document
```

The key takeaway is that **all analytical schemas and transformations are defined in the dbt project**.  The `DDL` scripts from the original template are minimal and only used for staging table definitions; they are **not** the source of truth for analytics.  dbt manages schemas, tests and documentation, ensuring consistency across environments.

## 14. Documentation & Discoverability

Documentation is part of the data product, not an afterthought.

- **dbt docs** – Each model includes descriptions and column‑level metadata. Source definitions specify freshness expectations and accepted values. Running `dbt docs generate` produces interactive documentation that displays lineage, model descriptions and dependencies.  
- **Lineage graph** – The built‑in lineage view reveals upstream and downstream impacts for each model, helping engineers and analysts understand the full data flow.  
- **Repository README** – This README provides context, design decisions and trade‑offs. The folder structure mirrors architectural responsibilities, and naming conventions reflect grain and purpose.  

These practices ensure the platform is understandable, auditable and evolvable.

## 15. Business Metrics & Decision Enablement

To ensure consistent metrics across the organisation, key business metrics are defined centrally in the Gold layer.  Examples include:

| Metric                    | Definition                                                      | Purpose                                   |
|--------------------------|----------------------------------------------------------------|-------------------------------------------|
| `booking_count`          | Count of distinct `booking_id` per period                      | Measure demand and business volume        |
| `avg_price_per_night`    | Average of `price_per_night` for confirmed bookings            | Assess pricing strategy effectiveness     |
| `active_listings`        | Count of listings with at least one booking in a given period  | Monitor marketplace supply                |
| `cancellation_rate`      | Ratio of cancelled bookings to total bookings                  | Identify potential service or policy issues |

Defining metrics centrally prevents drift across dashboards and ensures that all teams speak the same language when evaluating performance.  Analysts use these pre‑defined measures rather than re‑calculating logic in their own queries.

## 16. Analyst Experience: Before vs After

### Before this platform

- Analysts joined 4‑5 raw tables with complex join conditions and wrote nested SQL to derive metrics.  
- Business logic (e.g., price categorisation, date truncation) was duplicated across notebooks and dashboards, leading to inconsistencies.  
- Queries were brittle: a schema change in the raw data could silently break reports.  

### After this platform

- Analysts query a single OBT or Gold fact table; joins are abstracted away in dbt models.  
- Business logic is encoded once in dbt and reused; analysts focus on insights rather than wrangling.  
- CI/CD and tests catch schema or logic changes before they reach consumers, reducing fire‑drills.  
- Exploratory analysis is faster, and dashboards built on top of stable Gold models do not need rewriting when new fields are added upstream.

This transformation illustrates how analytics engineering improves analyst productivity and trust.

## 17. Design Trade‑offs & Alternatives Considered

- **Denormalised OBT vs strictly dimensional models** – I chose to provide both because the OBT significantly lowers the barrier for exploratory analysis and dashboarding, while dimensional models maintain analytical integrity for more complex queries.  Solely relying on dimensional modelling would increase join complexity for non‑technical users.  
- **SCD Type 2 snapshots vs overwriting dimensions** – SCD Type 2 preserves historical context, which is essential for auditing and trend analysis. Overwriting would lose valuable information about how listings and hosts evolve over time.  
- **Incremental materialisation vs full refresh** – Incremental models reduce compute cost and allow scaling with data volume.  However, they require careful handling of late‑arriving data; my tests and macros ensure correctness.  
- **dbt‑managed schemas vs hand‑written DDL** – The dbt approach centralises logic and documentation, making changes easier to manage and removing the risk of divergence between code and warehouse schema.  DDL scripts are kept minimal for initial staging only.

## 18. Future Scope & Platform Evolution

This platform is designed to evolve as data volume, use cases and governance needs grow.  Planned extensions include:

- **BI integration** – Native dashboards using Metabase or Power BI built on top of the Gold models and OBT.  
- **Data observability** – Freshness and volume monitoring, with alerting on test failures and anomalies.  
- **Metrics layer** – A centralised metrics service (e.g., MetricFlow) to standardise business measures and provide API access to metrics.  
- **Governance & security** – PII classification and masking; role‑based access controls aligned to consumer needs.  
- **Scalability enhancements** – Partitioning and clustering strategies, plus expanded incremental processing.  

These improvements reflect how an analytics platform matures in a real production environment.

---

## 19. How to Run Locally (Optional)

For completeness, if you wish to run the project locally:

1. **Clone the repository** and navigate to its directory.  
   ```bash
   git clone <repo-url>
   cd Airbnb-dbt
   ```
2. **Set up a Python virtual environment** (Python 3.9 or above).  
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ```
3. **Install dependencies**.  
   ```bash
   pip install -r requirements.txt
   ```
4. **Configure your Snowflake profile** in `~/.dbt/profiles.yml`. Use the example in `DBT_AE/ExampleProfiles.yml` as a template.  
5. **Load the raw CSVs** into Snowflake or run `main.py` to orchestrate an end‑to‑end pipeline.  
6. **Run dbt commands**:  
   ```bash
   cd DBT_AE
   dbt debug          # Validate connection
   dbt deps           # Install packages
   dbt build          # Run models, tests & snapshots
   dbt docs generate  # Generate documentation
   ```

---

## 20. Concluding Remarks

This project reflects my approach to analytics engineering in real organisations: balancing usability, correctness and performance while thinking deeply about business value and analyst experience.  It is not just an ETL pipeline; it is a data platform designed for scale, reliability and self‑service.  

If you have questions or suggestions, feel free to open an issue or contact me.  I hope this provides insight into how I think about building data systems that serve both technical teams and business stakeholders.

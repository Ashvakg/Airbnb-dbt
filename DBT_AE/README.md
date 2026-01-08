# DBT_AE – Analytics Engineering Project

This directory contains the dbt project for the Airbnb Analytics Engineering Platform. For a comprehensive overview of the system—including business context, architecture, modeling strategy, grain definitions, data quality, CI/CD setup, and design trade-offs—please refer to the top-level `README.md` in this repository.

This `README.md` provides basic usage instructions for working within the `DBT_AE` project.

### Running models

From the `DBT_AE` directory:

```bash
dbt deps     # install required packages
dbt build    # run models, tests and snapshots
```

To run a specific layer:

```bash
dbt run --select bronze.*
dbt run --select silver.*
dbt run --select gold.*
```

### Running tests

```bash
dbt test
```

### Generating documentation

```bash
dbt docs generate
dbt docs serve
```

### Snapshots

To create and update slowly changing dimension snapshots:

```bash
dbt snapshot
```

For detailed definitions of bronze, silver and gold layers, incremental models, SCD2 snapshots, and macros, see the root `README.md`.

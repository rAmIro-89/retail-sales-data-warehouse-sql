# Project Documentation

## Overview
Welcome to the Retail Sales Data Warehouse project documentation. This project implements a comprehensive data warehousing solution for retail sales analytics using SQL and Python ETL pipelines.

## Contents

1. **Architecture Overview** - System design and data flow
2. **Data Model** - Star schema design and table relationships
3. **ETL Pipeline** - Extract, Transform, Load process documentation
4. **Setup Guide** - Installation and configuration instructions
5. **Usage Examples** - Code examples and best practices
6. **API Reference** - Module and function documentation

## Project Structure

```
retail-sales-data-warehouse-sql/
├── data/
│   ├── raw/              # Raw data files
│   └── processed/        # Processed/cleaned data
├── sql/
│   ├── ddl/             # Data Definition Language scripts
│   ├── dml/             # Data Manipulation Language scripts
│   └── views/           # View definitions
├── src/
│   ├── etl/             # ETL pipeline modules
│   │   ├── extract.py
│   │   ├── transform.py
│   │   └── load.py
│   └── utils/           # Utility modules
│       └── db_connection.py
├── notebooks/           # Jupyter notebooks for analysis
│   └── eda_starter.ipynb
└── docs/               # Documentation
```

## Quick Start

### Prerequisites

- Python 3.8+
- PostgreSQL/MySQL/SQLite database
- Required Python packages: pandas, numpy, psycopg2-binary (or mysql-connector-python)

### Installation

1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure database connection (see Setup Guide)
4. Run DDL scripts to create tables
5. Execute ETL pipeline to load data

### Basic Usage

```python
# Extract data
from src.etl.extract import DataExtractor
extractor = DataExtractor()
df = extractor.extract_from_csv('sales.csv')

# Transform data
from src.etl.transform import DataTransformer
transformer = DataTransformer()
df_clean = transformer.clean_data(df)

# Load data
from src.etl.load import DataLoader
from src.utils.db_connection import get_connection

with get_connection() as db:
    loader = DataLoader(db)
    loader.load_fact_table(df_clean, 'fact_sales')
```

## Data Model

The data warehouse uses a star schema with the following structure:

### Dimension Tables
- **dim_date** - Time dimension
- **dim_customer** - Customer information
- **dim_product** - Product catalog
- **dim_store** - Store locations

### Fact Tables
- **fact_sales** - Sales transactions

### Views
- **v_sales_summary** - Comprehensive sales summary
- **v_monthly_sales** - Monthly aggregated metrics
- **v_product_performance** - Product-level KPIs
- **v_customer_analytics** - Customer behavior analytics
- **v_store_performance** - Store-level metrics

## Contributing

Please refer to the project's contribution guidelines before submitting pull requests.

## License

See LICENSE file for details.

## Support

For questions or issues, please open an issue in the repository.

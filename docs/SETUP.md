# Setup Guide

## Prerequisites

### System Requirements
- Python 3.8 or higher
- Database server (PostgreSQL, MySQL, or SQLite)
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### Software Dependencies
- pandas >= 1.3.0
- numpy >= 1.21.0
- psycopg2-binary >= 2.9.0 (for PostgreSQL)
- mysql-connector-python >= 8.0.0 (for MySQL)
- jupyter >= 1.0.0
- matplotlib >= 3.4.0
- seaborn >= 0.11.0

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/rAmIro-89/retail-sales-data-warehouse-sql.git
cd retail-sales-data-warehouse-sql
```

### 2. Set Up Python Environment

#### Using venv (recommended)
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

#### Using conda
```bash
conda create -n retail_dw python=3.9
conda activate retail_dw
```

### 3. Install Dependencies

Create a `requirements.txt` file with the following content:

```
pandas>=1.3.0
numpy>=1.21.0
psycopg2-binary>=2.9.0
mysql-connector-python>=8.0.0
jupyter>=1.0.0
matplotlib>=3.4.0
seaborn>=0.11.0
```

Then install:

```bash
pip install -r requirements.txt
```

### 4. Database Setup

#### PostgreSQL Setup

1. Install PostgreSQL:
```bash
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# macOS
brew install postgresql
```

2. Create database and user:
```sql
CREATE DATABASE retail_dw;
CREATE USER dw_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE retail_dw TO dw_user;
```

3. Run DDL scripts:
```bash
psql -U dw_user -d retail_dw -f sql/ddl/create_tables.sql
psql -U dw_user -d retail_dw -f sql/views/create_views.sql
```

#### MySQL Setup

1. Install MySQL:
```bash
# Ubuntu/Debian
sudo apt-get install mysql-server

# macOS
brew install mysql
```

2. Create database:
```sql
CREATE DATABASE retail_dw;
CREATE USER 'dw_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON retail_dw.* TO 'dw_user'@'localhost';
FLUSH PRIVILEGES;
```

3. Run DDL scripts:
```bash
mysql -u dw_user -p retail_dw < sql/ddl/create_tables.sql
mysql -u dw_user -p retail_dw < sql/views/create_views.sql
```

#### SQLite Setup

SQLite requires no separate installation. The database file will be created automatically.

### 5. Configure Environment Variables

Create a `.env` file in the project root:

```bash
# Database Configuration
DB_TYPE=postgresql  # or mysql, sqlite
DB_HOST=localhost
DB_PORT=5432        # 3306 for MySQL
DB_NAME=retail_dw
DB_USER=dw_user
DB_PASSWORD=your_password
```

### 6. Verify Installation

Run a test script to verify everything is set up correctly:

```python
from src.utils.db_connection import get_connection

with get_connection() as db:
    db.execute_query("SELECT 1")
    print("Database connection successful!")
```

## Running the ETL Pipeline

### Full Pipeline Execution

```python
from src.etl.extract import DataExtractor
from src.etl.transform import DataTransformer
from src.etl.load import DataLoader
from src.utils.db_connection import get_connection

# Extract
extractor = DataExtractor()
df = extractor.extract_from_csv('sales.csv')

# Transform
transformer = DataTransformer()
df = transformer.clean_data(df)
df = transformer.calculate_metrics(df)

# Load
with get_connection() as db:
    loader = DataLoader(db)
    loader.load_fact_table(df, 'fact_sales')
```

### Using Jupyter Notebooks

Launch Jupyter:
```bash
jupyter notebook notebooks/eda_starter.ipynb
```

## Troubleshooting

### Common Issues

1. **Database connection errors**
   - Verify database credentials
   - Check if database server is running
   - Confirm firewall settings allow connections

2. **Module import errors**
   - Ensure virtual environment is activated
   - Verify all dependencies are installed
   - Check Python path includes project root

3. **Permission errors**
   - Verify database user has necessary privileges
   - Check file system permissions for data directories

### Getting Help

- Check the documentation in `docs/`
- Review example notebooks in `notebooks/`
- Open an issue on GitHub for bugs or questions

## Next Steps

1. Review the data model in `sql/ddl/create_tables.sql`
2. Explore analytical views in `sql/views/create_views.sql`
3. Run the EDA notebook to understand the data
4. Customize ETL pipeline for your specific needs

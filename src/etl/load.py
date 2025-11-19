"""
Load Module for ETL Pipeline
=============================
This module handles data loading into the data warehouse.
Supports bulk loading and incremental loading strategies.
"""

import pandas as pd
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DataLoader:
    """
    Data loader class for loading data into the data warehouse.
    
    Attributes:
        db_connection: Database connection object
        batch_size (int): Size of batches for bulk loading
    """
    
    def __init__(self, db_connection, batch_size: int = 1000):
        """
        Initialize DataLoader.
        
        Args:
            db_connection: Database connection object
            batch_size (int): Number of records to load per batch
        """
        self.db_connection = db_connection
        self.batch_size = batch_size
        self.load_log = []
    
    def load_to_table(self, df: pd.DataFrame, 
                     table_name: str,
                     if_exists: str = 'append') -> int:
        """
        Load dataframe to database table.
        
        Args:
            df (pd.DataFrame): Data to load
            table_name (str): Target table name
            if_exists (str): How to behave if table exists ('fail', 'replace', 'append')
            
        Returns:
            int: Number of records loaded
        """
        try:
            logger.info(f"Loading {len(df)} records to {table_name}")
            start_time = datetime.now()
            
            df.to_sql(
                name=table_name,
                con=self.db_connection.connection,
                if_exists=if_exists,
                index=False,
                method='multi',
                chunksize=self.batch_size
            )
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            logger.info(f"Successfully loaded {len(df)} records to {table_name} in {duration:.2f} seconds")
            
            self.load_log.append({
                'table': table_name,
                'records': len(df),
                'duration': duration,
                'timestamp': end_time
            })
            
            return len(df)
            
        except Exception as e:
            logger.error(f"Error loading data to {table_name}: {str(e)}")
            raise
    
    def bulk_insert(self, table_name: str, 
                   columns: List[str],
                   data: List[tuple]) -> int:
        """
        Perform bulk insert using executemany.
        
        Args:
            table_name (str): Target table name
            columns (list): List of column names
            data (list): List of tuples containing row data
            
        Returns:
            int: Number of records loaded
        """
        try:
            logger.info(f"Bulk inserting {len(data)} records to {table_name}")
            start_time = datetime.now()
            
            # Create parameterized insert query
            placeholders = ', '.join(['%s'] * len(columns))
            column_str = ', '.join(columns)
            query = f"INSERT INTO {table_name} ({column_str}) VALUES ({placeholders})"
            
            self.db_connection.execute_many(query, data)
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            logger.info(f"Successfully bulk inserted {len(data)} records in {duration:.2f} seconds")
            
            self.load_log.append({
                'table': table_name,
                'records': len(data),
                'duration': duration,
                'timestamp': end_time,
                'method': 'bulk_insert'
            })
            
            return len(data)
            
        except Exception as e:
            logger.error(f"Error bulk inserting to {table_name}: {str(e)}")
            raise
    
    def upsert_data(self, df: pd.DataFrame,
                   table_name: str,
                   key_columns: List[str]) -> Dict[str, int]:
        """
        Upsert (update if exists, insert if not) data into table.
        
        Args:
            df (pd.DataFrame): Data to upsert
            table_name (str): Target table name
            key_columns (list): Columns to use for matching existing records
            
        Returns:
            dict: Dictionary with counts of inserted and updated records
        """
        logger.info(f"Upserting {len(df)} records to {table_name}")
        
        inserted = 0
        updated = 0
        
        try:
            # This is a simplified implementation
            # In production, use database-specific upsert syntax (e.g., MERGE, INSERT...ON CONFLICT)
            
            for _, row in df.iterrows():
                # Check if record exists
                where_clause = ' AND '.join([f"{col} = '{row[col]}'" for col in key_columns])
                check_query = f"SELECT COUNT(*) FROM {table_name} WHERE {where_clause}"
                
                self.db_connection.execute_query(check_query)
                exists = self.db_connection.cursor.fetchone()[0] > 0
                
                if exists:
                    # Update existing record
                    set_clause = ', '.join([f"{col} = '{row[col]}'" for col in df.columns if col not in key_columns])
                    update_query = f"UPDATE {table_name} SET {set_clause} WHERE {where_clause}"
                    self.db_connection.execute_query(update_query)
                    updated += 1
                else:
                    # Insert new record
                    columns = ', '.join(df.columns)
                    values = ', '.join([f"'{row[col]}'" for col in df.columns])
                    insert_query = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
                    self.db_connection.execute_query(insert_query)
                    inserted += 1
            
            self.db_connection.commit()
            
            logger.info(f"Upsert completed: {inserted} inserted, {updated} updated")
            
            self.load_log.append({
                'table': table_name,
                'inserted': inserted,
                'updated': updated,
                'timestamp': datetime.now(),
                'method': 'upsert'
            })
            
            return {'inserted': inserted, 'updated': updated}
            
        except Exception as e:
            logger.error(f"Error upserting data to {table_name}: {str(e)}")
            self.db_connection.rollback()
            raise
    
    def truncate_and_load(self, df: pd.DataFrame, 
                         table_name: str) -> int:
        """
        Truncate table and load fresh data.
        
        Args:
            df (pd.DataFrame): Data to load
            table_name (str): Target table name
            
        Returns:
            int: Number of records loaded
        """
        try:
            logger.info(f"Truncating table {table_name}")
            self.db_connection.execute_query(f"TRUNCATE TABLE {table_name}")
            self.db_connection.commit()
            
            return self.load_to_table(df, table_name, if_exists='append')
            
        except Exception as e:
            logger.error(f"Error in truncate and load for {table_name}: {str(e)}")
            self.db_connection.rollback()
            raise
    
    def load_dimension_table(self, df: pd.DataFrame,
                           table_name: str,
                           dimension_key: str) -> int:
        """
        Load data into a dimension table with SCD Type 1 (overwrite).
        
        Args:
            df (pd.DataFrame): Dimension data
            table_name (str): Target dimension table name
            dimension_key (str): Primary key column name
            
        Returns:
            int: Number of records loaded
        """
        logger.info(f"Loading dimension table: {table_name}")
        
        try:
            # For dimension tables, we typically want to replace existing data
            return self.load_to_table(df, table_name, if_exists='replace')
            
        except Exception as e:
            logger.error(f"Error loading dimension table {table_name}: {str(e)}")
            raise
    
    def load_fact_table(self, df: pd.DataFrame,
                       table_name: str) -> int:
        """
        Load data into a fact table (append only).
        
        Args:
            df (pd.DataFrame): Fact data
            table_name (str): Target fact table name
            
        Returns:
            int: Number of records loaded
        """
        logger.info(f"Loading fact table: {table_name}")
        
        try:
            # Fact tables are typically append-only
            return self.load_to_table(df, table_name, if_exists='append')
            
        except Exception as e:
            logger.error(f"Error loading fact table {table_name}: {str(e)}")
            raise
    
    def validate_load(self, df: pd.DataFrame, 
                     table_name: str) -> Dict[str, Any]:
        """
        Validate that data was loaded correctly.
        
        Args:
            df (pd.DataFrame): Original dataframe
            table_name (str): Table that was loaded
            
        Returns:
            dict: Validation results
        """
        try:
            logger.info(f"Validating load for {table_name}")
            
            # Count records in table
            count_query = f"SELECT COUNT(*) FROM {table_name}"
            self.db_connection.execute_query(count_query)
            table_count = self.db_connection.cursor.fetchone()[0]
            
            validation_results = {
                'table': table_name,
                'expected_rows': len(df),
                'actual_rows': table_count,
                'validation_passed': table_count >= len(df),
                'timestamp': datetime.now()
            }
            
            if validation_results['validation_passed']:
                logger.info(f"Validation passed for {table_name}")
            else:
                logger.warning(f"Validation failed for {table_name}")
            
            return validation_results
            
        except Exception as e:
            logger.error(f"Error validating load for {table_name}: {str(e)}")
            raise
    
    def get_load_summary(self) -> List[Dict[str, Any]]:
        """
        Get summary of all load operations performed.
        
        Returns:
            list: List of load operations
        """
        return self.load_log


def load_sales_data(df: pd.DataFrame, db_connection, table_name: str = 'fact_sales') -> int:
    """
    Convenience function to load sales data into fact table.
    
    Args:
        df (pd.DataFrame): Sales data
        db_connection: Database connection
        table_name (str): Target table name
        
    Returns:
        int: Number of records loaded
    """
    loader = DataLoader(db_connection)
    return loader.load_fact_table(df, table_name)


if __name__ == "__main__":
    # Example usage
    print("Data Loading Module")
    print("===================")
    print("Usage:")
    print("  from src.etl.load import DataLoader")
    print("  from src.utils.db_connection import get_connection")
    print()
    print("  with get_connection() as db:")
    print("      loader = DataLoader(db)")
    print("      loader.load_fact_table(df, 'fact_sales')")

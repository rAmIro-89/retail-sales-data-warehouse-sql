"""
Extract Module for ETL Pipeline
================================
This module handles data extraction from various sources including:
- CSV files
- Databases
- APIs
- Other data sources
"""

import os
import pandas as pd
import logging
from typing import Optional, List, Dict, Any
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DataExtractor:
    """
    Data extraction class that supports multiple data sources.
    
    Attributes:
        source_type (str): Type of data source ('csv', 'database', 'api')
        source_path (str): Path to data source
    """
    
    def __init__(self, source_type: str = 'csv'):
        """
        Initialize DataExtractor.
        
        Args:
            source_type (str): Type of data source
        """
        self.source_type = source_type
        self.data_dir = Path(__file__).parent.parent.parent / 'data' / 'raw'
        
    def extract_from_csv(self, filename: str, **kwargs) -> pd.DataFrame:
        """
        Extract data from CSV file.
        
        Args:
            filename (str): Name of CSV file
            **kwargs: Additional arguments for pd.read_csv
            
        Returns:
            pd.DataFrame: Extracted data
        """
        try:
            filepath = self.data_dir / filename
            logger.info(f"Extracting data from CSV: {filepath}")
            
            df = pd.read_csv(filepath, **kwargs)
            logger.info(f"Successfully extracted {len(df)} rows from {filename}")
            
            return df
            
        except FileNotFoundError:
            logger.error(f"File not found: {filepath}")
            raise
        except Exception as e:
            logger.error(f"Error extracting from CSV: {str(e)}")
            raise
    
    def extract_from_database(self, query: str, db_connection) -> pd.DataFrame:
        """
        Extract data from database using SQL query.
        
        Args:
            query (str): SQL query to execute
            db_connection: Database connection object
            
        Returns:
            pd.DataFrame: Extracted data
        """
        try:
            logger.info("Extracting data from database")
            
            df = pd.read_sql_query(query, db_connection.connection)
            logger.info(f"Successfully extracted {len(df)} rows from database")
            
            return df
            
        except Exception as e:
            logger.error(f"Error extracting from database: {str(e)}")
            raise
    
    def extract_from_excel(self, filename: str, sheet_name: Optional[str] = None, **kwargs) -> pd.DataFrame:
        """
        Extract data from Excel file.
        
        Args:
            filename (str): Name of Excel file
            sheet_name (str): Name of sheet to extract
            **kwargs: Additional arguments for pd.read_excel
            
        Returns:
            pd.DataFrame: Extracted data
        """
        try:
            filepath = self.data_dir / filename
            logger.info(f"Extracting data from Excel: {filepath}")
            
            df = pd.read_excel(filepath, sheet_name=sheet_name, **kwargs)
            logger.info(f"Successfully extracted {len(df)} rows from {filename}")
            
            return df
            
        except Exception as e:
            logger.error(f"Error extracting from Excel: {str(e)}")
            raise
    
    def extract_from_json(self, filename: str, **kwargs) -> pd.DataFrame:
        """
        Extract data from JSON file.
        
        Args:
            filename (str): Name of JSON file
            **kwargs: Additional arguments for pd.read_json
            
        Returns:
            pd.DataFrame: Extracted data
        """
        try:
            filepath = self.data_dir / filename
            logger.info(f"Extracting data from JSON: {filepath}")
            
            df = pd.read_json(filepath, **kwargs)
            logger.info(f"Successfully extracted {len(df)} rows from {filename}")
            
            return df
            
        except Exception as e:
            logger.error(f"Error extracting from JSON: {str(e)}")
            raise
    
    def extract_multiple_csvs(self, pattern: str = "*.csv") -> pd.DataFrame:
        """
        Extract and combine multiple CSV files matching a pattern.
        
        Args:
            pattern (str): File pattern to match
            
        Returns:
            pd.DataFrame: Combined data from all matching files
        """
        try:
            files = list(self.data_dir.glob(pattern))
            
            if not files:
                logger.warning(f"No files found matching pattern: {pattern}")
                return pd.DataFrame()
            
            logger.info(f"Found {len(files)} files matching pattern: {pattern}")
            
            dfs = []
            for file in files:
                df = pd.read_csv(file)
                dfs.append(df)
                logger.info(f"Extracted {len(df)} rows from {file.name}")
            
            combined_df = pd.concat(dfs, ignore_index=True)
            logger.info(f"Successfully combined {len(combined_df)} total rows")
            
            return combined_df
            
        except Exception as e:
            logger.error(f"Error extracting multiple CSVs: {str(e)}")
            raise
    
    def validate_extracted_data(self, df: pd.DataFrame) -> Dict[str, Any]:
        """
        Validate extracted data and return summary statistics.
        
        Args:
            df (pd.DataFrame): DataFrame to validate
            
        Returns:
            dict: Validation summary
        """
        validation_summary = {
            'row_count': len(df),
            'column_count': len(df.columns),
            'columns': df.columns.tolist(),
            'null_counts': df.isnull().sum().to_dict(),
            'dtypes': df.dtypes.astype(str).to_dict(),
            'memory_usage': df.memory_usage(deep=True).sum() / 1024**2,  # MB
        }
        
        logger.info("Data validation summary:")
        logger.info(f"  Rows: {validation_summary['row_count']}")
        logger.info(f"  Columns: {validation_summary['column_count']}")
        logger.info(f"  Memory usage: {validation_summary['memory_usage']:.2f} MB")
        
        return validation_summary


def extract_sales_data(source_file: str = "sales.csv") -> pd.DataFrame:
    """
    Convenience function to extract sales data.
    
    Args:
        source_file (str): Name of source file
        
    Returns:
        pd.DataFrame: Extracted sales data
    """
    extractor = DataExtractor()
    return extractor.extract_from_csv(source_file)


if __name__ == "__main__":
    # Example usage
    print("Data Extraction Module")
    print("======================")
    print("Usage:")
    print("  from src.etl.extract import DataExtractor")
    print()
    print("  extractor = DataExtractor()")
    print("  df = extractor.extract_from_csv('sales.csv')")
    print("  validation = extractor.validate_extracted_data(df)")

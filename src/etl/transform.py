"""
Transform Module for ETL Pipeline
==================================
This module handles data transformation including:
- Data cleaning
- Data validation
- Data type conversion
- Business logic application
- Aggregations
"""

import pandas as pd
import numpy as np
import logging
from typing import Optional, List, Dict, Any, Callable
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DataTransformer:
    """
    Data transformation class for ETL pipeline.
    
    Handles various data cleaning and transformation operations.
    """
    
    def __init__(self):
        """Initialize DataTransformer."""
        self.transformation_log = []
    
    def clean_data(self, df: pd.DataFrame, 
                   drop_duplicates: bool = True,
                   handle_missing: str = 'drop') -> pd.DataFrame:
        """
        Clean data by handling duplicates and missing values.
        
        Args:
            df (pd.DataFrame): Input dataframe
            drop_duplicates (bool): Whether to drop duplicate rows
            handle_missing (str): How to handle missing values ('drop', 'fill_zero', 'fill_mean')
            
        Returns:
            pd.DataFrame: Cleaned dataframe
        """
        logger.info("Starting data cleaning process")
        initial_rows = len(df)
        
        # Handle duplicates
        if drop_duplicates:
            df = df.drop_duplicates()
            logger.info(f"Removed {initial_rows - len(df)} duplicate rows")
        
        # Handle missing values
        if handle_missing == 'drop':
            df = df.dropna()
            logger.info(f"Dropped rows with missing values. Remaining rows: {len(df)}")
        elif handle_missing == 'fill_zero':
            df = df.fillna(0)
            logger.info("Filled missing values with 0")
        elif handle_missing == 'fill_mean':
            numeric_cols = df.select_dtypes(include=[np.number]).columns
            df[numeric_cols] = df[numeric_cols].fillna(df[numeric_cols].mean())
            logger.info("Filled numeric missing values with column means")
        
        self.transformation_log.append({
            'operation': 'clean_data',
            'rows_before': initial_rows,
            'rows_after': len(df),
            'timestamp': datetime.now()
        })
        
        return df
    
    def standardize_column_names(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Standardize column names (lowercase, replace spaces with underscores).
        
        Args:
            df (pd.DataFrame): Input dataframe
            
        Returns:
            pd.DataFrame: Dataframe with standardized column names
        """
        logger.info("Standardizing column names")
        
        df.columns = df.columns.str.lower().str.replace(' ', '_').str.replace('-', '_')
        logger.info(f"Columns standardized: {list(df.columns)}")
        
        self.transformation_log.append({
            'operation': 'standardize_columns',
            'timestamp': datetime.now()
        })
        
        return df
    
    def convert_data_types(self, df: pd.DataFrame, 
                          type_mapping: Dict[str, str]) -> pd.DataFrame:
        """
        Convert column data types.
        
        Args:
            df (pd.DataFrame): Input dataframe
            type_mapping (dict): Dictionary mapping column names to target types
            
        Returns:
            pd.DataFrame: Dataframe with converted types
        """
        logger.info("Converting data types")
        
        for col, dtype in type_mapping.items():
            if col in df.columns:
                try:
                    if dtype == 'datetime':
                        df[col] = pd.to_datetime(df[col])
                    else:
                        df[col] = df[col].astype(dtype)
                    logger.info(f"Converted {col} to {dtype}")
                except Exception as e:
                    logger.error(f"Failed to convert {col} to {dtype}: {str(e)}")
        
        self.transformation_log.append({
            'operation': 'convert_types',
            'columns': list(type_mapping.keys()),
            'timestamp': datetime.now()
        })
        
        return df
    
    def create_date_dimensions(self, df: pd.DataFrame, 
                              date_column: str) -> pd.DataFrame:
        """
        Create date dimension columns from a date column.
        
        Args:
            df (pd.DataFrame): Input dataframe
            date_column (str): Name of date column
            
        Returns:
            pd.DataFrame: Dataframe with additional date dimension columns
        """
        logger.info(f"Creating date dimensions from {date_column}")
        
        if date_column not in df.columns:
            logger.error(f"Column {date_column} not found in dataframe")
            return df
        
        # Ensure datetime type
        df[date_column] = pd.to_datetime(df[date_column])
        
        # Create dimension columns
        df[f'{date_column}_year'] = df[date_column].dt.year
        df[f'{date_column}_quarter'] = df[date_column].dt.quarter
        df[f'{date_column}_month'] = df[date_column].dt.month
        df[f'{date_column}_month_name'] = df[date_column].dt.month_name()
        df[f'{date_column}_week'] = df[date_column].dt.isocalendar().week
        df[f'{date_column}_day'] = df[date_column].dt.day
        df[f'{date_column}_day_of_week'] = df[date_column].dt.dayofweek
        df[f'{date_column}_day_name'] = df[date_column].dt.day_name()
        df[f'{date_column}_is_weekend'] = df[date_column].dt.dayofweek.isin([5, 6])
        
        logger.info("Date dimensions created successfully")
        
        self.transformation_log.append({
            'operation': 'create_date_dimensions',
            'date_column': date_column,
            'timestamp': datetime.now()
        })
        
        return df
    
    def calculate_metrics(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate derived metrics for sales data.
        
        Args:
            df (pd.DataFrame): Input dataframe
            
        Returns:
            pd.DataFrame: Dataframe with calculated metrics
        """
        logger.info("Calculating derived metrics")
        
        # Example calculations (adjust based on your schema)
        if 'quantity' in df.columns and 'unit_price' in df.columns:
            df['subtotal'] = df['quantity'] * df['unit_price']
            logger.info("Calculated subtotal")
        
        if 'subtotal' in df.columns and 'discount_amount' in df.columns:
            df['net_amount'] = df['subtotal'] - df['discount_amount']
            logger.info("Calculated net_amount")
        
        if 'quantity' in df.columns and 'unit_price' in df.columns and 'cost' in df.columns:
            df['profit'] = (df['unit_price'] - df['cost']) * df['quantity']
            logger.info("Calculated profit")
        
        self.transformation_log.append({
            'operation': 'calculate_metrics',
            'timestamp': datetime.now()
        })
        
        return df
    
    def apply_business_rules(self, df: pd.DataFrame,
                            rules: List[Dict[str, Any]]) -> pd.DataFrame:
        """
        Apply business rules to filter or transform data.
        
        Args:
            df (pd.DataFrame): Input dataframe
            rules (list): List of rule dictionaries
            
        Returns:
            pd.DataFrame: Dataframe with rules applied
        """
        logger.info("Applying business rules")
        
        for rule in rules:
            rule_type = rule.get('type')
            column = rule.get('column')
            
            if rule_type == 'filter':
                condition = rule.get('condition')
                df = df.query(condition)
                logger.info(f"Applied filter: {condition}")
            
            elif rule_type == 'transform':
                func = rule.get('function')
                df[column] = df[column].apply(func)
                logger.info(f"Applied transformation to {column}")
        
        self.transformation_log.append({
            'operation': 'apply_business_rules',
            'rules_count': len(rules),
            'timestamp': datetime.now()
        })
        
        return df
    
    def validate_ranges(self, df: pd.DataFrame,
                       validations: Dict[str, Dict[str, Any]]) -> pd.DataFrame:
        """
        Validate that numeric columns are within expected ranges.
        
        Args:
            df (pd.DataFrame): Input dataframe
            validations (dict): Dictionary with column names and min/max values
            
        Returns:
            pd.DataFrame: Validated dataframe
        """
        logger.info("Validating data ranges")
        initial_rows = len(df)
        
        for col, rules in validations.items():
            if col in df.columns:
                min_val = rules.get('min')
                max_val = rules.get('max')
                
                if min_val is not None:
                    df = df[df[col] >= min_val]
                if max_val is not None:
                    df = df[df[col] <= max_val]
                
                logger.info(f"Validated {col}: min={min_val}, max={max_val}")
        
        rows_removed = initial_rows - len(df)
        if rows_removed > 0:
            logger.warning(f"Removed {rows_removed} rows due to range validation")
        
        self.transformation_log.append({
            'operation': 'validate_ranges',
            'rows_removed': rows_removed,
            'timestamp': datetime.now()
        })
        
        return df
    
    def get_transformation_summary(self) -> List[Dict[str, Any]]:
        """
        Get summary of all transformations performed.
        
        Returns:
            list: List of transformation operations
        """
        return self.transformation_log


def transform_sales_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convenience function to apply standard sales data transformations.
    
    Args:
        df (pd.DataFrame): Raw sales data
        
    Returns:
        pd.DataFrame: Transformed sales data
    """
    transformer = DataTransformer()
    
    # Standard transformation pipeline
    df = transformer.standardize_column_names(df)
    df = transformer.clean_data(df)
    
    return df


if __name__ == "__main__":
    # Example usage
    print("Data Transformation Module")
    print("===========================")
    print("Usage:")
    print("  from src.etl.transform import DataTransformer")
    print()
    print("  transformer = DataTransformer()")
    print("  df_clean = transformer.clean_data(df)")
    print("  df_transformed = transformer.calculate_metrics(df_clean)")

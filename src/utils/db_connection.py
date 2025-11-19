"""
Database Connection Utility Module
===================================
This module provides database connection management for the ETL pipeline.
Supports PostgreSQL, MySQL, and SQLite databases.
"""

import os
from typing import Optional, Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseConnection:
    """
    Database connection manager that supports multiple database types.
    
    Attributes:
        db_type (str): Type of database ('postgresql', 'mysql', 'sqlite')
        connection: Database connection object
        cursor: Database cursor object
    """
    
    def __init__(self, db_type: str = 'postgresql', config: Optional[Dict[str, Any]] = None):
        """
        Initialize database connection.
        
        Args:
            db_type (str): Database type ('postgresql', 'mysql', 'sqlite')
            config (dict): Database configuration dictionary
        """
        self.db_type = db_type.lower()
        self.config = config or self._load_config_from_env()
        self.connection = None
        self.cursor = None
        
    def _load_config_from_env(self) -> Dict[str, Any]:
        """Load database configuration from environment variables."""
        return {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': os.getenv('DB_PORT', '5432'),
            'database': os.getenv('DB_NAME', 'retail_dw'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', ''),
        }
    
    def connect(self):
        """Establish database connection based on db_type."""
        try:
            if self.db_type == 'postgresql':
                self._connect_postgresql()
            elif self.db_type == 'mysql':
                self._connect_mysql()
            elif self.db_type == 'sqlite':
                self._connect_sqlite()
            else:
                raise ValueError(f"Unsupported database type: {self.db_type}")
            
            logger.info(f"Successfully connected to {self.db_type} database")
            
        except Exception as e:
            logger.error(f"Failed to connect to database: {str(e)}")
            raise
    
    def _connect_postgresql(self):
        """Connect to PostgreSQL database."""
        try:
            import psycopg2
            self.connection = psycopg2.connect(
                host=self.config['host'],
                port=self.config['port'],
                database=self.config['database'],
                user=self.config['user'],
                password=self.config['password']
            )
            self.cursor = self.connection.cursor()
        except ImportError:
            logger.error("psycopg2 not installed. Install with: pip install psycopg2-binary")
            raise
    
    def _connect_mysql(self):
        """Connect to MySQL database."""
        try:
            import mysql.connector
            self.connection = mysql.connector.connect(
                host=self.config['host'],
                port=self.config['port'],
                database=self.config['database'],
                user=self.config['user'],
                password=self.config['password']
            )
            self.cursor = self.connection.cursor()
        except ImportError:
            logger.error("mysql-connector-python not installed. Install with: pip install mysql-connector-python")
            raise
    
    def _connect_sqlite(self):
        """Connect to SQLite database."""
        try:
            import sqlite3
            db_path = self.config.get('database', 'retail_dw.db')
            self.connection = sqlite3.connect(db_path)
            self.cursor = self.connection.cursor()
        except Exception as e:
            logger.error(f"Failed to connect to SQLite: {str(e)}")
            raise
    
    def execute_query(self, query: str, params: Optional[tuple] = None):
        """
        Execute a SQL query.
        
        Args:
            query (str): SQL query to execute
            params (tuple): Query parameters for parameterized queries
            
        Returns:
            Cursor object with query results
        """
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            return self.cursor
        except Exception as e:
            logger.error(f"Query execution failed: {str(e)}")
            raise
    
    def execute_many(self, query: str, data: list):
        """
        Execute a query with multiple parameter sets.
        
        Args:
            query (str): SQL query to execute
            data (list): List of parameter tuples
        """
        try:
            self.cursor.executemany(query, data)
            self.connection.commit()
            logger.info(f"Successfully executed batch insert of {len(data)} records")
        except Exception as e:
            logger.error(f"Batch execution failed: {str(e)}")
            self.connection.rollback()
            raise
    
    def commit(self):
        """Commit the current transaction."""
        if self.connection:
            self.connection.commit()
            logger.info("Transaction committed successfully")
    
    def rollback(self):
        """Rollback the current transaction."""
        if self.connection:
            self.connection.rollback()
            logger.warning("Transaction rolled back")
    
    def close(self):
        """Close database connection and cursor."""
        try:
            if self.cursor:
                self.cursor.close()
            if self.connection:
                self.connection.close()
            logger.info("Database connection closed")
        except Exception as e:
            logger.error(f"Error closing connection: {str(e)}")
    
    def __enter__(self):
        """Context manager entry."""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self.close()


def get_connection(db_type: str = 'postgresql', config: Optional[Dict[str, Any]] = None) -> DatabaseConnection:
    """
    Factory function to create a database connection.
    
    Args:
        db_type (str): Database type ('postgresql', 'mysql', 'sqlite')
        config (dict): Database configuration dictionary
        
    Returns:
        DatabaseConnection: Configured database connection object
    """
    return DatabaseConnection(db_type=db_type, config=config)


if __name__ == "__main__":
    # Example usage
    print("Database Connection Utility")
    print("===========================")
    print("Usage:")
    print("  from src.utils.db_connection import get_connection")
    print()
    print("  # Using context manager")
    print("  with get_connection('postgresql') as db:")
    print("      db.execute_query('SELECT * FROM dim_customer LIMIT 10')")
    print("      results = db.cursor.fetchall()")

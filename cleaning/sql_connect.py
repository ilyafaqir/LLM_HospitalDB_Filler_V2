import mysql.connector
from mysql.connector import Error
import re
import time

def clean_sql_statement(statement):
    """Remove comments and clean up SQL statement"""
    # Remove single-line comments
    lines = statement.split('\n')
    cleaned_lines = []
    for line in lines:
        # Remove comments but keep the rest of the line
        if '--' in line:
            line = line[:line.index('--')]
        if line.strip():
            cleaned_lines.append(line)
    return '\n'.join(cleaned_lines).strip()

def is_select_statement(statement):
    """Check if statement is a SELECT query"""
    stmt_upper = statement.strip().upper()
    return stmt_upper.startswith('SELECT')

def execute_sql_file(connection, sql_file_path):
    """Execute SQL statements from a file"""
    try:
        # Read the SQL file
        print(f"Reading SQL file: {sql_file_path}")
        with open(sql_file_path, 'r', encoding='utf-8') as file:
            sql_content = file.read()
        
        print(f"File size: {len(sql_content)} characters\n")
        
        # Split by semicolons (but be careful with semicolons in strings)
        statements = []
        current_statement = []
        in_string = False
        
        for char in sql_content:
            if char == "'" and (not current_statement or current_statement[-1] != '\\'):
                in_string = not in_string
            
            current_statement.append(char)
            
            if char == ';' and not in_string:
                stmt = ''.join(current_statement)
                statements.append(stmt)
                current_statement = []
        
        # Add any remaining content
        if current_statement:
            stmt = ''.join(current_statement)
            if stmt.strip():
                statements.append(stmt)
        
        print(f"Found {len(statements)} SQL statements\n")
        
        executed_count = 0
        error_count = 0
        skipped_count = 0
        
        for i, statement in enumerate(statements, 1):
            # Clean the statement
            cleaned = clean_sql_statement(statement)
            
            # Skip empty statements
            if not cleaned:
                continue
            
            # Show preview of statement
            preview = cleaned.replace('\n', ' ')[:150]
            print(f"\n[{i}/{len(statements)}] Executing: {preview}...")
            
            # Check if it's a SELECT statement
            if is_select_statement(cleaned):
                print(f"    ⊘ SKIPPED - SELECT statements are not executed (use for verification only)")
                skipped_count += 1
                continue
            
            cursor = None
            try:
                # Create a new cursor for each statement
                cursor = connection.cursor(buffered=True)
                
                # Execute the statement
                cursor.execute(cleaned)
                
                # Consume any results immediately
                try:
                    cursor.fetchall()
                except:
                    pass
                
                connection.commit()
                
                rows_affected = cursor.rowcount
                print(f"    ✓ SUCCESS - Rows affected: {rows_affected}")
                executed_count += 1
                
            except Error as e:
                error_msg = str(e)
                
                # Special handling for "column doesn't exist" errors (not critical)
                if "Can't DROP COLUMN" in error_msg or "check that it exists" in error_msg:
                    print(f"    ⚠ WARNING: {e} (Column may have been dropped already)")
                else:
                    print(f"    ✗ ERROR: {e}")
                    print(f"    Statement preview: {cleaned[:300]}")
                
                # If "Commands out of sync" error, try to reset connection
                if "Commands out of sync" in error_msg or "2014" in error_msg:
                    print(f"    🔄 Attempting to reset connection...")
                    try:
                        if cursor:
                            cursor.close()
                        connection.rollback()
                        # Small delay to let connection settle
                        time.sleep(0.5)
                    except:
                        pass
                else:
                    try:
                        connection.rollback()
                    except:
                        pass
                error_count += 1
                
            finally:
                # Always close cursor in finally block
                if cursor:
                    try:
                        cursor.close()
                    except:
                        pass
                    # Small delay between statements to prevent sync issues
                    time.sleep(0.1)
        
        print("\n" + "="*60)
        print(f"SUMMARY:")
        print(f"  • Total statements: {len(statements)}")
        print(f"  • Successfully executed: {executed_count}")
        print(f"  • Skipped (SELECT): {skipped_count}")
        print(f"  • Errors/Warnings: {error_count}")
        print("="*60)
        
    except FileNotFoundError:
        print(f"✗ ERROR: SQL file not found: {sql_file_path}")
    except Exception as e:
        print(f"✗ ERROR: {e}")

def verify_changes(connection):
    """Verify that changes were made"""
    print("\n" + "="*60)
    print("VERIFICATION:")
    print("="*60)
    
    cursor = None
    try:
        # Reconnect if needed
        if not connection.is_connected():
            print("⚠ Reconnecting to database...")
            connection.reconnect()
        
        cursor = connection.cursor(buffered=True)
        
        # Check suppliers table
        cursor.execute("SELECT COUNT(*) FROM suppliers WHERE name = UPPER(name)")
        result = cursor.fetchone()
        print(f"✓ Suppliers with uppercase names: {result[0]}")
        
        cursor.execute("SELECT COUNT(*) FROM suppliers WHERE city IS NOT NULL AND city != ''")
        result = cursor.fetchone()
        print(f"✓ Suppliers with city filled: {result[0]}")
        
        # Check places table
        cursor.execute("SELECT COUNT(*) FROM places WHERE city = UPPER(city)")
        result = cursor.fetchone()
        print(f"✓ Places with uppercase cities: {result[0]}")
        
        cursor.execute("SELECT COUNT(*) FROM places WHERE region IS NOT NULL")
        result = cursor.fetchone()
        print(f"✓ Places with region filled: {result[0]}")
        
        cursor.execute("SELECT COUNT(*) FROM places WHERE region IS NULL OR province IS NULL")
        result = cursor.fetchone()
        print(f"⚠ Places missing region/province: {result[0]}")
        
    except Error as e:
        print(f"✗ Verification error: {e}")
    finally:
        if cursor:
            try:
                cursor.close()
            except:
                pass

def main():
    """Main function to connect to database and run cleaning script"""
    
    # Database configuration
    config = {
        'host': 'localhost',
        'database': 'morocco_health_db',
        'user': 'root',
        'password': '',
        'autocommit': False,
        'consume_results': True  # Automatically consume results
    }
    
    SQL_FILE_PATH = 'cleaning/cleaning.sql'
    
    connection = None
    
    try:
        # Connect to database
        print("="*60)
        print("CONNECTING TO DATABASE")
        print("="*60)
        connection = mysql.connector.connect(**config)
        
        if connection.is_connected():
            db_info = connection.get_server_info()
            print(f"✓ Connected to MySQL Server version {db_info}")
            
            cursor = connection.cursor()
            cursor.execute("SELECT DATABASE();")
            database_name = cursor.fetchone()
            print(f"✓ Using database: {database_name[0]}")
            cursor.close()
            
            # Execute the SQL file
            print("\n" + "="*60)
            print("EXECUTING SQL STATEMENTS")
            print("="*60)
            execute_sql_file(connection, SQL_FILE_PATH)
            
            # Verify changes
            verify_changes(connection)
            
    except Error as e:
        print(f"\n✗ ERROR connecting to MySQL: {e}")
        print("\nPlease check:")
        print("  1. MySQL server is running")
        print("  2. Database credentials are correct")
        print("  3. Database name exists")
        print("  4. User has proper permissions")
        
    finally:
        if connection and connection.is_connected():
            connection.close()
            print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()
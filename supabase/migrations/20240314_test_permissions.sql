-- First, let's check if we can create a simple table without any constraints
DROP TABLE IF EXISTS test_table;

CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT
);

-- Insert a test row
INSERT INTO test_table (name) VALUES ('test');

-- Enable RLS but allow everything
ALTER TABLE test_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on test_table" ON test_table FOR ALL USING (true);

-- Grant permissions
GRANT ALL ON test_table TO postgres;
GRANT ALL ON test_table TO authenticated;
GRANT ALL ON test_table TO anon;
GRANT ALL ON test_table TO service_role;

-- Create a simple test function
CREATE OR REPLACE FUNCTION test_insert()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO test_table (name) VALUES ('from_function');
    RETURN 1;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION test_insert() TO postgres;
GRANT EXECUTE ON FUNCTION test_insert() TO authenticated;
GRANT EXECUTE ON FUNCTION test_insert() TO anon;
GRANT EXECUTE ON FUNCTION test_insert() TO service_role; 
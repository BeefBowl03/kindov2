-- Drop everything first
DROP TABLE IF EXISTS profiles;

-- Create just the profiles table without any foreign key constraint
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS with a completely open policy
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on profiles" ON profiles FOR ALL USING (true);

-- Grant necessary permissions
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON profiles TO service_role;

-- Test function that just creates a profile
CREATE OR REPLACE FUNCTION test_create_profile(
    user_id UUID,
    user_name TEXT,
    user_email TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO profiles (id, name, email)
    VALUES (user_id, user_name, user_email)
    RETURNING id;
    RETURN user_id;
END;
$$; 
-- First, drop everything to start clean
DROP TABLE IF EXISTS shopping_items;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS family_members;
DROP TABLE IF EXISTS pending_invitations;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS families;

-- Drop any existing functions
DROP FUNCTION IF EXISTS create_user_profile;
DROP FUNCTION IF EXISTS update_updated_at_column;

-- Create the basic tables first without foreign keys
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY,  -- Changed to just UUID without the foreign key initially
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS but with completely open policies
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all on families" ON families FOR ALL USING (true);
CREATE POLICY "Allow all on profiles" ON profiles FOR ALL USING (true);

-- Test function for creating a profile
CREATE OR REPLACE FUNCTION create_test_profile(
    user_id UUID,
    user_name TEXT,
    user_email TEXT,
    is_parent BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO profiles (id, name, email, is_parent)
    VALUES (user_id, user_name, user_email, is_parent);
END;
$$;

-- Now add the foreign key reference to auth.users
DO $$
BEGIN
    -- Add the foreign key constraint to profiles
    ALTER TABLE profiles
    ADD CONSTRAINT profiles_id_fkey
    FOREIGN KEY (id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error adding foreign key constraint: %', SQLERRM;
END;
$$; 
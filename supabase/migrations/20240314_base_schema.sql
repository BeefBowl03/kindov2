-- Drop existing tables if they exist
DROP TABLE IF EXISTS shopping_items;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS family_members;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS families;
DROP TABLE IF EXISTS pending_invitations;

-- Create families table
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    avatar_url TEXT,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create family_members junction table
CREATE TABLE family_members (
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (family_id, user_id)
);

-- Create pending_invitations table
CREATE TABLE pending_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (CURRENT_TIMESTAMP + interval '24 hours'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create tasks table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    points INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create shopping_items table
CREATE TABLE shopping_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    is_purchased BOOLEAN DEFAULT false,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    purchased_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_invitations ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Allow all on profiles" ON profiles FOR ALL USING (true);

-- Policies for families
CREATE POLICY "Allow all on families" ON families FOR ALL USING (true);

-- Policies for family_members
CREATE POLICY "Allow all on family_members" ON family_members FOR ALL USING (true);

-- Policy for pending_invitations
CREATE POLICY "Allow all on pending_invitations" ON pending_invitations FOR ALL USING (true);

-- Policy for tasks
CREATE POLICY "Allow all on tasks" ON tasks FOR ALL USING (true);

-- Policy for shopping_items
CREATE POLICY "Allow all on shopping_items" ON shopping_items FOR ALL USING (true);

-- Create stored procedure for user profile creation
CREATE OR REPLACE FUNCTION create_user_profile(
    user_id UUID,
    user_name TEXT,
    user_email TEXT,
    is_parent BOOLEAN,
    family_name TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_family_id UUID;
BEGIN
    -- Create the user profile
    INSERT INTO profiles (id, name, email, is_parent)
    VALUES (user_id, user_name, user_email, is_parent);

    -- If family_name is provided, create a new family
    IF family_name IS NOT NULL THEN
        INSERT INTO families (name, created_by)
        VALUES (family_name, user_id)
        RETURNING id INTO new_family_id;

        -- Add the user as a family member
        INSERT INTO family_members (family_id, user_id)
        VALUES (new_family_id, user_id);
    END IF;
END;
$$; 
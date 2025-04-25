-- First, drop the trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Then clean up any existing objects
DROP TABLE IF EXISTS profiles CASCADE;
DROP FUNCTION IF EXISTS create_test_profile(UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS create_user_profile(UUID, TEXT, TEXT, BOOLEAN, TEXT) CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create profiles table without foreign key first
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    is_parent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS with open policy
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on profiles" ON profiles FOR ALL USING (true);

-- Grant permissions
GRANT ALL ON profiles TO postgres;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON profiles TO anon;
GRANT ALL ON profiles TO service_role;

-- Create trigger function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the user data for debugging
  RAISE LOG 'New user created: %', NEW;
  
  -- Check if profile already exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.id) THEN
    -- Create profile using the create_user_profile function
    PERFORM create_user_profile(
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
      NEW.email,
      COALESCE((NEW.raw_user_meta_data->>'is_parent')::boolean, false),
      COALESCE(NEW.raw_user_meta_data->>'family_name', 'My Family')
    );
  END IF;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any errors that occur
  RAISE LOG 'Error in handle_new_user: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Test function with explicit parameter types
CREATE OR REPLACE FUNCTION create_test_profile(
    p_user_id UUID,
    p_user_name TEXT,
    p_user_email TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    -- Log the attempt
    RAISE NOTICE 'Attempting to create profile: id=%, name=%, email=%', 
                 p_user_id, p_user_name, p_user_email;
                 
    INSERT INTO profiles (id, name, email)
    VALUES (p_user_id, p_user_name, p_user_email)
    RETURNING id INTO v_id;
    
    RAISE NOTICE 'Profile created successfully with id: %', v_id;
    RETURN v_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating profile: %', SQLERRM;
        RAISE;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_test_profile(UUID, TEXT, TEXT) TO postgres;
GRANT EXECUTE ON FUNCTION create_test_profile(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_test_profile(UUID, TEXT, TEXT) TO service_role;

-- Insert a test profile
DO $$
DECLARE
    v_result UUID;
BEGIN
    SELECT create_test_profile(
        '11111111-1111-1111-1111-111111111111'::UUID,
        'Test User',
        'test@example.com'
    ) INTO v_result;
    
    RAISE NOTICE 'Test profile created with id: %', v_result;
END;
$$;

-- Verify the function exists
DO $$
BEGIN
    RAISE NOTICE 'Checking if function exists...';
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'create_test_profile' 
        AND pronargs = 3
    ) THEN
        RAISE NOTICE 'Function create_test_profile exists';
    ELSE
        RAISE NOTICE 'Function create_test_profile does not exist';
    END IF;
END;
$$; 
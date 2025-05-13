-- Create the stored procedure for creating a user profile with family
CREATE OR REPLACE FUNCTION create_user_profile(
  user_id UUID,
  user_name TEXT,
  user_email TEXT,
  is_parent BOOLEAN,
  family_name TEXT
) RETURNS void AS $$
DECLARE
  new_family_id UUID;
BEGIN
  -- Start transaction
  BEGIN
    -- Create profile first
    INSERT INTO profiles (id, name, email, is_parent, points, created_at, updated_at)
    VALUES (
      user_id,
      user_name,
      user_email,
      is_parent,
      0,
      NOW(),
      NOW()
    );

    -- If family_name is provided, create a new family
    IF family_name IS NOT NULL AND family_name != '' THEN
      -- Create family
      INSERT INTO families (name, created_by, created_at, updated_at)
      VALUES (family_name, user_id, NOW(), NOW())
      RETURNING id INTO new_family_id;

      -- Add user as family member
      INSERT INTO family_members (family_id, user_id, created_at)
      VALUES (new_family_id, user_id, NOW());
    END IF;

    -- If we get here, commit the transaction
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
    -- If any error occurs, roll back the transaction
    ROLLBACK;
    RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 
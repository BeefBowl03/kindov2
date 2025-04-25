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

-- Create index for pending invitations
CREATE INDEX idx_pending_invitations_email ON pending_invitations(email);
CREATE INDEX idx_pending_invitations_family_id ON pending_invitations(family_id);

-- Enable RLS for pending_invitations
ALTER TABLE pending_invitations ENABLE ROW LEVEL SECURITY;

-- Create policies for pending_invitations
CREATE POLICY "Parents can manage pending invitations" ON pending_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM family_members
            JOIN profiles ON profiles.id = family_members.user_id
            WHERE family_members.family_id = pending_invitations.family_id
            AND profiles.id = auth.uid()
            AND profiles.is_parent = true
        )
    );

-- Create trigger for pending_invitations updated_at
CREATE TRIGGER update_pending_invitations_updated_at
    BEFORE UPDATE ON pending_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create stored procedure for creating user profile
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
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Parents can manage family members" ON family_members;
DROP POLICY IF EXISTS "Users can view their family members" ON family_members;

-- Updated policies for family_members
CREATE POLICY "Anyone can insert into family_members" ON family_members
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their family members" ON family_members
    FOR SELECT USING (
        user_id = auth.uid() OR
        family_id IN (
            SELECT family_id FROM family_members WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Parents can delete family members" ON family_members
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND is_parent = true
            AND EXISTS (
                SELECT 1 FROM family_members fm
                WHERE fm.family_id = family_members.family_id
                AND fm.user_id = auth.uid()
            )
        )
    );

-- Function to check if user is parent in family
CREATE OR REPLACE FUNCTION is_parent_in_family(family_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles p
        JOIN family_members fm ON fm.user_id = p.id
        WHERE p.id = auth.uid()
        AND p.is_parent = true
        AND fm.family_id = $1
    );
END;
$$;

-- Function to expire old invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE pending_invitations
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at < CURRENT_TIMESTAMP;
END;
$$; 
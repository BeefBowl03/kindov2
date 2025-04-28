-- Add temp_password column to pending_invitations if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pending_invitations' 
        AND column_name = 'temp_password'
    ) THEN
        ALTER TABLE pending_invitations 
        ADD COLUMN temp_password TEXT;
    END IF;
END $$; 
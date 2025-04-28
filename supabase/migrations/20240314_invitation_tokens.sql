-- Create invitation_tokens table
CREATE TABLE invitation_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invitation_id UUID REFERENCES pending_invitations(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMP WITH TIME ZONE
);

-- Create index for faster lookups
CREATE INDEX idx_invitation_tokens_token ON invitation_tokens(token);
CREATE INDEX idx_invitation_tokens_invitation_id ON invitation_tokens(invitation_id);

-- Enable RLS
ALTER TABLE invitation_tokens ENABLE ROW LEVEL SECURITY;

-- Create policy to allow service role to manage tokens
CREATE POLICY "Service role can manage invitation tokens" ON invitation_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- Function to generate invitation token
CREATE OR REPLACE FUNCTION generate_invitation_token(invitation_id UUID, email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
BEGIN
    -- Generate a random token
    v_token := encode(gen_random_bytes(32), 'base64');
    
    -- Insert the token
    INSERT INTO invitation_tokens (
        invitation_id,
        token,
        expires_at
    ) VALUES (
        invitation_id,
        v_token,
        CURRENT_TIMESTAMP + interval '7 days'
    );
    
    RETURN v_token;
END;
$$;

-- Function to verify invitation token
CREATE OR REPLACE FUNCTION verify_invitation_token(token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invitation_id UUID;
BEGIN
    -- Get the invitation ID and check if token is valid
    SELECT invitation_id INTO v_invitation_id
    FROM invitation_tokens
    WHERE token = $1
    AND expires_at > CURRENT_TIMESTAMP
    AND used_at IS NULL;
    
    IF v_invitation_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired token';
    END IF;
    
    -- Mark token as used
    UPDATE invitation_tokens
    SET used_at = CURRENT_TIMESTAMP
    WHERE token = $1;
    
    RETURN v_invitation_id;
END;
$$; 
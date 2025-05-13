// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Declare Deno types
declare global {
  interface Window {
    Deno: {
      env: {
        get(key: string): string | undefined;
      };
    }
  }
}

const Deno = window.Deno;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InviteUserPayload {
  email: string;
  name: string;
  isParent: boolean;
  familyId: string;
}

// Function to generate a random password of specified length
function generateRandomPassword(length = 16) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+';
  let password = '';
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    password += charset[randomIndex];
  }
  return password;
}

serve(async (req: Request) => {
  console.log('Invite user function called');
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestData = await req.json();
    const email = requestData.email;
    const name = requestData.name || 'New User'; // Default name if missing
    const isParent = requestData.isParent !== undefined ? requestData.isParent : true; // Default to parent if missing
    const familyId = requestData.familyId; // This one is critical, so no default
    
    console.log(`Processing invitation for email: ${email}, name: ${name}`);
    
    // Validate required fields
    if (!email) {
      throw new Error('Email is required');
    }
    
    if (!familyId) {
      throw new Error('Family ID is required');
    }

    // Create Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Generate a temporary random password
    const temporaryPassword = generateRandomPassword();
    console.log(`Generated temporary password for user`);

    // Create user with admin privileges (with temporary password, email_confirm true)
    const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: temporaryPassword,
      email_confirm: true,
      user_metadata: {
        name: name,
        is_parent: isParent,
        family_id: familyId
      },
    })

    if (createError) {
      console.log(`Error creating user: ${createError.message}`);
      throw createError
    }

    console.log(`User created successfully with ID: ${userData.user.id}`);

    // Create profile for the user
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: userData.user.id,
        email: email,
        name: name,
        is_parent: isParent,
      })

    if (profileError) {
      console.log(`Error creating profile: ${profileError.message}`);
      throw profileError
    }

    console.log('User profile created successfully');

    // Add user to family
    const { error: familyError } = await supabaseAdmin
      .from('family_members')
      .insert({
        family_id: familyId,
        user_id: userData.user.id,
      })

    if (familyError) {
      console.log(`Error adding user to family: ${familyError.message}`);
      throw familyError
    }

    console.log('User added to family successfully');

    // Send password reset (invite) email using generateLink
    const siteUrl = Deno.env.get('SITE_URL') ?? '';
    // Let Supabase construct the full URL with proper hash format
    const redirectTo = `${siteUrl}/reset-password?email=${email}`;
    console.log(`Creating reset link with redirectTo: ${redirectTo}`);
    
    const { data: linkData, error: linkError } = await supabaseAdmin.auth.admin.generateLink({
      type: 'recovery',
      email: email,
      options: {
        redirectTo: redirectTo,
        data: {
          name: name,
          is_parent: isParent,
          family_id: familyId
        }
      },
    });

    if (linkError) {
      console.log(`Error generating reset link: ${linkError.message}`);
      throw linkError
    }

    console.log(`Generated link successful for ${email}`);
    console.log(`Action URL: ${linkData.properties.action_link}`);

    // Try multiple methods to ensure email delivery
    
    // 1. Via Admin API's sendEmail
    try {
      console.log('Sending direct email via admin API...');
      
      const emailHtml = `
        <h2>Welcome to KinDo!</h2>
        <p>Hi ${name},</p>
        <p>You've been invited to join a family on KinDo - the family task management app that brings everyone together!</p>
        
        <p>Click the button below to accept the invitation and set your password:</p>
        
        <div style="margin: 24px 0;">
          <a href="${linkData.properties.action_link}" 
             style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Accept Invitation & Set Password
          </a>
        </div>
        
        <p><b>If the button doesn't work, copy and paste this link into your browser:</b><br>
        ${linkData.properties.action_link}</p>
        
        <p>This invitation will expire in 7 days.</p>
        <p style="color: #666; font-size: 14px;">If you didn't expect this invitation, you can safely ignore this email.</p>
      `;
      
      const { error: emailError } = await supabaseAdmin.auth.admin.sendEmail({
        email: email,
        subject: "You've been invited to KinDo",
        html: emailHtml,
      });
      
      if (emailError) {
        console.log(`Error sending direct email: ${emailError.message}`);
      } else {
        console.log('Direct email sent successfully');
      }
    } catch (emailError) {
      console.log(`Error in direct email sending: ${emailError.message}`);
      // We continue since we already created the user successfully
    }

    // 2. Try our custom send-invitation-email function too (if it exists)
    try {
      console.log('Also trying send-invitation-email function as backup...');
      const emailResponse = await supabaseAdmin.functions.invoke('send-invitation-email', {
        body: {
          email: email,
          name: name,
          reset_link: linkData.properties.action_link,
        }
      });
      console.log(`Backup email function response status: ${emailResponse.status}`);
    } catch (backupError) {
      console.log(`Backup email method failed: ${backupError.message}`);
      // This is just a backup, so we continue
    }

    return new Response(
      JSON.stringify({ 
        id: userData.user.id,
        message: 'User invited successfully',
        reset_link: linkData.properties.action_link 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.log(`Error processing invitation: ${error.message}`);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
}) 
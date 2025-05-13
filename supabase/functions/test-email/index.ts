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

serve(async (req: Request) => {
  console.log('Test email function called');
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email } = await req.json()
    console.log(`Attempting to send test email to: ${email}`);

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

    // Simple test email
    const emailHtml = `
      <h2>Test Email from KinDo</h2>
      <p>This is a test email to verify that the email delivery system is working.</p>
      <p>If you're receiving this, it means your Supabase email configuration is working!</p>
      <p>Time sent: ${new Date().toISOString()}</p>
      <p>Debug info:</p>
      <ul>
        <li>URL: ${Deno.env.get('SUPABASE_URL') ?? 'Not set'}</li>
        <li>Email Provider: ${Deno.env.get('SUPABASE_EMAIL_PROVIDER') ?? 'Default'}</li>
      </ul>
    `;
    
    // Method 1: Use sendEmail API
    let success = false;
    let error = null;
    
    try {
      const { error: emailError } = await supabaseAdmin.auth.admin.sendEmail({
        email: email,
        subject: "KinDo Test Email - Method 1",
        html: emailHtml,
      });
      
      if (emailError) {
        console.log(`Error sending test email (Method 1): ${emailError.message}`);
        error = emailError;
      } else {
        console.log('Test email sent successfully via Method 1');
        success = true;
      }
    } catch (e) {
      console.log(`Exception in Method 1: ${e.message}`);
      error = e;
    }
    
    // Method 2: Try password reset method
    try {
      const { data, error: resetError } = await supabaseAdmin.auth.admin.generateLink({
        type: 'recovery',
        email: email,
        options: {
          redirectTo: `${Deno.env.get('SITE_URL') ?? ''}/reset-password?email=${email}`,
        }
      });
      
      if (resetError) {
        console.log(`Error sending password reset (Method 2): ${resetError.message}`);
        if (!success) error = resetError;
      } else {
        console.log('Password reset link generated successfully via Method 2');
        console.log(`Action URL: ${data?.properties?.action_link}`);
        success = true;
      }
    } catch (e) {
      console.log(`Exception in Method 2: ${e.message}`);
      if (!success) error = e;
    }
    
    if (!success && error) {
      throw error;
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Test email sent using multiple methods. Please check your inbox (and spam folder).' 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.log(`Error in test email function: ${error.message}`);
    return new Response(
      JSON.stringify({ 
        error: error.message,
        message: 'Failed to send email. Please check if your email configuration is set up correctly in Supabase.'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
}) 
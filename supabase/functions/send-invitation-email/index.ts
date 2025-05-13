// @ts-ignore
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  console.log('Starting send-invitation-email function');
  
  try {
    // Parse the JSON body
    const body = await req.json();
    
    const { email, name, temporaryPassword, familyName, isExistingUser = false } = body;

    console.log(`Received request to send email to: ${email}`);
    console.log(`Parameters: name=${name}, isExistingUser=${isExistingUser}, familyName=${familyName}`);
    
    // Log success (even though we're not actually sending an email yet)
    console.log('Email would be sent in a production environment');
    
    return new Response(
      JSON.stringify({ 
        success: true,
        message: "Email sending simulated successfully",
        recipient: email,
        debug: {
          requestParams: { email, name, familyName, isExistingUser },
          // Don't log the password in production!
          temporaryPassword: temporaryPassword?.substring(0, 3) + '****'
        }
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Error in send-invitation-email function:', error);
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: `Function error: ${error.message || 'Unknown error'}`
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}); 
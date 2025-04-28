import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts";

serve(async (req) => {
  try {
    const { email, name, temp_password, token, redirect_url } = await req.json()

    // Create SMTP client
    const client = new SmtpClient();

    // Connect to SMTP server (using environment variables)
    await client.connectTLS({
      hostname: Deno.env.get('SMTP_HOSTNAME') || '',
      port: parseInt(Deno.env.get('SMTP_PORT') || '587'),
      username: Deno.env.get('SMTP_USERNAME') || '',
      password: Deno.env.get('SMTP_PASSWORD') || '',
    });

    // Send email
    await client.send({
      from: Deno.env.get('SMTP_FROM') || '',
      to: email,
      subject: 'Welcome to KinDo - Your Family Invitation',
      html: `
        <h2>Welcome to KinDo!</h2>
        <p>Hi ${name},</p>
        <p>You've been invited to join a family on KinDo - the family task management app that brings everyone together!</p>

        <p>Here are your temporary login credentials:</p>
        <ul>
          <li><strong>Email:</strong> ${email}</li>
          <li><strong>Temporary Password:</strong> ${temp_password}</li>
        </ul>

        <p>Click the button below to accept the invitation and set up your account:</p>

        <div style="margin: 24px 0;">
          <a href="${redirect_url}" style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Accept Invitation</a>
        </div>

        <p>This invitation will expire in 7 days.</p>
        <p style="color: #666; font-size: 14px;">If you didn't expect this invitation, you can safely ignore this email.</p>
      `,
    });

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Invitation email sent successfully' }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
}) 
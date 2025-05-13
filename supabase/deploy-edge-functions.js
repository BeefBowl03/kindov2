// Deploy Edge Functions to Supabase
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const functionsDir = path.join(__dirname, 'functions');
const functions = ['send-invitation-email']; // Add all functions you want to deploy

// URL and key from your Supabase project settings
const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const APP_URL = process.env.APP_URL || 'http://localhost:3000';

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set');
  process.exit(1);
}

console.log('Deploying Edge Functions to Supabase...');

for (const funcName of functions) {
  const funcPath = path.join(functionsDir, funcName);
  
  if (!fs.existsSync(funcPath)) {
    console.error(`Error: Function directory ${funcPath} does not exist`);
    continue;
  }
  
  try {
    console.log(`Deploying ${funcName}...`);
    
    // Deploy the function
    execSync(`npx supabase functions deploy ${funcName} --project-ref=${SUPABASE_URL.split('//')[1].split('.')[0]}`, {
      stdio: 'inherit'
    });
    
    // Set environment variables
    console.log(`Setting environment variables for ${funcName}...`);
    execSync(`npx supabase secrets set --env-file .env SUPABASE_URL=${SUPABASE_URL} SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY} APP_URL=${APP_URL}`, {
      stdio: 'inherit'
    });
    
    console.log(`Successfully deployed ${funcName} with environment variables`);
  } catch (error) {
    console.error(`Error deploying ${funcName}: ${error.message}`);
  }
}

console.log('Deployment completed.'); 
// Simple deploy script for Edge Functions
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const functionsDir = path.join(__dirname, 'functions');
const functionName = 'send-invitation-email';

console.log('Deploying simplified Edge Function to Supabase...');

const funcPath = path.join(functionsDir, functionName);
  
if (!fs.existsSync(funcPath)) {
  console.error(`Error: Function directory ${funcPath} does not exist`);
  process.exit(1);
}

try {
  console.log(`Deploying ${functionName}...`);
  
  // Get your project reference from supabase URL
  // Example: if your URL is https://abcdefghijk.supabase.co, 
  // then your project ref is abcdefghijk
  
  // You can set this value here directly
  // const projectRef = 'cgthmzpuqvxeiwqtscsy';
  // Or get it from the command line
  const projectRef = process.argv[2];
  
  if (!projectRef) {
    console.error('Please provide your Supabase project reference as a command line argument');
    console.error('Example: node deploy-simple.js cgthmzpuqvxeiwqtscsy');
    process.exit(1);
  }
  
  // Deploy function with no secrets (this version doesn't need them)
  execSync(`npx supabase functions deploy ${functionName} --project-ref=${projectRef}`, {
    stdio: 'inherit'
  });
  
  console.log(`Successfully deployed ${functionName}`);
} catch (error) {
  console.error(`Error deploying function: ${error.message}`);
} 
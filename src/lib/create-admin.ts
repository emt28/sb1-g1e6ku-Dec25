import { createAdminUser } from './supabase-admin';

async function main() {
  try {
    await createAdminUser('eddiemiron@gmail.com', 'PapucelU28');
    console.log('Admin user created successfully');
  } catch (error) {
    console.error('Failed to create admin user:', error);
  }
}

main();
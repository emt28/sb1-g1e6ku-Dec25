import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing required environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupAdminUser() {
  try {
    // Create admin user
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: 'admin@6fitness.com',
      password: 'Admin123!',
      email_confirm: true,
      user_metadata: {
        name: '6.fitness Admin',
        role: 'admin'
      }
    });

    if (authError) throw authError;

    // Create admin profile
    const { error: profileError } = await supabase
      .from('users_extension')
      .insert({
        id: authUser.user.id,
        email: 'admin@6fitness.com',
        name: '6.fitness Admin',
        role: 'admin',
        is_active: true
      });

    if (profileError) throw profileError;

    console.log('Admin user created successfully');
    console.log('Email: admin@6fitness.com');
    console.log('Password: Admin123!');
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
}

setupAdminUser();
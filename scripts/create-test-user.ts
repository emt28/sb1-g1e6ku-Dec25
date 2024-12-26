import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function createTestUser() {
  try {
    // Create auth user
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: 'test@example.com',
      password: 'password123',
      email_confirm: true
    });

    if (authError) throw authError;

    // Create user extension
    const { error: profileError } = await supabase
      .from('users_extension')
      .insert({
        id: authUser.user.id,
        email: 'test@example.com',
        name: 'Test User',
        role: 'admin',
        is_active: true
      });

    if (profileError) throw profileError;

    console.log('Test user created successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error creating test user:', error);
    process.exit(1);
  }
}

createTestUser();
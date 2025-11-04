// Supabase client for reading runs, flows, pages, and subscribers
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import env from '../config/env';
import logger from '../utils/logger';

// Create Supabase client
export const supabase: SupabaseClient = createClient(
  env.supabase.url,
  env.supabase.serviceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

logger.info('✅ Supabase client initialized', {
  url: env.supabase.url,
});

export default supabase;

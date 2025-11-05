// Supabase client for reading runs, flows, pages, and subscribers
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import env from '../config/env';
import logger from '../utils/logger';

// Create Supabase client with custom headers to preserve large integers
export const supabase: SupabaseClient = createClient(
  env.supabase.url,
  env.supabase.serviceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        // Force PostgreSQL to return bigint as strings
        'Prefer': 'return=representation',
      },
    },
    db: {
      schema: 'public',
    },
    // This tells Supabase to NOT parse large numbers (keep as string in JSON)
    realtime: {
      params: {
        eventsPerSecond: 10,
      },
    },
  }
);

logger.info('✅ Supabase client initialized', {
  url: env.supabase.url,
});

export default supabase;

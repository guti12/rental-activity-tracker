import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

if (!supabaseUrl || !supabaseAnonKey) {
	// Fail fast to surface misconfiguration early
	// Note: In some build environments, this may evaluate at import-time.
}

declare global {
	// eslint-disable-next-line no-var
	var __SUPABASE_BROWSER_CLIENT__: SupabaseClient | undefined;
}

/**
 * Singleton Supabase client for the browser. Cached on globalThis to survive HMR in dev.
 */
export const getBrowserSupabaseClient = (): SupabaseClient => {
	if (!globalThis.__SUPABASE_BROWSER_CLIENT__) {
		if (!supabaseUrl || !supabaseAnonKey) {
			throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY');
		}
		globalThis.__SUPABASE_BROWSER_CLIENT__ = createClient(supabaseUrl, supabaseAnonKey, {
			auth: {
				persistSession: true,
				autoRefreshToken: true,
				detectSessionInUrl: true,
			},
		});
	}
	return globalThis.__SUPABASE_BROWSER_CLIENT__;
};

/**
 * Server-side helper to create a Supabase client per-request.
 * Uses SUPABASE_SERVICE_ROLE_KEY if provided; otherwise falls back to anon key.
 */
export const createServerSupabaseClient = (options?: {
	serviceKey?: string;
	headers?: Record<string, string>;
}): SupabaseClient => {
	const key = options?.serviceKey || process.env.SUPABASE_SERVICE_ROLE_KEY || supabaseAnonKey;
	if (!supabaseUrl || !key) {
		throw new Error('Missing Supabase configuration for server client');
	}
	return createClient(supabaseUrl, key, {
		global: { headers: options?.headers },
		auth: {
			persistSession: false,
			autoRefreshToken: false,
			detectSessionInUrl: false,
		},
	});
};

// Convenience default export for browser usage
const supabase = getBrowserSupabaseClient();
export default supabase;


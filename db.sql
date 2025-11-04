--- 1. EXTENSIONS ---
plpgsql                   | 1.0
pg_cron                   | 1.6
pgsodium                  | 3.1.8
http                      | 1.6
hypopg                    | 1.4.1
index_advisor             | 0.2.0
pgcrypto                  | 1.3
unaccent                  | 1.1
uuid-ossp                 | 1.1
pg_graphql                | 1.5.11
vector                    | 0.8.0
supabase_vault            | 0.3.1
pg_stat_statements        | 1.11
pg_net                    | 0.19.5
pg_trgm                   | 1.6
pgmq                      | 1.4.4

--- 2. SCHEMAS ---
graphql_public
graphql
net
auth
cron
extensions
public
realtime
storage
supabase_functions
vault
supabase_migrations

--- 3. ROLES ---
anon
authenticated
authenticator
dashboard_user
supabase_replication_admin
service_role
supabase_admin
supabase_auth_admin
supabase_functions_admin
supabase_read_only_user
supabase_realtime_admin
supabase_storage_admin
postgres
supabase_etl_admin
cli_login_postgres

--- 4. TABLES AND COLUMNS ---
auth.audit_log_entries -> instance_id (uuid) | Nullable: YES | Default: NULL
auth.audit_log_entries -> id (uuid) | Nullable: NO | Default: NULL
auth.audit_log_entries -> payload (json) | Nullable: YES | Default: NULL
auth.audit_log_entries -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.audit_log_entries -> ip_address (varchar) | Nullable: NO | Default: ''::character varying
auth.flow_state -> id (uuid) | Nullable: NO | Default: NULL
auth.flow_state -> user_id (uuid) | Nullable: YES | Default: NULL
auth.flow_state -> auth_code (text) | Nullable: NO | Default: NULL
auth.flow_state -> code_challenge_method (code_challenge_method) | Nullable: NO | Default: NULL
auth.flow_state -> code_challenge (text) | Nullable: NO | Default: NULL
auth.flow_state -> provider_type (text) | Nullable: NO | Default: NULL
auth.flow_state -> provider_access_token (text) | Nullable: YES | Default: NULL
auth.flow_state -> provider_refresh_token (text) | Nullable: YES | Default: NULL
auth.flow_state -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.flow_state -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.flow_state -> authentication_method (text) | Nullable: NO | Default: NULL
auth.flow_state -> auth_code_issued_at (timestamptz) | Nullable: YES | Default: NULL
auth.identities -> provider_id (text) | Nullable: NO | Default: NULL
auth.identities -> user_id (uuid) | Nullable: NO | Default: NULL
auth.identities -> identity_data (jsonb) | Nullable: NO | Default: NULL
auth.identities -> provider (text) | Nullable: NO | Default: NULL
auth.identities -> last_sign_in_at (timestamptz) | Nullable: YES | Default: NULL
auth.identities -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.identities -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.identities -> email (text) | Nullable: YES | Default: NULL
auth.identities -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
auth.instances -> id (uuid) | Nullable: NO | Default: NULL
auth.instances -> uuid (uuid) | Nullable: YES | Default: NULL
auth.instances -> raw_base_config (text) | Nullable: YES | Default: NULL
auth.instances -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.instances -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.mfa_amr_claims -> session_id (uuid) | Nullable: NO | Default: NULL
auth.mfa_amr_claims -> created_at (timestamptz) | Nullable: NO | Default: NULL
auth.mfa_amr_claims -> updated_at (timestamptz) | Nullable: NO | Default: NULL
auth.mfa_amr_claims -> authentication_method (text) | Nullable: NO | Default: NULL
auth.mfa_amr_claims -> id (uuid) | Nullable: NO | Default: NULL
auth.mfa_challenges -> id (uuid) | Nullable: NO | Default: NULL
auth.mfa_challenges -> factor_id (uuid) | Nullable: NO | Default: NULL
auth.mfa_challenges -> created_at (timestamptz) | Nullable: NO | Default: NULL
auth.mfa_challenges -> verified_at (timestamptz) | Nullable: YES | Default: NULL
auth.mfa_challenges -> ip_address (inet) | Nullable: NO | Default: NULL
auth.mfa_challenges -> otp_code (text) | Nullable: YES | Default: NULL
auth.mfa_challenges -> web_authn_session_data (jsonb) | Nullable: YES | Default: NULL
auth.mfa_factors -> id (uuid) | Nullable: NO | Default: NULL
auth.mfa_factors -> user_id (uuid) | Nullable: NO | Default: NULL
auth.mfa_factors -> friendly_name (text) | Nullable: YES | Default: NULL
auth.mfa_factors -> factor_type (factor_type) | Nullable: NO | Default: NULL
auth.mfa_factors -> status (factor_status) | Nullable: NO | Default: NULL
auth.mfa_factors -> created_at (timestamptz) | Nullable: NO | Default: NULL
auth.mfa_factors -> updated_at (timestamptz) | Nullable: NO | Default: NULL
auth.mfa_factors -> secret (text) | Nullable: YES | Default: NULL
auth.mfa_factors -> phone (text) | Nullable: YES | Default: NULL
auth.mfa_factors -> last_challenged_at (timestamptz) | Nullable: YES | Default: NULL
auth.mfa_factors -> web_authn_credential (jsonb) | Nullable: YES | Default: NULL
auth.mfa_factors -> web_authn_aaguid (uuid) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> id (uuid) | Nullable: NO | Default: NULL
auth.oauth_authorizations -> authorization_id (text) | Nullable: NO | Default: NULL
auth.oauth_authorizations -> client_id (uuid) | Nullable: NO | Default: NULL
auth.oauth_authorizations -> user_id (uuid) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> redirect_uri (text) | Nullable: NO | Default: NULL
auth.oauth_authorizations -> scope (text) | Nullable: NO | Default: NULL
auth.oauth_authorizations -> state (text) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> resource (text) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> code_challenge (text) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> code_challenge_method (code_challenge_method) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> response_type (oauth_response_type) | Nullable: NO | Default: 'code'::auth.oauth_response_type
auth.oauth_authorizations -> status (oauth_authorization_status) | Nullable: NO | Default: 'pending'::auth.oauth_authorization_status
auth.oauth_authorizations -> authorization_code (text) | Nullable: YES | Default: NULL
auth.oauth_authorizations -> created_at (timestamptz) | Nullable: NO | Default: now()
auth.oauth_authorizations -> expires_at (timestamptz) | Nullable: NO | Default: (now() + '00:03:00'::interval)
auth.oauth_authorizations -> approved_at (timestamptz) | Nullable: YES | Default: NULL
auth.oauth_clients -> id (uuid) | Nullable: NO | Default: NULL
auth.oauth_clients -> client_secret_hash (text) | Nullable: YES | Default: NULL
auth.oauth_clients -> registration_type (oauth_registration_type) | Nullable: NO | Default: NULL
auth.oauth_clients -> redirect_uris (text) | Nullable: NO | Default: NULL
auth.oauth_clients -> grant_types (text) | Nullable: NO | Default: NULL
auth.oauth_clients -> client_name (text) | Nullable: YES | Default: NULL
auth.oauth_clients -> client_uri (text) | Nullable: YES | Default: NULL
auth.oauth_clients -> logo_uri (text) | Nullable: YES | Default: NULL
auth.oauth_clients -> created_at (timestamptz) | Nullable: NO | Default: now()
auth.oauth_clients -> updated_at (timestamptz) | Nullable: NO | Default: now()
auth.oauth_clients -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
auth.oauth_clients -> client_type (oauth_client_type) | Nullable: NO | Default: 'confidential'::auth.oauth_client_type
auth.oauth_consents -> id (uuid) | Nullable: NO | Default: NULL
auth.oauth_consents -> user_id (uuid) | Nullable: NO | Default: NULL
auth.oauth_consents -> client_id (uuid) | Nullable: NO | Default: NULL
auth.oauth_consents -> scopes (text) | Nullable: NO | Default: NULL
auth.oauth_consents -> granted_at (timestamptz) | Nullable: NO | Default: now()
auth.oauth_consents -> revoked_at (timestamptz) | Nullable: YES | Default: NULL
auth.one_time_tokens -> id (uuid) | Nullable: NO | Default: NULL
auth.one_time_tokens -> user_id (uuid) | Nullable: NO | Default: NULL
auth.one_time_tokens -> token_type (one_time_token_type) | Nullable: NO | Default: NULL
auth.one_time_tokens -> token_hash (text) | Nullable: NO | Default: NULL
auth.one_time_tokens -> relates_to (text) | Nullable: NO | Default: NULL
auth.one_time_tokens -> created_at (timestamp) | Nullable: NO | Default: now()
auth.one_time_tokens -> updated_at (timestamp) | Nullable: NO | Default: now()
auth.refresh_tokens -> instance_id (uuid) | Nullable: YES | Default: NULL
auth.refresh_tokens -> id (int8) | Nullable: NO | Default: nextval('auth.refresh_tokens_id_seq'::regclass)
auth.refresh_tokens -> token (varchar) | Nullable: YES | Default: NULL
auth.refresh_tokens -> user_id (varchar) | Nullable: YES | Default: NULL
auth.refresh_tokens -> revoked (bool) | Nullable: YES | Default: NULL
auth.refresh_tokens -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.refresh_tokens -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.refresh_tokens -> parent (varchar) | Nullable: YES | Default: NULL
auth.refresh_tokens -> session_id (uuid) | Nullable: YES | Default: NULL
auth.saml_providers -> id (uuid) | Nullable: NO | Default: NULL
auth.saml_providers -> sso_provider_id (uuid) | Nullable: NO | Default: NULL
auth.saml_providers -> entity_id (text) | Nullable: NO | Default: NULL
auth.saml_providers -> metadata_xml (text) | Nullable: NO | Default: NULL
auth.saml_providers -> metadata_url (text) | Nullable: YES | Default: NULL
auth.saml_providers -> attribute_mapping (jsonb) | Nullable: YES | Default: NULL
auth.saml_providers -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.saml_providers -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.saml_providers -> name_id_format (text) | Nullable: YES | Default: NULL
auth.saml_relay_states -> id (uuid) | Nullable: NO | Default: NULL
auth.saml_relay_states -> sso_provider_id (uuid) | Nullable: NO | Default: NULL
auth.saml_relay_states -> request_id (text) | Nullable: NO | Default: NULL
auth.saml_relay_states -> for_email (text) | Nullable: YES | Default: NULL
auth.saml_relay_states -> redirect_to (text) | Nullable: YES | Default: NULL
auth.saml_relay_states -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.saml_relay_states -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.saml_relay_states -> flow_state_id (uuid) | Nullable: YES | Default: NULL
auth.schema_migrations -> version (varchar) | Nullable: NO | Default: NULL
auth.sessions -> id (uuid) | Nullable: NO | Default: NULL
auth.sessions -> user_id (uuid) | Nullable: NO | Default: NULL
auth.sessions -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.sessions -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.sessions -> factor_id (uuid) | Nullable: YES | Default: NULL
auth.sessions -> aal (aal_level) | Nullable: YES | Default: NULL
auth.sessions -> not_after (timestamptz) | Nullable: YES | Default: NULL
auth.sessions -> refreshed_at (timestamp) | Nullable: YES | Default: NULL
auth.sessions -> user_agent (text) | Nullable: YES | Default: NULL
auth.sessions -> ip (inet) | Nullable: YES | Default: NULL
auth.sessions -> tag (text) | Nullable: YES | Default: NULL
auth.sessions -> oauth_client_id (uuid) | Nullable: YES | Default: NULL
auth.sso_domains -> id (uuid) | Nullable: NO | Default: NULL
auth.sso_domains -> sso_provider_id (uuid) | Nullable: NO | Default: NULL
auth.sso_domains -> domain (text) | Nullable: NO | Default: NULL
auth.sso_domains -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.sso_domains -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.sso_providers -> id (uuid) | Nullable: NO | Default: NULL
auth.sso_providers -> resource_id (text) | Nullable: YES | Default: NULL
auth.sso_providers -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.sso_providers -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.sso_providers -> disabled (bool) | Nullable: YES | Default: NULL
auth.users -> instance_id (uuid) | Nullable: YES | Default: NULL
auth.users -> id (uuid) | Nullable: NO | Default: NULL
auth.users -> aud (varchar) | Nullable: YES | Default: NULL
auth.users -> role (varchar) | Nullable: YES | Default: NULL
auth.users -> email (varchar) | Nullable: YES | Default: NULL
auth.users -> encrypted_password (varchar) | Nullable: YES | Default: NULL
auth.users -> email_confirmed_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> invited_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> confirmation_token (varchar) | Nullable: YES | Default: NULL
auth.users -> confirmation_sent_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> recovery_token (varchar) | Nullable: YES | Default: NULL
auth.users -> recovery_sent_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> email_change_token_new (varchar) | Nullable: YES | Default: NULL
auth.users -> email_change (varchar) | Nullable: YES | Default: NULL
auth.users -> email_change_sent_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> last_sign_in_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> raw_app_meta_data (jsonb) | Nullable: YES | Default: NULL
auth.users -> raw_user_meta_data (jsonb) | Nullable: YES | Default: NULL
auth.users -> is_super_admin (bool) | Nullable: YES | Default: NULL
auth.users -> created_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> updated_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> phone (text) | Nullable: YES | Default: NULL::character varying
auth.users -> phone_confirmed_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> phone_change (text) | Nullable: YES | Default: ''::character varying
auth.users -> phone_change_token (varchar) | Nullable: YES | Default: ''::character varying
auth.users -> phone_change_sent_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> confirmed_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> email_change_token_current (varchar) | Nullable: YES | Default: ''::character varying
auth.users -> email_change_confirm_status (int2) | Nullable: YES | Default: 0
auth.users -> banned_until (timestamptz) | Nullable: YES | Default: NULL
auth.users -> reauthentication_token (varchar) | Nullable: YES | Default: ''::character varying
auth.users -> reauthentication_sent_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> is_sso_user (bool) | Nullable: NO | Default: false
auth.users -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
auth.users -> is_anonymous (bool) | Nullable: NO | Default: false
net._http_response -> id (int8) | Nullable: YES | Default: NULL
net._http_response -> status_code (int4) | Nullable: YES | Default: NULL
net._http_response -> content_type (text) | Nullable: YES | Default: NULL
net._http_response -> headers (jsonb) | Nullable: YES | Default: NULL
net._http_response -> content (text) | Nullable: YES | Default: NULL
net._http_response -> timed_out (bool) | Nullable: YES | Default: NULL
net._http_response -> error_msg (text) | Nullable: YES | Default: NULL
net._http_response -> created (timestamptz) | Nullable: NO | Default: now()
net.http_request_queue -> id (int8) | Nullable: NO | Default: nextval('net.http_request_queue_id_seq'::regclass)
net.http_request_queue -> method (text) | Nullable: NO | Default: NULL
net.http_request_queue -> url (text) | Nullable: NO | Default: NULL
net.http_request_queue -> headers (jsonb) | Nullable: YES | Default: NULL
net.http_request_queue -> body (bytea) | Nullable: YES | Default: NULL
net.http_request_queue -> timeout_milliseconds (int4) | Nullable: NO | Default: NULL
pgmq.a_alvocast-messages -> msg_id (int8) | Nullable: NO | Default: NULL
pgmq.a_alvocast-messages -> read_ct (int4) | Nullable: NO | Default: 0
pgmq.a_alvocast-messages -> enqueued_at (timestamptz) | Nullable: NO | Default: now()
pgmq.a_alvocast-messages -> archived_at (timestamptz) | Nullable: NO | Default: now()
pgmq.a_alvocast-messages -> vt (timestamptz) | Nullable: NO | Default: NULL
pgmq.a_alvocast-messages -> message (jsonb) | Nullable: YES | Default: NULL
pgmq.meta -> queue_name (varchar) | Nullable: NO | Default: NULL
pgmq.meta -> is_partitioned (bool) | Nullable: NO | Default: NULL
pgmq.meta -> is_unlogged (bool) | Nullable: NO | Default: NULL
pgmq.meta -> created_at (timestamptz) | Nullable: NO | Default: now()
pgmq.q_alvocast-messages -> msg_id (int8) | Nullable: NO | Default: NULL
pgmq.q_alvocast-messages -> read_ct (int4) | Nullable: NO | Default: 0
pgmq.q_alvocast-messages -> enqueued_at (timestamptz) | Nullable: NO | Default: now()
pgmq.q_alvocast-messages -> vt (timestamptz) | Nullable: NO | Default: NULL
pgmq.q_alvocast-messages -> message (jsonb) | Nullable: YES | Default: NULL
public.admin_roles -> id (text) | Nullable: NO | Default: NULL
public.admin_roles -> public_name (text) | Nullable: NO | Default: NULL
public.admin_roles -> permissions (jsonb) | Nullable: NO | Default: NULL
public.admin_roles -> description (text) | Nullable: NO | Default: NULL
public.admin_roles -> status (text) | Nullable: NO | Default: 'active'::text
public.admin_roles -> created_at (timestamptz) | Nullable: NO | Default: now()
public.admin_roles -> updated_at (timestamptz) | Nullable: NO | Default: now()
public.admin_roles -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.admins -> user_id (uuid) | Nullable: NO | Default: NULL
public.admins -> id (int8) | Nullable: NO | Default: NULL
public.admins -> role (text) | Nullable: NO | Default: NULL
public.admins -> notes (text) | Nullable: YES | Default: NULL
public.admins -> status (text) | Nullable: NO | Default: 'active'::text
public.admins -> created_at (timestamptz) | Nullable: NO | Default: now()
public.admins -> updated_at (timestamptz) | Nullable: NO | Default: now()
public.admins -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.articles -> id (int8) | Nullable: NO | Default: NULL
public.articles -> user_id (uuid) | Nullable: YES | Default: NULL
public.articles -> project_id (int8) | Nullable: YES | Default: NULL
public.articles -> title (text) | Nullable: YES | Default: NULL
public.articles -> content (text) | Nullable: YES | Default: NULL
public.articles -> credits_used (int8) | Nullable: YES | Default: NULL
public.articles -> status (text) | Nullable: YES | Default: NULL
public.articles -> excerpt (text) | Nullable: YES | Default: NULL
public.articles -> images (json) | Nullable: YES | Default: NULL
public.articles -> slug (text) | Nullable: YES | Default: NULL
public.articles -> words (int8) | Nullable: YES | Default: NULL
public.articles -> wpPost_id (int8) | Nullable: YES | Default: NULL
public.articles -> wpFeaturedMedia_id (int8) | Nullable: YES | Default: NULL
public.articles -> wpCategories_id (int8) | Nullable: YES | Default: NULL
public.articles -> keyword_snapshot (json) | Nullable: YES | Default: NULL
public.articles -> keyword_used (text) | Nullable: YES | Default: NULL
public.articles -> date (timestamptz) | Nullable: YES | Default: NULL
public.articles -> created_at (timestamptz) | Nullable: YES | Default: now()
public.articles -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.articles -> input_tokens (int8) | Nullable: YES | Default: NULL
public.articles -> output_tokens (int8) | Nullable: YES | Default: NULL
public.articles -> model_used (text) | Nullable: YES | Default: NULL
public.articles -> is_approval_article (bool) | Nullable: YES | Default: false
public.articles -> imagePrompt (text) | Nullable: YES | Default: NULL
public.articles -> keyword_inclusion_exclusion (jsonb) | Nullable: YES | Default: NULL
public.articles -> language (text) | Nullable: YES | Default: NULL
public.articles -> url_added (bool) | Nullable: YES | Default: false
public.articles -> wpFeaturedMedia_url (text) | Nullable: YES | Default: NULL
public.author_profile_images -> id (int8) | Nullable: NO | Default: NULL
public.author_profile_images -> age (int2) | Nullable: YES | Default: NULL
public.author_profile_images -> sex (text) | Nullable: YES | Default: NULL
public.author_profile_images -> usage_count (int8) | Nullable: YES | Default: NULL
public.author_profile_images -> path (text) | Nullable: YES | Default: NULL
public.author_profile_images -> signature (text) | Nullable: YES | Default: NULL
public.author_profile_images -> created_at (timestamptz) | Nullable: NO | Default: now()
public.author_profile_images -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.connections -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.connections -> user_id (uuid) | Nullable: YES | Default: NULL
public.connections -> connection_name (text) | Nullable: YES | Default: NULL
public.connections -> plataform_name (text) | Nullable: YES | Default: NULL
public.connections -> platform_user_id (text) | Nullable: YES | Default: NULL
public.connections -> access_token (text) | Nullable: YES | Default: NULL
public.connections -> refresh_token (text) | Nullable: YES | Default: NULL
public.connections -> token_expires_at (timestamptz) | Nullable: YES | Default: NULL
public.connections -> metadata (jsonb) | Nullable: YES | Default: NULL
public.connections -> is_active (bool) | Nullable: YES | Default: NULL
public.connections -> last_used_at (timestamptz) | Nullable: YES | Default: NULL
public.connections -> created_at (timestamptz) | Nullable: NO | Default: now()
public.connections -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.connections -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.connections -> meta_app_id (uuid) | Nullable: YES | Default: NULL
public.conversations -> id (int8) | Nullable: NO | Default: nextval('conversations_id_seq'::regclass)
public.conversations -> page_id (int8) | Nullable: NO | Default: NULL
public.conversations -> user_id (int8) | Nullable: NO | Default: NULL
public.conversations -> message_id (text) | Nullable: YES | Default: NULL
public.conversations -> is_from_user (bool) | Nullable: NO | Default: NULL
public.conversations -> content_type (text) | Nullable: NO | Default: 'text'::text
public.conversations -> message_text (text) | Nullable: YES | Default: NULL
public.conversations -> attachments (jsonb) | Nullable: YES | Default: NULL
public.conversations -> postback_payload (jsonb) | Nullable: YES | Default: NULL
public.conversations -> meta_timestamp (timestamptz) | Nullable: YES | Default: NULL
public.conversations -> created_at (timestamptz) | Nullable: NO | Default: now()
public.domains -> id (int8) | Nullable: NO | Default: NULL
public.domains -> domain (text) | Nullable: YES | Default: NULL
public.domains -> is_domain_purchased (bool) | Nullable: YES | Default: NULL
public.domains -> execution_status (text) | Nullable: YES | Default: 'not_started'::text
public.domains -> server_id (text) | Nullable: YES | Default: NULL
public.domains -> app_id (text) | Nullable: YES | Default: NULL
public.domains -> alvobot_project_id (int8) | Nullable: YES | Default: NULL
public.domains -> created_at (timestamptz) | Nullable: NO | Default: now()
public.domains -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.domains -> is_domain_on_cloudflare (bool) | Nullable: YES | Default: NULL
public.domains -> is_available (bool) | Nullable: YES | Default: NULL
public.domains -> niche (text) | Nullable: YES | Default: NULL
public.domains -> server_ip (text) | Nullable: YES | Default: NULL
public.flow_messages_mapping -> id (int4) | Nullable: NO | Default: nextval('flow_messages_mapping_id_seq'::regclass)
public.flow_messages_mapping -> post_number (text) | Nullable: YES | Default: NULL
public.flow_messages_mapping -> flow_message_id (int4) | Nullable: YES | Default: NULL
public.flow_messages_mapping -> pattern (text) | Nullable: YES | Default: NULL
public.google_accounts -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.google_accounts -> project_id (int8) | Nullable: NO | Default: NULL
public.google_accounts -> google_user_id (text) | Nullable: NO | Default: NULL
public.google_accounts -> google_email (text) | Nullable: NO | Default: NULL
public.google_accounts -> access_token (text) | Nullable: NO | Default: NULL
public.google_accounts -> refresh_token (text) | Nullable: YES | Default: NULL
public.google_accounts -> token_expiry (timestamptz) | Nullable: YES | Default: NULL
public.google_accounts -> scopes (_text) | Nullable: NO | Default: NULL
public.google_accounts -> last_token_check_status (text) | Nullable: YES | Default: NULL
public.google_accounts -> last_token_check_at (timestamptz) | Nullable: YES | Default: NULL
public.google_accounts -> created_at (timestamptz) | Nullable: NO | Default: now()
public.google_accounts -> updated_at (timestamptz) | Nullable: NO | Default: now()
public.google_accounts -> google_ads_account_id (text) | Nullable: YES | Default: NULL
public.google_accounts -> search_console_account_id (text) | Nullable: YES | Default: NULL
public.google_accounts -> google_analytics_account_id (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> creativeId (text) | Nullable: NO | Default: NULL
public.google_ads_scraper -> advertiserId (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> advertiserName (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> creativeRegions (_text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> format (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> lastShown (timestamptz) | Nullable: YES | Default: NULL
public.google_ads_scraper -> previewUrl (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> regionStats (jsonb) | Nullable: YES | Default: NULL
public.google_ads_scraper -> startUrl (text) | Nullable: YES | Default: NULL
public.google_ads_scraper -> variations (jsonb) | Nullable: YES | Default: NULL
public.google_ads_scraper -> created_at (timestamptz) | Nullable: YES | Default: now()
public.google_ads_scraper -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.google_ads_scraper_advertiser -> advertiserId (text) | Nullable: NO | Default: NULL
public.google_ads_scraper_advertiser -> advertiserName (text) | Nullable: NO | Default: NULL
public.google_ads_scraper_advertiser -> active (bool) | Nullable: YES | Default: false
public.google_ads_scraper_advertiser -> last_scraped_at (timestamptz) | Nullable: YES | Default: NULL
public.google_ads_scraper_advertiser -> created_at (timestamptz) | Nullable: YES | Default: now()
public.google_ads_scraper_advertiser -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.google_ads_scraper_advertiser -> estimatedAds (text) | Nullable: YES | Default: NULL
public.imported_transactions -> id (int4) | Nullable: NO | Default: nextval('imported_transactions_id_seq'::regclass)
public.imported_transactions -> regular_price (numeric) | Nullable: YES | Default: NULL
public.imported_transactions -> buyer_paid (numeric) | Nullable: YES | Default: NULL
public.imported_transactions -> received (numeric) | Nullable: YES | Default: NULL
public.imported_transactions -> platform_name (text) | Nullable: YES | Default: NULL
public.imported_transactions -> payment_method (text) | Nullable: YES | Default: NULL
public.imported_transactions -> seller_name (text) | Nullable: YES | Default: NULL
public.imported_transactions -> transaction_code (text) | Nullable: NO | Default: NULL
public.imported_transactions -> status (text) | Nullable: NO | Default: NULL
public.imported_transactions -> timestamp_approved (timestamptz) | Nullable: YES | Default: NULL
public.imported_transactions -> duration (text) | Nullable: YES | Default: NULL
public.imported_transactions -> type (text) | Nullable: YES | Default: NULL
public.imported_transactions -> created_at (timestamptz) | Nullable: YES | Default: NULL
public.imported_transactions -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.imported_transactions -> product_name_original_purchase (text) | Nullable: YES | Default: NULL
public.imported_transactions -> currency (text) | Nullable: YES | Default: NULL
public.imported_transactions -> installments_number (int4) | Nullable: YES | Default: 1
public.imported_transactions -> name (text) | Nullable: YES | Default: NULL
public.imported_transactions -> email (text) | Nullable: YES | Default: NULL
public.imported_transactions -> phone (text) | Nullable: YES | Default: NULL
public.imported_transactions -> document (text) | Nullable: YES | Default: NULL
public.imported_transactions -> country (text) | Nullable: YES | Default: NULL
public.imported_transactions -> src (text) | Nullable: YES | Default: NULL
public.imported_transactions -> sck (text) | Nullable: YES | Default: NULL
public.imported_transactions -> utm_source (text) | Nullable: YES | Default: NULL
public.imported_transactions -> utm_medium (text) | Nullable: YES | Default: NULL
public.imported_transactions -> utm_campaign (text) | Nullable: YES | Default: NULL
public.imported_transactions -> utm_content (text) | Nullable: YES | Default: NULL
public.imported_transactions -> utm_term (text) | Nullable: YES | Default: NULL
public.imported_transactions -> payment_code (text) | Nullable: YES | Default: NULL
public.keywords -> id (int8) | Nullable: NO | Default: NULL
public.keywords -> word (text) | Nullable: NO | Default: NULL
public.keywords -> search_volume (int8) | Nullable: YES | Default: NULL
public.keywords -> cpc_min (numeric) | Nullable: YES | Default: NULL
public.keywords -> cpc_max (numeric) | Nullable: YES | Default: NULL
public.keywords -> visibility (text) | Nullable: YES | Default: 'private'::text
public.keywords -> created_at (timestamptz) | Nullable: NO | Default: now()
public.keywords -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.keywords -> competition (text) | Nullable: YES | Default: NULL
public.keywords -> language (text) | Nullable: YES | Default: NULL
public.keywords -> country (text) | Nullable: YES | Default: NULL
public.logs -> id (int8) | Nullable: NO | Default: NULL
public.logs -> title (text) | Nullable: YES | Default: NULL
public.logs -> description (text) | Nullable: YES | Default: NULL
public.logs -> user_id (uuid) | Nullable: YES | Default: NULL
public.logs -> created_at (timestamptz) | Nullable: NO | Default: now()
public.logs -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.logs -> is_user_visible (bool) | Nullable: YES | Default: false
public.message_flows -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.message_flows -> name (text) | Nullable: YES | Default: NULL
public.message_flows -> project_id (int8) | Nullable: YES | Default: NULL
public.message_flows -> status (text) | Nullable: YES | Default: NULL
public.message_flows -> flow (jsonb) | Nullable: YES | Default: NULL
public.message_flows -> created_at (timestamptz) | Nullable: NO | Default: now()
public.message_flows -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.message_flows -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.message_flows -> is_active (bool) | Nullable: YES | Default: NULL
public.message_logs -> log_id (int8) | Nullable: NO | Default: NULL
public.message_logs -> page_id (int8) | Nullable: NO | Default: NULL
public.message_logs -> user_id (text) | Nullable: NO | Default: NULL
public.message_logs -> message_id (text) | Nullable: YES | Default: NULL
public.message_logs -> status (text) | Nullable: NO | Default: 'pending'::text
public.message_logs -> error_message (text) | Nullable: YES | Default: NULL
public.message_logs -> sent_at (timestamptz) | Nullable: YES | Default: NULL
public.message_logs -> delivered_at (timestamptz) | Nullable: YES | Default: NULL
public.message_logs -> read_at (timestamptz) | Nullable: YES | Default: NULL
public.message_logs -> created_at (timestamptz) | Nullable: NO | Default: now()
public.message_logs -> flow_id (uuid) | Nullable: YES | Default: NULL
public.message_logs -> run_id (int8) | Nullable: YES | Default: NULL
public.message_logs -> flow_node_id (uuid) | Nullable: YES | Default: NULL
public.message_logs -> id (int8) | Nullable: NO | Default: NULL
public.message_logs -> error_code (text) | Nullable: YES | Default: NULL
public.message_logs -> fb_headers (jsonb) | Nullable: YES | Default: NULL
public.message_runs -> id (int8) | Nullable: NO | Default: NULL
public.message_runs -> user_id (uuid) | Nullable: YES | Default: NULL
public.message_runs -> trigger_id (int8) | Nullable: YES | Default: NULL
public.message_runs -> page_ids (_int8) | Nullable: YES | Default: NULL
public.message_runs -> flow_id (uuid) | Nullable: YES | Default: NULL
public.message_runs -> status (text) | Nullable: YES | Default: NULL
public.message_runs -> start_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> created_at (timestamptz) | Nullable: NO | Default: now()
public.message_runs -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> next_step_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> next_step_id (text) | Nullable: YES | Default: NULL
public.message_runs -> last_step_id (text) | Nullable: YES | Default: NULL
public.message_runs -> total_messages (int8) | Nullable: YES | Default: 0
public.message_runs -> success_count (int8) | Nullable: YES | Default: 0
public.message_runs -> failure_count (int8) | Nullable: YES | Default: 0
public.message_runs -> completed_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> metrics_updated_at (timestamptz) | Nullable: YES | Default: NULL
public.message_runs -> error_summary (jsonb) | Nullable: YES | Default: NULL
public.message_runs -> total_subscribers_at_creation (int4) | Nullable: YES | Default: 0
public.message_runs -> active_subscribers_at_creation (int4) | Nullable: YES | Default: 0
public.message_triggers -> id (int8) | Nullable: NO | Default: NULL
public.message_triggers -> trigger_definition (text) | Nullable: YES | Default: NULL
public.message_triggers -> page_ids (_int8) | Nullable: YES | Default: NULL
public.message_triggers -> flow_id (uuid) | Nullable: YES | Default: NULL
public.message_triggers -> status (text) | Nullable: YES | Default: NULL
public.message_triggers -> created_at (timestamptz) | Nullable: NO | Default: now()
public.message_triggers -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.message_triggers -> deleted_at (timestamptz) | Nullable: YES | Default: NULL
public.meta_app_credentials -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.meta_app_credentials -> app_name (text) | Nullable: NO | Default: NULL
public.meta_app_credentials -> app_id (text) | Nullable: NO | Default: NULL
public.meta_app_credentials -> app_secret (text) | Nullable: NO | Default: NULL
public.meta_app_credentials -> webhook_url (text) | Nullable: NO | Default: NULL
public.meta_app_credentials -> webhook_verify_token (text) | Nullable: YES | Default: NULL
public.meta_app_credentials -> environment (text) | Nullable: YES | Default: 'production'::text
public.meta_app_credentials -> is_active (bool) | Nullable: YES | Default: true
public.meta_app_credentials -> is_banned (bool) | Nullable: YES | Default: false
public.meta_app_credentials -> banned_at (timestamptz) | Nullable: YES | Default: NULL
public.meta_app_credentials -> banned_reason (text) | Nullable: YES | Default: NULL
public.meta_app_credentials -> created_at (timestamptz) | Nullable: YES | Default: now()
public.meta_app_credentials -> updated_at (timestamptz) | Nullable: YES | Default: now()
public.meta_app_credentials -> notes (text) | Nullable: YES | Default: NULL
public.meta_pages -> page_id (int8) | Nullable: NO | Default: NULL
public.meta_pages -> page_name (text) | Nullable: NO | Default: NULL
public.meta_pages -> access_token (text) | Nullable: NO | Default: NULL
public.meta_pages -> is_active (bool) | Nullable: YES | Default: true
public.meta_pages -> created_at (timestamp) | Nullable: YES | Default: CURRENT_TIMESTAMP
public.meta_pages -> updated_at (timestamp) | Nullable: YES | Default: CURRENT_TIMESTAMP
public.meta_pages -> country (text) | Nullable: YES | Default: NULL
public.meta_pages -> language (text) | Nullable: YES | Default: NULL
public.meta_pages -> niche (text) | Nullable: YES | Default: NULL
public.meta_pages -> objective (text) | Nullable: YES | Default: NULL
public.meta_pages -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.meta_pages -> user_id (uuid) | Nullable: YES | Default: NULL
public.meta_pages -> connection_id (uuid) | Nullable: YES | Default: NULL
public.meta_pages -> image (text) | Nullable: YES | Default: NULL
public.meta_pages -> error (text) | Nullable: YES | Default: NULL
public.meta_subscribers -> page_id (int8) | Nullable: NO | Default: NULL
public.meta_subscribers -> user_id (int8) | Nullable: NO | Default: NULL
public.meta_subscribers -> user_name (text) | Nullable: YES | Default: NULL
public.meta_subscribers -> is_active (bool) | Nullable: YES | Default: true
public.meta_subscribers -> created_at (timestamp) | Nullable: YES | Default: CURRENT_TIMESTAMP
public.meta_subscribers -> updated_at (timestamp) | Nullable: YES | Default: CURRENT_TIMESTAMP
public.meta_subscribers -> can_reply (bool) | Nullable: YES | Default: NULL
public.meta_subscribers -> is_subscribed (bool) | Nullable: YES | Default: NULL
public.meta_subscribers -> last_interaction_at (timestamptz) | Nullable: YES | Default: NULL
public.meta_subscribers -> window_expires_at (timestamptz) | Nullable: YES | Default: NULL
public.orchestrator_config -> id (text) | Nullable: NO | Default: 'main'::text
public.orchestrator_config -> is_enabled (bool) | Nullable: NO | Default: true
public.orchestrator_config -> max_workers (int4) | Nullable: NO | Default: 5
public.orchestrator_config -> delay_between_workers_ms (int4) | Nullable: NO | Default: 1000
public.orchestrator_config -> updated_at (timestamptz) | Nullable: YES | Default: now()
public.plans -> id (int8) | Nullable: NO | Default: NULL
public.plans -> name (text) | Nullable: YES | Default: NULL
public.plans -> description (text) | Nullable: YES | Default: NULL
public.plans -> monthly_credits (int8) | Nullable: YES | Default: '0'::bigint
public.plans -> price (float8) | Nullable: YES | Default: NULL
public.plans -> created_at (timestamptz) | Nullable: YES | Default: now()
public.plans -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.plans -> project_limit (int8) | Nullable: YES | Default: '0'::bigint
public.projects -> id (int8) | Nullable: NO | Default: NULL
public.projects -> user_id (uuid) | Nullable: YES | Default: NULL
public.projects -> name (text) | Nullable: YES | Default: NULL
public.projects -> domain (text) | Nullable: YES | Default: NULL
public.projects -> login (text) | Nullable: YES | Default: NULL
public.projects -> pass (text) | Nullable: YES | Default: NULL
public.projects -> status (bool) | Nullable: YES | Default: NULL
public.projects -> log (json) | Nullable: YES | Default: NULL
public.projects -> created_at (timestamptz) | Nullable: NO | Default: now()
public.projects -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.projects -> is_deleted (bool) | Nullable: YES | Default: false
public.projects -> default_language (text) | Nullable: YES | Default: NULL
public.projects -> token (text) | Nullable: YES | Default: NULL
public.projects -> wp_version (text) | Nullable: YES | Default: NULL
public.projects -> plugins (json) | Nullable: YES | Default: NULL
public.projects -> niche_selected (text) | Nullable: YES | Default: NULL
public.projects -> is_approved_on_adsense (bool) | Nullable: YES | Default: false
public.projects -> adsense_status (text) | Nullable: YES | Default: NULL
public.projects -> error (text) | Nullable: YES | Default: NULL
public.queue_metrics -> id (int8) | Nullable: NO | Default: nextval('queue_metrics_id_seq'::regclass)
public.queue_metrics -> queue_name (text) | Nullable: NO | Default: NULL
public.queue_metrics -> message_count (int4) | Nullable: NO | Default: NULL
public.queue_metrics -> recorded_at (timestamptz) | Nullable: YES | Default: now()
public.task_history -> id (int8) | Nullable: NO | Default: nextval('task_history_id_seq'::regclass)
public.task_history -> task_id (uuid) | Nullable: YES | Default: NULL
public.task_history -> user_id (uuid) | Nullable: YES | Default: NULL
public.task_history -> previous_status (text) | Nullable: YES | Default: NULL
public.task_history -> new_status (text) | Nullable: YES | Default: NULL
public.task_history -> details (text) | Nullable: YES | Default: NULL
public.task_history -> created_at (timestamptz) | Nullable: YES | Default: now()
public.task_templates -> id (int8) | Nullable: NO | Default: NULL
public.task_templates -> category_id (int8) | Nullable: YES | Default: NULL
public.task_templates -> name (text) | Nullable: YES | Default: NULL
public.task_templates -> description (text) | Nullable: YES | Default: NULL
public.task_templates -> order (int8) | Nullable: YES | Default: NULL
public.task_templates -> estimated_time (int8) | Nullable: YES | Default: NULL
public.task_templates -> is_active (bool) | Nullable: YES | Default: NULL
public.task_templates -> created_at (timestamptz) | Nullable: NO | Default: now()
public.task_templates -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.task_templates -> tags (_text) | Nullable: YES | Default: NULL
public.tasks -> id (uuid) | Nullable: NO | Default: gen_random_uuid()
public.tasks -> project_id (int8) | Nullable: YES | Default: NULL
public.tasks -> task_template_id (int8) | Nullable: YES | Default: NULL
public.tasks -> category_id (int8) | Nullable: YES | Default: NULL
public.tasks -> name (text) | Nullable: NO | Default: NULL
public.tasks -> description (text) | Nullable: YES | Default: NULL
public.tasks -> sort_order (int4) | Nullable: YES | Default: 0
public.tasks -> status (text) | Nullable: YES | Default: 'to_do'::text
public.tasks -> user_id (uuid) | Nullable: YES | Default: NULL
public.tasks -> started_at (timestamptz) | Nullable: YES | Default: NULL
public.tasks -> completed_at (timestamptz) | Nullable: YES | Default: NULL
public.tasks -> estimated_time (int4) | Nullable: YES | Default: NULL
public.tasks -> actual_time (int4) | Nullable: YES | Default: NULL
public.tasks -> completion_percentage (int4) | Nullable: YES | Default: 0
public.tasks -> notes (text) | Nullable: YES | Default: NULL
public.tasks -> created_at (timestamptz) | Nullable: YES | Default: now()
public.tasks -> updated_at (timestamptz) | Nullable: YES | Default: now()
public.tasks -> tags (_text) | Nullable: YES | Default: NULL
public.tasks_categories -> id (int8) | Nullable: NO | Default: NULL
public.tasks_categories -> name (text) | Nullable: YES | Default: NULL
public.tasks_categories -> description (text) | Nullable: YES | Default: NULL
public.tasks_categories -> order (int2) | Nullable: YES | Default: '0'::smallint
public.tasks_categories -> is_active (bool) | Nullable: YES | Default: true
public.tasks_categories -> created_at (timestamptz) | Nullable: NO | Default: now()
public.tasks_categories -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.tasks_tags -> id (int8) | Nullable: NO | Default: NULL
public.tasks_tags -> tag (text) | Nullable: YES | Default: NULL
public.tasks_tags -> created_at (timestamptz) | Nullable: NO | Default: now()
public.tasks_tags -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.test_message_logs -> log_id (int8) | Nullable: NO | Default: NULL
public.test_message_logs -> page_id (int8) | Nullable: NO | Default: NULL
public.test_message_logs -> user_id (text) | Nullable: NO | Default: NULL
public.test_message_logs -> message_id (text) | Nullable: YES | Default: NULL
public.test_message_logs -> status (text) | Nullable: YES | Default: NULL
public.test_message_logs -> error_message (text) | Nullable: YES | Default: NULL
public.test_message_logs -> sent_at (timestamp) | Nullable: YES | Default: NULL
public.test_message_logs -> delivered_at (timestamp) | Nullable: YES | Default: NULL
public.test_message_logs -> read_at (timestamp) | Nullable: YES | Default: NULL
public.test_message_logs -> created_at (timestamp) | Nullable: YES | Default: CURRENT_TIMESTAMP
public.test_message_logs -> flow_id (uuid) | Nullable: YES | Default: NULL
public.test_message_logs -> run_id (int8) | Nullable: YES | Default: NULL
public.test_message_logs -> flow_node_id (uuid) | Nullable: YES | Default: NULL
public.transactions -> id (int8) | Nullable: NO | Default: NULL
public.transactions -> plan_id (int8) | Nullable: YES | Default: NULL
public.transactions -> regular_price (numeric) | Nullable: YES | Default: NULL
public.transactions -> buyer_paid (numeric) | Nullable: YES | Default: NULL
public.transactions -> received (numeric) | Nullable: YES | Default: NULL
public.transactions -> platform_name (text) | Nullable: YES | Default: NULL
public.transactions -> payment_method (text) | Nullable: YES | Default: NULL
public.transactions -> seller_name (text) | Nullable: YES | Default: NULL
public.transactions -> transaction_code (text) | Nullable: YES | Default: NULL
public.transactions -> status (text) | Nullable: YES | Default: NULL
public.transactions -> timestamp_approved (timestamptz) | Nullable: YES | Default: NULL
public.transactions -> duration (int8) | Nullable: YES | Default: NULL
public.transactions -> type (text) | Nullable: YES | Default: NULL
public.transactions -> user_id (uuid) | Nullable: YES | Default: NULL
public.transactions -> created_at (timestamptz) | Nullable: YES | Default: now()
public.transactions -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.transactions -> product_name_original_purchase (text) | Nullable: YES | Default: NULL
public.transactions -> currency (text) | Nullable: YES | Default: NULL
public.transactions -> installments_number (int8) | Nullable: YES | Default: '1'::bigint
public.transactions -> src (text) | Nullable: YES | Default: NULL
public.transactions -> sck (text) | Nullable: YES | Default: NULL
public.transactions -> utm_source (text) | Nullable: YES | Default: NULL
public.transactions -> utm_medium (text) | Nullable: YES | Default: NULL
public.transactions -> utm_campaign (text) | Nullable: YES | Default: NULL
public.transactions -> utm_content (text) | Nullable: YES | Default: NULL
public.transactions -> utm_term (text) | Nullable: YES | Default: NULL
public.users -> id (uuid) | Nullable: NO | Default: NULL
public.users -> name (text) | Nullable: YES | Default: NULL
public.users -> email (text) | Nullable: YES | Default: NULL
public.users -> phone (text) | Nullable: YES | Default: NULL
public.users -> document (text) | Nullable: YES | Default: NULL
public.users -> image (text) | Nullable: YES | Default: NULL
public.users -> level (text) | Nullable: YES | Default: NULL
public.users -> created_at (timestamptz) | Nullable: NO | Default: now()
public.users -> updated_at (timestamptz) | Nullable: YES | Default: NULL
public.users -> country (text) | Nullable: YES | Default: NULL
public.users_keywords -> keyword_id (int8) | Nullable: NO | Default: NULL
public.users_keywords -> user_id (uuid) | Nullable: NO | Default: NULL
public.users_keywords -> created_at (timestamptz) | Nullable: NO | Default: now()
supabase_functions.hooks -> id (int8) | Nullable: NO | Default: nextval('supabase_functions.hooks_id_seq'::regclass)
supabase_functions.hooks -> hook_table_id (int4) | Nullable: NO | Default: NULL
supabase_functions.hooks -> hook_name (text) | Nullable: NO | Default: NULL
supabase_functions.hooks -> created_at (timestamptz) | Nullable: NO | Default: now()
supabase_functions.hooks -> request_id (int8) | Nullable: YES | Default: NULL
supabase_functions.migrations -> version (text) | Nullable: NO | Default: NULL
supabase_functions.migrations -> inserted_at (timestamptz) | Nullable: NO | Default: now()
supabase_migrations.schema_migrations -> version (text) | Nullable: NO | Default: NULL
supabase_migrations.schema_migrations -> statements (_text) | Nullable: YES | Default: NULL
supabase_migrations.schema_migrations -> name (text) | Nullable: YES | Default: NULL
supabase_migrations.seed_files -> path (text) | Nullable: NO | Default: NULL
supabase_migrations.seed_files -> hash (text) | Nullable: NO | Default: NULL

--- 5. CONSTRAINTS ---
auth.audit_log_entries (audit_log_entries_pkey) | p: PRIMARY KEY (id)
auth.flow_state (flow_state_pkey) | p: PRIMARY KEY (id)
auth.identities (identities_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.identities (identities_pkey) | p: PRIMARY KEY (id)
auth.identities (identities_provider_id_provider_unique) | u: UNIQUE (provider_id, provider)
auth.instances (instances_pkey) | p: PRIMARY KEY (id)
auth.mfa_amr_claims (mfa_amr_claims_session_id_fkey) | f: FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE
auth.mfa_amr_claims (amr_id_pk) | p: PRIMARY KEY (id)
auth.mfa_amr_claims (mfa_amr_claims_session_id_authentication_method_pkey) | u: UNIQUE (session_id, authentication_method)
auth.mfa_challenges (mfa_challenges_auth_factor_id_fkey) | f: FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE
auth.mfa_challenges (mfa_challenges_pkey) | p: PRIMARY KEY (id)
auth.mfa_factors (mfa_factors_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.mfa_factors (mfa_factors_pkey) | p: PRIMARY KEY (id)
auth.mfa_factors (mfa_factors_last_challenged_at_key) | u: UNIQUE (last_challenged_at)
auth.oauth_authorizations (oauth_authorizations_expires_at_future) | c: CHECK ((expires_at > created_at))
auth.oauth_authorizations (oauth_authorizations_authorization_code_length) | c: CHECK ((char_length(authorization_code) <= 255))
auth.oauth_authorizations (oauth_authorizations_code_challenge_length) | c: CHECK ((char_length(code_challenge) <= 128))
auth.oauth_authorizations (oauth_authorizations_resource_length) | c: CHECK ((char_length(resource) <= 2048))
auth.oauth_authorizations (oauth_authorizations_state_length) | c: CHECK ((char_length(state) <= 4096))
auth.oauth_authorizations (oauth_authorizations_scope_length) | c: CHECK ((char_length(scope) <= 4096))
auth.oauth_authorizations (oauth_authorizations_redirect_uri_length) | c: CHECK ((char_length(redirect_uri) <= 2048))
auth.oauth_authorizations (oauth_authorizations_client_id_fkey) | f: FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE
auth.oauth_authorizations (oauth_authorizations_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.oauth_authorizations (oauth_authorizations_pkey) | p: PRIMARY KEY (id)
auth.oauth_authorizations (oauth_authorizations_authorization_code_key) | u: UNIQUE (authorization_code)
auth.oauth_authorizations (oauth_authorizations_authorization_id_key) | u: UNIQUE (authorization_id)
auth.oauth_clients (oauth_clients_client_uri_length) | c: CHECK ((char_length(client_uri) <= 2048))
auth.oauth_clients (oauth_clients_logo_uri_length) | c: CHECK ((char_length(logo_uri) <= 2048))
auth.oauth_clients (oauth_clients_client_name_length) | c: CHECK ((char_length(client_name) <= 1024))
auth.oauth_clients (oauth_clients_pkey) | p: PRIMARY KEY (id)
auth.oauth_consents (oauth_consents_revoked_after_granted) | c: CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at)))
auth.oauth_consents (oauth_consents_scopes_length) | c: CHECK ((char_length(scopes) <= 2048))
auth.oauth_consents (oauth_consents_scopes_not_empty) | c: CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
auth.oauth_consents (oauth_consents_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.oauth_consents (oauth_consents_client_id_fkey) | f: FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE
auth.oauth_consents (oauth_consents_pkey) | p: PRIMARY KEY (id)
auth.oauth_consents (oauth_consents_user_client_unique) | u: UNIQUE (user_id, client_id)
auth.one_time_tokens (one_time_tokens_token_hash_check) | c: CHECK ((char_length(token_hash) > 0))
auth.one_time_tokens (one_time_tokens_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.one_time_tokens (one_time_tokens_pkey) | p: PRIMARY KEY (id)
auth.refresh_tokens (refresh_tokens_session_id_fkey) | f: FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE
auth.refresh_tokens (refresh_tokens_pkey) | p: PRIMARY KEY (id)
auth.refresh_tokens (refresh_tokens_token_unique) | u: UNIQUE (token)
auth.saml_providers (entity_id not empty) | c: CHECK ((char_length(entity_id) > 0))
auth.saml_providers (metadata_url not empty) | c: CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0)))
auth.saml_providers (metadata_xml not empty) | c: CHECK ((char_length(metadata_xml) > 0))
auth.saml_providers (saml_providers_sso_provider_id_fkey) | f: FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE
auth.saml_providers (saml_providers_pkey) | p: PRIMARY KEY (id)
auth.saml_providers (saml_providers_entity_id_key) | u: UNIQUE (entity_id)
auth.saml_relay_states (request_id not empty) | c: CHECK ((char_length(request_id) > 0))
auth.saml_relay_states (saml_relay_states_sso_provider_id_fkey) | f: FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE
auth.saml_relay_states (saml_relay_states_flow_state_id_fkey) | f: FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE
auth.saml_relay_states (saml_relay_states_pkey) | p: PRIMARY KEY (id)
auth.schema_migrations (schema_migrations_pkey) | p: PRIMARY KEY (version)
auth.sessions (sessions_oauth_client_id_fkey) | f: FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE
auth.sessions (sessions_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
auth.sessions (sessions_pkey) | p: PRIMARY KEY (id)
auth.sso_domains (domain not empty) | c: CHECK ((char_length(domain) > 0))
auth.sso_domains (sso_domains_sso_provider_id_fkey) | f: FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE
auth.sso_domains (sso_domains_pkey) | p: PRIMARY KEY (id)
auth.sso_providers (resource_id not empty) | c: CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
auth.sso_providers (sso_providers_pkey) | p: PRIMARY KEY (id)
auth.users (users_email_change_confirm_status_check) | c: CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
auth.users (users_pkey) | p: PRIMARY KEY (id)
auth.users (users_phone_key) | u: UNIQUE (phone)
pgmq.a_alvocast-messages (a_alvocast-messages_pkey) | p: PRIMARY KEY (msg_id)
pgmq.meta (meta_queue_name_key) | u: UNIQUE (queue_name)
pgmq.q_alvocast-messages (q_alvocast-messages_pkey) | p: PRIMARY KEY (msg_id)
public.admin_roles (admin_roles_pkey) | p: PRIMARY KEY (id)
public.admins (admins_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES users(id)
public.admins (admins_role_fkey) | f: FOREIGN KEY (role) REFERENCES admin_roles(id)
public.admins (admins_pkey) | p: PRIMARY KEY (user_id)
public.articles (articles_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.articles (articles_project_id_fkey) | f: FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
public.articles (articles_pkey) | p: PRIMARY KEY (id)
public.author_profile_images (author_profile_images_pkey) | p: PRIMARY KEY (id)
public.connections (connections_meta_app_id_fkey) | f: FOREIGN KEY (meta_app_id) REFERENCES meta_app_credentials(id) ON DELETE RESTRICT
public.connections (connections_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
public.connections (connections_pkey) | p: PRIMARY KEY (id)
public.conversations (conversations_page_id_user_id_fkey) | f: FOREIGN KEY (page_id, user_id) REFERENCES meta_subscribers(page_id, user_id) ON DELETE CASCADE
public.conversations (conversations_pkey) | p: PRIMARY KEY (id)
public.conversations (conversations_message_id_key) | u: UNIQUE (message_id)
public.domains (domains_alvobot_project_id_fkey) | f: FOREIGN KEY (alvobot_project_id) REFERENCES projects(id) ON DELETE SET NULL
public.domains (domains_pkey) | p: PRIMARY KEY (id)
public.flow_messages_mapping (flow_messages_mapping_pkey) | p: PRIMARY KEY (id)
public.google_accounts (fk_project) | f: FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
public.google_accounts (google_accounts_pkey) | p: PRIMARY KEY (id)
public.google_accounts (google_accounts_project_id_key) | u: UNIQUE (project_id)
public.google_ads_scraper (google_ads_scraper_pkey) | p: PRIMARY KEY ("creativeId")
public.google_ads_scraper_advertiser (google_ads_scraper_advertiser_pkey) | p: PRIMARY KEY ("advertiserId")
public.imported_transactions (imported_transactions_pkey) | p: PRIMARY KEY (id)
public.imported_transactions (imported_transactions_transaction_code_key) | u: UNIQUE (transaction_code)
public.keywords (keywords_pkey) | p: PRIMARY KEY (id, word)
public.keywords (unique_word) | u: UNIQUE (word)
public.keywords (keywords_id_key) | u: UNIQUE (id)
public.logs (logs_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.logs (logs_pkey) | p: PRIMARY KEY (id)
public.message_flows (message_flows_project_id_fkey) | f: FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
public.message_flows (message_flows_pkey) | p: PRIMARY KEY (id)
public.message_logs (message_logs_flow_id_fkey) | f: FOREIGN KEY (flow_id) REFERENCES message_flows(id) ON DELETE CASCADE
public.message_logs (message_logs_run_id_fkey) | f: FOREIGN KEY (run_id) REFERENCES message_runs(id) ON DELETE CASCADE
public.message_logs (message_logs_pkey) | p: PRIMARY KEY (id)
public.message_runs (message_runs_trigger_id_fkey) | f: FOREIGN KEY (trigger_id) REFERENCES message_triggers(id) ON DELETE CASCADE
public.message_runs (message_runs_flow_id_fkey) | f: FOREIGN KEY (flow_id) REFERENCES message_flows(id) ON DELETE SET NULL
public.message_runs (message_runs_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.message_runs (message_runs_pkey) | p: PRIMARY KEY (id)
public.message_triggers (message_triggers_flow_id_fkey) | f: FOREIGN KEY (flow_id) REFERENCES message_flows(id)
public.message_triggers (message_triggers_pkey) | p: PRIMARY KEY (id)
public.meta_app_credentials (meta_app_credentials_pkey) | p: PRIMARY KEY (id)
public.meta_app_credentials (meta_app_credentials_app_id_key) | u: UNIQUE (app_id)
public.meta_pages (meta_pages_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.meta_pages (meta_pages_connection_id_fkey) | f: FOREIGN KEY (connection_id) REFERENCES connections(id) ON DELETE CASCADE
public.meta_pages (meta_pages_pkey) | p: PRIMARY KEY (id)
public.meta_pages (meta_pages_user_page_unique) | u: UNIQUE (user_id, page_id)
public.meta_subscribers (meta_subscribers_pkey) | p: PRIMARY KEY (page_id, user_id)
public.orchestrator_config (orchestrator_config_pkey) | p: PRIMARY KEY (id)
public.plans (plans_pkey) | p: PRIMARY KEY (id)
public.plans (plans_id_key) | u: UNIQUE (id)
public.projects (projects_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.projects (projects_pkey) | p: PRIMARY KEY (id)
public.queue_metrics (queue_metrics_pkey) | p: PRIMARY KEY (id)
public.task_history (task_history_task_id_fkey) | f: FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
public.task_history (task_history_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id)
public.task_history (task_history_pkey) | p: PRIMARY KEY (id)
public.task_templates (task_templates_category_id_fkey) | f: FOREIGN KEY (category_id) REFERENCES tasks_categories(id)
public.task_templates (task_templates_pkey) | p: PRIMARY KEY (id)
public.tasks (tasks_completion_percentage_check) | c: CHECK (((completion_percentage >= 0) AND (completion_percentage <= 100)))
public.tasks (tasks_user_id_fkey1) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id)
public.tasks (tasks_task_template_id_fkey) | f: FOREIGN KEY (task_template_id) REFERENCES task_templates(id) ON DELETE SET NULL
public.tasks (tasks_project_id_fkey) | f: FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
public.tasks (tasks_category_id_fkey) | f: FOREIGN KEY (category_id) REFERENCES tasks_categories(id) ON DELETE CASCADE
public.tasks (tasks_pkey1) | p: PRIMARY KEY (id)
public.tasks_categories (tasks_categories_pkey) | p: PRIMARY KEY (id)
public.tasks_tags (tasks_tags_pkey) | p: PRIMARY KEY (id)
public.test_message_logs (test_message_logs_run_id_fkey) | f: FOREIGN KEY (run_id) REFERENCES message_runs(id) ON DELETE CASCADE
public.test_message_logs (test_message_logs_flow_id_fkey) | f: FOREIGN KEY (flow_id) REFERENCES message_flows(id) ON DELETE CASCADE
public.test_message_logs (meta_test_message_logs_pkey) | p: PRIMARY KEY (log_id)
public.transactions (transactions_plan_id_fkey) | f: FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE SET NULL
public.transactions (transactions_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.transactions (transactions_pkey) | p: PRIMARY KEY (id)
public.transactions (transactions_id_key) | u: UNIQUE (id)
public.users (users_id_fkey) | f: FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
public.users (users_pkey) | p: PRIMARY KEY (id)
public.users_keywords (users_keywords_user_id_fkey) | f: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
public.users_keywords (users_keywords_keyword_id_fkey) | f: FOREIGN KEY (keyword_id) REFERENCES keywords(id) ON DELETE CASCADE
public.users_keywords (users_keywords_pkey) | p: PRIMARY KEY (keyword_id, user_id)
supabase_functions.hooks (hooks_pkey) | p: PRIMARY KEY (id)
supabase_functions.migrations (migrations_pkey) | p: PRIMARY KEY (version)
supabase_migrations.schema_migrations (schema_migrations_pkey) | p: PRIMARY KEY (version)
supabase_migrations.seed_files (seed_files_pkey) | p: PRIMARY KEY (path)

--- 6. INDEXES ---
CREATE UNIQUE INDEX audit_log_entries_pkey ON auth.audit_log_entries USING btree (id);
CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);
CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);
CREATE UNIQUE INDEX flow_state_pkey ON auth.flow_state USING btree (id);
CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);
CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);
CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);
CREATE UNIQUE INDEX identities_pkey ON auth.identities USING btree (id);
CREATE UNIQUE INDEX identities_provider_id_provider_unique ON auth.identities USING btree (provider_id, provider);
CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);
CREATE UNIQUE INDEX instances_pkey ON auth.instances USING btree (id);
CREATE UNIQUE INDEX amr_id_pk ON auth.mfa_amr_claims USING btree (id);
CREATE UNIQUE INDEX mfa_amr_claims_session_id_authentication_method_pkey ON auth.mfa_amr_claims USING btree (session_id, authentication_method);
CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);
CREATE UNIQUE INDEX mfa_challenges_pkey ON auth.mfa_challenges USING btree (id);
CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);
CREATE UNIQUE INDEX mfa_factors_last_challenged_at_key ON auth.mfa_factors USING btree (last_challenged_at);
CREATE UNIQUE INDEX mfa_factors_pkey ON auth.mfa_factors USING btree (id);
CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);
CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);
CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);
CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);
CREATE UNIQUE INDEX oauth_authorizations_authorization_code_key ON auth.oauth_authorizations USING btree (authorization_code);
CREATE UNIQUE INDEX oauth_authorizations_authorization_id_key ON auth.oauth_authorizations USING btree (authorization_id);
CREATE UNIQUE INDEX oauth_authorizations_pkey ON auth.oauth_authorizations USING btree (id);
CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);
CREATE UNIQUE INDEX oauth_clients_pkey ON auth.oauth_clients USING btree (id);
CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);
CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);
CREATE UNIQUE INDEX oauth_consents_pkey ON auth.oauth_consents USING btree (id);
CREATE UNIQUE INDEX oauth_consents_user_client_unique ON auth.oauth_consents USING btree (user_id, client_id);
CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);
CREATE UNIQUE INDEX one_time_tokens_pkey ON auth.one_time_tokens USING btree (id);
CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);
CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);
CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);
CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);
CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);
CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);
CREATE UNIQUE INDEX refresh_tokens_pkey ON auth.refresh_tokens USING btree (id);
CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);
CREATE UNIQUE INDEX refresh_tokens_token_unique ON auth.refresh_tokens USING btree (token);
CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);
CREATE UNIQUE INDEX saml_providers_entity_id_key ON auth.saml_providers USING btree (entity_id);
CREATE UNIQUE INDEX saml_providers_pkey ON auth.saml_providers USING btree (id);
CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);
CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);
CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);
CREATE UNIQUE INDEX saml_relay_states_pkey ON auth.saml_relay_states USING btree (id);
CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);
CREATE UNIQUE INDEX schema_migrations_pkey ON auth.schema_migrations USING btree (version);
CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);
CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);
CREATE UNIQUE INDEX sessions_pkey ON auth.sessions USING btree (id);
CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);
CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);
CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));
CREATE UNIQUE INDEX sso_domains_pkey ON auth.sso_domains USING btree (id);
CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);
CREATE UNIQUE INDEX sso_providers_pkey ON auth.sso_providers USING btree (id);
CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));
CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);
CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);
CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));
CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);
CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);
CREATE UNIQUE INDEX users_phone_key ON auth.users USING btree (phone);
CREATE UNIQUE INDEX users_pkey ON auth.users USING btree (id);
CREATE INDEX _http_response_created_idx ON net._http_response USING btree (created);
CREATE UNIQUE INDEX "a_alvocast-messages_pkey" ON pgmq."a_alvocast-messages" USING btree (msg_id);
CREATE INDEX "archived_at_idx_alvocast-messages" ON pgmq."a_alvocast-messages" USING btree (archived_at);
CREATE UNIQUE INDEX meta_queue_name_key ON pgmq.meta USING btree (queue_name);
CREATE UNIQUE INDEX "q_alvocast-messages_pkey" ON pgmq."q_alvocast-messages" USING btree (msg_id);
CREATE INDEX "q_alvocast-messages_vt_idx" ON pgmq."q_alvocast-messages" USING btree (vt);
CREATE UNIQUE INDEX admin_roles_pkey ON public.admin_roles USING btree (id);
CREATE UNIQUE INDEX admins_pkey ON public.admins USING btree (user_id);
CREATE INDEX idx_admins_role ON public.admins USING btree (role);
CREATE UNIQUE INDEX articles_pkey ON public.articles USING btree (id);
CREATE INDEX idx_articles_created_at ON public.articles USING btree (created_at DESC);
CREATE INDEX idx_articles_project_id ON public.articles USING btree (project_id);
CREATE INDEX idx_articles_status ON public.articles USING btree (status);
CREATE INDEX idx_articles_user_id ON public.articles USING btree (user_id);
CREATE INDEX idx_articles_user_id_keyword_used ON public.articles USING btree (user_id, keyword_used);
CREATE UNIQUE INDEX author_profile_images_pkey ON public.author_profile_images USING btree (id);
CREATE UNIQUE INDEX connections_pkey ON public.connections USING btree (id);
CREATE INDEX idx_connections_meta_app_id ON public.connections USING btree (meta_app_id);
CREATE INDEX idx_connections_user_id ON public.connections USING btree (user_id);
CREATE UNIQUE INDEX conversations_message_id_key ON public.conversations USING btree (message_id);
CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id);
CREATE INDEX idx_conversations_created_at ON public.conversations USING btree (created_at DESC);
CREATE INDEX idx_conversations_is_from_user ON public.conversations USING btree (is_from_user);
CREATE INDEX idx_conversations_page_id ON public.conversations USING btree (page_id);
CREATE INDEX idx_conversations_thread ON public.conversations USING btree (page_id, user_id, created_at DESC);
CREATE UNIQUE INDEX domains_pkey ON public.domains USING btree (id);
CREATE INDEX idx_domains_alvobot_project_id ON public.domains USING btree (alvobot_project_id);
CREATE UNIQUE INDEX flow_messages_mapping_pkey ON public.flow_messages_mapping USING btree (id);
CREATE UNIQUE INDEX google_accounts_pkey ON public.google_accounts USING btree (id);
CREATE UNIQUE INDEX google_accounts_project_id_key ON public.google_accounts USING btree (project_id);
CREATE INDEX idx_ga_google_user_id ON public.google_accounts USING btree (google_user_id);
CREATE UNIQUE INDEX google_ads_scraper_pkey ON public.google_ads_scraper USING btree ("creativeId");
CREATE UNIQUE INDEX google_ads_scraper_advertiser_pkey ON public.google_ads_scraper_advertiser USING btree ("advertiserId");
CREATE UNIQUE INDEX imported_transactions_pkey ON public.imported_transactions USING btree (id);
CREATE UNIQUE INDEX imported_transactions_transaction_code_key ON public.imported_transactions USING btree (transaction_code);
CREATE INDEX idx_keywords_ranking_filters ON public.keywords USING btree (search_volume, cpc_min, cpc_max);
CREATE UNIQUE INDEX keywords_id_key ON public.keywords USING btree (id);
CREATE UNIQUE INDEX keywords_pkey ON public.keywords USING btree (id, word);
CREATE UNIQUE INDEX unique_word ON public.keywords USING btree (word);
CREATE INDEX idx_logs_user_id ON public.logs USING btree (user_id);
CREATE UNIQUE INDEX logs_pkey ON public.logs USING btree (id);
CREATE INDEX idx_message_flows_id ON public.message_flows USING btree (id) INCLUDE (name, project_id);
CREATE INDEX idx_message_flows_id_project ON public.message_flows USING btree (id, project_id, name) WHERE (is_active = true);
CREATE INDEX idx_message_flows_name_gin ON public.message_flows USING gin (name gin_trgm_ops);
CREATE INDEX idx_message_flows_project_id ON public.message_flows USING btree (project_id);
CREATE UNIQUE INDEX message_flows_pkey ON public.message_flows USING btree (id);
CREATE INDEX idx_logs_flow_id ON public.message_logs USING btree (flow_id) WHERE (flow_id IS NOT NULL);
CREATE INDEX idx_logs_flow_node ON public.message_logs USING btree (flow_node_id, created_at DESC) WHERE (flow_node_id IS NOT NULL);
CREATE INDEX idx_logs_message_id ON public.message_logs USING btree (message_id) WHERE (message_id IS NOT NULL);
CREATE INDEX idx_logs_page_status_created ON public.message_logs USING btree (page_id, status, created_at DESC);
CREATE INDEX idx_logs_run_status_created ON public.message_logs USING btree (run_id, status, created_at DESC) WHERE (run_id IS NOT NULL);
CREATE INDEX idx_logs_status_timestamps ON public.message_logs USING btree (status, created_at DESC) WHERE (status = ANY (ARRAY['sent'::text, 'delivered'::text, 'failed'::text]));
CREATE INDEX idx_logs_user_created ON public.message_logs USING btree (user_id, created_at DESC) INCLUDE (status, message_id);
CREATE INDEX idx_message_logs_error_code ON public.message_logs USING btree (error_code) WHERE (error_code IS NOT NULL);
CREATE INDEX idx_message_logs_fb_headers ON public.message_logs USING gin (fb_headers) WHERE (fb_headers IS NOT NULL);
CREATE INDEX idx_message_logs_on_run_id ON public.message_logs USING btree (run_id);
CREATE INDEX idx_message_logs_on_run_id_and_status ON public.message_logs USING btree (run_id, status) WHERE (status = 'error'::text);
CREATE UNIQUE INDEX message_logs_pkey ON public.message_logs USING btree (id);
CREATE INDEX idx_message_runs_created_at ON public.message_runs USING btree (created_at) WHERE (deleted_at IS NULL);
CREATE INDEX idx_message_runs_error_summary ON public.message_runs USING gin (error_summary);
CREATE INDEX idx_message_runs_flow_date ON public.message_runs USING btree (flow_id, created_at DESC) WHERE (deleted_at IS NULL);
CREATE INDEX idx_message_runs_flow_id ON public.message_runs USING btree (flow_id);
CREATE INDEX idx_message_runs_high_errors ON public.message_runs USING btree (created_at DESC) WHERE ((deleted_at IS NULL) AND (total_messages > 0) AND (((failure_count)::numeric / (total_messages)::numeric) > 0.5));
CREATE INDEX idx_message_runs_pending ON public.message_runs USING btree (status, next_step_at, start_at) WHERE (deleted_at IS NULL);
CREATE INDEX idx_message_runs_status_date ON public.message_runs USING btree (status, created_at DESC) WHERE (deleted_at IS NULL);
CREATE INDEX idx_message_runs_trigger_id ON public.message_runs USING btree (trigger_id);
CREATE INDEX idx_message_runs_user_created ON public.message_runs USING btree (user_id, created_at DESC) WHERE (deleted_at IS NULL);
CREATE INDEX idx_message_runs_user_id ON public.message_runs USING btree (user_id);
CREATE UNIQUE INDEX message_runs_pkey ON public.message_runs USING btree (id);
CREATE INDEX idx_message_triggers_flow_id ON public.message_triggers USING btree (flow_id);
CREATE UNIQUE INDEX message_triggers_pkey ON public.message_triggers USING btree (id);
CREATE UNIQUE INDEX meta_app_credentials_app_id_key ON public.meta_app_credentials USING btree (app_id);
CREATE UNIQUE INDEX meta_app_credentials_pkey ON public.meta_app_credentials USING btree (id);
CREATE INDEX idx_meta_pages_active ON public.meta_pages USING btree (is_active);
CREATE INDEX idx_meta_pages_connection_id ON public.meta_pages USING btree (connection_id);
CREATE INDEX idx_meta_pages_page_id ON public.meta_pages USING btree (page_id, page_name);
CREATE UNIQUE INDEX meta_pages_pkey ON public.meta_pages USING btree (id);
CREATE UNIQUE INDEX meta_pages_user_page_unique ON public.meta_pages USING btree (user_id, page_id);
CREATE INDEX idx_meta_subscribers_active ON public.meta_subscribers USING btree (is_active);
CREATE INDEX idx_meta_subscribers_page_id ON public.meta_subscribers USING btree (page_id);
CREATE INDEX idx_meta_subscribers_user_id ON public.meta_subscribers USING btree (user_id);
CREATE INDEX idx_subscribers_window_active ON public.meta_subscribers USING btree (page_id, window_expires_at);
CREATE UNIQUE INDEX meta_subscribers_pkey ON public.meta_subscribers USING btree (page_id, user_id);
CREATE UNIQUE INDEX orchestrator_config_pkey ON public.orchestrator_config USING btree (id);
CREATE UNIQUE INDEX plans_id_key ON public.plans USING btree (id);
CREATE UNIQUE INDEX plans_pkey ON public.plans USING btree (id);
CREATE INDEX idx_projects_id ON public.projects USING btree (id) INCLUDE (name);
CREATE INDEX idx_projects_id_name ON public.projects USING btree (id, name, domain) WHERE (is_deleted = false);
CREATE INDEX idx_projects_name_gin ON public.projects USING gin (name gin_trgm_ops);
CREATE INDEX idx_projects_user_id ON public.projects USING btree (user_id);
CREATE UNIQUE INDEX projects_pkey ON public.projects USING btree (id);
CREATE INDEX idx_queue_metrics_queue_name ON public.queue_metrics USING btree (queue_name);
CREATE INDEX idx_queue_metrics_recorded_at ON public.queue_metrics USING btree (recorded_at);
CREATE UNIQUE INDEX queue_metrics_pkey ON public.queue_metrics USING btree (id);
CREATE INDEX idx_task_history_task ON public.task_history USING btree (task_id);
CREATE INDEX idx_task_history_user_id ON public.task_history USING btree (user_id);
CREATE UNIQUE INDEX task_history_pkey ON public.task_history USING btree (id);
CREATE INDEX idx_task_templates_category ON public.task_templates USING btree (category_id);
CREATE UNIQUE INDEX task_templates_pkey ON public.task_templates USING btree (id);
CREATE INDEX idx_tasks_category_id ON public.tasks USING btree (category_id);
CREATE INDEX idx_tasks_project ON public.tasks USING btree (project_id);
CREATE INDEX idx_tasks_status ON public.tasks USING btree (status);
CREATE INDEX idx_tasks_task_template_id ON public.tasks USING btree (task_template_id);
CREATE INDEX idx_tasks_user_id ON public.tasks USING btree (user_id);
CREATE UNIQUE INDEX tasks_pkey1 ON public.tasks USING btree (id);
CREATE UNIQUE INDEX tasks_categories_pkey ON public.tasks_categories USING btree (id);
CREATE UNIQUE INDEX tasks_tags_pkey ON public.tasks_tags USING btree (id);
CREATE INDEX idx_test_message_logs_flow_id_status ON public.test_message_logs USING btree (flow_id, status);
CREATE INDEX idx_test_message_logs_run_id ON public.test_message_logs USING btree (run_id);
CREATE INDEX idx_test_message_logs_status ON public.test_message_logs USING btree (status);
CREATE INDEX idx_test_message_logs_status_run ON public.test_message_logs USING btree (run_id, status);
CREATE UNIQUE INDEX meta_test_message_logs_pkey ON public.test_message_logs USING btree (log_id);
CREATE INDEX idx_transactions_plan_id ON public.transactions USING btree (plan_id);
CREATE INDEX idx_transactions_status_timestamp ON public.transactions USING btree (status, timestamp_approved DESC);
CREATE INDEX idx_transactions_user_id ON public.transactions USING btree (user_id);
CREATE UNIQUE INDEX transactions_id_key ON public.transactions USING btree (id);
CREATE UNIQUE INDEX transactions_pkey ON public.transactions USING btree (id);
CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);
CREATE INDEX idx_users_keywords_created_at ON public.users_keywords USING btree (created_at DESC);
CREATE INDEX idx_users_keywords_user_id ON public.users_keywords USING btree (user_id);
CREATE UNIQUE INDEX users_keywords_pkey ON public.users_keywords USING btree (keyword_id, user_id);
CREATE UNIQUE INDEX hooks_pkey ON supabase_functions.hooks USING btree (id);
CREATE INDEX supabase_functions_hooks_h_table_id_h_name_idx ON supabase_functions.hooks USING btree (hook_table_id, hook_name);
CREATE INDEX supabase_functions_hooks_request_id_idx ON supabase_functions.hooks USING btree (request_id);
CREATE UNIQUE INDEX migrations_pkey ON supabase_functions.migrations USING btree (version);
CREATE UNIQUE INDEX schema_migrations_pkey ON supabase_migrations.schema_migrations USING btree (version);
CREATE UNIQUE INDEX seed_files_pkey ON supabase_migrations.seed_files USING btree (path)

--- 7. VIEWS ---
CREATE OR REPLACE VIEW extensions.hypopg_hidden_indexes AS

CREATE OR REPLACE VIEW extensions.hypopg_list_indexes AS

CREATE OR REPLACE VIEW extensions.pg_stat_statements AS

CREATE OR REPLACE VIEW extensions.pg_stat_statements_info AS SELECT dealloc,
    stats_reset
   FROM pg_stat_statements_info() pg_stat_statements_info(dealloc, stats_reset);

CREATE OR REPLACE VIEW public.all_transactions_view AS SELECT transactions.id,
    transactions.plan_id,
    transactions.regular_price,
    transactions.buyer_paid,
    transactions.received,
    transactions.platform_name,
    transactions.payment_method,
    transactions.seller_name,
    transactions.transaction_code,
    transactions.status,
    transactions.timestamp_approved,
    transactions.duration,
    transactions.type,
    transactions.user_id,
    transactions.created_at,
    transactions.updated_at,
    transactions.product_name_original_purchase,
    transactions.currency,
    transactions.installments_number,
    plans.monthly_credits,
    plans.project_limit,
    plans.name AS plan_name,
        CASE
            WHEN ((now() < (transactions.timestamp_approved + ((transactions.duration)::double precision * '1 mon'::interval))) AND ((transactions.status = 'approved'::text) OR (transactions.status = 'completed'::text))) THEN true
            ELSE false
        END AS is_active,
        CASE
            WHEN ((date_trunc('month'::text, now()) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval)) < now()) THEN (date_trunc('month'::text, now()) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
            ELSE (date_trunc('month'::text, (now() - '1 mon'::interval)) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
        END AS start_date_adjusted
   FROM (transactions
     LEFT JOIN plans ON ((transactions.plan_id = plans.id)));

CREATE OR REPLACE VIEW public.dashboard AS SELECT ( SELECT count(*) AS count
           FROM users) AS users_count,
    ( SELECT count(*) AS count
           FROM projects) AS projects_count,
    ( SELECT count(*) AS count
           FROM keywords) AS keywords_count,
    ( SELECT count(*) AS count
           FROM articles) AS articles_count,
    ( SELECT count(*) AS count
           FROM tasks) AS tasks_count;

CREATE OR REPLACE VIEW public.meta_page_subs_count AS SELECT mp.id,
    mp.page_id,
    mp.page_name,
    mp.access_token,
    mp.image,
    mp.is_active,
    mp.connection_id,
    count(ms.user_id) AS subscriber_count,
    count(
        CASE
            WHEN (ms.is_active = true) THEN 1
            ELSE NULL::integer
        END) AS active_subscribers,
    count(
        CASE
            WHEN (ms.is_active = false) THEN 1
            ELSE NULL::integer
        END) AS inactive_subscribers
   FROM (meta_pages mp
     LEFT JOIN meta_subscribers ms ON ((mp.page_id = ms.page_id)))
  GROUP BY mp.id, mp.page_id, mp.access_token, mp.image, mp.is_active, mp.connection_id, mp.page_name;

CREATE OR REPLACE VIEW public.monthly_keywords_ranking AS WITH keywords_counts AS (
         SELECT uk.user_id,
            count(DISTINCT uk.keyword_id) AS total_keywords
           FROM (users_keywords uk
             JOIN keywords k ON ((uk.keyword_id = k.id)))
          WHERE ((date_trunc('month'::text, uk.created_at) = date_trunc('month'::text, now())) AND (k.search_volume >= 1000) AND (k.cpc_min IS NOT NULL) AND (k.cpc_max IS NOT NULL) AND (k.cpc_min <= 0.10) AND (k.cpc_max >= (k.cpc_min * (10)::numeric)))
          GROUP BY uk.user_id
        ), articles_counts AS (
         SELECT a.user_id,
            count(DISTINCT a.id) AS total_articles
           FROM articles a
          WHERE (date_trunc('month'::text, a.created_at) = date_trunc('month'::text, now()))
          GROUP BY a.user_id
        )
 SELECT u.id AS user_id,
    u.name AS user_name,
    u.email AS user_email,
    COALESCE(kc.total_keywords, (0)::bigint) AS total_keywords,
    COALESCE(ac.total_articles, (0)::bigint) AS total_articles
   FROM ((users u
     LEFT JOIN keywords_counts kc ON ((u.id = kc.user_id)))
     LEFT JOIN articles_counts ac ON ((u.id = ac.user_id)))
  ORDER BY COALESCE(kc.total_keywords, (0)::bigint) DESC;

CREATE OR REPLACE VIEW public.projects_with_article_count AS SELECT p.id,
    p.user_id,
    p.name,
    p.domain,
    p.login,
    p.pass,
    p.status,
    p.created_at,
    p.updated_at,
    p.is_deleted,
    p.default_language,
    p.adsense_status,
    count(a.id) AS article_count,
    max(a.created_at) AS last_article_created_at,
    ga.google_user_id,
    ga.google_email,
    ga.token_expiry AS ga_token_expiry,
    ga.scopes AS ga_scopes,
    ga.last_token_check_status AS ga_last_token_check_status,
    ga.last_token_check_at AS ga_last_token_check_at,
    ga.created_at AS ga_created_at,
    ga.updated_at AS ga_updated_at
   FROM ((projects p
     LEFT JOIN articles a ON ((p.id = a.project_id)))
     LEFT JOIN google_accounts ga ON ((p.id = ga.project_id)))
  GROUP BY p.id, p.user_id, p.name, p.domain, p.login, p.pass, p.status, p.created_at, p.updated_at, p.is_deleted, p.default_language, p.adsense_status, ga.google_user_id, ga.google_email, ga.token_expiry, ga.scopes, ga.last_token_check_status, ga.last_token_check_at, ga.created_at, ga.updated_at;

CREATE OR REPLACE VIEW public.random_keywords_view AS SELECT id,
    word,
    search_volume,
    cpc_min,
    cpc_max,
    visibility,
    created_at,
    updated_at,
    competition,
    language,
    country
   FROM keywords
  ORDER BY (random());

CREATE OR REPLACE VIEW public.transactions_view AS SELECT transactions.id,
    transactions.plan_id,
    transactions.regular_price,
    transactions.buyer_paid,
    transactions.received,
    transactions.platform_name,
    transactions.payment_method,
    transactions.seller_name,
    transactions.transaction_code,
    transactions.status,
    transactions.timestamp_approved,
    transactions.duration,
    transactions.type,
    transactions.user_id,
    transactions.created_at,
    transactions.updated_at,
    transactions.product_name_original_purchase,
    transactions.currency,
    transactions.installments_number,
    plans.monthly_credits,
    plans.project_limit,
        CASE
            WHEN ((date_trunc('month'::text, now()) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval)) < now()) THEN (date_trunc('month'::text, now()) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
            ELSE (date_trunc('month'::text, (now() - '1 mon'::interval)) + (((EXTRACT(day FROM transactions.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
        END AS start_date_adjusted
   FROM (transactions
     LEFT JOIN plans ON ((transactions.plan_id = plans.id)))
  WHERE ((now() < (transactions.timestamp_approved + ((transactions.duration)::double precision * '1 mon'::interval))) AND ((transactions.status = 'approved'::text) OR (transactions.status = 'completed'::text)));

CREATE OR REPLACE VIEW public.user_transactions_view AS WITH active_transactions AS (
         SELECT t.user_id,
            t.timestamp_approved,
            t.duration,
            (t.timestamp_approved + ((t.duration || ' months'::text))::interval) AS expiration_date,
            pl.name AS plan_name,
            pl.monthly_credits,
            pl.project_limit,
            row_number() OVER (PARTITION BY t.user_id ORDER BY t.timestamp_approved DESC) AS row_num
           FROM (transactions t
             JOIN plans pl ON ((t.plan_id = pl.id)))
          WHERE (((t.status = 'completed'::text) OR (t.status = 'approved'::text)) AND (t.timestamp_approved IS NOT NULL) AND ((t.timestamp_approved + ((t.duration || ' months'::text))::interval) >= CURRENT_TIMESTAMP))
        )
 SELECT au.id AS user_id,
    au.email,
    pu.name,
    pu.phone,
    pu.document,
    pu.country,
    au.created_at,
    au.updated_at,
    ( SELECT count(p.id) AS count
           FROM projects p
          WHERE ((p.user_id = au.id) AND (p.is_deleted = false))) AS active_projects_count,
        CASE
            WHEN (at.timestamp_approved IS NOT NULL) THEN true
            ELSE false
        END AS has_active_plan,
    at.plan_name AS active_plan_name,
    at.monthly_credits AS active_plan_monthly_credits,
    at.project_limit AS active_plan_project_limit,
    at.expiration_date AS plan_expiration_date,
        CASE
            WHEN (at.timestamp_approved IS NOT NULL) THEN
            CASE
                WHEN (EXTRACT(day FROM at.timestamp_approved) <= EXTRACT(day FROM CURRENT_TIMESTAMP)) THEN (date_trunc('month'::text, CURRENT_TIMESTAMP) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
                ELSE (date_trunc('month'::text, (CURRENT_TIMESTAMP - '1 mon'::interval)) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
            END
            ELSE NULL::timestamp with time zone
        END AS current_cycle_start,
        CASE
            WHEN (at.timestamp_approved IS NOT NULL) THEN
            CASE
                WHEN (EXTRACT(day FROM at.timestamp_approved) <= EXTRACT(day FROM CURRENT_TIMESTAMP)) THEN (date_trunc('month'::text, (CURRENT_TIMESTAMP + '1 mon'::interval)) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
                ELSE (date_trunc('month'::text, CURRENT_TIMESTAMP) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
            END
            ELSE NULL::timestamp with time zone
        END AS current_cycle_end,
    ( SELECT count(a.id) AS count
           FROM articles a
          WHERE ((a.user_id = au.id) AND
                CASE
                    WHEN (at.timestamp_approved IS NOT NULL) THEN ((a.created_at >=
                    CASE
                        WHEN (EXTRACT(day FROM at.timestamp_approved) <= EXTRACT(day FROM CURRENT_TIMESTAMP)) THEN (date_trunc('month'::text, CURRENT_TIMESTAMP) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
                        ELSE (date_trunc('month'::text, (CURRENT_TIMESTAMP - '1 mon'::interval)) + (((EXTRACT(day FROM at.timestamp_approved) - (1)::numeric))::double precision * '1 day'::interval))
                    END) AND (a.created_at < CURRENT_TIMESTAMP))
                    ELSE false
                END)) AS current_cycle_articles_count,
    ( SELECT jsonb_agg(jsonb_build_object('id', t.id, 'plan_id', t.plan_id, 'plan_name', pl.name, 'regular_price', t.regular_price, 'buyer_paid', t.buyer_paid, 'received', t.received, 'platform_name', t.platform_name, 'payment_method', t.payment_method, 'transaction_code', t.transaction_code, 'status', t.status, 'timestamp_approved', t.timestamp_approved, 'duration', t.duration, 'type', t.type, 'created_at', t.created_at, 'expiration_date',
                CASE
                    WHEN (t.timestamp_approved IS NOT NULL) THEN (t.timestamp_approved + ((t.duration || ' months'::text))::interval)
                    ELSE NULL::timestamp with time zone
                END)) AS jsonb_agg
           FROM (transactions t
             LEFT JOIN plans pl ON ((t.plan_id = pl.id)))
          WHERE (t.user_id = au.id)) AS transactions
   FROM ((auth.users au
     LEFT JOIN users pu ON ((au.id = pu.id)))
     LEFT JOIN active_transactions at ON (((au.id = at.user_id) AND (at.row_num = 1))))
  WHERE (au.deleted_at IS NULL);

CREATE OR REPLACE VIEW public.users_keywords_articles AS WITH user_active_plan AS (
         SELECT t.user_id,
                CASE
                    WHEN ((date_trunc('month'::text, now()) + make_interval(days => ((EXTRACT(day FROM t.timestamp_approved))::integer - 1))) < now()) THEN (date_trunc('month'::text, now()) + make_interval(days => ((EXTRACT(day FROM t.timestamp_approved))::integer - 1)))
                    ELSE (date_trunc('month'::text, (now() - '1 mon'::interval)) + make_interval(days => ((EXTRACT(day FROM t.timestamp_approved))::integer - 1)))
                END AS start_date_adjusted
           FROM transactions t
          WHERE ((now() < (t.timestamp_approved + make_interval(months => (t.duration)::integer))) AND (t.status = ANY (ARRAY['approved'::text, 'completed'::text])))
        ), keywords_count AS (
         SELECT uk.user_id,
            count(*) AS total
           FROM (users_keywords uk
             JOIN user_active_plan uap ON ((uk.user_id = uap.user_id)))
          WHERE (uk.created_at >= uap.start_date_adjusted)
          GROUP BY uk.user_id
        ), articles_count AS (
         SELECT a.user_id,
            count(DISTINCT a.id) AS total
           FROM (articles a
             JOIN user_active_plan uap ON ((a.user_id = uap.user_id)))
          WHERE (a.created_at >= uap.start_date_adjusted)
          GROUP BY a.user_id
        )
 SELECT u.id AS user_id,
    u.name AS user_name,
    u.email AS user_email,
    COALESCE(kc.total, (0)::bigint) AS total_keywords,
    COALESCE(ac.total, (0)::bigint) AS total_articles
   FROM ((users u
     LEFT JOIN keywords_count kc ON ((u.id = kc.user_id)))
     LEFT JOIN articles_count ac ON ((u.id = ac.user_id)))
  WHERE (u.id = auth.uid())
  ORDER BY COALESCE(kc.total, (0)::bigint) DESC;

CREATE OR REPLACE VIEW public.users_keywords_view AS WITH article_counts AS (
         SELECT a.user_id,
            a.keyword_used,
            count(*) AS total
           FROM articles a
          GROUP BY a.user_id, a.keyword_used
        )
 SELECT k.id,
    k.word,
    k.search_volume,
    k.cpc_min,
    k.cpc_max,
    k.visibility,
    k.created_at,
    k.updated_at,
    k.competition,
    k.language,
    k.country,
    uk.user_id AS uk_user_id,
    COALESCE(ac.total, (0)::bigint) AS keyword_usage_count
   FROM ((users_keywords uk
     JOIN keywords k ON ((uk.keyword_id = k.id)))
     LEFT JOIN article_counts ac ON (((uk.user_id = ac.user_id) AND (k.word = ac.keyword_used))));

CREATE OR REPLACE VIEW public.v_tasks AS SELECT t.id,
    t.name,
    t.description,
    t.status,
    t.project_id,
    p.name AS project_name,
    t.category_id,
    t.task_template_id,
    t.sort_order,
    t.user_id,
    t.started_at,
    t.completed_at,
    t.estimated_time,
    t.actual_time,
    t.completion_percentage,
    t.notes,
    t.tags,
    t.created_at,
    t.updated_at
   FROM (tasks t
     LEFT JOIN projects p ON ((t.project_id = p.id)))
  WHERE ((p.is_deleted = false) OR (p.is_deleted IS NULL));

CREATE OR REPLACE VIEW public.vw_google_ads_domain_analytics AS WITH domain_level_data AS (
         SELECT
                CASE
                    WHEN ("substring"(url_list.url, 'https?://([^/]+)'::text) ~~ '%.com.br'::text) THEN regexp_replace("substring"(url_list.url, 'https?://([^/]+)'::text), '^.*\.([^.]+\.com\.br)$'::text, '\1'::text)
                    WHEN ("substring"(url_list.url, 'https?://([^/]+)'::text) ~~ '%.%'::text) THEN regexp_replace("substring"(url_list.url, 'https?://([^/]+)'::text), '^.*\.([^.]+\.[^.]+)$'::text, '\1'::text)
                    ELSE NULL::text
                END AS principal_domain,
            "substring"(url_list.url, 'https?://([^/]+)'::text) AS full_domain,
            g."advertiserName",
            g."creativeId",
            g.format,
            r.region,
            g."lastShown",
            COALESCE(g.updated_at, g.created_at) AS scraped_at
           FROM (((google_ads_scraper g
             CROSS JOIN LATERAL jsonb_array_elements(g.variations) variations_element(value))
             CROSS JOIN LATERAL ( SELECT (variations_element.value ->> 'clickUrl'::text) AS url) url_list)
             LEFT JOIN LATERAL unnest(g."creativeRegions") r(region) ON (true))
          WHERE ((url_list.url IS NOT NULL) AND (url_list.url <> ''::text) AND ("substring"(url_list.url, 'https?://([^/]+)'::text) IS NOT NULL))
        ), subdomain_counts AS (
         SELECT domain_level_data.principal_domain,
            domain_level_data.full_domain,
            count(DISTINCT domain_level_data."creativeId") AS creative_count
           FROM domain_level_data
          WHERE (domain_level_data.principal_domain IS NOT NULL)
          GROUP BY domain_level_data.principal_domain, domain_level_data.full_domain
        ), aggregated_subdomain_counts AS (
         SELECT subdomain_counts.principal_domain,
            jsonb_agg(jsonb_build_object('subdomain', subdomain_counts.full_domain, 'creative_count', subdomain_counts.creative_count) ORDER BY subdomain_counts.creative_count DESC) AS subdomain_breakdown
           FROM subdomain_counts
          GROUP BY subdomain_counts.principal_domain
        ), principal_domain_metrics AS (
         SELECT domain_level_data.principal_domain,
            count(DISTINCT domain_level_data."creativeId") AS principal_domain_total_creatives,
            array_agg(DISTINCT domain_level_data.full_domain) AS associated_domains,
            array_agg(DISTINCT domain_level_data."advertiserName") AS advertisers,
            max(domain_level_data.scraped_at) AS last_scraped_at,
            max(domain_level_data."lastShown") AS latest_ad_activity_date,
            count(DISTINCT domain_level_data.region) AS distinct_region_count,
            array_agg(DISTINCT domain_level_data.region) FILTER (WHERE (domain_level_data.region IS NOT NULL)) AS all_regions,
            array_agg(DISTINCT domain_level_data.format) AS formats_used
           FROM domain_level_data
          WHERE (domain_level_data.principal_domain IS NOT NULL)
          GROUP BY domain_level_data.principal_domain
        )
 SELECT pdm.principal_domain,
    pdm.principal_domain_total_creatives,
    sub_agg.subdomain_breakdown,
    pdm.associated_domains,
    pdm.advertisers,
    pdm.last_scraped_at,
    pdm.latest_ad_activity_date,
    pdm.distinct_region_count,
    pdm.all_regions,
    pdm.formats_used
   FROM (principal_domain_metrics pdm
     JOIN aggregated_subdomain_counts sub_agg ON ((pdm.principal_domain = sub_agg.principal_domain)))
  ORDER BY pdm.principal_domain_total_creatives DESC, pdm.last_scraped_at DESC;

CREATE OR REPLACE VIEW public.vw_google_ads_scraper_summary AS SELECT g."advertiserId",
    g."advertiserName",
    array_agg(DISTINCT dom.domain) FILTER (WHERE (dom.domain IS NOT NULL)) AS all_domains,
    max(COALESCE(g.updated_at, g.created_at)) AS last_scraped_at,
    count(DISTINCT g."creativeId") AS total_creatives,
    max(g."lastShown") AS latest_ad_activity_date,
    count(DISTINCT r.region) AS distinct_region_count,
    array_agg(DISTINCT r.region) FILTER (WHERE (r.region IS NOT NULL)) AS all_regions,
    array_agg(DISTINCT g.format) AS formats_used
   FROM ((google_ads_scraper g
     LEFT JOIN LATERAL unnest(g."creativeRegions") r(region) ON (true))
     LEFT JOIN LATERAL ( SELECT "substring"(url_list.url, 'https?://([^/]+)'::text) AS domain
           FROM ( SELECT (jsonb_array_elements.value ->> 'clickUrl'::text) AS url
                   FROM jsonb_array_elements(g.variations) jsonb_array_elements(value)) url_list
          WHERE ((url_list.url IS NOT NULL) AND (url_list.url <> ''::text))) dom ON (true))
  GROUP BY g."advertiserId", g."advertiserName"
  ORDER BY (max(COALESCE(g.updated_at, g.created_at))) DESC, (count(DISTINCT g."creativeId")) DESC;

CREATE OR REPLACE VIEW public.vw_google_ads_url_summary AS WITH url_level_data AS (
         SELECT url_list.url AS click_url,
            "substring"(url_list.url, 'https?://([^/]+)'::text) AS full_domain,
                CASE
                    WHEN ("substring"(url_list.url, 'https?://([^/]+)'::text) ~~ '%.com.br'::text) THEN regexp_replace("substring"(url_list.url, 'https?://([^/]+)'::text), '^.*\.([^.]+\.com\.br)$'::text, '\1'::text)
                    WHEN ("substring"(url_list.url, 'https?://([^/]+)'::text) ~~ '%.%'::text) THEN regexp_replace("substring"(url_list.url, 'https?://([^/]+)'::text), '^.*\.([^.]+\.[^.]+)$'::text, '\1'::text)
                    ELSE NULL::text
                END AS principal_domain,
            g."advertiserId",
            g."advertiserName",
            g."creativeId",
            g.format,
            r.region,
            g."lastShown",
            COALESCE(g.updated_at, g.created_at) AS scraped_at
           FROM (((google_ads_scraper g
             CROSS JOIN LATERAL jsonb_array_elements(g.variations) variations_element(value))
             CROSS JOIN LATERAL ( SELECT (variations_element.value ->> 'clickUrl'::text) AS url) url_list)
             LEFT JOIN LATERAL unnest(g."creativeRegions") r(region) ON (true))
          WHERE ((url_list.url IS NOT NULL) AND (url_list.url <> ''::text))
        )
 SELECT click_url,
    count(DISTINCT "creativeId") AS total_creatives,
    array_agg(DISTINCT "advertiserName") AS advertisers,
    max(scraped_at) AS last_scraped_at,
    max("lastShown") AS latest_ad_activity_date,
    max(full_domain) AS full_domain,
    max(principal_domain) AS principal_domain,
    count(DISTINCT region) AS distinct_region_count,
    array_agg(DISTINCT region) FILTER (WHERE (region IS NOT NULL)) AS all_regions,
    array_agg(DISTINCT format) AS formats_used,
    array_agg(DISTINCT "advertiserId") AS advertiser_ids
   FROM url_level_data d
  WHERE (principal_domain IS NOT NULL)
  GROUP BY click_url
  ORDER BY (count(DISTINCT "creativeId")) DESC, (max(scraped_at)) DESC;

CREATE OR REPLACE VIEW public.vw_message_runs_complete AS SELECT mr.id AS run_id,
    mr.user_id,
    mr.trigger_id,
    mr.flow_id,
    mr.status AS run_status,
    mr.start_at,
    mr.created_at,
    mr.updated_at,
    mr.completed_at,
    mr.deleted_at,
    mr.next_step_at,
    mr.metrics_updated_at,
    mf.name AS flow_name,
    mf.status AS flow_status,
    mf.is_active AS flow_is_active,
    mf.project_id,
    p.name AS project_name,
    p.domain AS project_domain,
    p.status AS project_status,
    p.is_deleted AS project_is_deleted,
    mt.trigger_definition,
    mt.status AS trigger_status,
    mr.next_step_id,
    mr.last_step_id,
    mr.page_ids,
    ( SELECT jsonb_agg(jsonb_build_object('page_id', mp.page_id, 'page_name', mp.page_name, 'image', mp.image, 'is_active', mp.is_active, 'country', mp.country, 'language', mp.language, 'niche', mp.niche) ORDER BY mp.page_name) AS jsonb_agg
           FROM (unnest(mr.page_ids) page_id_item(page_id_item)
             LEFT JOIN meta_pages mp ON ((mp.page_id = page_id_item.page_id_item)))) AS pages_info,
    ( SELECT string_agg(mp.page_name, ', '::text ORDER BY mp.page_name) AS string_agg
           FROM (unnest(mr.page_ids) page_id_item(page_id_item)
             LEFT JOIN meta_pages mp ON ((mp.page_id = page_id_item.page_id_item)))) AS page_names,
    mr.total_messages,
    mr.success_count,
    mr.failure_count,
    ((mr.total_messages - mr.success_count) - mr.failure_count) AS pending_count,
    mr.total_subscribers_at_creation,
    mr.active_subscribers_at_creation,
    (mr.total_subscribers_at_creation - mr.active_subscribers_at_creation) AS inactive_subscribers_at_creation,
        CASE
            WHEN (mr.total_messages > 0) THEN round((((mr.success_count)::numeric / (mr.total_messages)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS success_rate_pct,
        CASE
            WHEN (mr.total_messages > 0) THEN round((((mr.failure_count)::numeric / (mr.total_messages)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS error_rate_pct,
        CASE
            WHEN (mr.total_subscribers_at_creation > 0) THEN round((((mr.success_count)::numeric / (mr.total_subscribers_at_creation)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS delivery_rate_pct,
        CASE
            WHEN (mr.total_subscribers_at_creation > 0) THEN round((((mr.failure_count)::numeric / (mr.total_subscribers_at_creation)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS error_coverage_pct,
    mr.error_summary,
    ((mr.error_summary ->> 'total_errors'::text))::integer AS total_errors,
    ((mr.error_summary ->> 'unique_error_types'::text))::integer AS unique_error_types,
    (((mr.error_summary -> 'error_summary'::text) -> 0) ->> 'error_message'::text) AS most_common_error,
    ((((mr.error_summary -> 'error_summary'::text) -> 0) ->> 'count'::text))::integer AS most_common_error_count,
    ((((mr.error_summary -> 'error_summary'::text) -> 0) ->> 'percentage'::text))::numeric AS most_common_error_pct,
        CASE
            WHEN ((mr.completed_at IS NOT NULL) AND (mr.start_at IS NOT NULL)) THEN (EXTRACT(epoch FROM (mr.completed_at - mr.start_at)))::integer
            WHEN ((mr.start_at IS NOT NULL) AND (mr.completed_at IS NULL)) THEN (EXTRACT(epoch FROM (now() - mr.start_at)))::integer
            ELSE NULL::integer
        END AS duration_seconds,
        CASE
            WHEN ((mr.completed_at IS NOT NULL) AND (mr.start_at IS NOT NULL)) THEN round((EXTRACT(epoch FROM (mr.completed_at - mr.start_at)) / (60)::numeric), 2)
            WHEN ((mr.start_at IS NOT NULL) AND (mr.completed_at IS NULL)) THEN round((EXTRACT(epoch FROM (now() - mr.start_at)) / (60)::numeric), 2)
            ELSE NULL::numeric
        END AS duration_minutes,
    (mr.deleted_at IS NULL) AS is_active,
    (mr.status = ANY (ARRAY['running'::text, 'queued'::text])) AS is_in_progress,
    (mr.completed_at IS NOT NULL) AS is_completed,
    (mr.failure_count > 0) AS has_errors,
        CASE
            WHEN (mr.total_messages > 0) THEN (((mr.failure_count)::numeric / (mr.total_messages)::numeric) > 0.5)
            ELSE false
        END AS is_high_error_rate,
        CASE
            WHEN (mr.total_messages > 0) THEN (((mr.success_count)::numeric / (mr.total_messages)::numeric) > 0.9)
            ELSE false
        END AS is_high_success_rate,
        CASE
            WHEN ((mr.completed_at IS NOT NULL) AND (mr.start_at IS NOT NULL) AND (mr.total_messages > 0) AND (EXTRACT(epoch FROM (mr.completed_at - mr.start_at)) > (0)::numeric)) THEN round(((mr.total_messages)::numeric / NULLIF((EXTRACT(epoch FROM (mr.completed_at - mr.start_at)) / (60)::numeric), (0)::numeric)), 2)
            ELSE NULL::numeric
        END AS messages_per_minute
   FROM (((message_runs mr
     LEFT JOIN message_flows mf ON ((mf.id = mr.flow_id)))
     LEFT JOIN projects p ON ((p.id = mf.project_id)))
     LEFT JOIN message_triggers mt ON ((mt.id = mr.trigger_id)));

CREATE OR REPLACE VIEW public.vw_message_runs_with_flow AS SELECT mr.id,
    mr.user_id,
    mr.trigger_id,
    mr.page_ids,
    mr.flow_id,
    mf.name AS flow_name,
    mf.project_id,
    mr.status,
    mr.start_at,
    mr.next_step_at,
    mr.next_step_id,
    mr.last_step_id,
    mr.total_messages,
    mr.success_count,
    mr.failure_count,
    mr.completed_at,
    mr.created_at,
    mr.updated_at
   FROM (message_runs mr
     LEFT JOIN message_flows mf ON ((mf.id = mr.flow_id)));

--- 8. CUSTOM FUNCTIONS ---
auth.email() RETURNS text
auth.jwt() RETURNS jsonb
auth.role() RETURNS text
auth.uid() RETURNS uuid
extensions.armor(bytea, text[], text[]) RETURNS text
extensions.armor(bytea) RETURNS text
extensions.array_to_halfvec(real[], integer, boolean) RETURNS halfvec
extensions.array_to_halfvec(numeric[], integer, boolean) RETURNS halfvec
extensions.array_to_halfvec(double precision[], integer, boolean) RETURNS halfvec
extensions.array_to_halfvec(integer[], integer, boolean) RETURNS halfvec
extensions.array_to_sparsevec(numeric[], integer, boolean) RETURNS sparsevec
extensions.array_to_sparsevec(integer[], integer, boolean) RETURNS sparsevec
extensions.array_to_sparsevec(real[], integer, boolean) RETURNS sparsevec
extensions.array_to_sparsevec(double precision[], integer, boolean) RETURNS sparsevec
extensions.array_to_vector(integer[], integer, boolean) RETURNS vector
extensions.array_to_vector(double precision[], integer, boolean) RETURNS vector
extensions.array_to_vector(numeric[], integer, boolean) RETURNS vector
extensions.array_to_vector(real[], integer, boolean) RETURNS vector
extensions.avg(vector) RETURNS vector
extensions.avg(halfvec) RETURNS halfvec
extensions.binary_quantize(halfvec) RETURNS bit
extensions.binary_quantize(vector) RETURNS bit
extensions.cosine_distance(vector, vector) RETURNS double precision
extensions.cosine_distance(sparsevec, sparsevec) RETURNS double precision
extensions.cosine_distance(halfvec, halfvec) RETURNS double precision
extensions.crypt(text, text) RETURNS text
extensions.dearmor(text) RETURNS bytea
extensions.decrypt(bytea, bytea, text) RETURNS bytea
extensions.decrypt_iv(bytea, bytea, bytea, text) RETURNS bytea
extensions.digest(bytea, text) RETURNS bytea
extensions.digest(text, text) RETURNS bytea
extensions.encrypt(bytea, bytea, text) RETURNS bytea
extensions.encrypt_iv(bytea, bytea, bytea, text) RETURNS bytea
extensions.gen_random_bytes(integer) RETURNS bytea
extensions.gen_random_uuid() RETURNS uuid
extensions.gen_salt(text) RETURNS text
extensions.gen_salt(text, integer) RETURNS text
extensions.grant_pg_cron_access() RETURNS event_trigger
extensions.grant_pg_graphql_access() RETURNS event_trigger
extensions.grant_pg_net_access() RETURNS event_trigger
extensions.halfvec(halfvec, integer, boolean) RETURNS halfvec
extensions.halfvec_accum(double precision[], halfvec) RETURNS double precision[]
extensions.halfvec_add(halfvec, halfvec) RETURNS halfvec
extensions.halfvec_avg(double precision[]) RETURNS halfvec
extensions.halfvec_cmp(halfvec, halfvec) RETURNS integer
extensions.halfvec_combine(double precision[], double precision[]) RETURNS double precision[]
extensions.halfvec_concat(halfvec, halfvec) RETURNS halfvec
extensions.halfvec_eq(halfvec, halfvec) RETURNS boolean
extensions.halfvec_ge(halfvec, halfvec) RETURNS boolean
extensions.halfvec_gt(halfvec, halfvec) RETURNS boolean
extensions.halfvec_in(cstring, oid, integer) RETURNS halfvec
extensions.halfvec_l2_squared_distance(halfvec, halfvec) RETURNS double precision
extensions.halfvec_le(halfvec, halfvec) RETURNS boolean
extensions.halfvec_lt(halfvec, halfvec) RETURNS boolean
extensions.halfvec_mul(halfvec, halfvec) RETURNS halfvec
extensions.halfvec_ne(halfvec, halfvec) RETURNS boolean
extensions.halfvec_negative_inner_product(halfvec, halfvec) RETURNS double precision
extensions.halfvec_out(halfvec) RETURNS cstring
extensions.halfvec_recv(internal, oid, integer) RETURNS halfvec
extensions.halfvec_send(halfvec) RETURNS bytea
extensions.halfvec_spherical_distance(halfvec, halfvec) RETURNS double precision
extensions.halfvec_sub(halfvec, halfvec) RETURNS halfvec
extensions.halfvec_to_float4(halfvec, integer, boolean) RETURNS real[]
extensions.halfvec_to_sparsevec(halfvec, integer, boolean) RETURNS sparsevec
extensions.halfvec_to_vector(halfvec, integer, boolean) RETURNS vector
extensions.halfvec_typmod_in(cstring[]) RETURNS integer
extensions.hamming_distance(bit, bit) RETURNS double precision
extensions.hmac(bytea, bytea, text) RETURNS bytea
extensions.hmac(text, text, text) RETURNS bytea
extensions.hnsw_bit_support(internal) RETURNS internal
extensions.hnsw_halfvec_support(internal) RETURNS internal
extensions.hnsw_sparsevec_support(internal) RETURNS internal
extensions.hnswhandler(internal) RETURNS index_am_handler
extensions.hypopg(OUT indexname text, OUT indexrelid oid, OUT indrelid oid, OUT innatts integer, OUT indisunique boolean, OUT indkey int2vector, OUT indcollation oidvector, OUT indclass oidvector, OUT indoption oidvector, OUT indexprs pg_node_tree, OUT indpred pg_node_tree, OUT amid oid) RETURNS SETOF record
extensions.hypopg_create_index(sql_order text, OUT indexrelid oid, OUT indexname text) RETURNS SETOF record
extensions.hypopg_drop_index(indexid oid) RETURNS boolean
extensions.hypopg_get_indexdef(indexid oid) RETURNS text
extensions.hypopg_hidden_indexes() RETURNS TABLE(indexid oid)
extensions.hypopg_hide_index(indexid oid) RETURNS boolean
extensions.hypopg_relation_size(indexid oid) RETURNS bigint
extensions.hypopg_reset() RETURNS void
extensions.hypopg_reset_index() RETURNS void
extensions.hypopg_unhide_all_indexes() RETURNS void
extensions.hypopg_unhide_index(indexid oid) RETURNS boolean
extensions.index_advisor(query text) RETURNS TABLE(startup_cost_before jsonb, startup_cost_after jsonb, total_cost_before jsonb, total_cost_after jsonb, index_statements text[], errors text[])
extensions.inner_product(sparsevec, sparsevec) RETURNS double precision
extensions.inner_product(vector, vector) RETURNS double precision
extensions.inner_product(halfvec, halfvec) RETURNS double precision
extensions.ivfflat_bit_support(internal) RETURNS internal
extensions.ivfflat_halfvec_support(internal) RETURNS internal
extensions.ivfflathandler(internal) RETURNS index_am_handler
extensions.jaccard_distance(bit, bit) RETURNS double precision
extensions.l1_distance(halfvec, halfvec) RETURNS double precision
extensions.l1_distance(sparsevec, sparsevec) RETURNS double precision
extensions.l1_distance(vector, vector) RETURNS double precision
extensions.l2_distance(halfvec, halfvec) RETURNS double precision
extensions.l2_distance(sparsevec, sparsevec) RETURNS double precision
extensions.l2_distance(vector, vector) RETURNS double precision
extensions.l2_norm(halfvec) RETURNS double precision
extensions.l2_norm(sparsevec) RETURNS double precision
extensions.l2_normalize(sparsevec) RETURNS sparsevec
extensions.l2_normalize(halfvec) RETURNS halfvec
extensions.l2_normalize(vector) RETURNS vector
extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT shared_blk_read_time double precision, OUT shared_blk_write_time double precision, OUT local_blk_read_time double precision, OUT local_blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision, OUT jit_deform_count bigint, OUT jit_deform_time double precision, OUT stats_since timestamp with time zone, OUT minmax_stats_since timestamp with time zone) RETURNS SETOF record
extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) RETURNS record
extensions.pg_stat_statements_reset(userid oid DEFAULT 0, dbid oid DEFAULT 0, queryid bigint DEFAULT 0, minmax_only boolean DEFAULT false) RETURNS timestamp with time zone
extensions.pgp_armor_headers(text, OUT key text, OUT value text) RETURNS SETOF record
extensions.pgp_key_id(bytea) RETURNS text
extensions.pgp_pub_decrypt(bytea, bytea, text) RETURNS text
extensions.pgp_pub_decrypt(bytea, bytea) RETURNS text
extensions.pgp_pub_decrypt(bytea, bytea, text, text) RETURNS text
extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) RETURNS bytea
extensions.pgp_pub_decrypt_bytea(bytea, bytea) RETURNS bytea
extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) RETURNS bytea
extensions.pgp_pub_encrypt(text, bytea) RETURNS bytea
extensions.pgp_pub_encrypt(text, bytea, text) RETURNS bytea
extensions.pgp_pub_encrypt_bytea(bytea, bytea) RETURNS bytea
extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) RETURNS bytea
extensions.pgp_sym_decrypt(bytea, text, text) RETURNS text
extensions.pgp_sym_decrypt(bytea, text) RETURNS text
extensions.pgp_sym_decrypt_bytea(bytea, text, text) RETURNS bytea
extensions.pgp_sym_decrypt_bytea(bytea, text) RETURNS bytea
extensions.pgp_sym_encrypt(text, text, text) RETURNS bytea
extensions.pgp_sym_encrypt(text, text) RETURNS bytea
extensions.pgp_sym_encrypt_bytea(bytea, text, text) RETURNS bytea
extensions.pgp_sym_encrypt_bytea(bytea, text) RETURNS bytea
extensions.pgrst_ddl_watch() RETURNS event_trigger
extensions.pgrst_drop_watch() RETURNS event_trigger
extensions.set_graphql_placeholder() RETURNS event_trigger
extensions.sparsevec(sparsevec, integer, boolean) RETURNS sparsevec
extensions.sparsevec_cmp(sparsevec, sparsevec) RETURNS integer
extensions.sparsevec_eq(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_ge(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_gt(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_in(cstring, oid, integer) RETURNS sparsevec
extensions.sparsevec_l2_squared_distance(sparsevec, sparsevec) RETURNS double precision
extensions.sparsevec_le(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_lt(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_ne(sparsevec, sparsevec) RETURNS boolean
extensions.sparsevec_negative_inner_product(sparsevec, sparsevec) RETURNS double precision
extensions.sparsevec_out(sparsevec) RETURNS cstring
extensions.sparsevec_recv(internal, oid, integer) RETURNS sparsevec
extensions.sparsevec_send(sparsevec) RETURNS bytea
extensions.sparsevec_to_halfvec(sparsevec, integer, boolean) RETURNS halfvec
extensions.sparsevec_to_vector(sparsevec, integer, boolean) RETURNS vector
extensions.sparsevec_typmod_in(cstring[]) RETURNS integer
extensions.subvector(halfvec, integer, integer) RETURNS halfvec
extensions.subvector(vector, integer, integer) RETURNS vector
extensions.sum(halfvec) RETURNS halfvec
extensions.sum(vector) RETURNS vector
extensions.uuid_generate_v1() RETURNS uuid
extensions.uuid_generate_v1mc() RETURNS uuid
extensions.uuid_generate_v3(namespace uuid, name text) RETURNS uuid
extensions.uuid_generate_v4() RETURNS uuid
extensions.uuid_generate_v5(namespace uuid, name text) RETURNS uuid
extensions.uuid_nil() RETURNS uuid
extensions.uuid_ns_dns() RETURNS uuid
extensions.uuid_ns_oid() RETURNS uuid
extensions.uuid_ns_url() RETURNS uuid
extensions.uuid_ns_x500() RETURNS uuid
extensions.vector(vector, integer, boolean) RETURNS vector
extensions.vector_accum(double precision[], vector) RETURNS double precision[]
extensions.vector_add(vector, vector) RETURNS vector
extensions.vector_avg(double precision[]) RETURNS vector
extensions.vector_cmp(vector, vector) RETURNS integer
extensions.vector_combine(double precision[], double precision[]) RETURNS double precision[]
extensions.vector_concat(vector, vector) RETURNS vector
extensions.vector_dims(halfvec) RETURNS integer
extensions.vector_dims(vector) RETURNS integer
extensions.vector_eq(vector, vector) RETURNS boolean
extensions.vector_ge(vector, vector) RETURNS boolean
extensions.vector_gt(vector, vector) RETURNS boolean
extensions.vector_in(cstring, oid, integer) RETURNS vector
extensions.vector_l2_squared_distance(vector, vector) RETURNS double precision
extensions.vector_le(vector, vector) RETURNS boolean
extensions.vector_lt(vector, vector) RETURNS boolean
extensions.vector_mul(vector, vector) RETURNS vector
extensions.vector_ne(vector, vector) RETURNS boolean
extensions.vector_negative_inner_product(vector, vector) RETURNS double precision
extensions.vector_norm(vector) RETURNS double precision
extensions.vector_out(vector) RETURNS cstring
extensions.vector_recv(internal, oid, integer) RETURNS vector
extensions.vector_send(vector) RETURNS bytea
extensions.vector_spherical_distance(vector, vector) RETURNS double precision
extensions.vector_sub(vector, vector) RETURNS vector
extensions.vector_to_float4(vector, integer, boolean) RETURNS real[]
extensions.vector_to_halfvec(vector, integer, boolean) RETURNS halfvec
extensions.vector_to_sparsevec(vector, integer, boolean) RETURNS sparsevec
extensions.vector_typmod_in(cstring[]) RETURNS integer
graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
net._await_response(request_id bigint) RETURNS boolean
net._encode_url_with_params_array(url text, params_array text[]) RETURNS text
net._http_collect_response(request_id bigint, async boolean DEFAULT true) RETURNS net.http_response_result
net._urlencode_string(string character varying) RETURNS text
net.check_worker_is_up() RETURNS void
net.http_collect_response(request_id bigint, async boolean DEFAULT true) RETURNS net.http_response_result
net.http_delete(url text, params jsonb DEFAULT '{}'::jsonb, headers jsonb DEFAULT '{}'::jsonb, timeout_milliseconds integer DEFAULT 5000, body jsonb DEFAULT NULL::jsonb) RETURNS bigint
net.http_get(url text, params jsonb DEFAULT '{}'::jsonb, headers jsonb DEFAULT '{}'::jsonb, timeout_milliseconds integer DEFAULT 5000) RETURNS bigint
net.http_post(url text, body jsonb DEFAULT '{}'::jsonb, params jsonb DEFAULT '{}'::jsonb, headers jsonb DEFAULT '{"Content-Type": "application/json"}'::jsonb, timeout_milliseconds integer DEFAULT 5000) RETURNS bigint
net.wait_until_running() RETURNS void
net.wake() RETURNS void
net.worker_restart() RETURNS boolean
pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
pgmq._belongs_to_pgmq(table_name text) RETURNS boolean
pgmq._ensure_pg_partman_installed() RETURNS void
pgmq._get_partition_col(partition_interval text) RETURNS text
pgmq._get_pg_partman_major_version() RETURNS integer
pgmq._get_pg_partman_schema() RETURNS text
pgmq.archive(queue_name text, msg_ids bigint[]) RETURNS SETOF bigint
pgmq.archive(queue_name text, msg_id bigint) RETURNS boolean
pgmq.convert_archive_partitioned(table_name text, partition_interval text DEFAULT '10000'::text, retention_interval text DEFAULT '100000'::text, leading_partition integer DEFAULT 10) RETURNS void
pgmq.create(queue_name text) RETURNS void
pgmq.create_non_partitioned(queue_name text) RETURNS void
pgmq.create_partitioned(queue_name text, partition_interval text DEFAULT '10000'::text, retention_interval text DEFAULT '100000'::text) RETURNS void
pgmq.create_unlogged(queue_name text) RETURNS void
pgmq.delete(queue_name text, msg_id bigint) RETURNS boolean
pgmq.delete(queue_name text, msg_ids bigint[]) RETURNS SETOF bigint
pgmq.detach_archive(queue_name text) RETURNS void
pgmq.drop_queue(queue_name text) RETURNS boolean
pgmq.format_table_name(queue_name text, prefix text) RETURNS text
pgmq.list_queues() RETURNS SETOF pgmq.queue_record
pgmq.metrics(queue_name text) RETURNS pgmq.metrics_result
pgmq.metrics_all() RETURNS SETOF pgmq.metrics_result
pgmq.pop(queue_name text) RETURNS SETOF pgmq.message_record
pgmq.purge_queue(queue_name text) RETURNS bigint
pgmq.read(queue_name text, vt integer, qty integer) RETURNS SETOF pgmq.message_record
pgmq.read_with_poll(queue_name text, vt integer, qty integer, max_poll_seconds integer DEFAULT 5, poll_interval_ms integer DEFAULT 100) RETURNS SETOF pgmq.message_record
pgmq.send(queue_name text, msg jsonb, delay integer DEFAULT 0) RETURNS SETOF bigint
pgmq.send_batch(queue_name text, msgs jsonb[], delay integer DEFAULT 0) RETURNS SETOF bigint
pgmq.set_vt(queue_name text, msg_id bigint, vt integer) RETURNS SETOF pgmq.message_record
pgmq.validate_queue_name(queue_name text) RETURNS void
pgmq_public.archive(queue_name text, message_id bigint) RETURNS boolean
pgmq_public.delete(queue_name text, message_id bigint) RETURNS boolean
pgmq_public.list_queues() RETURNS TABLE(queue_name text, is_partitioned boolean, is_unlogged boolean, created_at timestamp with time zone)
pgmq_public.metrics(queue_name text) RETURNS TABLE(q_name text, queue_length bigint, newest_msg_age_sec numeric, oldest_msg_age_sec numeric, total_messages bigint, scrape_time timestamp with time zone)
pgmq_public.pop(queue_name text) RETURNS SETOF pgmq.message_record
pgmq_public.read(queue_name text, sleep_seconds integer DEFAULT 0, n integer DEFAULT 1) RETURNS TABLE(msg_id bigint, read_ct integer, enqueued_at timestamp with time zone, vt timestamp with time zone, message jsonb)
pgmq_public.read_distributed(queue_name text, sleep_seconds integer DEFAULT 30, n integer DEFAULT 1, max_per_page integer DEFAULT 10) RETURNS SETOF pgmq.message_record
pgmq_public.send(queue_name text, message jsonb, sleep_seconds integer DEFAULT 0) RETURNS bigint
pgmq_public.send_batch(queue_name text, messages jsonb[], sleep_seconds integer DEFAULT 0) RETURNS SETOF bigint
public.bytea_to_text(data bytea) RETURNS text
public.calculate_actual_time() RETURNS trigger
public.can_process_messages() RETURNS TABLE(can_process boolean, current_usage integer, reason text, pause_remaining_seconds integer)
public.clean_utm_fields_trigger() RETURNS trigger
public.cleanup_orphaned_data() RETURNS integer
public.configure_supabase_settings(p_supabase_url text, p_anon_key text DEFAULT NULL::text) RETURNS text
public.create_profile_for_new_user() RETURNS trigger
public.enqueue_messages_bulk(p_queue_name text, p_page_id text, p_flow_id text, p_run_id text, p_messages jsonb, p_page_data jsonb) RETURNS TABLE(total bigint, queued bigint)
public.get_complete_schema() RETURNS jsonb
public.get_message_rate_limit_stats() RETURNS TABLE(current_usage integer, is_paused boolean, pause_reason text, pause_remaining_minutes integer, calls_this_window integer, total_calls_lifetime bigint, total_rate_limit_hits integer, last_error_code text, last_error_time timestamp with time zone, last_updated timestamp with time zone)
public.get_message_runs_complete(p_user_id uuid, p_date_start timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_end timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS jsonb
public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) RETURNS internal
public.gin_extract_value_trgm(text, internal) RETURNS internal
public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) RETURNS boolean
public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) RETURNS "char"
public.gtrgm_compress(internal) RETURNS internal
public.gtrgm_consistent(internal, text, smallint, oid, internal) RETURNS boolean
public.gtrgm_decompress(internal) RETURNS internal
public.gtrgm_distance(internal, text, smallint, oid, internal) RETURNS double precision
public.gtrgm_in(cstring) RETURNS gtrgm
public.gtrgm_options(internal) RETURNS void
public.gtrgm_out(gtrgm) RETURNS cstring
public.gtrgm_penalty(internal, internal, internal) RETURNS internal
public.gtrgm_picksplit(internal, internal) RETURNS internal
public.gtrgm_same(gtrgm, gtrgm, internal) RETURNS internal
public.gtrgm_union(internal, internal) RETURNS gtrgm
public.http(request http_request) RETURNS http_response
public.http_delete(uri character varying) RETURNS http_response
public.http_delete(uri character varying, content character varying, content_type character varying) RETURNS http_response
public.http_get(uri character varying) RETURNS http_response
public.http_get(uri character varying, data jsonb) RETURNS http_response
public.http_head(uri character varying) RETURNS http_response
public.http_header(field character varying, value character varying) RETURNS http_header
public.http_list_curlopt() RETURNS TABLE(curlopt text, value text)
public.http_patch(uri character varying, content character varying, content_type character varying) RETURNS http_response
public.http_post(uri character varying, content character varying, content_type character varying) RETURNS http_response
public.http_post(uri character varying, data jsonb) RETURNS http_response
public.http_put(uri character varying, content character varying, content_type character varying) RETURNS http_response
public.http_reset_curlopt() RETURNS boolean
public.http_set_curlopt(curlopt character varying, value character varying) RETURNS boolean
public.import_category_tasks(p_project_id bigint, p_category_id bigint, p_user_id uuid) RETURNS void
public.is_admin(user_uuid uuid) RETURNS boolean
public.meta_pages_subscribe_webhook() RETURNS trigger
public.normalize_error_message_trigger() RETURNS trigger
public.normalize_keyword(input_text text) RETURNS text
public.notify_webhook_articles() RETURNS trigger
public.pgmq_archive(queue_name text, message_id bigint) RETURNS boolean
public.pgmq_archive_batch(queue_name text, message_ids bigint[]) RETURNS SETOF bigint
public.pgmq_delete(queue_name text, message_id bigint) RETURNS boolean
public.pgmq_list_queues() RETURNS TABLE(queue_name text)
public.pgmq_metrics(queue_name text) RETURNS TABLE(q_name text, queue_length bigint, newest_msg_age_sec integer, oldest_msg_age_sec integer, total_messages bigint)
public.pgmq_pop(queue_name text) RETURNS TABLE(msg_id bigint, read_ct integer, enqueued_at timestamp with time zone, vt timestamp with time zone, message jsonb)
public.pgmq_purge_queue(queue_name text) RETURNS bigint
public.pgmq_read(queue_name text, visibility_timeout integer, qty integer) RETURNS TABLE(msg_id bigint, read_ct integer, enqueued_at timestamp with time zone, vt timestamp with time zone, message jsonb)
public.pgmq_send(queue_name text, message jsonb) RETURNS bigint
public.pgmq_send_batch(queue_name text, messages jsonb[]) RETURNS SETOF bigint
public.pgmq_set_vt(queue_name text, message_id bigint, visibility_timeout integer) RETURNS TABLE(msg_id bigint, read_ct integer, enqueued_at timestamp with time zone, vt timestamp with time zone, message jsonb)
public.purge_page_messages(p_queue_name text, p_page_id text) RETURNS TABLE(archived_count bigint, message_ids bigint[])
public.record_task_history() RETURNS trigger
public.register_rate_limit_error(p_error_code text, p_error_message text) RETURNS void
public.reset_message_rate_limit() RETURNS void
public.set_limit(real) RETURNS real
public.show_limit() RETURNS real
public.show_trgm(text) RETURNS text[]
public.similarity(text, text) RETURNS real
public.similarity_dist(text, text) RETURNS real
public.similarity_op(text, text) RETURNS boolean
public.strict_word_similarity(text, text) RETURNS real
public.strict_word_similarity_commutator_op(text, text) RETURNS boolean
public.strict_word_similarity_dist_commutator_op(text, text) RETURNS real
public.strict_word_similarity_dist_op(text, text) RETURNS real
public.strict_word_similarity_op(text, text) RETURNS boolean
public.task_status_change() RETURNS trigger
public.test_task_status_update() RETURNS text
public.text_to_bytea(data text) RETURNS bytea
public.try_extract_message(p_error_text text) RETURNS text
public.unaccent(text) RETURNS text
public.unaccent(regdictionary, text) RETURNS text
public.unaccent_init(internal) RETURNS internal
public.unaccent_lexize(internal, internal, internal, internal) RETURNS internal
public.update_message_rate_limit(p_call_count integer, p_total_cputime integer DEFAULT NULL::integer, p_total_time integer DEFAULT NULL::integer, p_estimated_recovery_minutes integer DEFAULT NULL::integer) RETURNS void
public.update_run_metrics(p_run_id bigint DEFAULT NULL::bigint, p_user_id uuid DEFAULT NULL::uuid) RETURNS TABLE(processed_run_id bigint, status text, owner_user_id uuid)
public.update_utm_term() RETURNS void
public.urlencode(data jsonb) RETURNS text
public.urlencode(string character varying) RETURNS text
public.urlencode(string bytea) RETURNS text
public.word_similarity(text, text) RETURNS real
public.word_similarity_commutator_op(text, text) RETURNS boolean
public.word_similarity_dist_commutator_op(text, text) RETURNS real
public.word_similarity_dist_op(text, text) RETURNS real
public.word_similarity_op(text, text) RETURNS boolean
supabase_functions.http_request() RETURNS trigger

--- 9. TRIGGERS ---
user_created_trigger_to_profile ON auth.users | EXECUTE FUNCTION create_profile_for_new_user()
trigger_webhook_articles ON public.articles | EXECUTE FUNCTION notify_webhook_articles()
trigger_webhook_articles ON public.articles | EXECUTE FUNCTION notify_webhook_articles()
clean_utm_fields_before_insert_update ON public.imported_transactions | EXECUTE FUNCTION clean_utm_fields_trigger()
clean_utm_fields_before_insert_update ON public.imported_transactions | EXECUTE FUNCTION clean_utm_fields_trigger()
trg_meta_pages_subscribe_webhook ON public.meta_pages | EXECUTE FUNCTION meta_pages_subscribe_webhook()
trg_meta_pages_subscribe_webhook ON public.meta_pages | EXECUTE FUNCTION meta_pages_subscribe_webhook()
task_history_record ON public.tasks | EXECUTE FUNCTION record_task_history()
task_history_trigger ON public.tasks | EXECUTE FUNCTION record_task_history()
task_status_tracking_trigger ON public.tasks | EXECUTE FUNCTION task_status_change()
task_status_update ON public.tasks | EXECUTE FUNCTION task_status_change()

--- 10. RLS POLICIES ---
POLICY Only admins can delete admin roles ON public.admin_roles FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Only admins can insert admin roles ON public.admin_roles FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can update admin roles ON public.admin_roles FOR UPDATE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can view admin roles ON public.admin_roles FOR SELECT USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Only admins can delete from admins table ON public.admins FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Only admins can insert into admins table ON public.admins FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can update admins table ON public.admins FOR UPDATE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can view admins table ON public.admins FOR SELECT USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Delete articles policy ON public.articles FOR DELETE USING ((is_admin(( SELECT auth.uid() AS uid)) OR (user_id = ( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Insert articles policy ON public.articles FOR INSERT USING () WITH CHECK ((is_admin(( SELECT auth.uid() AS uid)) OR (user_id = ( SELECT auth.uid() AS uid))))
POLICY Update articles policy ON public.articles FOR UPDATE USING ((is_admin(( SELECT auth.uid() AS uid)) OR (user_id = ( SELECT auth.uid() AS uid)))) WITH CHECK ((is_admin(( SELECT auth.uid() AS uid)) OR (user_id = ( SELECT auth.uid() AS uid))))
POLICY View articles policy ON public.articles FOR SELECT USING ((is_admin(( SELECT auth.uid() AS uid)) OR (user_id = ( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY admin ON public.author_profile_images FOR ALL USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY only own ON public.connections FOR ALL USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)))
POLICY admin ON public.domains FOR ALL USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Apenas admins podem deletar keywords ON public.keywords FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Usuários autenticados podem atualizar keywords ON public.keywords FOR UPDATE USING (true) WITH CHECK (true)
POLICY Usuários autenticados podem inserir keywords ON public.keywords FOR INSERT USING () WITH CHECK (true)
POLICY Usuários autenticados podem visualizar keywords ON public.keywords FOR SELECT USING (true) WITH CHECK ()
POLICY user owner project ON public.message_flows FOR ALL USING ((EXISTS ( SELECT 1
   FROM projects p
  WHERE ((p.id = message_flows.project_id) AND (p.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM projects p
  WHERE ((p.id = message_flows.project_id) AND (p.user_id = ( SELECT auth.uid() AS uid))))))
POLICY own user ON public.meta_pages FOR ALL USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)))
POLICY Allow service role to read ON public.orchestrator_config FOR SELECT USING (true) WITH CHECK ()
POLICY Allow service role to update ON public.orchestrator_config FOR UPDATE USING (true) WITH CHECK ()
POLICY Enable read access for all users ON public.plans FOR SELECT USING (true) WITH CHECK ()
POLICY No physical deletion allowed for projects ON public.projects FOR DELETE USING (false) WITH CHECK ()
POLICY Users can insert own projects or admins can insert all ON public.projects FOR INSERT USING () WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY Users can update own projects or admins can update all ON public.projects FOR UPDATE USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY Users can view own projects or admins can view all ON public.projects FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Insert task history policy ON public.task_history FOR INSERT USING () WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)))
POLICY Update task history policy ON public.task_history FOR UPDATE USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY View task history policy ON public.task_history FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Authenticated users can view all task templates ON public.task_templates FOR SELECT USING (true) WITH CHECK ()
POLICY Only admins can delete task templates ON public.task_templates FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Only admins can insert task templates ON public.task_templates FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can update task templates ON public.task_templates FOR UPDATE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Users can delete own tasks or admins can delete all ON public.tasks FOR DELETE USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Users can insert own tasks or admins can insert all ON public.tasks FOR INSERT USING () WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY Users can update own tasks or admins can update all ON public.tasks FOR UPDATE USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY Users can view own tasks or admins can view all ON public.tasks FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Authenticated users can view all task categories ON public.tasks_categories FOR SELECT USING (true) WITH CHECK ()
POLICY Only admins can delete task categories ON public.tasks_categories FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Only admins can insert task categories ON public.tasks_categories FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Only admins can update task categories ON public.tasks_categories FOR UPDATE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Admins can delete transactions ON public.transactions FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Users can update own transactions or admins can update all ON public.transactions FOR UPDATE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Users can view own transactions or admins can view all ON public.transactions FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY admins can insert all ON public.transactions FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Admins can delete users ON public.users FOR DELETE USING (is_admin(( SELECT auth.uid() AS uid))) WITH CHECK ()
POLICY Admins can insert users ON public.users FOR INSERT USING () WITH CHECK (is_admin(( SELECT auth.uid() AS uid)))
POLICY Users can update own data or admins can update all ON public.users FOR UPDATE USING (((id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK (((id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid))))
POLICY Users can view own data or admins can view all ON public.users FOR SELECT USING (((id = ( SELECT auth.uid() AS uid)) OR is_admin(( SELECT auth.uid() AS uid)))) WITH CHECK ()
POLICY Policy with security definer functions ON public.users_keywords FOR ALL USING ((( SELECT auth.uid() AS uid) = user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id))

--- 11. CRON JOBS ---
ID 5 | Active: t | Schedule: */2 * * * * | Command: select
  net.http_post(
      url:='https://qbmbokpbcyempnaravaw.supabase.co/functions/v1/message-orchestrator',
      headers:=jsonb_build_object('Authorization', 'Bearer sb_secret_Sb8dwgwwVyO3gFsUyWCa5g_GG8mVi2_'), 
      timeout_milliseconds:=1000
  );
ID 7 | Active: t | Schedule: * * * * * | Command: 
  INSERT INTO queue_metrics (queue_name, message_count)
  SELECT 'alvocast-messages', count(*) 
  FROM "pgmq"."q_alvocast-messages";
  
ID 8 | Active: t | Schedule: 0 * * * * | Command: 
  DELETE FROM queue_metrics 
  WHERE recorded_at < NOW() - INTERVAL '24 hours';
  
ID 1 | Active: f | Schedule: * * * * * | Command: SELECT public.trigger_message_runs_webhook();
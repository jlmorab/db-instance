CREATE OR REPLACE FUNCTION public.fn_create_user(p_username VARCHAR, p_password VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
as $$
DECLARE
	schema_name TEXT;
BEGIN
	EXECUTE format('CREATE USER %I WITH PASSWORD %L', p_username, p_password);

	INSERT INTO public.user_allowed (ual_user)
    VALUES (p_username)
    ON CONFLICT (ual_user) DO NOTHING;

	FOR schema_name IN
        SELECT nspname FROM pg_namespace 
        WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
    LOOP
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO %I', schema_name, p_username);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I', schema_name, p_username);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %I TO %I', schema_name, p_username);
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', schema_name, p_username);
    END LOOP;

	EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO %I;', p_username);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO %I;', p_username);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO %I;', p_username);

END $$;
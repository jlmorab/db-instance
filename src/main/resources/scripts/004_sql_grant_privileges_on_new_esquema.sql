CREATE OR REPLACE FUNCTION public.fn_grant_access_on_new_schema()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
DECLARE
    schema_name TEXT;
    user_record RECORD;
BEGIN
    SELECT objid::regnamespace::text INTO schema_name
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag = 'CREATE SCHEMA';

    FOR user_record IN SELECT ual_user FROM public.user_allowed LOOP
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', schema_name, user_record.ual_user);
		EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON TABLES TO %I;', schema_name, user_record.ual_user);
	    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON SEQUENCES TO %I;', schema_name, user_record.ual_user);
	    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON FUNCTIONS TO %I;', schema_name, user_record.ual_user);
    END LOOP;
END $$;

CREATE EVENT TRIGGER grant_access_trigger
ON ddl_command_end
WHEN TAG IN ('CREATE SCHEMA')
EXECUTE FUNCTION public.fn_grant_access_on_new_schema();
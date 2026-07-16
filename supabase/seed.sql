-- Local/test-only switches. Production remains fail-closed when this setting is absent.
alter database postgres set app.environment = 'development';

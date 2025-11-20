WHENEVER SQLERROR EXIT SQL.SQLCODE
SET HEADING OFF FEEDBACK OFF
PROMPT Testing string_udf_wrapper:
SELECT string_udf_wrapper('Hello from the Oracle UDF!') FROM dual;
EXIT;

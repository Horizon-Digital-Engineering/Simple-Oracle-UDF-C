#!/bin/bash
set -euo pipefail

ORACLE_HOME=${ORACLE_HOME:-/opt/oracle/product/21c/dbhomeXE}
PATH="${ORACLE_HOME}/bin:${PATH}"
LOG_FILE=/opt/oracle/udf/install.log

{
  echo "[$(date)] Installing string_udf into XEPDB1"
  "${ORACLE_HOME}/bin/sqlplus" -s / as sysdba <<'SQL'
  ALTER SESSION SET CONTAINER = XEPDB1;
  @/opt/oracle/udf/string_udf.sql
  SHOW ERRORS FUNCTION string_udf_wrapper;
  EXIT;
SQL
} | tee -a "$LOG_FILE"

#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-simple-oracle-udf}"
CONTAINER="${CONTAINER:-oracle-udf}"
PLATFORM="${PLATFORM:-linux/amd64}"
ORACLE_PASSWORD="${ORACLE_PASSWORD:-YourPwd123}"

echo "[build] docker build --platform ${PLATFORM} -t ${IMAGE} ."
docker build --platform "${PLATFORM}" -t "${IMAGE}" .

echo "[clean] removing container ${CONTAINER} if present"
docker rm -f "${CONTAINER}" 2>/dev/null || true

echo "[clean] removing oracle* volumes (if any) to force fresh DB init"
for vol in $(docker volume ls --format '{{.Name}}' | grep -E '^oracle' || true); do
  docker volume rm "${vol}" || true
done

echo "[run] starting ${CONTAINER} (${PLATFORM})"
docker run --platform "${PLATFORM}" -d --name "${CONTAINER}" \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PASSWORD="${ORACLE_PASSWORD}" \
  "${IMAGE}"

echo "[wait] waiting for DATABASE IS READY TO USE"
max_tries=120
count=0
until docker logs "${CONTAINER}" 2>&1 | grep -q "DATABASE IS READY TO USE"; do
  sleep 5
  count=$((count + 1))
  if [ "${count}" -ge "${max_tries}" ]; then
    echo "Timed out waiting for database readiness"
    docker logs "${CONTAINER}"
    exit 1
  fi
done
echo "[ready] database is ready"

echo "[log] install log (if present)"
docker exec "${CONTAINER}" sh -c "if [ -f /opt/oracle/udf/install.log ]; then cat /opt/oracle/udf/install.log; else echo 'install.log not found'; fi"

echo "[log] setup/startup scripts present:"
docker exec "${CONTAINER}" sh -c "ls -l /opt/oracle/scripts/setup /opt/oracle/scripts/startup"

echo "[install] running string_udf.sql"
docker exec "${CONTAINER}" sh -c "sqlplus -s / as sysdba @/opt/oracle/udf/string_udf.sql"

echo "[verify] checking library and function"
docker exec "${CONTAINER}" sh -c "sqlplus -s system/${ORACLE_PASSWORD}@localhost/XEPDB1 <<'SQL'
select owner, object_name, status from dba_objects where object_name='STRING_UDF_WRAPPER';
select library_name, file_spec from dba_libraries where library_name='STRING_UDF_LIB';
show errors function string_udf_wrapper;
exit;
SQL"

echo "[test] running example.sql"
docker exec "${CONTAINER}" sqlplus -s system/"${ORACLE_PASSWORD}"@localhost/XEPDB1 @/opt/oracle/udf/example.sql

echo "[done] container ${CONTAINER} operational"

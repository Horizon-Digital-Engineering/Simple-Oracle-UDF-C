# Oracle UDF Example

An Oracle external procedure that accepts a string and echoes it back with guardrails for null or overly long inputs. The repo includes a ready-to-run Docker image that builds the shared library, registers it with Oracle XE, and ships with a quick test script.

## What's here
- `string_udf.c`: C implementation using `OCIExtProcAllocCallMemory` and friendly errors via `OCIExtProcRaiseExcpWithMsg`.
- `Makefile`: Builds `string_udf.so` against `ORACLE_HOME` (defaults to XE 21c; builder stage sets `/usr/lib/oracle/21/client64`).
- `Dockerfile`: Multi-stage; builds with Oracle Instant Client in a builder image, copies the `.so` into `gvenzl/oracle-xe:21`, and wires init SQL.
- `string_udf.sql`: Creates the external library and PL/SQL wrapper.
- `example.sql`: One-liner test you can run in the container.
- `run_local.sh`: End-to-end helper to build, start XE, install the UDF, verify, and run the example.

## Quick start (Docker)
1) Build the image (on Apple Silicon use `--platform linux/amd64`; multi-stage builder handles headers)  
```sh
docker build --platform linux/amd64 -t simple-oracle-udf .
```

2) Run Oracle XE (set your own strong password)  
```sh
docker run -d --name oracle-udf \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PASSWORD=YourPwd123 \
  simple-oracle-udf
```
First startup takes a couple minutes; tail logs with `docker logs -f oracle-udf` until you see `DATABASE IS READY TO USE`.

3) Install the UDF and test it  
```sh
docker exec oracle-udf sqlplus -s / as sysdba @/opt/oracle/udf/string_udf.sql
docker exec oracle-udf sqlplus -s system/YourPwd123@localhost/XEPDB1 @/opt/oracle/udf/example.sql
```
Expected output: `Hello from the Oracle UDF!`
Note: we explicitly run `string_udf.sql` after the DB is ready to avoid relying on image hooks. If you reuse a persisted XE volume/container, re-run the SQL manually as above.

### One-liner local helper
On macOS/arm64 (uses amd64 emulation) or Linux:
```sh
./run_local.sh
```
This rebuilds the image, wipes any `oracle*` volumes, starts XE, runs `string_udf.sql`, verifies objects, and runs `example.sql`.

## CI (GitHub Actions)
- Workflow: `.github/workflows/ci.yml`
- What it does: builds the image for `linux/amd64`, spins up Oracle XE, waits for readiness (`DATABASE IS READY TO USE`), then runs `example.sql` via `sqlplus` inside the container.
- Notes: Uses `ORACLE_PASSWORD=TestPwd123` for the ephemeral container. Timeout is 10 minutes to allow XE to bootstrap.

## Running on a DigitalOcean droplet (x86_64)
1) Create an x86_64 droplet (e.g., Ubuntu 22.04). For Oracle XE, pick at least 2 vCPU / 4 GB RAM.  
2) Install Docker:  
```sh
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```
3) Clone and build:  
```sh
git clone https://github.com/<your-username>/Simple-Oracle-UDF.git
cd Simple-Oracle-UDF
docker build --platform linux/amd64 -t simple-oracle-udf .
```
4) Run, install, and test (adjust password):  
```sh
docker run -d --name oracle-udf -p 1521:1521 -p 5500:5500 -e ORACLE_PASSWORD=YourPwd123 simple-oracle-udf
docker logs -f oracle-udf   # wait for DATABASE IS READY TO USE
docker exec oracle-udf sqlplus -s / as sysdba @/opt/oracle/udf/string_udf.sql
docker exec -it oracle-udf sqlplus system/YourPwd123@localhost/XEPDB1 @/opt/oracle/udf/example.sql
```

## Building locally (outside Docker)
1) Point `ORACLE_HOME` at your Oracle installation (headers and `libclntsh` must be present).  
```sh
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
make
```
2) Load the library and wrapper into your database (adjust the path if you place the `.so` elsewhere):  
```sql
@string_udf.sql
```

## Extending the UDF
Inside `string_udf.c` you can:
- Mask or redact: replace parts of `input` before returning (e.g., preserve last 4 chars, replace the rest with `*`).
- Call external libs: link against an encryption or hashing library and return ciphertext/digests.
- Validate/enrich: reject inputs that fail a regex check, or prepend context info before returning.
Remember to keep return size ≤ 4000 bytes and use `OCIExtProcAllocCallMemory` for allocations.

## Notes
- Errors: `NULL` input -> ORA-20000, input over 4000 bytes -> ORA-20001; allocation failure yields ORA-20003.
- The wrapper uses `WITH CONTEXT` plus a return indicator so Oracle can handle `NULL` results cleanly.
- The shared library is copied to `${ORACLE_HOME}/lib` inside the image for convenience; adjust `string_udf.sql` if you relocate it.

## License
MIT — see [LICENSE](LICENSE).

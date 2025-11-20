FROM oraclelinux:8 AS builder

ENV ORACLE_HOME=/usr/lib/oracle/21/client64

RUN yum install -y \
      gcc make \
      oracle-instantclient-release-el8 && \
    yum install -y \
      oracle-instantclient-basic \
      oracle-instantclient-devel && \
    yum clean all

WORKDIR /work
COPY string_udf.c Makefile ./

RUN make

FROM gvenzl/oracle-xe:21

USER root

ENV ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
ENV PATH=${ORACLE_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${ORACLE_HOME}/lib

WORKDIR /opt/oracle/udf
COPY --from=builder /work/string_udf.so .
COPY example.sql string_udf.sql string_udf_install.sh ./

RUN cp string_udf.so ${ORACLE_HOME}/lib/ && \
    chown -R oracle:dba /opt/oracle/udf ${ORACLE_HOME}/lib/string_udf.so && \
    chmod 755 /opt/oracle/udf/string_udf.so ${ORACLE_HOME}/lib/string_udf.so

RUN mkdir -p /opt/oracle/scripts/setup /opt/oracle/scripts/startup && \
    cp string_udf_install.sh /opt/oracle/scripts/setup/00-string-udf.sh && \
    cp string_udf_install.sh /opt/oracle/scripts/startup/00-string-udf.sh && \
    chown oracle:dba /opt/oracle/scripts/setup/00-string-udf.sh /opt/oracle/scripts/startup/00-string-udf.sh && \
    chmod 755 /opt/oracle/scripts/setup/00-string-udf.sh /opt/oracle/scripts/startup/00-string-udf.sh

USER oracle

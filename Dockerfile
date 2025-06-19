FROM ubuntu:25.04


COPY cpanfile /

ENV EV_EXTRA_DEFS=-DEV_NO_ATFORK
ENV DEBIAN_FRONTEND=noninteractive 

RUN  apt-get update && apt-get install make g++ curl wget checkinstall -y 

RUN apt-get update && \
  apt-get install perl cpanminus libio-socket-ssl-perl postgresql postgresql-server-dev-17 postgresql-17-pgvector libpq-dev libdbd-pg-perl r-base r-recommended -y && \
  cpanm -v -f --installdeps . -M https://cpan.metacpan.org && \
  rm -rf /root/.cpanm/* /usr/local/share/man/*

RUN mkdir /app
COPY Application /app
COPY sql_template.sql /app
COPY entrypoint.sh /app
RUN ln -s /usr/bin/R /usr/local/bin/R
RUN R -e "install.packages(c('rjson'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

RUN echo "local all  all  trust" > /etc/postgresql/17/main/pg_hba.conf && \
    echo "host  all  all  127.0.0.1/32 trust" >> /etc/postgresql/17/main/pg_hba.conf && \
    echo "host  all  all  ::1/128    trust" >> /etc/postgresql/17/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/17/main/postgresql.conf

RUN /etc/init.d/postgresql start && \
    until pg_isready -U postgres; do echo "Waiting for PostgreSQL..."; sleep 1; done && \
    psql -U postgres --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" 2>&1 | tee /tmp/psql_create_user.log && \
    createdb -U docker llm_patchbay 2>&1 | tee /tmp/psql_createdb.log && \
    psql -U docker llm_patchbay < /app/sql_template.sql 2>&1 | tee /tmp/psql_import.log

# RUN curl -fsSL https://ollama.com/install.sh | sh
# COPY install_ollama.sh /app
# RUN /app/install_ollama.sh

WORKDIR /app
EXPOSE 3036

ENTRYPOINT ["/app/entrypoint.sh"]
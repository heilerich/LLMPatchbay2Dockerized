FROM perl:5-bookworm

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ENV DEBIAN_FRONTEND=noninteractive 

RUN --mount=target=/var/lib/apt/lists,type=cache --mount=type=cache,target=/var/cache/apt apt-get update && apt-get install --no-install-recommends -y postgresql-common r-base r-recommended pandoc poppler-utils && \
  /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && apt-get install --no-install-recommends -y postgresql postgresql-17-pgvector

COPY cpanfile /usr/src/app

RUN --mount=type=cache,target=/root/.cpanm cpanm -v -f --installdeps --notest . -M https://cpan.metacpan.org

RUN ln -s /usr/bin/R /usr/local/bin/R && \
    R -e "install.packages(c('rjson'), dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    echo "local all  all  trust" > /etc/postgresql/17/main/pg_hba.conf && \
    echo "host  all  all  127.0.0.1/32 trust" >> /etc/postgresql/17/main/pg_hba.conf && \
    echo "host  all  all  ::1/128    trust" >> /etc/postgresql/17/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/17/main/postgresql.conf

COPY sql_template.sql .
RUN /etc/init.d/postgresql start && \
    until pg_isready -U postgres; do echo "Waiting for PostgreSQL..."; sleep 1; done && \
    psql -U postgres --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" 2>&1 | tee /tmp/psql_create_user.log && \
    createdb -U docker llm_patchbay 2>&1 | tee /tmp/psql_createdb.log && \
    psql -U docker llm_patchbay < sql_template.sql 2>&1 | tee /tmp/psql_import.log

COPY entrypoint.sh .
COPY Application .

VOLUME /var/lib/postgresql/17/main

# RUN curl -fsSL https://ollama.com/install.sh | sh
# COPY install_ollama.sh /app
# RUN /app/install_ollama.sh

EXPOSE 3036

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

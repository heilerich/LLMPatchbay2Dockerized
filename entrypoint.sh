#!/bin/sh
/etc/init.d/postgresql start && hypnotoad -f /app/backend.pl

# ollama support would go like this:
# /etc/init.d/postgresql start && hypnotoad /app/backend.pl && ollama serve

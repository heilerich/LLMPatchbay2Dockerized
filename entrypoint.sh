#!/bin/sh
/etc/init.d/postgresql start && hypnotoad -f /app/backend.pl # && ollama serve

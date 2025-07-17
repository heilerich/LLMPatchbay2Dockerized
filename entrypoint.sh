#!/bin/bash

PGDIR=/var/lib/postgresql/17/main
if [ ! -d "$PGDIR" ]; then
  cp -r /tmp/pginit $PGDIR
fi

# Start the PostgreSQL service
/etc/init.d/postgresql start

# Check if the 'ollama' command exists and is executable
if [ -x "$(command -v ollama)" ]; then
  echo "Ollama detected, starting service in the background..."
  ollama serve &
else
  echo "Ollama not found, skipping."
fi

# Start the main application in the foreground
echo "Starting LLMPatchbay backend..."
hypnotoad -f /usr/src/app/backend.pl &
tail -f /var/log/postgresql/postgresql-17-main.log &

wait

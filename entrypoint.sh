#!/bin/bash

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
hypnotoad -f /usr/src/app/backend.pl

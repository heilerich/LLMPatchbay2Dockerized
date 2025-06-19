echo "Starting Ollama server..."
ollama serve &


sleep 5

ollama pull gemma2:9b-text-q8_0
ollama pull mxbai-embed-large:latest
ollama pull bge-m3:latest
ollama pull snowflake-arctic-embed:latest
ollama pull bge-m3:latest
ollama pull paraphrase-multilingual:latest
ollama pull nomic-embed-text:latest
ollama pull jina/jina-embeddings-v2-base-de:latest
ollama pull stanus74/e5-base-sts-en-de
ollama pull jeffh/intfloat-multilingual-e5-large-instruct:f16
ollama ls


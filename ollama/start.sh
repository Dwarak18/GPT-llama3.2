#!/bin/sh
set -e

echo "Starting Ollama server..."
# Start Ollama server in background
ollama serve &
OLLAMA_PID=$!

echo "Waiting for Ollama server to start..."
# Wait for Ollama to be ready
for i in $(seq 1 30); do
    if curl -f http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "Ollama server is ready!"
        break
    fi
    echo "Waiting for Ollama server... ($i/30)"
    sleep 2
done

echo "Pulling llama3.2:1b-instruct-q4_K_M model..."
# Pull the required model
ollama pull llama3.2:1b-instruct-q4_K_M

# Verify model is available
echo "Verifying model availability..."
ollama list

echo "Model pulled successfully! Ollama is ready to serve requests."

# Keep the container running by waiting for the Ollama process
wait $OLLAMA_PID

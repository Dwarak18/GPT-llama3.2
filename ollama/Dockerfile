# Ollama Dockerfile with llama3.2 model
FROM ollama/ollama:latest

# Set environment variables
ENV OLLAMA_HOST=0.0.0.0:11434

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Expose the Ollama port
EXPOSE 11434

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Use ENTRYPOINT to run the startup script with sh
ENTRYPOINT ["/bin/sh", "/start.sh"]

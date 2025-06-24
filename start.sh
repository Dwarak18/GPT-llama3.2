#!/bin/bash

echo "🚀 Starting AI Chat App with Ollama..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Build and start all services
echo "📦 Building and starting services..."
docker-compose build --no-cache

echo "🎯 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."

# Wait for backend to be ready
echo "🔄 Checking backend health..."
for i in {1..30}; do
    if curl -f http://localhost:3001/ > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    echo "⏳ Waiting for backend... ($i/30)"
    sleep 2
done

# Wait for Ollama to be ready
echo "🔄 Checking Ollama health..."
for i in {1..60}; do
    if curl -f http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready!"
        break
    fi
    echo "⏳ Waiting for Ollama... ($i/60)"
    sleep 2
done

# Check if required model is available
echo "🤖 Checking if llama3.2:1b-instruct-q4_K_M model is available..."
if curl -f http://localhost:3001/health/ollama > /dev/null 2>&1; then
    echo "✅ Model health check passed!"
else
    echo "⚠️  Model might still be downloading. This can take several minutes..."
fi

# Show service status
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "🎉 Setup complete!"
echo "📱 Frontend: http://localhost:8080 (serve index.html with a local server)"
echo "🔧 Backend API: http://localhost:3001"
echo "🤖 Ollama API: http://localhost:11434"
echo ""
echo "📋 To view logs: docker-compose logs -f"
echo "🛑 To stop: docker-compose down"
echo ""
echo "💡 If the AI model is not responding:"
echo "   1. Check logs: docker-compose logs ollama"
echo "   2. The model might still be downloading (this can take 5-15 minutes)"
echo "   3. Check model availability: curl http://localhost:3001/health/ollama"

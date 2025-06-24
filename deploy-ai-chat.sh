#!/bin/bash

# AI Chat App - Complete Deployment Automation
# Usage: ./deploy-ai-chat.sh [OPTIONS]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check available RAM (in GB)
    if command_exists free; then
        RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$RAM_GB" -lt 4 ]; then
            print_warning "Low RAM detected: ${RAM_GB}GB. Recommended: 4GB+"
        else
            print_success "RAM check passed: ${RAM_GB}GB available"
        fi
    fi
    
    # Check disk space (in GB)
    DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_GB" -lt 10 ]; then
        print_warning "Low disk space: ${DISK_GB}GB. Recommended: 10GB+"
    else
        print_success "Disk space check passed: ${DISK_GB}GB available"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install Docker if not present
    if ! command_exists docker; then
        print_status "Installing Docker..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            print_error "Please install Docker Desktop for Mac from https://docker.com"
            exit 1
        fi
    else
        print_success "Docker is already installed"
    fi
    
    # Install Docker Compose if not present
    if ! command_exists docker-compose; then
        print_status "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        print_success "Docker Compose is already installed"
    fi
    
    # Install Python if not present
    if ! command_exists python3; then
        print_status "Installing Python..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python3
        fi
    else
        print_success "Python is already installed"
    fi
}

# Function to clone or update repository
setup_project() {
    print_status "Setting up project..."
    
    if [ ! -d "webapp" ]; then
        if [ -d ".git" ]; then
            print_status "Already in git repository, pulling latest changes..."
            git pull origin main
        else
            print_status "Cloning repository..."
            git clone https://github.com/Dwarak18/GPT-llama3.2.git .
        fi
    fi
    
    # Navigate to webapp directory
    if [ -d "webapp" ]; then
        cd webapp
    fi
    
    print_success "Project setup complete"
}

# Function to check port availability
check_ports() {
    print_status "Checking port availability..."
    
    PORTS=(3001 8080 11434 27017)
    for port in "${PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Port $port is already in use"
            if [ "$QUICK_MODE" = false ]; then
                read -p "Kill process on port $port? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sudo kill -9 $(lsof -t -i:$port) 2>/dev/null || true
                    print_success "Process on port $port terminated"
                fi
            else
                sudo kill -9 $(lsof -t -i:$port) 2>/dev/null || true
                print_success "Process on port $port terminated"
            fi
        else
            print_success "Port $port is available"
        fi
    done
}

# Function to deploy services
deploy_services() {
    print_status "Deploying services with Docker Compose..."
    
    # Stop any existing services
    docker-compose down 2>/dev/null || true
    
    # Build and start services
    print_status "Building Docker images..."
    docker-compose build --no-cache
    
    print_status "Starting services..."
    docker-compose up -d
    
    print_success "Services started successfully"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to initialize..."
    print_warning "This may take 5-15 minutes for first-time setup (model download)"
    
    # Wait for backend
    print_status "Waiting for backend service..."
    for i in {1..60}; do
        if curl -s http://localhost:3001/ >/dev/null 2>&1; then
            print_success "Backend is ready"
            break
        fi
        sleep 5
        echo -n "."
    done
    
    # Wait for Ollama
    print_status "Waiting for Ollama service..."
    for i in {1..180}; do  # 15 minutes timeout
        if curl -s http://localhost:3001/health/ollama | grep -q "healthy" 2>/dev/null; then
            print_success "Ollama is ready"
            break
        fi
        sleep 5
        echo -n "."
    done
}

# Function to start frontend
start_frontend() {
    print_status "Starting frontend server..."
    
    # Kill any existing server on port 8080
    pkill -f "python.*http.server.*8080" 2>/dev/null || true
    
    # Start frontend server in background
    if command_exists python3; then
        python3 -m http.server 8080 > /dev/null 2>&1 &
    elif command_exists python; then
        python -m http.server 8080 > /dev/null 2>&1 &
    else
        print_error "Python not found. Please install Python to serve frontend."
        exit 1
    fi
    
    FRONTEND_PID=$!
    sleep 2
    
    print_success "Frontend server started (PID: $FRONTEND_PID)"
    echo "Frontend URL: http://localhost:8080"
}

# Function to run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    # Check Docker services
    print_status "Checking Docker services..."
    docker-compose ps
    
    # Check backend
    print_status "Testing backend..."
    if curl -s http://localhost:3001/ | grep -q "Backend is running"; then
        print_success "Backend health check passed"
    else
        print_error "Backend health check failed"
    fi
    
    # Check Ollama
    print_status "Testing Ollama..."
    if curl -s http://localhost:3001/health/ollama | grep -q "healthy"; then
        print_success "Ollama health check passed"
    else
        print_error "Ollama health check failed"
    fi
    
    # Check frontend
    print_status "Testing frontend..."
    if curl -s http://localhost:8080/ >/dev/null 2>&1; then
        print_success "Frontend health check passed"
    else
        print_error "Frontend health check failed"
    fi
}

# Function to show completion message
show_completion() {
    echo
    echo "🎉 AI Chat App Deployment Complete!"
    echo "=================================="
    echo
    echo "🌐 Access your app:"
    echo "   Frontend: http://localhost:8080"
    echo "   Backend:  http://localhost:3001"
    echo "   Ollama:   http://localhost:11434"
    echo
    echo "📋 Useful commands:"
    echo "   View logs:     docker-compose logs -f"
    echo "   Stop services: docker-compose down"
    echo "   Restart:       docker-compose restart"
    echo "   Health check:  ./deploy-ai-chat.sh --health-only"
    echo
    echo "🚀 Your AI Chat App is ready to use!"
    echo "   Open http://localhost:8080 in your browser"
}

# Function to handle cleanup
cleanup() {
    print_status "Cleaning up..."
    docker-compose down 2>/dev/null || true
    pkill -f "python.*http.server.*8080" 2>/dev/null || true
    print_success "Cleanup complete"
}

# Function to show help
show_help() {
    echo "AI Chat App - Deployment Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --quick         Skip confirmations and run automatically"
    echo "  --dev           Development mode with detailed logging"
    echo "  --cleanup       Stop services and clean up"
    echo "  --health-only   Run health checks only"
    echo "  --no-frontend   Skip frontend server startup"
    echo "  --logs          Show service logs after deployment"
    echo ""
    echo "Examples:"
    echo "  $0              # Interactive deployment"
    echo "  $0 --quick      # Automated deployment"
    echo "  $0 --cleanup    # Stop all services"
    echo "  $0 --logs       # Deploy and show logs"
}

# Main deployment function
main() {
    echo "🚀 AI Chat App - Automated Deployment"
    echo "====================================="
    echo
    
    # Parse command line arguments
    QUICK_MODE=false
    DEV_MODE=false
    CLEANUP_MODE=false
    HEALTH_ONLY=false
    NO_FRONTEND=false
    SHOW_LOGS=false
    
    for arg in "$@"; do
        case $arg in
            --help)
                show_help
                exit 0
                ;;
            --quick)
                QUICK_MODE=true
                ;;
            --dev)
                DEV_MODE=true
                set -x  # Enable debug mode
                ;;
            --cleanup)
                CLEANUP_MODE=true
                ;;
            --health-only)
                HEALTH_ONLY=true
                ;;
            --no-frontend)
                NO_FRONTEND=true
                ;;
            --logs)
                SHOW_LOGS=true
                ;;
            *)
                print_error "Unknown option: $arg"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle cleanup mode
    if [ "$CLEANUP_MODE" = true ]; then
        cleanup
        exit 0
    fi
    
    # Handle health check only mode
    if [ "$HEALTH_ONLY" = true ]; then
        run_health_checks
        exit 0
    fi
    
    # Run deployment steps
    if [ "$QUICK_MODE" = false ]; then
        read -p "Continue with AI Chat App deployment? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    check_requirements
    install_dependencies
    setup_project
    check_ports
    deploy_services
    wait_for_services
    
    if [ "$NO_FRONTEND" = false ]; then
        start_frontend
    fi
    
    run_health_checks
    show_completion
    
    # Show logs if requested
    if [ "$SHOW_LOGS" = true ]; then
        print_status "Showing service logs (Ctrl+C to exit)..."
        docker-compose logs -f
    fi
}

# Run main function with all arguments
main "$@"

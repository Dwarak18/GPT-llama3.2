#!/bin/bash

# AI Chat App - Quick Deploy Script
# Usage: curl -sSL https://raw.githubusercontent.com/Dwarak18/GPT-llama3.2/main/quick-deploy.sh | bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}🚀 AI Chat App - Quick Deploy${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

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

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to install dependencies based on OS
install_dependencies() {
    local os=$(detect_os)
    print_status "Detected OS: $os"
    print_status "Installing dependencies..."
    
    case $os in
        "linux")
            # Update package manager
            if command_exists apt-get; then
                sudo apt-get update -qq
                sudo apt-get install -y curl wget git python3 python3-pip lsof
            elif command_exists yum; then
                sudo yum update -y
                sudo yum install -y curl wget git python3 python3-pip lsof
            elif command_exists dnf; then
                sudo dnf update -y
                sudo dnf install -y curl wget git python3 python3-pip lsof
            fi
            
            # Install Docker if not present
            if ! command_exists docker; then
                print_status "Installing Docker..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
                print_success "Docker installed successfully"
            fi
            
            # Install Docker Compose if not present
            if ! command_exists docker-compose; then
                print_status "Installing Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                print_success "Docker Compose installed successfully"
            fi
            ;;
            
        "mac")
            # Check if Homebrew is installed
            if ! command_exists brew; then
                print_status "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install dependencies
            brew update
            brew install curl wget git python3
            
            # Install Docker if not present
            if ! command_exists docker; then
                print_warning "Please install Docker Desktop for Mac from https://docker.com/products/docker-desktop"
                print_warning "After installation, start Docker Desktop and try again"
                exit 1
            fi
            ;;
            
        "windows")
            print_warning "Windows detected. Please use PowerShell version instead:"
            print_warning "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Dwarak18/GPT-llama3.2/main/quick-deploy.ps1' -OutFile 'quick-deploy.ps1'; .\\quick-deploy.ps1"
            exit 1
            ;;
            
        *)
            print_error "Unsupported operating system: $OSTYPE"
            exit 1
            ;;
    esac
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Docker
    if ! command_exists docker; then
        print_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker Compose
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
        return 1
    fi
    
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
    
    print_success "System requirements check completed"
}

# Function to setup project
setup_project() {
    print_status "Setting up AI Chat App project..."
    
    # Create project directory
    PROJECT_DIR="ai-chat-app"
    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Directory $PROJECT_DIR already exists. Updating..."
        cd "$PROJECT_DIR"
        if [ -d ".git" ]; then
            git pull origin main || true
        fi
    else
        print_status "Cloning repository..."
        git clone https://github.com/Dwarak18/GPT-llama3.2.git "$PROJECT_DIR"
        cd "$PROJECT_DIR"
    fi
    
    # Navigate to ai-chat-app directory
    if [ -d "ai-chat-app" ]; then
        cd ai-chat-app
    else
        print_error "ai-chat-app directory not found in repository"
        exit 1
    fi
    
    print_success "Project setup completed"
}

# Function to check and free ports
check_ports() {
    print_status "Checking port availability..."
    
    PORTS=(3001 8080 11434 27017)
    for port in "${PORTS[@]}"; do
        if command_exists lsof && lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Port $port is already in use"
            print_status "Attempting to free port $port..."
            
            # Try to kill the process using the port
            PID=$(lsof -t -i:$port)
            if [ ! -z "$PID" ]; then
                sudo kill -9 $PID 2>/dev/null || true
                sleep 2
                
                # Check if port is now free
                if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                    print_success "Port $port is now available"
                else
                    print_warning "Port $port is still in use, continuing anyway..."
                fi
            fi
        else
            print_success "Port $port is available"
        fi
    done
}

# Function to deploy services
deploy_services() {
    print_status "Deploying AI Chat App services..."
    
    # Stop any existing services
    print_status "Stopping existing services..."
    docker-compose down 2>/dev/null || true
    
    # Build and start services
    print_status "Building Docker images (this may take a few minutes)..."
    docker-compose build --no-cache
    
    print_status "Starting services..."
    docker-compose up -d
    
    print_success "Services deployment initiated"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to initialize..."
    print_warning "This may take 5-15 minutes for first-time setup (AI model download)"
    
    # Wait for backend
    print_status "Waiting for backend service..."
    for i in {1..60}; do
        if curl -s http://localhost:3001/ >/dev/null 2>&1; then
            print_success "Backend is ready"
            break
        fi
        sleep 5
        printf "."
    done
    echo
    
    # Wait for Ollama
    print_status "Waiting for Ollama AI service..."
    print_warning "AI model download in progress... please be patient"
    
    for i in {1..180}; do  # 15 minutes timeout
        if curl -s http://localhost:3001/health/ollama 2>/dev/null | grep -q "healthy"; then
            print_success "Ollama AI service is ready"
            break
        fi
        sleep 5
        printf "."
    done
    echo
    
    # Final health check
    print_status "Running final health checks..."
    sleep 5
    
    # Check backend
    if curl -s http://localhost:3001/ | grep -q "Backend is running"; then
        print_success "✅ Backend health check passed"
    else
        print_error "❌ Backend health check failed"
    fi
    
    # Check Ollama
    if curl -s http://localhost:3001/health/ollama | grep -q "healthy"; then
        print_success "✅ Ollama health check passed"
    else
        print_error "❌ Ollama health check failed"
    fi
}

# Function to start frontend
start_frontend() {
    print_status "Starting frontend web server..."
    
    # Kill any existing HTTP server on port 8080
    pkill -f "python.*http.server.*8080" 2>/dev/null || true
    
    # Start frontend server in background
    if command_exists python3; then
        nohup python3 -m http.server 8080 >/dev/null 2>&1 &
        FRONTEND_PID=$!
    elif command_exists python; then
        nohup python -m http.server 8080 >/dev/null 2>&1 &
        FRONTEND_PID=$!
    else
        print_error "Python not found. Please install Python to serve frontend."
        return 1
    fi
    
    sleep 3
    
    # Test frontend
    if curl -s http://localhost:8080/ >/dev/null 2>&1; then
        print_success "Frontend server started successfully (PID: $FRONTEND_PID)"
    else
        print_error "Frontend server failed to start"
        return 1
    fi
}

# Function to show completion message
show_completion() {
    echo
    echo -e "${GREEN}🎉 AI Chat App Deployment Complete!${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo
    echo -e "${CYAN}🌐 Access your AI Chat App:${NC}"
    echo -e "   ${YELLOW}Frontend:${NC} http://localhost:8080"
    echo -e "   ${YELLOW}Backend:${NC}  http://localhost:3001"
    echo -e "   ${YELLOW}Ollama:${NC}   http://localhost:11434"
    echo
    echo -e "${CYAN}📋 Useful commands:${NC}"
    echo -e "   ${YELLOW}View logs:${NC}     docker-compose logs -f"
    echo -e "   ${YELLOW}Stop services:${NC} docker-compose down"
    echo -e "   ${YELLOW}Restart:${NC}       docker-compose restart"
    echo -e "   ${YELLOW}Status:${NC}        docker-compose ps"
    echo
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "   1. Open ${YELLOW}http://localhost:8080${NC} in your browser"
    echo -e "   2. Sign up for a new account"
    echo -e "   3. Start chatting with the AI!"
    echo
    echo -e "${GREEN}Your AI Chat App is ready to use!${NC}"
    echo
    
    # Try to open browser automatically
    if command_exists xdg-open; then
        print_status "Opening browser..."
        xdg-open http://localhost:8080 >/dev/null 2>&1 &
    elif command_exists open; then
        print_status "Opening browser..."
        open http://localhost:8080 >/dev/null 2>&1 &
    fi
}

# Function to handle errors
handle_error() {
    print_error "Deployment failed. Cleaning up..."
    
    # Stop services
    docker-compose down 2>/dev/null || true
    
    # Kill frontend server
    pkill -f "python.*http.server.*8080" 2>/dev/null || true
    
    echo
    print_error "❌ Deployment failed. Please check the error messages above."
    print_status "For troubleshooting, visit: https://github.com/Dwarak18/GPT-llama3.2"
    echo
    exit 1
}

# Function to check internet connection
check_internet() {
    print_status "Checking internet connection..."
    if ! curl -s --head --request GET https://google.com >/dev/null; then
        print_error "No internet connection. Please check your network and try again."
        exit 1
    fi
    print_success "Internet connection verified"
}

# Main function
main() {
    # Set trap for error handling
    trap handle_error ERR
    
    print_header
    
    print_status "Starting AI Chat App quick deployment..."
    echo
    
    # Check internet connection
    check_internet
    
    # Install dependencies
    install_dependencies
    
    # Check system requirements
    check_requirements
    
    # Setup project
    setup_project
    
    # Check ports
    check_ports
    
    # Deploy services
    deploy_services
    
    # Wait for services
    wait_for_services
    
    # Start frontend
    start_frontend
    
    # Show completion message
    show_completion
    
    # Remove error trap since we completed successfully
    trap - ERR
}

# Run main function
main "$@"

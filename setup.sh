#!/bin/bash

# AI Chat App - Automated Setup Script
# This script installs all dependencies and sets up the project

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                  AI Chat App Setup Script                    ║"
    echo "║              Automated Dependency Installation               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="redhat"
        elif [ -f /etc/arch-release ]; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS="windows"
        DISTRO="windows"
    else
        OS="unknown"
        DISTRO="unknown"
    fi
    
    log_info "Detected OS: $OS ($DISTRO)"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    log_step "Checking system requirements..."
    
    # Check available RAM
    if [[ "$OS" == "linux" ]]; then
        TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OS" == "macos" ]]; then
        TOTAL_RAM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    else
        TOTAL_RAM=8  # Assume sufficient for Windows
    fi
    
    if [ "$TOTAL_RAM" -lt 4 ]; then
        log_warning "Low RAM detected: ${TOTAL_RAM}GB. Minimum 4GB recommended."
    else
        log_success "RAM: ${TOTAL_RAM}GB (sufficient)"
    fi
    
    # Check available disk space
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${AVAILABLE_SPACE%.*}" -lt 10 ]; then
        log_warning "Low disk space: ${AVAILABLE_SPACE}GB available. 10GB+ recommended."
    else
        log_success "Disk space: ${AVAILABLE_SPACE}GB available (sufficient)"
    fi
}

# Install Docker
install_docker() {
    log_step "Installing Docker..."
    
    if command_exists docker; then
        log_success "Docker already installed: $(docker --version)"
        return 0
    fi
    
    case $DISTRO in
        "debian")
            log_info "Installing Docker on Debian/Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
            ;;
        "redhat")
            log_info "Installing Docker on RedHat/CentOS/Fedora..."
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose
            ;;
        "arch")
            log_info "Installing Docker on Arch Linux..."
            sudo pacman -Sy docker docker-compose
            ;;
        "macos")
            log_info "Installing Docker on macOS..."
            if command_exists brew; then
                brew install --cask docker
            else
                log_error "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported distribution for automatic Docker installation"
            log_info "Please install Docker manually from https://docs.docker.com/get-docker/"
            return 1
            ;;
    esac
    
    # Add user to docker group (Linux only)
    if [[ "$OS" == "linux" ]]; then
        sudo usermod -aG docker $USER
        log_warning "Added user to docker group. Please log out and back in for changes to take effect."
    fi
    
    # Start Docker service
    if [[ "$OS" == "linux" ]]; then
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    log_success "Docker installation completed"
}

# Install Docker Compose (if not included with Docker)
install_docker_compose() {
    log_step "Checking Docker Compose..."
    
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose already available"
        return 0
    fi
    
    log_info "Installing Docker Compose..."
    
    case $OS in
        "linux")
            # Install latest docker-compose
            LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
            sudo curl -L "https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "macos")
            if command_exists brew; then
                brew install docker-compose
            else
                log_error "Please install Homebrew first or install Docker Desktop"
                return 1
            fi
            ;;
    esac
    
    log_success "Docker Compose installation completed"
}

# Install Python (for HTTP server)
install_python() {
    log_step "Checking Python installation..."
    
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_success "Python3 already installed: $PYTHON_VERSION"
        return 0
    elif command_exists python; then
        PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
        if [[ $PYTHON_VERSION == 3.* ]]; then
            log_success "Python already installed: $PYTHON_VERSION"
            return 0
        fi
    fi
    
    log_info "Installing Python..."
    
    case $DISTRO in
        "debian")
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
            ;;
        "redhat")
            sudo yum install -y python3 python3-pip
            ;;
        "arch")
            sudo pacman -Sy python python-pip
            ;;
        "macos")
            if command_exists brew; then
                brew install python
            else
                log_error "Please install Homebrew first or Python manually"
                return 1
            fi
            ;;
        *)
            log_error "Please install Python 3.7+ manually"
            return 1
            ;;
    esac
    
    log_success "Python installation completed"
}

# Install Node.js (for alternative HTTP server)
install_nodejs() {
    log_step "Checking Node.js installation..."
    
    if command_exists node; then
        NODE_VERSION=$(node --version)
        log_success "Node.js already installed: $NODE_VERSION"
        return 0
    fi
    
    log_info "Installing Node.js..."
    
    case $DISTRO in
        "debian")
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "redhat")
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        "arch")
            sudo pacman -Sy nodejs npm
            ;;
        "macos")
            if command_exists brew; then
                brew install node
            else
                log_warning "Homebrew not found. Skipping Node.js installation."
                return 0
            fi
            ;;
        *)
            log_warning "Skipping Node.js installation for this platform"
            return 0
            ;;
    esac
    
    log_success "Node.js installation completed"
}

# Install Git
install_git() {
    log_step "Checking Git installation..."
    
    if command_exists git; then
        GIT_VERSION=$(git --version)
        log_success "Git already installed: $GIT_VERSION"
        return 0
    fi
    
    log_info "Installing Git..."
    
    case $DISTRO in
        "debian")
            sudo apt-get update
            sudo apt-get install -y git
            ;;
        "redhat")
            sudo yum install -y git
            ;;
        "arch")
            sudo pacman -Sy git
            ;;
        "macos")
            if command_exists brew; then
                brew install git
            else
                log_info "Git should be available through Xcode Command Line Tools"
                xcode-select --install 2>/dev/null || true
            fi
            ;;
        *)
            log_error "Please install Git manually"
            return 1
            ;;
    esac
    
    log_success "Git installation completed"
}

# Install curl
install_curl() {
    log_step "Checking curl installation..."
    
    if command_exists curl; then
        log_success "curl already installed"
        return 0
    fi
    
    log_info "Installing curl..."
    
    case $DISTRO in
        "debian")
            sudo apt-get update
            sudo apt-get install -y curl
            ;;
        "redhat")
            sudo yum install -y curl
            ;;
        "arch")
            sudo pacman -Sy curl
            ;;
        "macos")
            log_success "curl is pre-installed on macOS"
            ;;
        *)
            log_warning "Please install curl manually"
            ;;
    esac
    
    log_success "curl installation completed"
}

# Check Docker daemon
check_docker_daemon() {
    log_step "Checking Docker daemon..."
    
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker daemon is not running"
        
        if [[ "$OS" == "linux" ]]; then
            log_info "Starting Docker daemon..."
            sudo systemctl start docker
            sleep 2
            
            if docker info >/dev/null 2>&1; then
                log_success "Docker daemon started successfully"
            else
                log_error "Failed to start Docker daemon. Please check Docker installation."
                return 1
            fi
        else
            log_warning "Please start Docker Desktop manually"
            return 1
        fi
    else
        log_success "Docker daemon is running"
    fi
}

# Setup project
setup_project() {
    log_step "Setting up project..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml not found. Please run this script from the project root directory."
        return 1
    fi
    
    # Make scripts executable
    if [ -f "start.sh" ]; then
        chmod +x start.sh
        log_success "Made start.sh executable"
    fi
    
    if [ -f "start.ps1" ]; then
        log_success "Found start.ps1 (Windows PowerShell script)"
    fi
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        log_info "Creating .env file with default values..."
        cat > .env << EOF
# Environment Variables for AI Chat App
MONGO_URL=mongodb://mongo:27017/chatapp
OLLAMA_URL=http://ollama:11434
NODE_ENV=development
BACKEND_PORT=3001
FRONTEND_PORT=8080
EOF
        log_success "Created .env file"
    else
        log_success ".env file already exists"
    fi
    
    log_success "Project setup completed"
}

# Final verification
verify_installation() {
    log_step "Verifying installation..."
    
    local all_good=true
    
    # Check Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        log_success "Docker: OK"
    else
        log_error "Docker: FAILED"
        all_good=false
    fi
    
    # Check Docker Compose
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose: OK"
    else
        log_error "Docker Compose: FAILED"
        all_good=false
    fi
    
    # Check Python
    if command_exists python3 || command_exists python; then
        log_success "Python: OK"
    else
        log_warning "Python: NOT FOUND (optional for HTTP server)"
    fi
    
    # Check Git
    if command_exists git; then
        log_success "Git: OK"
    else
        log_warning "Git: NOT FOUND"
    fi
    
    # Check curl
    if command_exists curl; then
        log_success "curl: OK"
    else
        log_warning "curl: NOT FOUND"
    fi
    
    if $all_good; then
        log_success "All essential dependencies installed successfully!"
        return 0
    else
        log_error "Some essential dependencies failed to install"
        return 1
    fi
}

# Usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --skip-docker       Skip Docker installation"
    echo "  --skip-python       Skip Python installation"
    echo "  --skip-node         Skip Node.js installation"
    echo "  --verify-only       Only verify existing installations"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full installation"
    echo "  $0 --skip-docker    # Install everything except Docker"
    echo "  $0 --verify-only    # Only check what's already installed"
}

# Print next steps
show_next_steps() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                        NEXT STEPS                            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "1. Build the Docker images:"
    echo "   docker-compose build --no-cache"
    echo ""
    
    log_info "2. Start the services:"
    echo "   docker-compose up -d"
    echo ""
    
    log_info "3. Start the frontend server:"
    if command_exists python3; then
        echo "   python3 -m http.server 8080"
    elif command_exists python; then
        echo "   python -m http.server 8080"
    elif command_exists node; then
        echo "   npx http-server . -p 8080 -c-1"
    else
        echo "   # Install Python or Node.js to serve the frontend"
    fi
    echo ""
    
    log_info "4. Access the application:"
    echo "   Frontend: http://localhost:8080"
    echo "   Backend:  http://localhost:3001"
    echo ""
    
    log_info "5. Or use the automated startup script:"
    if [[ "$OS" == "linux" ]] || [[ "$OS" == "macos" ]]; then
        echo "   ./start.sh"
    else
        echo "   powershell -ExecutionPolicy Bypass -File start.ps1"
    fi
    echo ""
    
    if [[ "$OS" == "linux" ]] && groups $USER | grep &>/dev/null '\bdocker\b'; then
        log_warning "You may need to log out and back in for Docker group changes to take effect"
    fi
}

# Main execution
main() {
    local skip_docker=false
    local skip_python=false
    local skip_node=false
    local verify_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --skip-docker)
                skip_docker=true
                shift
                ;;
            --skip-python)
                skip_python=true
                shift
                ;;
            --skip-node)
                skip_node=true
                shift
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_banner
    
    log_info "Starting automated setup for AI Chat App..."
    log_info "This script will install all required dependencies"
    echo ""
    
    # Detect operating system
    detect_os
    
    if [ "$verify_only" = true ]; then
        log_info "Running verification only..."
        verify_installation
        exit $?
    fi
    
    # Check system requirements
    check_system_requirements
    echo ""
    
    # Install dependencies
    if [ "$skip_docker" = false ]; then
        install_docker
        install_docker_compose
        check_docker_daemon
        echo ""
    fi
    
    install_git
    install_curl
    
    if [ "$skip_python" = false ]; then
        install_python
    fi
    
    if [ "$skip_node" = false ]; then
        install_nodejs
    fi
    
    echo ""
    
    # Setup project
    setup_project
    echo ""
    
    # Verify installation
    if verify_installation; then
        echo ""
        show_next_steps
        log_success "Setup completed successfully! 🎉"
    else
        log_error "Setup completed with some issues. Please check the errors above."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"

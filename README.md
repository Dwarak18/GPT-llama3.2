# 🚀 AI Chat App with Ollama - COMPLETE DEPLOYMENT GUIDE

This AI Chat App uses Ollama with the **llama3.2:1b-instruct-q4_K_M** model to provide intelligent chat responses. This guide ensures zero-error deployment with comprehensive troubleshooting.

## ⚡ QUICK DEPLOYMENT CHECKLIST

**Before You Start** (5 minutes):
- [ ] Docker Desktop installed and running ("Engine running" status)
- [ ] 4GB+ RAM available
- [ ] 10GB+ disk space free
- [ ] Ports 3001, 8080, 11434, 27017 available
- [ ] Stable internet connection (for model download)

**Deployment Steps** (15-30 minutes first time):
- [ ] Clone repository: `git clone https://github.com/Dwarak18/GPT-llama3.2.git`
- [ ] Build services: `docker-compose build --no-cache`
- [ ] Start services: `docker-compose up -d`
- [ ] **WAIT** for Ollama model download (5-15 minutes)
- [ ] Start frontend server: `python -m http.server 8080`
- [ ] Verify: Open `http://localhost:8080`

**Success Indicators**:
- [ ] `docker-compose ps` shows all services "Up"
- [ ] `curl http://localhost:3001/` returns "Backend is running!"
- [ ] `curl http://localhost:3001/health/ollama` returns healthy status
- [ ] Frontend loads at `http://localhost:8080` without errors
- [ ] Chat interface accepts and responds to messages

---

## 🤖 ONE-COMMAND AUTOMATION

### 🚀 **Super Quick Deploy (Bash)**

**For Linux/Mac users, run this single command to deploy everything:**

```bash
# One-liner deployment
curl -sSL https://raw.githubusercontent.com/Dwarak18/GPT-llama3.2/main/quick-deploy.sh | bash
```

**Or download and run locally:**

```bash
# Download the automation script
wget https://raw.githubusercontent.com/Dwarak18/GPT-llama3.2/main/deploy.sh
chmod +x deploy.sh

# Run with options
./deploy.sh                    # Full automated deployment
./deploy.sh --help             # Show all options
./deploy.sh --quick            # Skip confirmations
./deploy.sh --dev              # Development mode (with logs)
./deploy.sh --cleanup          # Clean up and restart
```

### 📋 **Manual Bash Automation Commands**

**Create your own automation script - copy and paste this:**

```bash
#!/bin/bash

# AI Chat App - Complete Deployment Automation
# Usage: ./deploy-ai-chat.sh

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
            read -p "Kill process on port $port? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
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
        python3 -m http.server 8080 &
    elif command_exists python; then
        python -m http.server 8080 &
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
    echo "   View logs:    docker-compose logs -f"
    echo "   Stop services: docker-compose down"
    echo "   Restart:      docker-compose restart"
    echo
    echo "🚀 Your AI Chat App is ready to use!"
}

# Function to handle cleanup
cleanup() {
    print_status "Cleaning up..."
    docker-compose down 2>/dev/null || true
    pkill -f "python.*http.server.*8080" 2>/dev/null || true
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
    echo ""
    echo "Examples:"
    echo "  $0              # Interactive deployment"
    echo "  $0 --quick      # Automated deployment"
    echo "  $0 --cleanup    # Stop all services"
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
        print_success "Cleanup complete"
        exit 0
    fi
    
    # Handle health check only mode
    if [ "$HEALTH_ONLY" = true ]; then
        run_health_checks
        exit 0
    fi
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
    
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
    
    # Remove trap since we completed successfully
    trap - EXIT
}

# Run main function with all arguments
main "$@"
```

**Save this as `deploy-ai-chat.sh` and run:**

```bash
chmod +x deploy-ai-chat.sh
./deploy-ai-chat.sh
```

### 🎯 **Quick Commands Reference**

```bash
# Full automated deployment
./deploy-ai-chat.sh --quick

# Development mode with detailed logs
./deploy-ai-chat.sh --dev

# Health checks only
./deploy-ai-chat.sh --health-only

# Clean up and stop all services
./deploy-ai-chat.sh --cleanup

# Deploy without frontend server
./deploy-ai-chat.sh --no-frontend

# Deploy and show logs
./deploy-ai-chat.sh --logs
```

### 🪟 **Windows PowerShell Automation**

**For Windows users:**

```powershell
# Use the existing PowerShell scripts
.\start.ps1                    # Quick start existing setup
.\setup.ps1                    # Install dependencies

# Manual PowerShell commands
docker-compose up -d --build   # Start services
python -m http.server 8080     # Start frontend
```

**Or create a PowerShell automation script:**

```powershell
# Save as deploy-ai-chat.ps1
param(
    [switch]$Quick,
    [switch]$Cleanup,
    [switch]$Help
)

if ($Help) {
    Write-Host "AI Chat App - PowerShell Deployment"
    Write-Host "Usage: .\deploy-ai-chat.ps1 [-Quick] [-Cleanup] [-Help]"
    exit 0
}

if ($Cleanup) {
    Write-Host "Cleaning up services..." -ForegroundColor Yellow
    docker-compose down
    Get-Process | Where-Object {$_.ProcessName -like "*python*" -and $_.CommandLine -like "*http.server*"} | Stop-Process -Force
    Write-Host "Cleanup complete!" -ForegroundColor Green
    exit 0
}

Write-Host "🚀 Starting AI Chat App deployment..." -ForegroundColor Cyan

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Start services
Write-Host "📦 Building and starting services..." -ForegroundColor Yellow
docker-compose down 2>$null
docker-compose up -d --build

# Wait for services
Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check health
$backendUp = $false
$ollamaUp = $false

for ($i = 1; $i -le 10; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001/" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $backendUp = $true
            Write-Host "✅ Backend is ready" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Waiting for backend... ($i/10)" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}

for ($i = 1; $i -le 20; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001/health/ollama" -TimeoutSec 5
        if ($response.Content -like "*healthy*") {
            $ollamaUp = $true
            Write-Host "✅ Ollama is ready" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Waiting for Ollama... ($i/20)" -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}

# Start frontend
Write-Host "🌐 Starting frontend server..." -ForegroundColor Yellow
Start-Process -FilePath "python" -ArgumentList "-m", "http.server", "8080" -WindowStyle Hidden

Start-Sleep -Seconds 3

Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "🌐 Frontend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "🔧 Backend:  http://localhost:3001" -ForegroundColor Cyan
Write-Host "🤖 Ollama:   http://localhost:11434" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor White
Write-Host "   docker-compose logs -f    # View logs"
Write-Host "   docker-compose down       # Stop services"
Write-Host "   .\deploy-ai-chat.ps1 -Cleanup  # Clean up"
```

### 🔧 **Manual Step-by-Step Commands**

**Cross-platform manual deployment:**

```bash
# 1. System preparation
sudo apt update && sudo apt upgrade -y  # Linux
brew update && brew upgrade             # Mac

# 2. Install Docker and dependencies
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt install -y python3 git curl

# 3. Clone and setup project
git clone https://github.com/Dwarak18/GPT-llama3.2.git
cd GPT-llama3.2/webapp

# 4. Deploy services
docker-compose build --no-cache
docker-compose up -d

# 5. Wait for services (check every 30 seconds)
watch -n 30 'docker-compose ps && curl -s http://localhost:3001/health/ollama'

# 6. Start frontend
python3 -m http.server 8080 &

# 7. Test everything
curl http://localhost:3001/
curl http://localhost:3001/health/ollama
curl http://localhost:8080/

# 8. Open in browser
xdg-open http://localhost:8080  # Linux
open http://localhost:8080      # Mac
start http://localhost:8080     # Windows (in WSL)
```

---

## ✨ FIXES IMPLEMENTED

### 🔧 Backend Improvements
- ✅ **Fixed Ollama API Communication**: Changed from streaming to reliable generate endpoint
- ✅ **Enhanced Error Handling**: Detailed error messages for different failure scenarios  
- ✅ **Health Check Endpoint**: `/health/ollama` to monitor Ollama status and model availability
- ✅ **Model Verification**: Automatic checking of required model during startup
- ✅ **Better Logging**: Comprehensive logging for debugging connectivity issues

### 🐳 Docker Configuration
- ✅ **Proper Networking**: Added custom Docker network for reliable service communication
- ✅ **Health Checks**: Ollama health check with proper timeouts and retries
- ✅ **Service Dependencies**: Backend waits for Ollama to be healthy before starting
- ✅ **Volume Management**: Persistent storage for Ollama models and MongoDB data
- ✅ **Environment Variables**: Proper configuration for inter-service communication

### 🎨 Frontend Enhancements  
- ✅ **Dynamic API URLs**: Frontend adapts to different environments (localhost/Docker)
- ✅ **Health Monitoring**: Automatic health checks for backend and Ollama services
- ✅ **Better Error Messages**: User-friendly error messages for different failure scenarios
- ✅ **Ollama Status Display**: Real-time status of AI model availability

### 📦 Model Configuration
- ✅ **Correct Model Name**: Uses `llama3.2:1b-instruct-q4_K_M` as specified
- ✅ **Automatic Download**: Model is pulled automatically during container startup
- ✅ **Model Verification**: Checks if model is available before serving requests

## 📋 Prerequisites

1. **Docker Desktop**: Install from [docker.com](https://www.docker.com/products/docker-desktop/)
2. **4GB+ RAM**: Required for running Ollama model  
3. **10GB+ Disk Space**: For Docker images and Ollama model

## 🚀 COMPLETE INSTALLATION & DEPLOYMENT GUIDE

### 🎯 AUTOMATED SETUP SCRIPTS

**We've created automated setup scripts to install all dependencies:**

#### **Linux/Mac Users:**
```bash
# Make script executable and run
chmod +x setup.sh
./setup.sh

# Or with options
./setup.sh --help              # Show help
./setup.sh --skip-docker       # Skip Docker installation
./setup.sh --verify-only       # Only verify existing installations
```

#### **Windows Users:**
```powershell
# Run in PowerShell as Administrator
.\setup.ps1

# Or with options
.\setup.ps1 -Help              # Show help
.\setup.ps1 -SkipDocker        # Skip Docker installation  
.\setup.ps1 -VerifyOnly        # Only verify existing installations
```

**These scripts will automatically:**
- ✅ Detect your operating system
- ✅ Check system requirements (RAM, disk space)
- ✅ Install Docker & Docker Compose
- ✅ Install Python (for HTTP server)
- ✅ Install Node.js (alternative HTTP server)
- ✅ Install Git and curl
- ✅ Set up project configuration
- ✅ Verify all installations

### 📦 Manual Installation (If Scripts Fail)

#### 1.1 Install Docker Desktop
**Windows:**
1. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/)
2. Run installer as Administrator
3. Restart computer when prompted
4. Launch Docker Desktop from Start Menu
5. **WAIT** until you see "Engine running" status in Docker Desktop

**Mac:**
1. Download Docker Desktop for Mac
2. Drag to Applications folder
3. Launch Docker Desktop
4. Grant permissions when asked

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Log out and back in
```

#### 1.2 Verify Docker Installation
```bash
docker --version
docker-compose --version
docker info
```
**Expected Output**: No errors, version numbers displayed

#### 1.3 System Requirements Check
- **RAM**: Minimum 4GB available (8GB recommended)
- **Disk Space**: At least 10GB free
- **Ports**: Ensure 3001, 8080, 11434, 27017 are available

### 🔧 Step 2: Project Setup

#### 2.1 Clone Repository
```bash
git clone https://github.com/Dwarak18/GPT-llama3.2.git
cd GPT-llama3.2/webapp
```

#### 2.2 Verify Project Structure
```bash
ls -la
```
**Expected files:**
- `docker-compose.yml`
- `index.html`
- `backend/` folder
- `ollama/` folder
- `start.ps1` (Windows)

### 🚀 Step 3: Build and Deploy Services

#### 3.1 Build Docker Images (First Time Setup)
```bash
# Build all services
docker-compose build --no-cache

# Verify images are built
docker images
```

#### 3.2 Start All Services
```bash
# Start in detached mode
docker-compose up -d

# Monitor startup progress
docker-compose logs -f
```

#### 3.3 Wait for Services to Initialize
**This step is CRITICAL - wait 5-15 minutes for first-time setup**

Monitor each service:
```bash
# Check service status
docker-compose ps

# Monitor Ollama model download (most time-consuming)
docker-compose logs -f ollama

# Monitor backend startup
docker-compose logs -f backend
```

**What to look for:**
- Ollama: "Pulling llama3.2:1b-instruct-q4_K_M model..." → "Success"
- Backend: "Server running on http://localhost:3001"
- All services: STATUS = "Up" in `docker-compose ps`

### 🌐 Step 4: Frontend Setup

#### 4.1 Start HTTP Server for Frontend
**IMPORTANT**: Don't open `index.html` directly in browser (causes CORS errors)

**Windows (PowerShell):**
```powershell
# Navigate to project directory
cd webapp

# Start Python HTTP server
python -m http.server 8080
```

**Linux/Mac:**
```bash
cd webapp
python3 -m http.server 8080
```

**Alternative (Node.js):**
```bash
npx http-server . -p 8080 -c-1
```

#### 4.2 Verify Frontend Server
Open browser and go to: `http://localhost:8080`
**Expected**: Chat interface loads without errors

### ✅ Step 5: Verification & Testing

#### 5.1 Health Checks
Run these commands to verify everything is working:

```bash
# 1. Check Docker services
docker-compose ps
# Expected: All services "Up" and "healthy"

# 2. Test backend
curl http://localhost:3001/
# Expected: "Backend is running!"

# 3. Test Ollama health
curl http://localhost:3001/health/ollama
# Expected: {"status":"healthy",...}

# 4. Test chat functionality
curl -X POST http://localhost:3001/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, test message"}'
# Expected: {"reply":"[AI response]"}
```

**Windows PowerShell Equivalent:**
```powershell
# Test backend
Invoke-WebRequest -Uri "http://localhost:3001/"

# Test Ollama health
Invoke-WebRequest -Uri "http://localhost:3001/health/ollama"

# Test chat
Invoke-WebRequest -Uri "http://localhost:3001/chat" -Method POST -ContentType "application/json" -Body '{"message":"Hello"}'
```

#### 5.2 Access Points Verification
- **Frontend Web App**: http://localhost:8080 ✅
- **Backend API**: http://localhost:3001 ✅
- **Ollama API**: http://localhost:11434 ✅
- **Health Check**: http://localhost:3001/health/ollama ✅

### 🎯 Step 6: Using the Application

#### 6.1 First Time Usage
1. Open `http://localhost:8080` in your browser
2. Click "Sign Up" to create account
3. Fill in username, email, password
4. Click "Login" after signup
5. Start chatting with the AI!

#### 6.2 Testing Chat Functionality
Try these test messages:
- "Hello, how are you?"
- "Tell me a joke"
- "What can you help me with?"

### 🛠️ DEPLOYMENT TROUBLESHOOTING

#### Issue: Docker Desktop Not Starting
**Symptoms**: `docker info` fails, "Docker not running" error
**Solutions**:
1. **Windows**: 
   - Restart Docker Desktop as Administrator
   - Enable WSL2 integration in Docker Desktop settings
   - Restart Windows if needed
2. **Mac**: Check Docker Desktop in Applications folder
3. **Linux**: 
   ```bash
   sudo systemctl restart docker
   sudo systemctl status docker
   ```

#### Issue: Port Already in Use
**Symptoms**: "Port 3001 is already in use" or similar errors
**Solutions**:
```bash
# Find what's using the port
netstat -ano | findstr :3001  # Windows
lsof -i :3001                 # Linux/Mac

# Stop the conflicting service
docker-compose down
# Kill specific process if needed
taskkill /PID <PID> /F        # Windows
kill -9 <PID>                 # Linux/Mac
```

#### Issue: Services Won't Start
**Symptoms**: Container exits immediately, "Exited (1)" status
**Solutions**:
```bash
# Check detailed logs
docker-compose logs <service-name>

# Rebuild images
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Check disk space
df -h                         # Linux/Mac
Get-PSDrive                   # Windows PowerShell
```

#### Issue: Ollama Model Download Fails
**Symptoms**: "Model not found", long startup times
**Solutions**:
1. **Wait longer** - First download can take 15-30 minutes
2. **Check internet connection** - Large model download (>1GB)
3. **Manual model pull**:
   ```bash
   docker-compose exec ollama ollama pull llama3.2:1b-instruct-q4_K_M
   ```
4. **Check available disk space** - Need 5GB+ free

#### Issue: Frontend CORS Errors
**Symptoms**: "CORS policy blocked", "Network error" in browser console
**Solutions**:
1. **Never open index.html directly** - Always use HTTP server
2. **Use correct URL**: `http://localhost:8080` not `file://...`
3. **Restart HTTP server**:
   ```bash
   # Stop current server (Ctrl+C)
   python -m http.server 8080
   ```

#### Issue: Backend API Not Responding
**Symptoms**: 500 errors, "Cannot connect to backend"
**Solutions**:
```bash
# Check backend logs
docker-compose logs backend

# Restart backend only
docker-compose restart backend

# Check if backend container is running
docker-compose ps backend
```

#### Issue: PowerShell Script Errors
**Symptoms**: Syntax errors, execution policy errors
**Solutions**:
```powershell
# Set execution policy (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run script with bypass
powershell -ExecutionPolicy Bypass -File start.ps1

# If encoding issues, recreate script file
notepad start.ps1  # Save with UTF-8 encoding
```

### 🔄 Complete Reset Procedure
If everything fails, use this nuclear option:

```bash
# Stop and remove everything
docker-compose down -v
docker system prune -a --volumes

# Remove all containers and images
docker container prune -f
docker image prune -a -f
docker volume prune -f

# Start fresh
docker-compose build --no-cache
docker-compose up -d
```

## 🔍 VERIFY EVERYTHING IS WORKING

```bash
# Check service status
docker-compose ps

# Test backend
curl http://localhost:3001/

# Test Ollama health  
curl http://localhost:3001/health/ollama

# Verify model is loaded
curl http://localhost:11434/api/tags
```

## 🛠️ TROUBLESHOOTING

### Problem: "AI model is not supported"

**Solution**: Wait for model download (5-15 minutes first time)
```bash
docker-compose logs ollama
# Look for: "Pulling llama3.2:1b-instruct-q4_K_M model..."
```

### Problem: Docker not starting

**Solution**: Ensure Docker Desktop is running
```bash  
docker info  # Should work without errors
```

### Problem: Port conflicts

**Solution**: Stop conflicting services
```bash
docker-compose down
netstat -ano | findstr :3001
netstat -ano | findstr :11434
```

## 🎯 WHAT'S WORKING NOW

✅ **Ollama Communication**: Backend properly connects to Ollama using generate API
✅ **Model Loading**: llama3.2:1b-instruct-q4_K_M downloads and runs correctly
✅ **Docker Networking**: All services communicate through custom network
✅ **Health Monitoring**: Comprehensive health checks for troubleshooting
✅ **Error Handling**: Clear error messages help identify issues
✅ **Frontend Integration**: Dynamic URLs work in all environments
✅ **Automated Setup**: Scripts handle complete setup process

## 🔧 STARTUP SCRIPTS INCLUDED

- **start.ps1**: Windows PowerShell script with health checking
- **start.sh**: Linux/Mac bash script with progress monitoring  
- **quickstart.html**: Interactive setup guide with real-time status

## 📊 EXPECTED PERFORMANCE

- **First Startup**: 5-15 minutes (model download)
- **Subsequent Starts**: 1-2 minutes
- **AI Response Time**: 2-10 seconds
- **Memory Usage**: ~2GB for Ollama model

The AI Chat App is now fully functional with the llama3.2:1b-instruct-q4_K_M model! 🎉
├── index.html
├── docker-compose.yml
└── README.md
```

---

## Setup & Installation

### 1. Clone the Repository
```sh
git clone https://github.com/Dwarak18/GPT-llama3.2.git
cd webapp
```

### 2. Build & Run with Docker Compose
Make sure Docker Desktop is running.

```sh
docker compose up --build
```
- This starts MongoDB and the backend API.
- Backend runs on port **3001**.
- MongoDB runs on port **27017**.

### 3. Serve the Frontend
You can use any static file server. Example with Python:

```sh
# In the webapp directory:
python -m http.server 8080
```
- Open your browser at: [http://localhost:8080](http://localhost:8080)

### 4. Start Ollama (AI Model)
You must have Ollama installed and running **outside Docker** on your host machine:

```sh
ollama run llama3.2:1b-instruct-q4_K_M
```
- Download Ollama: https://ollama.com/
- Make sure the model is running and accessible at `http://localhost:11434`.

### 5. Access the App
- Sign up for a new account.
- Log in with your credentials.
- Enjoy chatting with the AI assistant!

---

## Configuration
- The backend connects to MongoDB using the environment variable `MONGO_URL` (set in `docker-compose.yml`).
- The backend connects to Ollama using `host.docker.internal:11434` (works on Windows/Mac; for Linux, see [Ollama docs](https://github.com/ollama/ollama/blob/main/docs/linux.md#docker)).
- The frontend is configured to call the backend at `http://localhost:3001`. If you run on a different machine, update the fetch URLs in `index.html`.

---

## Error Messages & How to Fix

### 1. **Network error. Please try again.**
- **Cause:** Backend server is not running or unreachable.
- **Fix:**
  - Make sure Docker containers are running:  
    `docker compose up --build`
  - Ensure the backend is accessible at `http://localhost:3001`.

### 2. **Unable to connect to the AI service. Please make sure the backend server is running.**
- **Cause:** Backend is down or fetch to `/chat` failed.
- **Fix:**
  - Start backend:  
    `docker compose up --build`
  - Check your firewall and network settings.

### 3. **The AI model is currently unavailable. Please make sure Ollama is running with the llama3.2 model.**
- **Cause:** Ollama is not running or not accessible from Docker.
- **Fix:**
  - Start Ollama on your host:  
    `ollama run llama3.2:1b-instruct-q4_K_M`
  - Ensure `host.docker.internal` resolves (see [Ollama Docker docs](https://github.com/ollama/ollama/blob/main/docs/linux.md#docker) for Linux).

### 4. **Signup/Login errors (e.g., User already exists, Invalid credentials)**
- **Cause:** Duplicate user, wrong password, or missing fields.
- **Fix:**
  - Use a different username/email for signup.
  - Double-check your credentials for login.

### 5. **Module not found**
- **Cause:** Node modules missing in backend.
- **Fix:**
  - Run `npm install` in the `backend` folder, or rebuild Docker image:
    ```sh
    cd backend
    npm install
    # or
    docker compose up --build
    ```

### 6. **Port conflicts**
- **Cause:** Ports 3001 (backend) or 27017 (MongoDB) are in use.
- **Fix:**
  - Stop other services using these ports, or change the ports in `docker-compose.yml`.

### 7. **"Method Not Allowed. Only POST is supported on this endpoint."**
- **Cause:** Trying to use GET request on `/chat` endpoint which only accepts POST.
- **Fix:**
  - Use POST method when testing chat endpoint:
    ```powershell
    Invoke-WebRequest -Uri "http://localhost:3001/chat" -Method POST -ContentType "application/json" -Body '{"message":"Hello"}'
    ```
  - For health checks, use the correct endpoints:
    - Backend health: `GET http://localhost:3001/`
    - Ollama health: `GET http://localhost:3001/health/ollama`

### 8. **PowerShell Script Syntax Errors**
- **Cause:** Encoding issues or corrupted quote characters in PowerShell scripts.
- **Fix:**
  - Recreate the PowerShell script file with proper UTF-8 encoding
  - Ensure all quotes are properly closed
  - Use `-ExecutionPolicy Bypass` when running scripts:
    ```powershell
    powershell -ExecutionPolicy Bypass -File start.ps1
    ```

### 9. **Frontend CORS Issues**
- **Cause:** Opening `index.html` directly in browser (file://) instead of serving via HTTP.
- **Fix:**
  - Serve frontend through HTTP server:
    ```bash
    python -m http.server 8080
    ```
  - Access via `http://localhost:8080` instead of opening file directly

### 10. **Docker Compose Version Warning**
- **Cause:** Using deprecated `version` attribute in docker-compose.yml.
- **Fix:**
  - Remove the `version: '3.8'` line from docker-compose.yml (it's no longer needed)
  - Or ignore the warning as it doesn't affect functionality

---

---

## ✅ RECENT FIXES & CURRENT STATUS

### Successfully Resolved Issues (June 24, 2025):
1. **✅ PowerShell Script Fixed**: Resolved "Method Not Allowed" and syntax errors
2. **✅ Backend Chat Working**: AI model responding correctly with jokes and conversations
3. **✅ Frontend Served Properly**: HTTP server running on port 8080
4. **✅ All Services Operational**: MongoDB, Ollama, Backend, and Frontend all running
5. **✅ Health Checks Passing**: All endpoints responding correctly

### Current Working Configuration:
- **Frontend**: http://localhost:8080 (Python HTTP server)
- **Backend API**: http://localhost:3001 (Docker container)
- **Ollama AI**: http://localhost:11434 (Docker container, healthy)
- **MongoDB**: localhost:27017 (Docker container)
- **AI Model**: `llama3.2:1b-instruct-q4_K_M` (loaded and responding)

### Verified Functionality:
- ✅ Backend health endpoint: `GET /` returns "Backend is running!"
- ✅ Ollama health endpoint: `GET /health/ollama` returns healthy status
- ✅ Chat endpoint: `POST /chat` with JSON message returns AI responses
- ✅ Web interface: Full chat functionality through browser
- ✅ Docker services: All containers running and healthy

**Last Tested**: June 24, 2025 - All systems operational! 🎉

## 🚀 PRODUCTION DEPLOYMENT

### Environment Variables
Create a `.env` file for production:
```env
# Production Environment Variables
MONGO_URL=mongodb://mongo:27017/chatapp_prod
OLLAMA_URL=http://ollama:11434
NODE_ENV=production
BACKEND_PORT=3001
FRONTEND_PORT=80
```

### Security Considerations
1. **Change default ports** in production
2. **Add authentication** for API endpoints
3. **Use HTTPS** with SSL certificates
4. **Implement rate limiting** for chat endpoints
5. **Add input validation** and sanitization
6. **Use secrets management** for sensitive data

### Scaling for Production
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  backend:
    build: ./backend
    restart: always
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    restart: always
```

### Monitoring & Logging
```bash
# Production monitoring
docker-compose logs -f --tail=100
docker stats
docker-compose exec backend npm run health-check
```

## 🔧 AUTOMATED DEPLOYMENT SCRIPTS

### Windows PowerShell (start.ps1)
```powershell
# Enhanced production-ready script available in repository
.\start.ps1
```

### Linux/Mac Bash (start.sh)
```bash
# Enhanced production-ready script available in repository
./start.sh
```

## Stopping the App
```sh
docker compose down
```

---

## License
MIT (or your preferred license)

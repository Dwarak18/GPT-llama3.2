# AI Chat App - Quick Deploy Script (PowerShell)
# Usage: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Dwarak18/GPT-llama3.2/main/quick-deploy.ps1" -OutFile "quick-deploy.ps1"; .\quick-deploy.ps1

param(
    [switch]$Help,
    [switch]$SkipBrowser
)

# Show help if requested
if ($Help) {
    Write-Host "AI Chat App - Quick Deploy Script"
    Write-Host "Usage: .\quick-deploy.ps1 [-Help] [-SkipBrowser]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help        Show this help message"
    Write-Host "  -SkipBrowser Don't automatically open browser"
    exit 0
}

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "🚀 AI Chat App - Quick Deploy" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Function to check system requirements
function Test-Requirements {
    Write-Status "Checking system requirements..."
    
    # Check Docker
    if (!(Test-Command "docker")) {
        Write-Error "Docker is not installed or not in PATH"
        Write-Error "Please install Docker Desktop from https://docker.com/products/docker-desktop"
        exit 1
    }
    
    # Check Docker Compose
    if (!(Test-Command "docker-compose")) {
        Write-Error "Docker Compose is not installed or not in PATH"
        Write-Error "Please install Docker Desktop which includes Docker Compose"
        exit 1
    }
    
    # Check if Docker daemon is running
    try {
        docker info | Out-Null
        Write-Success "Docker is running"
    } catch {
        Write-Error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    }
    
    # Check Python
    if (!(Test-Command "python")) {
        Write-Warning "Python is not installed. Attempting to install..."
        try {
            winget install Python.Python.3.11
            Write-Success "Python installed successfully"
        } catch {
            Write-Error "Failed to install Python. Please install manually from https://python.org"
            exit 1
        }
    } else {
        Write-Success "Python is available"
    }
    
    # Check Git
    if (!(Test-Command "git")) {
        Write-Warning "Git is not installed. Attempting to install..."
        try {
            winget install Git.Git
            Write-Success "Git installed successfully"
        } catch {
            Write-Error "Failed to install Git. Please install manually from https://git-scm.com"
            exit 1
        }
    } else {
        Write-Success "Git is available"
    }
    
    # Check available RAM
    $RAM_GB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($RAM_GB -lt 4) {
        Write-Warning "Low RAM detected: ${RAM_GB}GB. Recommended: 4GB+"
    } else {
        Write-Success "RAM check passed: ${RAM_GB}GB available"
    }
    
    # Check disk space
    $Disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $FreeSpace_GB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    if ($FreeSpace_GB -lt 10) {
        Write-Warning "Low disk space: ${FreeSpace_GB}GB. Recommended: 10GB+"
    } else {
        Write-Success "Disk space check passed: ${FreeSpace_GB}GB available"
    }
    
    Write-Success "System requirements check completed"
}

# Function to check and free ports
function Test-Ports {
    Write-Status "Checking port availability..."
    
    $Ports = @(3001, 8080, 11434, 27017)
    foreach ($Port in $Ports) {
        $Connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($Connection) {
            Write-Warning "Port $Port is already in use"
            try {
                $Process = Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue
                if ($Process) {
                    Write-Status "Stopping process $($Process.ProcessName) on port $Port..."
                    Stop-Process -Id $Process.Id -Force
                    Start-Sleep -Seconds 2
                    Write-Success "Port $Port is now available"
                }
            } catch {
                Write-Warning "Could not free port $Port, continuing anyway..."
            }
        } else {
            Write-Success "Port $Port is available"
        }
    }
}

# Function to setup project
function Setup-Project {
    Write-Status "Setting up AI Chat App project..."
    
    $ProjectDir = "ai-chat-app"
    if (Test-Path $ProjectDir) {
        Write-Warning "Directory $ProjectDir already exists. Updating..."
        Set-Location $ProjectDir
        if (Test-Path ".git") {
            try {
                git pull origin main
            } catch {
                Write-Warning "Failed to update repository, continuing with existing files..."
            }
        }
    } else {
        Write-Status "Cloning repository..."
        try {
            git clone https://github.com/Dwarak18/GPT-llama3.2.git $ProjectDir
            Set-Location $ProjectDir
        } catch {
            Write-Error "Failed to clone repository. Please check your internet connection."
            exit 1
        }
    }
    
    # Navigate to webapp directory
    if (Test-Path "webapp") {
        Set-Location "webapp"
    } else {
        Write-Error "webapp directory not found in repository"
        exit 1
    }
    
    Write-Success "Project setup completed"
}

# Function to deploy services
function Deploy-Services {
    Write-Status "Deploying AI Chat App services..."
    
    # Stop any existing services
    Write-Status "Stopping existing services..."
    try {
        docker-compose down
    } catch {
        # Ignore errors if no services are running
    }
    
    # Build and start services
    Write-Status "Building Docker images (this may take a few minutes)..."
    try {
        docker-compose build --no-cache
        Write-Success "Docker images built successfully"
    } catch {
        Write-Error "Failed to build Docker images"
        exit 1
    }
    
    Write-Status "Starting services..."
    try {
        docker-compose up -d
        Write-Success "Services started successfully"
    } catch {
        Write-Error "Failed to start services"
        exit 1
    }
}

# Function to wait for services
function Wait-ForServices {
    Write-Status "Waiting for services to initialize..."
    Write-Warning "This may take 5-15 minutes for first-time setup (AI model download)"
    
    # Wait for backend
    Write-Status "Waiting for backend service..."
    $BackendReady = $false
    for ($i = 1; $i -le 60; $i++) {
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:3001/" -TimeoutSec 5
            if ($Response.StatusCode -eq 200) {
                $BackendReady = $true
                Write-Success "Backend is ready"
                break
            }
        } catch {
            Start-Sleep -Seconds 5
            Write-Host "." -NoNewline
        }
    }
    Write-Host ""
    
    if (-not $BackendReady) {
        Write-Error "Backend failed to start within timeout"
        exit 1
    }
    
    # Wait for Ollama
    Write-Status "Waiting for Ollama AI service..."
    Write-Warning "AI model download in progress... please be patient"
    
    $OllamaReady = $false
    for ($i = 1; $i -le 180; $i++) {  # 15 minutes timeout
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:3001/health/ollama" -TimeoutSec 5
            if ($Response.Content -like "*healthy*") {
                $OllamaReady = $true
                Write-Success "Ollama AI service is ready"
                break
            }
        } catch {
            Start-Sleep -Seconds 5
            Write-Host "." -NoNewline
        }
    }
    Write-Host ""
    
    if (-not $OllamaReady) {
        Write-Error "Ollama failed to start within timeout"
        exit 1
    }
    
    # Final health checks
    Write-Status "Running final health checks..."
    Start-Sleep -Seconds 5
    
    # Check backend
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:3001/"
        if ($Response.Content -like "*Backend is running*") {
            Write-Success "✅ Backend health check passed"
        } else {
            Write-Error "❌ Backend health check failed"
        }
    } catch {
        Write-Error "❌ Backend health check failed"
    }
    
    # Check Ollama
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:3001/health/ollama"
        if ($Response.Content -like "*healthy*") {
            Write-Success "✅ Ollama health check passed"
        } else {
            Write-Error "❌ Ollama health check failed"
        }
    } catch {
        Write-Error "❌ Ollama health check failed"
    }
}

# Function to start frontend
function Start-Frontend {
    Write-Status "Starting frontend web server..."
    
    # Kill any existing HTTP server on port 8080
    Get-Process | Where-Object {$_.ProcessName -like "*python*" -and $_.CommandLine -like "*http.server*8080*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Start frontend server in background
    try {
        $Process = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", "8080" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 3
        
        # Test frontend
        $Response = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 5
        if ($Response.StatusCode -eq 200) {
            Write-Success "Frontend server started successfully (PID: $($Process.Id))"
        } else {
            Write-Error "Frontend server failed to start"
            exit 1
        }
    } catch {
        Write-Error "Failed to start frontend server: $_"
        exit 1
    }
}

# Function to show completion message
function Show-Completion {
    Write-Host ""
    Write-Host "🎉 AI Chat App Deployment Complete!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Access your AI Chat App:" -ForegroundColor Cyan
    Write-Host "   Frontend: http://localhost:8080" -ForegroundColor Yellow
    Write-Host "   Backend:  http://localhost:3001" -ForegroundColor Yellow
    Write-Host "   Ollama:   http://localhost:11434" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Useful commands:" -ForegroundColor Cyan
    Write-Host "   View logs:     docker-compose logs -f" -ForegroundColor Yellow
    Write-Host "   Stop services: docker-compose down" -ForegroundColor Yellow
    Write-Host "   Restart:       docker-compose restart" -ForegroundColor Yellow
    Write-Host "   Status:        docker-compose ps" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Open http://localhost:8080 in your browser" -ForegroundColor Yellow
    Write-Host "   2. Sign up for a new account" -ForegroundColor Yellow
    Write-Host "   3. Start chatting with the AI!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your AI Chat App is ready to use!" -ForegroundColor Green
    Write-Host ""
    
    # Try to open browser automatically
    if (-not $SkipBrowser) {
        Write-Status "Opening browser..."
        try {
            Start-Process "http://localhost:8080"
        } catch {
            Write-Warning "Could not open browser automatically. Please open http://localhost:8080 manually."
        }
    }
}

# Function to handle errors
function Handle-Error {
    Write-Error "Deployment failed. Cleaning up..."
    
    # Stop services
    try {
        docker-compose down
    } catch {
        # Ignore errors
    }
    
    # Kill frontend server
    Get-Process | Where-Object {$_.ProcessName -like "*python*" -and $_.CommandLine -like "*http.server*8080*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Error "❌ Deployment failed. Please check the error messages above."
    Write-Status "For troubleshooting, visit: https://github.com/Dwarak18/GPT-llama3.2"
    Write-Host ""
    exit 1
}

# Function to check internet connection
function Test-Internet {
    Write-Status "Checking internet connection..."
    try {
        $Response = Invoke-WebRequest -Uri "https://google.com" -Method Head -TimeoutSec 10
        Write-Success "Internet connection verified"
    } catch {
        Write-Error "No internet connection. Please check your network and try again."
        exit 1
    }
}

# Main function
function Main {
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    try {
        Write-Header
        
        Write-Status "Starting AI Chat App quick deployment..."
        Write-Host ""
        
        # Check internet connection
        Test-Internet
        
        # Check system requirements
        Test-Requirements
        
        # Check ports
        Test-Ports
        
        # Setup project
        Setup-Project
        
        # Deploy services
        Deploy-Services
        
        # Wait for services
        Wait-ForServices
        
        # Start frontend
        Start-Frontend
        
        # Show completion message
        Show-Completion
        
    } catch {
        Handle-Error
    }
}

# Run main function
Main

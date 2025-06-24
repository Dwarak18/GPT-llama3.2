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

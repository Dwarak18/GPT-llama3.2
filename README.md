# AI Chat Web App

A modern, animated AI chat web application with user authentication and real AI chat integration.

---

## Tech Stack
- **Frontend:** Static HTML/CSS/JS (Tailwind CSS, Font Awesome, custom animations)
- **Backend:** Node.js + Express (Dockerized)
- **Database:** MongoDB (Dockerized)
- **AI Model:** Ollama (Llama 3.2) via REST API (local, not included in this repo)
- **Orchestration:** Docker Compose

---

## How It Works: UI to AI API Call Flow

1. **User Interface (index.html):**
   - Users interact with a beautiful, animated chat UI in their browser.
   - Login/Signup forms send credentials to the backend for authentication.
   - After login, users can send chat messages to the AI assistant.

2. **Frontend API Calls:**
   - All API calls are made to the backend at `http://localhost:3001` (or your LAN IP).
   - **Login:** `POST /login` with `{ usernameOrEmail, password }`
   - **Signup:** `POST /signup` with `{ username, email, password, phone }`
   - **Chat:** `POST /chat` with `{ message }` (sends user message to backend)

3. **Backend (Node.js/Express):**
   - Handles authentication (signup/login) and stores user data in MongoDB.
   - On `/chat`, the backend proxies the message to the Ollama API (Llama 3.2 model) running locally (not in Docker).
   - The backend receives the AI's reply and returns it to the frontend.

4. **AI Model (Ollama):**
   - The backend sends the user's message to Ollama at `http://host.docker.internal:11434/api/generate`.
   - Ollama generates a response using the Llama 3.2 model and sends it back to the backend.

5. **Frontend Displays Response:**
   - The AI's reply is shown in the chat UI, with animations and message history.

---

## Folder Structure

```
webapp/
├── backend/
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
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

---

## Stopping the App
```sh
docker compose down
```

---

## License
MIT (or your preferred license)

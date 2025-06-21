# AI Chat Web App

A modern, animated AI chat web application with user authentication, built with:
- **Frontend:** Static HTML/CSS/JS (Tailwind CSS, animations)
- **Backend:** Node.js + Express + MongoDB (Dockerized)
- **Database:** MongoDB (Dockerized)

---

## Features
- Animated, interactive chat UI (no AI logic, just UI)
- User signup and login (with hashed passwords)
- Profile and chat history UI
- Backend REST API for authentication
- MongoDB for user data
- Docker Compose for easy orchestration

---

## Folder Structure

```
webapp/
├── backend/
│   ├── server.js
│   ├── package.json
│   ├── package-lock.json (optional)
│   └── Dockerfile
├── index.html
├── docker-compose.yml
└── README.md
```

---

## Dependencies

### Backend
- express
- mongoose
- bcryptjs
- cors

### Frontend
- Tailwind CSS (CDN)
- Font Awesome (CDN)
- No build tools required

### System
- Docker Desktop (for Windows/Mac/Linux)
- Node.js (for local development, optional)
- Python (for serving static frontend, optional)

---

## Setup & Installation

### 1. Clone the Repository
```
git clone <your-repo-url>
cd webapp
```

### 2. Build & Run with Docker Compose
Make sure Docker Desktop is running.

```
docker compose up --build
```
- This will start MongoDB and the backend API.
- Backend runs on port **3001**.
- MongoDB runs on port **27017**.

### 3. Serve the Frontend
You can use any static file server. Example with Python:

```
# In the webapp directory:
python -m http.server 8080
```
- Open your browser at: [http://localhost:8080](http://localhost:8080)

### 4. Access the App
- Sign up for a new account.
- Log in with your credentials.
- Enjoy the animated chat UI!

---

## Configuration
- The backend connects to MongoDB using the environment variable `MONGO_URL` (set in `docker-compose.yml`).
- The frontend is configured to call the backend at your LAN IP (e.g., `http://192.168.10.6:3001`). If you run on a different machine, update the fetch URLs in `index.html`.

---

## Development Tips
- To see live backend code changes, uncomment the `volumes` line in `docker-compose.yml` and run `npm install` in the `backend` folder.
- For production/stable use, keep the volume commented out.

---

## Troubleshooting
- **Network error:** Make sure Docker containers are running and the backend is accessible at the correct IP/port.
- **Module not found:** Ensure `npm install` has been run in the backend folder, or rebuild the Docker image.
- **Port conflicts:** Make sure ports 3001 (backend) and 27017 (MongoDB) are free.

---

## Stopping the App
```
docker compose down
```

---

## License
MIT (or your preferred license)

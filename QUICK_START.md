# 🚀 Quick Start Guide

Get your First Pipeline application running in **less than 5 minutes**!

## Choose Your Method

### 🐳 **Option 1: Docker Compose** (Recommended for beginners)
**Best for**: Local development, quick testing, no Kubernetes needed
```bash
./start.sh
# Choose option 1
```

**Then**: Open [http://localhost:3000](http://localhost:3000)

### 🐳 **Option 2: Minikube** (Recommended for learning Kubernetes)
**Best for**: Local Kubernetes testing, learning, before production
```bash
./start.sh
# Choose option 2
```

**Then**: 
```bash
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
# Open http://localhost:8080
```

### ☁️ **Option 3: Production Kubernetes**
**Best for**: Production deployment, existing Kubernetes cluster
```bash
./start.sh
# Choose option 3
```

**Then**: Same as Minikube port-forward

### 📦 **Option 4: Helm** (Recommended for production)
**Best for**: Templated deployments, multi-environment, GitOps
```bash
./start.sh
# Choose option 4
```

---

## ⚡ Quick Start Commands

### Linux/macOS
```bash
# Make executable
chmod +x start.sh

# Run the startup script
./start.sh
```

### Windows
```bash
# Run the batch file
start.bat

# Or in PowerShell
.\start.bat
```

---

## 🎯 Step-by-Step: Docker Compose (Easiest)

### Step 1: Open Terminal/PowerShell
```bash
cd /path/to/Lillteamet-first-pipeline
```

### Step 2: Start the Application
```bash
./start.sh      # Linux/macOS
# or
start.bat       # Windows
```

### Step 3: Choose Option 1 (Docker Compose)
```
Enter your choice (1-6): 1
```

### Step 4: Wait for Startup
- Docker builds the image
- Container starts running
- Browser opens automatically

### Step 5: Test the Application
```bash
curl http://localhost:3000/status
# Response: {"status":"ok","timestamp":"2026-02-17T..."}
```

---

## 🎯 Step-by-Step: Minikube (Full Kubernetes Locally)

### Prerequisites
- Docker Desktop running
- kubectl installed
- 2+ GB RAM available

### Step 1: Run Startup Script
```bash
./start.sh

# Or directly:
./scripts/minikube-setup.sh full-setup
```

### Step 2: Wait for Setup
- Minikube CLI installs (if needed)
- Kubernetes cluster starts
- Application deploys
- Takes 3-5 minutes

### Step 3: Access Application
```bash
# In another terminal:
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80

# Open browser: http://localhost:8080/status
```

### Step 4: Explore Kubernetes
```bash
# View pods
kubectl get pods -n first-pipeline

# View logs
kubectl logs -f -n first-pipeline -l app=first-pipeline

# View dashboard
kubectl port-forward -n kube-system svc/kubernetes-dashboard 8443:443

# Watch scaling
kubectl get hpa -n first-pipeline -w
```

---

## 📋 All Available Commands

### Using the Startup Script
```bash
./start.sh          # Interactive menu (recommended)
start.bat           # Windows batch file
```

### Manual Commands

**Docker Compose:**
```bash
docker-compose up              # Start
docker-compose down            # Stop
docker-compose logs -f         # View logs
```

**Minikube:**
```bash
./scripts/minikube-setup.sh full-setup     # Full setup
./scripts/minikube-setup.sh deploy         # Deploy only
./scripts/minikube-setup.sh logs           # View logs
./scripts/minikube-setup.sh dashboard      # Open dashboard
./scripts/minikube-setup.sh status         # Check status
./scripts/minikube-setup.sh stop           # Stop cluster
./scripts/minikube-setup.sh delete         # Delete cluster
```

**Kubernetes:**
```bash
./scripts/k8s-deploy.sh deploy     # Deploy
kubectl get all -n first-pipeline  # View resources
kubectl logs -f -n first-pipeline -l app=first-pipeline  # View logs
```

**Helm:**
```bash
helm install first-pipeline ./helm/first-pipeline -n first-pipeline --create-namespace
```

---

## � Cleanup & Shutdown

### Quick Factory Reset
When you're done or need a clean restart:

**Linux/macOS:**
```bash
./shutdown.sh
# Choose your cleanup option:
# 1) Full Cleanup   - Remove everything
# 2) Docker Compose - Stop just Docker Compose
# 3) Kubernetes     - Remove pods & port-forwards
# 4) Advanced       - Custom cleanup
```

**Windows:**
```bash
shutdown.bat
# Same menu as above
```

### What Gets Cleaned
- ✓ Kills all `kubectl port-forward` processes
- ✓ Removes `first-pipeline` namespace (all pods deleted)
- ✓ Stops Docker Compose (if running)
- ✓ Optional: Stop/Delete Minikube cluster

### Examples

**Quick cleanup (keep cluster running):**
```bash
./shutdown.sh
# Choose: 1) Full Cleanup → 1) Keep cluster running
```

**Stop everything (save resources):**
```bash
./shutdown.sh
# Choose: 1) Full Cleanup → 2) Stop cluster
```

**Full factory reset:**
```bash
./shutdown.sh
# Choose: 1) Full Cleanup → 3) Delete cluster
# Answer: yes
```

### Manual Cleanup Commands
```bash
# Kill port-forwards
pkill -f "kubectl port-forward"

# Stop Docker Compose
docker-compose down

# Delete all resources
kubectl delete namespace first-pipeline

# Stop Minikube
minikube stop -p first-pipeline

# Delete Minikube cluster
minikube delete -p first-pipeline
```

---

## �🔍 Verify It's Working

### Get Status
```bash
# For Docker Compose
curl http://localhost:3000/status

# For Kubernetes (after port-forward)
curl http://localhost:8080/status
```

### Expected Response
```json
{
  "status": "ok",
  "timestamp": "2026-02-17T10:30:00.000Z"
}
```

---

## 🚨 Troubleshooting

### "Docker is not running"
- **Solution**: Start Docker Desktop or Docker daemon
  ```bash
  # macOS/Windows: Open Docker Desktop app
  # Linux: sudo systemctl start docker
  ```

### "kubectl not found"
- **Solution**: Install kubectl
  ```bash
  # macOS
  brew install kubectl
  
  # Windows
  choco install kubernetes-cli
  
  # Linux
  sudo apt install kubectl
  ```

### "Cannot connect to Kubernetes cluster"
- **Solution**: Use Minikube for local testing
  ```bash
  ./start.sh
  # Choose option 2
  ```

### "Port 3000 already in use"
- **Solution**: Stop other services or use different port
  ```bash
  # Find what's using port 3000
  lsof -i :3000  # macOS/Linux
  netstat -ano | findstr :3000  # Windows
  
  # Kill the process or use docker-compose with different port
  ```

### "Minikube fails to start"
- **Solution**: Increase resources
  ```bash
  minikube stop -p first-pipeline
  minikube start -p first-pipeline --memory=4096 --cpus=4
  ```

---

## 📚 Next Steps

### Learn More
1. **Docker**: [docker-compose.yml](./docker-compose.yml)
2. **Minikube**: [MINIKUBE_SETUP.md](./MINIKUBE_SETUP.md)
3. **Kubernetes**: [DEPLOY_K8S.md](./DEPLOY_K8S.md)
4. **Everything**: [INDEX.md](./INDEX.md)

### Run Tests
```bash
npm test
```

### Build & Push Docker Image
```bash
docker build -t your-registry/first-pipeline:latest .
docker push your-registry/first-pipeline:latest
```

### Deploy to Production
```bash
# See DEPLOY_K8S.md or helm/HELM_USAGE.md
```

---

## 📊 Comparison

| Method | Complexity | Setup Time | Best For |
|--------|-----------|-----------|----------|
| **Docker Compose** | ⭐ Easy | 1-2 min | Learning, quick testing |
| **Minikube** | ⭐⭐ Medium | 3-5 min | Learning k8s locally |
| **Raw kubectl** | ⭐⭐ Medium | 2-3 min | Existing cluster |
| **Helm** | ⭐⭐⭐ Advanced | 2-3 min | Production |

---

## 💡 Pro Tips

### See Everything at Once
```bash
# Terminal 1: Start application
./start.sh
# Choose your option

# Terminal 2: Watch logs
kubectl logs -f -n first-pipeline -l app=first-pipeline
# or for Docker:
docker-compose logs -f

# Terminal 3: Make requests
while true; do
  curl http://localhost:3000/status
  sleep 1
done
```

### Test Scaling (Minikube/k8s)
```bash
# Terminal 1: Watch HPA
kubectl get hpa -n first-pipeline -w

# Terminal 2: Generate load
kubectl port-forward -n first-pipeline svc/first-pipeline 8080:80
while true; do curl http://localhost:8080/; done

# Watch replicas increase!
```

### Access via Dashboard
```bash
# Minikube
./scripts/minikube-setup.sh dashboard

# Or manually
kubectl port-forward -n kube-system svc/kubernetes-dashboard 8443:443
```

---

## ✅ Common Scenarios

### Scenario 1: "I just want to run it"
```bash
./start.sh
# Pick 1 (Docker Compose)
# Done! Open http://localhost:3000
```

### Scenario 2: "I want to learn Kubernetes"
```bash
./start.sh
# Pick 2 (Minikube)
# Run kubectl commands to explore
```

### Scenario 3: "I'm ready for production"
```bash
./start.sh
# Pick 4 (Helm)
# Customize helm/first-pipeline/values.yaml
# Deploy to your cloud provider
```

---

## 🎓 What You Can Do

### After Docker Compose
- ✓ Run the application locally
- ✓ Test your code
- ✓ Run unit tests

### After Minikube
- ✓ Full local Kubernetes
- ✓ Test scaling (2-10 replicas)
- ✓ Learn Kubernetes concepts
- ✓ Test before production

### After Production Deployment
- ✓ Scale automatically
- ✓ Update with zero downtime
- ✓ Monitor and debug
- ✓ Rollback if needed

---

## 🎉 You're Ready!

Just run:
```bash
./start.sh
```

And choose your option! No complicated setup, just simple, clear choices. 🚀

---

**Questions?** See [INDEX.md](./INDEX.md) for complete documentation.

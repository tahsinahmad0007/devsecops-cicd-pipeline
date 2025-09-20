#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

restart_container() {
    echo -e "${RED}🔄 Restarting container: $1...${NC}"
    docker restart $1 > /dev/null 2>&1
    sleep 5
    docker ps --filter "name=$1" --format "table {{.Names}}\t{{.Status}}"
}

echo "🔍 Checking DevSecOps Environment..."
echo "-------------------------------------"

# 1. Check running containers
echo "🛠 Checking Docker containers..."
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"
check_status $? "Containers are running"

# 2. Check SonarQube health
echo "🛠 Checking SonarQube health..."
SONAR_STATUS=$(curl -s -u $SONAR_ADMIN_TOKEN: http://localhost:9000/api/system/health | grep -o GREEN)
if [[ "$SONAR_STATUS" == "GREEN" ]]; then
    echo -e "${GREEN}✅ SonarQube is healthy${NC}"
else
    echo -e "${RED}❌ SonarQube not healthy${NC}"
    restart_container sonarqube
fi

# 3. Check App endpoint
echo "🛠 Checking DevSecOps App..."
APP_RESPONSE=$(curl -s http://localhost:3000)
if [[ "$APP_RESPONSE" == *"Hello from DevSecOps App"* ]]; then
    echo -e "${GREEN}✅ App root endpoint working${NC}"
else
    echo -e "${RED}❌ App root endpoint failed${NC}"
    restart_container devsecops-app
fi

APP_HEALTH=$(curl -s http://localhost:3000/health | grep -o healthy)
if [[ "$APP_HEALTH" == "healthy" ]]; then
    echo -e "${GREEN}✅ App health endpoint OK${NC}"
else
    echo -e "${RED}❌ App health endpoint failed${NC}"
    restart_container devsecops-app
fi

# 4. Check Jenkins UI (port open)
echo "🛠 Checking Jenkins..."
curl -s http://localhost:8080 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Jenkins UI reachable at http://localhost:8080${NC}"
else
    echo -e "${RED}❌ Jenkins not responding${NC}"
    restart_container devsecops-jenkins
fi

# 5. Check DB connectivity
echo "🛠 Checking PostgreSQL..."
docker logs sonar-db 2>&1 | grep "database system is ready to accept connections" > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
else
    echo -e "${RED}❌ PostgreSQL not ready${NC}"
    restart_container sonar-db
fi

echo "-------------------------------------"
echo "✅ Service check complete!"

#!/bin/bash
# =============================================================================
# LUMOS AI — Master Setup Script
# =============================================================================
# This script sets up the entire LUMOS AI development environment
# =============================================================================

set -e

echo "=========================================="
echo "  LUMOS AI — Development Environment Setup"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisite() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 found: $(command -v "$1")"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found. Please install $1."
        return 1
    fi
}

echo -e "${BLUE}Checking prerequisites...${NC}"
echo ""

MISSING=0

check_prerequisite "docker" || MISSING=1
check_prerequisite "docker compose" || MISSING=1
check_prerequisite "flutter" || MISSING=1
check_prerequisite "rustc" || MISSING=1
check_prerequisite "python3" || MISSING=1
check_prerequisite "node" || MISSING=1
check_prerequisite "pnpm" || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}Please install missing prerequisites and run this script again.${NC}"
    exit 1
fi

echo ""

# =============================================================================
# Step 1: Environment Configuration
# =============================================================================
echo -e "${BLUE}Step 1: Setting up environment configuration...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env from .env.example"
else
    echo -e "${YELLOW}!${NC} .env already exists, skipping"
fi

echo ""

# =============================================================================
# Step 2: Start Infrastructure (PostgreSQL, Redis, MinIO)
# =============================================================================
echo -e "${BLUE}Step 2: Starting infrastructure services...${NC}"

docker compose up -d postgres redis minio

# Wait for PostgreSQL to be ready
echo -n "Waiting for PostgreSQL to be ready..."
until docker compose exec postgres pg_isready -U lumos > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}ready!${NC}"

# Wait for Redis to be ready
echo -n "Waiting for Redis to be ready..."
until docker compose exec redis redis-cli ping > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}ready!${NC}"

echo -e "${GREEN}✓${NC} Infrastructure services started"
echo ""

# =============================================================================
# Step 3: Install JavaScript/TypeScript dependencies
# =============================================================================
echo -e "${BLUE}Step 3: Installing JavaScript dependencies...${NC}"

pnpm install

echo -e "${GREEN}✓${NC} JavaScript dependencies installed"
echo ""

# =============================================================================
# Step 4: Install Python dependencies
# =============================================================================
echo -e "${BLUE}Step 4: Installing Python dependencies...${NC}"

# API service
echo "Installing API service dependencies..."
cd services/api
python3 -m pip install -r requirements.txt --quiet
cd ../..

# AI service
echo "Installing AI service dependencies..."
cd services/ai
python3 -m pip install -r requirements.txt --quiet
cd ../..

echo -e "${GREEN}✓${NC} Python dependencies installed"
echo ""

# =============================================================================
# Step 5: Install Flutter dependencies
# =============================================================================
echo -e "${BLUE}Step 5: Installing Flutter dependencies...${NC}"

cd apps/desktop
flutter pub get > /dev/null 2>&1
cd ../..

echo -e "${GREEN}✓${NC} Flutter dependencies installed"
echo ""

# =============================================================================
# Step 6: Build Rust rendering engine
# =============================================================================
echo -e "${BLUE}Step 6: Building Rust rendering engine...${NC}"

cd services/render
cargo build --release 2>/dev/null || cargo build
cd ../..

echo -e "${GREEN}✓${NC} Rust rendering engine built"
echo ""

# =============================================================================
# Step 7: Run database migrations
# =============================================================================
echo -e "${BLUE}Step 7: Setting up database...${NC}"

# The database schema is initialized via docker-compose volume
echo -e "${GREEN}✓${NC} Database initialized (via Docker)"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=========================================="
echo -e "  ${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Services running:"
echo "  - PostgreSQL:    localhost:5432"
echo "  - Redis:         localhost:6379"
echo "  - MinIO:         localhost:9000 (console: 9001)"
echo ""
echo "To start development:"
echo ""
echo "  Terminal 1:  pnpm dev:api"
echo "  Terminal 2:  pnpm dev:ai"
echo "  Terminal 3:  pnpm dev:render"
echo "  Terminal 4:  pnpm dev:desktop"
echo ""
echo "Or start all at once:"
echo "  pnpm dev"
echo ""
echo "To run tests:"
echo "  pnpm test"
echo ""
echo "To build for production:"
echo "  pnpm build"
echo ""
echo "API Documentation:"
echo "  http://localhost:8000/docs"
echo ""

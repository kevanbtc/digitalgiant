#!/bin/bash

# Digital Giant - Deployment Script (Foundry-Independent)
# This script sets up the Digital Giant ecosystem without requiring Foundry

set -e

echo "🏗️ Digital Giant - Connection Economy Revolution"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the Digital Giant root directory."
    exit 1
fi

print_info "Checking prerequisites..."

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status "Node.js found: $NODE_VERSION"
else
    print_error "Node.js not found. Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_status "Python found: $PYTHON_VERSION"
else
    print_error "Python 3 not found. Please install Python 3.9+ from https://python.org/"
    exit 1
fi

# Check if .env exists, if not copy from example
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        print_info "Creating .env file from .env.example..."
        cp .env.example .env
        print_status "Created .env file. Please edit it with your configuration."
    else
        print_warning ".env.example not found. Creating basic .env file..."
        echo "NODE_ENV=development" > .env
        echo "PORT=8080" >> .env
        echo "ETHEREUM_RPC_URL=https://ethereum-rpc.publicnode.com" >> .env
        echo "POLYGON_RPC_URL=https://polygon-rpc.com" >> .env
        print_status "Created basic .env file."
    fi
else
    print_status ".env file already exists."
fi

# Install Node.js dependencies
print_info "Installing Node.js dependencies..."
if npm install; then
    print_status "Node.js dependencies installed successfully."
else
    print_warning "Some Node.js dependencies may have failed to install. This is expected in some environments."
fi

# Install Python dependencies
print_info "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    if python3 -m pip install -r requirements.txt; then
        print_status "Python dependencies installed successfully."
    else
        print_warning "Some Python dependencies may have failed to install. You may need to install them manually."
    fi
else
    print_info "No requirements.txt found. Skipping Python dependency installation."
fi

# Check smart contracts
print_info "Verifying smart contract files..."
CONTRACTS=(
    "src/UnykornToken.sol"
    "src/AssetVault.sol"
    "src/SalesForceManager.sol"
    "src/InstitutionalPaymentGateway.sol"
    "src/AIOrchestrationSystem.sol"
    "src/NFTTimestampSystem.sol"
    "src/QRCodeOnboardingSystem.sol"
)

for contract in "${CONTRACTS[@]}"; do
    if [ -f "$contract" ]; then
        print_status "Found: $contract"
    else
        print_warning "Missing: $contract"
    fi
done

# Check Python components
print_info "Verifying Python components..."
PYTHON_FILES=(
    "ai_agent_orchestrator.py"
    "qr_sms_interface.py"
)

for file in "${PYTHON_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_warning "Missing: $file"
    fi
done

# Check website files
print_info "Verifying website components..."
if [ -d "website" ]; then
    if [ -f "website/index.html" ]; then
        print_status "Website files found."
    else
        print_warning "Website directory exists but index.html not found."
    fi
else
    print_warning "Website directory not found."
fi

# Make scripts executable
if [ -f "deploy-unykorn-ecosystem.sh" ]; then
    chmod +x deploy-unykorn-ecosystem.sh
    print_status "Made deploy-unykorn-ecosystem.sh executable."
fi

print_info "Creating quick start script..."
cat > quick-start.sh << 'EOF'
#!/bin/bash
# Digital Giant Quick Start

echo "🏗️ Starting Digital Giant..."

# Start AI orchestrator in background
if [ -f "ai_agent_orchestrator.py" ]; then
    echo "Starting AI Agent Orchestrator..."
    python3 ai_agent_orchestrator.py &
    AI_PID=$!
    echo "AI Agent started with PID: $AI_PID"
fi

# Start QR/SMS interface
if [ -f "qr_sms_interface.py" ]; then
    echo "Starting QR/SMS Interface..."
    python3 qr_sms_interface.py &
    QR_PID=$!
    echo "QR/SMS Interface started with PID: $QR_PID"
fi

echo ""
echo "🎯 Digital Giant is running!"
echo "📊 Dashboard: http://localhost:8080"
echo "📱 QR Interface: http://localhost:8081"
echo ""
echo "Press Ctrl+C to stop all services..."

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping services..."
    if [ ! -z "$AI_PID" ]; then
        kill $AI_PID 2>/dev/null || true
    fi
    if [ ! -z "$QR_PID" ]; then
        kill $QR_PID 2>/dev/null || true
    fi
    echo "Services stopped."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for user to stop
wait
EOF

chmod +x quick-start.sh
print_status "Created quick-start.sh script."

echo ""
echo "================================================"
print_status "Digital Giant setup complete!"
echo ""
print_info "Next steps:"
echo "  1. Edit .env file with your configuration"
echo "  2. Run: npm run start"
echo "  3. Or run: ./quick-start.sh"
echo "  4. Visit: http://localhost:8080"
echo ""
print_info "Available commands:"
echo "  npm run start     - Start AI orchestrator"
echo "  npm run dashboard - Start QR/SMS interface"
echo "  npm run dev       - Start in development mode"
echo "  ./quick-start.sh  - Start all services"
echo ""
print_status "🎯 Ready to build your Digital Empire!"
echo "================================================"
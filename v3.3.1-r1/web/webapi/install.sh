#!/bin/bash
# AAPEN WebAPI Installer
# Installs required Node.js dependencies for webapi.js

# Check for Node.js installation
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed"
    echo "Please install Node.js 16.x or later first"
    exit 1
fi

# Verify Node.js version
NODE_VERSION=$(node -v | cut -d'.' -f1 | tr -d 'v')
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "ERROR: Node.js version 16 or higher required"
    echo "Current version: $(node -v)"
    exit 1
fi

# Check for npm/yarn
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm is not installed"
    exit 1
fi

# Install dependencies
echo "Installing required packages..."
npm install express socket.io cors node-fetch dotenv

# Verify installations
echo "Verifying packages..."
REQUIRED_PKGS=("express" "socket.io" "cors" "node-fetch" "dotenv")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! npm list "$pkg" &> /dev/null; then
        echo "ERROR: Failed to install $pkg"
        exit 1
    fi
done

# Create basic .env template if missing
if [ ! -f .env ]; then
    echo "Creating .env template..."
    cat << EOF > .env
# AAPEN WebAPI Configuration
API_PASS=your_secure_password_here
API_PORT=39113
WS_PORT=3000
MAX_SOCKETS=30

# Socket.IO Settings
ALLOWED_DOMAINS="http://plateau.eth,https://plateau.eth,http://localhost"
EOF
fi

echo ""
echo "Installation complete!"
echo "1. Edit the .env file with your configuration"
echo "2. Start the server with: node webapi.js"
echo "3. Access the API at: http://localhost:3000"

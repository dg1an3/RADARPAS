#!/bin/bash
# Build script for RADARPAS using Docker

set -e

echo "=================================================="
echo "RADARPAS - FreePascal Container Build"
echo "=================================================="
echo ""

# Build the Docker image
echo "Building Docker image..."
docker build -t radarpas-fpc:latest .

echo ""
echo "Docker image built successfully!"
echo ""

# Run the build inside the container
echo "Compiling RADARPAS..."
docker run --rm -v "$(pwd):/build" radarpas-fpc:latest make clean all

echo ""
echo "=================================================="
echo "Build complete!"
echo "=================================================="
echo ""
echo "To run the program:"
echo "  docker run --rm -it -v \"\$(pwd):/build\" radarpas-fpc:latest ./radarpas"
echo ""
echo "Or directly with:"
echo "  docker run --rm -it -v \"\$(pwd):/build\" radarpas-fpc:latest make run"
echo ""

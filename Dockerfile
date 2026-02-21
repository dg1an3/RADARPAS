# FreePascal build environment for RADARPAS
FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install FreePascal compiler and dependencies
RUN apt-get update && apt-get install -y \
    fpc \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy source files
COPY . /build/

# FreePascal version info
RUN fpc -i

CMD ["/bin/bash"]

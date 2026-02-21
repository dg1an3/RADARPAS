# Makefile for RADARPAS - FreePascal Build
# Original software: Ellason E300 Radar Terminal (1988)

# Compiler
FPC = fpc

# Compiler flags
FPCFLAGS = -Mtp -O2 -vh -l

# Target executable
TARGET = radarpas

# Source file
SRC = radar.pas

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(SRC)
	@echo "Building RADARPAS with FreePascal..."
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(SRC)
	@echo "Build complete: $(TARGET)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET) *.o *.ppu
	@echo "Clean complete"

# Run the program
run: $(TARGET)
	./$(TARGET)

# Build info
info:
	@echo "RADARPAS - FreePascal Build System"
	@echo "Original: Turbo Pascal (1988)"
	@echo "Target: $(TARGET)"
	@echo "Source: $(SRC)"
	@echo ""
	@fpc -i | head -n 5

# Help target
help:
	@echo "RADARPAS Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make           - Build the program"
	@echo "  make clean     - Remove build artifacts"
	@echo "  make run       - Build and run the program"
	@echo "  make info      - Show build information"
	@echo "  make help      - Show this help message"

.PHONY: all clean run info help

# Makefile to build the ords standalone executable with SBCL

# Variables
LISP = sbcl
BINARY = hexerei
SOURCE = hexerei.lisp

# Default target
all: $(BINARY)

# Build the standalone executable
$(BINARY): $(SOURCE)
	@echo "Building $(BINARY) with SBCL ..."
	@$(LISP) --non-interactive \
	--eval "(ql:quickload '(:drakma :cl-base64 :flexi-streams :alexandria :uiop :local-time))" \
	--load $(SOURCE) \
	--eval "(sb-ext:save-lisp-and-die \"$(BINARY)\" :toplevel #'(lambda () (sb-ext:exit :code (hexerei:main))) :executable t)"
	@chmod +x $(BINARY)
	@echo "Build complete: $(BINARY)"

# Clean up the binary
clean:
	@echo "Cleaning up..."
	@rm -f $(BINARY)
	@echo "Clean complete."

# Phony targets
.PHONY: all clean

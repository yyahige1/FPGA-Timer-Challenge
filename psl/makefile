
.PHONY: all bmc 

all: bmc 
	@echo "All formal verification passed!"

# Bounded Model Checking
bmc: 
	@echo "Running BMC (Bounded Model Checking)..."
	sby -f timer.sby
	@echo "BMC PASSED"

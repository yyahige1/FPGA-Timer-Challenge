
.PHONY: all bmc prove cover

all: bmc prove cover
	@echo "All formal verification passed!"

# Bounded Model Checking
bmc: 
	@echo "Running BMC (Bounded Model Checking)..."
	sby -f timer.sby
	@echo "BMC PASSED"
# Unbounded Proving
prove: 
	@echo "Running unbounded proving..."
	sby -f timer_prove.sby
	@echo "PROVE PASSED"
	
# Coverage/Reachability
cover: 
	@echo "Running coverage analysis..."
	sby -f timer_cover.sby
	@echo "COVER PASSED"

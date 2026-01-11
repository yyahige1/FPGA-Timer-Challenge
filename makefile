# Rules to clean and run 
YOSYS_SCRIPT=scripts/synth_check.ys
SYNTH_OUTPUT=netlist/synth_output_timer.v
VHDL_SRC=src/timer.vhd

.PHONY: run clean synth sweep sweep-report clean-sweep

run:
	python run.py

clean:
	rm -rf $(SYNTH_OUTPUT) vunit_out/
	cd lab_test ; rm -rf build/
	rm -rf sweep_logs/

synth: $(SYNTH_OUTPUT)

$(SYNTH_OUTPUT): $(VHDL_SRC)
	yosys -m ghdl $(YOSYS_SCRIPT)

# Generate sweep script, run it, show report
sweep:
	python generate_sweep.py 
	./run_sweep_all.sh 
	python report_sweep.py

# Just show the report (if sweep already done)
sweep-report:
	python report_sweep.py

# Clean sweep logs
clean-sweep:
	rm -rf sweep_logs/

# Synthesis sweep: run synthesis for all configs
synth-sweep:
	./make_sweep_synth.sh

# Clean synthesis outputs
clean-synth:
	rm -rf synth_logs/
	rm -f netlist/synth_*.v
	rm -f $(SYNTH_OUTPUT)
# Clean everything
clean-all: clean clean-sweep clean-synth

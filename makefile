#Rules to clean and run 
YOSYS_SCRIPT=scripts/synth_check.ys
SYNTH_OUTPUT=netlist/synth_output_timer.v
VHDL_SRC=src/timer.vhd
.PHONY: synth
run:
	python run.py

clean:
	rm -rf $(SYNTH_OUTPUT) vunit_out/
	cd lab_test ; rm -rf build/
synth: $(SYNTH_OUTPUT)

$(SYNTH_OUTPUT): $(VHDL_SRC)
	yosys -m ghdl $(YOSYS_SCRIPT) # Relies on yosys and the ghdl plugin being

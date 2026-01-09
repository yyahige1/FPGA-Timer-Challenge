This folder contains the following scripts:

tb_compare_div.sh — compares cycle computation precision across implementations (natural integer, floating point, native time, unsigned 64). The natural integer implementation has the smallest numeric range for very large delays (expected), but it is the only approach that is synthesizable and produces optimal bit‑width estimates (synthesis to be verified with Yosys).

tb_test_width.sh — runs many (clk_hz, delay) combinations to verify the computed counter width is minimal for normal operating ranges.

tb_time_to_calc.sh — runs the natural integer cycle computation across frequency/delay combinations and verifies rounding‑up behavior.

If you want to run the scripts yourself you only need to run each bash script:

Usage: ./<bash_script>

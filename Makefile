VIVADO ?= vivado

.PHONY: all package test synth validate clean

all: test synth package

package:
	$(VIVADO) -mode batch -source scripts/package_ip.tcl

test:
	$(VIVADO) -mode batch -source scripts/run_tests.tcl

synth:
	$(VIVADO) -mode batch -source scripts/synth_ip.tcl

validate: package
	$(VIVADO) -mode batch -source scripts/validate_packaged_ip.tcl

clean:
	rm -rf build .Xil *.jou *.log *.str *.pb

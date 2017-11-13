sim:
	mkdir -p work
	ghdl -a --workdir=work hdl/*.vhd
	ghdl -e --workdir=work tb_toplevel
	ghdl -r tb_toplevel --vcd=tb_spiwish.vcd --disp-tree

view: sim
	gtkwave -z tb_spiwish.vcd bus_transaction.gtkw

clean:
	rm -rf work tb_spiwish tb_spiwish.vcd "e~tb_spiwish.o" "$(VENDORLIBDIR)"

VENDOR=vendor/vcomponent_vital.vhd vendor/sb_ice_syn_vital.vhd vendor/sb_ice_lc_vital.vhd
VENDORLIBDIR=ice

sim_routed:
	mkdir -p simrouted
	ghdl -a -fexplicit --ieee=synopsys --workdir=simrouted -P"$(VENDORLIBDIR)" --warn-no-vital-generic project/dronefpga/dronefpga_Implmnt/sbt/outputs/simulation_netlist/tinyfpga_sbt.vhd hdl/tb_toplevel.vhd
	ghdl -e -fexplicit --ieee=synopsys --workdir=simrouted -P"$(VENDORLIBDIR)" --warn-no-vital-generic tb_toplevel
	ghdl -r tb_toplevel --vcd=tb_toplevel.vcd

view_routed: sim_routed
	gtkwave -z tb_toplevel.vcd

vendorlib:
	rm -rf "$(VENDORLIBDIR)"
	mkdir -p "$(VENDORLIBDIR)"
	ghdl -a -fexplicit --ieee=synopsys --work=ice --workdir="$(VENDORLIBDIR)" $(VENDOR)

program:
	tinyfpgab -p project/dronefpga/dronefpga_Implmnt/sbt/outputs/bitmap/tinyfpga_bitmap.bin
	tinyfpgab -b

.PHONY: sim view clean


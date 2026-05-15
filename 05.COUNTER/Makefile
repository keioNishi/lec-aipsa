# 05.COUNTER contains three independent designs.
# Select one with `make TOP=<name>` (default: preset_counter)
# Convenience targets: `make simple`, `make updown`, `make preset`
TOP        ?= preset_counter
SRCS        = $(TOP).v
TESTSRC     = test_$(TOP).v
ALLSRCS     = $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE     = $(TOP).vcd
YOSYSSCRIPT = $(TOP).ys
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim clean simple updown preset

all: sim

sim: $(VCDFILE)

$(OUTFILE): $(TESTSRCS)
	iverilog -g2012 -o $(OUTFILE) $(TESTSRCS)

$(VCDFILE): $(OUTFILE)
	vvp $(OUTFILE)

view wave: $(VCDFILE)
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE)

synth yosys: $(GATEFILE)

$(GATEFILE): $(ALLSRCS) $(YOSYSSCRIPT)
	yosys $(YOSYSSCRIPT)

show: $(DOTFILE)
	gvedit $(DOTFILE)

typsim: $(GATEFILE)
	iverilog -gspecify -T typ -o gate_typ.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_typ.out

minsim: $(GATEFILE)
	iverilog -gspecify -T min -o gate_min.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_min.out

maxsim: $(GATEFILE)
	iverilog -gspecify -T max -o gate_max.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_max.out

simple:
	$(MAKE) TOP=simple_counter

updown:
	$(MAKE) TOP=updown_counter

preset:
	$(MAKE) TOP=preset_counter

clean:
	-rm -f *.out *.vcd *.dot abc.history $(GATEFILE) $(SYNTHFILE)

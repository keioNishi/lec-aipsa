SRCS        = sel.v
TESTSRC     = seltest.v
ALLSRCS     = $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE     = sel.vcd
YOSYSSCRIPT = sel.ys
TOP         = sel
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim clean

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

clean:
	-rm -f *.out *.vcd *.dot abc.history $(GATEFILE) $(SYNTHFILE)

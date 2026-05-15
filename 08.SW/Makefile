SRCS        = sw.sv ib.sv ibsm.sv fifo.sv mkreq.sv mkwe.sv arb.sv cb.sv cbsel.sv ackor.sv
TESTSRC     = test.sv
ALLSRCS     = sw.vh $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE     = sw.vcd
VCDFILE_TYP = $(basename $(VCDFILE))_typ.vcd
VCDFILE_MIN = $(basename $(VCDFILE))_min.vcd
VCDFILE_MAX = $(basename $(VCDFILE))_max.vcd
YOSYSSCRIPT = sw.ys
TOP         = sw
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim typwave minwave maxwave clean \
        sw fifo ibsm mkreq mkwe ib arb cbsel cb ackor

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

typsim: $(VCDFILE_TYP)

$(VCDFILE_TYP): $(GATEFILE) $(TESTSRC) $(CELLFILE)
	iverilog -gspecify -T typ -o gate_typ.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_typ.out
	mv -f $(VCDFILE) $@

typwave: $(VCDFILE_TYP)
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_TYP)

minsim: $(VCDFILE_MIN)

$(VCDFILE_MIN): $(GATEFILE) $(TESTSRC) $(CELLFILE)
	iverilog -gspecify -T min -o gate_min.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_min.out
	mv -f $(VCDFILE) $@

minwave: $(VCDFILE_MIN)
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_MIN)

maxsim: $(VCDFILE_MAX)

$(VCDFILE_MAX): $(GATEFILE) $(TESTSRC) $(CELLFILE)
	iverilog -gspecify -T max -o gate_max.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_max.out
	mv -f $(VCDFILE) $@

maxwave: $(VCDFILE_MAX)
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_MAX)

sw:
	iverilog -g2012 $(SRCS)
fifo:
	iverilog -g2012 fifo.sv
ibsm:
	iverilog -g2012 ibsm.sv
mkreq:
	iverilog -g2012 mkreq.sv
mkwe:
	iverilog -g2012 mkwe.sv
ib:
	iverilog -g2012 ib.sv ibsm.sv fifo.sv mkreq.sv mkwe.sv
arb:
	iverilog -g2012 arb.sv
cbsel:
	iverilog -g2012 cbsel.sv
cb:
	iverilog -g2012 cb.sv cbsel.sv
ackor:
	iverilog -g2012 ackor.sv

clean:
	-rm -f *.out *.vcd *.dot abc.history $(GATEFILE) $(SYNTHFILE)

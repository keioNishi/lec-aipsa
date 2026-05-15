# 07.STATE has two implementations of the same module name `state`:
#   state.v     - binary-encoded FSM
#   state-oh.v  - one-hot-encoded FSM (default; matches the legacy syn.scr)
# Switch with: make STATEFILE=state.v
STATEFILE  ?= state-oh.v
SRCS        = $(STATEFILE)
TESTSRC     = test.v
ALLSRCS     = $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE     = state.vcd
VCDFILE_TYP = $(basename $(VCDFILE))_typ.vcd
VCDFILE_MIN = $(basename $(VCDFILE))_min.vcd
VCDFILE_MAX = $(basename $(VCDFILE))_max.vcd
YOSYSSCRIPT = state.ys
TOP         = state
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim typwave minwave maxwave clean

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

clean:
	-rm -f *.out *.vcd *.dot abc.history $(GATEFILE) $(SYNTHFILE)

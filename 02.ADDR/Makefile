SRCS        = faddr.v raddr.v
TESTSRC     = test.v
ALLSRCS     = $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE     = raddr.vcd
VCDFILE_TYP = $(basename $(VCDFILE))_typ.vcd
VCDFILE_MIN = $(basename $(VCDFILE))_min.vcd
VCDFILE_MAX = $(basename $(VCDFILE))_max.vcd
YOSYSSCRIPT = raddr.ys
TOP         = raddr
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim typwave minwave maxwave clean faddr

all: sim

# --- behavioral simulation (always re-runs) ---
$(OUTFILE): $(TESTSRCS)
	iverilog -g2012 -o $(OUTFILE) $(TESTSRCS)

sim: $(OUTFILE)
	vvp $(OUTFILE)

view wave: sim
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE)

# --- synthesis (rebuilds only when sources change) ---
synth yosys: $(GATEFILE)

$(GATEFILE): $(ALLSRCS) $(YOSYSSCRIPT)
	yosys $(YOSYSSCRIPT)

show: $(DOTFILE)
	dot -Tsvg $(DOTFILE) -o $(basename $(DOTFILE)).svg
	cmd //c start "" "$(basename $(DOTFILE)).svg"

$(DOTFILE): $(ALLSRCS) $(YOSYSSCRIPT)
	yosys -p "script $(YOSYSSCRIPT); read_liberty -lib $(CELLLIB); show -notitle -format dot -prefix $(basename $(DOTFILE)) $(TOP)"

# --- gate-level simulation (always re-runs) ---
typsim: $(GATEFILE)
	iverilog -gspecify -T typ -o gate_typ.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_typ.out
	mv -f $(VCDFILE) $(VCDFILE_TYP)

typwave: typsim
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_TYP)

minsim: $(GATEFILE)
	iverilog -gspecify -T min -o gate_min.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_min.out
	mv -f $(VCDFILE) $(VCDFILE_MIN)

minwave: minsim
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_MIN)

maxsim: $(GATEFILE)
	iverilog -gspecify -T max -o gate_max.out $(TESTSRC) $(GATEFILE) $(CELLFILE)
	vvp gate_max.out
	mv -f $(VCDFILE) $(VCDFILE_MAX)

maxwave: maxsim
	gtkwave -4 'fontname_signals Lucida Console 12' -4 'fontname_waves Lucida Console 12' $(VCDFILE_MAX)

faddr:
	iverilog -g2012 faddr.v

clean:
	-rm -f *.out *.vcd *.dot *.svg abc.history $(GATEFILE) $(SYNTHFILE)

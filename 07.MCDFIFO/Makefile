# 07.MCDFIFO has two multi-clock-domain FIFO implementations:
#   async_fifo.v      - Gray-code pointer FIFO (Cummings, SNUG 2002)
#   slot_valid_fifo.v - per-slot toggle/phase-flag FIFO
# Switch with: make DESIGN=slot   (default: async)
DESIGN     ?= async

ifeq ($(DESIGN),slot)
SRCS        = slot_valid_fifo.v
TESTSRC     = tb_slot_valid_fifo.v
VCDFILE     = slot_valid_fifo.vcd
YOSYSSCRIPT = slot_valid_fifo.ys
TOP         = slot_valid_fifo
else
SRCS        = async_fifo.v
TESTSRC     = tb_async_fifo.v
VCDFILE     = async_fifo.vcd
YOSYSSCRIPT = async_fifo.ys
TOP         = async_fifo
endif

ALLSRCS     = mcdfifo.vh $(SRCS)
TESTSRCS    = $(TESTSRC) $(SRCS)
VCDFILE_TYP = $(basename $(VCDFILE))_typ.vcd
VCDFILE_MIN = $(basename $(VCDFILE))_min.vcd
VCDFILE_MAX = $(basename $(VCDFILE))_max.vcd
OUTFILE     = a.out
GATEFILE    = gate.v
SYNTHFILE   = synth.v
DOTFILE     = show.dot
CELLLIB     = ../osu018_stdcells.lib
CELLFILE    = ../osu018_stdcells.v

.PHONY: all sim view wave synth yosys show typsim minsim maxsim typwave minwave maxwave clean

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

clean:
	-rm -f *.out *.vcd *.dot *.svg abc.history $(GATEFILE) $(SYNTHFILE)

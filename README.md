[![Icarus Verilog Badge](https://img.shields.io/badge/Icarus_Verilog->v11.0-fe0000.svg?style=flat)](http://iverilog.icarus.com/)
[![GTKWave Badge](https://img.shields.io/badge/GTKWave->v3.3.1-3d4067.svg?style=flat)](http://gtkwave.sourceforge.net/)
[![yosys Badge](https://img.shields.io/badge/yosys->v0.12--1-84e7f7.svg?style=flat)](https://github.com/YosysHQ/yosys#readme)

# Advanced Information Processing System Architecture (AIPSA) — Lecture Notes
## lec-aipsa
- Location: Yagami 14-B102
- Browsing and downloading the materials
  - Use this page, or `git clone` to download the entire repository.
- Individual files can also be downloaded via the links below.
  - When downloading individual files, you may need to place or move them to fit your environment.
  - Using `git clone` is most convenient when attending lectures.

### A PC is required for this course
- Windows / macOS / Linux environments are all supported.

### You are strongly encouraged to bring your own laptop
- We use Icarus Verilog, GTKWave, yosys, and other tools.
- The hardware description language used is SystemVerilog. You do not need to study SystemVerilog in advance — it will be taught in class.
  - Familiarity with the basic structure of any common programming language is sufficient.

### Setting up and using the CAD environment
- This course uses Icarus Verilog for SystemVerilog logic simulation and post-synthesis simulation.
  - Always compile with `iverilog -g2012` (the Makefiles do this).
- GTKWave is used as the waveform viewer.
- yosys is used for logic synthesis.
  - The synthesis scripts (`*.ys`) use the yosys-slang SystemVerilog frontend (`plugin -i slang` / `read_slang`), which is included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).
  - If your yosys has no slang plugin, use the commented-out `read_verilog -sv` line in each `.ys` file instead.
  - Install the binary that matches your PC.
  - Use the latest version.
  - The tools are already installed on the PCs in the KIC labs.
  - Putting the tools on a USB stick is a convenient way to use the same setup at the university, at home, or anywhere.
- In testbenches, connect module ports by name (e.g. `ff ff0(.d(d), .q(q), .clk(clk));`).
  The synthesized netlist (`gate.v`) may list the ports in a different order, so positional connections can silently mis-wire post-synthesis simulation.
- Other free or commercial tools (e.g., Cadence, Synopsys, etc.) may also be used in this lecture and the exercises.

## Using your own environment
- You are free to build and use your own environment.
  - Questions about environment setup will be answered to the extent possible.
- Issues or disadvantages caused by compatibility problems are not the responsibility of the course.
  - Pay attention to differences between versions.
  - In particular, compatibility issues may arise around SystemVerilog support.

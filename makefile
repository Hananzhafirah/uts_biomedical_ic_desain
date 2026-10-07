DIR_BUILD = build
DIR_CONS  = constraints
DIR_RTL   = rtl

PROJECT    = uts1
TOP_MODULE = top

VERILOGS = $(DIR_RTL)/uts1.v $(DIR_RTL)/tm1638.v


# =========================
# SYNTHESIS
# =========================
syn:
	if not exist $(DIR_BUILD) mkdir $(DIR_BUILD)
	yosys -p "synth_ice40 -top $(TOP_MODULE) -json $(DIR_BUILD)/$(PROJECT)_netlist.json" $(VERILOGS)


# =========================
# PLACE AND ROUTE
# =========================
pnr:
	nextpnr-ice40 \
		--up5k \
		--package sg48 \
		--json $(DIR_BUILD)/$(PROJECT)_netlist.json \
		--pcf $(DIR_CONS)/$(PROJECT).pcf \
		--asc $(DIR_BUILD)/$(PROJECT).asc


# =========================
# BITSTREAM
# =========================
bit:
	icepack $(DIR_BUILD)/$(PROJECT).asc $(DIR_BUILD)/$(PROJECT).bin


# =========================
# FLASH
# =========================
flash:
	icesprog $(DIR_BUILD)/$(PROJECT).bin


# =========================
# ALL
# =========================
all: syn pnr bit


# =========================
# CLEAN
# =========================
clean:
	if exist $(DIR_BUILD) rmdir $(DIR_BUILD) /S /Q
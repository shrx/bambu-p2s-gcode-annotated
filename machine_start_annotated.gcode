; Set flag to enable flow/extrusion calibration before printing. Slicer controls whether this is commented out.
;M1002 set_flag extrude_cali_flag=1
; Set flag to enable bed leveling (G29) before printing. Slicer controls whether this is commented out.
;M1002 set_flag g29_before_print_flag=1
; Set flag to enable nozzle offset calibration (for dual-nozzle printers like H2D). No effect on single-nozzle P2S. Slicer controls whether this is commented out.
;M1002 set_flag auto_cali_toolhead_offset_flag=1
; Set flag to enable build plate type detection before printing. Slicer controls whether this is commented out.
;M1002 set_flag build_plate_detect_flag=1

;======== P2S start gcode==========
;===== 2026/02/26 =====

; Set bed temperature to slicer value (non-blocking, does not wait to reach target)
  M140 S[bed_temperature_initial_layer_single] ; heat heatbed first
; TODO: check what this does
  M993 A0 B0 C0 ; nozzle cam detection not allowed.
; Wait for all pending moves/commands to complete
  M400

;=====printer start sound ===================
; Enable all stepper motors
M17
; Wait 1 second
M400 S1
; TODO: M1006 S1 — undocumented. Always appears before stepper motor sound notes.
M1006 S1
; Play stepper motor sound: 3 groups (A/B/L, C/D/M, E/F/N) = one per motor. A/C/E = MIDI note (0=rest), B/D/F = duration. TODO: L/M/N unknown.
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50
; Play stepper motor sound
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50
; Play stepper motor sound
M1006 A61 B9 L50 C61 D9 M50 E61 F9 N50
; Play stepper motor sound
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50
; Play stepper motor sound
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50
; Play stepper motor sound (longer duration: B/D/F=18 vs 9)
M1006 A61 B18 L50 C61 D18 M50 E61 F18 N50
; TODO: M1006 W — undocumented. Always appears after stepper motor sound notes.
M1006 W
;=====printer start sound ===================

; Enable AMS filament remapping (matching sliced filament assignments to actual loaded filaments). Run once before any other M620 command.
  M620 M ;enable remap
; TODO: check what this does
  G389

;===== avoid end stop =================
; Move Z away from any physical travel limit to prevent crashes during startup.
; Set relative positioning mode
  G91
; Move Z axis up 22mm at 1200 mm/min (toolhead away from bed). TODO: S2 parameter meaning unknown.
  G380 S2 Z22 F1200
; Move Z axis down 12mm at 1200 mm/min (toolhead toward bed). Net result: toolhead ends 10mm higher than start. TODO: S2 parameter meaning unknown.
  G380 S2 Z-12 F1200
; Set absolute positioning mode
  G90
;===== avoid end stop =================

;===== reset machine status =================
; Set default acceleration to 10000 mm/s²
  M204 S10000
; TODO: check what this does
  M630 S0 P1
; Set absolute positioning mode
  G90
; Set stepper motor currents to default
  M17 D ; reset motor current to default
; Turn on toolhead logo light
  M960 S5 P1 ; turn on logo lamp
; Set absolute positioning mode
  G90
; Set feedrate override to 100% (normal speed)
  M220 S100 ;Reset Feedrate
; Set speed profile level on LCD/app to 5 (default). Controls the speed preset shown in the UI.
  M1002 set_gcode_claim_speed_level: 5
; Set flow rate override to 100% (normal flow)
  M221 S100 ;Reset Flowrate
; Reset remaining time estimate multiplier to 1.0 (normal). Printer uses this to scale the displayed time remaining.
  M73.2   R1.0 ;Reset left time magnitude
; Set Z-trim value to 0 (clear any previous offset)
  G29.1 Z{+0.0} ; clear z-trim value first
; TODO: check what this does
  M983.1 M1
; Enable motor cog noise reduction (reduces stepper motor noise during printing). NOTE: this depends on M975 S1 (input shaping) being active, but M975 is only called later — so this has no effect until then. Community considers this a bug in the stock gcode.
  M982.2 S1 ; turn on cog noise reduction
; TODO: check what this does
  M983.4 S0
;===== reset machine status =================

;==== set airduct mode ====
;==== if Chamber Cooling is necessary ====
; Slicer conditional: if target chamber temperature >= 40°C
{if (overall_chamber_temperature >= 40)}
; Set airduct mode to heating (P0=cooling, P1=heating).
M145 P1 ; set airduct mode to heating mode for heating
; Set aux fan to full speed (255/255)
M106 P2 S255 ; turn on filter fan
; TODO: undocumented. OpenBambuAPI notes: "M622.1 S0 — Always run just before dynamic extrusion". Purpose unclear.
M622.1 S0
; Select flag ventobox_replace_aux1_fan_flag for conditional check
M1002 judge_flag ventobox_replace_aux1_fan_flag
; Execute following block if ventobox_replace_aux1_fan_flag is false
M622 J0
; Set fan #10 to off
M106 P10 S0 ; turn off left aux fan
; End conditional block
M623
; Slicer conditional: else (chamber temperature < 40°C)
{else}
; Slicer conditional: if minimum vitrification (glass transition) temperature <= 50°C
{if (min_vitrification_temperature <= 50)}
; Set airduct mode to cooling (P0=cooling, P1=heating).
M145 P0 ; set airduct mode to cooling mode for cooling
; Set aux fan to full speed (255/255)
M106 P2 S255 ; turn on auxiliary fan for cooling
; Set chamber fan to ~50% speed (127/255)
M106 P3 S127 ; turn on chamber fan for cooling
; Display "Cooling chamber" on LCD and Bambu Studio (action 29).
M1002 gcode_claim_action : 29
; Wait for chamber temperature to reach target (S0 = wait until chamber cools down).
M191 S0 ; wait for chamber temp
; Set aux fan to ~40% speed (102/255)
M106 P2 S102 ; turn on chamber cooling fan
; TODO: undocumented. OpenBambuAPI notes: "M622.1 S0 — Always run just before dynamic extrusion". Purpose unclear.
M622.1 S0
; Select flag ventobox_replace_aux1_fan_flag for conditional check
M1002 judge_flag ventobox_replace_aux1_fan_flag
; Execute following block if ventobox_replace_aux1_fan_flag is false
M622 J0
; Set fan #10 to off
M106 P10 S0 ; turn off left aux fan
; End conditional block
M623
; Configure exhaust chamber autocooling. TODO: P6/R30/S40/U0.3/V0.8 parameters undocumented.
M142 P6 R30 S40 U0.3 V0.8 ; set PETG exhaust chamber autocooling
; Slicer conditional: else (vitrification temperature > 50°C)
{else}
; Set airduct mode to heating (P0=cooling, P1=heating).
M145 P1 ; set airduct mode to heating mode for heating
; Set aux fan to ~50% speed (127/255)
M106 P2 S127 ; turn on 50% filter fan
; Configure exhaust chamber autocooling. TODO: P6/R30/S40/U0.3/V0.8 parameters undocumented.
M142 P6 R30 S40 U0.3 V0.8 ; set PLA/TPU exhaust chamber autocooling
; Slicer conditional: end inner if
{endif}
; Slicer conditional: end outer if
{endif}
;==== set airduct mode ====

;===== start to heat heatbed & hotend==========
; Display "Heatbed preheating" on LCD and Bambu Studio
  M1002 gcode_claim_action : 2
; Tell printer/display the current filament type (e.g. PLA, PETG). Value set by slicer.
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
; Set hotend temperature to 140°C (non-blocking). TODO: A parameter unknown, Bambu-specific.
  M104 S140 A

; Disable bed leveling compensation
  G29.2 S0 ; avoid invalid abl data

;===== first homing start =====
; Display "Homing toolhead" on LCD and Bambu Studio
  M1002 gcode_claim_action : 13
; Home X axis. T300 = allow nozzle temperature up to 300°C during homing.
  G28 X T300
; Wipe nozzle on purge wiper at 8000 mm/min feedrate.
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
; Move toolhead to position above the cutter/wiper.
  G150.3
; Camera/scanner operation. TODO: S24 mode unknown (M972 S values select different camera operations).
  M972 S24 P0
; Camera/scanner operation. TODO: S26 mode unknown. C0 parameter unknown.
  M972 S26 P0 C0
; Camera/scanner operation. TODO: S42 mode unknown. T5000 likely timeout in ms.
  M972 S42 P0 T5000
; Wipe nozzle on purge wiper at 8000 mm/min feedrate (second pass).
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
; Set absolute positioning mode
  G90
; Linear move to X=128 Y=128 (center of 256mm bed) at 30000 mm/min
  G1 X128 Y128 F30000
; Home Z axis with low precision (P0). T400 = allow nozzle temperature up to 400°C during homing.
  G28 Z P0 T400
; Wait for all pending moves/commands to complete
  M400
;===== first homign end =====

;===== detection start =====
; Display "Identifying build plate type" on LCD and Bambu Studio
  M1002 gcode_claim_action : 11
; Set hotend temperature to (initial layer temp - 80)°C (non-blocking)
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A ; rise temp in advance
; Camera/scanner: detect build plate type by reading ArUco marker (4x4 or 5x5 binary grid) on plate.
; Bambu uses different ArUco IDs for different plate types (Textured PEI, Smooth PEI, etc.),
; but in practice only two codes are used: one for Textured PEI, one for everything else.
; T5000 likely timeout in ms.
  M972 S19 P0 T5000 ;plate type detection

; Slicer conditional: if max print height >= 145mm
  {if max_print_z >= 145}
; Display status on LCD (action 75). Not in BambuStudio source — P2S firmware-specific.
    M1002 gcode_claim_action : 75 ;  Detect obstacles at the botton of the heated bed
; Move toolhead to position above the cutter/wiper.
    G150.3
; Set hotend temperature to initial layer temp (non-blocking)
    M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]} ; rise temp in advance
; Detect obstacles at the bottom of the heated bed. Z parameter = max print height. Only needed for tall prints (>=145mm) where bed travels far down.
    G3811 Z{max_print_z}  ; Detect obstacles at the bottom of the heated bed
; Slicer conditional: end if
  {endif}
;===== detection end =====

;===== prepare print temperature and material ==========
; Wait for all pending moves/commands to complete
  M400
; Disable software endstops on all axes (X0/Y0/Z0 = off). Software endstops prevent moves beyond defined boundaries; disabled here to avoid logic issues during startup.
  M211 X0 Y0 Z0 ;turn off soft endstop
; Enable vibration compensation
  M975 S1 ; turn on input shaping

; Disable bed leveling compensation
  G29.2 S0 ; avoid invalid abl data
; Move toolhead to position above the cutter/wiper.
  G150.3
; Slicer conditional: if filament is PLA/PLA-CF/PETG AND nozzle diameter is 0.2mm
{if ((filament_type[initial_no_support_extruder] == "PLA") || (filament_type[initial_no_support_extruder] == "PLA-CF") || (filament_type[initial_no_support_extruder] == "PETG")) && (nozzle_diameter[initial_no_support_extruder] == 0.2)}
; Set filament flush/purge parameters for the outgoing filament (A0). F = feedrate, H = nozzle diameter, T = flush temp, P = initial layer temp.
M620.10 A0 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
; Set filament flush/purge parameters for the incoming filament (A1). F = feedrate, H = nozzle diameter, T = flush temp, P = initial layer temp.
M620.10 A1 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
; Slicer conditional: else (other filament types or nozzle sizes)
{else}
; Set filament flush/purge parameters for the outgoing filament (A0). F = feedrate, H = nozzle diameter, T = flush temp, P = initial layer temp.
M620.10 A0 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
; Set filament flush/purge parameters for the incoming filament (A1). F = feedrate, H = nozzle diameter, T = flush temp, P = initial layer temp.
M620.10 A1 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
; Slicer conditional: end if
{endif}

; Configure AMS filament cut retraction (how far to pull filament back into AMS tube after cutting). I = extruder index, E = retraction distance (0 = none). TODO: P/L parameters unknown.
 M620.11 P0 L0 I[initial_no_support_extruder] E0
; Configure AMS filament cut retraction. I = extruder index. TODO: K/R parameters unknown.
 M620.11 K0 I[initial_no_support_extruder] R0

; Select AMS tray by index
  M620 S[initial_no_support_extruder]A   ; switch material if AMS exist
; Display "Changing filament" on LCD and Bambu Studio
  M1002 gcode_claim_action : 4
; Tell printer/display the filament type is unknown (before new filament is loaded).
  M1002 set_filament_type:UNKNOWN
; Wait for all pending moves/commands to complete
  M400
; Select tool/extruder [initial_no_support_extruder]
  T[initial_no_support_extruder]
; Wait for all pending moves/commands to complete
  M400
; TODO: check what this does
  M628 S0
; Filament cut (triggers the cutter on the toolhead).
  M629
; Wait for all pending moves/commands to complete
  M400
; Tell printer/display the current filament type (e.g. PLA, PETG). Value set by slicer.
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
; Load filament in AMS by tray index
  M621 S[initial_no_support_extruder]A
; Set hotend temperature to initial layer temp (non-blocking)
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
; Wait for all pending moves/commands to complete
  M400
; Set part cooling fan to off
  M106 P1 S0
; Wait for all pending moves/commands to complete
  M400
; Enable bed leveling compensation
  G29.2 S1
;===== prepare print temperature and material ==========


;===== auto extrude cali start =========================
; Enable vibration compensation
  M975 S1
; Select flag extrude_cali_flag for conditional check
  M1002 judge_flag extrude_cali_flag
; Execute following block if extrude_cali_flag is false (skip calibration)
  M622 J0
; Run flow dynamics calibration (compensates for pressure lag during acceleration/deceleration to prevent gaps and blobs). F = volumetric speed. TODO: A parameter unknown (not nozzle diameter — older firmware used a separate H parameter for that).
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
; End conditional block
  M623

; Execute following block if extrude_cali_flag is true (do calibration)
  M622 J1
; TODO: check what this does
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
; Display "Calibrating dynamic flow" on LCD and Bambu Studio (action 8).
    M1002 gcode_claim_action : 8
; Wait for hotend to reach target temperature
    M109 S{nozzle_temperature[initial_no_support_extruder]}
; Set absolute positioning mode
    G90
; Set extruder to relative mode
    M83
; Run flow dynamics calibration (compensates for pressure lag during acceleration/deceleration to prevent gaps and blobs). F = volumetric speed. TODO: A parameter unknown (not nozzle diameter — older firmware used a separate H parameter for that).
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
; Wait for all pending moves/commands to complete
    M400
; Set part cooling fan to full speed (255/255)
    M106 P1 S255
; Wait 5 seconds
    M400 S5
; Set part cooling fan to off
    M106 P1 S0
; TODO: check what this does
    G150.3
; End conditional block
  M623

; TODO: check what M622 J2 does (not documented, possibly a third branch)
  M622 J2
; TODO: check what this does
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
; Display "Calibrating dynamic flow" on LCD and Bambu Studio (action 8).
    M1002 gcode_claim_action : 8
; Wait for hotend to reach target temperature
    M109 S{nozzle_temperature[initial_no_support_extruder]}
; Set absolute positioning mode
    G90
; Set extruder to relative mode
    M83
; Run flow dynamics calibration (compensates for pressure lag during acceleration/deceleration to prevent gaps and blobs). F = volumetric speed. TODO: A parameter unknown (not nozzle diameter — older firmware used a separate H parameter for that).
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
; Wait for all pending moves/commands to complete
    M400
; Set part cooling fan to full speed (255/255)
    M106 P1 S255
; Wait 5 seconds
    M400 S5
; Set part cooling fan to off
    M106 P1 S0
; TODO: check what this does
    G150.3
; End conditional block
  M623
;===== auto extrude cali end =========================

; Slicer conditional: if hold_chamber_temp_for_flat_print is true
  {if hold_chamber_temp_for_flat_print}
; Display "Thermal Preconditioning for first layer optimization" on LCD and Bambu Studio (action 58).
    M1002 gcode_claim_action : 58
; Set hotend temperature to first layer temp (non-blocking)
    M104 S{first_layer_temperature[initial_no_support_extruder]}
; Slicer conditional: if initial bed temp > 89°C
    {if bed_temperature_initial_layer_single > 89}
; TODO: M1030/SYNC undocumented. Context: holds chamber temperature before printing. S1800 = 1800 seconds (30 min) for high bed temps (>89°C, e.g. ABS/ASA).
        M1030 S1800
; TODO: SYNC undocumented. T value matches M1030 S value. Likely synchronization/wait for the hold period.
        SYNC R0 T1800
; Slicer conditional: else (bed temp <= 89°C)
    {else}
; TODO: M1030/SYNC undocumented. S300 = 300 seconds (5 min) for lower bed temps.
        M1030 S300
; TODO: SYNC undocumented. T value matches M1030 S value.
        SYNC R0 T300
; Slicer conditional: end if
    {endif}
; TODO: M1030 C undocumented. Likely ends/cancels the chamber temp hold.
    M1030 C
; Slicer conditional: end if
  {endif}

; Slicer conditional: if filament is TPU or PVA
  {if filament_type[current_extruder] == "TPU" || filament_type[current_extruder] == "PVA"}
; Slicer conditional: else (filament is not TPU or PVA)
  {else}
; Set extruder to relative mode
    M83
; Retract 3mm of filament at 1800 mm/min
    G1 E-3 F1800
; Wait 500 milliseconds
    M400 P500
; Slicer conditional: end if (TPU/PVA filaments skip the retract)
  {endif}
; TODO: undocumented. In end gcode G150.2 retracts filament to AMS, but here it alternates with G150.1 (wipe) which suggests different behavior in this context.
  G150.2
; Wipe nozzle on purge wiper at 8000 mm/min feedrate.
  G150.1 F8000
; TODO: undocumented.
  G150.2
; Wipe nozzle on purge wiper at 8000 mm/min feedrate (second pass).
  G150.1 F8000

; Set relative positioning mode
  G91
; Move Y -16mm at 12000 mm/min (relative)
  G1 Y-16 F12000 ; move away from the trash bin
; Set absolute positioning mode
  G90
; Wait for all pending moves/commands to complete
  M400

; Set hotend temperature to (initial layer temp - 80)°C (non-blocking)
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A

;===== wipe right nozzle start =====
; Display "Cleaning nozzle tip" on LCD and Bambu Studio
  M1002 gcode_claim_action : 14
; TODO: undocumented. G150 (without suffix) with T = target nozzle temperature. Part of the P2S nozzle wipe/clean sequence.
  G150 T{nozzle_temperature_initial_layer[initial_no_support_extruder]}
; Wait for all pending moves/commands to complete
  M400

; Slicer conditional: if filament is PC (polycarbonate)
{if filament_type[current_extruder] == "PC"}
; Wait for hotend to reach 170°C
  M109 S170 A
; Slicer conditional: else (not PC)
{else}
; Wait for hotend to reach 140°C
  M109 S140 A
; Slicer conditional: end if
{endif}
; Set relative positioning mode
  G91
; Move Z up 5mm at 1200 mm/min (relative)
  G1 Z5 F1200
; Set absolute positioning mode
  G90
; Wait for all pending moves/commands to complete
  M400
; Wipe nozzle on purge wiper. No F parameter specified (unlike other G150.1 calls that use F8000).
  G150.1
;===== wipe left nozzle end =====


;===== mech mode sweep start =====
; Display "Sweeping XY mech mode" on LCD and Bambu Studio
  M1002 gcode_claim_action : 3
; Set absolute positioning mode
  G90
; Move to X=128 Y=128 (center of bed) at 20000 mm/min
  G1 X128 Y128 F20000
; Move to Z=5mm at 1200 mm/min
  G1 Z5 F1200
; Wait 200 milliseconds
  M400 P200
; Vibration compensation fast frequency sweep for Y axis (Q1). A5 = amplitude. TODO: K0, O1 parameters unknown.
  M970.3 Q1 A5 K0 O1
; TODO: undocumented. Part of Y axis vibration compensation sequence. Q1 = Y axis.
  M970.2 Q1 K1 W74 Z0.01
; Apply curve fitting to Y axis (Q1) vibration compensation data. S2 P0 = standard curve fit.
  M974 Q1 S2 P0
; Vibration compensation fast frequency sweep for X axis (Q0). A7 = amplitude. TODO: K0, O1 parameters unknown.
  M970.3 Q0 A7 K0 O1
; TODO: undocumented. Part of X axis vibration compensation sequence. Q0 = X axis.
  M970.2 Q0 K1 W74 Z0.01
; Apply curve fitting to X axis (Q0) vibration compensation data. S2 P0 = standard curve fit.
  M974 Q0 S2 P0
; Enable vibration compensation
  M975 S1
; Wait for all pending moves/commands to complete
  M400
;===== mech mode sweep end =====

;===== bed leveling ==================================
; Display "Waiting for heatbed temperature" on LCD and Bambu Studio (action 54).
  M1002 gcode_claim_action : 54
; Wait for bed to reach initial layer temperature
  M190 S[bed_temperature_initial_layer_single]; ensure bed temp
; Wait for hotend to reach 140°C
  M109 S140 A
; Set part cooling fan (fan #0) to off
  M106 S0 ; turn off fan , too noisy
; Select flag g29_before_print_flag for conditional check
  M1002 judge_flag g29_before_print_flag
; Execute following block if g29_before_print_flag is true
  M622 J1
; Display "Auto bed levelling" on LCD and Bambu Studio
    M1002 gcode_claim_action : 1
; Slicer conditional: if hold_chamber_temp_for_flat_print is true
    {if hold_chamber_temp_for_flat_print}
; Run bed mesh calibration on full bed (H = full bed probe). Used when holding chamber temp for flat prints.
      G29 H
; Slicer conditional: else
    {else}
; Adaptive bed leveling: probe only the print area (X/Y = origin, I/J = size). Reduces prep time vs full-bed probing.
      G29 A1 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}
; Slicer conditional: end if
    {endif}
; Wait for all pending moves/commands to complete
    M400
; Save current settings to EEPROM
    M500 ; save cali data
; End conditional block
  M623

; TODO: check what M622 J2 does (not documented, possibly a third branch)
  M622 J2
; Display "Auto bed levelling" on LCD and Bambu Studio
    M1002 gcode_claim_action : 1
; Slicer conditional: if hold_chamber_temp_for_flat_print is true
    {if hold_chamber_temp_for_flat_print}
; Run bed mesh calibration on full bed (H = full bed probe). Used when holding chamber temp for flat prints.
      G29 H
; Slicer conditional: else
    {else}
; Adaptive bed leveling: probe only the print area. TODO: A2 vs A1 mode difference unknown.
      G29 A2 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}
; Slicer conditional: end if
    {endif}
; Wait for all pending moves/commands to complete
    M400
; Save current settings to EEPROM
    M500 ; save cali data
; End conditional block
  M623

; Execute following block if g29_before_print_flag is false
  M622 J0
; Home all axes
    G28
; End conditional block
  M623
; Enable bed leveling compensation
  G29.2 S1
; Home all axes
  G28
;===== bed leveling end ================================

; TODO: check what this does
  M985.1 U0 E2
; TODO: check what this does
  M985.1 U1 E2

; Set hotend temperature to initial layer temp (non-blocking)
  M104 S[nozzle_temperature_initial_layer] A
; Move toolhead to position above the cutter/wiper.
  G150.3 ; move to garbage can to wait for temp

;===== wait temperature reaching the reference value =======
; Wait for bed to reach initial layer temperature
  M190 S[bed_temperature_initial_layer_single]

  ;========turn off light and fans =============
; Turn off laser S1 (on X1C: Y-axis 808nm IR laser). P2S has no lasers — likely a no-op from shared gcode template.
  M960 S1 P0 ; turn off laser
; Turn off laser S2 (on X1C: X-axis 405nm purple laser). P2S has no lasers — likely a no-op from shared gcode template.
  M960 S2 P0 ; turn off laser
; Set part cooling fan (fan #0) to off
  M106 S0 ; turn off cooling fan

;===== wait temperature reaching the reference value =======

; Display status on LCD (action 255). Not in BambuStudio source — handled at firmware level. On P1/P2 series, 255 signals idle/end of startup preparation.
  M1002 gcode_claim_action : 255
; Wait for all pending moves/commands to complete
  M400
; Enable vibration compensation
  M975 S1 ; turn on mech mode supression

;============switch again==================
; Disable software endstops on all axes (X0/Y0/Z0 = off). Software endstops prevent moves beyond defined boundaries; disabled here to avoid logic issues during startup.
  M211 X0 Y0 Z0 ;turn off soft endstop
; Set relative positioning mode
  G91
; Move Z up 6mm at 1200 mm/min (relative)
  G1 Z6 F1200
; Set absolute positioning mode
  G90
; Tell printer/display the current filament type (e.g. PLA, PETG). Value set by slicer.
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
; Select AMS tray by index
  M620 S[initial_no_support_extruder]A
; Wait for all pending moves/commands to complete
  M400
; Select tool/extruder [initial_no_support_extruder]
  T[initial_no_support_extruder]
; Wait for all pending moves/commands to complete
  M400
; TODO: check what this does
  M628 S0
; Filament cut (triggers the cutter on the toolhead).
  M629
; Wait for all pending moves/commands to complete
  M400
; Load filament in AMS by tray index
  M621 S[initial_no_support_extruder]A
;============switch again==================

;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
; Slicer conditional: if initial bed temp > 89°C
  {if bed_temperature_initial_layer_single > 89}
; Slicer conditional: if bed type is Textured PEI Plate
    {if curr_bed_type=="Textured PEI Plate"}
; Set Z-trim to -0.02mm for Textured PEI Plate at high bed temp
      G29.1 Z{-0.02} ; for Textured PEI Plate
; Slicer conditional: else (other plate types)
    {else}
; Set Z-trim to 0mm (no offset)
      G29.1 Z{0.0}
; Slicer conditional: end if
    {endif}
; Slicer conditional: else (bed temp <= 89°C)
  {else}
; Slicer conditional: if bed type is Textured PEI Plate
    {if curr_bed_type=="Textured PEI Plate"}
; Set Z-trim to +0.01mm for Textured PEI Plate at low bed temp
      G29.1 Z{0.01} ; for Textured PEI Plate
; Slicer conditional: else (other plate types)
    {else}
; Set Z-trim to +0.03mm
      G29.1 Z{0.03}
; Slicer conditional: end if
    {endif}
; Slicer conditional: end if
  {endif}

; Save current settings to EEPROM
  M500

;===== nozzle load line ===============================
; Display "Printing calibration lines" on LCD and Bambu Studio (action 51).
M1002 gcode_claim_action : 51
; Enable bed leveling compensation
  G29.2 S1 ; ensure z comp turn on
; Set absolute positioning mode
  G90
; Set extruder to relative mode
  M83
; Wait for hotend to reach initial layer temperature
  M109 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
; Rapid move to X=100 Y=0 at 24000 mm/min
  G0 X100 Y0 F24000
; Wait for all pending moves/commands to complete
  M400
  ;G130 O0 X100 Y-0.4 Z0.8 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L40 E20 D5
; Print purge/prime line at front edge of bed. P2S-specific command. X/Y = position, Z = height, F = feedrate from volumetric speed, E = extrusion amount. TODO: O, L, D parameters undocumented.
  G130 O0 X100 Y-0.2 Z0.6 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L40 E12 D4
; Set absolute positioning mode
  G90
; Set extruder to relative mode
  M83
; Move to Z=0.5mm at current feedrate
  G1 Z0.5
; Wait for all pending moves/commands to complete
  M400
;===== noozle load line end ===========================
; Clear status message on LCD and Bambu Studio
M1002 gcode_claim_action : 0
; TODO: undocumented.
  G29.99

; Slicer conditional: if filament is TPU, PLA, or PETG
{if (filament_type[initial_no_support_extruder] == "TPU") ||
(filament_type[initial_no_support_extruder] == "PLA") ||  (filament_type[initial_no_support_extruder] == "PETG")}
; Enable nozzle clog detection for TPU/PLA/PETG. S1 = enable, H = nozzle diameter.
M1015.3 S1 H[nozzle_diameter];enable tpu, pla and petg clog detect
; Slicer conditional: else (other filament types)
{else}
; Disable nozzle clog detection (not supported for this filament type).
M1015.3 S0;disable clog detect
; Slicer conditional: end if
{endif}

; Slicer conditional: if filament is PLA, PETG, PLA-CF, or PETG-CF
{if (filament_type[initial_no_support_extruder] == "PLA") ||  (filament_type[initial_no_support_extruder] == "PETG")
 ||  (filament_type[initial_no_support_extruder] == "PLA-CF")  ||  (filament_type[initial_no_support_extruder] == "PETG-CF")}
; Enable extruder air printing detection (detects when extruder is printing with no filament coming out). S1 = enable, H = nozzle diameter. TODO: K1 parameter unknown.
M1015.4 S1 K1 H[nozzle_diameter] ;enable E air printing detect
; Slicer conditional: else (other filament types)
{else}
; Disable extruder air printing detection.
M1015.4 S0 K0 H[nozzle_diameter] ;disable E air printing detect
; Slicer conditional: end if
{endif}

; Enable AMS air printing detection (detects filament feed failure from AMS). I = extruder index, W1 = enable.
M620.6 I[initial_no_support_extruder] W1 ;enable ams air printing detect

; Set load cell sensitivity for X axis (Q0). Load cells are force sensors in the toolhead used for Z homing (nozzle contact detection) and clog detection. B and S are sensitivity thresholds.
M1010 Q0 B0.023 S0.01
; Set load cell sensitivity for Y axis (Q1). Different threshold from X due to different mechanical characteristics.
M1010 Q1 B0.005 S0.01
; Enable load cell monitoring (continuous force sensing during printing).
M1010.1 S1

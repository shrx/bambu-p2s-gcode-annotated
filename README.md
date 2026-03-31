# Annotated Bambu Lab P2S Machine Start G-code

Original and annotated versions of the default machine start (pre-print) G-code for the Bambu Lab P2S 3D printer, as shipped with Bambu Studio 2.5.0.66 (retrieved 2026-02-26).

## Files

- `machine_start.gcode` — Original start G-code
- `machine_start_annotated.gcode` — Annotated copy with documentation comments

## Annotation approach

- Every line is documented with a comment explaining what it does
- Only confirmed information is included, unknowns are marked with `TODO`
- Bambu's own inline comments (after `;`) are preserved as-is
- Slicer template syntax (`{if}`, `{else}`, `{endif}`, `[variable]`) is explained in context

## What's covered

- Standard Marlin G-codes (G0/G1, G28, G90/G91, M104/M109, M140/M190, M106, etc.)
- Bambu-proprietary commands (M1002, M620/M621, M960, M970/M974/M975, G150.x, G380, etc.)
- Slicer conditional logic and template variables
- LCD/app status messages (`M1002 gcode_claim_action`) with display strings from BambuStudio source
- AMS filament handling, flow dynamics calibration, vibration compensation, build plate detection
- P2S-specific commands not present on older models (G150.x wiper system, G130 purge line, M1010 load cell, G3811 obstacle detection)

## Known issues in stock G-code

As of 2026-02-26 there are two issues present in stock G-code, as documented by community members:

- **Redundant homing**: An unconditional `G28` after the bed leveling block re-homes every print even when ABL already homed ([source](https://github.com/scoofz/P2S-start-gcode))
- **Noise reduction ordering**: `M982.2 S1` (cog noise reduction) is called before `M975 S1` (input shaping), but depends on it. Therefore it has no effect during the noisiest startup phases ([source](https://old.reddit.com/r/BambuLab/comments/1s8kneu/p2s_quirks_and_poorly_optimized_firmware_settings/))

## Disclaimer

The G-code itself is authored by Bambu Lab and ships as part of [Bambu Studio](https://github.com/bambulab/BambuStudio) (AGPL-3.0), in [`resources/profiles/BBL/machine/`](https://github.com/bambulab/BambuStudio/tree/master/resources/profiles/BBL/machine). This repository only adds documentation comments and does not modify the original G-code. Bambu Lab is not affiliated with this project.

## References

### Community G-code documentation
- [OpenBambuAPI — G-code reference](https://github.com/Doridian/OpenBambuAPI/blob/main/gcode.md)
- [x1plus — Gcode.md](https://github.com/jphannifan/x1plus-testing/blob/main/Gcode.md)
- [Bambu Lab X1 Specific G-Code (forum)](https://forum.bambulab.com/t/bambu-lab-x1-specific-g-code/666)
- [BBL P1S organized start and end gcode (forum)](https://forum.bambulab.com/t/bbl-p1s-organized-start-and-end-gcode/38795)

### P2S-specific
- [P2S quick start G-code by SylwekK (forum)](https://forum.bambulab.com/t/bambu-lab-p2s-print-starts-after-1-5-minutes/232157)
- [P2S optimized start G-code by scoofz (GitHub)](https://github.com/scoofz/P2S-start-gcode)
- [P2S quirks and firmware settings (Reddit)](https://old.reddit.com/r/BambuLab/comments/1s8kneu/p2s_quirks_and_poorly_optimized_firmware_settings/)
- [P2S single filament no-switch startup (GitHub Gist)](https://gist.github.com/pawrequest/7e7b09718024f1fc16eb375e78f1708f)

### Official Bambu Lab sources
- [BambuStudio source — `get_stage_string()` in DeviceManager.cpp](https://github.com/bambulab/BambuStudio/blob/master/src/slic3r/GUI/DeviceManager.cpp) — LCD status message strings
- [OpenBambuAPI — MQTT reference](https://github.com/Doridian/OpenBambuAPI/blob/main/mqtt.md)
- [Bambu Lab Wiki — MIDI to A1 mini User Guide](https://wiki.bambulab.com/en/A1-mini/Midi) — M1006 stepper motor music
- [Bambu Lab Wiki — Flow Dynamics Calibration](https://wiki.bambulab.com/en/software/bambu-studio/calibration_pa)
- [Bambu Lab Wiki — Filament Mapping Principles](https://wiki.bambulab.com/en/software/bambu-studio/filament-mapping-principle)
- [Bambu Lab Wiki — P2S Nozzle Purge Position Calibration](https://wiki.bambulab.com/en/p2s/troubleshooting/purge-wiper-position-calibeation)
- [Bambu Lab Wiki — P2S Visual Detection](https://wiki.bambulab.com/en/p2s/manual/intelligent-detection)

### Other
- [ha-bambulab Home Assistant integration — const.py](https://github.com/greghesp/ha-bambulab) — Stage ID mappings, airduct modes
- [NineLizards — Plate Lab: ArUco codes and Bambu Lab plates](https://ninelizardsblog.blogspot.com/2024/06/plate-lab-bambu-lab-plates-and-x1c.html)
- [OpenCV — ArUco Marker Detection](https://docs.opencv.org/4.x/d5/dae/tutorial_aruco_detection.html)

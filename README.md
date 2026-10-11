# Image processing on Cora Z7-07S

A 3x3 image convolution pipeline on a Digilent Cora Z7-07S. Verilog line buffers and a convolution core sit on AXI-Stream, the Zynq processing system feeds pixels through an AXI DMA, and a bare-metal application sends a 512x512 image and reads the result back over UART.

Tested with Vivado 2023.1. The applications were built with Vitis 2023.2. The board part is `digilentinc.com:cora-z7-07s:part0:1.1` (`xc7z007sclg400-1`).

## Layout

| Path | Contents |
|---|---|
| `rtl/` | Convolution pipeline (`imageProcessTop.v`, `lineBuffer.v`, `imageControl.v`, `conv.v`) and `tb.v` |
| `IP/outputBuffer/` | FIFO Generator `.xci` used by the pipeline |
| `IP/imageProcess/` | Packaged custom IP (`component.xml` and the GUI file). The script copies `rtl/` into this IP before building |
| `constraints/` | User constraints. This design has none yet |
| `SW/hello_world_3/src/` | Current bare-metal application |
| `SW/hello_image/src/`, `SW/hello_image_2/src/` | Earlier application versions |
| `python_script/` | Host scripts that format `imageData.h` and turn captured bytes back into an image |
| `create_project.tcl` | Recreates both Vivado projects |
| `imageProcessingSystem_bd.tcl` | Recreates the block design |

`work/` is where Vivado writes the projects. It is not stored in git.

## Rebuild the Vivado project

From this directory, with Vivado 2023.1 on `PATH`:

```bat
vivado -mode batch -source create_project.tcl
```

The script creates two projects:

- `work/cora_image_process` — RTL sources, the output FIFO, and `tb` as the simulation top
- `work/cora_image_process_system` — processing system, AXI DMA, the image-processing IP, data-width converter, SmartConnect, and interrupt concat

Pass `-tclargs bitstream` to run implementation and write `work/cora_image_process_system/imageProcessingSystem_wrapper.xsa`. Any `.xdc` file placed in `constraints/` is added to both projects.

The simulation testbench reads `lena_gray.bmp` from the simulator working directory and writes `blurred_lena.bmp`.

## Software

Open `SW` as the Vitis workspace. The platform `pll_image` was built from the exported XSA. `hello_world_3` is the application that pushes `imageData.h` through the DMA, waits on the core interrupt, and prints the processed pixels on the UART at 115200 baud.

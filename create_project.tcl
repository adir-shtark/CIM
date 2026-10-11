# Recreate the CIM image-processing Vivado projects from source.
#
# From this folder, in a Vivado 2023.1 Tcl console or batch shell:
#   vivado -mode batch -source create_project.tcl
#
# That builds two projects under work/:
#   work/cora_image_process          RTL + outputBuffer FIFO, for simulation
#   work/cora_image_process_system   block design used by Vitis
#
# To also run implementation and write the .xsa the Vitis platform consumes:
#   vivado -mode batch -source create_project.tcl -tclargs bitstream
#
# Sources this script expects to find next to itself:
#   rtl/*.v
#   IP/outputBuffer/outputBuffer.xci
#   IP/imageProcess/component.xml  and  IP/imageProcess/xgui/
#   imageProcessingSystem_bd.tcl
#   constraints/*.xdc              optional; this design has none today

set origin_dir [file normalize [file dirname [info script]]]

proc fwd {path} {
  return [string map {\\ /} [file normalize $path]]
}

proc sync_packaged_ip {origin_dir} {
  set dst [file join $origin_dir IP imageProcess src]
  file mkdir [file join $dst outputBuffer]
  foreach f {conv.v imageControl.v imageProcessTop.v lineBuffer.v tb.v} {
    file copy -force [file join $origin_dir rtl $f] [file join $dst $f]
  }
  file copy -force \
    [file join $origin_dir IP outputBuffer outputBuffer.xci] \
    [file join $dst outputBuffer outputBuffer.xci]
}

proc add_constraints {origin_dir} {
  set xdc_files [glob -nocomplain -types f [file join $origin_dir constraints *.xdc]]
  if {[llength $xdc_files] == 0} {
    return
  }
  set paths {}
  foreach f $xdc_files {
    lappend paths [fwd $f]
  }
  add_files -fileset constrs_1 -norecurse $paths
}

set run_bitstream 0
if {[info exists argv] && [lsearch -exact $argv bitstream] >= 0} {
  set run_bitstream 1
}

set part xc7z007sclg400-1
set board digilentinc.com:cora-z7-07s:part0:1.1
set work_dir [file join $origin_dir work]
set ip_repo [fwd [file join $origin_dir IP imageProcess]]

file mkdir $work_dir
sync_packaged_ip $origin_dir

if {[llength [get_projects -quiet]]} {
  close_project
}

# -----------------------------------------------------------------------------
# RTL project. imageProcessTop is the top; tb is simulation-only.
# -----------------------------------------------------------------------------
create_project cora_image_process [fwd [file join $work_dir cora_image_process]] \
  -part $part -force
set_property board_part $board [current_project]
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

set rtl_sources {}
foreach f {conv.v imageControl.v imageProcessTop.v lineBuffer.v} {
  lappend rtl_sources [fwd [file join $origin_dir rtl $f]]
}
add_files -norecurse $rtl_sources
set_property top imageProcessTop [current_fileset]

set tb_path [fwd [file join $origin_dir rtl tb.v]]
add_files -fileset sim_1 -norecurse $tb_path
set_property top tb [get_filesets sim_1]
set_property used_in_synthesis false [get_files $tb_path]
set_property used_in_implementation false [get_files $tb_path]

import_ip [fwd [file join $origin_dir IP outputBuffer outputBuffer.xci]]
generate_target all [get_ips outputBuffer]

add_constraints $origin_dir
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project

# -----------------------------------------------------------------------------
# System project. The custom IP is the packaged core in IP/imageProcess.
# imageProcessingSystem_bd.tcl recreates the block design in the open project.
# -----------------------------------------------------------------------------
create_project cora_image_process_system \
  [fwd [file join $work_dir cora_image_process_system]] \
  -part $part -force
set_property board_part $board [current_project]
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property ip_repo_paths [list $ip_repo] [current_project]
update_ip_catalog

set bd_script [fwd [file join $origin_dir imageProcessingSystem_bd.tcl]]
if {![file exists $bd_script]} {
  error "Missing block-design script: $bd_script"
}
source $bd_script

set bd_file [get_files imageProcessingSystem.bd]
set wrapper [make_wrapper -files $bd_file -top -force]
add_files -norecurse $wrapper
set_property top imageProcessingSystem_wrapper [current_fileset]
add_constraints $origin_dir
generate_target all $bd_file
update_compile_order -fileset sources_1

if {$run_bitstream} {
  launch_runs impl_1 -to_step write_bitstream -jobs 8
  wait_on_run impl_1
  set impl_status [get_property STATUS [get_runs impl_1]]
  if {![string match "*Complete*" $impl_status]} {
    error "Implementation did not complete: $impl_status"
  }
  open_run impl_1
  set xsa_file [fwd [file join $work_dir cora_image_process_system imageProcessingSystem_wrapper.xsa]]
  write_hw_platform -fixed -include_bit -force -file $xsa_file
  puts "INFO: Wrote hardware platform $xsa_file"
}

puts "INFO: Projects are in [fwd $work_dir]"

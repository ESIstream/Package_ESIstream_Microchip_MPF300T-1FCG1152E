# ##----------------------------------------------------------------------
# ##--! @file   : run_simu.tcl
# ##--! @brief  : this file run a simultion for a libero project
# ##--! @author : Rayhane BAHRI
# ##--! @date   : 17/10/2022
# ##--! @version 1.0
# ##----------------------------------------------------------------------

set OS 	$tcl_platform(os)
set err 	{0}
set Msg {Errors :0}
set Proj "esistream_txrx_64b"
set ls_ch [open "project_check_status.txt" w+]

proc grepPattern { ex dumped_file } \
{
	set f_id [open $dumped_file]
	while {[eof $f_id]==0} \
	{
		set line_tokens [gets $f_id]
		if {[regexp $ex "$line_tokens"]==1} \
		{
			puts "Pattern $ex found"
			close $f_id
			return 1	
		}
	}
	puts "Pattern $ex not found"
	close $f_id
	return 0
}

open_project -file {./../esistream_txrx_64b/esistream_txrx_64b.prjx}				   

	puts $ls_ch "Starting Modelsim..."
	if {[catch {run_tool -name SIM_PRESYNTH }]} {
		puts  "Pre-Synthesis simulation -> FAILED"
		puts $ls_ch "Simulation -> FAILED\n\n"
		puts "TEST RUN FAILED";
		incr err
		return 0
	}

	if {$err == 0} {
		puts "\n"
		puts $ls_ch "TEST CASE PASSED"
		puts "TEST CASE PASSED"
		puts "\n"
	} else {
		puts "\n"
		puts $ls_ch"TEST CASE FAILED"
		puts "\n"
	} 
	

save_project
close_project

# ##----------------------------------------------------------------------
# ##--! @file   : run_bitstream.tcl
# ##--! @brief  : this file creates the bitstream of a libero project
# ##--! @author : Rayhane BAHRI
# ##--! @date   : 21/09/2022
# ##--! @version 1.0
# ##----------------------------------------------------------------------
set OS 	$tcl_platform(os)
set err 	{0}
set Msg {Errors :0}
set Proj "esistream_txrx_32b"
set ls_ch [open "project_check_status.txt" w+]

# proc grepPattern { ex dumped_file } \
# {
	# set f_id [open $dumped_file]
	# while {[eof $f_id]==0} \
	# {
		# set line_tokens [gets $f_id]
		# if {[regexp $ex "$line_tokens"]==1} \
		# {
			# puts "Pattern $ex found"
			# close $f_id
			# return 1	
		# }
	# }
	# puts "Pattern $ex not found"
	# close $f_id
	# return 0
# }

open_project -file {./../esistream_txrx_32b/esistream_txrx_32b.prjx}


	puts $ls_ch "Starting Synplify Pro ME..." 
	if {[catch {run_tool -name SYNTHESIZE }]} {
		puts  " Synthesis -> FAILED"
		puts "TEST RUN FAILED";
	} else {
		puts $ls_ch "Synthesize completed successfully\n"
	}

	if {[catch {run_tool -name PLACEROUTE }]} {
		puts  "Place and route -> FAILED"
		puts "TEST RUN FAILED";
		incr err
		return 0
	}

	if {[catch {run_tool -name VERIFYTIMING }]} {
		puts  "Place and route -> FAILED"
		puts "TEST RUN FAILED";
		incr err
		return 0
	}

	if {[catch {run_tool -name VERIFYPOWER }]} {
		puts  "Place and route -> FAILED"
		puts "TEST RUN FAILED";
		incr err
		return 0
    }
	if {[catch {run_tool -name GENERATEPROGRAMMINGDATA }]} {
		puts  "generate programming data-> FAILED"
		puts "TEST RUN FAILED";
		incr err
		return 0
	}
	if {[catch {run_tool -name GENERATEPROGRAMMINGFILE  }]} {
		puts  "generate bitstream -> FAILED"
		puts "TEST RUN FAILED";
		incr err
		return 0
	} else {
		puts $ls_ch "BITSTREAM generated\n"
	}
export_bitstream_file -file_name {esistream_txrx_32b} \
                      -export_dir {./../bitstream} \
                      -format STP \
                      -master_file 0 \
                      -master_file_components {} \
                      -encrypted_uek1_file 0 \
                      -encrypted_uek1_file_components {} \
                      -encrypted_uek2_file 0 \
                      -encrypted_uek2_file_components {} \
                      -trusted_facility_file 1 \
                      -trusted_facility_file_components {FABRIC}
                      

	
	if {$err == 0} {
		puts "\n"
		puts $ls_ch "TEST CASE PASSED"
		puts "TEST CASE PASSED"
		puts "\n"
	} else {
		puts "\n"
		puts "TEST CASE FAILED"
		puts "\n"
	} 
	

save_project
close_project

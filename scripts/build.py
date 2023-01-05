# ##----------------------------------------------------------------------
# ##--! @file   : build.py
# ##--! @brief  : 
# ##--! @author : Rayhane BAHRI
# ##--! @date   : 14/09/2022
# ##--! @version: 1.0
# ##----------------------------------------------------------------------

import os
import sys
import time
import datetime
import logging
logging.basicConfig(level=logging.DEBUG)
# DEBUG    | Detailed information, typically of interest only when diagnosing problems.
# INFO     | Confirmation that things are working as expected.
# WARNING  | An indication that something unexpected happened, or indicative of some problem in the near future (e.g. "disk space low"). The software is still working as expected.
# ERROR    | Due to a more serious problem, the software has not been able to perform some function.
# CRITICAL | A serious error, indicating that the program itself may be unable to continue running.

if  len(sys.argv) > 1:
    arg1= sys.argv[1]
    arg2= sys.argv[2]
else:
    arg1 = 0
    print("-------------------------------------------------------------")
    print("-- START of PYTHON BUILD.PY ARG1 ARG2 without argument...")
    print("-- ")
    print("-- use 'python build.py prj 32_5' to open 32bit-libero project 5G datarate")
    print("-- use 'python build.py prj 32' to open 32bit-libero project")
    print("-- use 'python build.py sim 32' to launch testbench simulation for 32bit project")
    print("-- use 'python build.py gen 32' to launch bitstream generationfor 32bit project")
    print("-- use 'python build.py prj 64' to open 64bit-libero project")
    print("-- use 'python build.py sim 64' to launch testbench simulation for 64bit project")
    print("-- use 'python build.py gen 64' to launch bitstream generationfor 64bit project")
    print("-- ")
    print("-------------------------------------------------------------")
    sys.exit("-- exit on error: python script argument is missing...")
        
logging.debug(arg1)
logging.debug(arg2)

# Get the current working directory:
cwd = os.getcwd()
logging.debug("Current working directory: %s", cwd)

# Get the current working durectory path (python_path):
cwdp = os.path.dirname(os.path.realpath(__file__))
logging.debug("Current working directory path: %s", cwdp)

# Create libero.bat  directory path
libero_path = "C:\\Microsemi\\Libero_SoC_v2022.1\\Designer\\bin\\libero.exe"

if arg2 == "32" :
    if arg1 == "prj" :
        os.system(libero_path +" SCRIPT:create_project_32b.tcl" )
        logging.debug("end of project build ")
        print("-------------------------------------------------------------")
        print("-- LIBERO PROJECT CREATED...")
        print("-------------------------------------------------------------")
    if arg1 == "sim" :
        os.system(libero_path +" SCRIPT:run_simu_32b.tcl")
        logging.debug("end of sim %s %s")
        print("-------------------------------------------------------------")
        print("-- TESTBENCH SIMULATED...")
        print("-------------------------------------------------------------")
    if arg1 == "gen" :
        os.system(libero_path + " SCRIPT:run_bitstream_32b.tcl")
        logging.debug("end of bitstream gen")
        print("-------------------------------------------------------------")
        print("-- BISTREAM GENERATED...")
        print("-------------------------------------------------------------")
elif arg2 == "64" :
    if arg1 == "prj" :
        os.system(libero_path +" SCRIPT:create_project_64b.tcl" )
        logging.debug("end of project build ")
        print("-------------------------------------------------------------")
        print("-- LIBERO PROJECT CREATED...")
        print("-------------------------------------------------------------")
    if arg1 == "sim" :
        os.system(libero_path +" SCRIPT:run_simu_64b.tcl")
        logging.debug("end of sim %s %s")
        print("-------------------------------------------------------------")
        print("-- TESTBENCH SIMULATED...")
        print("-------------------------------------------------------------")
    if arg1 == "gen" :
        os.system(libero_path + " SCRIPT:run_bitstream_64b.tcl")
        logging.debug("end of bitstream gen")
        print("-------------------------------------------------------------")
        print("-- BISTREAM GENERATED...")
        print("-------------------------------------------------------------")
elif arg2 == "32_5" :
    if arg1 == "prj" :
        os.system(libero_path +" SCRIPT:create_project_32b-5G.tcl" )
        logging.debug("end of project build ")
        print("-------------------------------------------------------------")
        print("-- LIBERO PROJECT CREATED...")
        print("-------------------------------------------------------------")



















# hw_id = 0
# for hw in hw_project_list:
  # logging.debug(hw)
  # hw_id = hw_id + 1
  # tcl_path = ""
  # # Work only on enabled implementations:
    # if imp[hw_id]:
        # logging.debug(imp)
        # if arg1 == "prj" or arg1 == "all":
            # tcl_path = imp[0]
            # logging.debug(tcl_path)
            # # Launch bat file to create vivado project and generate simulation scripts (compile.bat, elaborate.bat and simulate.bat).
            # # In a batch file use CALL is better than use START because CALL waits for the end of process execution to continue !
            # build_enable = str(0)
            # print ("*************************************************")
            # os.system(libero_path + " " +"SCRIPT:"+tcl_path )
            # print ("*************************************************")
            # logging.debug("end of bat file creating vivado project and generating simulation scripts (compile.bat, elaborate.bat and simulate.bat).")
            # logging.debug("end of build %s %s", hw, "create_project.tcl")
            # print("-------------------------------------------------------------")
            # print("-- LIBERO PROJECT CREATED...")
            # print("-------------------------------------------------------------")
        # if arg1 == "sim" or arg1 == "all":
            # tcl_path = imp[1]
            # logging.debug(tcl_path)
            # # Open testbench log file in append mode, or create it if it does not exist:
            # tb_log = open(tb_log_path, "a+")
            # tb_log_text = "\r\n" + str(datetime.datetime.now()) + ": " + package_reference + ", " + hw + ", " + imp[0] + " [sim] \r\n" 
            # tb_log.write(tb_log_text)
            # tb_log.close() 
            # # Launch simulation only
            # sim_enable = str(imp[hw_id])
            # os.system(libero_path + " " +"SCRIPT:"+tcl_path )
            # logging.debug("end of sim %s %s", hw, "run_simu.tcl")
            # print("-------------------------------------------------------------")
            # print("-- TESTBENCH SIMULATED...")
            # print("-------------------------------------------------------------")
        # if arg1 == "gen" or arg1 == "all":
            # tcl_path = imp[2]
            # logging.debug(tcl_path)
            # # Open testbench log file in append mode, or create it if it does not exist:
            # tb_log = open(tb_log_path, "a+")
            # tb_log_text = "\r\n" + str(datetime.datetime.now()) + ": " + package_reference + ", " + hw + ", " + imp[0] + " [gen]\r\n" 
            # tb_log.write(tb_log_text)
            # tb_log.close() 
            # # Launch simulation only
            # gen_enable = str(-1)
            # os.system(libero_path + " SCRIPT: run_bitstream.tcl")
            # logging.debug("end of gen %s %s", hw, "run_bitstream.tcl")
            # print("-------------------------------------------------------------")
            # print("-- BISTREAM GENERATED...")
            # print("-------------------------------------------------------------")
    

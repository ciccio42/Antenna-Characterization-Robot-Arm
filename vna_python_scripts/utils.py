#! /usr/bin/env python3

PC_VNA_ADDRESS = '192.168.1.112'
SERVER_IP = "192.168.1.101"  # The server's hostname or IP address
PORT = 65432  # The port used by the server
BUFFSIZE = 1024

INIT_FILE_PATH = "E:\Test_braccio\init_file.txt"
COMMAND_FILE_PATH = "E:\Test_braccio\command_file.txt"

# Init Messages
INIT_MSG = 'Run initialization'
INIT_OK = 'INIT OK'
INIT_FAIL = 'INIT FAIL'

# Data Acquisition Messages
START_ACQUISITION = "START ACQUISITION" 
DATA_ACQUISITION_OK = "DATA ACQUISITION OK"
DATA_ACQUISITION_FAIL = "DATA ACQUISITION FAIL"
STOP_ACQUISITION = "STOP ACQUISITION"

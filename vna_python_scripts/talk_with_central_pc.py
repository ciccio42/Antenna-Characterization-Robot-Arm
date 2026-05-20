import socket
import time
from utils import *
import os


def reset_files():
    with open(INIT_FILE_PATH, 'w') as init_file:
        init_file.write('RESET')

    with open(COMMAND_FILE_PATH, 'w') as command_file:
        command_file.write('RESET')

def initialization():
    # Wait until initialization is completed
    init_result = None
    with open(INIT_FILE_PATH, 'r') as init_file:
        
        while init_result != INIT_OK and init_result != INIT_FAIL:
            init_file.seek(0)
            lines = init_file.readlines()
            # print(lines)
            assert len(lines) <= 1, 'Error Init File has more than 1 line'

            if len(lines) == 1:
                init_result = lines[0].strip()
                print('Init result: {}'.format(init_result))
                time.sleep(1)
                
        return True if init_result == INIT_OK else False

def command_start_acquisition():
    with open(COMMAND_FILE_PATH, 'w') as command_file:
        print("Sending command for data acquisition")
        command_file.write(START_ACQUISITION)

def wait_data_acquisition():
    data_acquisition_result = None
    with open(COMMAND_FILE_PATH, 'r') as command_file:
        while data_acquisition_result != DATA_ACQUISITION_OK and data_acquisition_result != DATA_ACQUISITION_FAIL:
            command_file.seek(0)
            lines = command_file.readlines()
            # print(lines)
            assert len(lines) <= 1, 'Error Init File has more than 1 line'

            if len(lines) == 1:
                data_acquisition_result = lines[0].strip()
                print('Data Acquisition result: {}'.format(data_acquisition_result))
                time.sleep(1)
                
        return True if data_acquisition_result == DATA_ACQUISITION_OK else False
        

if __name__ == '__main__':

    reset_files()
    conn_port = PORT
    n_scan = 0
    max_num_scan = 3
    data_acquisition_result = True
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            print("Connecting to IP {} - Port {}".format(SERVER_IP, conn_port))
            s.connect((SERVER_IP, conn_port))
            print("Connected to server")
        except ConnectionRefusedError as error:
            conn_port += 1

        # 1. Wait for initialization command
        # msg, address = s.recvfrom(BUFFSIZE)
        # msg = msg.decode()
        # print("Received message: ".format(msg))
        # while msg != INIT_MSG:
        #     print("\tWait for initialization")
        #     time.sleep(100)
        # print("Asked for initialization {}".format(msg))

        print("Run initialization...")
        return_init = initialization()
            
        if return_init:
            print("Sending init ok")
            s.send(INIT_OK.encode())

            print("Waiting for starting command")
            measurement_cnt = 0
            msg, address = s.recvfrom(BUFFSIZE)
            msg = msg.decode().strip()

            # while msg != STOP_ACQUISITION and msg == START_ACQUISITION:
            while True:
                print("Asking for measurement number {}".format(measurement_cnt))
                command_start_acquisition()
                data_acquisition_result = wait_data_acquisition()
                if data_acquisition_result:
                    time.sleep(1)
                    # send message OK
                    print("Measurement number {} OK - Sending msg {} to central node".format(measurement_cnt, DATA_ACQUISITION_OK))
                    measurement_cnt += 1
                    s.send(DATA_ACQUISITION_OK.encode())

                    print("Waiting for new command")
                    msg, address = s.recvfrom(BUFFSIZE)
                    msg = msg.decode().strip()
                    
                    
                else:
                    print("Measurement number {} NO OK - Sending msg {} to central node".format(measurement_cnt, DATA_ACQUISITION_FAIL))
                    s.send(DATA_ACQUISITION_FAIL.encode())
                    raise Exception("Error in Data Acquisition")

            if msg == STOP_ACQUISITION:
                print("Acquisition completed exit")
                with open(COMMAND_FILE_PATH, 'w') as command_file:
                    print("Sending command for data acquisition")
                    command_file.write(STOP_ACQUISITION)
                exit(1)
                    
        else:
            s.send(INIT_FAIL.encode())

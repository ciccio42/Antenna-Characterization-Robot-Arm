#! /usr/bin/env python3
import socket
from utils import *


if __name__ == '__main__':
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        print(f"Socket listening for a new connection")
        s.bind(('', PORT))
        
        s.listen()
        conn, addr = s.accept()
        print(f"Connected from {addr}")
        with conn:
            if str(addr[0]) == PC_VNA_ADDRESS:
                print("Connected from PC_VNA")
                
                # 1. RUN INITIALIZATION
                conn.send(INIT_MSG.encode())
                
                # 2. Wait for end initialization
                msg = conn.recv(BUFFSIZE)
                msg = msg.decode()
                print(f"Received message {msg}")
                
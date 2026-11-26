#!/usr/bin/env python3
"""
SSH Brute-Force Attack Simulation Script
Case Study 2 - Innovatech Solutions (Medium Stake 2)
Simuleert 4 mislukte inlogpogingen vanaf de attacker node (192.168.56.30)
naar workstation-01 (192.168.56.10) om het SOAR mitigatieplaybook te triggeren.
"""
import subprocess
import time
import sys

TARGET = "192.168.56.10"
print(f"[*] Starting SSH brute-force attack simulation against {TARGET}...")

for i in range(1, 5):
    print(f"[{i}/4] Sending failed SSH login attempt to {TARGET}...")
    subprocess.run(
        ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "BatchMode=yes", "-o", "ConnectTimeout=2", f"fakehacker{i}@{TARGET}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    time.sleep(0.3)

print("[*] Finished sending brute-force attempts. SOAR webhook should trigger DROP rule now.")

import os
import subprocess

def main(mytimer):
    rg = os.getenv("RG_NAME")
    vmss = os.getenv("VMSS_NAME")

    if not rg or not vmss:
        raise Exception("Missing RG_NAME or VMSS_NAME environment variables")

    subprocess.run(["az", "login", "--identity"])
    subprocess.run(["az", "vmss", "deallocate", "--resource-group", rg, "--name", vmss])

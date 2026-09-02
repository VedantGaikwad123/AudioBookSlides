"""
CUDA and GPU Detection Utility for AudioBookSlides
Determines GPU presence, CUDA driver capability, and PyTorch CUDA compatibility.
"""

import sys
import os
import subprocess
import json

def get_gpu_wmi():
    """Detect GPU hardware name via Windows WMI/CIM query."""
    try:
        cmd = ["powershell", "-NoProfile", "-Command", 
               "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name"]
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        gpus = [line.strip() for line in res.stdout.splitlines() if line.strip()]
        return gpus
    except Exception:
        return []

def get_nvidia_smi_info():
    """Query nvidia-smi for driver version and GPU details."""
    try:
        cmd = ["nvidia-smi", "--query-gpu=name,driver_version,memory.total", "--format=csv,noheader,nounits"]
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        lines = [line.strip() for line in res.stdout.splitlines() if line.strip()]
        if lines:
            parts = [p.strip() for p in lines[0].split(",")]
            return {
                "name": parts[0] if len(parts) > 0 else "Unknown",
                "driver": parts[1] if len(parts) > 1 else "Unknown",
                "vram_mb": int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
            }
    except Exception:
        pass
    return None

def check_torch_cuda():
    """Check PyTorch CUDA availability and version."""
    try:
        import torch
        cuda_available = torch.cuda.is_available()
        cuda_version = torch.version.cuda
        device_count = torch.cuda.device_count() if cuda_available else 0
        device_name = torch.cuda.get_device_name(0) if cuda_available and device_count > 0 else None
        
        return {
            "torch_installed": True,
            "torch_version": torch.__version__,
            "cuda_available": cuda_available,
            "torch_cuda_version": cuda_version,
            "device_count": device_count,
            "torch_device_name": device_name
        }
    except ImportError:
        return {
            "torch_installed": False,
            "torch_version": None,
            "cuda_available": False,
            "torch_cuda_version": None,
            "device_count": 0,
            "torch_device_name": None
        }

def main():
    as_json = "--json" in sys.argv
    quiet = "--quiet" in sys.argv

    wmi_gpus = get_gpu_wmi()
    smi_info = get_nvidia_smi_info()
    torch_info = check_torch_cuda()

    has_nvidia = False
    gpu_name = "None detected"

    if smi_info:
        has_nvidia = True
        gpu_name = smi_info["name"]
    else:
        for g in wmi_gpus:
            if "NVIDIA" in g.upper() or "GEFORCE" in g.upper() or "RTX" in g.upper() or "GTX" in g.upper() or "QUADRO" in g.upper():
                has_nvidia = True
                gpu_name = g
                break

    report = {
        "nvidia_gpu_detected": has_nvidia,
        "gpu_name": gpu_name,
        "driver_version": smi_info.get("driver") if smi_info else None,
        "vram_mb": smi_info.get("vram_mb") if smi_info else None,
        "torch": torch_info,
        "recommendation": "cuda" if has_nvidia else "cpu"
    }

    if as_json:
        print(json.dumps(report, indent=2))
    elif not quiet:
        print("========================================")
        print(" GPU & CUDA Diagnostics")
        print("========================================")
        print(f"NVIDIA GPU Detected : {'Yes' if has_nvidia else 'No'}")
        print(f"GPU Model           : {gpu_name}")
        if smi_info and smi_info.get("driver"):
            print(f"NVIDIA Driver       : {smi_info['driver']}")
        if smi_info and smi_info.get("vram_mb"):
            print(f"VRAM                : {smi_info['vram_mb']} MB (~{round(smi_info['vram_mb']/1024, 1)} GB)")
        
        print("\n--- PyTorch Runtime Status ---")
        if torch_info["torch_installed"]:
            print(f"PyTorch Version     : {torch_info['torch_version']}")
            print(f"CUDA Available (PyTorch) : {'Yes' if torch_info['cuda_available'] else 'No'}")
            if torch_info["torch_cuda_version"]:
                print(f"PyTorch CUDA Build  : {torch_info['torch_cuda_version']}")
            if torch_info["torch_device_name"]:
                print(f"Active CUDA Device  : {torch_info['torch_device_name']}")
        else:
            print("PyTorch is not yet installed in this environment.")
        
        print("========================================")
        print(f"Recommended Target  : {report['recommendation'].upper()}")
        print("========================================")

    # Return exit code: 0 if NVIDIA detected, 1 if CPU only
    sys.exit(0 if has_nvidia else 1)

if __name__ == "__main__":
    main()

"""
Environment and Installation Verification Script for AudioBookSlides
Validates Python, packages, GPU, FFmpeg, and core assets.
"""

import sys
import os
import shutil
import importlib.util
import subprocess

def check_python_version():
    major, minor, micro = sys.version_info[:3]
    version_str = f"{major}.{minor}.{micro}"
    # Target 3.9 - 3.11 (3.12 is accepted with warning due to whisperx/torch ecosystem)
    is_ok = (major == 3 and 9 <= minor <= 11)
    warning = "" if is_ok else " (Warning: 3.9-3.11 recommended for WhisperX & CUDA)"
    return is_ok, f"{version_str}{warning}"

def check_module(module_name, import_name=None):
    name_to_check = import_name or module_name
    spec = importlib.util.find_spec(name_to_check)
    if spec is None:
        return False, "Missing"
    try:
        mod = __import__(name_to_check)
        ver = getattr(mod, "__version__", "Installed")
        return True, str(ver)
    except Exception as e:
        return False, f"Error: {e}"

def check_ffmpeg():
    # Check system PATH or local tools\ffmpeg\bin
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    local_ffmpeg = os.path.join(base_dir, "tools", "ffmpeg", "bin")
    if os.path.isdir(local_ffmpeg) and local_ffmpeg not in os.environ.get("PATH", ""):
        os.environ["PATH"] = local_ffmpeg + os.pathsep + os.environ.get("PATH", "")
        
    ffmpeg_path = shutil.which("ffmpeg")
    if not ffmpeg_path:
        return False, "Not found on PATH or in tools/ffmpeg/bin"
    try:
        res = subprocess.run(["ffmpeg", "-version"], capture_output=True, text=True, check=True)
        first_line = res.stdout.splitlines()[0] if res.stdout else "Found"
        return True, first_line.split(" Copyright")[0]
    except Exception:
        return False, "Execution failed"

def check_comfyui():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    comfy_dir = os.path.join(base_dir, "ComfyUI")
    if not os.path.exists(comfy_dir):
        # Check parent directory as well
        parent_comfy = os.path.join(os.path.dirname(base_dir), "ComfyUI")
        if os.path.exists(parent_comfy):
            return True, f"Found in parent dir: {parent_comfy}"
        return False, "Not found (Optional: required for ComfyUI image generation)"
    
    # Check custom node presence
    custom_nodes_dir = os.path.join(comfy_dir, "custom_nodes")
    manager_exists = os.path.exists(os.path.join(custom_nodes_dir, "ComfyUI-Manager"))
    sampler_exists = os.path.exists(os.path.join(comfy_dir, "comfy_extras", "nodes_custom_sampler.py"))
    
    status_detail = []
    if manager_exists: status_detail.append("Manager")
    if sampler_exists: status_detail.append("CustomSampler")
    detail_str = f" ({', '.join(status_detail)})" if status_detail else ""
    return True, f"Found: {comfy_dir}{detail_str}"

def check_application_files():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    critical_files = [
        os.path.join(base_dir, "abs.py"),
        os.path.join(base_dir, "default_config.yaml"),
        os.path.join(base_dir, "actors", "female.csv"),
        os.path.join(base_dir, "actors", "male.csv"),
        os.path.join(base_dir, "tokenizer_vocab_2.txt")
    ]
    missing = [f for f in critical_files if not os.path.exists(f)]
    if missing:
        return False, f"Missing {len(missing)} file(s)"
    return True, "All critical assets present"

def main():
    print("========================================")
    print(" Installation Verification")
    print("========================================")

    all_passed = True

    # 1. Python
    py_ok, py_ver = check_python_version()
    print(f"Python:       {'OK' if py_ok else 'WARN'} ({py_ver})")
    if not py_ok:
        pass # Warning only

    # 2. Package Managers
    pip_ok, pip_ver = check_module("pip")
    print(f"pip:          {'OK' if pip_ok else 'FAIL'} ({pip_ver})")
    if not pip_ok:
        all_passed = False

    uv_path = shutil.which("uv")
    uv_ok = bool(uv_path)
    print(f"uv:           {'OK' if uv_ok else 'WARN'} ({'Found: ' + uv_path if uv_ok else 'Not in PATH'})")

    # 3. Dependencies
    required_pkgs = [
        ("opencv-python", "cv2"),
        ("openai", "openai"),
        ("pyyaml", "yaml"),
        ("joblib", "joblib"),
        ("tqdm", "tqdm")
    ]
    
    deps_ok = True
    for pkg_name, import_name in required_pkgs:
        ok, ver = check_module(pkg_name, import_name)
        if not ok:
            deps_ok = False
            print(f"  - {pkg_name}: FAIL ({ver})")
    print(f"Dependencies: {'OK' if deps_ok else 'FAIL'}")
    if not deps_ok:
        all_passed = False

    # 4. PyTorch & CUDA
    torch_ok, torch_ver = check_module("torch")
    if torch_ok:
        import torch
        cuda_avail = torch.cuda.is_available()
        cuda_dev = torch.cuda.get_device_name(0) if cuda_avail else "CPU Mode"
        print(f"PyTorch:      OK (v{torch_ver})")
        print(f"CUDA (Torch): {'OK' if cuda_avail else 'INFO'} ({cuda_dev})")
    else:
        print(f"PyTorch:      FAIL ({torch_ver})")
        print("CUDA (Torch): N/A")
        all_passed = False

    # 5. FFmpeg
    ff_ok, ff_info = check_ffmpeg()
    print(f"FFmpeg:       {'OK' if ff_ok else 'WARN'} ({ff_info})")
    if not ff_ok:
        print("  Note: ffmpeg is required to concatenate audio and generate final videos.")

    # 6. ComfyUI
    comfy_ok, comfy_info = check_comfyui()
    print(f"ComfyUI:      {'OK' if comfy_ok else 'INFO'} ({comfy_info})")

    # 7. Application Files
    app_ok, app_info = check_application_files()
    print(f"Application:  {'OK' if app_ok else 'FAIL'} ({app_info})")
    if not app_ok:
        all_passed = False

    print("========================================")
    if all_passed:
        print("Installation completed successfully.")
        sys.exit(0)
    else:
        print("ERROR: One or more critical verification checks failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()

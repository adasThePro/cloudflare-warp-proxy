import re
import sys
import os
from urllib.request import urlopen, Request

VERSION_FILE = ".warp_version"

def get_latest_warp_info():
    try:
        url = "https://pkg.cloudflareclient.com/dists/jammy/main/binary-amd64/Packages"
        
        req = Request(url, headers={
            "User-Agent": "Mozilla/5.0 (compatible; WARP-Version-Checker/1.0)"
        })
        
        with urlopen(req, timeout=30) as response:
            page_content = response.read().decode("utf-8")

        sha256_match = re.search(r"SHA256:\s*([a-f0-9]{64})", page_content)
        version_match = re.search(r"Version:\s*([\S]+)", page_content)
                
        if sha256_match:
            info = {
                "version": version_match.group(1).strip() if version_match else "unknown",
                "sha256": sha256_match.group(1).strip()
            }
            return info
        else:
            return None
    except Exception as _:
        return None

def get_saved_hash():
    if not os.path.exists(VERSION_FILE):
        return None
    
    try:
        with open(VERSION_FILE, "r") as f:
            content = f.read().strip()
            saved_version, saved_hash = content.split(":", 1)
            return {"version": saved_version.strip(), "sha256": saved_hash.strip()}
    except Exception:
        return None

def save_hash(info):
    try:
        with open(VERSION_FILE, "w") as f:
            f.write(f"{info['version']}:{info['sha256']}")
        return True
    except Exception as _:
        return False

def check_new_version():
    latest_info = get_latest_warp_info()
    if latest_info is None:
        return None
    
    saved_info = get_saved_hash()
    
    if saved_info is None:
        save_hash(latest_info)
        return latest_info

    if latest_info["sha256"] != saved_info["sha256"]:
        save_hash(latest_info)
        return latest_info
    else:
        return None

def main():
    try:
        result = check_new_version()
        
        if result:
            print(f"{result['version']}:{result['sha256']}")
            sys.exit(0)
        else:
            sys.exit(1)
    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        sys.exit(3)

if __name__ == "__main__":
    main()
"""
WARP Version Checker

A utility to monitor Cloudflare WARP package updates by tracking SHA256 hashes
from the official package repository.
"""

import os
import re
import sys
from typing import Optional, Dict
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen

# Constants
VERSION_FILE = ".warp_version"
PACKAGE_URL = "https://pkg.cloudflareclient.com/dists/jammy/main/binary-amd64/Packages"
USER_AGENT = "Mozilla/5.0 (compatible; WARP-Version-Checker/1.0)"
REQUEST_TIMEOUT = 30

# Exit codes
EXIT_SUCCESS = 0
EXIT_NO_UPDATE = 1
EXIT_FATAL_ERROR = 3


class WARPVersionChecker:

    def __init__(self, version_file: str = VERSION_FILE):
        self.version_file = version_file

    def fetch_latest_package_info(self) -> Optional[Dict[str, str]]:
        try:
            request = Request(PACKAGE_URL, headers={"User-Agent": USER_AGENT})
            
            with urlopen(request, timeout=REQUEST_TIMEOUT) as response:
                content = response.read().decode("utf-8")

            return self._parse_package_info(content)

        except (URLError, HTTPError, TimeoutError) as e:
            print(f"Network error fetching package info: {e}", file=sys.stderr)
            return None
        except Exception as e:
            print(f"Unexpected error fetching package info: {e}", file=sys.stderr)
            return None

    @staticmethod
    def _parse_package_info(content: str) -> Optional[Dict[str, str]]:
        sha256_match = re.search(r"SHA256:\s*([a-f0-9]{64})", content)
        version_match = re.search(r"Version:\s*([\S]+)", content)

        if not sha256_match:
            return None

        return {
            "version": version_match.group(1).strip() if version_match else "unknown",
            "sha256": sha256_match.group(1).strip()
        }

    def load_saved_info(self) -> Optional[Dict[str, str]]:
        if not os.path.exists(self.version_file):
            return None

        try:
            with open(self.version_file, "r", encoding="utf-8") as f:
                content = f.read().strip()

            if ":" not in content:
                return None

            version, sha256_hash = content.split(":", 1)
            return {"version": version.strip(), "sha256": sha256_hash.strip()}

        except (IOError, ValueError) as e:
            print(f"Error reading version file: {e}", file=sys.stderr)
            return None

    def save_info(self, info: Dict[str, str]) -> bool:
        try:
            with open(self.version_file, "w", encoding="utf-8") as f:
                f.write(f"{info['version']}:{info['sha256']}")
            return True

        except IOError as e:
            print(f"Error saving version file: {e}", file=sys.stderr)
            return False

    def check_for_update(self) -> Optional[Dict[str, str]]:
        latest_info = self.fetch_latest_package_info()
        if latest_info is None:
            return None

        saved_info = self.load_saved_info()

        if saved_info is None:
            self.save_info(latest_info)
            return latest_info

        if latest_info["sha256"] != saved_info["sha256"]:
            self.save_info(latest_info)
            return latest_info

        return None


def main() -> None:
    try:
        checker = WARPVersionChecker()
        update_info = checker.check_for_update()

        if update_info:
            print(f"{update_info['version']}:{update_info['sha256']}")
            sys.exit(EXIT_SUCCESS)
        else:
            sys.exit(EXIT_NO_UPDATE)

    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        sys.exit(EXIT_FATAL_ERROR)


if __name__ == "__main__":
    main()
"""Entry point for python -m jinli_workflow.

Usage:
    python -m jinli_workflow [--role planner|implementer|verifier]
"""

import sys
import os

# Ensure the package is importable
_package_dir = os.path.dirname(os.path.abspath(__file__))
_parent = os.path.dirname(_package_dir)
if _parent not in sys.path:
    sys.path.insert(0, _parent)

from jinli_workflow.server import main

if __name__ == "__main__":
    main()

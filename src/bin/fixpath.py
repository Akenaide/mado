import sys
import os

print("\n".join(sys.path))
sys.path.append(os.path.abspath(os.path.dirname(__name__)))

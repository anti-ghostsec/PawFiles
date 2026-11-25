# Prints "x y", the middle of the first node in a uiautomator dump whose
# text is exactly the one given (used by ui-check.sh).
import re
import sys
import xml.etree.ElementTree as ET

dump, text = sys.argv[1], sys.argv[2]
for node in ET.parse(dump).iter("node"):
    if node.get("text") == text:
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
sys.exit(f"ui-find: nothing on screen says {text!r}")

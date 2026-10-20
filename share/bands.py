"""Split img2sixel output into lines: DCS intro, palette, then one sixel band (6px row) per line.

mdview slices these lines to scroll without re-encoding the image.
"""
import re
import sys

data = sys.stdin.buffer.read()
m = re.match(rb'(\x1bP[\d;]*q)("[\d;]*)?((?:#\d+;\d+;\d+;\d+;\d+)*)', data)
body = data[m.end():]
if body.endswith(b'\x1b\\'):
    body = body[:-2]
out = sys.stdout.buffer
out.write(m.group(1) + b'\n' + m.group(3) + b'\n')
out.write(body.replace(b'\n', b'').replace(b'-', b'\n') + b'\n')

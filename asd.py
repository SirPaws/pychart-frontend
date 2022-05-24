from pathlib import Path
contents = Path('test.txt').read_text()
print(contents)

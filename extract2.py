with open('lib/core/services/pdf_generator_service.dart', 'rb') as f:
    lines = f.readlines()

in_func = False
for i, line in enumerate(lines):
    text = line.decode('utf-8', errors='replace')
    if 'List<pw.Page> _buildPhotosPage' in text:
        in_func = True
    if in_func:
        print(f"{i+1}: {text.strip()}")
        if 'return pages' in text:
            break

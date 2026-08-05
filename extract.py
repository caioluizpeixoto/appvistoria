with open('lib/core/services/pdf_generator_service.dart', 'rb') as f:
    lines = f.readlines()

in_func = False
for i, line in enumerate(lines):
    text = line.decode('utf-8', errors='replace')
    if '_buildPage1Modern' in text:
        in_func = True
    if in_func:
        print(f"{i+1}: {text.strip()}")
        if 'return pw.Page' in text:
            for j in range(i+1, i+250):
                if j < len(lines):
                    print(f"{j+1}: {lines[j].decode('utf-8', errors='replace').strip()}")
            break

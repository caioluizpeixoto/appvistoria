import re

with open('lib/core/services/pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '<svg viewBox=\"0 0 24 24\"><path fill=\"white\" d=\"M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z\"/></svg>',
    '<svg viewBox=\"0 0 24 24\"><path fill=\"#8CC63F\" d=\"M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z\"/></svg>'
)

content = content.replace(
    '<svg viewBox=\"0 0 24 24\"><path fill=\"white\" d=\"M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z\"/></svg>',
    '<svg viewBox=\"0 0 24 24\"><path fill=\"#FBB03B\" d=\"M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z\"/></svg>'
)

content = content.replace(
    '<svg viewBox=\"0 0 24 24\"><path fill=\"white\" d=\"M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z\"/></svg>',
    '<svg viewBox=\"0 0 24 24\"><path fill=\"#EE4036\" d=\"M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z\"/></svg>'
)

content = re.sub(
    r'pw\.Container\(\s*width:\s*\d+,\s*height:\s*\d+,\s*decoration:\s*pw\.BoxDecoration\(\s*(?:color:\s*[^,]+,\s*)?shape:\s*pw\.BoxShape\.circle(?:,\s*color:\s*[^,]+)?\),\s*child:\s*pw\.Center\(\s*child:\s*(pw\.SvgImage\([^)]+\))\)\)',
    r'\1',
    content
)

with open('lib/core/services/pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')

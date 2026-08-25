import re

with open('lib/core/services/pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Restore fill="white" for statusIcon in _buildFichaTecnica
# Lines around 1960:
content = re.sub(
    r'(PdfColor statusColor = limeGreen;\s*String statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M9 16\.2L4\.8 12l-1\.4 1\.4L9 19 21 7l-1\.4-1\.4L9 16\.2z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = dangerRed;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M19 6\.41L17\.59 5 12 10\.59 6\.41 5 5 6\.41 10\.59 12 5 17\.59 6\.41 19 12 13\.41 17\.59 19 19 17\.59 13\.41 12 19 6\.41z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = warningYellow;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = limeGreen;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M9 16\.2L4\.8 12l-1\.4 1\.4L9 19 21 7l-1\.4-1\.4L9 16\.2z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)

# 2. Restore fill="white" for statusIcon in _buildGroupResumo
# Lines around 3160:
content = re.sub(
    r'(PdfColor statusColor = warningYellow;\s*String statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = dangerRed;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M19 6\.41L17\.59 5 12 10\.59 6\.41 5 5 6\.41 10\.59 12 5 17\.59 6\.41 19 12 13\.41 17\.59 19 19 17\.59 13\.41 12 19 6\.41z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = warningYellow;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=1
)
content = re.sub(
    r'(statusColor = limeGreen;\s*statusIcon =\s*\'<svg viewBox="0 0 24 24"><path fill=")[^"]+(" d="M9 16\.2L4\.8 12l-1\.4 1\.4L9 19 21 7l-1\.4-1\.4L9 16\.2z"/></svg>\';)',
    r'\g<1>white\g<2>',
    content, count=2 # It appears twice at the end of the if-else block
)

# 3. Restore circle container in Header Parecer (around line 2635)
header_parecer = '''                              pw.Container(
                                width: 42,
                                height: 42,
                                decoration: pw.BoxDecoration(
                                  color: statusColor,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(
                                  child: pw.SvgImage(
                                    svg: statusIcon,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),'''
# The current code is:
#                              pw.SvgImage(
#                                svg: statusIcon,
#                                width: 24,
#                                height: 24,
#                              ),
content = content.replace(
    '                              pw.SvgImage(\n                                svg: statusIcon,\n                                width: 24,\n                                height: 24,\n                              ),',
    header_parecer
)

# 4. Restore circle container in Group Resumo Parecer (around line 3368)
group_parecer = '''                            pw.Container(
                              width: 44,
                              height: 44,
                              decoration: pw.BoxDecoration(
                                  color: statusColor,
                                  shape: pw.BoxShape.circle),
                              child: pw.Center(
                                  child: pw.SvgImage(
                                      svg: statusIcon, width: 24, height: 24)),
                            ),'''
# The current code is:
#                            pw.SvgImage(
#                                svg: statusIcon, width: 32, height: 32),
content = content.replace(
    '                            pw.SvgImage(\n                                svg: statusIcon, width: 32, height: 32),',
    group_parecer
)

with open('lib/core/services/pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')

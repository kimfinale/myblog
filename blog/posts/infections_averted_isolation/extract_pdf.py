import pypdf

reader = pypdf.PdfReader('C:\\Users\\jonghoon.kim\\Workspace\\Antigravity\\individual_collective_compliance\\Roberts et al. - 2023 - Quantifying the impact of individual and collective compliance with infection control measures for e.pdf')
text = '\n'.join(page.extract_text() for page in reader.pages)
with open('temp_pdf.txt', 'w', encoding='utf-8') as f:
    f.write(text)

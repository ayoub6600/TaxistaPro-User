#!/usr/bin/env python3
"""Inline src/ into (1) index.html, a standalone page, and (2) taxista-rider-prototype.html, the Artifact fragment
(no doctype/html/head/body: the Artifact host adds those). Images from src/img become data URIs in IMG."""
import base64, json, pathlib, re
here = pathlib.Path(__file__).resolve().parent
src = here / 'src'
imgs = {}
for f in sorted((src / 'img').iterdir()):
    mime = 'image/jpeg' if f.suffix == '.jpg' else 'image/png'
    imgs[f.stem] = f'data:{mime};base64,' + base64.b64encode(f.read_bytes()).decode()
order = ['core.js', 'data.js', 'screens_home.js', 'screens_trip.js', 'screens_future.js', 'screens_account.js', 'screens_review.js', 'main.js']
js = 'const IMG = ' + json.dumps(imgs) + ';\n' + '\n'.join((src / f).read_text(encoding='utf-8') for f in order)
shell = (src / 'shell.html').read_text(encoding='utf-8')
frag = shell[shell.index('<!--FRAGMENT-START-->') + len('<!--FRAGMENT-START-->'): shell.index('<!--FRAGMENT-END-->')].strip()
frag = frag.replace('/*__CSS__*/', (src / 'styles.css').read_text(encoding='utf-8'))
frag = frag.replace('/*__JS__*/', js.replace('</script>', '<\\/script>'))
frag = frag.replace('__LOGO__', imgs['logo'])
(here / 'taxista-rider-prototype.html').write_text(frag + '\n', encoding='utf-8')
title = re.search(r'<title>.*?</title>', frag).group(0)
body = frag.replace(title, '')
full = ('<!doctype html>\n<html lang="ar" dir="rtl">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
        '<meta name="apple-mobile-web-app-capable" content="yes">\n' + title +
        '\n<style>[hidden]{display:none!important}</style>\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
(here / 'index.html').write_text(full, encoding='utf-8')
for n in ('index.html', 'taxista-rider-prototype.html'):
    print(n, round((here / n).stat().st_size / 1024), 'KB')

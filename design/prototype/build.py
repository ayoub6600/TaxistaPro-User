#!/usr/bin/env python3
"""Inline src/ into a single self-contained index.html (logo + mascot as data URIs)."""
import base64, pathlib
here = pathlib.Path(__file__).resolve().parent
src = here / 'src'
img = lambda p: 'data:image/png;base64,' + base64.b64encode((src / p).read_bytes()).decode()
order = ['core.js', 'data.js', 'screens_home.js', 'screens_trip.js', 'screens_future.js', 'screens_account.js', 'screens_review.js', 'main.js']
js = '\n'.join((src / f).read_text(encoding='utf-8') for f in order)
html = (src / 'shell.html').read_text(encoding='utf-8')
html = html.replace('/*__CSS__*/', (src / 'styles.css').read_text(encoding='utf-8'))
html = html.replace('/*__JS__*/', js.replace('</script>', '<\\/script>'))
html = html.replace('__LOGO__', img('logo.png')).replace('__MASCOT__', img('mascot.png'))
out = here / 'index.html'
out.write_text(html, encoding='utf-8')
print(out, round(out.stat().st_size / 1024), 'KB')

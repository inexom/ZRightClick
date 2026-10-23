"""Check bundled blank OOXML templates without requiring Office or third-party libraries."""
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
import posixpath

folder = Path(__file__).resolve().parents[1] / 'ZRightClickApp' / 'Templates'
expected = {
    'docx': ('word/document.xml', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main', 't'),
    'xlsx': ('xl/workbook.xml', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main', 'sheet'),
    'pptx': ('ppt/presentation.xml', 'http://schemas.openxmlformats.org/presentationml/2006/main', 'sldId'),
}
for suffix, (main_part, ns, child) in expected.items():
    with ZipFile(folder / f'Blank.{suffix}') as archive:
        names = set(archive.namelist())
        assert archive.testzip() is None
        assert {'[Content_Types].xml', '_rels/.rels', main_part} <= names
        for name in names:
            assert 'vbaproject' not in name.lower()
            if not name.endswith(('.xml', '.rels')):
                continue
            root = ET.fromstring(archive.read(name))
            if name.endswith('.rels'):
                base = '' if name == '_rels/.rels' else posixpath.dirname(posixpath.dirname(name))
                for relation in root:
                    assert relation.get('TargetMode') != 'External', (suffix, name)
                    target = relation.get('Target', '')
                    resolved = posixpath.normpath(posixpath.join(base, target)) if not target.startswith('/') else target.lstrip('/')
                    assert resolved in names, (suffix, name, resolved)
        root = ET.fromstring(archive.read(main_part))
        children = root.findall(f'.//{{{ns}}}{child}')
        if suffix == 'docx':
            assert not any(element.text for element in children)
        else:
            assert len(children) == 1, suffix
        if suffix == 'xlsx':
            sheet = ET.fromstring(archive.read('xl/worksheets/sheet1.xml'))
            assert not sheet.findall(f'.//{{{ns}}}c')
        if suffix == 'pptx':
            slide = ET.fromstring(archive.read('ppt/slides/slide1.xml'))
            assert not slide.findall(f'.//{{{ns}}}sp')
print('Office templates passed: package relationships, blank content, no macros or external links')

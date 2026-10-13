# Translating AppManager

## Dependencies

Install the required tools before working with translations:

```bash
# Debian / Ubuntu
sudo apt install gettext itstool python3

# Fedora
sudo dnf install gettext itstool python3
```

## Quick Start: Using the Translation Script

The script at `scripts/translations.sh` helps you add or update translations
without needing to touch `.po` files directly.

### 1. Export untranslated strings

This generates a YAML file with all strings that still need translating:

```bash
./scripts/translations.sh --export lv      # → po/lv.yaml
```

Only untranslated strings are exported. Strings marked fuzzy (an older translation that needs review) are not, so fix those directly in the `.po` file.

### 2. Translate

Open the generated YAML file and fill in the `msgstr` fields:

```yaml
entries:
  - msgid: "Keep Both"
    msgstr: "Paturēt abus"
    locations: "src/application.vala:508, src/windows/drop_window.vala:460"
  - msgid: "Ignore"
    msgstr: "Ignorēt"
    locations: "src/application.vala:766"
```

### 3. Import translations

This validates the `.po` file, merges your translations, and validates again:

```bash
./scripts/translations.sh --import lv      # reads po/lv.yaml → po/lv.po
```

### 4. Submit

Commit your updated `.po` file and open a pull request.

> **Tip:** If the script reports errors during import, run `./scripts/translations.sh --fix`
> first, then try importing again. It regenerates the template, merges it into every `.po`
> file and marks broken entries as fuzzy.
>
> `./scripts/translations.sh --check-only` validates all `.po` files without changing anything
> and prints the statistics below.

### Adding a new language

To start a translation for a language that doesn't exist yet:

1. Add the language code to `po/LINGUAS` (e.g. `fr`)
2. Run `./scripts/translations.sh`. It creates the new `.po` from the template
3. Then use `--export` / `--import` as described above
4. Optionally translate the launcher's `GenericName`, `Comment` and `Keywords` by adding `[code]` lines to `data/app-manager.desktop.in`, and add the language name to `LANG_NAMES` in the script

## Translation Status

Counted with `./scripts/translations.sh --check-only` on 2026-10-05, out of 464 strings.

| Language | Code | Translated | Fuzzy |
| -------- | ---- | ---------- | ----- |
| Arabic | ar | 61.9% (287) | 9 |
| German | de | 61.9% (287) | 9 |
| Greek | el | 61.9% (287) | 9 |
| Spanish | es | 78.2% (363) | 0 |
| Estonian | et | 61.9% (287) | 9 |
| Finnish | fi | 61.9% (287) | 9 |
| French | fr | 78.2% (363) | 0 |
| Irish | ga | 62.3% (289) | 8 |
| Italian | it | 61.9% (287) | 9 |
| Japanese | ja | 61.9% (287) | 9 |
| Kazakh | kk | 61.9% (287) | 9 |
| Korean | ko | 61.9% (287) | 9 |
| Lithuanian | lt | 61.9% (287) | 9 |
| Latvian | lv | 71.1% (330) | 9 |
| Norwegian Bokmål | nb | 61.9% (287) | 9 |
| Dutch | nl | 61.9% (287) | 9 |
| Polish | pl | 66.6% (309) | 0 |
| Portuguese (Brazil) | pt_BR | 61.9% (287) | 9 |
| Swedish | sv | 61.9% (287) | 9 |
| Ukrainian | uk | 62.1% (288) | 8 |
| Vietnamese | vi | 61.9% (287) | 9 |
| Chinese (Simplified) | zh_CN | 61.9% (287) | 9 |

## Note

> Some translations are machine-generated and may contain mistakes. Native speakers are welcome to review and improve them!

## Testing Translations Locally

After building with meson, translations are compiled automatically. To test:

```bash
meson setup build --prefix=$HOME/.local
meson compile -C build
meson install -C build
```

Then run the app with a specific locale:

```bash
LANGUAGE=de app-manager
```

## Further Reading

- [GNU gettext Manual](https://www.gnu.org/software/gettext/manual/gettext.html)
- [Meson i18n module](https://mesonbuild.com/i18n-module.html)

# Zenodo Archiving — atcddd

This folder contains files for archiving the `atcddd` R package on
[Zenodo](https://zenodo.org) to obtain a DOI (Digital Object Identifier)
for academic citation.

## How to Archive on Zenodo

### Method 1: Automatic (via GitHub — Recommended)

1. **Create a release on GitHub**
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```
   Then go to https://github.com/vanhungtran/atcddd/releases/new
   and create a release from the tag.

2. **Link Zenodo to GitHub**
   - Go to https://zenodo.org/github/
   - Log in with your GitHub account
   - Toggle the `atcddd` repository to ON
   - Zenodo will automatically archive every new release

3. **Your first archive creates the DOI**
   - Zenodo will create a DOI like `10.5281/zenodo.XXXXXXX`
   - Update the badge in `README.md` with the real DOI
   - Update `CITATION.cff` with the real DOI

### Method 2: Manual Upload

1. Create a tar.gz of the package:
   ```bash
   R CMD build .
   # Creates atcddd_0.2.0.tar.gz
   ```

2. Go to https://zenodo.org/deposit/new
3. Upload the `.tar.gz` file
4. Fill in metadata (use `.zenodo.json` as reference)
5. Click "Publish"

## Files

| File | Purpose |
|------|---------|
| `.zenodo.json` | Zenodo metadata (auto-detected at repo root) |
| `.zenodo.json` (here) | Reference copy |
| `../CITATION.cff` | CFF citation file (GitHub-native) |
| `../inst/CITATION` | R package citation file |

## After Archiving

1. Paste the DOI into `README.md` badge: `[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXX)`
2. Update `CITATION.cff` with the DOI
3. Update `inst/CITATION` with the DOI

## Notes

- Zenodo archives are **immutable** — once published, the version is frozen
- Each new GitHub release creates a **new version** with a **new DOI**
- A **concept DOI** covers all versions (use this in publications)
- The WHO ATC/DDD data is freely redistributable for non-commercial research

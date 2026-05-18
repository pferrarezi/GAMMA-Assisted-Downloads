# GAMMA Assisted Downloads

Small PowerShell helper for completing S.T.A.L.K.E.R. GAMMA downloads when the
Grok's Modpack Installer cannot fetch ModDB files because of Cloudflare or other
browser-only checks.

The script reads GAMMA's `mods.txt`, opens each missing download in your normal
browser session, waits for the completed file to appear in your browser download
folder, then moves it into GAMMA's `downloads` folder using the exact filename
expected by the installer.

## Paths

Default inputs:

- Mods list: `C:\GAMMA\.Grok's Modpack Installer\mods.txt`
- Browser downloads: `C:\Users\p_fer\Downloads`
- GAMMA downloads: `C:\GAMMA\downloads`

## Dry Run

Preview the next missing downloads without opening the browser:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -DryRun -Limit 10
```

## Download a Batch

Open and process the next 20 missing files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -Limit 20
```

If the direct `addons/start/...` URL does not start the download, open the mod
page instead:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -UseModPage -Limit 20
```

## Useful Options

- `-Limit 20`: process only a small batch.
- `-StartAt 21`: skip the first 20 queued missing files.
- `-UseModPage`: open the public mod page instead of the direct start URL.
- `-BrowserDownloadsDir "D:\Downloads"`: use a different browser download folder.
- `-DownloadsDir "C:\GAMMA\downloads"`: use a different GAMMA downloads folder.
- `-NoHash`: skip MD5 validation and accept stable completed files.
- `-All`: process entries even if the expected file already exists.

## Interactive Keys

While waiting for a file:

- `R`: reopen the current download URL.
- `P`: open the mod page.
- `S`: skip the current file.
- `Q`: quit.

## Notes

Run in small batches to avoid triggering additional rate limits. After the files
are present in `C:\GAMMA\downloads`, rerun the GAMMA installer so it can extract
and install the mods normally.


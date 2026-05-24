# GAMMA Assisted Downloads

Small PowerShell helper for completing S.T.A.L.K.E.R. GAMMA downloads when the
Grok's Modpack Installer cannot fetch ModDB files because of Cloudflare or other
browser-only checks.

The script reads GAMMA's `mods.txt`, opens each missing download in your normal
browser session, waits for the completed file to appear in your browser download
folder, then moves it into GAMMA's `downloads` folder using the exact filename
expected by the installer.

## Recommended Flow

First, try installing G.A.M.M.A. with the official installer and the recommended
method from the [G.A.M.M.A. repository](https://github.com/Grokitach/Stalker_GAMMA).
Use this script only if the official installer fails on every download.

After this script finishes downloading all files into `C:\GAMMA\downloads`, run
the official installer again with `Force git download` unchecked. The installer
will then extract the downloaded files into the correct folders. After that,
press `Play` in the G.A.M.M.A. Launcher to start the game.

## Paths

Default inputs:

- Mods list: `C:\GAMMA\.Grok's Modpack Installer\mods.txt`
- Browser downloads: current user's configured Downloads folder
- GAMMA downloads: `C:\GAMMA\downloads`

The browser downloads folder is detected automatically for the Windows user
running the script, so it works with any user folder name such as
`C:\Users\YourName\Downloads`. If your browser saves files somewhere else, pass
that location with `-BrowserDownloadsDir`.

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
- `-BrowserDownloadsDir "D:\Downloads"`: use a different browser download folder instead of the current user's default.
- `-DownloadsDir "C:\GAMMA\downloads"`: use a different GAMMA downloads folder.
- `-NoHash`: skip MD5 validation and accept stable completed files.
- `-All`: process entries even if the expected file already exists.

## Interactive Keys

While waiting for a file:

- `R`: reopen the current download URL.
- `P`: open the mod page.
- `S`: skip the current file.
- `Q`: quit.

## Troubleshooting

If the script fails on your machine, you can ask an AI coding assistant to inspect
the error and adjust the script for your local Windows, browser, or GAMMA setup.
Include the exact PowerShell error message, the command you ran, and your GAMMA
folder path.

Suggested prompt:

```text
I am using this PowerShell script to help download missing S.T.A.L.K.E.R.
G.A.M.M.A. files:

[paste the contents of gamma-assisted-downloads.ps1 here]

I ran this command:

[paste the exact PowerShell command here]

It failed with this error:

[paste the full error message here]

My GAMMA folder is:

[paste your GAMMA folder path here]

Please investigate the cause and update the script so it works on my machine.
```

## Notes

Run in small batches to avoid triggering additional rate limits. After the files
are present in `C:\GAMMA\downloads`, rerun the GAMMA installer so it can extract
and install the mods normally.


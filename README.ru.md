# GAMMA Assisted Downloads

[English version](README.md)

Небольшой PowerShell-скрипт для завершения загрузок S.T.A.L.K.E.R. GAMMA, когда
Grok's Modpack Installer не может скачать файлы с ModDB из-за Cloudflare или
других проверок, которые проходят только в браузере.

Скрипт читает файл `mods.txt` из GAMMA, открывает каждую отсутствующую загрузку
в обычной сессии браузера, ждет появления готового файла в папке загрузок
браузера, а затем переносит его в папку `downloads` GAMMA с точным именем,
которое ожидает установщик.

## Рекомендуемый порядок

Сначала попробуйте установить G.A.M.M.A. официальным установщиком и способом,
описанным в [репозитории G.A.M.M.A.](https://github.com/Grokitach/Stalker_GAMMA).
Используйте этот скрипт только если официальный установщик не справляется с
загрузками.

После того как скрипт загрузит все файлы в `C:\GAMMA\downloads`, запустите
официальный установщик еще раз с отключенной опцией `Force git download`.
Установщик распакует загруженные файлы в нужные папки. Затем нажмите `Play` в
G.A.M.M.A. Launcher, чтобы запустить игру.

## Пути

Пути по умолчанию:

- Список модов: `C:\GAMMA\.Grok's Modpack Installer\mods.txt`
- Загрузки браузера: текущая папка Downloads пользователя Windows
- Загрузки GAMMA: `C:\GAMMA\downloads`

Папка загрузок браузера определяется автоматически для пользователя Windows,
который запускает скрипт. Поэтому скрипт работает с любым именем профиля,
например `C:\Users\YourName\Downloads`. Если браузер сохраняет файлы в другое
место, передайте этот путь через `-BrowserDownloadsDir`.

## Проверочный запуск

Показать следующие отсутствующие загрузки без открытия браузера:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -DryRun -Limit 10 -Language ru
```

## Загрузка пакета

Открыть и обработать следующие 20 отсутствующих файлов:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -Limit 20 -Language ru
```

Если прямая ссылка `addons/start/...` не начинает загрузку, откройте страницу
мода:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\GAMMA\tools\gamma-assisted-downloads.ps1" -UseModPage -Limit 20 -Language ru
```

## Полезные параметры

- `-Limit 20`: обработать только небольшой пакет.
- `-StartAt 21`: пропустить первые 20 отсутствующих файлов в очереди.
- `-UseModPage`: открыть публичную страницу мода вместо прямой ссылки.
- `-BrowserDownloadsDir "D:\Downloads"`: использовать другую папку загрузок браузера.
- `-DownloadsDir "C:\GAMMA\downloads"`: использовать другую папку загрузок GAMMA.
- `-NoHash`: пропустить проверку MD5 и принимать стабильные завершенные файлы.
- `-All`: обрабатывать записи даже если ожидаемый файл уже существует.
- `-Language ru`: показывать сообщения скрипта на русском. `-Language en` принудительно включает английский.

## Интерактивные клавиши

Во время ожидания файла:

- `R`: снова открыть текущую ссылку загрузки.
- `P`: открыть страницу мода.
- `S`: пропустить текущий файл.
- `Q`: выйти.

## Устранение проблем

Если скрипт не работает на вашем компьютере, можно попросить AI coding assistant
посмотреть ошибку и адаптировать скрипт под вашу Windows, браузер или установку
GAMMA. Укажите точное сообщение PowerShell, команду запуска и путь к папке
GAMMA.

Пример запроса:

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

## Примечания

Запускайте скрипт небольшими пакетами, чтобы не вызвать дополнительные лимиты.
После появления файлов в `C:\GAMMA\downloads` снова запустите установщик GAMMA,
чтобы он нормально распаковал и установил моды.

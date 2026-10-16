# farmer-potato-save-tool
A PowerShell tool for reading, editing, and re-signing local save files of Farmer Against Potatoes Idle. For personal, offline use only. Use at your own risk.

# fapi-save-tool

PowerShell-инструмент для чтения, редактирования и повторной подписи локальных
сохранений игры **Farmer Against Potatoes Idle**.

## Что делает

- Распаковывает gzip-сейв (`fapi-save.txt`).
- Разбирает содержимое: `JSON + Base64(SHA256(salt + json))`.
- Позволяет прибавить (или установить) значение к указанным полям JSON.
- Пересчитывает подпись.
- Запаковывает обратно в gzip в том же формате, что использует игра.
- Делает резервную копию `.bak` рядом с оригиналом.

## Требования

- Windows 10 / 11.
- PowerShell 5.1 (встроен в Windows) или PowerShell 7+.
- Установленная игра *Farmer Against Potatoes Idle*.

## Установка

1. Скачай `Boost-Save.ps1` из этого репозитория.
2. Положи в любую папку, например `C:\Tools\`.

При первом запуске PowerShell может блокировать скрипт. Разреши его выполнение
для текущей сессии:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Использование
Сухой прогон (ничего не пишет, только показывает, что будет):

.\Boost-Save.ps1 -DryRun
Прибавить значение к FreeSoul и TotalSoul:

.\Boost-Save.ps1 -Value 1000000000
Прибавить только к одному полю:

.\Boost-Save.ps1 -Value 500000000 -Fields FreeSoul
Прибавить к нескольким полям сразу:

.\Boost-Save.ps1 -Value 1000000 -Fields FreeSoul,TotalSoul,SpentSoul
Указать путь вручную (если автоопределение не сработало):

.\Boost-Save.ps1 -SaveDir "C:\path\to\save\folder"
Скрипт по умолчанию прибавляет к текущему значению, а не заменяет.

Отказ от ответственности
Инструмент изменяет локальные файлы сохранений. Использование может нарушать
Steam Subscriber Agreement и/или правила конкретной игры.

Автор не несёт ответственности за:

повреждённые или потерянные сохранения,

перезапись файлов через Steam Cloud,

сброс лидербордов, флаги аккаунта или блокировки,

любые другие последствия использования инструмента.

Используйте на свой риск. Перед использованием сохраните копию оригинального
сейва в надёжном месте.

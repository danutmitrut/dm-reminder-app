# Remindere pe ecran: un ghid scurt

Acesta este un program mic care, la ziua și ora alese de tine, deschide o fereastră mare în mijlocul ecranului, cu un sunet, și o lasă acolo până apeși „Am înțeles”. Poți și să o amâni, cu „Repetă în”, și să îți alegi culorile ferestrei. Nu dispare singură, ca să n-o ratezi.

Nu ai nevoie de Grok Bot. Programul folosește doar unelte deja prezente pe calculator, pe Mac și pe Windows. Dacă lucrezi cu Claude Code, îi poți cere lui să adauge, să schimbe sau să șteargă un reminder. Îi dai textul gata de lipit de mai jos și fișierul `INSTRUCTIUNI-PENTRU-CLAUDE.md`.

Alege sistemul tău, Mac sau Windows, și urmează doar partea aceea.

## Pe Mac

### 1. Pune fișierele la locul lor

Din pachetul „Remindere pentru cursanti”, trebuie copiat tot conținutul folderului `mac` în folderul `Remindere` din directorul tău de utilizator. Calea finală arată așa: `/Users/NUMELE_TAU/Remindere/`.

Copiază acolo și fișierele `GHID.md` și `INSTRUCTIUNI-PENTRU-CLAUDE.md` din rădăcina pachetului, ca să le aibă Claude la îndemână.

Cel mai simplu: deschizi Terminalul, mergi în folderul pachetului (cel primit de la curs) și scrii:

```
zsh mac/instaleaza.sh
```

Scriptul face copierea pentru tine. Dacă ai deja un `remindere.json` acolo, nu îl suprascrie.

### 2. Adaugă un reminder de mână

Dacă vrei să o faci tu, fără Claude:

1. Deschide fișierul `/Users/NUMELE_TAU/Remindere/remindere.json`. În pachet găsești un exemplu, `pauza-ceai`. Poți să-l schimbi sau să adaugi o intrare nouă, pe același model. Id-ul (cheia scurtă, de exemplu `pauza-ceai`) trebuie să conțină doar litere, cifre, cratimă sau underscore.
2. Salvează fișierul.
3. În Terminal, rulează una dintre variantele de mai jos:

```
zsh ~/Remindere/adauga-reminder.sh pauza-ceai --saptamanal luni 11 00
zsh ~/Remindere/adauga-reminder.sh pauza-ceai --zilnic 11:00
zsh ~/Remindere/adauga-reminder.sh pauza-ceai --o-data 2026-11-15 11 00
```

Ziua o poți scrie și fără diacritice (`marti`, `sambata`). Ora poate fi `11 00` sau `11:00`.

Scriptul armă reminderul în programatorul de sarcini al Mac-ului (launchd) și îți confirmă ora.

### 3. Cere-i lui Claude (text gata de lipit)

Deschide Claude Code în folderul `~/Remindere` (sau spune-i calea pachetului) și lipește un text ca acesta, completat cu datele tale:

```
Pune-mi un reminder în fiecare luni la 11:00 cu textul: „Ridică-te de la birou, bea un ceai și respiră un minut.” Titlul scurt: „Pauză de ceai”.

Citește mai întâi fișierul INSTRUCTIUNI-PENTRU-CLAUDE.md din folderul Remindere (sau din pachetul „Remindere pentru cursanti”) și urmează pașii de acolo. La final, verifică că reminderul e armat și spune-mi cum îl pot testa acum.
```

Poți schimba ziua, ora, textul și titlul. Merge și „în fiecare zi la 9:00”, sau „o dată, pe 15 noiembrie 2026, la 18:30”.

### 4. Testează acum, fără să aștepți ora

În Terminal:

```
/usr/bin/osascript -l JavaScript ~/Remindere/reminder.js pauza-ceai
```

Înlocuiește `pauza-ceai` cu id-ul tău. Trebuie să apară fereastra, cu sunet. O închizi cu butonul „Am înțeles” sau cu Enter, sau o amâni cu „Repetă în”. Asta nu strică programarea: reminderul rămâne armat pentru ziua și ora alese.

### 5. Șterge un reminder

Doar programarea (textul rămâne în listă):

```
zsh ~/Remindere/sterge-reminder.sh pauza-ceai
```

Programarea și intrarea din listă:

```
zsh ~/Remindere/sterge-reminder.sh pauza-ceai --si-din-lista
```

### 6. Dacă Mac-ul doarme la ora aceea

Mac-ul trebuie să fie pornit, sau să-l deschizi după ora programată. Dacă doarme la ora reminderului, fereastra apare imediat ce îl trezești. Dacă e stins de tot, reminderul apare după ce îl pornești și te autentifici.

## Pe Windows

Atenție: varianta de Windows nu a fost încă încercată pe un calculator real. Folosește-o, dar dacă ceva nu merge (fereastra nu apare, diacriticele ies strâmbe, sau sarcina nu se armează), notează ce s-a întâmplat și spune-i lui Dănuț Mitruț, ca să o corectăm. E util dacă un cursant o încearcă primul și ne spune cum a mers.

### 1. Pune fișierele la locul lor

Din pachetul „Remindere pentru cursanti”, copiază tot conținutul folderului `windows` în folderul `Remindere` din directorul tău de utilizator. Calea finală arată așa: `C:\Users\NUMELE_TAU\Remindere\`.

Copiază acolo și fișierele `GHID.md` și `INSTRUCTIUNI-PENTRU-CLAUDE.md` din rădăcina pachetului.

Cel mai simplu: deschizi PowerShell, mergi în folderul pachetului și scrii:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\instaleaza.ps1
```

Scriptul face copierea pentru tine. Dacă ai deja un `remindere.json` acolo, nu îl suprascrie.

Dacă Windows refuză să ruleze scripturile pentru că vin din altă sursă (un zip, un email, un drive), în PowerShell, în folderul Remindere, scrie o dată:

```
Unblock-File *
```

### 2. Adaugă un reminder de mână

1. Deschide fișierul `C:\Users\NUMELE_TAU\Remindere\remindere.json`. Folosește exemplul `pauza-ceai` sau adaugă o intrare nouă, pe același model. Id-ul trebuie să conțină doar litere, cifre, cratimă sau underscore.
2. Salvează fișierul ca UTF-8.
3. În PowerShell, rulează una dintre variantele de mai jos:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\adauga-reminder.ps1 pauza-ceai --saptamanal luni 11 00
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\adauga-reminder.ps1 pauza-ceai --zilnic 11:00
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\adauga-reminder.ps1 pauza-ceai --o-data 2026-11-15 11 00
```

Scriptul creează o sarcină în Programatorul de sarcini (Task Scheduler), care rulează doar când ești autentificat (logat) în Windows.

### 3. Cere-i lui Claude (text gata de lipit)

Este același text ca la Mac. Deschide Claude Code în folderul `Remindere` și lipește:

```
Pune-mi un reminder în fiecare luni la 11:00 cu textul: „Ridică-te de la birou, bea un ceai și respiră un minut.” Titlul scurt: „Pauză de ceai”.

Citește mai întâi fișierul INSTRUCTIUNI-PENTRU-CLAUDE.md din folderul Remindere (sau din pachetul „Remindere pentru cursanti”) și urmează pașii de acolo. La final, verifică că reminderul e armat și spune-mi cum îl pot testa acum.
```

### 4. Testează acum, fără să aștepți ora

În PowerShell:

```
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\reminder.ps1 -Id pauza-ceai
```

Înlocuiește `pauza-ceai` cu id-ul tău. Trebuie să apară fereastra, cu sunet. O închizi cu „Am înțeles” sau cu Enter, sau o amâni cu „Repetă în”. Programarea rămâne în picioare.

### 5. Șterge un reminder

Doar programarea:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\sterge-reminder.ps1 pauza-ceai
```

Programarea și intrarea din listă:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Remindere\sterge-reminder.ps1 pauza-ceai --si-din-lista
```

### 6. Dacă calculatorul doarme sau e stins la ora aceea

Sarcina e setată să pornească imediat ce e posibil după ora programată, dacă ai ratat startul (calculatorul era adormit sau stins). Trebuie să fii autentificat în Windows. Dacă ești doar pe ecranul de blocare, dar sesiunea ta există, sarcina poate porni oricum. Dacă nimeni nu e autentificat, fereastra așteaptă până te autentifici.

## Amânarea ferestrei

În fereastră, lângă „Am înțeles”, ai o casetă derulantă cu intervale de 5, 10, 15, până la 60 de minute, și butonul „Repetă în”. Dacă îl apeși, fereastra se închide și revine, cu sunet, după minutele alese. Poți amâna de mai multe ori. „Am înțeles” sau Enter închid reminderul de tot, până la următoarea dată programată. Pentru un interval mai lung de 60 de minute, nu folosi amânarea: pune un reminder obișnuit, la ora pe care o vrei.

## Culorile ferestrei

În stânga sus, într-un chenar rotunjit, la „Alege fundalul”, vezi două rânduri: „Culoare solidă” cu o casetă mică de culoare în dreapta, și „Degrade” cu două casete (început și sfârșit). Casetele stau pe aceeași coloană. Un clic pe casetă deschide paleta de culori; dacă apeși o casetă a celuilalt mod, se selectează și modul. Doar casetele modului ales au chenar; celelalte sunt puțin estompate, dar rămân active. În dreapta sus e un ceas analogic, care merge în timp real. În stânga ceasului, data e scrisă pe trei rânduri, în română, cu un font fără serife: ziua săptămânii, apoi ziua și luna, apoi anul. La solid alegi o culoare din paletă; la degrade, două (început și sfârșit). Fundalul se schimbă imediat, iar alegerea se păstrează pentru toate reminderele următoare, inclusiv după ce amâni fereastra. Dacă nu schimbi nimic, rămâne degradeul prestabilit, lavandă, violet și turcoaz. Ca să revii la acest aspect, șterge fișierul `design.json` din folderul Remindere (pe Mac: `~/Remindere/design.json`; pe Windows: `%USERPROFILE%\Remindere\design.json`).

## Dacă ceva nu merge

- Verifică întâi că fișierele sunt exact în `~/Remindere` (Mac) sau `%USERPROFILE%\Remindere` (Windows), nu rămase doar în pachetul de pe Desktop sau din Descărcări.
- Pe Mac, poți privi `~/Remindere/err.log` și `~/Remindere/jurnal.log`.
- Pe Windows, același `jurnal.log` din folderul Remindere, plus Programatorul de sarcini, la folderul `Remindere`.
- Nu instala nimic în plus. Pe Mac nu e nevoie de Python. Pe Windows e de ajuns Windows PowerShell, care vine cu sistemul.

Pachet pregătit pentru cursanții lui Dănuț Mitruț.

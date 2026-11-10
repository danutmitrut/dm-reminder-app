# Instrucțiuni pentru Claude Code: remindere pe ecran

Acest fișier este pentru tine, asistentul de cod, nu un ghid pas cu pas pentru cursant. Citește-l până la capăt înainte să adaugi, să schimbi, să ștergi sau să testezi un reminder. Vorbește cu cursantul în română, cu diacritice. Nu folosi linia de pauză lungă (em dash sau en dash) ca separator în texte; folosește virgulă sau două puncte.

## Ce este

Un program mic, fără servicii externe. La ziua și ora programate, apare o fereastră mare, deasupra celorlalte, până când utilizatorul apasă „Am înțeles” sau Enter. Poate amâna fereastra cu „Repetă în”, alegând 5, 10, 15, până la 60 de minute: fereastra se închide și revine, cu sunet, după intervalul ales, și poate fi amânată din nou. Pentru mai mult de 60 de minute se pune un reminder obișnuit. Lista reminderelor stă în `remindere.json`. Programarea o face sistemul de operare: launchd pe Mac, Task Scheduler pe Windows.

Locul canonic al fișierelor, după instalare:

- Mac: `~/Remindere/`
- Windows: `%USERPROFILE%\Remindere\`

Nu instala Python, node sau alte unelte. Nu modifica alte LaunchAgents, alte sarcini din Task Scheduler, și nu atinge foldere care nu țin de acest pachet (de exemplu `~/.mister-o`).

## Detectează sistemul și instalează dacă e nevoie

1. Află dacă ești pe macOS sau pe Windows.
2. Dacă folderul canonic nu există, sau dacă lipsesc scripturile platformei, instalează din pachet:
   - Mac, din rădăcina pachetului „Remindere pentru cursanti”: `zsh mac/instaleaza.sh`
   - Windows, din rădăcina pachetului: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\instaleaza.ps1`
3. `instaleaza` copiază scripturile, ghidul și aceste instrucțiuni în folderul canonic. Dacă `remindere.json` există deja acolo, îl lasă neschimbat. Nu-l suprascrie.
4. Lucrează apoi doar din folderul canonic. Scripturile `adauga-reminder` și `sterge-reminder` refuză să ruleze din altă cale.

## Schema lui `remindere.json`

Un obiect, cheile sunt id-urile:

```json
{
  "pauza-ceai": {
    "titlu": "Pauză de ceai",
    "text": "Ridică-te de la birou, bea un ceai și respiră un minut.",
    "cand": "luni 11:00, săptămânal"
  }
}
```

Reguli:

- Id: doar `a-z`, `A-Z`, `0-9`, cratimă, underscore. Preferă litere mici și cratimă: `pauza-ceai`.
- `titlu` și `text` sunt obligatorii. `cand` este o descriere pentru om; scriptul `adauga-reminder` o actualizează el când programează.
- Pentru un reminder care trebuie să apară o singură dată, scriptul pune și `"o_data": true`. Pe Mac, după ce fereastra se închide, `reminder.js` dezarmează singur programarea, pentru că launchd nu are an în intervalul de calendar și altfel s-ar relua în anul următor.
- Păstrează JSON valid, UTF-8, cu diacritice scrise clar, nu ca `\uXXXX`. Pe Windows, poți salva și cu BOM. Nu folosi Python ca să rescrii fișierul pe Mac: editează-l tu, sau lasă `adauga-reminder.sh` / `sterge-reminder.sh` să actualizeze `cand` și ștergerea din listă.

## Cum adaugi un reminder

1. Asigură-te că fișierele sunt în folderul canonic.
2. Adaugă sau actualizează intrarea în `remindere.json` (`titlu`, `text`). Nu armă încă.
3. Rulează scriptul de programare din folderul canonic:

Mac:

```
zsh ~/Remindere/adauga-reminder.sh <id> --saptamanal <zi> <ora> [minut]
zsh ~/Remindere/adauga-reminder.sh <id> --zilnic <ora> [minut]
zsh ~/Remindere/adauga-reminder.sh <id> --o-data <YYYY-MM-DD> <ora> [minut]
```

Windows (Windows PowerShell 5.1 e în regulă):

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\adauga-reminder.ps1 <id> --saptamanal <zi> <ora> [minut]
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\adauga-reminder.ps1 <id> --zilnic <ora> [minut]
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\adauga-reminder.ps1 <id> --o-data <YYYY-MM-DD> <ora> [minut]
```

Ziua poate fi în română, cu sau fără diacritice, sau în engleză. Ora poate fi `18 30` sau `18:30`.

4. Dacă reminderul exista deja, scriptul înlocuiește programarea (bootout + bootstrap pe Mac, `Register-ScheduledTask -Force` pe Windows).

## Cum verifici că e armat

Mac:

```
launchctl print gui/$(id -u)/com.cursant.reminder.<id>
```

Trebuie să găsească serviciul. Te uiți după `ProgramArguments` (calea spre `reminder.js` și id), după `StartCalendarInterval` (zi, oră, minut) și după faptul că nu e dezactivat. Dacă print eșuează cu „Could not find service”, nu e armat.

Windows:

```
Get-ScheduledTask -TaskName CursantReminder-<id> -TaskPath \Remindere\
Get-ScheduledTaskInfo -TaskName CursantReminder-<id> -TaskPath \Remindere\
```

Starea normală, înainte de oră, este `Ready`. Verifici acțiunea (powershell.exe, `-File` spre `reminder.ps1`, `-Identificator` sau `-Id`), declanșatorul (zi/oră) și `StartWhenAvailable` (să pornească imediat ce e posibil după un start ratat). `LogonType` trebuie să fie interactiv, iar sarcina să ruleze doar când utilizatorul e autentificat. Nu pune sarcina Hidden și nu-i cere parolă de SYSTEM.

Spune-i cursantului, pe scurt, ce ai verificat și la ce oră va apărea fereastra.

## Cum testezi acum, fără să aștepți ora

Nu crea o programare „peste un minut” doar ca test, dacă poți evită asta. Rulează scriptul ferestrei direct:

Mac:

```
/usr/bin/osascript -l JavaScript ~/Remindere/reminder.js <id>
```

Windows:

```
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\reminder.ps1 -Id <id>
```

Avertizează cursantul că va apărea o fereastră și că o poate închide cu „Am înțeles” sau Enter, sau o poate amâna cu „Repetă în”. Dacă testezi tu amânarea, alege un interval scurt sau nu aștepta cele 5 minute în sesiune. Testul nu trebuie să dezarmeze un reminder săptămânal sau zilnic. (Pe Mac, un reminder cu `"o_data": true` se dezarmează după închiderea ferestrei, deci nu testa un reminder „o dată” în acest fel dacă vrei să rămână armat pentru data viitoare: spune-i cursantului și, dacă e nevoie, re-armează-l după test.)

Nu instala un job launchd pe un calculator care nu e al cursantului, și nu armă nimic „ca să vezi dacă merge” fără cererea lui.

## Cum schimbi un reminder

- Doar textul sau titlul: editează `remindere.json`. Programarea rămâne, pentru că ea trimite doar id-ul.
- Doar ziua sau ora: rulează din nou `adauga-reminder` cu același id și noul program. Scriptul actualizează și câmpul `cand`.
- Id-ul: adaugă o intrare nouă, armează-o, apoi șterge id-ul vechi (programare + listă). Nu redenumi doar cheia și lăsa jobul vechi în urmă.

## Cum ștergi un reminder

Mac:

```
zsh ~/Remindere/sterge-reminder.sh <id>
zsh ~/Remindere/sterge-reminder.sh <id> --si-din-lista
```

Windows:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\sterge-reminder.ps1 <id>
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\Remindere\sterge-reminder.ps1 <id> --si-din-lista
```

Fără `--si-din-lista` rămâne textul în JSON, dar nu se mai afișează la oră. După ștergere, verifică: `launchctl print` sau `Get-ScheduledTask` nu mai găsesc serviciul, respectiv sarcina. Ștergi doar etichetele `com.cursant.reminder.*` și sarcinile `\Remindere\CursantReminder-*`. Nimic altceva.

## Amânarea ferestrei

Fereastra are, în stânga jos, o casetă derulantă (5, 10, 15, până la 60 de minute, din 5 în 5) și butonul „Repetă în”. În dreapta rămâne „Am înțeles”. Enter închide definitiv, ca „Am înțeles”. La amânare, fereastra se ascunde, așteaptă N minute, apoi reapare cu sunet. Poate fi amânată de mai multe ori. Pentru un interval mai lung de 60 de minute, cursantul pune un reminder obișnuit, nu folosește amânarea. În `jurnal.log` apare o linie `amana N min` la fiecare amânare, și `ok` când fereastra e închisă de tot.

## Culorile ferestrei

În stânga sus, panoul „Alege fundalul” (eticheta și cele două rânduri) e încadrat într-un chenar cu colțuri rotunjite, gros de 2 px, culoare (0,62, 0,50, 0,92), ca bordura ferestrei. Două rânduri mereu vizibile: radio „Culoare solidă” cu o casetă mică (circa 28×18) în dreapta, și radio „Degrade” cu două casete (început și sfârșit) aliniate pe aceeași coloană. Textul radio-ului e centrat vertical cu caseta. Etichetele separate de sub casete au fost scoase (rămân ca tooltip). Casetele modului neales sunt estompate (alpha circa 0,5), dar rămân clicabile; un clic pe ele selectează și modul, apoi deschide paleta. Chenarul vizibil de 2 px, aproape negru sau alb după luminozitate, e doar pe caseta sau casetele modului selectat; cele neselectate nu au chenar. În dreapta sus e un ceas analogic funcțional. În stânga ceasului, data e pe trei rânduri, aliniate la dreapta, cu font fără serife, aceleași mărimi: ziua săptămânii, apoi „10 noiembrie”, apoi anul. Numele zilelor și lunilor sunt scrise în script, nu luate din locale. Fontul datei e sans-serif: pe Mac Avenir Next (Medium, DemiBold la mijloc), cu rezervă Helvetica Neue sau sistem; pe Windows Segoe UI (Semibold la mijloc). Titlul și textul principal sunt centrate pe lățimea ferestrei, așezate vertical între zona de sus și butoane. Nu există emoticon ⏰. Fundalul se actualizează pe loc. Alegerea stă în `design.json`, în folderul canonic, și se aplică la toate reminderele, inclusiv la reafișarea după amânare. Fără acest fișier, aspectul e cel prestabilit (degrade lavandă, violet, turcoaz, text aproape negru). Ca să revii la prestabilit, ștergi `design.json`. Nu inventa alt format; fișierul e scris de fereastră. Dacă cineva alege o culoare foarte închisă, textul (inclusiv data și acele ceasului) trece automat pe alb, după luminozitate. Amânarea și „Am înțeles” rămân neschimbate.

## Detalii de platformă, importante

### Mac

- Fereastra e un singur script JXA, `reminder.js`. Nu introduce Python. Amânarea stă tot în `reminder.js`: ascunde fereastra, așteaptă cu `NSThread.sleepForTimeInterval`, apoi o reafișează și redă sunetul. Pentru butonul de amânare și caseta derulantă, folosește `setTitle` / `setFont` / `setContentTintColor` și `NSPopUpButton` (`addItemWithTitle`, `indexOfSelectedItem`). Nu folosi `NSAttributedString`. Culorile stau în stânga sus, pe două rânduri: eticheta „Alege fundalul”, radio-ul „Culoare solidă” cu caseta în dreapta, apoi radio-ul „Degrade” cu două casete. Eșantioanele sunt butoane colorate mici (circa 28×18), nu `NSColorWell`. Clic pe eșantion selectează modul dacă e nevoie și deschide `NSColorPanel` (ridicat deasupra ferestrei, cu `setTarget` / `setAction` pe panou). Ceasul analogic din dreapta sus e o subclasă `NSView` (cadranul e desenat într-un `NSImage`, pentru că JXA nu poate suprascrie `drawRect:`, tipul `NSRect` nu trece de verificare), actualizat de un `NSTimer` la 1 secundă, adăugat pe `NSRunLoopCommonModes`. Fereastra e o subclasă de `NSWindow` cu `canBecomeKeyWindow`, ca paleta să poată deveni activă; `NSColorPanel` e partajat și trebuie ridicat deasupra ferestrei (`setLevel` mai mare decât `NSStatusWindowLevel`). Verifică existența clasei cu `typeof $.NumeClasa === 'undefined'`, nu cu adevărul lui `NSClassFromString`.
- Degradeul trebuie desenat cu `NSGradient` într-un `NSImage`, pus într-un `NSImageView`. `CAGradientLayer` nu s-a văzut în probe. Rămâne `ObjC.import('QuartzCore')`. Pentru buton, nu folosi `NSAttributedString` (inițializarea a eșuat în probe): folosește `setTitle`, `setFont` și `setContentTintColor`.
- Sunet: `doShellScript('afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &')`.
- Eticheta launchd: `com.cursant.reminder.<id>`. Fișierul: `~/Library/LaunchAgents/com.cursant.reminder.<id>.plist`. Încărcare: `launchctl bootstrap gui/$(id -u) <plist>`, după un `bootout` dacă exista. În plist, comanda este `/usr/bin/osascript -l JavaScript /Users/.../Remindere/reminder.js <id>`.
- launchd: duminică = 0, luni = 1, marți = 2, miercuri = 3, joi = 4, vineri = 5, sâmbătă = 6. Pentru zilnic, pui doar Hour și Minute. Pentru o dată, pui Month, Day, Hour, Minute (fără an) și `"o_data": true`.
- Dacă Mac-ul doarme la oră, jobul rulează la trezire. Dacă e stins, rulează după pornire și autentificare, când launchd preia intervalul ratat.

### Windows

- Dacă Windows blochează scripturile descărcate (ExecutionPolicy sau „running scripts is disabled”), rulează `Unblock-File` pe fișierele `.ps1` din folderul canonic, apoi lansează-le cu `-ExecutionPolicy Bypass`, ca în exemple.
- Varianta de Windows nu a fost testată pe un calculator real. După ce armezi, verifică sarcina și propune testul imediat al ferestrei. Dacă ceva eșuează, spune clar ce comandă a picat și mesajul de eroare. Nu „repara” instaland unelte noi fără acord.
- Scripturile `.ps1` trebuie să rămână UTF-8 cu BOM, altfel Windows PowerShell 5.1 strică diacriticele (`ă`, `î`, `â`, `ș`, `ț`, „Am înțeles”). Când editezi un `.ps1`, păstrează BOM-ul. `remindere.json` se citește explicit ca UTF-8.
- Fereastra e WPF (`PresentationFramework`): `WindowStyle="None"`, `AllowsTransparency="True"`, `Topmost="True"`, bordură cu `CornerRadius="28"` și `LinearGradientBrush` cu aceleași trei culori ca pe Mac. Rândul de jos are un `ComboBox` (5 până la 60 de minute) și butonul „Repetă în” în stânga, iar „Am înțeles” în dreapta (`IsDefault`, deci Enter închide definitiv). În stânga sus, eticheta „Alege fundalul”, apoi două rânduri: radio „Culoare solidă” cu o casetă în dreapta, radio „Degrade” cu două casete. Eșantioanele mici (28×18, colțuri rotunjite; chenar de 2 px doar pe modul selectat) deschid `System.Windows.Forms.ColorDialog` (`FullOpen`), cu paleta completă; în timpul dialogului, `Topmost` se dezactivează temporar ca dialogul să nu rămână în spate. În dreapta sus, ceasul analogic e un `Canvas` WPF redesenat de un `DispatcherTimer` la 1 secundă, oprit la închiderea ferestrei. La amânare, scriptul închide fereastra, face `Start-Sleep` N minute, apoi o reconstruiește (citind `design.json`) și reapare cu sunet. Firul trebuie să fie STA: de aceea comanda de rulare include `-STA`.
- Sarcina: `\Remindere\CursantReminder-<id>`. Acțiune: `powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "<cale>\reminder.ps1" -Identificator <id>`. Principal interactiv, doar când utilizatorul e autentificat, `StartWhenAvailable`, fără Hidden pe sarcină, `ExecutionTimeLimit` o oră. `-WindowStyle Hidden` ascunde consola, nu fereastra WPF.
- Dacă `New-ScheduledTaskAction` refuză `-WorkingDirectory` pe o ediție veche, omite parametrul și lasă calea absolută spre `.ps1`, care e deja în argumente.

## Cum îi spui cursantului, la final

În română, scurt:

- ce reminder ai pus (titlu, text, zi, oră, săptămânal / zilnic / o dată);
- că e armat, și cum ai verificat;
- comanda cu care poate deschide fereastra imediat, ca să o vadă;
- cum îl poate șterge mai târziu, sau că ți-o poate cere ție.

Nu pretinde că varianta de Windows a fost încercată pe un PC, dacă tu rulezi pe Mac sau într-un mediu fără Windows.

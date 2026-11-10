# DM reminder app: cum îl instalezi cu Claude sau Codex

Programul pune pe ecran, la ziua și ora alese, o fereastră mare cu sunet, care stă acolo până apeși „Am înțeles”. O poți amâna 5 până la 60 de minute, îți alegi culorile și are un ceas cu data. Merge pe Mac și pe Windows, fără să instalezi nimic în plus.

Codul e aici: https://github.com/danutmitrut/dm-reminder-app

Nu trebuie să știi programare. Lucrul greu îl face Claude Code sau Codex, tu doar îi dai linkul și îi spui ce reminder vrei.

## Pasul 1. Deschide Claude Code sau Codex

- **Pe Mac:** deschide aplicația Terminal, scrie `cd ~` și apasă Enter, apoi pornește `claude` (sau `codex`).
- **Pe Windows:** deschide PowerShell, scrie `cd ~` și apasă Enter, apoi pornește `claude` (sau `codex`).

Dacă folosești aplicația desktop Claude Code sau Codex, deschide un proiect nou în folderul tău de utilizator.

## Pasul 2. Lipește textul acesta

Același text merge și pe Mac, și pe Windows. Schimbă doar ziua, ora, titlul și mesajul.

```
Vreau să instalezi programul de remindere de aici: https://github.com/danutmitrut/dm-reminder-app

1. Descarcă repo-ul (git clone sau, dacă nu am git, arhiva ZIP de pe GitHub) într-un folder temporar.
2. Citește README.md și INSTRUCTIUNI-PENTRU-CLAUDE.md și urmează partea pentru sistemul meu (Mac sau Windows; verifică tu ce am).
3. Instalează-l în folderul Remindere din directorul meu de utilizator, cu scriptul instaleaza din repo.
4. Pune-mi un reminder în fiecare luni la 11:00, cu titlul „Pauză de ceai” și textul „Ridică-te de la birou, bea un ceai și respiră un minut.”
5. Verifică că reminderul e armat și arată-mi fereastra o dată acum, ca test.

Nu modifica scripturile programului. Dacă apare o eroare, arată-mi-o exact și spune-mi ce propui, înainte să faci altceva.
```

Alte variante pentru punctul 4: „în fiecare zi la 9:00” sau „o singură dată, pe 15 noiembrie 2026, la 18:30”.

## Pasul 3. Ce trebuie să vezi

La final îți apare fereastra de test, cu sunet. Încearcă:
- în stânga sus, la „Alege fundalul”, o culoare solidă sau un degrade;
- jos, un interval din casetă și „Repetă în” (fereastra revine după minutele alese);
- „Am înțeles” sau Enter, ca s-o închizi.

## Mai departe

Pentru alt reminder, schimbare sau ștergere, deschizi Claude sau Codex în folderul `Remindere` și îi spui simplu, de exemplu: „Pune-mi un reminder miercuri la 18:30 cu textul …”, „Mută pauza de ceai la 10:30” sau „Șterge reminderul pauza-ceai”. Instrucțiunile lui sunt deja în folder.

**Bine de știut:**
- Calculatorul trebuie să fie pornit și tu autentificat. Dacă dormea la ora reminderului, fereastra apare când îl trezești.
- **Windows:** dacă scripturile sunt blocate pentru că vin de pe internet, cere-i lui Claude sau Codex să ruleze `Unblock-File` pe folderul Remindere. Varianta de Windows e nouă, așa că, dacă ceva nu merge, trimite eroarea mai departe ca s-o reparăm.
- **Mac:** prima dată, macOS te poate întreba dacă Terminalul are voie să controleze ceva. Apasă OK.
- Ca să revii la culorile inițiale, ștergi fișierul `design.json` din folderul Remindere.

Ghid de la Dănuț Mitruț.

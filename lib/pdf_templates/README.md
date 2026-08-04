# eFZ Antrag PDF Template

The corresponding directory in the last loaded wagon (this is the first wagon listed in the environment variable `$WAGONS`) 
must contain the PDF formular file used to generate the eFZ (erweitertes Führungszeugnis) application document.

The file must be named exactly `efz_antrag.pdf`

It must be a PDF form and all included fields named like the following list will get filled in automatically:

- `mitglied_name`  
  Name der Person (Vor- und Nachname)
- `mitglied_address`
  Mehrzeilige Adresse der Person ohne Name:
  - c/o Zusatz (wenn vorhanden)
  - Strasse + Hausnummer
  - Postfach (wenn vorhanden)
  - PLZ + Ortsname
  - Land (wenn nicht Deutschland)
- `mitglied_number`
- `mitglied_birthdate`
- `mitglied_city`
  Wohnort der Person
- `group_name`
  Name der Gruppe im Namen derer der Antrag gestellt wird
- `group_address`
  Mehrzeilige Adresse der Gruppe:
  - c/o Zusatz (wenn vorhanden)
  - Strasse + Hausnummer
  - Postfach (wenn vorhanden)
  - PLZ + Ortsname
  - Land (wenn nicht Deutschland)
- `group_mail`
- `group_phone`
  Die erste gelistete Telefonnummer der Gruppe
- `group_url`
- `efz_recipient_name`
  Name auf der eFZ Empfängeradresse der Gruppe falls vorhanden, sonst der Name der Gruppe
- `efz_recipient_address`
  eFZ Empfängeradresse der Gruppe falls vorhanden, sonst die Adresse der Gruppe.  
  Mehrzeilige Adresse, siehe `group_address` für Format
- `date`
  aktuelles Datum

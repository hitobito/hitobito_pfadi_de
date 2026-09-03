# Hitobito Changelog

## unreleased

* `pfadi_de` spezifische Kontaktkonto-Kategorien (Telefon, E-Mail, Adresse, Social Media) implementiert inkl. eFZ Anschrift auf Gruppen (hitobito_pfadi_de#102)
* Die satzungsgemässe Hauptgruppierung einer Person kann auf Personenlisten eingeblendet, exportiert und über die API gelesen werden. Die bisherige Hitobito-Hauptgruppe/-Hauptebene heisst neu "Standardgruppe"/"Standardebene" (hitobito_pfadi_de#47)
* Aufnahmeverfahren-Attribute an Personen können auf dem Verlauf-Tab eingesehen werden (hitobito_bdp#27)
* API Keys (ServiceTokens) können nur noch von Benutzern mit Admin-Rechten verwaltet werden. Andere user sehen die API Keys nicht (hitobito_pfadi_de#68)
* eFZ Einsichtnahmen können über das JSON:API aufgelistet, erstellt und gelöscht werden (hitobito_bdp#26)
* Der "Nachrichten"-Tab auf Personenprofilen ist nur noch für die Person selbst und für Admins sichtbar (hitobito_pfadi_de#70)

## Version 2.9

* Layer spezifische Gruppenattribute (Gründungsdatum, Rechtsform u.a.) können erfasst und über die API gelesen werden (hitobito_pfadi_de#46)
* Beitragsarten können auf Personlisten eingeblendet und exportiert werden (hitobito_pfadi_de#31)
* In den Rechnungseinstellungen können Beitragsarten erfasst und verwaltet werden (hitobito_pfadi_de#15)
* Wenn eine Beitragart archiviert ist, wird sie nicht mehr zur Vererbung angeboten (hitobito_pfadi_de#22)
* Beitragsarten können "rechtebeschränkt" werden, damit diese nur noch von gewissen Rollen zugewiesen werden können (hitobito_pfadi_de#17)
* Zu Beitragsarten können Beitragssätze erfasst und verwaltet werden (hitobito_pfadi_de#19)
* Jeder Rolle mit Beitragsart wird beim Anlegen eine Beitragsart automatisch zugeordnet (hitobito_pfadi_de#16)
* Lesende JSON-API für Beitragsartzen und -sätze inklusive speziell hierfür ausgestellter ServiceTokens kann genutzt werden (hitobito_pfadi_de#20)

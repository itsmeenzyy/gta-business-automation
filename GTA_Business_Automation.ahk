#Requires AutoHotkey v2.0
SetTitleMatchMode(2)  ; "Titel enthält" statt exakter Übereinstimmung

global Sprache := "DE"  ; wird ganz am Anfang per ZeigeKomplettSetup() gesetzt
global AkzentFarbe := "00E5FF"  ; wird ganz am Anfang per ZeigeKomplettSetup() gesetzt

; =========================================================================
; 🔄 AUTO-UPDATE (optional, standardmäßig aus).
;
; WICHTIG: Nur DU (der Ersteller) musst das hier einrichten und bei jeder
; neuen Version pflegen. Deine Freunde müssen NICHTS tun - bei ihnen läuft
; die Prüfung automatisch im Hintergrund, sie bekommen nur den Dialog
; "Update verfügbar?" zu sehen, wenn eine neue Version bereitsteht.
;
; So richtest du es einmalig ein (GitHub, kostenlos, zuverlässiger als
; Pastebin - Pastebin blockt automatisierte Abrufe oft):
;   1. Kostenlosen Account auf https://github.com anlegen (falls noch nicht
;      vorhanden).
;   2. Neues Repository erstellen (oben rechts "+" -> "New repository"),
;      z.B. "gta-business-automation". Sichtbarkeit: Public (kostenlos,
;      auch bei privaten Skripten unproblematisch, da niemand danach sucht,
;      der die URL nicht kennt).
;   3. Diese Datei dort hochladen (per Weboberfläche: "Add file" ->
;      "Upload files"), z.B. als "GTA_Business_Automation.ahk".
;   4. Eine zweite, kleine Datei "version.txt" hochladen, die NUR die
;      Versionsnummer enthält, z.B. "4.7" (ohne "v", ohne Anführungszeichen).
;   5. Für jede der beiden Dateien im Repo öffnen -> "Raw"-Button klicken ->
;      die URL aus der Adresszeile kopieren (sieht aus wie
;      https://raw.githubusercontent.com/DeinName/DeinRepo/main/DATEINAME)
;      -> unten bei UpdateDateiUrl bzw. UpdateVersionsUrl eintragen.
;   6. AutoUpdateAktiviert auf true setzen.
;
; WICHTIG: Liegt die .ahk-Datei in einem geschützten Ordner (z.B. "Program
; Files"), kann das Update trotzdem mit "Zugriff verweigert" fehlschlagen -
; dort braucht JEDE Datei-Änderung Admin-Rechte. Lege die Datei stattdessen
; z.B. auf den Desktop oder in "Dokumente".
;
; Bei jeder neuen Version: beide Dateien im Repo aktualisieren (Weboberfläche:
; Datei öffnen -> Stift-Symbol "Edit" -> Inhalt ersetzen -> "Commit changes").
; Die URLs bleiben dabei gleich, nur der Inhalt ändert sich. Nutzer bekommen
; die neue Version dann beim nächsten Start (oder Shift+U) automatisch
; angeboten.
; =========================================================================
global AutoUpdateAktiviert := true
global AktuelleVersion := "6.2"
global UpdateVersionsUrl := "https://raw.githubusercontent.com/itsmeenzyy/gta-business-automation/main/version.txt"
global UpdateDateiUrl := "https://raw.githubusercontent.com/itsmeenzyy/gta-business-automation/main/GTA_Business_Automation.ahk"

; =========================================================================
; 🎮 GTA-FENSTER: Skript sendet Tasten NUR, wenn dieses Fenster aktiv ist
; bzw. holt es sich vorher automatisch in den Vordergrund - so kannst du
; nebenbei am PC andere Dinge erledigen, ohne dass Tasten woanders landen.
; =========================================================================
global GTAFensterTitel := "Grand Theft Auto V"

; =========================================================================
; 🏢 UNTERNEHMENS-BESITZ (wird beim ersten Start abgefragt & gespeichert)
; =========================================================================
global BesitztNachtclub := true
global BesitztSpielhalle := true
global BesitztAgentur := true
global BesitztSchrotthandel := true
global BesitztKautionsbuero := true
global BesitztTextilfabrik := true
global BesitztWaschanlage := true
global BesitztHangar := true
; Lagerhäuser jetzt einzeln pro Slot (1-5), Größe wird im Setup gewählt.
global BesitztLager1 := true
global BesitztLager2 := true
global BesitztLager3 := true
global BesitztLager4 := true
global BesitztLager5 := true
global BesitztLagerhaus := true  ; abgeleitet: true, falls mind. 1 Lager besessen

; =========================================================================
; 📋 FESTE WIRTSCHAFTS-WERTE (EXAKT NACH DEINEN ANGABEN)
; =========================================================================
global KostenProLagerhaus := 7500   ; Pro Lagerhaus-Mitarbeiter-Dispatch (4 Lager)
global KostenHangar      := 25000   ; Pro Hangar-Mitarbeiter-Dispatch
global SpielhalleEinnahmen := 5000  ; Feste Arcade-Safe Einnahmen (Maximum bei allen Slots belegt)
global AgenturEinnahmen  := 10000   ; Agency-Safe (bis zu $20.000 möglich, abhängig von Sicherheitsverträgen - ggf. anpassen)
; TODO: Keine offizielle Quelle für Schrotthandel/Textilfabrik gefunden -
; erstmal grob wie Spielhalle geschätzt, bitte an echten Wert anpassen.
global SchrotthandelEinnahmen := 5000
global TextilfabrikEinnahmen := 5000
; Waschanlage: Safe startet bei $750/Tag, verdoppelt sich nach 15 Geldwäsche-
; Missionen auf $1.500/Tag. Deckel liegt bei $100.000 im Safe.
global WaschanlageEinnahmen := 750

; =========================================================================
; 🎵 NACHTCLUB-BELIEBTHEIT (bestimmt die Safe-Einnahmen, sinkt automatisch)
; =========================================================================
; Beliebtheit sinkt um 5%-Punkte pro 48-Min-Runde (offizielle Spielmechanik).
; Die Einnahmen pro Runde hängen nichtlinear von der Beliebtheit ab -
; siehe BeliebtheitZuEinnahmen() weiter unten für die genaue Tabelle.
global NachtclubBeliebtheit := 100   ; Wird beim Start abgefragt/synchronisiert
global TotalNachtclubEinnahmen := 0

; =========================================================================
; 🎚️ NACHTCLUB-WARENLAGER (Techniker-System, läuft in ECHTZEIT unabhängig
; vom 48-Min-Rundenzyklus). Werte laut aktuellen Guides (2026): mit
; Ausrüstungs-Upgrade ~$41.000/Std. bei allen 5 Top-Kategorien zugewiesen,
; voll nach ca. 60-66 Std. bei ~$1.900.000 brutto. Ohne Upgrade etwa halbe
; Rate/doppelte Füllzeit. NUR EINE SCHÄTZUNG - echte Ingame-Werte variieren
; je nach genau zugewiesenen Kategorien.
; =========================================================================
global BesitztNachtclubWarenlager := false
global NachtclubAusruestungGekauft := false
global NachtclubWarenlagerStartZeit := ""   ; A_Now-Zeitstempel bei Start/letztem Verkauf
global NachtclubWarenlagerRateMitUpgrade := 41000     ; $/Std.
global NachtclubWarenlagerRateOhneUpgrade := 20500    ; $/Std.
global NachtclubWarenlagerMaxWert := 1900000          ; $ voll (brutto)

; "Von-Bis" Werte der herbeigeschafften Waren pro 48 Minuten Loop
global MinWarenProRunde  := 101500  ; Schlechtestes Fracht-Glück + passiver Nachtclub-Zuwachs
global MaxWarenProRunde  := 299500  ; Bestes Fracht-Glück (3er Kisten) + Verkaufs-Bonus & Nachtclub

; Kautionsbüro: 2 Agenten a $5.000-$10.000, reift wie die Ware erst nach 48 Min.
; WICHTIG: Das Schicken selbst kostet nichts (nur Zeit) - bezahlt wird nur
; EINMALIG beim Einstellen der 2 erfahrenen Agenten (kein Rundenkosten-Faktor).
global MinKautionProRunde := 10000
global MaxKautionProRunde := 20000

; =========================================================================
; 📦 KISTEN-TRACKING FÜR DIE LAGERHÄUSER (wird in Datei gespeichert)
; =========================================================================
; Größe & Preis pro Kiste werden im Unternehmens-Setup pro Lager gewählt:
;   Klein (16 Kisten): $15.000/Kiste  |  Mittel (42): $17.500/Kiste
;   Groß (111 Kisten): $20.000/Kiste
; Vorbelegung hier nur als Fallback, bis das Setup läuft.
global MaxKistenLager1 := 16
global MaxKistenLager2 := 111
global MaxKistenLager3 := 111
global MaxKistenLager4 := 111
global MaxKistenLager5 := 111
global PreisProKisteLager1 := 15000
global PreisProKisteLager2 := 20000
global PreisProKisteLager3 := 20000
global PreisProKisteLager4 := 20000
global PreisProKisteLager5 := 20000
global VolleLobbyBonus := 0.5        ; +50% bei voller öffentlicher Lobby (~20 Spieler)
global KistenDateiPfad := A_ScriptDir . "\GTA_Lagerstand.ini"
global KistenLager1 := 0
global KistenLager2 := 0
global KistenLager3 := 0
global KistenLager4 := 0
global KistenLager5 := 0

; FIX: "Ausstehende" Kisten - diese Runde losgeschickt, kommen aber laut
; Spielmechanik erst NÄCHSTE Runde im Lager an (48 Min. Produktionszeit).
global AusstehendLager1 := 0
global AusstehendLager2 := 0
global AusstehendLager3 := 0
global AusstehendLager4 := 0
global AusstehendLager5 := 0
global AusstehendHangar := 0

; --- Luftfracht (Hangar) - eigenes Tracking, andere Werte als die Lagerhäuser ---
; TODO: Keine offizielle Quelle für die Menge pro Mitarbeiter-Durchgang -
; wie bei den Lagern erstmal zufällig 1-3 geschätzt, per Shift+L korrigierbar.
global MaxKistenHangar := 50
global PreisProKisteHangar := 30000   ; Aktueller Wert (seit 3x-Buff) ohne Bonus
global KistenHangar := 0

KombinationsListe() {
    global BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar, BesitztLagerhaus, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, RundenZaehler

    L := []

    ; --- SCHRITT 1: HANDY ÖFFNEN ---
    L.Push(["Oben",    T("handy_oeffnen")])

    ; --- SCHRITT 2: VINEWOOD-APP ÖFFNEN ---
    L.Push(["Rechts",  T("zur_vinewood_navigieren")])
    L.Push(["Enter1",  T("vinewood_oeffnen")])

    ; --- SCHRITT 3: EINKÜNFTE AUS UNTERNEHMEN ABHOLEN ---
    ; WICHTIG: Das Menü zeigt ALLE 7 Kategorien fest an, auch nicht besessene
    ; (die einfach nichts abwerfen) - deshalb IMMER genau ein "Runter" pro
    ; Kategorie, aber "Enter" (abholen) nur wenn tatsächlich besessen.
    ; Reihenfolge im Spiel bestätigt: Nachtclub, Spielhalle, Agentur,
    ; Schrotthandel, Kautionsbüro, Textilfabrik, Hands-On-Waschanlage
    if (BesitztNachtclub || BesitztSpielhalle || BesitztAgentur || BesitztSchrotthandel || BesitztKautionsbuero || BesitztTextilfabrik || BesitztWaschanlage) {
        L.Push(["Enter1", T("einkuenfte_menu_oeffnen")])

        ; [Name (übersetzt), besessen?, Beschreibung fürs Abholen]
        EinkunftsListe := [
            [T("biz_nachtclub"), BesitztNachtclub, TP("einnahmen_abholen", T("biz_nachtclub"))],
            [T("biz_spielhalle"), BesitztSpielhalle, TP("einnahmen_abholen", T("biz_spielhalle"))],
            [T("biz_agentur"), BesitztAgentur, TP("einnahmen_abholen", T("biz_agentur"))],
            [T("biz_schrotthandel"), BesitztSchrotthandel, TP("einnahmen_abholen", T("biz_schrotthandel"))],
            [T("biz_kautionsbuero"), BesitztKautionsbuero, TP("einnahmen_abholen", T("biz_kautionsbuero"))],
            [T("biz_textilfabrik"), BesitztTextilfabrik, TP("einnahmen_abholen", T("biz_textilfabrik"))],
            [T("biz_waschanlage"), BesitztWaschanlage, TP("einnahmen_abholen", T("biz_waschanlage"))]
        ]
        ErsteZeile := true
        for Eintrag in EinkunftsListe {
            Name := Eintrag[1], Besessen := Eintrag[2], AbholText := Eintrag[3]
            if !ErsteZeile
                L.Push(["Unten", TP("zu_x_navigieren", Name)])
            if Besessen
                L.Push(["Enter", AbholText])
            ErsteZeile := false
        }
        L.Push(["Zurück", T("zurueck_hauptmenu")])
    }

    ; --- SCHRITT 4-6: PERSONAL VERWALTEN (Hangar, Lagerhaus, Kautionsbüro-Agenten) ---
    ; WICHTIG: Auch hier vermutlich feste Zeilen für alle 3 Kategorien,
    ; unabhängig vom Besitz - deshalb IMMER ein "Runter" pro Kategorie.
    if (BesitztHangar || BesitztLagerhaus || BesitztKautionsbuero) {
        L.Push(["Oben",   T("zu_personal_navigieren")])
        L.Push(["Enter1", T("personal_menu_oeffnen")])
        ErsteZeile := true

        ; --- Zeile 1: Hangar ---
        if !ErsteZeile
            L.Push(["Unten", T("zum_hangar_navigieren")])
        if BesitztHangar
            L.Push(["Enter", T("hangar_mitarbeiter_losschicken"), "Hangar"])
        ErsteZeile := false

        ; --- Zeile 2: Lagerhaus (öffnet Untermenü mit den tatsächlich
        ; besessenen Lagern - dort bleibt die kompakte Logik, da das echte
        ; Eigentum sind, keine feste Kategorie) ---
        if !ErsteZeile
            L.Push(["Unten", T("zum_lagerhaus_navigieren")])
        if BesitztLagerhaus {
            L.Push(["Enter1", T("lagerhaeuser_menu_oeffnen")])

            ErstesLager := true
            if BesitztLager1 {
                L.Push(["Enter", TP("lagerhaus_n_fracht", 1), "Lager1"])
                ErstesLager := false
            }
            if BesitztLager2 {
                if !ErstesLager
                    L.Push(["Unten", T("zum_naechsten_lagerhaus")])
                L.Push(["Enter", TP("lagerhaus_n_fracht", 2), "Lager2"])
                ErstesLager := false
            }
            if BesitztLager3 {
                if !ErstesLager
                    L.Push(["Unten", T("zum_naechsten_lagerhaus")])
                L.Push(["Enter", TP("lagerhaus_n_fracht", 3), "Lager3"])
                ErstesLager := false
            }
            if BesitztLager4 {
                if !ErstesLager
                    L.Push(["Unten", T("zum_naechsten_lagerhaus")])
                L.Push(["Enter", TP("lagerhaus_n_fracht", 4), "Lager4"])
                ErstesLager := false
            }
            if BesitztLager5 {
                if !ErstesLager
                    L.Push(["Unten", T("zum_naechsten_lagerhaus")])
                L.Push(["Enter", TP("lagerhaus_n_fracht", 5), "Lager5"])
                ErstesLager := false
            }
            L.Push(["Zurück", T("zurueck_personal_liste")])
        }
        ErsteZeile := false

        ; --- Zeile 3: Kautionsbüro-Agenten ---
        if !ErsteZeile
            L.Push(["Unten", T("zum_kautionsbuero_navigieren")])
        if BesitztKautionsbuero {
            L.Push(["Enter1", T("kautionsbuero_menu_oeffnen")])
            L.Push(["Enter", T("agenten_losschicken")])
            L.Push(["Enter", T("auftrag_bestaetigen")])
        }
        ErsteZeile := false
    }

    ; --- SCHRITT 7: VINEWOOD-APP SCHLIESSEN ---
    L.Push(["Zurück", TP("vinewood_schliessen_n", 1)])
    L.Push(["Zurück", TP("vinewood_schliessen_n", 2)])
    L.Push(["Zurück", T("handy_menu_verlassen")])

    return L
}

; =========================================================================
; ⚡ SONDERFRACHT-SCHNELLLISTE (für den optionalen 24-Min-2x-Speed-Modus):
; Navigiert MINIMAL nur zu den Lagerhäusern - überspringt Einkünfte, Hangar
; und Kautionsbüro komplett, um Zeit zu sparen. Genau dieselbe Ziel-Position
; (Lagerhaus-Zeile) wie im vollen Ablauf, nur ohne die anderen Kategorien
; vorher zu besuchen:
;   - Statt Enter1 auf "Einkünfte" wird direkt "Oben" zu "Personal verwalten"
;     navigiert (überspringt die Einkünfte-Kategorie komplett).
;   - Innerhalb von "Personal verwalten" wird die Hangar-Zeile nur mit einem
;     "Unten" übersprungen (kein Enter), direkt weiter zum Lagerhaus.
;   - Nach dem Lagerhaus wird NICHT mehr zum Kautionsbüro weitergegangen -
;     stattdessen direkt geschlossen (3x Zurück, wie im vollen Ablauf auch).
; =========================================================================
SonderfrachtSchnellListe() {
    global BesitztLagerhaus, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5

    L := []
    if !BesitztLagerhaus
        return L

    L.Push(["Oben", T("handy_oeffnen")])
    L.Push(["Rechts", T("zur_vinewood_navigieren")])
    L.Push(["Enter1", T("vinewood_oeffnen")])

    ; Direkt zu "Personal verwalten" - überspringt "Einkünfte" komplett.
    L.Push(["Oben", T("zu_personal_navigieren")])
    L.Push(["Enter1", T("personal_menu_oeffnen")])

    ; Hangar-Zeile nur überspringen (kein Enter), direkt weiter zum Lagerhaus.
    L.Push(["Unten", T("zum_lagerhaus_navigieren")])
    L.Push(["Enter1", T("lagerhaeuser_menu_oeffnen")])

    ErstesLager := true
    if BesitztLager1 {
        L.Push(["Enter", TP("lagerhaus_n_fracht", 1), "Lager1"])
        ErstesLager := false
    }
    if BesitztLager2 {
        if !ErstesLager
            L.Push(["Unten", T("zum_naechsten_lagerhaus")])
        L.Push(["Enter", TP("lagerhaus_n_fracht", 2), "Lager2"])
        ErstesLager := false
    }
    if BesitztLager3 {
        if !ErstesLager
            L.Push(["Unten", T("zum_naechsten_lagerhaus")])
        L.Push(["Enter", TP("lagerhaus_n_fracht", 3), "Lager3"])
        ErstesLager := false
    }
    if BesitztLager4 {
        if !ErstesLager
            L.Push(["Unten", T("zum_naechsten_lagerhaus")])
        L.Push(["Enter", TP("lagerhaus_n_fracht", 4), "Lager4"])
        ErstesLager := false
    }
    if BesitztLager5 {
        if !ErstesLager
            L.Push(["Unten", T("zum_naechsten_lagerhaus")])
        L.Push(["Enter", TP("lagerhaus_n_fracht", 5), "Lager5"])
        ErstesLager := false
    }
    L.Push(["Zurück", T("zurueck_personal_liste")])

    ; Schließen - exakt wie im vollen Ablauf (3x Zurück von derselben Stelle).
    L.Push(["Zurück", TP("vinewood_schliessen_n", 1)])
    L.Push(["Zurück", TP("vinewood_schliessen_n", 2)])
    L.Push(["Zurück", T("handy_menu_verlassen")])

    return L
}

; =========================================================================
; ⚡ SONDERFRACHT-SCHNELLDURCHLAUF: läuft alle 24 Min. (unabhängig vom
; normalen 48-Min-Rundenzyklus, der weiterhin ganz normal daneben läuft),
; NUR wenn per Shift+2 aktiviert. Holt NUR Sonderfracht ab, sonst nichts.
; =========================================================================
SonderfrachtSchnelldurchlauf() {
    global SonderfrachtSchnellModusAktiv, BesitztLagerhaus, AutomationAktiv, AutomatisierungBeschaeftigt

    if !SonderfrachtSchnellModusAktiv
        return
    if !AutomationAktiv {
        ; Automatisierung läuft gerade nicht (pausiert/noch nicht gestartet) -
        ; einfach in 1 Min. erneut prüfen, statt den 24-Min-Takt zu verlieren.
        SetTimer(SonderfrachtSchnelldurchlauf, -60000)
        return
    }
    if !BesitztLagerhaus
        return

    ; FIX: Falls die normale 48-Min-Runde genau jetzt aktiv Tasten sendet,
    ; kurz warten und in 2 Min. erneut versuchen - niemals gleichzeitig
    ; Tasten aus zwei Quellen senden.
    if AutomatisierungBeschaeftigt {
        SetTimer(SonderfrachtSchnelldurchlauf, -120000)
        return
    }

    Liste := SonderfrachtSchnellListe()
    if (Liste.Length = 0)
        return

    ; FIX: Genau wie beim vollen Rundenablauf - AntiAFK/Countdown-Anzeige
    ; kurz pausieren, damit sich keine Tasten mit dem Schnelldurchlauf
    ; überschneiden, danach wieder aktivieren (die normale 48-Min-Wartezeit
    ; läuft ja parallel unbeeinflusst im Hintergrund weiter).
    SetTimer(AntiAFK, 0)
    SetTimer(CountdownTicker, 0)

    Ergebnis := FuehreListeAus(Liste, T("sonderfracht_schnell_laeuft"))
    if (Ergebnis["vorheriges"] != "" && WinExist(Ergebnis["vorheriges"]))
        WinActivate(Ergebnis["vorheriges"])

    SetTimer(CountdownTicker, 1000)
    SetTimer(AntiAFK, 8000)

    ; Nächsten Schnelldurchlauf in 24 Min. einplanen, solange der Modus noch
    ; aktiv ist (falls inzwischen per Shift+2 deaktiviert, nicht neu planen).
    if SonderfrachtSchnellModusAktiv
        SetTimer(SonderfrachtSchnelldurchlauf, -(24 * 60000))

    UpdateDashboard(T("bereit"))
}



global RundenZaehler := 0
global TotalKosten := 0
global TotalSafeEinnahmen := 0
global TotalWarenMin := 0
global TotalWarenMax := 0
global TotalKautionMin := 0
global TotalKautionMax := 0
global StartZeit := 0
global AutomationAktiv := false
global ZielRundenAnzahl := 0  ; 0 = kein automatisches Herunterfahren
global RundenIntervallMinuten := 48  ; Standard 48 Min - bei 2x-Speed-Events (z.B. Sonderfracht) auf 24 stellbar
global WarenbestandBekannt := true  ; false = Nutzer wollte Kisten nicht eingeben
global AktuellerFlavorText := ""    ; zufälliger Warte-Text, siehe WaehleFlavorText()

; =========================================================================
; 📢 EVENT-BONI (experimentell): Best-Effort-Abruf der aktuellen wöchentlichen
; GTA$-Boni von gtabase.com (keine offizielle API - falls die Website ihre
; Struktur ändert, zeigt das Dashboard einfach eine Fehlermeldung statt
; falscher Daten). Nur zur Info, fließt NICHT in Gewinnberechnungen ein.
; =========================================================================
global EventBoniListe := []
global EventBoniLetzteAktualisierung := ""
global EventBoniFehler := ""
global EventBoniQuelleUrl := "https://www.gtabase.com/gta-online/weekly-update-bonuses-discounts"

; FIX: MUSS vor LadeKistenstand() stehen, sonst würde die spätere
; Deklaration den von dort geladenen 2x-Speed-Zustand direkt wieder
; überschreiben (Zuweisungen in der Auto-Ausführungs-Reihenfolge gewinnen).
global SonderfrachtSchnellModusAktiv := false  ; 2x-Speed: Sonderfracht alle 24 statt 48 Min. abholen

; FIX: Erst den zuletzt gespeicherten Stand laden (Unternehmen, Lager,
; 2x-Speed-Zustand etc.), DANACH das Komplett-Setup zeigen - so ist alles
; von Anfang an mit dem letzten Stand vorausgewählt, statt immer wieder bei
; Null anzufangen.
LadeKistenstand()

; FIX: EIN einziges Setup-Fenster ganz am Anfang statt vieler Fenster
; nacheinander (Sprache, Farbe, Unternehmen, Auto-Shutdown - alles in einem).
ZeigeKomplettSetup()

; FIX: WS_EX_TRANSPARENT (0x20) allein reicht oft nicht - erst zusammen mit
; WS_EX_LAYERED (0x80000) wird das Fenster wirklich komplett klickdurchlässig,
; auch beim reinen Drüberstreichen mit der Maus (kein Hover-Abfangen mehr).
global InfoGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020")
InfoGui.BackColor := "0A0A0F"
InfoGui.MarginX := 12
InfoGui.MarginY := 8

; FIX: Komplett manuell durchgerechnete Koordinaten (kein GetPos() mehr) -
; GetPos() lieferte auf manchen Systemen falsche/verschobene Werte, was die
; Spezialfracht-Karte weit nach rechts verschoben hat. Ein einziger, selbst
; mitgeführter Y-Zähler ist zuverlässig und immer nachvollziehbar.
KartenX := 12
KartenBreite := 900
CursorY := 8

; --- Titel + Branding in einer Zeile ---
InfoGui.SetFont("s12 Bold", "Consolas")
global TitelCtrl := InfoGui.Add("Text", "cFFFFFF x" . KartenX . " y" . CursorY, T("dash_titel"))
InfoGui.SetFont("s8 Bold", "Consolas")
global BrandingCtrl := InfoGui.Add("Text", "c00E5FF x" . (KartenX + 300) . " y" . (CursorY + 4), "by Enzyy — v6.2")

; 🕐 Digitale Live-Uhr oben rechts (LED-Stil, tickt unabhängig von der
; Automatisierung jede Sekunde).
InfoGui.SetFont("s16 Bold", "Consolas")
global UhrzeitCtrl := InfoGui.Add("Text", "c00FF00 x" . (KartenX + 800) . " y" . (CursorY - 4) . " w110 Right", FormatTime(A_Now, "HH:mm:ss"))
UhrzeitTicker() {
    global UhrzeitCtrl
    UhrzeitCtrl.Value := FormatTime(A_Now, "HH:mm:ss")
}
SetTimer(UhrzeitTicker, 1000)

CursorY += 26

; 🌈 Nur zum Spaß: "Enzyy" wechselt im Regenbogen die Farbe
RegenbogenFarben := ["FF0000", "FF7F00", "FFFF00", "00FF00", "0000FF", "4B0082", "9400D3"]
RegenbogenIndex := 0
RegenbogenTick() {
    global BrandingCtrl, RegenbogenFarben, RegenbogenIndex
    RegenbogenIndex := Mod(RegenbogenIndex + 1, RegenbogenFarben.Length)
    BrandingCtrl.SetFont("c" . RegenbogenFarben[RegenbogenIndex + 1])
}
SetTimer(RegenbogenTick, 400)

; --- WARNHINWEIS (kompakt, 1 Zeile) ---
InfoGui.SetFont("s9 Bold", "Consolas")
global WarnhinweisCtrl := InfoGui.Add("Text", "cFF5555 x" . KartenX . " y" . CursorY . " w" . KartenBreite . " r1", T("dash_warnung"))
CursorY += 18

; --- Steuerung (kompakt, 2 Zeilen erlaubt - der Hotkey-Text ist inzwischen
; recht lang) - bleibt IMMER sichtbar, auch wenn Shift+H das restliche
; Dashboard versteckt, damit du die Hotkeys nie vergisst. ---
InfoGui.SetFont("s9 Norm", "Consolas")
global SteuerungCtrl := InfoGui.Add("Text", "cAAAAAA x" . KartenX . " y" . CursorY . " w" . KartenBreite . " r2", T("dash_steuerung"))
CursorY += 36

; Dezente Trennlinie zwischen Header und den Karten darunter
InfoGui.Add("Text", "x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h1 0x10")
CursorY += 10

; =========================================================================
; 💰 KARTE: GESAMTGEWINN
; =========================================================================
global GewinnBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h58", T("karte_gewinn"))
global GewinnStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h56 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s16 Bold", "Consolas")
global ProfitGrossCtrl := InfoGui.Add("Text", "c00FF88 x" . (KartenX + 15) . " y" . (CursorY + 18) . " w870", "$0 – $0")
InfoGui.SetFont("s9 Norm", "Consolas")
global ProfitDetailCtrl := InfoGui.Add("Text", "cCCCCCC x" . (KartenX + 15) . " y" . (CursorY + 40) . " w870 r1", T("gewinn_std_wird_berechnet"))
CursorY += 58 + 8

; =========================================================================
; 📡 KARTE: STATUS + COUNTDOWN
; =========================================================================
global StatusBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h90", T("karte_status"))
global StatusStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h88 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s10 Bold", "Consolas")
global StatusCtrl := InfoGui.Add("Text", "cFFAA00 x" . (KartenX + 15) . " y" . (CursorY + 16) . " w870 r2", T("bereit"))
global CountdownBarCtrl := InfoGui.Add("Progress", "x" . (KartenX + 15) . " y" . (CursorY + 47) . " w870 h12 c00FF00 Background333333", 0)
InfoGui.SetFont("s8 Norm", "Consolas")
global CountdownTextCtrl := InfoGui.Add("Text", "cAAAAAA x" . (KartenX + 15) . " y" . (CursorY + 61) . " w870", "")
global ShutdownInfoCtrl := InfoGui.Add("Text", "cAAAAAA x" . (KartenX + 15) . " y" . (CursorY + 75) . " w870", T("auto_shutdown_deaktiviert"))
CursorY += 90 + 8

; =========================================================================
; 📊 KARTE: FINANZEN
; =========================================================================
global FinanzenBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h96", T("karte_finanzen"))
global FinanzenStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h94 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s9 Norm", "Consolas")
global RundeCtrl := InfoGui.Add("Text", "cDDDDDD x" . (KartenX + 15) . " y" . (CursorY + 18) . " w870", T("runde_label") . ": 0")
global AfkZeitCtrl := InfoGui.Add("Text", "cDDDDDD x" . (KartenX + 15) . " y" . (CursorY + 33) . " w870", T("gesamte_afk_zeit_label") . ": 0:00:00 " . T("std_kurz"))
global KostenCtrl := InfoGui.Add("Text", "cFF7777 x" . (KartenX + 15) . " y" . (CursorY + 48) . " w870", T("mitarbeiter_kosten_label") . ": $0")
global EinnahmenCtrl := InfoGui.Add("Text", "c77FF77 x" . (KartenX + 15) . " y" . (CursorY + 63) . " w870", T("bar_geld_label") . ": $0")
global WarenwertCtrl := InfoGui.Add("Text", "c77FF77 x" . (KartenX + 15) . " y" . (CursorY + 78) . " w870", "")
CursorY += 96 + 8

; =========================================================================
; 🎵 KARTE: NACHTCLUB-BELIEBTHEIT (nur sichtbar falls besessen)
; =========================================================================
global NachtclubBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h44", T("karte_nachtclub"))
global NachtclubStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h42 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s9 Bold", "Consolas")
global NCBarCtrl := InfoGui.Add("Progress", "x" . (KartenX + 15) . " y" . (CursorY + 17) . " w770 h16 c00FF00 Background333333", 0)
global NCPercentCtrl := InfoGui.Add("Text", "cDDDDDD x" . (KartenX + 793) . " y" . (CursorY + 18) . " w90", "0%")
CursorY += 44 + 8

; =========================================================================
; 🎚️ KARTE: NACHTCLUB-WARENLAGER (Techniker, läuft in Echtzeit - nur
; sichtbar falls aktiviert). Schätzung, keine exakten Ingame-Werte.
; =========================================================================
global WarenlagerBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h58", T("karte_warenlager"))
global WarenlagerStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h56 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s9 Bold", "Consolas")
global WarenlagerBarCtrl := InfoGui.Add("Progress", "x" . (KartenX + 15) . " y" . (CursorY + 17) . " w770 h16 c" . AkzentFarbe . " Background333333", 0)
global WarenlagerPercentCtrl := InfoGui.Add("Text", "cDDDDDD x" . (KartenX + 793) . " y" . (CursorY + 18) . " w90", "0%")
InfoGui.SetFont("s9 Norm", "Consolas")
global WarenlagerInfoCtrl := InfoGui.Add("Text", "cAAAAAA x" . (KartenX + 15) . " y" . (CursorY + 38) . " w870", T("warenlager_hinweis"))
CursorY += 58 + 8

; =========================================================================
; 📢 KARTE: EVENT-BONI DIESE WOCHE (experimentell, Best-Effort-Abruf)
; =========================================================================
global EventBoniBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . KartenX . " y" . CursorY . " w" . KartenBreite . " h74", T("karte_eventboni"))
global EventBoniStreifen := InfoGui.Add("Progress", "x" . KartenX . " y" . (CursorY + 1) . " w4 h72 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InfoGui.SetFont("s9 Norm", "Consolas")
global EventBoniTextCtrl := InfoGui.Add("Text", "cDDDDDD x" . (KartenX + 15) . " y" . (CursorY + 17) . " w870 r3", T("eventboni_laedt"))
InfoGui.SetFont("s8 Norm", "Consolas")
global EventBoniStatusCtrl := InfoGui.Add("Text", "cAAAAAA x" . (KartenX + 15) . " y" . (CursorY + 56) . " w870", "")
CursorY += 74 + 8

; =========================================================================
; 📦 KARTE: SPEZIALFRACHT & HANGAR (nur besessene Zeilen sichtbar, dynamisch gepackt)
; =========================================================================
global LagerBoxX := KartenX
global LagerBoxY := CursorY
global LagerBox := InfoGui.Add("GroupBox", "c" . AkzentFarbe . " x" . LagerBoxX . " y" . LagerBoxY . " w" . KartenBreite . " h195", T("karte_lager"))
global LagerStreifen := InfoGui.Add("Progress", "x" . LagerBoxX . " y" . (LagerBoxY + 1) . " w4 h193 c" . AkzentFarbe . " Background" . AkzentFarbe, 100)
InnenX := LagerBoxX + 15
BarX := LagerBoxX + 150
WertX := LagerBoxX + 510
ZeileY := LagerBoxY + 17
ZeilenHoehe := 19

InfoGui.SetFont("s8 Bold", "Consolas")
global Lager1Label := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("spezialfracht_kurz") . " 1:")
global Lager1Bar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 c" . AkzentFarbe . " Background333333", 0)
global Lager1Wert := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe

global Lager2Label := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("spezialfracht_kurz") . " 2:")
global Lager2Bar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 c" . AkzentFarbe . " Background333333", 0)
global Lager2Wert := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe

global Lager3Label := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("spezialfracht_kurz") . " 3:")
global Lager3Bar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 c" . AkzentFarbe . " Background333333", 0)
global Lager3Wert := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe

global Lager4Label := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("spezialfracht_kurz") . " 4:")
global Lager4Bar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 c" . AkzentFarbe . " Background333333", 0)
global Lager4Wert := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe

global Lager5Label := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("spezialfracht_kurz") . " 5:")
global Lager5Bar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 c" . AkzentFarbe . " Background333333", 0)
global Lager5Wert := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe

global HangarLabel := InfoGui.Add("Text", "cDDDDDD x" . InnenX . " y" . ZeileY . " w130", T("hangar_label") . ":")
global HangarBar := InfoGui.Add("Progress", "x" . BarX . " y" . (ZeileY - 2) . " w350 h14 cFFA500 Background333333", 0)
global HangarWertCtrl := InfoGui.Add("Text", "cDDDDDD x" . WertX . " y" . ZeileY . " w380", "")
ZeileY += ZeilenHoehe + 4

InfoGui.SetFont("s9 Bold", "Consolas")
global GesamtwarenwertCtrl := InfoGui.Add("Text", "c77FF77 x" . InnenX . " y" . ZeileY . " w870", "")

; FIX: Fenster sofort beim Skriptstart anzeigen (nicht erst nach Shift+P),
; damit du sofort siehst, ob das Overlay grundsätzlich sichtbar ist.
InfoGui.Show("AutoSize xCenter y20 NoActivate")

; FIX: WS_EX_LAYERED-Fenster brauchen eine explizit gesetzte Deckkraft, sonst
; können sie unsichtbar bleiben. Statt hart auf 255 zu springen, sanft von
; 0 einblenden - netter erster Eindruck beim Start.
WinSetTransparent(0, "ahk_id " . InfoGui.Hwnd)
FadeUebergang(0, 255)

global DashboardSichtbar := true
global AutomatisierungBeschaeftigt := false
global UpdateVerfuegbarVersion := ""

; Steuerungszeile mit dem im Setup-Fenster festgelegten Zustand aktualisieren
; (Kistenstand wurde schon ganz am Anfang vor dem Setup-Fenster geladen).
; FIX: Erst NACH den obigen Variablen-Initialisierungen aufrufen, sonst
; "nicht zugewiesen"-Fehler beim Lesen von UpdateVerfuegbarVersion.
AktualisiereSteuerungszeile()

; FIX: Direkt einmal aktualisieren (nicht erst beim ersten Shift+P) - sonst
; bleiben Karten (z.B. Spezialfracht & Hangar), die erst durch UpdateDashboard()
; dynamisch verkleinert werden, bis zum ersten Start auf ihrer vollen
; Platzhalter-Höhe stehen und es sieht unnötig leer/groß aus.
UpdateDashboard(T("bereit"))

; Event-Boni leicht verzögert abrufen (1 Sek.), damit das Dashboard zuerst
; sichtbar ist, bevor der Netzwerkaufruf kurz blockiert.
SetTimer(ErstAbrufEventBoni, -1000)
ErstAbrufEventBoni() {
    AbrufeEventBoni()
    AktualisiereEventBoniAnzeige()
}

; Auto-Update-Prüfung leicht verzögert (2 Sek.) beim Start - nur falls in
; den Zeilen oben konfiguriert (siehe Kommentar bei AutoUpdateAktiviert).
SetTimer(() => PrüfeAufUpdate(false), -2000)

; FIX: Zusätzlich alle 30 Minuten WIEDERHOLT prüfen - das Skript läuft ja
; oft stundenlang durch, ein einmaliger Check beim Start würde ein Update
; verpassen, das erst später veröffentlicht wird.
SetTimer(() => PrüfeAufUpdate(false), 1800000)

+p::StartAutomation()
+o::PauseAutomation()
+h::DashboardUmschalten()

; =========================================================================
; 👁️ Shift+H: Dashboard komplett ein-/ausblenden (z.B. für Screenshot/Stream).
; Im ausgeblendeten Zustand bleiben sichtbar: die Steuerungs-Hinweiszeile,
; das Regenbogen-Branding, sowie AFK-Zeit + Shutdown-Info (rücken direkt
; unter die Steuerungszeile hoch).
; =========================================================================
; =========================================================================
; ✨ Sanfte Fade-Überblendung (statt hartem Sprung) - animiert die
; Fenster-Transparenz in kleinen Schritten. Wird bei Shift+H und beim
; ersten Erscheinen des Dashboards genutzt.
; =========================================================================
FadeUebergang(VonAlpha, ZuAlpha, DauerMs := 140) {
    global InfoGui
    Schritte := 8
    Delta := (ZuAlpha - VonAlpha) / Schritte
    SleepZeit := Round(DauerMs / Schritte)
    Loop Schritte {
        WinSetTransparent(Round(VonAlpha + Delta * A_Index), "ahk_id " . InfoGui.Hwnd)
        Sleep(SleepZeit)
    }
    WinSetTransparent(ZuAlpha, "ahk_id " . InfoGui.Hwnd)
}

; ✨ Kurzer Bestätigungs-Puls (z.B. nach Shift+V/Shift+B) - kurzes Aufblitzen,
; damit klar ist, dass die Aktion angekommen ist, auch ohne den Text zu lesen.
BestaetigungsBlitz() {
    FadeUebergang(255, 150, 60)
    FadeUebergang(150, 255, 60)
}

DashboardUmschalten() {
    global DashboardSichtbar, InfoGui, TitelCtrl, BrandingCtrl, WarnhinweisCtrl, SteuerungCtrl
    global GewinnBox, GewinnStreifen, ProfitGrossCtrl, ProfitDetailCtrl
    global StatusBox, StatusStreifen, StatusCtrl, CountdownBarCtrl, CountdownTextCtrl, ShutdownInfoCtrl
    global FinanzenBox, FinanzenStreifen, RundeCtrl, AfkZeitCtrl, KostenCtrl, EinnahmenCtrl, WarenwertCtrl
    global NachtclubBox, NachtclubStreifen, NCBarCtrl, NCPercentCtrl
    global WarenlagerBox, WarenlagerStreifen, WarenlagerBarCtrl, WarenlagerPercentCtrl, WarenlagerInfoCtrl
    global LagerBox, LagerStreifen, Lager1Label, Lager1Bar, Lager1Wert, Lager2Label, Lager2Bar, Lager2Wert, Lager3Label, Lager3Bar, Lager3Wert, Lager4Label, Lager4Bar, Lager4Wert, Lager5Label, Lager5Bar, Lager5Wert, HangarLabel, HangarBar, HangarWertCtrl, GesamtwarenwertCtrl
    global EventBoniBox, EventBoniStreifen, EventBoniTextCtrl, EventBoniStatusCtrl
    ; FIX: Ursprungsposition von AFK-Zeit/Shutdown-Info EINMALIG merken
    ; (static - bleibt über mehrere Aufrufe hinweg erhalten), damit sie beim
    ; Wieder-Einblenden exakt an ihren normalen Platz zurückkehren.
    static AfkZeitOrigX := 0, AfkZeitOrigY := 0, ShutdownOrigX := 0, ShutdownOrigY := 0, PositionGemerkt := false
    if !PositionGemerkt {
        AfkZeitCtrl.GetPos(&AfkZeitOrigX, &AfkZeitOrigY)
        ShutdownInfoCtrl.GetPos(&ShutdownOrigX, &ShutdownOrigY)
        PositionGemerkt := true
    }

    DashboardSichtbar := !DashboardSichtbar

    ; Erst sanft ausblenden, BEVOR die Inhalte umgeschaltet werden - so sieht
    ; man keinen harten Sprung, sondern die alte Ansicht verblasst.
    FadeUebergang(255, 25)

    if DashboardSichtbar {
        ; Wieder einblenden - ALLE "immer sichtbaren" Karten explizit
        ; zurücksetzen (FIX: das fehlte bisher!), dann UpdateDashboard() für
        ; den Rest (ownership-abhängige Karten wie Nachtclub/Lager).
        TitelCtrl.Visible := true
        WarnhinweisCtrl.Visible := true
        GewinnBox.Visible := true
        GewinnStreifen.Visible := true
        ProfitGrossCtrl.Visible := true
        ProfitDetailCtrl.Visible := true
        StatusBox.Visible := true
        StatusStreifen.Visible := true
        StatusCtrl.Visible := true
        CountdownBarCtrl.Visible := true
        CountdownTextCtrl.Visible := true
        FinanzenBox.Visible := true
        FinanzenStreifen.Visible := true
        RundeCtrl.Visible := true
        KostenCtrl.Visible := true
        EinnahmenCtrl.Visible := true
        WarenwertCtrl.Visible := true
        EventBoniBox.Visible := true
        EventBoniStreifen.Visible := true
        EventBoniTextCtrl.Visible := true
        EventBoniStatusCtrl.Visible := true
        AfkZeitCtrl.Move(AfkZeitOrigX, AfkZeitOrigY)
        ShutdownInfoCtrl.Move(ShutdownOrigX, ShutdownOrigY)
        UpdateDashboard(T("dashboard_wieder_eingeblendet"))
        FadeUebergang(25, 255)
        return
    }

    TitelCtrl.Visible := false
    WarnhinweisCtrl.Visible := false
    GewinnBox.Visible := false
    GewinnStreifen.Visible := false
    ProfitGrossCtrl.Visible := false
    ProfitDetailCtrl.Visible := false
    StatusBox.Visible := false
    StatusStreifen.Visible := false
    StatusCtrl.Visible := false
    CountdownBarCtrl.Visible := false
    CountdownTextCtrl.Visible := false
    FinanzenBox.Visible := false
    FinanzenStreifen.Visible := false
    RundeCtrl.Visible := false
    KostenCtrl.Visible := false
    EinnahmenCtrl.Visible := false
    WarenwertCtrl.Visible := false
    EventBoniBox.Visible := false
    EventBoniStreifen.Visible := false
    EventBoniTextCtrl.Visible := false
    EventBoniStatusCtrl.Visible := false
    NachtclubBox.Visible := false
    NachtclubStreifen.Visible := false
    NCBarCtrl.Visible := false
    NCPercentCtrl.Visible := false
    WarenlagerBox.Visible := false
    WarenlagerStreifen.Visible := false
    WarenlagerBarCtrl.Visible := false
    WarenlagerPercentCtrl.Visible := false
    WarenlagerInfoCtrl.Visible := false
    LagerBox.Visible := false
    LagerStreifen.Visible := false
    Lager1Label.Visible := false, Lager1Bar.Visible := false, Lager1Wert.Visible := false
    Lager2Label.Visible := false, Lager2Bar.Visible := false, Lager2Wert.Visible := false
    Lager3Label.Visible := false, Lager3Bar.Visible := false, Lager3Wert.Visible := false
    Lager4Label.Visible := false, Lager4Bar.Visible := false, Lager4Wert.Visible := false
    Lager5Label.Visible := false, Lager5Bar.Visible := false, Lager5Wert.Visible := false
    HangarLabel.Visible := false, HangarBar.Visible := false, HangarWertCtrl.Visible := false
    GesamtwarenwertCtrl.Visible := false

    ; AFK-Zeit + Shutdown-Info bleiben sichtbar und rücken direkt unter die
    ; Steuerungszeile, statt an ihrer ursprünglichen (jetzt leeren) Stelle
    ; weit unten zu hängen. (Steuerungszeile ist jetzt 2 Zeilen hoch.)
    SteuerungCtrl.GetPos(&SX, &SY)
    AfkZeitCtrl.Move(SX, SY + 36)
    ShutdownInfoCtrl.Move(SX, SY + 54)

    InfoGui.Show("AutoSize xCenter y20 NoActivate")
    FadeUebergang(25, 255)
}

; =========================================================================
; 🎨 EIGENE DIALOG-FENSTER (dunkles Theme, immer im Vordergrund, zentriert)
; Ersetzen die hässlichen Standard-Windows-MsgBox/InputBox-Fenster, die
; teilweise hinter dem Spiel/Skript-Fenster gespawnt sind.
; =========================================================================
; =========================================================================
; 🏁 KOMPLETT-SETUP: EIN einziges Fenster für Sprache, Akzentfarbe,
; Unternehmen, Sonderfracht-Lagerhäuser, Nachtclub-Warenlager UND Auto-
; Shutdown-Rundenanzahl - ersetzt die früheren 4 separaten Fenster
; (Sprachauswahl, Farbauswahl, Unternehmens-Setup, Runden-Eingabe), die
; nacheinander aufploppten. Ändert sich Sprache oder Farbe, wird das
; Fenster einmal neu aufgebaut (kurzes Aufblitzen), damit der Rest des
; Textes sofort in der neuen Sprache/Farbe erscheint - alle bereits
; getroffenen Auswahlen bleiben dabei erhalten.
; =========================================================================
ZeigeKomplettSetup() {
    global Sprache, AkzentFarbe
    global BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar
    global BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, BesitztLagerhaus
    global MaxKistenLager1, MaxKistenLager2, MaxKistenLager3, MaxKistenLager4, MaxKistenLager5
    global PreisProKisteLager1, PreisProKisteLager2, PreisProKisteLager3, PreisProKisteLager4, PreisProKisteLager5
    global BesitztNachtclubWarenlager, NachtclubAusruestungGekauft, NachtclubWarenlagerStartZeit
    global ZielRundenAnzahl, RundenIntervallMinuten

    ; FIX: Aktuelle Lager-Größe (1-4) aus den bereits geladenen Max-Werten
    ; ableiten, damit das Dropdown beim Neu-Aufbau (oder bei wiederholtem
    ; Start) den zuletzt gewählten Zustand vorausgewählt zeigt statt immer
    ; bei "Nicht vorhanden" zu starten.
    LagerIndexAusMax(Besitzt, Max) {
        if !Besitzt
            return 1
        if (Max = 16)
            return 2
        if (Max = 42)
            return 3
        return 4
    }

    ; Diese Werte überleben einen Neuaufbau (bei Sprach-/Farbwechsel), weil
    ; sie als "static" deklariert sind - beim ALLERERSTEN Aufruf mit dem
    ; zuletzt gespeicherten Zustand vorbefüllt (siehe unten).
    static Init := false
    static AuswahlBusiness := []
    static AuswahlLager := []
    static AuswahlWarenlager := 1
    static AuswahlAusruestung := 1
    static AuswahlRunden := 0
    if !Init {
        AuswahlBusiness := [BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar]
        AuswahlBusiness := [BesitztNachtclub?1:2, BesitztSpielhalle?1:2, BesitztAgentur?1:2, BesitztSchrotthandel?1:2, BesitztKautionsbuero?1:2, BesitztTextilfabrik?1:2, BesitztWaschanlage?1:2, BesitztHangar?1:2]
        AuswahlLager := [LagerIndexAusMax(BesitztLager1, MaxKistenLager1), LagerIndexAusMax(BesitztLager2, MaxKistenLager2), LagerIndexAusMax(BesitztLager3, MaxKistenLager3), LagerIndexAusMax(BesitztLager4, MaxKistenLager4), LagerIndexAusMax(BesitztLager5, MaxKistenLager5)]
        AuswahlWarenlager := BesitztNachtclubWarenlager ? 1 : 2
        AuswahlAusruestung := NachtclubAusruestungGekauft ? 1 : 2
        AuswahlRunden := ZielRundenAnzahl
        Init := true
    }

    NeuAufbauNoetig := true
    while NeuAufbauNoetig {
        NeuAufbauNoetig := false

        JaNein := [T("ja"), T("nein")]
        LagerOptionen := [T("lager_keins"), T("lager_klein"), T("lager_mittel"), T("lager_gross")]
        BusinessNamen := (Sprache = "DE")
            ? ["Nachtclub", "Spielhalle (Arcade)", "Agentur", "Schrotthandel", "Kautionsbüro", "Textilfabrik", "Hands-On-Waschanlage", "Hangar"]
            : ["Nightclub", "Arcade", "Agency", "Salvage Yard", "Bail Office", "Textile Factory", "Hands-On Car Wash", "Hangar"]
        Farben := [
            ["00E5FF", (Sprache = "DE") ? "Neon-Blau" : "Neon Blue"],
            ["00FF88", (Sprache = "DE") ? "Grün" : "Green"],
            ["FF00CC", "Pink"],
            ["FF7700", "Orange"],
            ["FF3333", (Sprache = "DE") ? "Rot" : "Red"],
            ["B366FF", (Sprache = "DE") ? "Lila" : "Purple"],
            ["FFEE00", (Sprache = "DE") ? "Gelb" : "Yellow"],
            ["FFFFFF", (Sprache = "DE") ? "Weiß" : "White"]
        ]

        SDlg := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "GTA Business Automation - Setup")
        SDlg.BackColor := "111111"
        SDlg.MarginX := 24
        SDlg.MarginY := 20

        InhaltX := 24
        InhaltBreite := 912
        SpalteLinksX := InhaltX
        SpalteRechtsX := InhaltX + 470
        CY := 20

        SDlg.SetFont("s16 Bold", "Consolas")
        SDlg.Add("Text", "cFFFFFF x" . InhaltX . " y" . CY . " w" . InhaltBreite, "🏁 GTA Business Automation")
        CY += 30
        SDlg.Add("Progress", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h4 c" . AkzentFarbe . " Background1A1A1A -Smooth", 100)
        CY += 20

        ; --- Sprache ---
        SDlg.SetFont("s10 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . InhaltX . " y" . (CY + 8) . " w110", "🌐 Sprache:")
        SDlg.SetFont("s10 Norm", "Consolas")
        BtnDE := SDlg.Add("Button", "x" . (InhaltX + 115) . " y" . CY . " w110 h30" . (Sprache = "DE" ? " Default" : ""), "🇩🇪 Deutsch")
        BtnEN := SDlg.Add("Button", "x+10 y" . CY . " w110 h30" . (Sprache = "EN" ? " Default" : ""), "🇬🇧 English")
        CY += 42

        ; --- Akzentfarbe (kompakte Reihe aus 8 farbigen Quadraten) ---
        SDlg.SetFont("s10 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . InhaltX . " y" . (CY + 8) . " w110", T("farbauswahl_titel"))
        FarbButtons := []
        FX := InhaltX + 115
        for Eintrag in Farben {
            Hex := Eintrag[1]
            Swatch := SDlg.Add("Text", "+0x100 x" . FX . " y" . CY . " w28 h28 Background" . Hex, "")
            if (Hex = AkzentFarbe)
                SDlg.Add("Text", "x" . FX . " y" . CY . " w28 h28 cFFFFFF Center", "✓")
            FarbButtons.Push([Swatch, Hex])
            FX += 36
        }
        CY += 44

        ; --- Trennlinie ---
        SDlg.Add("Text", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h1 0x10")
        CY += 14

        ; --- Unternehmen + Lagerhäuser (2-Spalten-Grid) ---
        SDlg.SetFont("s11 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . SpalteLinksX . " y" . CY . " w400", T("spalte_unternehmen"))
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . SpalteRechtsX . " y" . CY . " w400", T("spalte_lager"))
        CY += 26

        ReihenStartY := CY
        ReihenHoehe := 32

        DDBusiness := []
        SDlg.SetFont("s9 Norm", "Consolas")
        Loop 8 {
            RY := ReihenStartY + (A_Index - 1) * ReihenHoehe
            SDlg.Add("Text", "cDDDDDD x" . SpalteLinksX . " y" . (RY + 4) . " w170", BusinessNamen[A_Index] . ":")
            DD := SDlg.Add("DropDownList", "x" . (SpalteLinksX + 175) . " y" . RY . " w195 Choose" . AuswahlBusiness[A_Index], JaNein)
            DDBusiness.Push(DD)
        }

        DDLager := []
        Loop 5 {
            RY := ReihenStartY + (A_Index - 1) * ReihenHoehe
            SDlg.Add("Text", "cDDDDDD x" . SpalteRechtsX . " y" . (RY + 4) . " w100", T("kisten_lager") . " " . A_Index . ":")
            DD := SDlg.Add("DropDownList", "x" . (SpalteRechtsX + 105) . " y" . RY . " w345 Choose" . AuswahlLager[A_Index], LagerOptionen)
            DDLager.Push(DD)
        }

        ; Nachtclub-Warenlager - 2 Zeilen unter den Lagern
        RY := ReihenStartY + 5 * ReihenHoehe + 8
        SDlg.SetFont("s9 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . SpalteRechtsX . " y" . RY . " w400", T("warenlager_ueberschrift"))
        RY += 22
        SDlg.SetFont("s9 Norm", "Consolas")
        SDlg.Add("Text", "cDDDDDD x" . SpalteRechtsX . " y" . (RY + 4) . " w340", T("techniker_frage"))
        DDWarenlager := SDlg.Add("DropDownList", "x" . (SpalteRechtsX + 350) . " y" . RY . " w100 Choose" . AuswahlWarenlager, JaNein)
        RY += ReihenHoehe
        SDlg.Add("Text", "cDDDDDD x" . SpalteRechtsX . " y" . (RY + 4) . " w340", T("ausruestung_frage"))
        DDAusruestung := SDlg.Add("DropDownList", "x" . (SpalteRechtsX + 350) . " y" . RY . " w100 Choose" . AuswahlAusruestung, JaNein)

        CY := ReihenStartY + 8 * ReihenHoehe + 12

        ; --- Trennlinie ---
        SDlg.Add("Text", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h1 0x10")
        CY += 14

        ; --- Auto-Shutdown ---
        SDlg.SetFont("s11 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . InhaltX . " y" . CY . " w" . InhaltBreite, T("autoshutdown_titel"))
        CY += 24
        SDlg.SetFont("s9 Norm", "Consolas")
        SDlg.Add("Text", "cCCCCCC x" . InhaltX . " y" . CY . " w" . InhaltBreite . " r2", T("autoshutdown_frage"))
        CY += 34

        SDlg.SetFont("s12 Norm", "Consolas")
        EF := SDlg.Add("Edit", "x" . InhaltX . " y" . CY . " w300 h28 cFFFFFF Background2A2A2A -E0x200", AuswahlRunden)
        SDlg.SetFont("s10 Bold", "Consolas")
        ZeitAnzeige := SDlg.Add("Text", "c00FF88 x+15 yp+4 w550 r2", T("autoshutdown_deaktiviert_live"))

        Umrechnen(*) {
            Runden := Integer(IsNumber(EF.Value) ? EF.Value : 0)
            VorausStunden := Floor(Runden * RundenIntervallMinuten / 60)
            VorausMinuten := Mod(Runden * RundenIntervallMinuten, 60)
            ShutdownUhrzeit := FormatTime(DateAdd(A_Now, Runden * RundenIntervallMinuten, "Minutes"), "HH:mm")
            ZeitAnzeige.Value := (Runden > 0) ? TPn("autoshutdown_voraussichtlich", VorausStunden, VorausMinuten, ShutdownUhrzeit) : T("autoshutdown_deaktiviert_live")
        }
        EF.OnEvent("Change", Umrechnen)
        Umrechnen()
        CY += 46

        ; --- Fertig-Button ---
        SDlg.SetFont("s12 Bold", "Consolas")
        BtnFertig := SDlg.Add("Button", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h48 Default", "✓  " . T("btn_uebernehmen"))

        ; --- Klick-Handler ---
        SpracheWechseln(NeueSprache, *) {
            AuswahlBusiness := [DDBusiness[1].Value, DDBusiness[2].Value, DDBusiness[3].Value, DDBusiness[4].Value, DDBusiness[5].Value, DDBusiness[6].Value, DDBusiness[7].Value, DDBusiness[8].Value]
            AuswahlLager := [DDLager[1].Value, DDLager[2].Value, DDLager[3].Value, DDLager[4].Value, DDLager[5].Value]
            AuswahlWarenlager := DDWarenlager.Value
            AuswahlAusruestung := DDAusruestung.Value
            AuswahlRunden := Integer(IsNumber(EF.Value) ? EF.Value : 0)
            Sprache := NeueSprache
            NeuAufbauNoetig := true
            SDlg.Destroy()
        }
        BtnDE.OnEvent("Click", SpracheWechseln.Bind("DE"))
        BtnEN.OnEvent("Click", SpracheWechseln.Bind("EN"))

        for Eintrag in FarbButtons {
            Swatch := Eintrag[1], Hex := Eintrag[2]
            Swatch.OnEvent("Click", FarbeWechseln.Bind(Hex))
        }
        FarbeWechseln(Hex, *) {
            AuswahlBusiness := [DDBusiness[1].Value, DDBusiness[2].Value, DDBusiness[3].Value, DDBusiness[4].Value, DDBusiness[5].Value, DDBusiness[6].Value, DDBusiness[7].Value, DDBusiness[8].Value]
            AuswahlLager := [DDLager[1].Value, DDLager[2].Value, DDLager[3].Value, DDLager[4].Value, DDLager[5].Value]
            AuswahlWarenlager := DDWarenlager.Value
            AuswahlAusruestung := DDAusruestung.Value
            AuswahlRunden := Integer(IsNumber(EF.Value) ? EF.Value : 0)
            AkzentFarbe := Hex
            NeuAufbauNoetig := true
            SDlg.Destroy()
        }

        FertigKlick(*) {
            BesitztNachtclub := (DDBusiness[1].Value = 1)
            BesitztSpielhalle := (DDBusiness[2].Value = 1)
            BesitztAgentur := (DDBusiness[3].Value = 1)
            BesitztSchrotthandel := (DDBusiness[4].Value = 1)
            BesitztKautionsbuero := (DDBusiness[5].Value = 1)
            BesitztTextilfabrik := (DDBusiness[6].Value = 1)
            BesitztWaschanlage := (DDBusiness[7].Value = 1)
            BesitztHangar := (DDBusiness[8].Value = 1)

            LagerGroesseAuswerten(DDLager[1].Value, &BesitztLager1, &MaxKistenLager1, &PreisProKisteLager1)
            LagerGroesseAuswerten(DDLager[2].Value, &BesitztLager2, &MaxKistenLager2, &PreisProKisteLager2)
            LagerGroesseAuswerten(DDLager[3].Value, &BesitztLager3, &MaxKistenLager3, &PreisProKisteLager3)
            LagerGroesseAuswerten(DDLager[4].Value, &BesitztLager4, &MaxKistenLager4, &PreisProKisteLager4)
            LagerGroesseAuswerten(DDLager[5].Value, &BesitztLager5, &MaxKistenLager5, &PreisProKisteLager5)
            BesitztLagerhaus := BesitztLager1 || BesitztLager2 || BesitztLager3 || BesitztLager4 || BesitztLager5

            BesitztNachtclubWarenlager := (DDWarenlager.Value = 1)
            NachtclubAusruestungGekauft := (DDAusruestung.Value = 1)
            if (BesitztNachtclubWarenlager && NachtclubWarenlagerStartZeit = "")
                NachtclubWarenlagerStartZeit := A_Now

            ZielRundenAnzahl := (IsNumber(EF.Value) ? Integer(EF.Value) : 0)

            NeuAufbauNoetig := false
            SDlg.Destroy()
        }
        BtnFertig.OnEvent("Click", FertigKlick)
        SDlg.OnEvent("Close", FertigKlick)
        SDlg.OnEvent("Escape", FertigKlick)

        SDlg.Show("AutoSize xCenter yCenter")
        WinWaitClose("ahk_id " . SDlg.Hwnd)
    }

    SpeichereKistenstand()
}

; =========================================================================
; 🌐 T(): Übersetzungsfunktion - gibt je nach gewählter Sprache den
; passenden Text zurück. Deckt Dashboard + alle Setup-/Abfrage-Fenster ab.
; =========================================================================
T(Key) {
    global Sprache
    static Texte := Map(
        "dash_titel", Map("DE", "🎮 GTA BUSINESS DASHBOARD", "EN", "🎮 GTA BUSINESS DASHBOARD"),
        "dash_warnung", Map("DE", "⚠ GTA muss im FENSTERMODUS/RANDLOS laufen (nicht exklusives Vollbild)!", "EN", "⚠ GTA must run in WINDOWED/BORDERLESS mode (not exclusive fullscreen)!"),
        "dash_steuerung", Map("DE", "⌨ Shift+P=Start | Shift+O=Pause | Shift+L=Sync | Shift+V=Warenlager verkauft | Shift+H=Dashboard ein-/ausblenden | Shift+B=Boni neu laden | Shift+U=Update prüfen | Shift+2=2x-Speed Fracht", "EN", "⌨ Shift+P=Start | Shift+O=Pause | Shift+L=Sync | Shift+V=Warehouse sold | Shift+H=Show/hide dashboard | Shift+B=Reload bonuses | Shift+U=Check update | Shift+2=2x-Speed Cargo"),
        "karte_gewinn", Map("DE", "💰 GESAMTGEWINN", "EN", "💰 TOTAL PROFIT"),
        "karte_status", Map("DE", "📡 STATUS", "EN", "📡 STATUS"),
        "karte_finanzen", Map("DE", "📊 FINANZEN", "EN", "📊 FINANCES"),
        "karte_nachtclub", Map("DE", "🎵 NACHTCLUB-BELIEBTHEIT", "EN", "🎵 NIGHTCLUB POPULARITY"),
        "karte_warenlager", Map("DE", "🎚️ NACHTCLUB-WARENLAGER (Techniker, Echtzeit-Schätzung)", "EN", "🎚️ NIGHTCLUB WAREHOUSE (technicians, real-time estimate)"),
        "karte_lager", Map("DE", "📦 SPEZIALFRACHT & HANGAR", "EN", "📦 SPECIAL CARGO & HANGAR"),
        "bereit", Map("DE", "Bereit... (Shift+P)", "EN", "Ready... (Shift+P)"),
        "gewinn_std_wird_berechnet", Map("DE", "Gewinn/Std.: wird berechnet...", "EN", "Profit/hr: calculating..."),
        "pro_std_suffix", Map("DE", "/ Std.", "EN", "/ hr"),
        "spezialfracht_kurz", Map("DE", "Spezialfracht", "EN", "Special Cargo"),
        "hangar_label", Map("DE", "Hangar", "EN", "Hangar"),
        "noch_nicht_gestartet", Map("DE", "Noch nicht gestartet", "EN", "Not started yet"),
        "auto_shutdown_deaktiviert", Map("DE", "Auto-Shutdown: deaktiviert", "EN", "Auto-shutdown: disabled"),
        "warenlager_hinweis", Map("DE", "Shift+V drücken, sobald du das Warenlager verkauft hast (setzt die Schätzung zurück auf 0)", "EN", "Press Shift+V once you've sold the warehouse (resets the estimate to 0)"),
        "ja", Map("DE", "Ja", "EN", "Yes"),
        "nein", Map("DE", "Nein", "EN", "No"),
        "btn_ja", Map("DE", "✓  Ja", "EN", "✓  Yes"),
        "btn_nein", Map("DE", "✗  Nein", "EN", "✗  No"),
        "btn_ok", Map("DE", "✓  OK", "EN", "✓  OK"),
        "btn_abbrechen", Map("DE", "✗  Abbrechen", "EN", "✗  Cancel"),
        "btn_uebernehmen", Map("DE", "✓  Übernehmen", "EN", "✓  Apply"),
        "spalte_unternehmen", Map("DE", "UNTERNEHMEN", "EN", "BUSINESSES"),
        "spalte_lager", Map("DE", "SONDERFRACHT-LAGERHÄUSER", "EN", "SPECIAL CARGO WAREHOUSES"),
        "warenlager_ueberschrift", Map("DE", "NACHTCLUB-WARENLAGER (Techniker)", "EN", "NIGHTCLUB WAREHOUSE (technicians)"),
        "techniker_frage", Map("DE", "Techniker Waren zuweisen?", "EN", "Technicians assigned to goods?"),
        "ausruestung_frage", Map("DE", "Ausrüstungs-Upgrade gekauft?", "EN", "Equipment upgrade bought?"),
        "lager_klein", Map("DE", "Klein (16 Kisten)", "EN", "Small (16 crates)"),
        "lager_mittel", Map("DE", "Mittel (42 Kisten)", "EN", "Medium (42 crates)"),
        "lager_gross", Map("DE", "Groß (111 Kisten)", "EN", "Large (111 crates)"),
        "lager_keins", Map("DE", "Nicht vorhanden", "EN", "Not owned"),
        "spielstand_titel", Map("DE", "📋 Spielstand-Sync", "EN", "📋 Save Data Sync"),
        "spielstand_subtitel", Map("DE", "Echte, aktuelle Werte aus dem Spiel eintragen, dann unten übernehmen.", "EN", "Enter the real, current values from the game, then apply below."),
        "kisten_lager", Map("DE", "Lager", "EN", "Warehouse"),
        "kisten_einheit", Map("DE", "(Kisten)", "EN", "(crates)"),
        "kisten_hangar", Map("DE", "Hangar (Kisten)", "EN", "Hangar (crates)"),
        "beliebtheit_feld", Map("DE", "Nachtclub-Beliebtheit (%)", "EN", "Nightclub popularity (%)"),
        "startmodus_titel", Map("DE", "Start-Modus wählen", "EN", "Choose start mode"),
        "startmodus_frage", Map("DE", "Sofort mit dem Einkauf starten, oder erst die Wartezeit abwarten (z.B. weil gerade erst frisch eingekauft wurde)?", "EN", "Start with a purchase immediately, or wait out the cooldown first (e.g. because you just bought)?"),
        "startmodus_sofort", Map("DE", "⚡ Sofort starten", "EN", "⚡ Start immediately"),
        "startmodus_cooldown", Map("DE", "⏳ Erst warten", "EN", "⏳ Wait first"),
        "warenbestand_ueberspringen_checkbox", Map("DE", "Genauen Warenbestand nicht eingeben (nur schätzen lassen)", "EN", "Don't enter exact cargo stock (estimate only)"),
        "btn_jetzt_starten", Map("DE", "🚀  Jetzt starten", "EN", "🚀  Start now"),
        "autoshutdown_titel", Map("DE", "⏻ Auto-Shutdown (optional)", "EN", "⏻ Auto-Shutdown (optional)"),
        "autoshutdown_frage", Map("DE", "Nach wie vielen Runden soll der PC automatisch heruntergefahren werden?`n(0 oder leer = nie automatisch herunterfahren)", "EN", "After how many rounds should the PC shut down automatically?`n(0 or empty = never shut down automatically)"),
        "autoshutdown_deaktiviert_live", Map("DE", "= Auto-Shutdown deaktiviert", "EN", "= Auto-shutdown disabled"),
        "autoshutdown_voraussichtlich", Map("DE", "= voraussichtl. {1}Std {2}Min Gesamt-AFK-Zeit   →   Shutdown ca. um {3} Uhr", "EN", "= estimated {1}h {2}m total AFK time   →   Shutdown at approx. {3}"),
        "farbauswahl_titel", Map("DE", "🎨 Akzentfarbe wählen", "EN", "🎨 Choose accent color"),
        "karte_eventboni", Map("DE", "📢 EVENT-BONI DIESE WOCHE", "EN", "📢 EVENT BONUSES THIS WEEK"),
        "eventboni_laedt", Map("DE", "Werte ab...", "EN", "Loading..."),
        "eventboni_fehler", Map("DE", "Konnte Boni nicht laden. Debug-Datei: GTA_EventBoni_Debug.txt (im Skript-Ordner). Shift+B = erneut versuchen. Manuell prüfen: {1}", "EN", "Couldn't load bonuses. Debug file: GTA_EventBoni_Debug.txt (in script folder). Shift+B = retry. Check manually: {1}"),
        "eventboni_leer", Map("DE", "Keine Boni gefunden. Debug-Datei: GTA_EventBoni_Debug.txt (im Skript-Ordner). Shift+B = erneut versuchen. Manuell prüfen: {1}", "EN", "No bonuses found. Debug file: GTA_EventBoni_Debug.txt (in script folder). Shift+B = retry. Check manually: {1}"),
        "eventboni_aktualisiert", Map("DE", "Zuletzt aktualisiert: {1}   |   Shift+B = neu laden   |   Quelle: gtabase.com", "EN", "Last updated: {1}   |   Shift+B = refresh   |   Source: gtabase.com"),
        "eventboni_wird_geladen_status", Map("DE", "Event-Boni werden abgerufen...", "EN", "Fetching event bonuses..."),
        "update_suche_status", Map("DE", "Suche nach Updates...", "EN", "Checking for updates..."),
        "update_gefunden_titel", Map("DE", "Update verfügbar", "EN", "Update available"),
        "update_gefunden_frage", Map("DE", "Version {1} ist verfügbar (du hast {2}).`n`nJetzt herunterladen und installieren? Das Skript startet danach automatisch neu.", "EN", "Version {1} is available (you have {2}).`n`nDownload and install now? The script will restart automatically afterwards."),
        "update_wird_installiert", Map("DE", "Update wird installiert, Skript startet neu...", "EN", "Installing update, script is restarting..."),
        "update_hinweis_kurz", Map("DE", "   |   🔄 Update {1} verfügbar! Shift+U zum Installieren", "EN", "   |   🔄 Update {1} available! Shift+U to install"),
        "sonderfracht_hinweis_kurz", Map("DE", "   |   ⚡ 2x-Speed AN (alle 24 Min.)", "EN", "   |   ⚡ 2x-Speed ON (every 24 min.)"),
        "sonderfracht_schnell_laeuft", Map("DE", "⚡ 2x-SPEED: Sonderfracht wird abgeholt...", "EN", "⚡ 2x SPEED: Collecting special cargo..."),
        "sonderfracht_schnell_aktiviert", Map("DE", "⚡ 2x-Speed AN: Sonderfracht jetzt alle 24 Min.", "EN", "⚡ 2x-Speed ON: cargo now every 24 min."),
        "sonderfracht_schnell_deaktiviert", Map("DE", "2x-Speed AUS - zurück zu 48 Min.", "EN", "2x-Speed OFF - back to 48 min."),
        "sonderfracht_schnell_kein_lager", Map("DE", "Kein Sonderfracht-Lagerhaus besessen - 2x-Speed nicht nötig", "EN", "No special cargo warehouse owned - 2x speed not needed"),
        "update_fehler", Map("DE", "Update-Prüfung fehlgeschlagen: {1}", "EN", "Update check failed: {1}"),
        "update_aktuell", Map("DE", "Du hast bereits die neueste Version ({1}).", "EN", "You already have the latest version ({1})."),
        "update_nicht_konfiguriert", Map("DE", "Auto-Update ist nicht eingerichtet (siehe Kommentar am Skriptanfang).", "EN", "Auto-update isn't set up yet (see comment at the top of the script)."),
        "biz_nachtclub", Map("DE", "Nachtclub", "EN", "Nightclub"),
        "biz_spielhalle", Map("DE", "Spielhalle", "EN", "Arcade"),
        "biz_agentur", Map("DE", "Agentur", "EN", "Agency"),
        "biz_schrotthandel", Map("DE", "Schrotthandel", "EN", "Salvage Yard"),
        "biz_kautionsbuero", Map("DE", "Kautionsbüro", "EN", "Bail Office"),
        "biz_textilfabrik", Map("DE", "Textilfabrik", "EN", "Textile Factory"),
        "biz_waschanlage", Map("DE", "Waschanlage", "EN", "Car Wash"),
        "handy_oeffnen", Map("DE", "Handy öffnen", "EN", "Open phone"),
        "zur_vinewood_navigieren", Map("DE", "Zur Vinewood-App navigieren", "EN", "Navigate to the Vinewood app"),
        "vinewood_oeffnen", Map("DE", "Vinewood-App öffnen", "EN", "Open the Vinewood app"),
        "einkuenfte_menu_oeffnen", Map("DE", "Einkünfte aus Unternehmen abholen (Menü öffnen)", "EN", "Collect business earnings (open menu)"),
        "zu_x_navigieren", Map("DE", "Zu {1} navigieren", "EN", "Navigate to {1}"),
        "einnahmen_abholen", Map("DE", "{1}-Einnahmen abholen", "EN", "Collect {1} earnings"),
        "zurueck_hauptmenu", Map("DE", "Zurück zum Hauptmenü", "EN", "Back to main menu"),
        "zu_personal_navigieren", Map("DE", "Zu 'Personal verwalten' navigieren", "EN", "Navigate to 'Manage Personnel'"),
        "personal_menu_oeffnen", Map("DE", "Personal-Menü öffnen", "EN", "Open personnel menu"),
        "zum_hangar_navigieren", Map("DE", "Zum Hangar navigieren", "EN", "Navigate to Hangar"),
        "hangar_mitarbeiter_losschicken", Map("DE", "Hangar-Mitarbeiter losschicken", "EN", "Send Hangar worker"),
        "zum_lagerhaus_navigieren", Map("DE", "Zum Lagerhaus navigieren", "EN", "Navigate to Warehouse"),
        "lagerhaeuser_menu_oeffnen", Map("DE", "Lagerhäuser-Menü öffnen", "EN", "Open warehouses menu"),
        "lagerhaus_n_fracht", Map("DE", "{1}. Lagerhaus: Fracht besorgen", "EN", "Warehouse {1}: get cargo"),
        "zum_naechsten_lagerhaus", Map("DE", "Zum nächsten Lagerhaus", "EN", "Navigate to next warehouse"),
        "zurueck_personal_liste", Map("DE", "Zurück in die Personal-verwalten-Liste", "EN", "Back to the personnel list"),
        "zum_kautionsbuero_navigieren", Map("DE", "Zum Kautionsbüro navigieren", "EN", "Navigate to Bail Office"),
        "kautionsbuero_menu_oeffnen", Map("DE", "Kautionsbüro-Menü öffnen", "EN", "Open Bail Office menu"),
        "agenten_losschicken", Map("DE", "Agenten losschicken", "EN", "Send agents"),
        "auftrag_bestaetigen", Map("DE", "Auftrag bestätigen", "EN", "Confirm job"),
        "vinewood_schliessen_n", Map("DE", "Vinewood-App schließen ({1}/3)", "EN", "Close Vinewood app ({1}/3)"),
        "handy_menu_verlassen", Map("DE", "Handy-Menü verlassen (3/3)", "EN", "Exit phone menu (3/3)"),
        "dashboard_wieder_eingeblendet", Map("DE", "Dashboard wieder eingeblendet", "EN", "Dashboard shown again"),
        "warenlager_verkauft_markiert", Map("DE", "Nachtclub-Warenlager als verkauft markiert - Schätzung zurückgesetzt", "EN", "Nightclub warehouse marked as sold - estimate reset"),
        "spielstand_synchronisiert", Map("DE", "Spielstand manuell synchronisiert", "EN", "Save data manually synced"),
        "start_abgebrochen", Map("DE", "Start abgebrochen - Shift+P erneut drücken, um Werte neu einzugeben", "EN", "Start cancelled - press Shift+P again to re-enter values"),
        "cooldown_laeuft", Map("DE", "Cooldown läuft (kein Einkauf in dieser Runde)...", "EN", "Cooldown running (no purchase this round)..."),
        "automatisierung_pausiert", Map("DE", "AUTOMATISIERUNG PAUSIERT", "EN", "AUTOMATION PAUSED"),
        "gta_fenster_nicht_gefunden", Map("DE", "WARNUNG: GTA-Fenster nicht gefunden - erneuter Versuch in 10 Sek.", "EN", "WARNING: GTA window not found - retrying in 10 sec."),
        "gta_fenster_nicht_aktiviert", Map("DE", "WARNUNG: GTA-Fenster ließ sich nicht aktivieren - erneuter Versuch in 10 Sek.", "EN", "WARNING: Couldn't activate GTA window - retrying in 10 sec."),
        "einkauf_laeuft", Map("DE", "EINKAUF LÄUFT...", "EN", "PURCHASE IN PROGRESS..."),
        "automatisierung_pausiert_runde_abgebrochen", Map("DE", "AUTOMATISIERUNG PAUSIERT (Runde abgebrochen)", "EN", "AUTOMATION PAUSED (round cancelled)"),
        "aktion_praefix", Map("DE", "AKTION: {1}", "EN", "ACTION: {1}"),
        "ziel_erreicht_shutdown", Map("DE", "Ziel erreicht ({1} Runden) - PC fährt in 60 Sek. herunter! (Abbrechen: 'shutdown /a' in cmd)", "EN", "Target reached ({1} rounds) - PC shutting down in 60 sec.! (Cancel: 'shutdown /a' in cmd)"),
        "afk_wartezeit_laeuft", Map("DE", "AFK-Wartezeit läuft...", "EN", "AFK wait time running..."),
        "runde_label", Map("DE", "Runde", "EN", "Round"),
        "gesamte_afk_zeit_label", Map("DE", "Gesamte AFK-Zeit", "EN", "Total AFK time"),
        "std_kurz", Map("DE", "Std", "EN", "hrs"),
        "mitarbeiter_kosten_label", Map("DE", "Mitarbeiter-Kosten", "EN", "Staff costs"),
        "bar_geld_label", Map("DE", "Bar-Geld", "EN", "Cash"),
        "club_kurz", Map("DE", "Club", "EN", "Club"),
        "arcade_kurz", Map("DE", "Arcade", "EN", "Arcade"),
        "warenwert_seit_afk_label", Map("DE", "Warenwert seit AFK-Start", "EN", "Cargo value since AFK start"),
        "naechste_runde_in", Map("DE", "Nächste Runde in {1}:{2} Min. ({3}% der Wartezeit um)", "EN", "Next round in {1}:{2} min. ({3}% of wait time done)"),
        "warenlager_geschaetzt", Map("DE", "Geschätzter Wert: ${1} von ${2} ({3} Std. seit letztem Verkauf)   |   Shift+V nach dem Verkaufen drücken", "EN", "Estimated value: ${1} of ${2} ({3} hrs since last sale)   |   Press Shift+V after selling"),
        "shutdown_info_aktiv", Map("DE", "Auto-Shutdown nach Runde {1} von {2} (voraussichtl. Gesamt-AFK-Zeit: {3}Std {4}Min)   →   Shutdown ca. um {5} Uhr", "EN", "Auto-shutdown after round {1} of {2} (estimated total AFK time: {3}h {4}m)   →   Shutdown at approx. {5}"),
        "gesamtwarenwert_label", Map("DE", "GESAMTWARENWERT: ${1}   (volle Lobby +50%: ${2})", "EN", "TOTAL CARGO VALUE: ${1}   (full lobby +50%: ${2})")
    )
    if Texte.Has(Key)
        return Texte[Key].Has(Sprache) ? Texte[Key][Sprache] : Texte[Key]["DE"]
    return Key
}

; Wie T(), aber ersetzt {1} im übersetzten Text durch den übergebenen Wert
TP(Key, Wert1) {
    return StrReplace(T(Key), "{1}", Wert1)
}

; Wie TP(), aber für mehrere Platzhalter {1}, {2}, {3}, ... auf einmal
TPn(Key, Werte*) {
    Text := T(Key)
    for i, Wert in Werte
        Text := StrReplace(Text, "{" . i . "}", Wert)
    return Text
}

; =========================================================================
; 🎲 Wählt einen zufälligen Warte-Text für die AFK-Phase (statt immer
; derselben Meldung). Wird einmal zu Beginn jeder AFK-Wartezeit aufgerufen.
; =========================================================================
WaehleFlavorText() {
    global AktuellerFlavorText, Sprache
    static TexteDE := [
        "Der Nachtclub bebt...",
        "Die Agenten sind unterwegs...",
        "Die Kisten werden verladen...",
        "Der Hangar wird beladen...",
        "Die Party läuft auf Hochtouren...",
        "Die Fracht rollt an...",
        "Kautionsagenten auf Streife...",
        "Der DJ legt auf...",
        "Lagerarbeiter schuften fleißig...",
        "Geld wird gezählt..."
    ]
    static TexteEN := [
        "The nightclub is buzzing...",
        "Agents are on the move...",
        "Crates are being loaded...",
        "The hangar is filling up...",
        "The party is in full swing...",
        "Cargo is rolling in...",
        "Bail agents on patrol...",
        "The DJ is spinning...",
        "Warehouse crew hard at work...",
        "Counting the cash..."
    ]
    Texte := (Sprache = "DE") ? TexteDE : TexteEN
    AktuellerFlavorText := Texte[Random(1, Texte.Length)]
}

; =========================================================================
; 📢 Best-Effort-Abruf der aktuellen GTA$-Event-Boni von gtabase.com.
; WICHTIG: Keine offizielle API - reine Text-/Regex-Auswertung der Webseite.
; Bricht die Seite die Struktur um, liefert diese Funktion einfach nichts
; (EventBoniFehler wird gesetzt) statt falscher/erfundener Daten.
; =========================================================================
; =========================================================================
; 🔄 AUTO-UPDATE: vergleicht die eigene Version mit der online hinterlegten
; Versionsnummer. Bei neuerer Version wird gefragt, ob installiert werden
; soll - bei Ja wird die neue Skript-Datei heruntergeladen, die aktuelle
; .ahk-Datei überschrieben und das Skript automatisch neu gestartet.
; =========================================================================

; Baut die Steuerungszeile neu auf: Basistext + optionaler Update-Hinweis +
; optionaler 2x-Speed-Hinweis, ohne das restliche Layout zu verschieben.
; Blinkt rot, solange ein Update verfügbar ist (2x-Speed-Hinweis blinkt
; bewusst NICHT - der ist ja ein normaler, gewollter Dauerzustand).
AktualisiereSteuerungszeile() {
    global SteuerungCtrl, UpdateVerfuegbarVersion, SonderfrachtSchnellModusAktiv
    Text := T("dash_steuerung")
    if (UpdateVerfuegbarVersion != "")
        Text .= TP("update_hinweis_kurz", UpdateVerfuegbarVersion)
    if SonderfrachtSchnellModusAktiv
        Text .= T("sonderfracht_hinweis_kurz")
    SteuerungCtrl.Value := Text

    if (UpdateVerfuegbarVersion != "")
        SetTimer(UpdateBlinkTicker, 500)
    else {
        SetTimer(UpdateBlinkTicker, 0)
        SteuerungCtrl.SetFont("cAAAAAA")
    }
}

; Alter Funktionsname bleibt als Alias erhalten (wird an mehreren Stellen
; nach einer Update-Prüfung aufgerufen).
AktualisiereUpdateHinweis() {
    AktualisiereSteuerungszeile()
}

; Wechselt die Farbe der Steuerungszeile im Sekundentakt zwischen Rot und
; normalem Grau, solange ein Update-Hinweis aktiv ist.
UpdateBlinkTicker() {
    global SteuerungCtrl
    static Rot := false
    Rot := !Rot
    SteuerungCtrl.SetFont(Rot ? "cFF3333" : "cAAAAAA")
}

IstNeuereVersion(Neu, Alt) {
    ; FIX: Jeden Teil vor der Umwandlung auf reine Ziffern reduzieren - so
    ; können unsichtbare Zeichen (z.B. ein Windows-Zeilenumbruch \r, der in
    ; der Versions-Datei mitgeliefert wurde) nicht mehr zum Absturz führen.
    NurZiffern(Text) {
        Bereinigt := RegExReplace(Text, "[^\d]", "")
        return (Bereinigt = "") ? 0 : Integer(Bereinigt)
    }
    NeuTeile := StrSplit(Trim(Neu, " `t`r`n"), ".")
    AltTeile := StrSplit(Trim(Alt, " `t`r`n"), ".")
    NeuHaupt := NurZiffern(NeuTeile.Length >= 1 ? NeuTeile[1] : "0")
    AltHaupt := NurZiffern(AltTeile.Length >= 1 ? AltTeile[1] : "0")
    if (NeuHaupt != AltHaupt)
        return NeuHaupt > AltHaupt
    NeuNeben := NurZiffern(NeuTeile.Length >= 2 ? NeuTeile[2] : "0")
    AltNeben := NurZiffern(AltTeile.Length >= 2 ? AltTeile[2] : "0")
    return NeuNeben > AltNeben
}

PrüfeAufUpdate(ManuellAusgeloest := false) {
    global AutoUpdateAktiviert, AktuelleVersion, UpdateVersionsUrl, UpdateDateiUrl, AutomatisierungBeschaeftigt, UpdateVerfuegbarVersion

    if (UpdateVersionsUrl = "" || UpdateDateiUrl = "") {
        if ManuellAusgeloest
            UpdateDashboard(T("update_nicht_konfiguriert"))
        return
    }
    if (!AutoUpdateAktiviert && !ManuellAusgeloest)
        return

    ; FIX: Die automatische (wiederkehrende) Prüfung überspringt einfach,
    ; falls gerade eine Runde aktiv läuft (Tasten werden gesendet) - wird
    ; beim nächsten 30-Min-Intervall erneut versucht. Ein manueller Shift+U
    ; läuft dagegen immer sofort, das entscheidest du bewusst selbst.
    if (!ManuellAusgeloest && AutomatisierungBeschaeftigt)
        return

    if ManuellAusgeloest
        UpdateDashboard(T("update_suche_status"))

    try {
        ; FIX: Cache-Buster (?t=Zufallszahl) anhängen - raw.githubusercontent.com
        ; cached Inhalte sonst teils mehrere Minuten, auch nach einer Änderung.
        CacheBuster := "?t=" . A_TickCount . Random(1000, 9999)
        Http := ComObject("WinHttp.WinHttpRequest.5.1")
        Http.Open("GET", UpdateVersionsUrl . CacheBuster, false)
        Http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        Http.SetRequestHeader("Cache-Control", "no-cache")
        Http.SetTimeouts(5000, 5000, 8000, 8000)
        Http.Send()
        if (Http.Status != 200) {
            if ManuellAusgeloest
                UpdateDashboard(TP("update_fehler", "HTTP " . Http.Status))
            return
        }
        OnlineVersion := Trim(Http.ResponseText, " `t`r`n")
    } catch as Fehler {
        if ManuellAusgeloest
            UpdateDashboard(TP("update_fehler", Fehler.Message))
        return
    }

    if !IstNeuereVersion(OnlineVersion, AktuelleVersion) {
        if (UpdateVerfuegbarVersion != "") {
            UpdateVerfuegbarVersion := ""
            AktualisiereUpdateHinweis()
        }
        if ManuellAusgeloest
            UpdateDashboard(TP("update_aktuell", AktuelleVersion))
        return
    }

    ; FIX: Die automatische (wiederkehrende) Prüfung fragt NIE aktiv nach -
    ; das wäre ein blockierender Dialog mitten in der AFK-Wartezeit, wo
    ; niemand am PC sitzt, um zu bestätigen. Stattdessen nur ein stiller
    ; Hinweis im Dashboard; erst ein bewusstes Shift+U (= du bist am PC)
    ; zeigt den Bestätigungsdialog.
    if !ManuellAusgeloest {
        UpdateVerfuegbarVersion := OnlineVersion
        AktualisiereUpdateHinweis()
        return
    }

    Antwort := ZeigeFrage(T("update_gefunden_titel"), TPn("update_gefunden_frage", OnlineVersion, AktuelleVersion))
    if !Antwort
        return

    UpdateDashboard(T("update_wird_installiert"))
    try {
        HttpDatei := ComObject("WinHttp.WinHttpRequest.5.1")
        HttpDatei.Open("GET", UpdateDateiUrl . CacheBuster, false)
        HttpDatei.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        HttpDatei.SetRequestHeader("Cache-Control", "no-cache")
        HttpDatei.SetTimeouts(5000, 5000, 15000, 15000)
        HttpDatei.Send()
        if (HttpDatei.Status != 200) {
            UpdateDashboard(TP("update_fehler", "HTTP " . HttpDatei.Status))
            return
        }
        NeuerInhalt := HttpDatei.ResponseText
    } catch as Fehler {
        UpdateDashboard(TP("update_fehler", Fehler.Message))
        return
    }

    ; FIX: Die Datei NICHT direkt überschreiben, während das Skript noch
    ; läuft - Windows/Antivirus-Programme sperren die gerade ausgeführte
    ; .ahk-Datei dabei oft ("Zugriff verweigert"). Stattdessen: neuen Inhalt
    ; in eine Temp-Datei schreiben, ein kleines Batch-Skript erzeugen, das
    ; ERST NACH dem vollständigen Beenden dieses Skripts die eigentliche
    ; Datei ersetzt und neu startet, und dieses Skript sofort beenden.
    ZielPfad := A_ScriptFullPath
    TempPfad := A_ScriptDir . "\_gta_update_temp.ahk"
    BatchPfad := A_ScriptDir . "\_gta_update_installer.bat"
    try {
        TempDatei := FileOpen(TempPfad, "w", "UTF-8")
        TempDatei.Write(NeuerInhalt)
        TempDatei.Close()
    } catch as Fehler {
        UpdateDashboard(TP("update_fehler", Fehler.Message))
        return
    }

    try {
        BatchInhalt := "@echo off`r`n"
        BatchInhalt .= "timeout /t 2 /nobreak >nul`r`n"
        BatchInhalt .= "move /y " . Chr(34) . TempPfad . Chr(34) . " " . Chr(34) . ZielPfad . Chr(34) . "`r`n"
        BatchInhalt .= "start " . Chr(34) . Chr(34) . " " . Chr(34) . A_AhkPath . Chr(34) . " " . Chr(34) . ZielPfad . Chr(34) . "`r`n"
        BatchInhalt .= "del " . Chr(34) . "%~f0" . Chr(34) . "`r`n"
        BatchDatei := FileOpen(BatchPfad, "w", "UTF-8")
        BatchDatei.Write(BatchInhalt)
        BatchDatei.Close()
    } catch as Fehler {
        UpdateDashboard(TP("update_fehler", Fehler.Message))
        return
    }

    Run('"' . BatchPfad . '"', , "Hide")
    Sleep(200)
    ExitApp()
}

AbrufeEventBoni() {
    global EventBoniListe, EventBoniLetzteAktualisierung, EventBoniFehler, EventBoniQuelleUrl

    ; FIX: Diagnose-Datei - protokolliert bei JEDEM Abruf, was tatsächlich
    ; ankam (HTTP-Status, Länge, Auszug). Damit lässt sich genau sehen, woran
    ; es hakt, falls die automatische Auswertung mal nichts findet.
    DebugPfad := A_ScriptDir . "\GTA_EventBoni_Debug.txt"
    DebugText := "=== Abruf um " . FormatTime(A_Now, "dd.MM.yyyy HH:mm:ss") . " ===`n"

    EventBoniFehler := ""
    HTML := ""
    try {
        Http := ComObject("WinHttp.WinHttpRequest.5.1")
        Http.Open("GET", EventBoniQuelleUrl, false)
        Http.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        Http.SetTimeouts(5000, 5000, 8000, 8000)
        Http.Send()
        DebugText .= "HTTP-Status: " . Http.Status . "`n"
        if (Http.Status != 200) {
            EventBoniFehler := "HTTP " . Http.Status
            EventBoniListe := []
            DebugText .= "-> Abbruch: kein Status 200`n"
            FileAppend(DebugText, DebugPfad)
            return
        }
        HTML := Http.ResponseText
    } catch as Fehler {
        EventBoniFehler := Fehler.Message
        EventBoniListe := []
        DebugText .= "AUSNAHME: " . Fehler.Message . "`n"
        FileAppend(DebugText, DebugPfad)
        return
    }

    DebugText .= "Antwortlänge: " . StrLen(HTML) . " Zeichen`n"
    DebugText .= "Erste 1000 Zeichen der Antwort:`n" . SubStr(HTML, 1, 1000) . "`n---`n"

    ; FIX: Die Seite hat (mind.) ein Inhaltsverzeichnis ganz oben, das
    ; dieselben Überschriften als reine Links enthält (ohne Inhalt danach).
    ; Deshalb wird hier so lange zum NÄCHSTEN Vorkommen gesprungen, bis ein
    ; Abschnitt mit spürbarem Inhalt (>300 Zeichen bis "In-Game Discounts")
    ; gefunden wird - unabhängig davon, wie viele kurze Verzeichnis-Links
    ; vorher liegen.
    Suchtext := "GTA$ &amp; RP Bonuses"
    if !InStr(HTML, Suchtext)
        Suchtext := "GTA$ & RP Bonuses"
    if !InStr(HTML, Suchtext) {
        EventBoniFehler := "Abschnitt nicht gefunden"
        EventBoniListe := []
        DebugText .= "-> 'GTA$ & RP Bonuses' NICHT in der Antwort gefunden.`n"
        FileAppend(DebugText, DebugPfad)
        return
    }
    AbschnittStart := 0
    AbschnittEnde := 0
    SuchPos := 1
    Loop 6 {
        Gefunden := InStr(HTML, Suchtext, , SuchPos)
        if !Gefunden
            break
        Ende := InStr(HTML, "In-Game Discounts", , Gefunden)
        Laenge := Ende ? (Ende - Gefunden) : 9999
        DebugText .= "Vorkommen bei Position " . Gefunden . ", Länge bis 'In-Game Discounts': " . Laenge . "`n"
        if (Laenge > 300) {
            AbschnittStart := Gefunden
            AbschnittEnde := Ende
            break
        }
        SuchPos := Gefunden + 1
    }
    if !AbschnittStart {
        EventBoniFehler := "Abschnitt nicht gefunden"
        EventBoniListe := []
        DebugText .= "-> Kein Vorkommen mit substanziellem Inhalt gefunden.`n"
        FileAppend(DebugText, DebugPfad)
        return
    }
    Abschnitt := AbschnittEnde ? SubStr(HTML, AbschnittStart, AbschnittEnde - AbschnittStart) : SubStr(HTML, AbschnittStart, 6000)
    DebugText .= "Abschnitt gefunden, Länge: " . StrLen(Abschnitt) . " Zeichen`n"

    ; FIX: Statt exakter HTML-Tag-Struktur zu erraten (die sich jederzeit
    ; ändern kann), werden zuerst ALLE HTML-Tags entfernt -> reiner Text.
    ; Danach wird zeilenweise nach "Nx" gesucht; die letzte nicht-leere
    ; Textzeile davor gilt als Name der Aktivität. Das ist unabhängig von
    ; der genauen HTML-Struktur (Klassen, verschachtelte Tags, etc.).
    KlartextRoh := RegExReplace(Abschnitt, "s)<[^>]+>", "`n")
    KlartextRoh := StrReplace(KlartextRoh, "&amp;", "&")
    KlartextRoh := StrReplace(KlartextRoh, "&#039;", "'")
    KlartextRoh := StrReplace(KlartextRoh, "&#39;", "'")
    KlartextRoh := StrReplace(KlartextRoh, "&nbsp;", " ")
    KlartextRoh := StrReplace(KlartextRoh, "&quot;", Chr(34))
    Zeilen := StrSplit(KlartextRoh, "`n", "`r")

    DebugText .= "Extrahierter Klartext (nicht-leere Zeilen):`n"
    for Zeile in Zeilen {
        if (Trim(Zeile) != "")
            DebugText .= "  [" . Trim(Zeile) . "]`n"
    }

    Liste := []
    LetzterName := ""
    for Zeile in Zeilen {
        ZeileTrim := Trim(Zeile)
        if (ZeileTrim = "")
            continue
        if RegExMatch(ZeileTrim, "^(\d+)\s*x$", &MMult) {
            if (LetzterName != "" && StrLen(LetzterName) < 60) {
                NeuerEintrag := LetzterName . ": " . MMult[1] . "x"
                Gefunden := false
                for Vorhanden in Liste
                    if (Vorhanden = NeuerEintrag)
                        Gefunden := true
                if !Gefunden
                    Liste.Push(NeuerEintrag)
                LetzterName := ""  ; verhindert doppelte Auswertung bei "5x`n5x"
            }
        } else {
            LetzterName := ZeileTrim
        }
        if (Liste.Length >= 8)
            break
    }

    DebugText .= "Gefundene Boni (" . Liste.Length . "):`n"
    for Eintrag in Liste
        DebugText .= "  - " . Eintrag . "`n"
    FileAppend(DebugText, DebugPfad)

    if (Liste.Length = 0)
        EventBoniFehler := "keine_gefunden"
    EventBoniListe := Liste
    EventBoniLetzteAktualisierung := FormatTime(A_Now, "dd.MM. HH:mm")
}

ZeigeFrage(Titel, Frage, Zeilen := 2) {
    global AkzentFarbe
    Antwort := false

    FDlg := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", Titel)
    FDlg.BackColor := "111111"
    FDlg.MarginX := 28
    FDlg.MarginY := 24

    FDlg.SetFont("s14 Bold", "Consolas")
    FDlg.Add("Text", "cFFFFFF w440", "❔ " . Titel)
    FDlg.Add("Progress", "w440 h4 c" . AkzentFarbe . " Background1A1A1A -Smooth y+8", 100)
    FDlg.SetFont("s11 Norm", "Consolas")
    FDlg.Add("Text", "cCCCCCC w440 r" . Zeilen . " y+14", Frage)

    FDlg.SetFont("s11 Bold", "Consolas")
    BtnJa := FDlg.Add("Button", "w210 h42 Default y+18", T("btn_ja"))
    BtnNein := FDlg.Add("Button", "x+20 w210 h42", T("btn_nein"))

    JaKlick(*) {
        Antwort := true
        FDlg.Destroy()
    }
    NeinKlick(*) {
        Antwort := false
        FDlg.Destroy()
    }

    BtnJa.OnEvent("Click", JaKlick)
    BtnNein.OnEvent("Click", NeinKlick)
    FDlg.OnEvent("Close", NeinKlick)
    FDlg.OnEvent("Escape", NeinKlick)

    ; FIX: Zentriert. Das Dashboard ist klickdurchlässig (WS_EX_TRANSPARENT),
    ; dieser Dialog hier ist aber ein normales, interaktives Fenster - klar
    ; klickbar, ohne die Maus im Spiel zu stören.
    FDlg.Show("AutoSize xCenter yCenter")
    WinWaitClose("ahk_id " . FDlg.Hwnd)
    return Antwort
}

ZeigeEingabe(Titel, Frage, Standardwert := "") {
    global AkzentFarbe
    ErgebnisWert := ""
    ErgebnisOK := false

    EDlg := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", Titel)
    EDlg.BackColor := "111111"
    EDlg.MarginX := 28
    EDlg.MarginY := 24

    EDlg.SetFont("s14 Bold", "Consolas")
    EDlg.Add("Text", "cFFFFFF w440", "✏️ " . Titel)
    EDlg.Add("Progress", "w440 h4 c" . AkzentFarbe . " Background1A1A1A -Smooth y+8", 100)
    EDlg.SetFont("s11 Norm", "Consolas")
    EDlg.Add("Text", "cCCCCCC w440 r2 y+14", Frage)

    EDlg.SetFont("s13 Norm", "Consolas")
    EF := EDlg.Add("Edit", "w440 h32 cFFFFFF Background2A2A2A -E0x200 y+10", Standardwert)

    EDlg.SetFont("s11 Bold", "Consolas")
    BtnOK := EDlg.Add("Button", "w210 h42 Default y+16", T("btn_ok"))
    BtnAbbrechen := EDlg.Add("Button", "x+20 w210 h42", T("btn_abbrechen"))

    OkKlick(*) {
        ErgebnisWert := EF.Value
        ErgebnisOK := true
        EDlg.Destroy()
    }
    AbbrechenKlick(*) {
        EDlg.Destroy()
    }

    BtnOK.OnEvent("Click", OkKlick)
    BtnAbbrechen.OnEvent("Click", AbbrechenKlick)
    EDlg.OnEvent("Close", AbbrechenKlick)
    EDlg.OnEvent("Escape", AbbrechenKlick)

    ; FIX: Zentriert. Das Dashboard ist klickdurchlässig (WS_EX_TRANSPARENT),
    ; dieser Dialog hier ist aber ein normales, interaktives Fenster.
    EDlg.Show("AutoSize xCenter yCenter")
    WinWaitClose("ahk_id " . EDlg.Hwnd)
    return {ok: ErgebnisOK, value: ErgebnisWert}
}

; =========================================================================
; 📋 SPIELSTAND-EINGABE: EIN Fenster für alle Kistenstände + Nachtclub-
; Beliebtheit, statt vieler Einzelfenster nacheinander. Zeigt nur Zeilen für
; tatsächlich besessene Lager/Hangar/Nachtclub.
; =========================================================================
; =========================================================================
; 📋 SYNC & START: EIN Fenster für Warenbestand-Eingabe (mit Überspringen-
; Checkbox statt separatem Ja/Nein-Fenster), Nachtclub-Beliebtheit UND -
; beim allerersten Start - direkt auch den Start-Modus (Sofort/Cooldown).
; Ersetzt damit 3-4 vorher separate, nacheinander aufploppende Fenster.
; Rückgabe: Map mit "abgebrochen" (bool), "warenbestand_bekannt" (bool),
; "sofort_starten" (bool, nur relevant wenn ZeigStartOptionen=true).
; =========================================================================
ZeigeSpielstandEingabe(ZeigStartOptionen := false) {
    global KistenLager1, KistenLager2, KistenLager3, KistenLager4, KistenLager5, KistenHangar, NachtclubBeliebtheit, BesitztNachtclub, BesitztHangar, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, AkzentFarbe

    Ergebnis := Map("abgebrochen", true, "warenbestand_bekannt", false, "sofort_starten", true)
    HatLager := BesitztLager1 || BesitztLager2 || BesitztLager3 || BesitztLager4 || BesitztLager5 || BesitztHangar

    SDlg := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", T("spielstand_titel"))
    SDlg.BackColor := "111111"
    SDlg.MarginX := 28
    SDlg.MarginY := 24

    InhaltX := 28
    InhaltBreite := 460
    CY := 24

    SDlg.SetFont("s14 Bold", "Consolas")
    SDlg.Add("Text", "cFFFFFF x" . InhaltX . " y" . CY . " w" . InhaltBreite, T("spielstand_titel"))
    CY += 26
    SDlg.Add("Progress", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h4 c" . AkzentFarbe . " Background1A1A1A -Smooth", 100)
    CY += 14
    SDlg.SetFont("s10 Norm", "Consolas")
    SDlg.Add("Text", "cCCCCCC x" . InhaltX . " y" . CY . " w" . InhaltBreite . " r2", T("spielstand_subtitel"))
    CY += 36

    ; FIX: Eigenes farbiges Häkchen-Feld statt nativer Windows-Checkbox
    ; (bessere Lesbarkeit + moderne Optik, volle Farbkontrolle).
    CBChecked := false
    CBIndikator := "", CBLabel := ""
    if HatLager {
        CBIndikator := SDlg.Add("Text", "+0x100 x" . InhaltX . " y" . CY . " w22 h22 Background2A2A2A cFFFFFF Center", "")
        SDlg.SetFont("s10 Norm", "Consolas")
        CBLabel := SDlg.Add("Text", "+0x100 cCCCCCC x" . (InhaltX + 32) . " y" . (CY + 3) . " w" . (InhaltBreite - 32) . " h20", T("warenbestand_ueberspringen_checkbox"))
        CY += 34
    }

    ReihenHoehe := 38
    Felder := Map()
    FelderLabels := Map()

    ZeileHinzufuegen(SchluesselIntern, AnzeigeLabel, AktuellerWert) {
        Lbl := SDlg.Add("Text", "cDDDDDD x" . InhaltX . " y" . (CY + 6) . " w220", AnzeigeLabel . ":")
        SDlg.SetFont("s12 Norm", "Consolas")
        EF := SDlg.Add("Edit", "x" . (InhaltX + 225) . " y" . CY . " w" . (InhaltBreite - 225) . " h30 cFFFFFF Background2A2A2A -E0x200", AktuellerWert)
        SDlg.SetFont("s10 Bold", "Consolas")
        Felder[SchluesselIntern] := EF
        FelderLabels[SchluesselIntern] := Lbl
        CY += ReihenHoehe
    }

    LagerWort := T("kisten_lager"), KistenWort := T("kisten_einheit")
    SDlg.SetFont("s10 Bold", "Consolas")
    if BesitztLager1
        ZeileHinzufuegen("Lager1", LagerWort . " 1 " . KistenWort, KistenLager1)
    if BesitztLager2
        ZeileHinzufuegen("Lager2", LagerWort . " 2 " . KistenWort, KistenLager2)
    if BesitztLager3
        ZeileHinzufuegen("Lager3", LagerWort . " 3 " . KistenWort, KistenLager3)
    if BesitztLager4
        ZeileHinzufuegen("Lager4", LagerWort . " 4 " . KistenWort, KistenLager4)
    if BesitztLager5
        ZeileHinzufuegen("Lager5", LagerWort . " 5 " . KistenWort, KistenLager5)
    if BesitztHangar
        ZeileHinzufuegen("Hangar", T("kisten_hangar"), KistenHangar)
    if BesitztNachtclub
        ZeileHinzufuegen("Beliebtheit", T("beliebtheit_feld"), NachtclubBeliebtheit)

    ; FIX: Beim Anhaken müssen Feld UND Label zusammen ausgeblendet werden.
    ; Beliebtheit bleibt immer sichtbar, ist ja nicht Teil vom Warenbestand.
    if (CBIndikator != "") {
        UeberspringenToggle(*) {
            CBChecked := !CBChecked
            CBIndikator.Text := CBChecked ? "✓" : ""
            CBIndikator.Opt("Background" . (CBChecked ? AkzentFarbe : "2A2A2A"))
            Sichtbar := !CBChecked
            for Key, EF in Felder {
                if (Key != "Beliebtheit") {
                    EF.Visible := Sichtbar
                    FelderLabels[Key].Visible := Sichtbar
                }
            }
        }
        CBIndikator.OnEvent("Click", UeberspringenToggle)
        CBLabel.OnEvent("Click", UeberspringenToggle)
    }

    CY += 8

    ; --- Start-Modus (nur beim allerersten Start relevant) - eigene farbige
    ; "Pille"-Auswahl statt nativer Radio-Buttons (bessere Lesbarkeit). ---
    StartSofort := true
    BoxSofort := "", BoxCooldown := ""
    if ZeigStartOptionen {
        SDlg.Add("Text", "x" . InhaltX . " y" . CY . " w" . InhaltBreite . " h1 0x10")
        CY += 12
        SDlg.SetFont("s10 Bold", "Consolas")
        SDlg.Add("Text", "c" . AkzentFarbe . " x" . InhaltX . " y" . CY . " w" . InhaltBreite, T("startmodus_titel"))
        CY += 22
        SDlg.SetFont("s9 Norm", "Consolas")
        SDlg.Add("Text", "cCCCCCC x" . InhaltX . " y" . CY . " w" . InhaltBreite . " r3", T("startmodus_frage"))
        CY += 50

        SDlg.SetFont("s10 Bold", "Consolas")
        BoxSofort := SDlg.Add("Text", "+0x100 +0x200 x" . InhaltX . " y" . CY . " w220 h38 Background" . AkzentFarbe . " cFFFFFF Center", T("startmodus_sofort"))
        BoxCooldown := SDlg.Add("Text", "+0x100 +0x200 x+20 y" . CY . " w220 h38 Background2A2A2A cAAAAAA Center", T("startmodus_cooldown"))
        CY += 34

        StartModusWaehlen(IstSofort, *) {
            StartSofort := IstSofort
            BoxSofort.Opt(StartSofort ? "Background" . AkzentFarbe . " cFFFFFF" : "Background2A2A2A cAAAAAA")
            BoxCooldown.Opt(!StartSofort ? "Background" . AkzentFarbe . " cFFFFFF" : "Background2A2A2A cAAAAAA")
        }
        BoxSofort.OnEvent("Click", StartModusWaehlen.Bind(true))
        BoxCooldown.OnEvent("Click", StartModusWaehlen.Bind(false))
    }

    CY += 10
    SDlg.SetFont("s12 Bold", "Consolas")
    BtnOK := SDlg.Add("Button", "x" . InhaltX . " y" . CY . " w220 h44 Default", ZeigStartOptionen ? T("btn_jetzt_starten") : T("btn_uebernehmen"))
    BtnAbbrechen := SDlg.Add("Button", "x+20 w220 h44", T("btn_abbrechen"))

    OkKlick(*) {
        WarenbestandBekanntLokal := (CBIndikator = "" || !CBChecked)
        if WarenbestandBekanntLokal {
            if Felder.Has("Lager1")
                KistenLager1 := Integer(IsNumber(Felder["Lager1"].Value) ? Felder["Lager1"].Value : KistenLager1)
            if Felder.Has("Lager2")
                KistenLager2 := Integer(IsNumber(Felder["Lager2"].Value) ? Felder["Lager2"].Value : KistenLager2)
            if Felder.Has("Lager3")
                KistenLager3 := Integer(IsNumber(Felder["Lager3"].Value) ? Felder["Lager3"].Value : KistenLager3)
            if Felder.Has("Lager4")
                KistenLager4 := Integer(IsNumber(Felder["Lager4"].Value) ? Felder["Lager4"].Value : KistenLager4)
            if Felder.Has("Lager5")
                KistenLager5 := Integer(IsNumber(Felder["Lager5"].Value) ? Felder["Lager5"].Value : KistenLager5)
            if Felder.Has("Hangar")
                KistenHangar := Integer(IsNumber(Felder["Hangar"].Value) ? Felder["Hangar"].Value : KistenHangar)
        }
        if Felder.Has("Beliebtheit")
            NachtclubBeliebtheit := Integer(IsNumber(Felder["Beliebtheit"].Value) ? Felder["Beliebtheit"].Value : NachtclubBeliebtheit)

        Ergebnis := Map("abgebrochen", false, "warenbestand_bekannt", HatLager ? WarenbestandBekanntLokal : false, "sofort_starten", StartSofort)
        SDlg.Destroy()
    }
    AbbrechenKlick(*) {
        SDlg.Destroy()
    }

    BtnOK.OnEvent("Click", OkKlick)
    BtnAbbrechen.OnEvent("Click", AbbrechenKlick)
    SDlg.OnEvent("Close", AbbrechenKlick)
    SDlg.OnEvent("Escape", AbbrechenKlick)

    SDlg.Show("AutoSize xCenter yCenter")
    WinWaitClose("ahk_id " . SDlg.Hwnd)
    return Ergebnis
}

; =========================================================================
; 📦 LAGERHAUS-SETUP: EIN Fenster für alle bis zu 4 Sonderfracht-Lagerhäuser.
; Pro Lager per Dropdown die Größe wählen (oder "Nicht vorhanden").
; Größe bestimmt automatisch Kapazität + Preis pro Kiste.
; =========================================================================
; Wertet die Dropdown-AUSWAHL PER INDEX aus (sprachunabhängig, egal ob DE/EN):
; 1=Nicht vorhanden/Not owned, 2=Klein/Small, 3=Mittel/Medium, 4=Groß/Large
LagerGroesseAuswerten(AuswahlIndex, &Besitzt, &Max, &Preis) {
    if (AuswahlIndex = 1) {
        Besitzt := false
        Max := 0
        Preis := 0
        return
    }
    Besitzt := true
    if (AuswahlIndex = 2) {
        Max := 16
        Preis := 15000
    } else if (AuswahlIndex = 3) {
        Max := 42
        Preis := 17500
    } else {
        Max := 111
        Preis := 20000
    }
}

; =========================================================================
; 🔄 SPIELSTAND-SYNC: Shift+L - trägt den echten, im Spiel abgelesenen
; Kistenstand UND die aktuelle Nachtclub-Beliebtheit ein (nur für Unternehmen,
; die du laut Setup tatsächlich besitzt). Beides driftet über die Zeit vom
; echten Spielstand ab (Kisten durch die zufällige Schätzung, Beliebtheit
; falls du zwischendurch selbst was am Club machst); mit diesem Hotkey holst
; du beides zurück auf den korrekten Stand.
; WICHTIG: Wird außerdem automatisch VOR dem allerersten Start (Shift+P)
; aufgerufen, damit das Skript von Anfang an mit den richtigen Werten läuft.
; =========================================================================
+l::SpielstandSync()

; =========================================================================
; 🎚️ Shift+V: Nachtclub-Warenlager als "verkauft" markieren - setzt die
; Echtzeit-Schätzung zurück auf 0 (genau wie im Spiel nach der Verkaufsmission).
; =========================================================================
+v::
{
    global BesitztNachtclubWarenlager, NachtclubWarenlagerStartZeit
    if !BesitztNachtclubWarenlager
        return
    NachtclubWarenlagerStartZeit := A_Now
    SpeichereKistenstand()
    UpdateDashboard(T("warenlager_verkauft_markiert"))
    BestaetigungsBlitz()
}

; =========================================================================
; 📢 Shift+B: Event-Boni neu laden (experimentell, siehe AbrufeEventBoni()).
; =========================================================================
+b::
{
    UpdateDashboard(T("eventboni_wird_geladen_status"))
    AbrufeEventBoni()
    AktualisiereEventBoniAnzeige()
    UpdateDashboard(T("bereit"))
    BestaetigungsBlitz()
}

; =========================================================================
; 🔄 Shift+U: Manuell nach einem Update suchen (siehe PrüfeAufUpdate()).
; =========================================================================
+u::PrüfeAufUpdate(true)

; =========================================================================
; ⚡ Shift+2: "2x Speed CEO Fracht" ein-/ausschalten - auf Knopfdruck, für
; Event-Wochen mit doppelter Fracht-Geschwindigkeit. Ändert NUR das Intervall
; fürs Abholen der Sonderfracht-Lagerhäuser auf 24 Min. (siehe Sonderfracht-
; Schnelldurchlauf), der normale 48-Min-Rundenablauf läuft unverändert weiter.
; =========================================================================
+2::
{
    global SonderfrachtSchnellModusAktiv, BesitztLagerhaus

    if !BesitztLagerhaus {
        UpdateDashboard(T("sonderfracht_schnell_kein_lager"))
        return
    }

    SonderfrachtSchnellModusAktiv := !SonderfrachtSchnellModusAktiv
    if SonderfrachtSchnellModusAktiv {
        SetTimer(SonderfrachtSchnelldurchlauf, -(24 * 60000))
        UpdateDashboard(T("sonderfracht_schnell_aktiviert"))
    } else {
        SetTimer(SonderfrachtSchnelldurchlauf, 0)
        UpdateDashboard(T("sonderfracht_schnell_deaktiviert"))
    }
    AktualisiereSteuerungszeile()
    SpeichereKistenstand()
    BestaetigungsBlitz()
}

; Zeigt EventBoniListe/EventBoniFehler in den Dashboard-Controls an.
AktualisiereEventBoniAnzeige() {
    global EventBoniListe, EventBoniLetzteAktualisierung, EventBoniFehler, EventBoniQuelleUrl
    global EventBoniTextCtrl, EventBoniStatusCtrl

    if (EventBoniFehler != "") {
        EventBoniTextCtrl.Value := (EventBoniFehler = "keine_gefunden") ? TP("eventboni_leer", EventBoniQuelleUrl) : TP("eventboni_fehler", EventBoniQuelleUrl)
        EventBoniStatusCtrl.Value := ""
        return
    }

    Text := ""
    for Eintrag in EventBoniListe
        Text .= "• " . Eintrag . "   "
    EventBoniTextCtrl.Value := Text
    EventBoniStatusCtrl.Value := TP("eventboni_aktualisiert", EventBoniLetzteAktualisierung)
}

SpielstandSync() {
    global AutomationAktiv, ZielZeit, WarenbestandBekannt

    ; FIX: Alle Timer pausieren, BEVOR die Eingabefenster aufgehen - sonst
    ; könnte z.B. AntiAFK oder der 48-Min-Timer während der Eingabe feuern
    ; und Tasten senden (die dann sogar ins Eingabefeld rutschen könnten).
    SetTimer(HauptLoop, 0)
    SetTimer(AntiAFK, 0)
    SetTimer(CountdownTicker, 0)

    ; FIX: Warenbestand-Frage ist jetzt eine Checkbox INNERHALB desselben
    ; Fensters (siehe ZeigeSpielstandEingabe), kein separates Ja/Nein-Fenster
    ; mehr davor nötig.
    Ergebnis := ZeigeSpielstandEingabe(false)
    if !Ergebnis["abgebrochen"]
        WarenbestandBekannt := Ergebnis["warenbestand_bekannt"]

    SpeichereKistenstand()
    UpdateDashboard(T("spielstand_synchronisiert"))

    ; FIX: Timer nur reaktivieren, falls die Automatisierung vorher lief -
    ; und den 48-Min-Timer exakt mit der verbliebenen Restzeit fortsetzen,
    ; statt ihn komplett neu auf 48:00 zu setzen.
    if AutomationAktiv {
        SetTimer(CountdownTicker, 1000)
        SetTimer(AntiAFK, 8000)
        RestMs := ZielZeit - A_TickCount
        if (RestMs > 0)
            SetTimer(HauptLoop, -RestMs)
        else
            HauptLoop()
    }
}

StartAutomation() {
    global InfoGui, StartZeit, AutomationAktiv, ZielZeit, WarenbestandBekannt, RundenIntervallMinuten

    ; FIX: Unternehmen/Lager/Auto-Shutdown werden bereits EINMALIG beim
    ; Skriptstart im Komplett-Setup-Fenster festgelegt (siehe ZeigeKomplett-
    ; Setup() ganz am Anfang). Hier beim ersten Shift+P nur noch EIN Fenster:
    ; Spielstand (Kisten/Beliebtheit) + Start-Modus zusammen, statt vorher
    ; 3 separate Fenster (Sync, Bestätigung, Start-Modus) nacheinander.
    if (StartZeit = 0) {
        Ergebnis := ZeigeSpielstandEingabe(true)
        if Ergebnis["abgebrochen"] {
            UpdateDashboard(T("start_abgebrochen"))
            return
        }
        WarenbestandBekannt := Ergebnis["warenbestand_bekannt"]
        SpeichereKistenstand()

        if !Ergebnis["sofort_starten"] {
            StartZeit := A_TickCount
            AutomationAktiv := true
            InfoGui.Show("AutoSize xCenter y20 NoActivate")
            ; FIX: Timer direkt auf 48 Min setzen, OHNE AusfuehrenKombi()
            ; aufzurufen - dadurch werden auch keine Kisten/Einnahmen/
            ; Kosten für diese "leere" Runde addiert.
            ZielZeit := A_TickCount + (RundenIntervallMinuten * 60000)
            WaehleFlavorText()
            SetTimer(HauptLoop, -(RundenIntervallMinuten * 60000))
            SetTimer(CountdownTicker, 1000)
            SetTimer(AntiAFK, 8000)
            UpdateDashboard(T("cooldown_laeuft"))
            return
        }
    }

    InfoGui.Show("AutoSize xCenter y20 NoActivate")
    if (StartZeit = 0)
        StartZeit := A_TickCount
    AutomationAktiv := true
    SetTimer(CountdownTicker, 1000)
    AusfuehrenKombi()
}

PauseAutomation() {
    global AutomationAktiv
    AutomationAktiv := false
    SetTimer(HauptLoop, 0)
    SetTimer(AntiAFK, 0)
    SetTimer(CountdownTicker, 0)
    UpdateDashboard(T("automatisierung_pausiert"))
}

HauptLoop() {
    ; Cooldown ist durch -> kurz Richtung Stuhl laufen, bevor die Runde startet
    DrückeMenüTaste("a")
    Sleep(300)
    AusfuehrenKombi()
}

DrückeMenüTaste(Taste) {
    SendEvent("{" Taste " down}"), Sleep(50), SendEvent("{" Taste " up}")
}

DrückeTaste(Taste) {
    SendEvent("{" Taste " down}"), Sleep(200), SendEvent("{" Taste " up}")
}

; =========================================================================
; 🔁 GETEILTE DISPATCH-ENGINE: Führt eine beliebige Aktionen-Liste aus -
; genutzt sowohl vom vollen 48-Min-Rundenablauf (AusfuehrenKombi) als auch
; vom optionalen 24-Min-Sonderfracht-Schnelldurchlauf (SonderfrachtSchnell-
; durchlauf). So bleibt die Logik (Fenster aktivieren, Pause-Prüfung,
; Kisten-Tracking) an nur einer Stelle gepflegt.
; Rückgabe: Map mit "status" ("erfolg"/"pausiert"/"fenster_fehlt") und
; "vorheriges" (Fenstertitel, das vor dem Start aktiv war).
; =========================================================================
FuehreListeAus(Aktionen, StatusLaeuftText) {
    global AutomationAktiv, AutomatisierungBeschaeftigt, GTAFensterTitel
    global AusstehendLager1, AusstehendLager2, AusstehendLager3, AusstehendLager4, AusstehendLager5, AusstehendHangar

    AutomatisierungBeschaeftigt := true

    VorherigesFenster := WinExist("A") ? WinGetTitle("A") : ""
    if !WinExist(GTAFensterTitel) {
        UpdateDashboard(T("gta_fenster_nicht_gefunden"))
        AutomatisierungBeschaeftigt := false
        return Map("status", "fenster_fehlt", "vorheriges", VorherigesFenster)
    }
    WinActivate(GTAFensterTitel)
    if !WinWaitActive(GTAFensterTitel, , 5) {
        UpdateDashboard(T("gta_fenster_nicht_aktiviert"))
        AutomatisierungBeschaeftigt := false
        return Map("status", "fenster_fehlt", "vorheriges", VorherigesFenster)
    }

    UpdateDashboard(StatusLaeuftText)
    Sleep(1000)

    for Index, Element in Aktionen {
        if !AutomationAktiv {
            UpdateDashboard(T("automatisierung_pausiert_runde_abgebrochen"))
            if (VorherigesFenster != "" && WinExist(VorherigesFenster))
                WinActivate(VorherigesFenster)
            AutomatisierungBeschaeftigt := false
            return Map("status", "pausiert", "vorheriges", VorherigesFenster)
        }

        Taste := Element[1]
        Beschreibung := Element[2]

        UpdateDashboard(TP("aktion_praefix", Beschreibung))

        if (Taste = "Oben") {
            DrückeMenüTaste("Up")
            Sleep(1000)
        } else if (Taste = "Unten") {
            DrückeMenüTaste("Down")
            NaechsteTaste := (Index < Aktionen.Length) ? Aktionen[Index + 1][1] : ""
            if (NaechsteTaste = "Enter" || NaechsteTaste = "Enter1")
                Sleep(1000)
            else
                Sleep(200)
            continue
        } else if (Taste = "Rechts")
            DrückeMenüTaste("Right")
        else if (Taste = "Enter") {
            DrückeTaste("Enter"), Sleep(2000), DrückeTaste("Enter")
            Sleep(2000)
        } else if (Taste = "Enter1") {
            DrückeTaste("Enter")
            Sleep(2000)
        } else if (Taste = "Zurück")
            DrückeTaste("Backspace")

        if (Element.Length >= 3) {
            LagerTag := Element[3]
            GelieferteKisten := Random(1, 3)
            if (LagerTag = "Lager1")
                AusstehendLager1 += GelieferteKisten
            else if (LagerTag = "Lager2")
                AusstehendLager2 += GelieferteKisten
            else if (LagerTag = "Lager3")
                AusstehendLager3 += GelieferteKisten
            else if (LagerTag = "Lager4")
                AusstehendLager4 += GelieferteKisten
            else if (LagerTag = "Lager5")
                AusstehendLager5 += GelieferteKisten
            else if (LagerTag = "Hangar")
                AusstehendHangar += GelieferteKisten
        }

        Sleep(1000)
    }

    AutomatisierungBeschaeftigt := false
    return Map("status", "erfolg", "vorheriges", VorherigesFenster)
}

AusfuehrenKombi() {
    global RundenZaehler, TotalKosten, TotalSafeEinnahmen, TotalWarenMin, TotalWarenMax, TotalKautionMin, TotalKautionMax, KostenProLagerhaus, KostenHangar, SpielhalleEinnahmen, AgenturEinnahmen, SchrotthandelEinnahmen, TextilfabrikEinnahmen, WaschanlageEinnahmen, MinWarenProRunde, MaxWarenProRunde, MinKautionProRunde, MaxKautionProRunde, ZielZeit, KistenLager1, KistenLager2, KistenLager3, KistenLager4, KistenLager5, MaxKistenLager1, MaxKistenLager2, MaxKistenLager3, MaxKistenLager4, MaxKistenLager5, KistenHangar, MaxKistenHangar, NachtclubBeliebtheit, TotalNachtclubEinnahmen, AutomationAktiv, BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar, BesitztLagerhaus, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, GTAFensterTitel, ZielRundenAnzahl, AusstehendLager1, AusstehendLager2, AusstehendLager3, AusstehendLager4, AusstehendLager5, AusstehendHangar, AutomatisierungBeschaeftigt, RundenIntervallMinuten

    ; FIX: Falls der Sonderfracht-Schnelldurchlauf (2x-Speed) genau jetzt
    ; aktiv Tasten sendet, kurz warten und in 1 Min. erneut versuchen -
    ; niemals gleichzeitig Tasten aus zwei Quellen senden.
    if AutomatisierungBeschaeftigt {
        SetTimer(AusfuehrenKombi, -60000)
        return
    }

    SetTimer(AntiAFK, 0)
    SetTimer(CountdownTicker, 0)

    ; FIX: Erst die "ausstehenden" Kisten aus der VORHERIGEN Runde jetzt dem
    ; sichtbaren Lagerbestand zuschlagen (die sind jetzt fertig produziert) -
    ; danach auf 0 zurücksetzen, damit diese Runde neu gesammelt wird.
    KistenLager1 := Min(KistenLager1 + AusstehendLager1, MaxKistenLager1)
    KistenLager2 := Min(KistenLager2 + AusstehendLager2, MaxKistenLager2)
    KistenLager3 := Min(KistenLager3 + AusstehendLager3, MaxKistenLager3)
    KistenLager4 := Min(KistenLager4 + AusstehendLager4, MaxKistenLager4)
    KistenLager5 := Min(KistenLager5 + AusstehendLager5, MaxKistenLager5)
    KistenHangar := Min(KistenHangar + AusstehendHangar, MaxKistenHangar)
    AusstehendLager1 := 0, AusstehendLager2 := 0, AusstehendLager3 := 0
    AusstehendLager4 := 0, AusstehendLager5 := 0, AusstehendHangar := 0

    Ergebnis := FuehreListeAus(KombinationsListe(), T("einkauf_laeuft"))

    if (Ergebnis["status"] = "fenster_fehlt") {
        SetTimer(CountdownTicker, 1000)
        SetTimer(AntiAFK, 8000)
        SetTimer(AusfuehrenKombi, -10000)
        return
    }
    if (Ergebnis["status"] = "pausiert")
        return

    VorherigesFenster := Ergebnis["vorheriges"]

    ; Werte nach erfolgreicher Runde hochrechnen
    RundenZaehler++

    ; FIX: Kosten nur für tatsächlich besessene Lager-Slots (statt pauschal 4)
    ; + Hangar-Dispatch, falls jeweils besessen.
    AnzahlLager := (BesitztLager1?1:0) + (BesitztLager2?1:0) + (BesitztLager3?1:0) + (BesitztLager4?1:0) + (BesitztLager5?1:0)
    TotalKosten := RundenZaehler * (KostenProLagerhaus * AnzahlLager + (BesitztHangar ? KostenHangar : 0))

    ; FIX: Nachtclub-Einnahmen hängen von der aktuellen Beliebtheit ab (siehe
    ; BeliebtheitZuEinnahmen) statt einem festen Betrag. Nach der Abholung
    ; sinkt die Beliebtheit um 5%-Punkte (offizielle 48-Min-Spielmechanik).
    ; Nur berechnen, falls der Nachtclub tatsächlich besessen wird.
    if BesitztNachtclub {
        TotalNachtclubEinnahmen += BeliebtheitZuEinnahmen(NachtclubBeliebtheit)
        NachtclubBeliebtheit := Max(NachtclubBeliebtheit - 5, 0)
    }

    ; Spielhalle + Agentur + Schrotthandel + Textilfabrik + Waschanlage nur falls besessen, sonst 0
    TotalSafeEinnahmen := TotalNachtclubEinnahmen + RundenZaehler * ((BesitztSpielhalle ? SpielhalleEinnahmen : 0) + (BesitztAgentur ? AgenturEinnahmen : 0) + (BesitztSchrotthandel ? SchrotthandelEinnahmen : 0) + (BesitztTextilfabrik ? TextilfabrikEinnahmen : 0) + (BesitztWaschanlage ? WaschanlageEinnahmen : 0))

    ; Kistenstand + aktualisierte Beliebtheit dauerhaft speichern
    SpeichereKistenstand()

    ; FIX: Die Ware aus dem Fracht-Auftrag einer Runde ist erst NACH 48 Min.
    ; fertig produziert und wird erst in der darauffolgenden Runde abgeholt.
    ; In Runde 1 wurde gerade erst losgeschickt -> noch 0 fertige Ware.
    ; Gilt genauso für die Kautionsbüro-Agenten (auch die brauchen 48 Min.).
    ; Nur berechnen, falls Hangar/Lagerhaus bzw. Kautionsbüro besessen werden.
    WarenRunden := (RundenZaehler > 1) ? (RundenZaehler - 1) : 0
    if (BesitztHangar || BesitztLagerhaus) {
        TotalWarenMin := WarenRunden * MinWarenProRunde
        TotalWarenMax := WarenRunden * MaxWarenProRunde
    } else {
        TotalWarenMin := 0
        TotalWarenMax := 0
    }
    if BesitztKautionsbuero {
        TotalKautionMin := WarenRunden * MinKautionProRunde
        TotalKautionMax := WarenRunden * MaxKautionProRunde
    } else {
        TotalKautionMin := 0
        TotalKautionMax := 0
    }

    ; FIX: Falls eine Ziel-Rundenanzahl gesetzt ist und erreicht wurde, PC
    ; automatisch herunterfahren (60 Sek. Vorlaufzeit, per "shutdown /a" in
    ; der Kommandozeile abbrechbar) statt die nächste Runde zu starten.
    if (ZielRundenAnzahl > 0 && RundenZaehler >= ZielRundenAnzahl) {
        AutomationAktiv := false
        UpdateDashboard(TP("ziel_erreicht_shutdown", RundenZaehler))
        if (VorherigesFenster != "" && WinExist(VorherigesFenster))
            WinActivate(VorherigesFenster)
        Run("shutdown /s /t 60")
        AutomatisierungBeschaeftigt := false
        return
    }

    ; FIX: AFK-Phase beginnt genau JETZT (nach der Klick-Sequenz) ->
    ; Ziel- und Timer-Zeit erst hier auf +48 Min setzen, nicht schon vor der
    ; Sequenz. So startet der Countdown immer exakt bei 48:00.
    ZielZeit := A_TickCount + (RundenIntervallMinuten * 60000)
    WaehleFlavorText()
    SetTimer(HauptLoop, -(RundenIntervallMinuten * 60000))
    SetTimer(CountdownTicker, 1000)
    SetTimer(AntiAFK, 8000)

    ; FIX: Dein vorheriges Fenster (Browser o.ä.) wiederherstellen, damit du
    ; nahtlos dort weitermachen kannst, wo du warst, bevor die Runde GTA
    ; automatisch in den Vordergrund geholt hat.
    if (VorherigesFenster != "" && WinExist(VorherigesFenster))
        WinActivate(VorherigesFenster)

    ; Ab hier ist die Runde fertig - die AFK-Wartezeit beginnt, in der eine
    ; Update-Prüfung wieder unbedenklich ist.
    AutomatisierungBeschaeftigt := false
}

UpdateDashboard(StatusText) {
    global StatusCtrl, InfoGui, StartZeit, RundenZaehler, TotalKosten, TotalSafeEinnahmen, TotalWarenMin, TotalWarenMax, TotalKautionMin, TotalKautionMax, MinKautionProRunde, MaxKautionProRunde, KistenLager1, KistenLager2, KistenLager3, KistenLager4, KistenLager5, MaxKistenLager1, MaxKistenLager2, MaxKistenLager3, MaxKistenLager4, MaxKistenLager5, KistenHangar, MaxKistenHangar, PreisProKisteHangar, NachtclubBeliebtheit, PreisProKisteLager1, PreisProKisteLager2, PreisProKisteLager3, PreisProKisteLager4, PreisProKisteLager5, VolleLobbyBonus, BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar, BesitztLagerhaus, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, ZielRundenAnzahl, ZielZeit, AusstehendLager1, AusstehendLager2, AusstehendLager3, AusstehendLager4, AusstehendLager5, AusstehendHangar, WarenbestandBekannt, BesitztNachtclubWarenlager, NachtclubAusruestungGekauft, NachtclubWarenlagerStartZeit, NachtclubWarenlagerRateMitUpgrade, NachtclubWarenlagerRateOhneUpgrade, NachtclubWarenlagerMaxWert, RundenIntervallMinuten
    global ProfitGrossCtrl, ProfitDetailCtrl, CountdownBarCtrl, CountdownTextCtrl, ShutdownInfoCtrl, RundeCtrl, AfkZeitCtrl, KostenCtrl, EinnahmenCtrl, WarenwertCtrl
    global NachtclubBox, NCBarCtrl, NCPercentCtrl
    global WarenlagerBox, WarenlagerBarCtrl, WarenlagerPercentCtrl, WarenlagerInfoCtrl
    global LagerBox, Lager1Label, Lager1Bar, Lager1Wert, Lager2Label, Lager2Bar, Lager2Wert, Lager3Label, Lager3Bar, Lager3Wert, Lager4Label, Lager4Bar, Lager4Wert, Lager5Label, Lager5Bar, Lager5Wert, HangarLabel, HangarBar, HangarWertCtrl, GesamtwarenwertCtrl
    global DashboardSichtbar, AkzentFarbe

    ; FIX: Solange Shift+H das Dashboard versteckt hat, hier nichts neu
    ; anzeigen - sonst würde der nächste normale Update-Aufruf (z.B. der
    ; Countdown-Ticker) das Dashboard sofort wieder sichtbar machen.
    if !DashboardSichtbar
        return

    VergangeneStunden := 0, VergangeneMinuten := 0, VergangeneSekunden := 0, StundenAlsDezimal := 0
    if (StartZeit != 0) {
        MilliSeitStart := A_TickCount - StartZeit
        VergangeneStunden := Floor(MilliSeitStart / 3600000)
        VergangeneMinuten := Mod(Floor(MilliSeitStart / 60000), 60)
        VergangeneSekunden := Mod(Floor(MilliSeitStart / 1000), 60)
        StundenAlsDezimal := MilliSeitStart / 3600000
    }
    FormatierteMinuten := (VergangeneMinuten < 10) ? "0" VergangeneMinuten : VergangeneMinuten
    FormatierteSekundenAFK := (VergangeneSekunden < 10) ? "0" VergangeneSekunden : VergangeneSekunden

    ; Berechne Netto-Ergebnisse (Insgesamt) - inkl. Kautionsbüro-Agenten
    NettoMin := (TotalSafeEinnahmen + TotalWarenMin + TotalKautionMin) - TotalKosten
    NettoMax := (TotalSafeEinnahmen + TotalWarenMax + TotalKautionMax) - TotalKosten

    ; Berechne Gewinn pro Stunde (Echtzeit)
    ; FIX: Vor Abschluss der ersten vollen Runde ist der Nenner winzig ->
    ; Hochrechnung wäre absurd hoch. Deshalb erst ab Runde 2 berechnen.
    if (RundenZaehler > 1 && StundenAlsDezimal > 0) {
        GewinnProStundeMin := Floor(NettoMin / StundenAlsDezimal)
        GewinnProStundeMax := Floor(NettoMax / StundenAlsDezimal)
        GewinnProStundeText := "$" . FormatGeld(GewinnProStundeMin) . " – $" . FormatGeld(GewinnProStundeMax) . " " . T("pro_std_suffix")
    } else {
        GewinnProStundeText := T("gewinn_std_wird_berechnet")
    }

    ; ===================== STATUS-KARTE =====================
    if InStr(StatusText, "PAUSIERT") || InStr(StatusText, "PAUSED")
        StatusCtrl.SetFont("cFF5555")
    else if InStr(StatusText, "AKTION") || InStr(StatusText, "LÄUFT") || InStr(StatusText, "ACTION") || InStr(StatusText, "PROGRESS") || InStr(StatusText, "RUNNING")
        StatusCtrl.SetFont("cFFAA00")
    else
        StatusCtrl.SetFont("c00CCFF")
    StatusCtrl.Value := "STATUS: " . StatusText

    ; Countdown-Fortschrittsbalken: Anteil des Rundenintervalls, der bereits um ist
    if (IsSet(ZielZeit) && ZielZeit > 0) {
        IntervallMs := RundenIntervallMinuten * 60000
        RestMs := ZielZeit - A_TickCount
        if (RestMs < 0)
            RestMs := 0
        Fortschritt := Round((IntervallMs - RestMs) / IntervallMs * 100)
        if (Fortschritt > 100)
            Fortschritt := 100
        RestSek := Floor(RestMs / 1000)
        RestMin := Floor(RestSek / 60)
        RestSekRest := Mod(RestSek, 60)
        CountdownBarCtrl.Value := Fortschritt
        if (Fortschritt < 60)
            CountdownBarCtrl.Opt("c00FF00")
        else if (Fortschritt < 85)
            CountdownBarCtrl.Opt("cFFFF00")
        else
            CountdownBarCtrl.Opt("cFF0000")
        CountdownTextCtrl.Value := TPn("naechste_runde_in", RestMin, (RestSekRest < 10 ? "0" : "") . RestSekRest, Fortschritt)
    } else {
        CountdownBarCtrl.Value := 0
        CountdownTextCtrl.Value := T("noch_nicht_gestartet")
    }

    ; Shutdown-Info: nach wie vielen Runden der PC herunterfährt + die
    ; daraus resultierende voraussichtliche Gesamt-AFK-Zeit + die ungefähre
    ; tatsächliche Uhrzeit, zu der das passieren wird.
    if (ZielRundenAnzahl > 0) {
        VorausStunden := Floor(ZielRundenAnzahl * RundenIntervallMinuten / 60)
        VorausMinuten := Mod(ZielRundenAnzahl * RundenIntervallMinuten, 60)
        GesamtAFKMinuten := ZielRundenAnzahl * 48
        VergangeneMinutenSeitStart := (StartZeit != 0) ? (A_TickCount - StartZeit) / 60000 : 0
        RestMinuten := Max(0, GesamtAFKMinuten - VergangeneMinutenSeitStart)
        ShutdownUhrzeit := FormatTime(DateAdd(A_Now, Round(RestMinuten), "Minutes"), "HH:mm")
        ShutdownInfoCtrl.Value := TPn("shutdown_info_aktiv", ZielRundenAnzahl, RundenZaehler, VorausStunden, VorausMinuten, ShutdownUhrzeit)
    } else {
        ShutdownInfoCtrl.Value := T("auto_shutdown_deaktiviert")
    }

    ; ===================== FINANZEN-KARTE =====================
    RundeCtrl.Value := T("runde_label") . ": " . RundenZaehler
    AfkZeitCtrl.Value := T("gesamte_afk_zeit_label") . ": " . VergangeneStunden . ":" . FormatierteMinuten . ":" . FormatierteSekundenAFK . " " . T("std_kurz")
    KostenCtrl.Value := T("mitarbeiter_kosten_label") . ": $" . FormatGeld(TotalKosten)

    BarGeldLabel := T("bar_geld_label") . " ("
    if BesitztNachtclub
        BarGeldLabel .= T("club_kurz") . " "
    if BesitztSpielhalle
        BarGeldLabel .= T("arcade_kurz") . " "
    if BesitztAgentur
        BarGeldLabel .= T("biz_agentur") . " "
    if BesitztSchrotthandel
        BarGeldLabel .= T("biz_schrotthandel") . " "
    if BesitztTextilfabrik
        BarGeldLabel .= T("biz_textilfabrik") . " "
    if BesitztWaschanlage
        BarGeldLabel .= T("biz_waschanlage") . " "
    BarGeldLabel .= ")"
    EinnahmenZeile := BarGeldLabel . ": $" . FormatGeld(TotalSafeEinnahmen)
    if BesitztKautionsbuero
        EinnahmenZeile .= "   |   " . T("biz_kautionsbuero") . ": $" . FormatGeld(TotalKautionMin) . " – $" . FormatGeld(TotalKautionMax)
    EinnahmenCtrl.Value := EinnahmenZeile

    if (BesitztHangar || BesitztLagerhaus)
        WarenwertCtrl.Value := T("warenwert_seit_afk_label") . ": $" . FormatGeld(TotalWarenMin) . " – $" . FormatGeld(TotalWarenMax)
    else
        WarenwertCtrl.Value := ""

    ; ===================== NACHTCLUB / WARENLAGER / EVENT-BONI / LAGER: =====================
    ; Diese 4 Karten stehen hintereinander, aber Nachtclub und Warenlager sind
    ; jeweils NUR sichtbar, falls besessen/aktiviert - deshalb hier die Ketten-
    ; Position dynamisch neu berechnen, statt der festen Erstellungsposition,
    ; sonst bleibt bei fehlendem Nachtclub/Warenlager eine leere Lücke stehen.
    static BasisX := 0, BasisY := 0, BasisGemerkt := false
    if !BasisGemerkt {
        NachtclubBox.GetPos(&BasisX, &BasisY)
        BasisGemerkt := true
    }
    KY := BasisY

    NachtclubBox.Visible := BesitztNachtclub
    NachtclubStreifen.Visible := BesitztNachtclub
    NCBarCtrl.Visible := BesitztNachtclub
    NCPercentCtrl.Visible := BesitztNachtclub
    if BesitztNachtclub {
        NachtclubBox.Move(, KY)
        NachtclubStreifen.Move(, KY + 1)
        NCBarCtrl.Move(BasisX + 15, KY + 17)
        NCPercentCtrl.Move(BasisX + 793, KY + 18)
        NCBarCtrl.Value := NachtclubBeliebtheit
        if (NachtclubBeliebtheit >= 60)
            NCBarCtrl.Opt("c00FF00")
        else if (NachtclubBeliebtheit >= 30)
            NCBarCtrl.Opt("cFFFF00")
        else
            NCBarCtrl.Opt("cFF0000")
        NCPercentCtrl.Value := NachtclubBeliebtheit . "%"
        KY += 44 + 8
    }

    WarenlagerBox.Visible := BesitztNachtclubWarenlager
    WarenlagerStreifen.Visible := BesitztNachtclubWarenlager
    WarenlagerBarCtrl.Visible := BesitztNachtclubWarenlager
    WarenlagerPercentCtrl.Visible := BesitztNachtclubWarenlager
    WarenlagerInfoCtrl.Visible := BesitztNachtclubWarenlager
    if BesitztNachtclubWarenlager {
        WarenlagerBox.Move(, KY)
        WarenlagerStreifen.Move(, KY + 1)
        WarenlagerBarCtrl.Move(BasisX + 15, KY + 17)
        WarenlagerPercentCtrl.Move(BasisX + 793, KY + 18)
        WarenlagerInfoCtrl.Move(BasisX + 15, KY + 38)
        Rate := NachtclubAusruestungGekauft ? NachtclubWarenlagerRateMitUpgrade : NachtclubWarenlagerRateOhneUpgrade
        VergangeneSekundenWL := (NachtclubWarenlagerStartZeit != "") ? DateDiff(A_Now, NachtclubWarenlagerStartZeit, "Seconds") : 0
        VergangeneStundenWL := VergangeneSekundenWL / 3600
        GeschaetzterWert := Min(Round(VergangeneStundenWL * Rate), NachtclubWarenlagerMaxWert)
        ProzentWL := Round(GeschaetzterWert / NachtclubWarenlagerMaxWert * 100)
        WarenlagerBarCtrl.Value := ProzentWL
        WarenlagerBarCtrl.Opt(ProzentWL >= 100 ? "cFFFF00" : "c" . AkzentFarbe)
        WarenlagerPercentCtrl.Value := ProzentWL . "%"
        WarenlagerInfoCtrl.Value := TPn("warenlager_geschaetzt", FormatGeld(GeschaetzterWert), FormatGeld(NachtclubWarenlagerMaxWert), Round(VergangeneStundenWL, 1))
        KY += 58 + 8
    }

    ; EVENT-BONI: immer sichtbar (nicht ownership-abhängig), rückt aber mit
    ; hoch, falls Nachtclub/Warenlager oben fehlen.
    EventBoniBox.Move(, KY)
    EventBoniStreifen.Move(, KY + 1)
    EventBoniTextCtrl.Move(BasisX + 15, KY + 17)
    EventBoniStatusCtrl.Move(BasisX + 15, KY + 56)
    KY += 74 + 8

    ; LAGER & HANGAR: an die neue Kettenposition verschieben - die
    ; nachfolgende Packing-Logik liest die Position gleich per GetPos() aus.
    LagerBox.Move(, KY)
    LagerStreifen.Move(, KY + 1)

    ; ===================== LAGER & HANGAR-KARTE =====================
    LagerBox.Visible := (BesitztLagerhaus || BesitztHangar) && WarenbestandBekannt

    Lager1Sicht := BesitztLager1 && WarenbestandBekannt
    Lager2Sicht := BesitztLager2 && WarenbestandBekannt
    Lager3Sicht := BesitztLager3 && WarenbestandBekannt
    Lager4Sicht := BesitztLager4 && WarenbestandBekannt
    Lager5Sicht := BesitztLager5 && WarenbestandBekannt
    HangarSicht := BesitztHangar && WarenbestandBekannt

    Lager1Label.Visible := Lager1Sicht, Lager1Bar.Visible := Lager1Sicht, Lager1Wert.Visible := Lager1Sicht
    Lager2Label.Visible := Lager2Sicht, Lager2Bar.Visible := Lager2Sicht, Lager2Wert.Visible := Lager2Sicht
    Lager3Label.Visible := Lager3Sicht, Lager3Bar.Visible := Lager3Sicht, Lager3Wert.Visible := Lager3Sicht
    Lager4Label.Visible := Lager4Sicht, Lager4Bar.Visible := Lager4Sicht, Lager4Wert.Visible := Lager4Sicht
    Lager5Label.Visible := Lager5Sicht, Lager5Bar.Visible := Lager5Sicht, Lager5Wert.Visible := Lager5Sicht
    HangarLabel.Visible := HangarSicht, HangarBar.Visible := HangarSicht, HangarWertCtrl.Visible := HangarSicht

    LagerWertGesamt := 0, LagerWertGesamtBonus := 0

    if BesitztLager1 {
        Lager1Bar.Value := Round(KistenLager1 / MaxKistenLager1 * 100)
        W := KistenLager1 * PreisProKisteLager1
        AW := AusstehendLager1 * PreisProKisteLager1
        Lager1Wert.Value := KistenLager1 . "/" . MaxKistenLager1 . " ($" . FormatGeld(W) . ")" . (AusstehendLager1 > 0 ? "  +" . AusstehendLager1 . " ausstehend ($" . FormatGeld(AW) . ")" : "")
        LagerWertGesamt += W
        LagerWertGesamtBonus += Round(W * (1 + VolleLobbyBonus))
    }
    if BesitztLager2 {
        Lager2Bar.Value := Round(KistenLager2 / MaxKistenLager2 * 100)
        W := KistenLager2 * PreisProKisteLager2
        AW := AusstehendLager2 * PreisProKisteLager2
        Lager2Wert.Value := KistenLager2 . "/" . MaxKistenLager2 . " ($" . FormatGeld(W) . ")" . (AusstehendLager2 > 0 ? "  +" . AusstehendLager2 . " ausstehend ($" . FormatGeld(AW) . ")" : "")
        LagerWertGesamt += W
        LagerWertGesamtBonus += Round(W * (1 + VolleLobbyBonus))
    }
    if BesitztLager3 {
        Lager3Bar.Value := Round(KistenLager3 / MaxKistenLager3 * 100)
        W := KistenLager3 * PreisProKisteLager3
        AW := AusstehendLager3 * PreisProKisteLager3
        Lager3Wert.Value := KistenLager3 . "/" . MaxKistenLager3 . " ($" . FormatGeld(W) . ")" . (AusstehendLager3 > 0 ? "  +" . AusstehendLager3 . " ausstehend ($" . FormatGeld(AW) . ")" : "")
        LagerWertGesamt += W
        LagerWertGesamtBonus += Round(W * (1 + VolleLobbyBonus))
    }
    if BesitztLager4 {
        Lager4Bar.Value := Round(KistenLager4 / MaxKistenLager4 * 100)
        W := KistenLager4 * PreisProKisteLager4
        AW := AusstehendLager4 * PreisProKisteLager4
        Lager4Wert.Value := KistenLager4 . "/" . MaxKistenLager4 . " ($" . FormatGeld(W) . ")" . (AusstehendLager4 > 0 ? "  +" . AusstehendLager4 . " ausstehend ($" . FormatGeld(AW) . ")" : "")
        LagerWertGesamt += W
        LagerWertGesamtBonus += Round(W * (1 + VolleLobbyBonus))
    }
    if BesitztLager5 {
        Lager5Bar.Value := Round(KistenLager5 / MaxKistenLager5 * 100)
        W := KistenLager5 * PreisProKisteLager5
        AW := AusstehendLager5 * PreisProKisteLager5
        Lager5Wert.Value := KistenLager5 . "/" . MaxKistenLager5 . " ($" . FormatGeld(W) . ")" . (AusstehendLager5 > 0 ? "  +" . AusstehendLager5 . " ausstehend ($" . FormatGeld(AW) . ")" : "")
        LagerWertGesamt += W
        LagerWertGesamtBonus += Round(W * (1 + VolleLobbyBonus))
    }

    HangarWert := 0, HangarWertBonus := 0
    if BesitztHangar {
        HangarWert := KistenHangar * PreisProKisteHangar
        HangarWertBonus := Round(HangarWert * (1 + VolleLobbyBonus))
        AWHangar := AusstehendHangar * PreisProKisteHangar
        HangarBar.Value := Round(KistenHangar / MaxKistenHangar * 100)
        HangarWertCtrl.Value := KistenHangar . "/" . MaxKistenHangar . " ($" . FormatGeld(HangarWert) . ")" . (AusstehendHangar > 0 ? "  +" . AusstehendHangar . " ausstehend ($" . FormatGeld(AWHangar) . ")" : "")
    }

    if (BesitztLagerhaus || BesitztHangar) && WarenbestandBekannt {
        GesamtWarenwert := LagerWertGesamt + HangarWert
        GesamtWarenwertBonus := LagerWertGesamtBonus + HangarWertBonus
        GesamtwarenwertCtrl.Value := TPn("gesamtwarenwert_label", FormatGeld(GesamtWarenwert), FormatGeld(GesamtWarenwertBonus))
        GesamtwarenwertCtrl.Visible := true
    } else {
        GesamtwarenwertCtrl.Value := ""
        GesamtwarenwertCtrl.Visible := false
    }

    ; FIX: Zeilen dynamisch lückenlos packen - nicht besessene Lager/Hangar
    ; sollen keine leere Lücke hinterlassen. Karte wird auf die tatsächlich
    ; benötigte Höhe verkleinert, statt immer volle 6 Zeilen Platz zu reservieren.
    LagerBox.GetPos(&LagerBoxX2, &LagerBoxY2)
    InnenX2 := LagerBoxX2 + 15
    BarX2 := LagerBoxX2 + 150
    WertX2 := LagerBoxX2 + 510
    PackY := LagerBoxY2 + 17
    ZeilenHoehe2 := 19
    SichtbareZeilen := 0

    LagerEintraege := [
        [Lager1Sicht, Lager1Label, Lager1Bar, Lager1Wert],
        [Lager2Sicht, Lager2Label, Lager2Bar, Lager2Wert],
        [Lager3Sicht, Lager3Label, Lager3Bar, Lager3Wert],
        [Lager4Sicht, Lager4Label, Lager4Bar, Lager4Wert],
        [Lager5Sicht, Lager5Label, Lager5Bar, Lager5Wert],
        [HangarSicht, HangarLabel, HangarBar, HangarWertCtrl]
    ]
    for Eintrag in LagerEintraege {
        Besitzt := Eintrag[1], ZLabel := Eintrag[2], ZBar := Eintrag[3], ZWert := Eintrag[4]
        if Besitzt {
            ZLabel.Move(InnenX2, PackY)
            ZBar.Move(BarX2, PackY - 2)
            ZWert.Move(WertX2, PackY)
            PackY += ZeilenHoehe2
            SichtbareZeilen += 1
        }
    }

    if (SichtbareZeilen > 0) {
        GesamtwarenwertCtrl.Move(InnenX2, PackY + 4)
        NeueLagerBoxHoehe := (PackY + 4 + 22) - LagerBoxY2
        LagerBox.Move(, , , NeueLagerBoxHoehe)
    }

    ; ===================== GROSSE GEWINN-ANZEIGE =====================
    ProfitGrossCtrl.Value := "$" . FormatGeld(NettoMin) . " – $" . FormatGeld(NettoMax)
    ProfitGrossCtrl.SetFont((NettoMin >= 0 ? "c00FF88" : "cFF5555"))
    ProfitDetailCtrl.Value := GewinnProStundeText

    ; FIX: Fenster nach jeder Aktualisierung erneut mit AutoSize anzeigen,
    ; damit die Fenstergröße zum Inhalt passt und "AlwaysOnTop" gegenüber
    ; dem Spielfenster durchgesetzt bleibt.
    InfoGui.Show("AutoSize xCenter y20 NoActivate")
}

; Fügt Tausenderpunkte in Geldbeträge ein, z.B. 3502500 -> 3.502.500
FormatGeld(Betrag) {
    Text := Betrag . ""
    Negativ := (SubStr(Text, 1, 1) = "-")
    if Negativ
        Text := SubStr(Text, 2)
    Ergebnis := ""
    Laenge := StrLen(Text)
    Loop Laenge {
        Pos := Laenge - A_Index + 1
        Ergebnis := SubStr(Text, Pos, 1) . Ergebnis
        if (Mod(A_Index, 3) = 0 && A_Index < Laenge)
            Ergebnis := "." . Ergebnis
    }
    return (Negativ ? "-" : "") . Ergebnis
}

; Nachtclub-Safe-Einnahmen pro 48-Min-Runde nach aktueller Beliebtheit (offizielle Tabelle)
BeliebtheitZuEinnahmen(Beliebtheit) {
    if (Beliebtheit >= 95)
        return 50000
    else if (Beliebtheit >= 90)
        return 45000
    else if (Beliebtheit >= 85)
        return 25000
    else if (Beliebtheit >= 80)
        return 24000
    else if (Beliebtheit >= 75)
        return 23000
    else if (Beliebtheit >= 70)
        return 22000
    else if (Beliebtheit >= 65)
        return 21000
    else if (Beliebtheit >= 60)
        return 20000
    else if (Beliebtheit >= 55)
        return 10000
    else if (Beliebtheit >= 50)
        return 9500
    else if (Beliebtheit >= 45)
        return 9000
    else if (Beliebtheit >= 40)
        return 8500
    else if (Beliebtheit >= 35)
        return 8000
    else if (Beliebtheit >= 30)
        return 2500
    else if (Beliebtheit >= 25)
        return 2200
    else if (Beliebtheit >= 20)
        return 2000
    else if (Beliebtheit >= 15)
        return 1800
    else if (Beliebtheit >= 10)
        return 1600
    else
        return 1500
}

; Lädt den Kistenstand + Nachtclub-Beliebtheit + Unternehmens-Besitz aus der INI-Datei
LadeKistenstand() {
    global KistenDateiPfad, KistenLager1, KistenLager2, KistenLager3, KistenLager4, KistenLager5, KistenHangar, NachtclubBeliebtheit, BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar, BesitztLagerhaus, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, MaxKistenLager1, MaxKistenLager2, MaxKistenLager3, MaxKistenLager4, MaxKistenLager5, PreisProKisteLager1, PreisProKisteLager2, PreisProKisteLager3, PreisProKisteLager4, PreisProKisteLager5, AusstehendLager1, AusstehendLager2, AusstehendLager3, AusstehendLager4, AusstehendLager5, AusstehendHangar, BesitztNachtclubWarenlager, NachtclubAusruestungGekauft, NachtclubWarenlagerStartZeit, RundenIntervallMinuten, SonderfrachtSchnellModusAktiv
    SonderfrachtSchnellModusAktiv := Integer(IniRead(KistenDateiPfad, "Einstellungen", "SonderfrachtSchnellModus", 0))
    if SonderfrachtSchnellModusAktiv
        SetTimer(SonderfrachtSchnelldurchlauf, -(24 * 60000))
    KistenLager1 := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Lager1", 0))
    KistenLager2 := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Lager2", 0))
    KistenLager3 := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Lager3", 0))
    KistenLager4 := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Lager4", 0))
    KistenLager5 := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Lager5", 0))
    KistenHangar := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Hangar", 0))
    AusstehendLager1 := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Lager1", 0))
    AusstehendLager2 := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Lager2", 0))
    AusstehendLager3 := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Lager3", 0))
    AusstehendLager4 := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Lager4", 0))
    AusstehendLager5 := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Lager5", 0))
    AusstehendHangar := Integer(IniRead(KistenDateiPfad, "Ausstehend", "Hangar", 0))
    NachtclubBeliebtheit := Integer(IniRead(KistenDateiPfad, "Lagerstand", "Beliebtheit", 100))
    BesitztNachtclub := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Nachtclub", 1))
    BesitztSpielhalle := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Spielhalle", 1))
    BesitztAgentur := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Agentur", 1))
    BesitztSchrotthandel := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Schrotthandel", 1))
    BesitztKautionsbuero := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Kautionsbuero", 1))
    BesitztTextilfabrik := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Textilfabrik", 1))
    BesitztWaschanlage := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Waschanlage", 1))
    BesitztHangar := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Hangar", 1))
    BesitztLager1 := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Lager1", 1))
    BesitztLager2 := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Lager2", 1))
    BesitztLager3 := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Lager3", 1))
    BesitztLager4 := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Lager4", 1))
    BesitztLager5 := Integer(IniRead(KistenDateiPfad, "Unternehmen", "Lager5", 1))
    BesitztLagerhaus := BesitztLager1 || BesitztLager2 || BesitztLager3 || BesitztLager4 || BesitztLager5
    MaxKistenLager1 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Max1", 16))
    MaxKistenLager2 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Max2", 111))
    MaxKistenLager3 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Max3", 111))
    MaxKistenLager4 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Max4", 111))
    MaxKistenLager5 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Max5", 111))
    PreisProKisteLager1 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Preis1", 15000))
    PreisProKisteLager2 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Preis2", 20000))
    PreisProKisteLager3 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Preis3", 20000))
    PreisProKisteLager4 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Preis4", 20000))
    PreisProKisteLager5 := Integer(IniRead(KistenDateiPfad, "Lagergroesse", "Preis5", 20000))
    BesitztNachtclubWarenlager := Integer(IniRead(KistenDateiPfad, "Warenlager", "Aktiv", 0))
    NachtclubAusruestungGekauft := Integer(IniRead(KistenDateiPfad, "Warenlager", "Ausruestung", 0))
    NachtclubWarenlagerStartZeit := IniRead(KistenDateiPfad, "Warenlager", "StartZeit", "")
}

; Schreibt den aktuellen Kistenstand + Nachtclub-Beliebtheit + Unternehmens-Besitz in die INI-Datei
SpeichereKistenstand() {
    global KistenDateiPfad, KistenLager1, KistenLager2, KistenLager3, KistenLager4, KistenLager5, KistenHangar, NachtclubBeliebtheit, BesitztNachtclub, BesitztSpielhalle, BesitztAgentur, BesitztSchrotthandel, BesitztKautionsbuero, BesitztTextilfabrik, BesitztWaschanlage, BesitztHangar, BesitztLager1, BesitztLager2, BesitztLager3, BesitztLager4, BesitztLager5, MaxKistenLager1, MaxKistenLager2, MaxKistenLager3, MaxKistenLager4, MaxKistenLager5, PreisProKisteLager1, PreisProKisteLager2, PreisProKisteLager3, PreisProKisteLager4, PreisProKisteLager5, AusstehendLager1, AusstehendLager2, AusstehendLager3, AusstehendLager4, AusstehendLager5, AusstehendHangar, BesitztNachtclubWarenlager, NachtclubAusruestungGekauft, NachtclubWarenlagerStartZeit, RundenIntervallMinuten, SonderfrachtSchnellModusAktiv
    IniWrite(SonderfrachtSchnellModusAktiv, KistenDateiPfad, "Einstellungen", "SonderfrachtSchnellModus")
    IniWrite(KistenLager1, KistenDateiPfad, "Lagerstand", "Lager1")
    IniWrite(KistenLager2, KistenDateiPfad, "Lagerstand", "Lager2")
    IniWrite(KistenLager3, KistenDateiPfad, "Lagerstand", "Lager3")
    IniWrite(KistenLager4, KistenDateiPfad, "Lagerstand", "Lager4")
    IniWrite(KistenLager5, KistenDateiPfad, "Lagerstand", "Lager5")
    IniWrite(KistenHangar, KistenDateiPfad, "Lagerstand", "Hangar")
    IniWrite(AusstehendLager1, KistenDateiPfad, "Ausstehend", "Lager1")
    IniWrite(AusstehendLager2, KistenDateiPfad, "Ausstehend", "Lager2")
    IniWrite(AusstehendLager3, KistenDateiPfad, "Ausstehend", "Lager3")
    IniWrite(AusstehendLager4, KistenDateiPfad, "Ausstehend", "Lager4")
    IniWrite(AusstehendLager5, KistenDateiPfad, "Ausstehend", "Lager5")
    IniWrite(AusstehendHangar, KistenDateiPfad, "Ausstehend", "Hangar")
    IniWrite(NachtclubBeliebtheit, KistenDateiPfad, "Lagerstand", "Beliebtheit")
    IniWrite(BesitztNachtclub, KistenDateiPfad, "Unternehmen", "Nachtclub")
    IniWrite(BesitztSpielhalle, KistenDateiPfad, "Unternehmen", "Spielhalle")
    IniWrite(BesitztAgentur, KistenDateiPfad, "Unternehmen", "Agentur")
    IniWrite(BesitztSchrotthandel, KistenDateiPfad, "Unternehmen", "Schrotthandel")
    IniWrite(BesitztKautionsbuero, KistenDateiPfad, "Unternehmen", "Kautionsbuero")
    IniWrite(BesitztTextilfabrik, KistenDateiPfad, "Unternehmen", "Textilfabrik")
    IniWrite(BesitztWaschanlage, KistenDateiPfad, "Unternehmen", "Waschanlage")
    IniWrite(BesitztHangar, KistenDateiPfad, "Unternehmen", "Hangar")
    IniWrite(BesitztLager1, KistenDateiPfad, "Unternehmen", "Lager1")
    IniWrite(BesitztLager2, KistenDateiPfad, "Unternehmen", "Lager2")
    IniWrite(BesitztLager3, KistenDateiPfad, "Unternehmen", "Lager3")
    IniWrite(BesitztLager4, KistenDateiPfad, "Unternehmen", "Lager4")
    IniWrite(BesitztLager5, KistenDateiPfad, "Unternehmen", "Lager5")
    IniWrite(MaxKistenLager1, KistenDateiPfad, "Lagergroesse", "Max1")
    IniWrite(MaxKistenLager2, KistenDateiPfad, "Lagergroesse", "Max2")
    IniWrite(MaxKistenLager3, KistenDateiPfad, "Lagergroesse", "Max3")
    IniWrite(MaxKistenLager4, KistenDateiPfad, "Lagergroesse", "Max4")
    IniWrite(MaxKistenLager5, KistenDateiPfad, "Lagergroesse", "Max5")
    IniWrite(PreisProKisteLager1, KistenDateiPfad, "Lagergroesse", "Preis1")
    IniWrite(PreisProKisteLager2, KistenDateiPfad, "Lagergroesse", "Preis2")
    IniWrite(PreisProKisteLager3, KistenDateiPfad, "Lagergroesse", "Preis3")
    IniWrite(PreisProKisteLager4, KistenDateiPfad, "Lagergroesse", "Preis4")
    IniWrite(PreisProKisteLager5, KistenDateiPfad, "Lagergroesse", "Preis5")
    IniWrite(BesitztNachtclubWarenlager, KistenDateiPfad, "Warenlager", "Aktiv")
    IniWrite(NachtclubAusruestungGekauft, KistenDateiPfad, "Warenlager", "Ausruestung")
    IniWrite(NachtclubWarenlagerStartZeit, KistenDateiPfad, "Warenlager", "StartZeit")
}

CountdownTicker() {
    global ZielZeit, AktuellerFlavorText
    if !IsSet(ZielZeit)
        return
    VerbleibendeMillisekunden := ZielZeit - A_TickCount
    if (VerbleibendeMillisekunden > 0)
        UpdateDashboard(AktuellerFlavorText != "" ? AktuellerFlavorText : T("afk_wartezeit_laeuft"))
}

; FIX: Während der AFK-Wartezeit wird jetzt alle paar Sekunden kurz das
; Handy geöffnet und wieder geschlossen (Hoch, dann Zurück), statt sich zu
; bewegen. Das reicht gegen den Inaktivitäts-Kick, ohne die Position zu
; verändern. Erst wenn der Cooldown durch ist, läuft man kurz per D-Tap
; Richtung Stuhl (siehe HauptLoop).
AntiAFK() {
    global GTAFensterTitel
    ; FIX: Nur ausführen, wenn GTA gerade das aktive Fenster ist - sonst
    ; würden diese Tasten in ein anderes Programm gesendet, während du am
    ; PC etwas anderes machst. Einfach überspringen und beim nächsten Mal
    ; (in 8 Sek.) erneut versuchen.
    if !WinActive(GTAFensterTitel)
        return
    DrückeMenüTaste("Up")        ; Handy öffnen
    Sleep(1500)                  ; FIX: mehr Zeit, damit GTA die Aktion sicher als Aktivität zählt
    DrückeTaste("Backspace")     ; Handy wieder schließen
}

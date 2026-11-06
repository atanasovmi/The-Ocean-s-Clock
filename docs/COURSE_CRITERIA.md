# Bewertungskriterien: wo sie sich prüfen lassen

Diese Seite ordnet die veröffentlichten Kriterien der Leistungsbewertung den Stellen im Projekt zu, an denen sie sich nachprüfen lassen. Die Beurteilung liegt bei Jury und Dozierenden. Wir möchten sie nur einfach machen und nennen deshalb auch die Grenzen unserer Arbeit.

Entstanden in der Blockwoche Applied Data Science an der FHNW, von Mihael Atanasov und Pirasanna Siva.

## Die Kriterien im Einzelnen

| Kriterium | Was wir getan haben | Wo prüfen |
| --- | --- | --- |
| **Interessante und relevante Leitfragen** | Drei Leitfragen zu einem Naturphänomen, das Riffmonitoring und Riffrestaurierung betrifft. Sie stehen auf Folie 2 und werden unten einzeln beantwortet. | [Forschungsnotizen](RESEARCH.md) |
| **Komplexität der Datenlage** | Sechs Hauptquellen und eine Kontrollquelle, rund 23,1 Millionen Werte. Die Formate reichen von einem Excel-Export über 214 komprimierte Textdateien, GeoJSON-Polygone und JSON aus einer API bis zu einer Tabelle in einem PDF. | [README](../README.md#how-the-sources-connect), [`data/raw/`](../data/raw/) |
| **Saubere Aufbereitung** | Explizite Joins über IDs, die 6'178 Zeilen bleiben erhalten. Codes wie `-99` werden zu fehlenden Werten, fehlende Tage bleiben fehlend. Die Spalte `spawning_binary` zählt in Wahrheit Becken und wird umgewandelt. 60 `stopifnot()`-Aufrufe stoppen den Lauf bei Abweichungen. | [`R/prepare_coral.R`](../R/prepare_coral.R), [`R/check_results.R`](../R/check_results.R), [Validierung](VALIDATION.md) |
| **Best Practices, Skalenniveaus** | Keine Kuchendiagramme. Jahr, Mondmonat und Tag sind zyklische Grössen, darum nutzen wir zirkuläre Statistik und Zifferblätter. Balken beginnen bei null. Die Hitzestufen sind ordinal und haben eine geordnete Farbrampe. | [`R/analyse_clocks.R`](../R/analyse_clocks.R), [Plot 1](../outputs/figures/01_three_clocks.png) |
| **Farbe, auch für Farbenblinde** | Jede Farbe hat auf allen Plots dieselbe Aufgabe. Rosa, Gold und Blau bleiben bei simulierter Farbenblindheit unterscheidbar (kleinster ΔE 9,4 bei Deuteranopie). Farbe trägt nie allein: Zeilen, Positionen und direkte Beschriftungen zeigen dieselbe Information. | [`R/plots/style.R`](../R/plots/style.R), [Validierung](VALIDATION.md#timing-and-visual-checks) |
| **Sinnvolle Skalen und Achsen** | Achsen in natürlichen Einheiten: Tage ab Vollmond, Stunden nach Sonnenuntergang, Tage zur wärmsten Woche. Das Mondlicht ist als Wurzel skaliert, und das steht in der Methode. Nenner stehen bei den Prozentzahlen. | [Plot 3](../outputs/figures/03_moon.png), [Methoden](METHODS.md#rebuilding-the-sky) |
| **Perfektion der Details (`theme()`)** | Ein gemeinsames Theme mit eigener Schrifthierarchie aus Schnitten der Bahnschrift, dazu 23 `theme()`-Aufrufe in den Plot-Skripten. Export als PNG mit 300 dpi und als SVG, jeder Plot in voller Grösse auf Kollisionen geprüft. | [`R/plots/style.R`](../R/plots/style.R), [`outputs/vector/`](../outputs/vector/) |
| **Selbsterklärend** | Der Titel jedes Plots nennt den Befund. Legenden zeigen die echten Markierungen und stehen ausserhalb der Datenfläche. Kennzahlen werden auf dem Plot erklärt, und auf Plot 9 zeigt jede Notiz mit einer Linie auf ihre Markierung. | [Plot 9](../outputs/figures/09_genera.png), [Lesehilfe](PLOT_GUIDE.md) |
| **Kreativität, eigene Ideen** | Über die Cases hinaus: Zifferblätter für drei Zyklen, ein selbst berechneter Himmel (Plots 4 und 4.01), ein Hitze-Index mit festem Laichkalender und Modelle, die ganze Jahre zurückhalten. Für R haben wir eine animierte Erklärung gebaut. | [Plot 4](../outputs/figures/04_sky.png), [`docs/r_explainer.svg`](r_explainer.svg) |
| **Leitfragen beantwortet** | Siehe unten, jede Antwort mit ihrer Grenze. | [Ergebnisse](../outputs/RESULTS.md) |

## Leitfragen und Antworten

| Leitfrage | Antwort aus den Visualisierungen | Grenze |
| --- | --- | --- |
| Wie wissen Korallenriffe, wann sie zu laichen haben? | Die Daten zeigen drei Uhren. Die Erwärmung öffnet die Saison (89 % der Riffnächte), der Mond grenzt die Nacht ein (88 % in den Tropen, 51 % ausserhalb), der Sonnenuntergang setzt die Stunde (R = 0,90). Plots 1, 2, 3. | Das sind Zusammenhänge in erfassten Ereignissen. Welches Signal eine Koralle nutzt, zeigen wir nicht. |
| Verhalten sich die Gattungen homogen oder heterogen? Gibt es Ausreisser? | Weitgehend homogen: Bei 20 Gattungen liegt die typische Nacht 3 bis 7 Tage nach Vollmond. *Pocillopora* ist der klare Ausreisser, tagsüber und im Roten Meer nahe Neumond. Plot 9. | Unterschiede zwischen Gattungen hängen stark am Standort: p = 0,25 ohne Eilat. Die Trennung nach Meer entstand erst nach Sichtung der Daten. |
| Welche Muster beeinflussen das Laichverhalten massgeblich? | In der lückenlos beobachteten Aquariumsreihe trägt die Saison fast die ganze Prognose (Fehler 17 % tiefer). Der Mond bringt dort kaum mehr. Plot 5. Darum herum verändert sich die Hitze: 171 von 214 Regionen im Jahr 2024. Plots 7, 8. | Ein einziges Aquarium und eine rückblickende Prüfung. Überlappung mit Hitze ist kein Nachweis gescheiterter Fortpflanzung. |

## Präsentation und Abgabe

| Vorgabe | Stand |
| --- | --- |
| Jede Person präsentiert | Mihael Atanasov: Plots 1, 3, 9. Pirasanna Siva: Plots 2, 7. |
| Folien | Fünf Visualisierungen mit je einer Folie, dazu Titel, Leitfragen und zwei Folien zu den Quellen. |
| Inhalt der Präsentation | Leitfragen, Datensätze, Antworten und Besonderheiten sind auf den Folien und in den Notizen zur Präsentation. |
| Grafiken als PNG | Zehn PNGs mit 300 dpi und 4000 × 2250 Pixeln, der Name der hauptverantwortlichen Person steht im Dateinamen. |
| R-Projekt als ZIP | Alle Skripte und Dateien. `run.R` baut alle Tabellen und Plots aus den gespeicherten Quellen neu auf. |

## Reproduzierbarkeit und Grenzen

Ein [GitHub-Actions-Lauf](../.github/workflows/reproduce.yml) erstellt das ganze Projekt auf einem sauberen Rechner neu und prüft dabei die Summen. Getrennte [Python-Prüfungen](VALIDATION.md#independent-calculations) rechnen 546 Region-Jahre, 4'028 Modelleingaben und 56 Modelle unabhängig nach.

Diese Arbeit ist explorativ. Wenn ein Befund unsere Tests nicht bestand, haben wir ihn zurückgezogen, und im [README](../README.md#what-this-work-is-and-is-not) steht offen, was wir nicht behaupten. Auch der Einsatz von KI ist dort beschrieben.

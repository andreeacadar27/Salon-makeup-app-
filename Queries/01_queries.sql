-- Baza de Date: Studio Make-Up
-- ============================================================

-- 1. SELECT simplu cu WHERE: Lista clientelor cu ten mixt
SELECT nume, prenume, telefon, email 
FROM clienti 
WHERE tip_ten_frecvent = 'Mixt';

-- 2. SELECT cu ORDER BY: Lista tipurilor de machiaj ordonate descrescător după prețul de bază
SELECT denumire, pret_baza, durata_baza_minute 
FROM tipuri_machiaj 
ORDER BY pret_baza DESC;

-- 3. JOIN pe 2 tabele: Programările împreună cu numele și telefonul clienților
SELECT p.id_programare, c.nume, c.prenume, c.telefon, p.data_ora_start, p.status
FROM programari p
JOIN clienti c ON p.id_client = c.id_client;

-- 4. JOIN pe 3 tabele: Programările cu numele clientului, artistului și tipul de machiaj
SELECT p.id_programare, 
       CONCAT(c.nume, ' ', c.prenume) AS client, 
       CONCAT(a.nume, ' ', a.prenume) AS artist, 
       tm.denumire AS tip_machiaj, 
       p.data_ora_start
FROM programari p
JOIN clienti c ON p.id_client = c.id_client
JOIN makeup_artisti a ON p.id_artist = a.id_artist
JOIN tipuri_machiaj tm ON p.id_tip_machiaj = tm.id_tip_machiaj;

-- 5. JOIN pe 4 tabele (cu detalii complete): Client, Artist, Tip Machiaj și Tehnică
SELECT p.id_programare, 
       CONCAT(c.nume, ' ', c.prenume) AS client, 
       CONCAT(a.nume, ' ', a.prenume) AS artist, 
       tm.denumire AS machiaj, 
       tech.denumire_tehnica AS tehnica,
       p.status
FROM programari p
JOIN clienti c ON p.id_client = c.id_client
JOIN makeup_artisti a ON p.id_artist = a.id_artist
JOIN tipuri_machiaj tm ON p.id_tip_machiaj = tm.id_tip_machiaj
JOIN tehnici_makeup tech ON p.id_tehnica = tech.id_tehnica;

-- 6. Agregare (COUNT, AVG): Numărul total de programări și durata medie a machiajelor de bază
SELECT COUNT(*) AS total_programari, 
       ROUND(AVG(durata_baza_minute), 1) AS durata_medie_baza_min
FROM tipuri_machiaj;

-- 7. GROUP BY + COUNT: Numărul de programări realizate de fiecare Make-Up Artist
SELECT a.nume, a.prenume, COUNT(p.id_programare) AS numar_programari
FROM makeup_artisti a
LEFT JOIN programari p ON a.id_artist = p.id_artist
GROUP BY a.id_artist, a.nume, a.prenume;

-- 8. GROUP BY + SUM + HAVING: Încasările totale pe fiecare artist unde suma depășește 200 RON
SELECT a.nume, a.prenume, SUM(i.suma_totala) AS total_incasat
FROM makeup_artisti a
JOIN programari p ON a.id_artist = p.id_artist
JOIN incasari i ON p.id_programare = i.id_programare
GROUP BY a.id_artist, a.nume, a.prenume
HAVING SUM(i.suma_totala) > 200;

-- 9. Subinterogare în WHERE: Programările cu servicii al căror preț de bază este peste prețul mediu
SELECT id_programare, id_client, id_tip_machiaj, data_ora_start
FROM programari
WHERE id_tip_machiaj IN (
    SELECT id_tip_machiaj 
    FROM tipuri_machiaj 
    WHERE pret_baza > (SELECT AVG(pret_baza) FROM tipuri_machiaj)
);

-- 10. Subinterogare cu EXISTS: Clientele care au efectuat cel puțin o programare cu tehnica Airbrush
SELECT nume, prenume, telefon 
FROM clienti c
WHERE EXISTS (
    SELECT 1 FROM programari p
    JOIN tehnici_makeup t ON p.id_tehnica = t.id_tehnica
    WHERE p.id_client = c.id_client AND t.denumire_tehnica = 'Tehnica Airbrush'
);

-- 11. VIEW 1: Vedere pentru vizualizarea sintetică a programărilor detaliate
CREATE OR REPLACE VIEW v_programari_detaliate AS
SELECT p.id_programare,
       c.nume AS nume_client,
       c.prenume AS prenume_client,
       a.nume AS nume_artist,
       tm.denumire AS tip_machiaj,
       tm.pret_baza + tech.cost_extra AS pret_total_estimat,
       p.data_ora_start,
       p.status
FROM programari p
JOIN clienti c ON p.id_client = c.id_client
JOIN makeup_artisti a ON p.id_artist = a.id_artist
JOIN tipuri_machiaj tm ON p.id_tip_machiaj = tm.id_tip_machiaj
JOIN tehnici_makeup tech ON p.id_tehnica = tech.id_tehnica;

-- Interogare pe View-ul 1:
SELECT * FROM v_programari_detaliate WHERE status = 'Programata';

-- 12. VIEW 2: Vedere pentru raportul încasărilor pe metode de plată
CREATE OR REPLACE VIEW v_raport_incasari_plata AS
SELECT modalitate_plata, 
       COUNT(*) AS Numar_Tranzactii, 
       SUM(suma_totala) AS Total_Incasat
FROM incasari
GROUP BY modalitate_plata;

-- Interogare pe View-ul 2:
SELECT * FROM v_raport_incasari_plata;

-- 13. DML INSERT: Adăugarea unui client nou
INSERT INTO clienti (nume, prenume, telefon, email, tip_ten_frecvent) 
VALUES ('Muresan', 'Alina', '0777888999', 'alina.muresan@gmail.com', 'Sensibil');

-- 14. DML INSERT: Adăugarea unei programări noi
INSERT INTO programari (id_client, id_artist, id_tip_machiaj, id_tehnica, tip_gene, observatii_ten, data_ora_start, data_ora_final, status)
VALUES (6, 1, 2, 1, 'Smocuri', 'Piele uscată', '2026-11-20 14:00:00', '2026-11-20 15:00:00', 'Programata');

-- 15. DML UPDATE: Modificarea numărului de telefon al unui client
UPDATE clienti 
SET telefon = '0788999000' 
WHERE id_client = 1;

-- 16. DML UPDATE: Actualizarea statusului unei programări finalizate
UPDATE programari 
SET status = 'Finalizata' 
WHERE id_programare = 3;

-- 17. DML DELETE: Ștergerea unei programări anulate
DELETE FROM programari 
WHERE status = 'Anulata' AND data_ora_start < '2026-01-01';

-- 18. CTE (WITH): Calculul totalului încasat și al mediei per tranzacție
WITH CTE_Statistici_Incasari AS (
    SELECT modalitate_plata,
           SUM(suma_totala) AS suma_totala,
           AVG(suma_totala) AS suma_medie
    FROM incasari
    GROUP BY modalitate_plata
)
SELECT * FROM CTE_Statistici_Incasari WHERE suma_totala > 100;

-- 19. WINDOW FUNCTION (ROW_NUMBER): Ierarhizarea programărilor fiecărui client după dată
SELECT id_programare, id_client, data_ora_start, status,
       ROW_NUMBER() OVER (PARTITION BY id_client ORDER BY data_ora_start DESC) AS Numar_Vizita
FROM programari;

-- 20. Interogare cu funcții de DATĂ/TIMP: Programările din luna curentă
SELECT id_programare, id_client, id_artist, data_ora_start
FROM programari
WHERE MONTH(data_ora_start) = MONTH(CURRENT_DATE())
  AND YEAR(data_ora_start) = YEAR(CURRENT_DATE());
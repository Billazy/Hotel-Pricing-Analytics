
/*--------------------------------------------------------------------------------------------------------------------------
Présentation des étapes du projet : de l’exploration des données à l’analyse avancée
Ce projet s’articule autour d’une analyse complète des données hôtelières, depuis 
la compréhension de la structure de la base jusqu’à l’étude détaillée des prix, 
des revenus et de leur évolution dans le temps. Il suit une démarche progressive et logique, 
permettant d’obtenir une vision globale et approfondie du fonctionnement tarifaire des hôtels.
------------------------------------------------------------------------------------------------------------------------------*/


-------------------------------------------------------
------------ 1. Data Understanding  -------------------
-------------------------------------------------------

-- Analyse de la structure des données hôtelières.


--Lister les hôtels existants  
--Objectif : identifier tous les hôtels présents dans la base.
SELECT DISTINCT 
    H.idHotel,
    H.Libelle
FROM Hotels AS H;


--Lister les types de chambres  
--Objectif : compter le nombre de types de chambres différents proposés.
SELECT 
    COUNT(DISTINCT CH.TypeChambre) AS NbTypesChambres
FROM Chambres AS CH;


--Capacité par hôtel  
--Objectif : déterminer combien de chambres possède chaque hôtel.
SELECT
    Ho.Libelle,
    COUNT(*) AS NbChambres
FROM Chambres AS CH
JOIN Hotels AS Ho ON Ho.idHotel = CH.hotel
GROUP BY
    Ho.Libelle;


--Répartition des chambres par type  
--Objectif : savoir combien de chambres de chaque type possède chaque hôtel.
SELECT
Ho.Libelle,
CH.TypeChambre,
COUNT(*) AS NbChambreHotels
FROM Chambres CH 
JOIN Hotels Ho ON Ho.idHotel = CH.Hotel
GROUP BY
Ho.Libelle,
CH.TypeChambre

-------------------------------------------------------
------------ 2. Pricing Analysis  -------------------
-------------------------------------------------------

-- Analyse des prix par hôtel et par type de chambre.



-- Quel est le prix moyen des chambres par hôtel ?
-- Objectif : obtenir une vue globale du niveau tarifaire de chaque hôtel.
SELECT
    H.Libelle,
    AVG(T.Prix) AS PrixMoyenHotel
FROM Tarifs T
JOIN Hotels H ON H.idHotel = T.hotel
GROUP BY H.Libelle;


-- Quel est le prix moyen par type de chambre ?
-- Objectif : comparer les types de chambres indépendamment des hôtels.
SELECT
    tc.Description,
    AVG(t.Prix) AS PrixMoyenType
FROM Tarifs t
JOIN TypesChambre tc ON tc.idTypeChambre = t.typeChambre
GROUP BY
    tc.Description
ORDER BY 
tc.Description;

-- Quel est le type de chambre le plus premium dans chaque hôtel ?
-- Objectif : identifier le type de chambre le plus cher (en moyenne) par hôtel.
WITH Moyennes AS (
    SELECT
        t.hotel,
        t.typeChambre,
        AVG(t.Prix) AS AvgPrix
    FROM Tarifs t
    GROUP BY
        t.hotel,
        t.typeChambre
),
MaxParHotel AS (
    SELECT
        hotel,
        MAX(AvgPrix) AS MaxPrix
    FROM Moyennes
    GROUP BY hotel
)
SELECT
    h.Libelle AS Hotel,
    tc.Description AS TypeChambre,
    m.AvgPrix AS PrixMoyen
FROM Moyennes m
JOIN MaxParHotel mx
    ON mx.hotel = m.hotel
   AND mx.MaxPrix = m.AvgPrix
JOIN Hotels h
    ON h.idHotel = m.hotel
JOIN TypesChambre tc
    ON tc.idTypeChambre = m.typeChambre
ORDER BY
    h.Libelle,
    tc.Description;



-------------------------------------------------------
------------ 3. Time‑based Analysis  -------------------
-------------------------------------------------------

-- Analyse temporelle des prix et revenus.


-- Quel est le revenu potentiel par hôtel et par période de tarification ?
-- Objectif : calculer le revenu total théorique pour chaque période.
SELECT
    H.Libelle AS Hotel,
    T.DateDebut AS PerideTarification,
    SUM(T.Prix * C.NbChambres) AS RevenuPotentiel
FROM Tarifs T
JOIN (
    -- Sous‑requête : compter le nombre de chambres par type et par hôtel.
    SELECT 
        Hotel,
        TypeChambre,
        COUNT(*) AS NbChambres
    FROM Chambres
    GROUP BY Hotel, TypeChambre
) C
    ON C.Hotel = T.hotel
    AND C.TypeChambre = T.typeChambre
JOIN Hotels H
    ON H.idHotel = T.hotel
GROUP BY 
    H.Libelle,
    T.DateDebut
ORDER BY 
    RevenuPotentiel DESC;


-- Le détail par type de chambre.
-- Objectif : décomposer le revenu potentiel par type de chambre et période.
WITH PrixParType AS (
    SELECT
        t.hotel,
        t.DateDebut,
        t.typeChambre,
        AVG(t.Prix) AS PrixMoyen
    FROM Tarifs t
    GROUP BY
        t.hotel,
        t.DateDebut,
        t.typeChambre
)
SELECT
    h.Libelle AS Hotel,
    p.DateDebut,
    tc.Description AS TypeChambre,
    p.PrixMoyen,
    COUNT(*) AS NbChambres,
    (p.PrixMoyen * COUNT(*)) AS RevenuPotentiel
FROM PrixParType p
JOIN Chambres c
    ON c.Hotel = p.hotel
   AND c.TypeChambre = p.typeChambre
JOIN Hotels h
    ON h.idHotel = p.hotel
JOIN TypesChambre tc
    ON tc.idTypeChambre = p.typeChambre
GROUP BY
    h.Libelle,
    p.DateDebut,
    tc.Description,
    p.PrixMoyen
ORDER BY
    h.Libelle,
    p.DateDebut,
    tc.Description;


-- Quelle est la période la plus rentable pour chaque hôtel ?
-- Objectif : identifier la période où chaque hôtel génère le plus de revenus.
WITH RevenuParPeriode AS (
    SELECT
        H.Libelle AS Hotel,
        T.DateDebut AS PeriodeTarification,
        SUM(T.Prix * C.NbChambres) AS RevenuPotentiel
    FROM Tarifs T
    JOIN (
        -- Comptage des chambres par type et hôtel.
        SELECT 
            Hotel,
            TypeChambre,
            COUNT(*) AS NbChambres
        FROM Chambres
        GROUP BY Hotel, TypeChambre
    ) C
        ON C.Hotel = T.hotel
        AND C.TypeChambre = T.typeChambre
    JOIN Hotels H
        ON H.idHotel = T.hotel
    GROUP BY 
        H.Libelle,
        T.DateDebut
),
Classement AS (
    -- Classement des périodes par revenu décroissant.
    SELECT
        Hotel,
        PeriodeTarification,
        RevenuPotentiel,
        ROW_NUMBER() OVER (
            PARTITION BY Hotel
            ORDER BY RevenuPotentiel DESC
        ) AS rn
    FROM RevenuParPeriode
)
SELECT
    Hotel,
    PeriodeTarification,
    RevenuPotentiel
FROM Classement
WHERE rn = 1
ORDER BY Hotel;



-------------------------------------------------------
------------ 4. Revenue Analysis  -------------------
-------------------------------------------------------

-- Analyse des revenus potentiels.


-- Quel hôtel génère le revenu potentiel le plus élevé ?
-- Objectif : comparer les hôtels sur leur revenu total cumulé.
WITH RevenuParPeriode AS (
    SELECT
        H.Libelle AS Hotel,
        SUM(T.Prix * C.NbChambres) AS RevenuPotentiel
    FROM Tarifs T
    JOIN (
        -- Comptage des chambres par type et hôtel.
        SELECT 
            Hotel,
            TypeChambre,
            COUNT(*) AS NbChambres
        FROM Chambres
        GROUP BY Hotel, TypeChambre
    ) C
        ON C.Hotel = T.hotel
        AND C.TypeChambre = T.typeChambre
    JOIN Hotels H
        ON H.idHotel = T.hotel
    GROUP BY 
        H.Libelle
)
SELECT TOP 1
    Hotel,
    RevenuPotentiel
FROM RevenuParPeriode
ORDER BY RevenuPotentiel DESC;


-- Quel type de chambre génère le plus de revenus par hôtel ?
-- Objectif : identifier le type le plus rentable dans chaque hôtel.
WITH RevenuParType AS (
    SELECT
        H.Libelle AS Hotel,
        TC.Description AS TypeChambre,
        SUM(T.Prix * C.NbChambres) AS RevenuPotentiel
    FROM Tarifs T
    JOIN (
        -- Comptage des chambres par type et hôtel.
        SELECT 
            Hotel,
            TypeChambre,
            COUNT(*) AS NbChambres
        FROM Chambres
        GROUP BY Hotel, TypeChambre
    ) C
        ON C.Hotel = T.hotel
        AND C.TypeChambre = T.typeChambre
    JOIN Hotels H
        ON H.idHotel = T.hotel
    JOIN TypesChambre TC
        ON TC.idTypeChambre = T.typeChambre
    GROUP BY 
        H.Libelle,
        TC.Description
),
Classement AS (
    -- Classement des types par revenu décroissant.
    SELECT
        Hotel,
        TypeChambre,
        RevenuPotentiel,
        ROW_NUMBER() OVER (
            PARTITION BY Hotel
            ORDER BY RevenuPotentiel DESC
        ) AS rn
    FROM RevenuParType
)
SELECT
    Hotel,
    TypeChambre,
    RevenuPotentiel
FROM Classement
WHERE rn = 1
ORDER BY Hotel;


-- Type de chambre le moins rentable dans chaque hôtel.
-- Objectif : identifier les types générant le moins de revenus.
WITH RevenuParType AS (
    SELECT
        H.Libelle AS Hotel,
        TC.Description AS TypeChambre,
        SUM(T.Prix * C.NbChambres) AS RevenuPotentiel
    FROM Tarifs T
    JOIN (
        -- Comptage des chambres par type et hôtel.
        SELECT 
            Hotel,
            TypeChambre,
            COUNT(*) AS NbChambres
        FROM Chambres
        GROUP BY Hotel, TypeChambre
    ) C
        ON C.Hotel = T.hotel
        AND C.TypeChambre = T.typeChambre
    JOIN Hotels H
        ON H.idHotel = T.hotel
    JOIN TypesChambre TC
        ON TC.idTypeChambre = T.typeChambre
    GROUP BY 
        H.Libelle,
        TC.Description
),
Classement AS (
    -- Classement des types par revenu croissant (ASC).
    SELECT
        Hotel,
        TypeChambre,
        RevenuPotentiel,
        DENSE_RANK() OVER (
            PARTITION BY Hotel
            ORDER BY RevenuPotentiel ASC
        ) AS rn
    FROM RevenuParType
)
SELECT
    Hotel,
    TypeChambre,
    RevenuPotentiel
FROM Classement
WHERE rn = 1
ORDER BY Hotel;





-------------------------------------------------------
------------ 5. Price Evolution  -------------------
-------------------------------------------------------

-- Étude de l’évolution des prix.


-- Comment les prix évoluent‑ils entre les différentes périodes ?
-- Objectif : comparer chaque prix à celui de la période précédente.
WITH Prix AS (
    SELECT
        H.Libelle AS Hotel,
        TC.Description AS TypeChambre,
        T.DateDebut AS Periode,
        T.Prix,
        LAG(T.Prix) OVER (
            PARTITION BY T.hotel, T.typeChambre
            ORDER BY T.DateDebut
        ) AS PrixPrecedent
    FROM Tarifs T
    JOIN Hotels H
        ON H.idHotel = T.hotel
    JOIN TypesChambre TC
        ON TC.idTypeChambre = T.typeChambre
)
SELECT
    Hotel,
    TypeChambre,
    Periode,
    Prix,
    PrixPrecedent,
    (Prix - PrixPrecedent) AS VariationAbsolue,
    CASE 
        WHEN PrixPrecedent IS NULL THEN NULL
        ELSE ROUND(((Prix - PrixPrecedent) / PrixPrecedent) * 100, 2)
    END AS VariationPourcentage
FROM Prix
ORDER BY
    Hotel,
    TypeChambre,
    Periode;



-- Quel hôtel augmente le plus ses prix entre deux périodes ?
-- Objectif : identifier la plus forte hausse de prix par hôtel.
WITH Evolution AS (
    SELECT
        H.Libelle AS Hotel,
        T.DateDebut AS Periode,
        T.Prix,
        LAG(T.Prix) OVER (
            PARTITION BY T.hotel
            ORDER BY T.DateDebut
        ) AS PrixPrecedent
    FROM Tarifs T
    JOIN Hotels H
        ON H.idHotel = T.hotel
),
Variations AS (
    -- Calcul des variations entre périodes consécutives.
    SELECT
        Hotel,
        Periode,
        Prix,
        PrixPrecedent,
        (Prix - PrixPrecedent) AS Variation
    FROM Evolution
    WHERE PrixPrecedent IS NOT NULL
),
MaxVariationParHotel AS (
    -- Extraction de la plus forte hausse pour chaque hôtel.
    SELECT
        Hotel,
        MAX(Variation) AS MaxVariation
    FROM Variations
    GROUP BY Hotel
)
SELECT
    M.Hotel,
    M.MaxVariation AS PlusForteHausse
FROM MaxVariationParHotel M
ORDER BY
    PlusForteHausse DESC;

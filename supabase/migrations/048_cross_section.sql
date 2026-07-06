-- Migration 048: cross_section — tverrsnittform på sigaren
-- Verdier: 'Round' (standard), 'Box Pressed', 'Oval', 'Hexagonal'
-- Kilde: kjente produktsider, halfwheel.com, cigaraficionado.com

ALTER TABLE cigars
ADD COLUMN IF NOT EXISTS cross_section TEXT DEFAULT 'Round';

-- Tag kjente box pressed-serier
UPDATE cigars SET cross_section = 'Box Pressed'
WHERE
    (brand = 'Alec Bradley'    AND series = 'Prensado')
 OR (brand = 'Padron'          AND series = '1964 Anniversary Series')
 OR (brand = 'Padron'          AND series = '1926 Serie')
 OR (brand = 'Padron'          AND series = 'Family Reserve')
 OR (brand = 'My Father'       AND series = 'Le Bijou 1922')
 OR (brand = 'La Gloria Cubana' AND series IN ('Serie R', 'Serie R Estelí'))
 OR (brand = 'Oliva'           AND series IN ('Serie V Melanio', 'Serie V Melanio Maduro'))
 OR (brand = 'Camacho'         AND series = 'Ecuador BXP');

-- Tag oval tverrsnitt (AJ Fernandez San Lotano Oval — markedsføres som "oval pressed")
UPDATE cigars SET cross_section = 'Oval'
WHERE brand = 'AJ Fernandez' AND series = 'San Lotano Oval';

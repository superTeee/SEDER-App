-- Backfill flavor_notes for all cigars that are missing tasting/flavor data.
-- Scope: 77 brand/series combinations, 404 cigar rows total.
-- Notes are grouped per series since vitolas within a series share the same blend
-- and therefore a near-identical flavor profile (size mainly affects intensity, not character).

-- Ashton
update cigars set flavor_notes = array['dark chocolate','dried fruit','espresso','cedar','mild spice'] where brand = 'Ashton' and series = 'Aged Maduro';
update cigars set flavor_notes = array['cream','cedar','toasted nuts','subtle sweetness','hay'] where brand = 'Ashton' and series = 'Cabinet Selection';
update cigars set flavor_notes = array['cedar','cream','light pepper','hay','mild sweetness'] where brand = 'Ashton' and series = 'Classic';
update cigars set flavor_notes = array['cocoa','coffee','earth','cedar','black pepper'] where brand = 'Ashton' and series = 'ESG';
update cigars set flavor_notes = array['leather','dark chocolate','earth','black pepper','cedar'] where brand = 'Ashton' and series = 'Heritage Puro Sol';
update cigars set flavor_notes = array['toasted nuts','cedar','light spice','cream','hay'] where brand = 'Ashton' and series = 'Small Cigars Cameroon';
update cigars set flavor_notes = array['cream','cedar','mild sweetness','hay','light nuts'] where brand = 'Ashton' and series = 'Small Cigars Connecticut';
update cigars set flavor_notes = array['cocoa','cedar','toasted nuts','light spice','cream'] where brand = 'Ashton' and series = 'Symmetry';
update cigars set flavor_notes = array['espresso','dark cocoa','leather','earth','black pepper'] where brand = 'Ashton' and series = 'VSG';

-- Brick House
update cigars set flavor_notes = array['cocoa','cedar','earth','mild sweetness','leather'] where brand = 'Brick House' and series = 'Classic';
update cigars set flavor_notes = array['cream','sweet hay','cedar','light nuts','vanilla'] where brand = 'Brick House' and series = 'Double Connecticut';
update cigars set flavor_notes = array['dark chocolate','coffee','earth','mild sweetness','cedar'] where brand = 'Brick House' and series = 'Maduro';

-- Casa Magna
update cigars set flavor_notes = array['black pepper','cocoa','leather','earth','cedar'] where brand = 'Casa Magna' and series = 'Colorado';
update cigars set flavor_notes = array['cream','cedar','light spice','hay','mild sweetness'] where brand = 'Casa Magna' and series = 'Connecticut';
update cigars set flavor_notes = array['dark chocolate','espresso','earth','mild sweetness','leather'] where brand = 'Casa Magna' and series = 'Maduro';
update cigars set flavor_notes = array['dark chocolate','black pepper','leather','earth','espresso'] where brand = 'Casa Magna' and series = 'Oscuro';

-- Cuesta-Rey
update cigars set flavor_notes = array['cedar','cream','toasted nuts','light spice','mild sweetness'] where brand = 'Cuesta-Rey' and series = 'Centro Fino';

-- Diamond Crown
update cigars set flavor_notes = array['cocoa','cedar','light spice','cream','earth'] where brand = 'Diamond Crown' and series = 'Black Diamond';
update cigars set flavor_notes = array['cedar','toasted nuts','cream','mild sweetness','earth'] where brand = 'Diamond Crown' and series = 'Classic';

-- Don Pepin Garcia
update cigars set flavor_notes = array['black pepper','earth','leather','espresso','spice'] where brand = 'Don Pepin Garcia' and series = 'Cuban Classic';
update cigars set flavor_notes = array['black pepper','leather','earth','dark cocoa','spice'] where brand = 'Don Pepin Garcia' and series = 'E.R.H';
update cigars set flavor_notes = array['black pepper','earth','leather','spice','cedar'] where brand = 'Don Pepin Garcia' and series = 'Original / Blue Label';
update cigars set flavor_notes = array['cocoa','black pepper','cedar','earth','leather'] where brand = 'Don Pepin Garcia' and series = 'Series JJ';
update cigars set flavor_notes = array['black pepper','leather','earth','espresso','spice'] where brand = 'Don Pepin Garcia' and series = 'Vegas Cubanas';
update cigars set flavor_notes = array['spice','leather','cocoa','earth','black pepper'] where brand = 'Don Pepin Garcia' and series = 'Vintage Edition';

-- El Baton (no series subdivision)
update cigars set flavor_notes = array['black pepper','earth','leather','espresso','spice'] where brand = 'El Baton' and series is null;

-- El Centurion
update cigars set flavor_notes = array['cream','cedar','toasted nuts','light spice','mild sweetness'] where brand = 'El Centurion' and series = 'H-2K-CT';
update cigars set flavor_notes = array['black pepper','cocoa','earth','leather','cedar'] where brand = 'El Centurion' and series = 'Original';

-- Flor de las Antillas
update cigars set flavor_notes = array['dark chocolate','espresso','spice','earth','mild sweetness'] where brand = 'Flor de las Antillas' and series = 'Maduro';
update cigars set flavor_notes = array['black pepper','cocoa','leather','earth','cedar'] where brand = 'Flor de las Antillas' and series = 'Natural';

-- Fonseca by My Father
update cigars set flavor_notes = array['cedar','cocoa','toasted nuts','light spice','cream'] where brand = 'Fonseca by My Father' and series = 'Corojo / Natural';
update cigars set flavor_notes = array['earth','cocoa','spice','leather','cedar'] where brand = 'Fonseca by My Father' and series = 'Mexico Edition';

-- Foundation Cigar Co
update cigars set flavor_notes = array['cedar','cream','toasted nuts','light spice','mild sweetness'] where brand = 'Foundation Cigar Co' and series = 'Charter Oak';
update cigars set flavor_notes = array['earth','cocoa','leather','black pepper','cedar'] where brand = 'Foundation Cigar Co' and series = 'El Güegüense';
update cigars set flavor_notes = array['cedar','cocoa','cream','light spice','earth'] where brand = 'Foundation Cigar Co' and series = 'Highclere Castle Edwardian';
update cigars set flavor_notes = array['spice','cocoa','earth','leather','cedar'] where brand = 'Foundation Cigar Co' and series = 'Highclere Castle Senetjer';
update cigars set flavor_notes = array['cream','cedar','mild sweetness','toasted nuts','hay'] where brand = 'Foundation Cigar Co' and series = 'Highclere Castle Victorian';
update cigars set flavor_notes = array['dark chocolate','espresso','earth','mild sweetness','leather'] where brand = 'Foundation Cigar Co' and series = 'Olmec Maduro';
update cigars set flavor_notes = array['dark chocolate','espresso','earth','black pepper','leather'] where brand = 'Foundation Cigar Co' and series = 'The Tabernacle';
update cigars set flavor_notes = array['spice','cedar','cocoa','earth','leather'] where brand = 'Foundation Cigar Co' and series = 'The Wise Man Corojo';
update cigars set flavor_notes = array['dark chocolate','coffee','earth','mild sweetness','leather'] where brand = 'Foundation Cigar Co' and series = 'The Wise Man Maduro';

-- Jaime Garcia
update cigars set flavor_notes = array['earth','cocoa','spice','cedar','leather'] where brand = 'Jaime Garcia' and series = 'Reserva Especial';
update cigars set flavor_notes = array['cream','cedar','toasted nuts','light spice','mild sweetness'] where brand = 'Jaime Garcia' and series = 'Reserva Especial Connecticut';

-- La Antiguedad
update cigars set flavor_notes = array['black pepper','earth','leather','espresso','spice'] where brand = 'La Antiguedad' and series = 'La Antiguedad';

-- La Duena
update cigars set flavor_notes = array['cocoa','cedar','light spice','cream','mild sweetness'] where brand = 'La Duena' and series = 'La Duena';

-- La Flor Dominicana
update cigars set flavor_notes = array['black pepper','earth','leather','spice','cedar'] where brand = 'La Flor Dominicana' and series = '1994';
update cigars set flavor_notes = array['black pepper','earth','espresso','leather','spice'] where brand = 'La Flor Dominicana' and series = 'Air Bender';
update cigars set flavor_notes = array['spice','earth','cocoa','leather','black pepper'] where brand = 'La Flor Dominicana' and series = 'Andalusian Bull';
update cigars set flavor_notes = array['toasted nuts','spice','cedar','earth','light pepper'] where brand = 'La Flor Dominicana' and series = 'Cameroon Cabinet';
update cigars set flavor_notes = array['black pepper','earth','leather','espresso','spice'] where brand = 'La Flor Dominicana' and series = 'Carajos';
update cigars set flavor_notes = array['dark chocolate','earth','leather','mild sweetness','black pepper'] where brand = 'La Flor Dominicana' and series = 'Colorado Oscuro';
update cigars set flavor_notes = array['black pepper','earth','spice','leather','espresso'] where brand = 'La Flor Dominicana' and series = 'Double Ligero';
update cigars set flavor_notes = array['spice','earth','dark cocoa','leather','black pepper'] where brand = 'La Flor Dominicana' and series = 'La Nox';
update cigars set flavor_notes = array['black pepper','earth','leather','cedar','spice'] where brand = 'La Flor Dominicana' and series = 'Mambises';

-- My Father
update cigars set flavor_notes = array['cocoa','cedar','light spice','cream','mild sweetness'] where brand = 'My Father' and series = 'Blue';
update cigars set flavor_notes = array['cream','cedar','cocoa','light spice','hay'] where brand = 'My Father' and series = 'Connecticut';
update cigars set flavor_notes = array['earth','cocoa','spice','leather','cedar'] where brand = 'My Father' and series = 'La Gran Oferta';
update cigars set flavor_notes = array['cocoa','earth','spice','cedar','leather'] where brand = 'My Father' and series = 'La Lealtad';
update cigars set flavor_notes = array['cocoa','espresso','earth','spice','leather'] where brand = 'My Father' and series = 'La Opulencia';
update cigars set flavor_notes = array['earth','cocoa','cedar','light pepper','leather'] where brand = 'My Father' and series = 'La Promesa';
update cigars set flavor_notes = array['black pepper','espresso','earth','leather','spice'] where brand = 'My Father' and series = 'Le Bijou 1922';
update cigars set flavor_notes = array['black pepper','earth','cocoa','leather','espresso'] where brand = 'My Father' and series = 'Original Core Line';
update cigars set flavor_notes = array['black pepper','earth','espresso','leather','spice'] where brand = 'My Father' and series = 'The Judge';

-- Padron
update cigars set flavor_notes = array['cocoa','espresso','earth','leather','black pepper'] where brand = 'Padron' and series = '1926 Serie';
update cigars set flavor_notes = array['cocoa','coffee','cedar','earth','spice'] where brand = 'Padron' and series = '1964 Anniversary Series';
update cigars set flavor_notes = array['cream','cocoa','cedar','light spice','mild sweetness'] where brand = 'Padron' and series = 'Damaso Series';
update cigars set flavor_notes = array['dark chocolate','espresso','leather','earth','dried fruit'] where brand = 'Padron' and series = 'Family Reserve';
update cigars set flavor_notes = array['cocoa','cedar','earth','light pepper','leather'] where brand = 'Padron' and series = 'Padron Series';

-- Perla del Mar
update cigars set flavor_notes = array['spice','cedar','cocoa','earth','light pepper'] where brand = 'Perla del Mar' and series = 'Corojo';
update cigars set flavor_notes = array['chocolate','coffee','earth','mild sweetness','cedar'] where brand = 'Perla del Mar' and series = 'Maduro';
update cigars set flavor_notes = array['cream','cedar','mild sweetness','hay','light nuts'] where brand = 'Perla del Mar' and series = 'Shade';

-- Quesada
update cigars set flavor_notes = array['cedar','cocoa','toasted nuts','light spice','cream'] where brand = 'Quesada' and series = '1974';
update cigars set flavor_notes = array['spice','earth','cocoa','leather','black pepper'] where brand = 'Quesada' and series = 'Oktoberfest';
update cigars set flavor_notes = array['cocoa','cedar','spice','earth','leather'] where brand = 'Quesada' and series = 'Tributo';

-- Tabacos Baez
update cigars set flavor_notes = array['earth','cocoa','spice','cedar','leather'] where brand = 'Tabacos Baez Serie SF' and series = 'Tabacos Baez Serie SF';

-- The American (no series subdivision)
update cigars set flavor_notes = array['earth','mild sweetness','cedar','toasted nuts','cream'] where brand = 'The American' and series is null;

-- Yagua (no series subdivision)
update cigars set flavor_notes = array['earth','cedar','light spice','hay','light pepper'] where brand = 'Yagua' and series is null;

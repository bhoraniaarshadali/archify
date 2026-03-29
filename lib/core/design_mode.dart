/// Design mode configurations for the AI Design App
library;

/// Main design modes available in the app
enum DesignMode {
  interior('Interior Design', 'Redesign room interiors'),
  exterior('Exterior Design', 'Transform building facades'),
  garden('Garden Design', 'Landscape outdoor spaces'),
  styleTransfer('Style Transfer', 'Copy style from reference');

  final String displayName;
  final String description;
  const DesignMode(this.displayName, this.description);
}

/// Room types for interior design
enum RoomType {
  livingRoom('Living Room', 'assets/images/rooms/living_room.jpg'),
  bedroom('Bedroom', 'assets/images/rooms/bedroom.jpg'),
  kitchen('Kitchen', 'assets/images/rooms/kitchen.jpg'),
  bathroom('Bathroom', 'assets/images/rooms/bathroom.jpg'),
  diningRoom('Dining Room', 'assets/images/rooms/dining_room.jpg'),
  office('Home Office', 'assets/images/rooms/office.jpg');

  final String displayName;
  final String imagePath;
  const RoomType(this.displayName, this.imagePath);
}

/// Interior design styles
enum InteriorStyle {
  modern(
    'Modern',
    'Clean lines, minimal clutter, neutral palette',
    'assets/images/styles/interior/modern.jpg',
  ),
  contemporary(
    'Contemporary',
    'Current trends, mixed textures',
    'assets/images/styles/interior/contemporary.jpg',
  ),
  minimalist(
    'Minimalist',
    'Simple, functional, clutter-free',
    'assets/images/styles/interior/minimalist.jpg',
  ),
  scandinavian(
    'Scandinavian',
    'Light, airy, cozy hygge vibes',
    'assets/images/styles/interior/scandinavian.jpg',
  ),
  industrial(
    'Industrial',
    'Raw materials, exposed elements',
    'assets/images/styles/interior/industrial.jpg',
  ),
  bohemian(
    'Bohemian',
    'Eclectic, colorful, artistic',
    'assets/images/styles/interior/bohemian.jpg',
  ),
  traditional(
    'Traditional',
    'Classic elegance, timeless',
    'assets/images/styles/interior/traditional.jpg',
  ),
  japandi(
    'Japandi',
    'Japanese minimalism + Scandinavian',
    'assets/images/styles/interior/japandi.jpg',
  ),
  midCentury(
    'Mid-Century',
    '1950s-60s retro modern',
    'assets/images/styles/interior/midcentury.jpg',
  ),
  coastal(
    'Coastal',
    'Beach-inspired, light and breezy',
    'assets/images/styles/interior/coastal.jpg',
  );

  final String displayName;
  final String description;
  final String imagePath;
  const InteriorStyle(this.displayName, this.description, this.imagePath);
}

/// Exterior design styles (matching existing styles)
enum ExteriorStyle {
  modern('Modern', 'Industrial contemporary with mixed materials'),
  victorian('Victorian', 'Traditional American Craftsman charm'),
  industrial('Industrial', 'Modern with wood accents'),
  minimalist('Minimalist', 'Clean tropical contemporary'),
  rustic('Rustic', 'Natural wood and stone farmhouse'),
  luxury('Luxury', 'Neoclassical mansion elegance');


  final String displayName;
  final String description;
  const ExteriorStyle(this.displayName, this.description);
}

/// Garden design styles
enum GardenStyle {
  modern(
    'Modern Minimalist',
    'Clean lines, structured plants',
    'assets/images/styles/garden/modern.jpg',
  ),
  lushNatural(
    'Lush Natural',
    'Dense greenery, organic feel',
    'assets/images/styles/garden/lush.jpg',
  ),
  zen('Zen', 'Gravel, calm, meditative', 'assets/images/styles/garden/zen.jpg'),
  diwali(
    'Diwali',
    'Festive lights, marigolds, vibrant colors',
    'assets/images/styles/garden/diwali.jpg',
  ),
  christmas(
    'Christmas',
    'Snow, pine trees, festive decorations',
    'assets/images/styles/garden/christmas.jpg',
  );

  final String displayName;
  final String description;
  final String imagePath;
  const GardenStyle(this.displayName, this.description, this.imagePath);
}

/// Color palette options
enum ColorPalette {
  surpriseMe('Surprise Me', 'AI chooses the best palette'),
  warm('Warm Tones', 'Beige, cream, soft browns'),
  cool('Cool Tones', 'Gray, white, blue-gray'),
  bold('Bold Colors', 'Deep burgundy, navy, forest green'),
  neutral('Neutral', 'Black, white, gray monochrome'),
  natural('Natural', 'Earth tones, terracotta, wood');

  final String displayName;
  final String description;
  const ColorPalette(this.displayName, this.description);
}


class EcoBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int requiredPoints;
  final int requiredDisposals;

  const EcoBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.requiredPoints = 0,
    this.requiredDisposals = 0,
  });

  bool isUnlocked({
    required int totalPoints,
    required int totalDisposals,
  }) {
    return totalPoints >= requiredPoints &&
        totalDisposals >= requiredDisposals;
  }
}

const List<EcoBadge> ecoBadges = [
  EcoBadge(
    id: 'first_steps',
    name: 'First Steps',
    description: 'Complete your first responsible disposal.',
    emoji: '🌱',
    requiredPoints: 15,
    requiredDisposals: 1,
  ),
  EcoBadge(
    id: 'recycling_rookie',
    name: 'Recycling Rookie',
    description: 'Earn 50 Eco Points.',
    emoji: '♻️',
    requiredPoints: 50,
  ),
  EcoBadge(
    id: 'green_contributor',
    name: 'Green Contributor',
    description: 'Earn 200 Eco Points.',
    emoji: '🌿',
    requiredPoints: 200,
  ),
  EcoBadge(
    id: 'eco_champion',
    name: 'Eco Champion',
    description: 'Earn 500 Eco Points.',
    emoji: '🌳',
    requiredPoints: 500,
  ),
  EcoBadge(
    id: 'planet_protector',
    name: 'Planet Protector',
    description: 'Earn 1,000 Eco Points.',
    emoji: '🏆',
    requiredPoints: 1000,
  ),
];

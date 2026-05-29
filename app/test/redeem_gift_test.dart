import 'package:flutter_test/flutter_test.dart';
import 'package:souma_parfumerie/features/clients/data/clients_repository.dart';

/// Nécessite PostgreSQL local (souma_parfumerie).
void main() {
  test('redeemGift ne remet à zéro qu’un seul client', () async {
    final repo = ClientsRepository();
    final all = await repo.list();
    if (all.length < 2) return;

    final target = all.firstWhere(
      (c) => (c['loyalty_points'] as num?)?.toInt() != 0,
      orElse: () => all.first,
    );
    final other = all.firstWhere(
      (c) => c['id'] != target['id'],
      orElse: () => all[1],
    );

    final targetId = target['id']!.toString();
    final otherPtsBefore = (other['loyalty_points'] as num).toInt();

    // Forcer 10 tampons sur la cible uniquement via SQL direct si besoin — skip si < 10
    final targetPts = (target['loyalty_points'] as num).toInt();
    if (targetPts < ClientsRepository.giftThreshold) {
      return; // pas de client éligible en base de test
    }

    final ok = await repo.redeemGift(targetId);
    expect(ok, isTrue);

    final afterTarget = await repo.getLoyaltyPoints(targetId);
    expect(afterTarget, 0);

    final afterOther = await repo.getLoyaltyPoints(other['id']!.toString());
    expect(afterOther, otherPtsBefore);
  });
}

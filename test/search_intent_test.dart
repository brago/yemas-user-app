import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/search_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Category names as they appear on the server.
  final names = [
    'Blanchisserie', 'Cérémonies', 'Climatisation', 'Couture', 'Cuisine', 'Dératisation', 'Désinfection', 'Électricité',
    'Entretien Automobile', 'Gardiennage', 'Jardinage', 'Maison Connectée', 'Menuiserie et rénovation', 'Nettoyage',
    'Peinture', 'Photographie', 'Plomberie', 'Salon de Beauté', 'Services à la personne',
  ];
  final categories = [for (var i = 0; i < names.length; i++) CategoryData(id: i + 1, name: names[i])];

  String? categoryOf(String text) => understandSearch(text, categories).category?.name;

  test('everyday sentences find the right category', () {
    expect(categoryOf("J'ai besoin d'un plombier"), 'Plomberie');
    expect(categoryOf('ma clim ne marche plus'), 'Climatisation');
    expect(categoryOf('Je cherche une femme de ménage'), 'Nettoyage');
    expect(categoryOf('il y a des cafards chez moi'), 'Dératisation');
    expect(categoryOf('une coiffeuse pour des tresses'), 'Salon de Beauté');
    expect(categoryOf('nounou pour mes enfants'), 'Services à la personne');
    expect(categoryOf('je veux déménager'), 'Services à la personne');
    expect(categoryOf('électricien urgent, plus de courant'), 'Électricité');
    expect(categoryOf('vidange de ma voiture'), 'Entretien Automobile');
    expect(categoryOf('Peinture'), 'Peinture');
  });

  test('"ménage" is not confused with "déménagement"', () {
    expect(categoryOf('ménage'), 'Nettoyage');
    expect(categoryOf('déménagement'), 'Services à la personne');
  });

  test('filler words are removed from the keywords', () {
    expect(understandSearch("Bonjour, je cherche quelqu'un pour un ourlet s'il vous plaît", categories).keywords, 'ourlet');
    expect(understandSearch('fuite', categories).keywords, 'fuite');
  });

  test('unknown words give no category but keep the keywords', () {
    final intent = understandSearch('installation piscine', categories);
    expect(intent.category, isNull);
    expect(intent.keywords, 'installation piscine');
  });

  test('works with the old "Services à Distance" name too', () {
    final old = [CategoryData(id: 27, name: 'Services à Distance')];
    expect(understandSearch('garde enfant', old).category?.id, 27);
  });
}

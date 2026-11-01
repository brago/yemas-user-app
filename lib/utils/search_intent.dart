import '../model/category_model.dart';

/// Understands what the user is looking for, from a typed or spoken sentence
/// such as "J'ai besoin d'un plombier" or "ma clim ne marche plus".
///
/// It finds the matching category from everyday words, and keeps the useful
/// words to search in service names when no category matches.
class SearchIntent {
  /// The matching category, if any.
  final CategoryData? category;

  /// The sentence without filler words ("j'ai besoin d'un", "s'il vous plaît"...).
  final String keywords;

  const SearchIntent({this.category, this.keywords = ''});

  bool get isEmpty => category == null && keywords.isEmpty;
}

/// Everyday words for each category. The key is part of the category name as it
/// appears on the server, without accents and in lower case ("a|b" accepts either).
const Map<String, List<String>> _categoryWords = {
  'plomberie': ['plombier', 'plomberie', 'fuite', 'fuit', 'robinet', 'canalisation', 'tuyau', 'wc', 'toilette', 'evier', 'lavabo', 'chauffe eau', 'douche', 'debouchage', 'deboucher', 'bouche', 'egout', 'fosse'],
  'climatisation': ['clim', 'climatiseur', 'climatisation', 'split', 'air conditionne', 'climatiseurs', 'froid'],
  'electricite': ['electricien', 'electricite', 'courant', 'prise', 'disjoncteur', 'lumiere', 'ampoule', 'cable', 'cablage', 'groupe electrogene', 'groupe', 'compteur', 'lampe'],
  'nettoyage': ['menage', 'nettoyage', 'nettoyer', 'femme de menage', 'proprete', 'tapis', 'rideau', 'rideaux', 'balayer', 'laver la maison'],
  'peinture': ['peintre', 'peinture', 'peindre', 'facade', 'repeindre'],
  'menuiserie': ['menuisier', 'menuiserie', 'bois', 'meuble', 'meubles', 'porte', 'placard', 'carrelage', 'carreleur', 'toiture', 'toit', 'charpente', 'chaise', 'table'],
  'beaute': ['coiffure', 'coiffeuse', 'coiffeur', 'tresse', 'tresses', 'natte', 'meches', 'ongles', 'ongle', 'manucure', 'pedicure', 'maquillage', 'massage', 'beaute', 'esthetique', 'visage', 'cheveux'],
  'jardinage': ['jardin', 'jardinier', 'jardinage', 'pelouse', 'gazon', 'elagage', 'arbre', 'haie', 'tondre'],
  'deratisation': ['rat', 'rats', 'souris', 'cafard', 'cafards', 'punaise', 'punaises', 'insecte', 'insectes', 'moustique', 'moustiques', 'termite', 'termites', 'deratisation', 'desinsectisation', 'nuisible', 'nuisibles'],
  'desinfection': ['desinfection', 'desinfecter', 'virus', 'microbe', 'microbes', 'assainir'],
  'gardiennage': ['gardien', 'vigile', 'securite', 'garde du corps', 'gardiennage', 'surveillance'],
  'cuisine': ['cuisinier', 'cuisiniere', 'chef', 'cuisine', 'repas', 'traiteur', 'gateau', 'patissier', 'patisserie', 'cuisiner'],
  'couture': ['couturier', 'couturiere', 'couture', 'tailleur', 'ourlet', 'retouche', 'pagne', 'habit', 'robe sur mesure'],
  'blanchisserie': ['pressing', 'linge', 'lessive', 'repassage', 'repasser', 'blanchisserie', 'laver mes vetements', 'vetements sales'],
  'automobile': ['voiture', 'auto', 'mecanicien', 'mecanique', 'garage', 'vidange', 'pneu', 'pneus', 'moteur', 'vehicule', 'lavage auto'],
  'connectee': ['camera', 'cameras', 'alarme', 'domotique', 'television', 'tele', 'home cinema', 'serrure', 'wifi'],
  'photographie': ['photo', 'photos', 'photographe', 'video', 'shooting', 'film'],
  'ceremonie': ['mariage', 'ceremonie', 'bapteme', 'fete', 'evenement'],
  'personne|distance': ['nounou', 'baby sitter', 'babysitter', 'garde d enfant', 'garde enfant', 'enfant', 'enfants', 'cours', 'repetiteur', 'professeur', 'prof', 'demenagement', 'demenager'],
};

/// Words that carry no meaning for the search ("je cherche un...").
const Set<String> _fillerWords = {
  'j', 'je', 'ai', 'besoin', 'd', 'de', 'des', 'du', 'un', 'une', 'le', 'la', 'les', 'l', 'mon', 'ma', 'mes', 'pour',
  'cherche', 'recherche', 'veux', 'voudrais', 'aimerais', 'faut', 'il', 'me', 'moi', 'svp', 'stp', 's', 'plait', 'vous',
  'est', 'ce', 'que', 'qui', 'quelqu', 'chez', 'a', 'au', 'aux', 'en', 'et', 'ou', 'sur', 'dans',
  'trouver', 'faire', 'venir', 'urgent', 'urgence', 'vite', 'rapidement', 'bonjour', 'merci', 'ne', 'pas', 'plus',
  'marche', 'fonctionne', 'probleme', 'panne', 'bon', 'bien', 'tres', 'peux', 'pouvez', 'avoir', 'aider', 'aide',
};

/// Lower case, no accents, no punctuation.
String normalizeSearchText(String text) {
  const accents = {'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae'};
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r"[^a-z0-9]+"), ' ').trim().replaceAll(RegExp(r' +'), ' ');
}

/// Finds the category and the useful words in [text], among [categories].
SearchIntent understandSearch(String text, List<CategoryData> categories) {
  final normalized = normalizeSearchText(text);
  if (normalized.isEmpty) return const SearchIntent();

  final padded = ' $normalized ';
  CategoryData? found;
  int bestLength = 0;

  // 1. A word linked to a category: the longest match wins ("garde du corps" before "garde").
  _categoryWords.forEach((categoryKey, words) {
    for (final word in words) {
      if (word.length > bestLength && padded.contains(' $word ')) {
        final category = _findCategory(categoryKey, categories);
        if (category != null) {
          found = category;
          bestLength = word.length;
        }
      }
    }
  });

  // 2. Otherwise, the name of a category typed directly ("Climatisation").
  if (found == null) {
    for (final category in categories) {
      final name = normalizeSearchText(category.name ?? '');
      if (name.isNotEmpty && (padded.contains(' $name ') || name.split(' ').any((w) => w.length > 4 && padded.contains(' $w ')))) {
        found = category;
        break;
      }
    }
  }

  final keywords = normalized.split(' ').where((w) => w.length > 1 && !_fillerWords.contains(w)).join(' ');
  return SearchIntent(category: found, keywords: keywords);
}

CategoryData? _findCategory(String key, List<CategoryData> categories) {
  for (final part in key.split('|')) {
    for (final category in categories) {
      if (normalizeSearchText(category.name ?? '').contains(part)) return category;
    }
  }
  return null;
}

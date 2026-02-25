import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/models/item.dart';

/// Linha de texto com coordenadas espaciais (do bounding box do ML Kit)
class _PositionedLine {
  final String text;
  final double top;
  final double bottom;
  final double left;
  final double right;

  _PositionedLine({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Candidato a item (nome do produto encontrado no lado esquerdo)
class _ItemCandidate {
  final String name;
  final double centerY;
  final double inlinePrice;

  _ItemCandidate({
    required this.name,
    required this.centerY,
    this.inlinePrice = 0,
  });
}

/// Candidato a preço (valor encontrado no lado direito)
class _PriceCandidate {
  final double price;
  final double centerY;
  bool used = false;

  _PriceCandidate({
    required this.price,
    required this.centerY,
  });
}

/// Candidato de quantidade (ex: "1 X 1,79")
class _QtyCandidate {
  final int quantity;
  final double unitPrice;
  final double centerY;

  _QtyCandidate({
    required this.quantity,
    required this.unitPrice,
    required this.centerY,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Retorna o texto puro do OCR (para compatibilidade)
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Faz scan com dados espaciais (bounding boxes) para emparelhar
  /// nomes de itens (esquerda) com preços (direita) pela posição Y.
  Future<List<Item>> scanReceipt(String imagePath, String vendor) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    if (vendor.toLowerCase() == 'continente') {
      return _parseContinenteStructured(recognizedText);
    }
    // Fallback para texto puro
    return processInvoiceText(recognizedText.text, vendor);
  }

  void dispose() {
    _textRecognizer.close();
  }

  /// Fallback: parse de texto puro (para vendors sem spatial matching)
  List<Item> processInvoiceText(String rawText, String vendor) {
    if (vendor.toLowerCase() == 'continente') {
      return _parseContinenteText(rawText);
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // SPATIAL MATCHING (usando bounding boxes do ML Kit)
  // ---------------------------------------------------------------------------

  List<Item> _parseContinenteStructured(RecognizedText recognizedText) {
    // 1) Recolher todas as linhas com posição
    final List<_PositionedLine> allLines = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allLines.add(_PositionedLine(
          text: line.text.trim(),
          top: line.boundingBox.top,
          bottom: line.boundingBox.bottom,
          left: line.boundingBox.left,
          right: line.boundingBox.right,
        ));
      }
    }

    if (allLines.isEmpty) return [];

    // 2) Ordenar por posição vertical
    allLines.sort((a, b) => a.top.compareTo(b.top));

    // 3) Calcular tolerância Y baseada na altura média das linhas
    double totalHeight = 0;
    for (final line in allLines) {
      totalHeight += line.height;
    }
    double avgLineHeight = totalHeight / allLines.length;
    // Tolerância: linhas na mesma faixa vertical (1.5x a altura de linha)
    double yTolerance = avgLineHeight * 1.5;

    // 4) Determinar geometria da página
    double maxRight = 0;
    for (final line in allLines) {
      if (line.right > maxRight) maxRight = line.right;
    }
    // Preços ficam no lado direito — threshold ~55% da largura
    double rightThreshold = maxRight * 0.50;

    // 5) Regexes
    final itemStartRegex =
        RegExp(r'^[\(\[\{]?\s*[A-Ca-c]\s*[\)\]\}]\s+(.+)');
    final standalonePrice = RegExp(r'^(\d+[.,]\d{2})$');
    final trailingPriceRegex = RegExp(r'\s{2,}(\d+[.,]\d{2})\s*$');
    final qtyPriceRegex = RegExp(r'(\d+)\s*[xX*]\s*(\d+[.,]\d{2})');

    // 6) Classificar cada linha
    final List<_ItemCandidate> itemCandidates = [];
    final List<_PriceCandidate> priceCandidates = [];
    final List<_QtyCandidate> qtyCandidates = [];
    bool reachedEnd = false;

    for (final line in allLines) {
      final text = line.text;
      final centerY = line.centerY;

      // Condição de paragem
      final upper = text.toUpperCase();
      if (upper.contains('SUBTOTAL') ||
          upper.contains('TOTAL A PAGAR') ||
          (upper.contains('TOTAL') && upper.contains('PAGAR'))) {
        reachedEnd = true;
      }
      if (reachedEnd) continue;

      // Ignorar linhas sem utilidade
      if (_shouldSkipLine(text)) continue;

      // --- Item (começa com (A), (C), etc.) ---
      final itemMatch = itemStartRegex.firstMatch(text);
      if (itemMatch != null) {
        String name = itemMatch.group(1)!.trim();
        double inlinePrice = 0;

        // Preço embutido na mesma linha (com >=2 espaços antes)
        final tp = trailingPriceRegex.firstMatch(name);
        if (tp != null) {
          inlinePrice =
              double.tryParse(tp.group(1)!.replaceAll(',', '.')) ?? 0;
          name = name.substring(0, name.length - tp.group(0)!.length).trim();
        }

        name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
        name = name.replaceAll(RegExp(r'[.\s]+$'), '').trim();

        if (name.isNotEmpty) {
          itemCandidates.add(_ItemCandidate(
            name: name,
            centerY: centerY,
            inlinePrice: inlinePrice,
          ));
        }
        continue;
      }

      // --- Preço isolado no lado direito ---
      final pm = standalonePrice.firstMatch(text.trim());
      if (pm != null && line.left >= rightThreshold) {
        double price =
            double.tryParse(pm.group(1)!.replaceAll(',', '.')) ?? 0;
        priceCandidates.add(_PriceCandidate(price: price, centerY: centerY));
        continue;
      }

      // --- Quantidade x preço (ex: "1 X 1,79") ---
      final qm = qtyPriceRegex.firstMatch(text);
      if (qm != null) {
        int qty = int.tryParse(qm.group(1)!) ?? 1;
        double unitPrice =
            double.tryParse(qm.group(2)!.replaceAll(',', '.')) ?? 0;
        qtyCandidates.add(_QtyCandidate(
          quantity: qty,
          unitPrice: unitPrice,
          centerY: centerY,
        ));
        continue;
      }

      // --- Preço solto sem ser item (pode estar no meio/direita) ---
      // Ex: preço lido num bloco separado mas não no extremo direito
      final loosePm = standalonePrice.firstMatch(text.trim());
      if (loosePm != null) {
        double price =
            double.tryParse(loosePm.group(1)!.replaceAll(',', '.')) ?? 0;
        priceCandidates.add(_PriceCandidate(price: price, centerY: centerY));
        continue;
      }
    }

    // 7) Emparelhar itens com preços pela coordenada Y
    final List<Item> items = [];

    for (final item in itemCandidates) {
      double price = item.inlinePrice;
      int quantity = 1;

      // Procurar linha de quantidade logo abaixo do item
      _QtyCandidate? matchedQty;
      double bestQtyDist = double.infinity;
      for (final qty in qtyCandidates) {
        double dist = qty.centerY - item.centerY;
        // Qty fica logo abaixo, dentro de ~2.5 alturas de linha
        if (dist > 0 && dist < yTolerance * 2.5 && dist < bestQtyDist) {
          bestQtyDist = dist;
          matchedQty = qty;
        }
      }

      if (matchedQty != null) {
        quantity = matchedQty.quantity;
        if (price == 0) {
          price = matchedQty.unitPrice;
        }
      }

      // Procurar preço correspondente no lado direito (mesmo Y)
      if (price == 0) {
        _PriceCandidate? bestMatch;
        double bestDist = double.infinity;

        // Tentar na mesma Y do item
        for (final p in priceCandidates) {
          if (p.used) continue;
          double dist = (p.centerY - item.centerY).abs();
          if (dist < yTolerance && dist < bestDist) {
            bestDist = dist;
            bestMatch = p;
          }
        }

        // Se nada encontrado e tem qty line, tentar na Y do qty
        if (bestMatch == null && matchedQty != null) {
          for (final p in priceCandidates) {
            if (p.used) continue;
            double dist = (p.centerY - matchedQty.centerY).abs();
            if (dist < yTolerance && dist < bestDist) {
              bestDist = dist;
              bestMatch = p;
            }
          }
        }

        if (bestMatch != null) {
          if (quantity > 1 && matchedQty != null) {
            // O preço à direita é o total → usar o unitário da qty line
            price = matchedQty.unitPrice;
          } else {
            price = bestMatch.price;
          }
          bestMatch.used = true;
        }
      }

      items.add(Item(
        name: item.name,
        price: price,
        quantity: quantity,
      ));
    }

    return items;
  }

  /// Linhas a ignorar (não são itens nem preços de produtos)
  bool _shouldSkipLine(String text) {
    final upper = text.toUpperCase();
    return upper.contains('DESCONTO') ||
        (upper.contains('IVA') && text.contains('%')) ||
        upper.contains('NIF') ||
        upper.contains('FATURA') ||
        upper.contains('NRO:') ||
        upper.contains('CARTAO') ||
        upper.contains('ATKM') ||
        upper.contains('ATCUD') ||
        upper.contains('CONTRIBUINTE') ||
        upper.contains('OPERADOR') ||
        upper.contains('CAIXA') ||
        text.contains('---') ||
        RegExp(r'^[A-Za-zÀ-ÿ&/\s]+:\s*$').hasMatch(text);
  }

  // ---------------------------------------------------------------------------
  // FALLBACK: Parse baseado em texto puro (sem dados espaciais)
  // ---------------------------------------------------------------------------

  List<Item> _parseContinenteText(String text) {
    final List<Item> items = [];
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final itemStartRegex =
        RegExp(r'^[\(\[\{]?\s*[A-Ca-c]\s*[\)\]\}]\s+(.+)');
    final priceRegex = RegExp(r'(\d+[.,]\d{2})\s*$');
    final categoryRegex = RegExp(r'^[A-Za-zÀ-ÿ&/\s]+:\s*$');
    final onlyPriceRegex = RegExp(r'^\s*(\d+[.,]\d{2})\s*$');
    final qtyPriceRegex = RegExp(r'(\d+)\s*[xX*]\s*(\d+[.,]\d{2})');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.toUpperCase().contains('SUBTOTAL') ||
          line.toUpperCase().contains('TOTAL A PAGAR') ||
          line.toUpperCase().contains('TOTAL') &&
              line.toUpperCase().contains('PAGAR')) {
        break;
      }

      if (categoryRegex.hasMatch(line)) continue;
      if (_shouldSkipLine(line)) continue;

      final matchStart = itemStartRegex.firstMatch(line);
      if (matchStart != null) {
        String namePart = matchStart.group(1) ?? '';
        double price = 0.0;
        int quantity = 1;

        final matchPrice = priceRegex.firstMatch(namePart);
        if (matchPrice != null) {
          price = double.tryParse(
                  matchPrice.group(1)!.replaceAll(',', '.')) ??
              0.0;
          namePart = namePart
              .substring(0, namePart.length - matchPrice.group(0)!.length)
              .trim();
        }

        if (price == 0.0 && i + 1 < lines.length) {
          String nextLine = lines[i + 1];
          final matchQty = qtyPriceRegex.firstMatch(nextLine);
          if (matchQty != null) {
            quantity = int.tryParse(matchQty.group(1)!) ?? 1;
            final endPriceMatch = priceRegex.firstMatch(nextLine);
            if (endPriceMatch != null) {
              double totalPrice = double.tryParse(
                      endPriceMatch.group(1)!.replaceAll(',', '.')) ??
                  0.0;
              price = double.tryParse(
                      matchQty.group(2)!.replaceAll(',', '.')) ??
                  0.0;
              if (quantity > 0 &&
                  totalPrice > 0 &&
                  (totalPrice - price * quantity).abs() > 0.02) {
                price = totalPrice / quantity;
              }
            } else {
              price = double.tryParse(
                      matchQty.group(2)!.replaceAll(',', '.')) ??
                  0.0;
            }
            i++;
          } else {
            final matchNextPrice = onlyPriceRegex.firstMatch(nextLine);
            if (matchNextPrice != null) {
              price = double.tryParse(
                      matchNextPrice.group(1)!.replaceAll(',', '.')) ??
                  0.0;
              i++;
            }
          }
        }

        namePart = namePart.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
        namePart = namePart.replaceAll(RegExp(r'[.\s]+$'), '').trim();

        if (namePart.isNotEmpty) {
          items.add(Item(
            name: namePart,
            price: price,
            quantity: quantity,
          ));
        }
      }
    }

    return items;
  }
}

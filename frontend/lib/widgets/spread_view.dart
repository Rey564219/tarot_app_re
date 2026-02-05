import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpreadView extends StatelessWidget {
  const SpreadView({
    super.key,
    required this.resultJson,
    this.showCardName = true,
    this.showPosition = true,
  });

  final dynamic resultJson;
  final bool showCardName;
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    final cards = _collectCards(resultJson);
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutForType(resultJson);
        if (layout == _SpreadLayout.hexagram) {
          return _hexagramLayout(context, cards, constraints.maxWidth);
        }
        if (layout == _SpreadLayout.celticCross) {
          return _celticCrossLayout(context, cards, constraints.maxWidth);
        }
        if (layout == _SpreadLayout.triangle) {
          return _triangleLayout(context, cards, constraints.maxWidth);
        }
        if (layout == _SpreadLayout.flower) {
          return _flowerLayout(context, cards, constraints.maxWidth);
        }
        if (layout == _SpreadLayout.todayDeep) {
          return _todayDeepLayout(context, cards, constraints.maxWidth);
        }
        return _simpleGrid(context, cards, constraints.maxWidth);
      },
    );
  }

  List<Map<String, dynamic>> _collectCards(dynamic resultJson) {
    if (resultJson is! Map) return [];
    final cards = <Map<String, dynamic>>[];

    final baseCard = resultJson['base_card'];
    if (baseCard is Map) {
      cards.add({
        ...baseCard,
        'position': 'base',
      });
    }

    final slots = resultJson['slots'] as List<dynamic>? ?? [];
    for (final slot in slots) {
      if (slot is Map) {
        final card = slot['card'];
        if (card is Map) {
          cards.add({
            ...card,
            'position': slot['position'],
          });
        }
      }
    }
    if (cards.isEmpty) {
      final rawCards = resultJson['cards'] as List<dynamic>? ?? [];
      for (final card in rawCards) {
        if (card is Map) {
          cards.add({
            ...card,
            'position': '',
          });
        }
      }
    }
    return cards;
  }

  _SpreadLayout _layoutForType(dynamic resultJson) {
    if (resultJson is! Map) return _SpreadLayout.grid;
    final type = resultJson['type']?.toString() ?? '';
    if (type == 'hexagram') return _SpreadLayout.hexagram;
    if (type == 'celtic_cross') return _SpreadLayout.celticCross;
    if (type == 'triangle_warning') return _SpreadLayout.triangle;
    if (type == 'flower_timing') return _SpreadLayout.flower;
    if (type == 'today_deep') return _SpreadLayout.todayDeep;
    return _SpreadLayout.grid;
  }

  Widget _cardTile(BuildContext context, Map<String, dynamic> card, double width) {
    final name = card['name']?.toString() ?? '';
    final position = card['position']?.toString() ?? '';
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _cardAssetPath(card),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEEE5DA),
                  child: Center(
                    child: Text(
                      name.isEmpty ? 'Card' : name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (showCardName && name.isNotEmpty)
            Text(name, style: Theme.of(context).textTheme.bodySmall),
          if (showPosition && position.isNotEmpty)
            Text(position, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _simpleGrid(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final cardWidth = (maxWidth - 24) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) => _cardTile(context, card, cardWidth)).toList(),
    );
  }

  Widget _hexagramLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth.clamp(260, 520).toDouble();
    final cardW = size / 4.4;
    final cardH = cardW / 0.6;
    final center = size / 2;
    final radius = size / 2.5;
    final angleStep = 60 * (3.1415926535 / 180);
    final positions = List.generate(6, (i) {
      final angle = -90 * (3.1415926535 / 180) + (angleStep * i);
      return Offset(center + radius * math.cos(angle), center + radius * math.sin(angle));
    });
    final last = cards.length > 6 ? cards[6] : null;
    return SizedBox(
      width: size,
      height: size + cardH * 0.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < positions.length && i < cards.length; i++)
            Positioned(
              left: positions[i].dx - cardW / 2,
              top: positions[i].dy - cardH / 2,
              width: cardW,
              child: _cardTile(context, cards[i], cardW),
            ),
          if (last != null)
            Positioned(
              left: center - cardW / 2,
              top: center - cardH / 2,
              width: cardW,
              child: _cardTile(context, last, cardW),
            ),
        ],
      ),
    );
  }

  Widget _celticCrossLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth.clamp(280, 560).toDouble();
    final cardW = size / 4.3;
    final cardH = cardW / 0.6;
    final centerX = size * 0.38;
    final centerY = size * 0.42;
    final gap = cardW * 0.25;

    final center = Offset(centerX - cardW / 2, centerY - cardH / 2);
    final above = Offset(centerX - cardW / 2, centerY - cardH - gap);
    final below = Offset(centerX - cardW / 2, centerY + gap);
    final left = Offset(centerX - cardW - gap, centerY - cardH / 2);
    final right = Offset(centerX + cardW + gap, centerY - cardH / 2);
    final columnX = size * 0.72;
    final colTop = size * 0.1;
    final colGap = cardH * 0.18;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (cards.isNotEmpty)
            Positioned(left: center.dx, top: center.dy, width: cardW, child: _cardTile(context, cards[0], cardW)),
          if (cards.length > 1)
            Positioned(
              left: center.dx,
              top: center.dy,
              width: cardW,
              child: Transform.rotate(
                angle: math.pi / 2,
                child: _cardTile(context, cards[1], cardW),
              ),
            ),
          if (cards.length > 2)
            Positioned(left: above.dx, top: above.dy, width: cardW, child: _cardTile(context, cards[2], cardW)),
          if (cards.length > 3)
            Positioned(left: below.dx, top: below.dy, width: cardW, child: _cardTile(context, cards[3], cardW)),
          if (cards.length > 4)
            Positioned(left: left.dx, top: left.dy, width: cardW, child: _cardTile(context, cards[4], cardW)),
          if (cards.length > 5)
            Positioned(left: right.dx, top: right.dy, width: cardW, child: _cardTile(context, cards[5], cardW)),
          if (cards.length > 6)
            Positioned(left: columnX, top: colTop, width: cardW, child: _cardTile(context, cards[6], cardW)),
          if (cards.length > 7)
            Positioned(
              left: columnX,
              top: colTop + cardH + colGap,
              width: cardW,
              child: _cardTile(context, cards[7], cardW),
            ),
          if (cards.length > 8)
            Positioned(
              left: columnX,
              top: colTop + (cardH + colGap) * 2,
              width: cardW,
              child: _cardTile(context, cards[8], cardW),
            ),
          if (cards.length > 9)
            Positioned(
              left: columnX,
              top: colTop + (cardH + colGap) * 3,
              width: cardW,
              child: _cardTile(context, cards[9], cardW),
            ),
        ],
      ),
    );
  }

  Widget _triangleLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth.clamp(260, 520).toDouble();
    final cardW = size / 3.4;
    final cardH = cardW / 0.6;
    final top = Offset(size / 2 - cardW / 2, 0);
    final left = Offset(0, cardH + 20);
    final right = Offset(size - cardW, cardH + 20);
    final positions = [top, left, right];
    return SizedBox(
      width: size,
      height: cardH * 2.2,
      child: Stack(
        children: [
          for (var i = 0; i < cards.length && i < positions.length; i++)
            Positioned(
              left: positions[i].dx,
              top: positions[i].dy,
              width: cardW,
              child: _cardTile(context, cards[i], cardW),
            ),
        ],
      ),
    );
  }

  Widget _flowerLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth.clamp(300, 600).toDouble();
    final cardW = size / 5.5;
    final cardH = cardW / 0.6;
    final center = size / 2;
    final radius = size / 2.6;
    final angleStep = 30 * (3.1415926535 / 180);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < cards.length && i < 12; i++)
            Positioned(
              left: center + radius * math.cos(-90 * (3.1415926535 / 180) + angleStep * i) - cardW / 2,
              top: center + radius * math.sin(-90 * (3.1415926535 / 180) + angleStep * i) - cardH / 2,
              width: cardW,
              child: _cardTile(context, cards[i], cardW),
            ),
        ],
      ),
    );
  }

  Widget _todayDeepLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth.clamp(260, 520).toDouble();
    final cardW = size / 3.8;
    final cardH = cardW / 0.6;
    final center = Offset(size / 2 - cardW / 2, cardH * 0.6);
    final positions = [
      center,
      Offset(0, cardH * 1.6),
      Offset(size - cardW, cardH * 1.6),
      Offset(size * 0.2, cardH * 3.0),
      Offset(size * 0.6, cardH * 3.0),
    ];
    return SizedBox(
      width: size,
      height: cardH * 4.2,
      child: Stack(
        children: [
          for (var i = 0; i < cards.length && i < positions.length; i++)
            Positioned(
              left: positions[i].dx,
              top: positions[i].dy,
              width: cardW,
              child: _cardTile(context, cards[i], cardW),
            ),
        ],
      ),
    );
  }

  String _cardAssetPath(Map<String, dynamic> card) {
    final name = card['name']?.toString() ?? 'card';
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'assets/cards/$normalized.png';
  }
}

enum _SpreadLayout {
  grid,
  hexagram,
  celticCross,
  triangle,
  flower,
  todayDeep,
}

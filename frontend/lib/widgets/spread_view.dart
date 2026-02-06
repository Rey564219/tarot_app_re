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
    if (layout == _SpreadLayout.compatibility) {
      return _compatibilityLayout(context, cards, constraints.maxWidth);
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
    final type = resultJson['type']?.toString() ?? '';
    final cards = <Map<String, dynamic>>[];

    final baseCard = resultJson['base_card'];
    if (baseCard is Map) {
      cards.add({
        ...baseCard,
        'position': type == 'today_deep' ? '総合' : 'base',
      });
    }

    final slots = resultJson['slots'] as List<dynamic>? ?? [];
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot is Map) {
        final card = slot['card'];
        if (card is Map) {
          cards.add({
            ...card,
            'position': _mapPositionLabel(type, i, slot['position']?.toString() ?? ''),
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

  String _mapPositionLabel(String type, int index, String fallback) {
    if (type == 'hexagram') {
      const labels = ['過去', '立場', '現在', '未来', 'アドバイス', '周囲', '結果'];
      if (index >= 0 && index < labels.length) return labels[index];
    }
    if (type == 'celtic_cross') {
      const labels = ['現状', 'キー', '表層', '過去', '未来', '深層', '総合', '希望と恐れ', '周囲', '立場'];
      if (index >= 0 && index < labels.length) return labels[index];
    }
    if (type == 'triangle_warning') {
      const labels = ['動機', '機会', '自己正当化'];
      if (index >= 0 && index < labels.length) return labels[index];
    }
    if (type == 'compatibility') {
      const labels = ['相手', '相性', '自分'];
      if (index >= 0 && index < labels.length) return labels[index];
    }
    return fallback;
  }

  _SpreadLayout _layoutForType(dynamic resultJson) {
    if (resultJson is! Map) return _SpreadLayout.grid;
    final type = resultJson['type']?.toString() ?? '';
    if (type == 'hexagram') return _SpreadLayout.hexagram;
    if (type == 'celtic_cross') return _SpreadLayout.celticCross;
    if (type == 'triangle_warning') return _SpreadLayout.triangle;
    if (type == 'flower_timing') return _SpreadLayout.flower;
    if (type == 'compatibility') return _SpreadLayout.compatibility;
    if (type == 'today_deep') return _SpreadLayout.grid;
    return _SpreadLayout.grid;
  }

  Widget _cardTile(BuildContext context, Map<String, dynamic> card, double width) {
    final name = card['name']?.toString() ?? '';
    final position = card['position']?.toString() ?? '';
    final upright = card['upright'];
    final showOrientation = _layoutForType(resultJson) != _SpreadLayout.flower;
    final orientationText = upright == null
        ? null
        : (upright == true ? '正位置' : '逆位置');
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
          if (showOrientation && orientationText != null)
            Text(orientationText, style: Theme.of(context).textTheme.bodySmall),
          if (showPosition && position.isNotEmpty)
            Text(position, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _simpleGrid(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final cardWidth = maxWidth * 0.10;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards.map((card) => _cardTile(context, card, cardWidth)).toList(),
    );
  }

  Widget _hexagramLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth;
    final cardW = maxWidth * 0.10;
    final cardH = cardW / 0.6;
    final center = Offset(size * 0.5, size * 0.42);
    final top = Offset(size * 0.5, size * 0.16);
    final bottom = Offset(size * 0.5, size * 0.72);
    final left = Offset(size * 0.18, size * 0.42);
    final right = Offset(size * 0.82, size * 0.42);
    final bottomLeft = Offset(size * 0.18, size * 0.70);
    final bottomRight = Offset(size * 0.82, size * 0.70);
    final positions = <Offset>[
      top, // 過去
      right, // 立場
      bottomRight, // 現在
      bottomLeft, // 未来
      bottom, // アドバイス
      left, // 周囲
      center, // 結果
    ];
    return SizedBox(
      width: size,
      height: size * 0.9,
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
        ],
      ),
    );
  }

  Widget _celticCrossLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth;
    final cardW = maxWidth * 0.10;
    final cardH = cardW / 0.6;
    final centerX = size * 0.34;
    final centerY = size * 0.42;
    final gap = cardW * 0.30;

    final center = Offset(centerX - cardW / 2, centerY - cardH / 2);
    final above = Offset(centerX - cardW / 2, centerY - cardH - gap);
    final below = Offset(centerX - cardW / 2, centerY + gap);
    final left = Offset(centerX - cardW - gap, centerY - cardH / 2);
    final right = Offset(centerX + cardW + gap, centerY - cardH / 2);
    final columnX = size * 0.72;
    final colTop = size * 0.08;
    final colGap = cardH * 0.12;

    return SizedBox(
      width: size,
      height: size * 0.9,
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
    final size = maxWidth;
    final cardW = maxWidth * 0.10;
    final cardH = cardW / 0.6;
    final top = Offset(size / 2 - cardW / 2, 0);
    final left = Offset(size * 0.2 - cardW / 2, cardH * 1.2);
    final right = Offset(size * 0.8 - cardW / 2, cardH * 1.2);
    final positions = [top, left, right];
    return SizedBox(
      width: size,
      height: cardH * 2.4,
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
    final size = maxWidth;
    final cardW = maxWidth * 0.10;
    final cardH = cardW / 0.6;
    final center = size / 2;
    final radius = size * 0.36;
    final angleStep = 30 * (3.1415926535 / 180);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final card in _flowerOrdered(cards))
            Positioned(
              left: center +
                  radius *
                      math.cos(
                        -90 * (3.1415926535 / 180) + angleStep * ((card['pos_index'] as int) % 12),
                      ) -
                  cardW / 2,
              top: center +
                  radius *
                      math.sin(
                        -90 * (3.1415926535 / 180) + angleStep * ((card['pos_index'] as int) % 12),
                      ) -
                  cardH / 2,
              width: cardW,
              child: _cardTile(context, card['card'] as Map<String, dynamic>, cardW),
            ),
        ],
      ),
    );
  }

  Widget _todayDeepLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final size = maxWidth;
    final cardW = maxWidth * 0.10;
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
      height: cardH * 3.6,
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

  Widget _compatibilityLayout(BuildContext context, List<Map<String, dynamic>> cards, double maxWidth) {
    final cardW = maxWidth * 0.10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < cards.length && i < 3; i++)
          _cardTile(context, cards[i], cardW),
      ],
    );
  }

  List<Map<String, dynamic>> _flowerOrdered(List<Map<String, dynamic>> cards) {
    final ordered = <Map<String, dynamic>>[];
    for (final card in cards) {
      final pos = card['position']?.toString() ?? '';
      final idx = int.tryParse(pos);
      if (idx == null) continue;
      final posIndex = idx % 12; // 12 -> 0 (top)
      ordered.add({'pos_index': posIndex, 'card': card});
    }
    ordered.sort((a, b) => (a['pos_index'] as int).compareTo(b['pos_index'] as int));
    return ordered;
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
  compatibility,
  todayDeep,
}

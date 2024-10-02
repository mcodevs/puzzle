import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PolygonArea extends StatefulWidget {
  const PolygonArea({super.key});

  @override
  State<PolygonArea> createState() => _PolygonAreaState();
}

class _PolygonAreaState extends State<PolygonArea> {
  static const double containerSize = 300; // Size of the snapping container
  static const double gridSize =
      5; // Grid size for snapping inside the container
  static Size layout = Size.zero;
  static const double blockOffsetY = 600;

  // Initial positions for blocks (outside the container)
  List<Block> blocks = getBlocks();

  Offset containerPosition =
      Offset.zero; // Will store the position of the container on the screen

  void _updatePosition(int index, DragUpdateDetails details) {
    final delta = details.delta;
    setState(() {
      Offset newPosition = blocks[index].offset + delta;

      for (var block in blocks) {
        if (block == blocks[index]) continue;
        if (_checkOverlap(
          newPosition & blocks[index].size,
          block.rect,
        )) {
          Rect currentRect = blocks[index].rect;
          Rect otherRect = block.rect;
          if (currentRect.right <= otherRect.left ||
              otherRect.right <= currentRect.left) {
            newPosition = newPosition.translate(-delta.dx, 0);
          } else {
            newPosition = newPosition.translate(0, -delta.dy);
          }
        }
      }

      if (blocks[index].inside) {
        // If the block is inside the container, restrict it within the container
        newPosition = _adjustPositionToBounds(newPosition, blocks[index].size);
      }

      blocks[index] = blocks[index].copyWith(offset: newPosition);
    });
  }

  bool _checkOverlap(Rect current, Rect other) {
    return current.overlaps(other);
  }

  bool _isInsideContainer(Offset pos, Size size) {
    // Check if the block is inside the 300x300 container
    return pos.dx >= containerPosition.dx &&
        pos.dy >= containerPosition.dy &&
        pos.dx + size.width <= containerPosition.dx + containerSize + 10 &&
        pos.dy + size.height <= containerPosition.dy + containerSize + 10;
  }

  void _onDragEnd(int index) {
    setState(() {
      // If the block enters the container, snap to grid and lock it inside
      if (_isInsideContainer(blocks[index].offset, blocks[index].size)) {
        final isInside = blocks[index].inside;
        blocks[index] = blocks[index].copyWith(
          offset: _adjustPositionToBounds(
            _snapToGrid(blocks[index].offset),
            blocks[index].size,
          ),
          inside: true,
        );
        if (!isInside) {
          blocks.add(blocks[index].copyWith(
            inside: false,
            offset: blocks[index].initialOffset,
          ));
        }
      } else {
        // If the block is not inside the container, just update the position
        blocks[index] = blocks[index].copyWith(
          offset: blocks[index].initialOffset,
        );
      }
    });
  }

  Offset _snapToGrid(Offset position) {
    // Snap the position to the nearest grid point inside the 300x300 container
    double x =
        ((position.dx - containerPosition.dx) / gridSize).round() * gridSize +
            containerPosition.dx;
    double y =
        ((position.dy - containerPosition.dy) / gridSize).round() * gridSize +
            containerPosition.dy;

    // Ensure snapping remains inside the container
    x = x.clamp(
        containerPosition.dx, containerPosition.dx + containerSize - gridSize);
    y = y.clamp(
        containerPosition.dy, containerPosition.dy + containerSize - gridSize);

    return Offset(x, y);
  }

  Offset _adjustPositionToBounds(Offset pos, Size size) {
    double newX = pos.dx;
    double newY = pos.dy;

    // Restrict within the polygon boundaries (300x300 container)
    if (newX < containerPosition.dx) newX = containerPosition.dx;
    if (newX + size.width > containerPosition.dx + containerSize) {
      newX = containerPosition.dx + containerSize - size.width;
    }
    if (newY < containerPosition.dy) newY = containerPosition.dy;
    if (newY + size.height > containerPosition.dy + containerSize) {
      newY = containerPosition.dy + containerSize - size.height;
    }

    return Offset(newX, newY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Containers in Polygon'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                blocks = getBlocks();
              });
            },
            icon: const Icon(
              Icons.refresh,
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          layout = constraints.biggest;

          // Calculate the position of the container in the center of the screen
          containerPosition = Offset(
            (layout.width - containerSize) / 2,
            (layout.height - containerSize) / 2,
          );

          return Stack(
            children: [
              // The 300x300 container where snapping should occur
              Positioned(
                left: containerPosition.dx,
                top: containerPosition.dy,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              // The draggable blocks
              ...List.generate(
                blocks.length,
                (index) {
                  return Positioned(
                    left: blocks[index].offset.dx,
                    top: blocks[index].offset.dy,
                    child: GestureDetector(
                      onLongPress: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Yo'q"),
                            ),
                            title:
                                const Text("Ushbu blokni o'chirmoqchimisiz?"),
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() {
                                    blocks[index] = blocks[index].copyWith(
                                      inside: false,
                                      offset: blocks[index].initialOffset,
                                    );
                                  });
                                  Navigator.pop(context);
                                },
                                isDestructiveAction: true,
                                child: const Text("Ha"),
                              )
                            ],
                          ),
                        );
                      },
                      onPanUpdate: (details) => _updatePosition(index, details),
                      onPanEnd: (_) => _onDragEnd(index),
                      child: Container(
                        width: blocks[index].size.width,
                        height: blocks[index].size.height,
                        color: blocks[index].color,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static List<Block> getBlocks() {
    return [
      Block(
        size: const Size(200, 100),
        offset: const Offset(
          50,
          blockOffsetY,
        ),
      ),
      Block(
        size: const Size(100, 150),
        offset: const Offset(
          200,
          blockOffsetY,
        ),
      ),
    ];
  }
}

class Block {
  static final _rand = Random();

  final Size size;
  final Color color;
  final bool inside; // Tracks whether the block is inside the container
  Offset offset;
  final Offset initialOffset;

  Block({
    required this.size,
    this.inside = false,
    Offset? offset,
    Offset? initialOffset,
    Color? color,
  })  : offset = offset ?? Offset.zero,
        initialOffset = initialOffset ?? offset ?? Offset.zero,
        color = color ??
            Color.fromARGB(
              255,
              _rand.nextInt(256),
              _rand.nextInt(256),
              _rand.nextInt(256),
            );

  Rect get rect => offset & size;

  Block copyWith({
    Offset? offset,
    bool? inside,
  }) {
    return Block(
      size: size,
      color: color,
      initialOffset: initialOffset,
      inside: inside ?? this.inside,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Block &&
        other.size == size &&
        other.color == color &&
        other.inside == inside &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return size.hashCode ^ color.hashCode ^ inside.hashCode ^ offset.hashCode;
  }
}

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widgets/custom_app_bar.dart';

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

  // Initial positions for blocks (outside the container)
  List<Block> blocks = [];

  Offset containerPosition =
      Offset.zero; // Will store the position of the container on the screen

  void _updatePosition(int index, DragUpdateDetails details) {
    final delta = details.delta;
    setState(() {
      Offset newPosition = blocks[index].offset + delta;

      for (var block in blocks) {
        if (block == blocks[index]) continue;
        if (_checkOverlap(newPosition & blocks[index].size, block.rect)) {
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

  bool _checkSpaceAvailable(Block newBlock) {
    for (double x = containerPosition.dx;
        x <= containerPosition.dx + containerSize - newBlock.size.width;
        x += gridSize) {
      for (double y = containerPosition.dy;
          y <= containerPosition.dy + containerSize - newBlock.size.height;
          y += gridSize) {
        Rect newRect =
            Rect.fromLTWH(x, y, newBlock.size.width, newBlock.size.height);
        bool overlap = false;

        for (var block in blocks) {
          if (block.inside && _checkOverlap(newRect, block.rect)) {
            overlap = true;
            break;
          }
        }

        if (!overlap) {
          return true; // Found a space where the block can fit
        }
      }
    }
    return false; // No space found
  }

  void _addBlockToContainer(Block block) {
    print("isAvailable: ${_checkSpaceAvailable(block)}");
    if (_checkSpaceAvailable(block)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Space Available"),
            content: const Text(
                "There is space available in the polygon. Do you want to place the block?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Place"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _placeBlock(block);
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("No Space Available"),
            content: const Text(
                "There is no space available in the polygon for this block."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _placeBlock(Block block) {
    setState(() {
      Offset? availablePosition;
      for (double x = containerPosition.dx;
          x <= containerPosition.dx + containerSize - block.size.width;
          x += gridSize) {
        for (double y = containerPosition.dy;
            y <= containerPosition.dy + containerSize - block.size.height;
            y += gridSize) {
          Rect newRect =
              Rect.fromLTWH(x, y, block.size.width, block.size.height);
          bool overlap = false;

          for (var existingBlock in blocks) {
            if (existingBlock.inside &&
                _checkOverlap(newRect, existingBlock.rect)) {
              overlap = true;
              break;
            }
          }

          if (!overlap) {
            availablePosition = Offset(x, y);
            break;
          }
        }
        if (availablePosition != null) break;
      }

      if (availablePosition != null) {
        blocks.add(block.copyWith(
          offset: availablePosition,
          inside: true,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CustomAppBar(
          onPressed: () => setState(() => blocks.clear()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            enableDrag: true,
            showDragHandle: true,
            useSafeArea: true,
            builder: (context) => DraggableScrollableSheet(
              expand: false,
              minChildSize: 0.4,
              initialChildSize: 0.4,
              builder: (context, scrollController) {
                return GridView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CustomBlock(
                          checkSpaceAvailable: _checkSpaceAvailable,
                          onBlockSelected: (block) {
                            Navigator.pop(context);
                            _addBlockToContainer(block);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          child: const Icon(Icons.menu),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            layout = constraints.biggest;
            containerPosition = Offset(
              (layout.width - containerSize) / 2,
              (layout.height - containerSize) / 2,
            );

            return Stack(
              children: [
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
                ...List.generate(
                  blocks.length,
                  (index) {
                    return Positioned(
                      left: blocks[index].offset.dx,
                      top: blocks[index].offset.dy,
                      child: GestureDetector(
                        onLongPress: () {
                          if (!blocks[index].inside) return;
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
                                    setState(() => blocks.removeAt(index));
                                    Navigator.pop(context);
                                  },
                                  isDestructiveAction: true,
                                  child: const Text("Ha"),
                                )
                              ],
                            ),
                          );
                        },
                        onPanUpdate: (details) =>
                            _updatePosition(index, details),
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

  factory Block.random() {
    return Block(
      size: Size(
        (_rand.nextInt(30) + 1) * 10,
        (_rand.nextInt(30) + 1) * 10,
      ),
    );
  }

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

class CustomBlock extends StatefulWidget {
  const CustomBlock({
    super.key,
    required this.onBlockSelected,
    required this.checkSpaceAvailable,
  });
  final void Function(Block block) onBlockSelected;
  final bool Function(Block block) checkSpaceAvailable;

  @override
  State<CustomBlock> createState() => _CustomBlockState();
}

class _CustomBlockState extends State<CustomBlock> {
  late final Block block;
  @override
  void initState() {
    block = Block.random();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final isAvailable = widget.checkSpaceAvailable(block);
        if (!isAvailable) return;
        widget.onBlockSelected(block);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: block.size.width,
                height: block.size.height,
                decoration: BoxDecoration(
                  color: block.color,
                ),
              ),
              if (!widget.checkSpaceAvailable(block)) const Icon(Icons.clear)
            ],
          ),
          Text(block.size.toString()),
        ],
      ),
    );
  }
}

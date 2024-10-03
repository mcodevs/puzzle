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

  List<Block> blocks = [];

  Offset containerPosition =
      Offset.zero; // Position of the container on the screen

  void _updatePosition(int index, DragUpdateDetails details) {
    setState(() {
      final delta = details.delta;
      Offset newPosition = blocks[index].offset + delta;

      // Check for overlap with other blocks
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
        // Restrict movement within the container
        newPosition = _adjustPositionToBounds(newPosition, blocks[index].size);
      }

      blocks[index] = blocks[index].copyWith(offset: newPosition);
    });
  }

  // Improved overlap logic
  bool _checkOverlap(Rect rect1, Rect rect2) {
    // Ensure no overlap by checking the boundaries
    return !(rect1.right <= rect2.left ||
        rect1.left >= rect2.right ||
        rect1.bottom <= rect2.top ||
        rect1.top >= rect2.bottom);
  }

  bool _isInsideContainer(Offset pos, Size size) {
    // Check if the block is inside the container
    return pos.dx >= containerPosition.dx &&
        pos.dy >= containerPosition.dy &&
        pos.dx + size.width <= containerPosition.dx + containerSize &&
        pos.dy + size.height <= containerPosition.dy + containerSize;
  }

  void _onDragEnd(int index) {
    setState(() {
      if (_isInsideContainer(blocks[index].offset, blocks[index].size)) {
        // Snap to grid and lock inside the container
        blocks[index] = blocks[index].copyWith(
          offset: _adjustPositionToBounds(
            _snapToGrid(blocks[index].offset),
            blocks[index].size,
          ),
          inside: true,
        );
      } else {
        // Return to initial position if not inside the container
        blocks[index] =
            blocks[index].copyWith(offset: blocks[index].initialOffset);
      }
    });
  }

  Offset _snapToGrid(Offset position) {
    double x =
        ((position.dx - containerPosition.dx) / gridSize).round() * gridSize +
            containerPosition.dx;
    double y =
        ((position.dy - containerPosition.dy) / gridSize).round() * gridSize +
            containerPosition.dy;

    return Offset(
      x.clamp(containerPosition.dx,
          containerPosition.dx + containerSize - gridSize),
      y.clamp(containerPosition.dy,
          containerPosition.dy + containerSize - gridSize),
    );
  }

  Offset _adjustPositionToBounds(Offset pos, Size size) {
    double x = pos.dx.clamp(containerPosition.dx,
        containerPosition.dx + containerSize - size.width);
    double y = pos.dy.clamp(containerPosition.dy,
        containerPosition.dy + containerSize - size.height);
    return Offset(x, y);
  }

  bool _checkSpaceAvailable(Block newBlock) {
    // Iterate over rows (y) first, then columns (x)
    for (double y = containerPosition.dy;
        y <= containerPosition.dy + containerSize - newBlock.size.height;
        y += gridSize) {
      for (double x = containerPosition.dx;
          x <= containerPosition.dx + containerSize - newBlock.size.width;
          x += gridSize) {
        Rect newRect =
            Rect.fromLTWH(x, y, newBlock.size.width, newBlock.size.height);
        bool overlap = blocks
            .any((block) => block.inside && _checkOverlap(newRect, block.rect));

        if (!overlap) {
          return true; // Found space
        }
      }
    }
    return false; // No space found
  }

  void _placeBlock(Block block) {
    setState(() {
      Offset? availablePosition;

      // Iterate over rows (y) first, then columns (x)
      for (double y = containerPosition.dy;
          y <= containerPosition.dy + containerSize - block.size.height;
          y += gridSize) {
        for (double x = containerPosition.dx;
            x <= containerPosition.dx + containerSize - block.size.width;
            x += gridSize) {
          Rect newRect =
              Rect.fromLTWH(x, y, block.size.width, block.size.height);
          bool overlap = blocks.any((existingBlock) =>
              existingBlock.inside &&
              _checkOverlap(newRect, existingBlock.rect));

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
      } else {
        _showNoSpaceDialog();
      }
    });
  }

  void _showNoSpaceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No Space Available"),
        content: const Text("There's no space in the polygon for this block."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Polygon Area"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => blocks.clear()),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showBlockPicker,
          child: const Icon(Icons.add),
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
                    color: Colors.grey.shade300,
                  ),
                ),
                ...blocks.map((block) {
                  int index = blocks.indexOf(block);
                  return Positioned(
                    left: block.offset.dx,
                    top: block.offset.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) => _updatePosition(index, details),
                      onPanEnd: (_) => _onDragEnd(index),
                      onLongPress: () {
                        if (block.inside) {
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
                        }
                      },
                      child: Container(
                        width: block.size.width,
                        height: block.size.height,
                        color: block.color,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );

  void _showBlockPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
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
                crossAxisCount: 2),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomBlock(
                    checkSpaceAvailable: _checkSpaceAvailable,
                    onBlockSelected: (block) {
                      Navigator.pop(context);
                      _placeBlock(block);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Block {
  static final _rand = Random();
  final Size size;
  final Color color;
  final bool inside;
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
        color =
            color ?? Colors.primaries[_rand.nextInt(Colors.primaries.length)];

  factory Block.random() {
    return Block(
      size: Size(
        (_rand.nextInt(20) + 1) * 10,
        (_rand.nextInt(20) + 1) * 10,
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
    super.initState();
    block = Block.random();
  }

  @override
  Widget build(BuildContext context) {
    bool isAvailable = widget.checkSpaceAvailable(block);

    return GestureDetector(
      onTap: isAvailable ? () => widget.onBlockSelected(block) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: block.size.width,
                height: block.size.height,
                color: block.color,
              ),
              if (!isAvailable)
                const Icon(
                  Icons.clear,
                  color: Colors.white,
                  size: 50,
                ),
            ],
          ),
          Text(block.size.toString()),
        ],
      ),
    );
  }
}

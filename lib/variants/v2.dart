// import 'dart:math';
// import 'package:flutter/material.dart';

// class PolygonArea extends StatefulWidget {
//   const PolygonArea({super.key});

//   @override
//   State<PolygonArea> createState() => _PolygonAreaState();
// }

// class _PolygonAreaState extends State<PolygonArea> {
//   static const double containerSize = 300; // Size of the snapping container
//   static const double gridSize = 20; // Grid size for snapping inside the container
//   static Size layout = Size.zero;

//   // Initial positions for blocks (outside the container)
//   List<Block> blocks = [
//     Block(size: const Size(100, 100), offset: const Offset(50, 500), inside: false),
//     Block(size: const Size(100, 100), offset: const Offset(200, 500), inside: false),
//   ];

//   Offset containerPosition = Offset.zero; // Will store the position of the container on the screen

//   // Keep original _updatePosition method logic as requested
//   void _updatePosition(int index, DragUpdateDetails details) {
//     final delta = details.delta;
//     setState(() {
//       // Move the container by delta
//       Offset newPosition = blocks[index].offset + delta;

//       // Keep the original logic of updating position intact
//       blocks[index] = blocks[index].copyWith(offset: newPosition);
//     });
//   }

//   bool _isInsideContainer(Offset pos, Size size) {
//     // Check if the block is inside the 300x300 container
//     return pos.dx >= containerPosition.dx &&
//         pos.dy >= containerPosition.dy &&
//         pos.dx + size.width <= containerPosition.dx + containerSize &&
//         pos.dy + size.height <= containerPosition.dy + containerSize;
//   }

//   void _onDragEnd(int index) {
//     setState(() {
//       // If the block enters the container, snap to grid and lock it inside
//       if (_isInsideContainer(blocks[index].offset, blocks[index].size)) {
//         blocks[index] = blocks[index].copyWith(inside: true);
//         blocks[index] = blocks[index].copyWith(
//           offset: _adjustPositionToBounds(
//             _snapToGrid(blocks[index].offset),
//             blocks[index].size,
//           ),
//         );
//       }
//     });
//   }

//   Offset _snapToGrid(Offset position) {
//     // Snap the position to the nearest grid point inside the 300x300 container
//     double x = ((position.dx - containerPosition.dx) / gridSize).round() * gridSize + containerPosition.dx;
//     double y = ((position.dy - containerPosition.dy) / gridSize).round() * gridSize + containerPosition.dy;

//     // Ensure snapping remains inside the container
//     x = x.clamp(containerPosition.dx, containerPosition.dx + containerSize - gridSize);
//     y = y.clamp(containerPosition.dy, containerPosition.dy + containerSize - gridSize);

//     return Offset(x, y);
//   }

//   Offset _adjustPositionToBounds(Offset pos, Size size) {
//     double newX = pos.dx;
//     double newY = pos.dy;

//     // Restrict within the polygon boundaries (300x300 container)
//     if (newX < containerPosition.dx) newX = containerPosition.dx;
//     if (newX + size.width > containerPosition.dx + containerSize) newX = containerPosition.dx + containerSize - size.width;
//     if (newY < containerPosition.dy) newY = containerPosition.dy;
//     if (newY + size.height > containerPosition.dy + containerSize) newY = containerPosition.dy + containerSize - size.height;

//     return Offset(newX, newY);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(builder: (context, constraints) {
//       layout = constraints.biggest;

//       // Calculate the position of the container in the center of the screen
//       containerPosition = Offset(
//         (layout.width - containerSize) / 2,
//         (layout.height - containerSize) / 2,
//       );

//       return Stack(
//         children: [
//           // The 300x300 container where snapping should occur
//           Positioned(
//             left: containerPosition.dx,
//             top: containerPosition.dy,
//             child: Container(
//               width: containerSize,
//               height: containerSize,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.black, width: 2),
//                 color: Colors.grey.shade300,
//               ),
//             ),
//           ),
//           // The draggable blocks
//           ...List.generate(
//             blocks.length,
//             (index) {
//               return Positioned(
//                 left: blocks[index].offset.dx,
//                 top: blocks[index].offset.dy,
//                 child: GestureDetector(
//                   onPanUpdate: (details) => _updatePosition(index, details),
//                   onPanEnd: (_) => _onDragEnd(index),
//                   child: Container(
//                     width: blocks[index].size.width,
//                     height: blocks[index].size.height,
//                     color: blocks[index].color,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       );
//     });
//   }
// }

// class Block {
//   static final _rand = Random();

//   final Size size;
//   final Color color;
//   final bool inside; // Tracks whether the block is inside the container
//   Offset offset;

//   Block({
//     required this.size,
//     required this.inside,
//     Offset? offset,
//     Color? color,
//   })  : offset = offset ?? Offset.zero,
//         color = color ??
//             Color.fromARGB(255, _rand.nextInt(256), _rand.nextInt(256),
//                 _rand.nextInt(256));

//   Block copyWith({
//     Offset? offset,
//     bool? inside,
//   }) {
//     return Block(
//       size: size,
//       color: color,
//       inside: inside ?? this.inside,
//       offset: offset ?? this.offset,
//     );
//   }
// }

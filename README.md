# Photo Sticker Board

A macOS sticker board application built with SwiftUI that allows users to create interactive photo collages.

## Features

- 📸 **Photo Import**: Add photos from your file browser with security-scoped resource handling
- 🖱️ **Drag & Drop**: Smooth, responsive dragging with boundary constraints
- 📏 **Resize**: Interactive resize handles for adjusting sticker size
- 🔄 **Rotate**: Rotation handles for precise sticker orientation
- 🎯 **Precise Positioning**: Accurate mouse tracking and positioning
- 🎨 **Visual Feedback**: Enhanced shadows and animations during interaction
- 🖼️ **Clean UI**: Modern interface with white outlines and grid background

## Requirements

- macOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone the repository
2. Open `tester.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Click the "Add Photo" button to import images
2. Drag stickers around the board to reposition them
3. Select a sticker to show resize and rotation handles
4. Use the handles to adjust size and rotation
5. Click "Delete" to remove selected stickers
6. Use "Clear All" to remove all stickers

## Technical Details

- Built with SwiftUI for modern macOS development
- Implements proper security-scoped resource handling for file access
- Uses Canvas for efficient grid rendering
- Responsive drag gesture handling with boundary constraints
- State management for sticker positioning and selection

## License

This project is open source and available under the [MIT License](LICENSE).

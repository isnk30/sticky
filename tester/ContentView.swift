//
//  ContentView.swift
//  tester
//
//  Created by Israel Kamuanga  on 7/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct PhotoSticker: Identifiable {
    let id = UUID()
    var imageData: Data
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    
    init(imageData: Data, position: CGPoint = CGPoint(x: 100, y: 100), size: CGSize = CGSize(width: 150, height: 150), rotation: Double = 0) {
        self.imageData = imageData
        self.position = position
        self.size = size
        self.rotation = rotation
    }
}

struct ContentView: View {
    @State private var stickers: [PhotoSticker] = []
    @State private var isImporting = false
    @State private var selectedSticker: PhotoSticker?
    @State private var dragStartPositions: [UUID: CGPoint] = [:]
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Text("Photo Sticker Board")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    isImporting = true
                }) {
                    Label("Add Photo", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    if let selected = selectedSticker {
                        stickers.removeAll { $0.id == selected.id }
                        selectedSticker = nil
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedSticker == nil)
                
                Button(action: {
                    stickers.removeAll()
                    selectedSticker = nil
                }) {
                    Label("Clear All", systemImage: "trash.fill")
                }
                .buttonStyle(.bordered)
                .disabled(stickers.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .border(Color.gray.opacity(0.2), width: 0.5)
            
            // Sticker board canvas
            GeometryReader { geometry in
                let _ = DispatchQueue.main.async {
                    viewSize = geometry.size
                }
                ZStack {
                    // Background
                    Color(NSColor.controlBackgroundColor)
                        .ignoresSafeArea()
                    
                    // Grid background for visual reference
                    GridBackground()
                    
                    // Photo stickers
                    ForEach(stickers) { sticker in
                    PhotoStickerView(
                        sticker: sticker,
                        isSelected: selectedSticker?.id == sticker.id,
                        onTap: { selectedSticker = sticker },
                        onDragChanged: { value in
                            if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                // Get the drag start position for this sticker
                                let startPosition = dragStartPositions[sticker.id] ?? sticker.position
                                
                                // Use the drag start position plus current translation for more predictable movement
                                let newX = startPosition.x + value.translation.width
                                let newY = startPosition.y + value.translation.height
                                
                                // Get the actual sticker dimensions
                                let stickerWidth = sticker.size.width
                                let stickerHeight = sticker.size.height
                                
                                // Apply boundary constraints using actual view dimensions
                                let minX = stickerWidth / 2
                                let maxX = geometry.size.width - stickerWidth / 2
                                let minY = stickerHeight / 2
                                let maxY = geometry.size.height - stickerHeight / 2
                                
                                let constrainedX = max(minX, min(maxX, newX))
                                let constrainedY = max(minY, min(maxY, newY))
                                
                                stickers[index].position = CGPoint(x: constrainedX, y: constrainedY)
                            }
                        },
                        onDragStart: {
                            dragStartPositions[sticker.id] = sticker.position
                        },
                        onDragEnd: {
                            dragStartPositions.removeValue(forKey: sticker.id)
                        },
                        onResize: { newSize in
                            if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                stickers[index].size = newSize
                            }
                        },
                        onRotate: { newRotation in
                            if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                stickers[index].rotation = newRotation
                            }
                        }
                    )
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                selectedSticker = nil
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                print("Selected \(urls.count) images")
                for url in urls {
                    print("Processing URL: \(url)")
                    
                    // Start accessing the security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        print("Failed to access security-scoped resource: \(url)")
                        continue
                    }
                    
                    defer {
                        // Stop accessing the security-scoped resource
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    if let imageData = try? Data(contentsOf: url) {
                        print("Successfully loaded image data: \(imageData.count) bytes")
                        let centerX = viewSize.width > 0 ? viewSize.width / 2 : 400
                        let centerY = viewSize.height > 0 ? viewSize.height / 2 : 300
                        let newSticker = PhotoSticker(
                            imageData: imageData,
                            position: CGPoint(x: centerX, y: centerY)
                        )
                        stickers.append(newSticker)
                        print("Added sticker. Total stickers: \(stickers.count)")
                    } else {
                        print("Failed to load image data from: \(url)")
                    }
                }
            case .failure(let error):
                print("Error importing images: \(error.localizedDescription)")
            }
        }
    }
}

struct GridBackground: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 20
            let rows = Int(size.height / gridSize)
            let cols = Int(size.width / gridSize)
            
            for row in 0...rows {
                let y = CGFloat(row) * gridSize
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(.gray.opacity(0.1)),
                    lineWidth: 0.5
                )
            }
            
            for col in 0...cols {
                let x = CGFloat(col) * gridSize
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(.gray.opacity(0.1)),
                    lineWidth: 0.5
                )
            }
        }
    }
}

struct PhotoStickerView: View {
    let sticker: PhotoSticker
    let isSelected: Bool
    let onTap: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onResize: (CGSize) -> Void
    let onRotate: (Double) -> Void
    
    @State private var isDragging: Bool = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Main image
            if let nsImage = NSImage(data: sticker.imageData) {
                ZStack(alignment: .trailing) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Rectangle())
                        .frame(width: sticker.size.width, height: sticker.size.height)
                        .rotationEffect(.degrees(sticker.rotation + rotationAngle))
                        .shadow(color: .black.opacity(isDragging ? 0.5 : 0.3), radius: isSelected ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
                        .scaleEffect(isDragging ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                    
                    if isSelected {
                        ResizeSideHandle(
                            onDrag: { value in
                                // Only use horizontal drag for resizing
                                let delta = value.translation.width
                                let newWidth = max(50, sticker.size.width + delta)
                                let aspectRatio = sticker.size.width / sticker.size.height
                                let newHeight = max(50, newWidth / aspectRatio)
                                onResize(CGSize(width: newWidth, height: newHeight))
                            }
                        )
                        .offset(x: 12, y: 0)
                    }
                }
            } else {
                // Fallback if image fails to load
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: sticker.size.width, height: sticker.size.height)
                    .overlay(
                        Text("Failed to load image")
                            .foregroundColor(.red)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.white, lineWidth: 4)
                    )
            }
            
            // Selection controls
            if isSelected {
                // Rotation handle
                VStack {
                    HStack {
                        Spacer()
                        RotationHandle(onChanged: { value in
                            let center = CGPoint(x: sticker.size.width / 2, y: sticker.size.height / 2)
                            let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                            onRotate(angle * 180 / Double.pi)
                        })
                    }
                }
            }
        }
        .position(sticker.position)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        onDragStart()
                    }
                    onDragChanged(value)
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnd()
                }
        )
    }
}

struct RotationHandle: View {
    var onChanged: (DragGesture.Value) -> Void
    
    var body: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "rotate.3d")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onChanged(value)
                    }
            )
    }
}

struct ResizeSideHandle: View {
    var onDrag: (DragGesture.Value) -> Void
    @State private var isHovering = false
    var body: some View {
        ZStack {
            Circle()
                .fill(isHovering ? Color.blue : Color.gray)
                .frame(width: 24, height: 24)
                .shadow(radius: isHovering ? 6 : 2)
            Image(systemName: "arrow.left.and.right")
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .bold))
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    onDrag(value)
                }
        )
    }
}

#Preview {
    ContentView()
}

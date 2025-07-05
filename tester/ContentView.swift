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
    @State private var backgroundColor: Color = Color(NSColor.controlBackgroundColor)
    @State private var showingColorPicker = false
    @State private var tempBackgroundColor: Color = Color(NSColor.controlBackgroundColor)
    @State private var showAddTooltip = false
    @State private var addButtonHoverTimer: Timer?
    @State private var showDeleteTooltip = false
    @State private var deleteButtonHoverTimer: Timer?
    @State private var showClearAllTooltip = false
    @State private var clearAllButtonHoverTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticker board canvas
            GeometryReader { geometry in
                ZStack {
                    // Background
                    backgroundColor
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
                    
                    // Floating toolbar at bottom
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                isImporting = true
                            }) {
                                Text("+")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    // Cancel any existing timer
                                    addButtonHoverTimer?.invalidate()
                                    
                                    // Start a new timer
                                    addButtonHoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                        showAddTooltip = true
                                    }
                                } else {
                                    // Cancel timer and hide tooltip
                                    addButtonHoverTimer?.invalidate()
                                    addButtonHoverTimer = nil
                                    showAddTooltip = false
                                }
                            }
                            .overlay(
                                Group {
                                    if showAddTooltip {
                                        Text("add sticker")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.8))
                                            .cornerRadius(6)
                                            .fixedSize()
                                            .offset(y: -40)
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.2), value: showAddTooltip)
                                    }
                                }
                            )
                            
                            Button(action: {
                                if let selected = selectedSticker {
                                    stickers.removeAll { $0.id == selected.id }
                                    selectedSticker = nil
                                }
                            }) {
                                Text("×")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedSticker == nil ? .gray : .black)
                                    .frame(width: 32, height: 32)
                                    .background(selectedSticker == nil ? Color.gray.opacity(0.2) : Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedSticker == nil)
                            .onHover { hovering in
                                if hovering {
                                    // Cancel any existing timer
                                    deleteButtonHoverTimer?.invalidate()
                                    
                                    // Start a new timer
                                    deleteButtonHoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                        showDeleteTooltip = true
                                    }
                                } else {
                                    // Cancel timer and hide tooltip
                                    deleteButtonHoverTimer?.invalidate()
                                    deleteButtonHoverTimer = nil
                                    showDeleteTooltip = false
                                }
                            }
                            .overlay(
                                Group {
                                    if showDeleteTooltip {
                                        Text("delete")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.8))
                                            .cornerRadius(6)
                                            .fixedSize()
                                            .offset(y: -40)
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.2), value: showDeleteTooltip)
                                    }
                                }
                            )
                            
                            Button(action: {
                                stickers.removeAll()
                                selectedSticker = nil
                            }) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(stickers.isEmpty ? .gray : .white)
                                    .frame(width: 32, height: 32)
                                    .background(stickers.isEmpty ? Color.gray.opacity(0.2) : Color.red)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(stickers.isEmpty)
                            .onHover { hovering in
                                if hovering {
                                    // Cancel any existing timer
                                    clearAllButtonHoverTimer?.invalidate()
                                    
                                    // Start a new timer
                                    clearAllButtonHoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                        showClearAllTooltip = true
                                    }
                                } else {
                                    // Cancel timer and hide tooltip
                                    clearAllButtonHoverTimer?.invalidate()
                                    clearAllButtonHoverTimer = nil
                                    showClearAllTooltip = false
                                }
                            }
                            .overlay(
                                Group {
                                    if showClearAllTooltip {
                                        Text("clear all")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.8))
                                            .cornerRadius(6)
                                            .fixedSize()
                                            .offset(y: -40)
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.2), value: showClearAllTooltip)
                                    }
                                }
                            )
                            
                            Spacer()
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    selectedSticker = nil
                }
                .onAppear {
                    viewSize = geometry.size
                }
                .contextMenu {
                    Button("Change Color") {
                        tempBackgroundColor = backgroundColor
                        showingColorPicker = true
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else {
                        continue
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    if let imageData = try? Data(contentsOf: url) {
                        let centerX = viewSize.width > 0 ? viewSize.width / 2 : 400
                        let centerY = viewSize.height > 0 ? viewSize.height / 2 : 300
                        let newSticker = PhotoSticker(
                            imageData: imageData,
                            position: CGPoint(x: centerX, y: centerY)
                        )
                        stickers.append(newSticker)
                    }
                }
            case .failure(let error):
                print("Error importing images: \(error.localizedDescription)")
            }
        }
        .overlay(
            ColorPickerModal(
                backgroundColor: $tempBackgroundColor,
                isPresented: $showingColorPicker,
                onConfirm: {
                    backgroundColor = tempBackgroundColor
                    showingColorPicker = false
                },
                onCancel: {
                    tempBackgroundColor = backgroundColor
                    showingColorPicker = false
                }
            )
        )
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
                // Rotation handle at bottom right
                RotationHandle(
                    currentRotation: sticker.rotation,
                    onRotate: onRotate
                )
                .offset(x: 0, y: 0)
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
    let currentRotation: Double
    let onRotate: (Double) -> Void
    
    @State private var isHovering = false
    @State private var startAngle: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isHovering ? Color.blue : Color.gray)
                .frame(width: 24, height: 24)
                .shadow(radius: isHovering ? 6 : 2)
            Image(systemName: "rotate.3d")
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .bold))
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let center = CGPoint(x: 12, y: 12) // Center of the 24x24 circle
                    let currentPoint = CGPoint(x: value.location.x, y: value.location.y)
                    let angle = atan2(currentPoint.y - center.y, currentPoint.x - center.x) * 180.0 / Double.pi
                    
                    if startAngle == 0 {
                        startAngle = angle - currentRotation
                    }
                    
                    let newRotation = angle - startAngle
                    onRotate(newRotation)
                }
                .onEnded { _ in
                    startAngle = 0
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

// MARK: - Color Picker Modal

struct ColorPickerModal: View {
    @Binding var backgroundColor: Color
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var backgroundOpacity: Double = 0
    @State private var modalOpacity: Double = 0
    
    private let graySwatches: [Color] = [
        Color(hex: "#1e1e1e"), // Darkest
        Color(hex: "#4a4a4a"),
        Color(hex: "#7a7a7a"),
        Color(hex: "#b8b8b8"),
        Color(hex: "#fafafa")  // Lightest
    ]
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Modal content
            VStack(spacing: 20) {
                VStack(spacing: 2) {
                    ForEach(0..<graySwatches.count, id: \.self) { index in
                        Button(action: {
                            backgroundColor = graySwatches[index]
                        }) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(graySwatches[index])
                                .frame(width: 150, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(backgroundColor == graySwatches[index] ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 40)
                
                HStack(spacing: 20) {
                    // Confirm button (checkmark)
                    Button(action: onConfirm) {
                        Text("✓")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Cancel button (X)
                    Button(action: onCancel) {
                        Text("×")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 20)
            }
            .frame(width: 280)
            .background(Color.black)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .opacity(modalOpacity)
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                // Show modal
                withAnimation(.easeInOut(duration: 0.2)) {
                    backgroundOpacity = 0.5
                    modalOpacity = 1
                }
            } else {
                // Hide modal
                withAnimation(.easeInOut(duration: 0.2)) {
                    backgroundOpacity = 0
                    modalOpacity = 0
                }
            }
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  tester
//
//  Created by Israel Kamuanga  on 7/4/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

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

struct TextSticker: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var fontSize: CGFloat
    var textColor: Color
    
    init(text: String = "Text", position: CGPoint = CGPoint(x: 100, y: 100), size: CGSize = CGSize(width: 150, height: 50), rotation: Double = 0, fontSize: CGFloat = 24, textColor: Color = .black) {
        self.text = text
        self.position = position
        self.size = size
        self.rotation = rotation
        self.fontSize = fontSize
        self.textColor = textColor
    }
}

struct ContentView: View {
    @State private var stickers: [PhotoSticker] = []
    @State private var textStickers: [TextSticker] = []
    @State private var isImporting = false
    @State private var selectedSticker: PhotoSticker?
    @State private var selectedTextSticker: TextSticker?
    @State private var dragStartPositions: [UUID: CGPoint] = [:]
    @State private var viewSize: CGSize = .zero
    @State private var backgroundColor: Color = Color(NSColor.controlBackgroundColor)
    @State private var showingColorPicker = false
    @State private var tempBackgroundColor: Color = Color(NSColor.controlBackgroundColor)
    @State private var showAddTooltip = false
    @State private var addButtonHoverTimer: Timer?
    @State private var showAddTextTooltip = false
    @State private var addTextButtonHoverTimer: Timer?
    @State private var showDeleteTooltip = false
    @State private var deleteButtonHoverTimer: Timer?
    @State private var showClearAllTooltip = false
    @State private var clearAllButtonHoverTimer: Timer?
    @State private var showStickerList = false
    
    var body: some View {
        ZStack {
            KeyEventHandlingView(
                onDelete: {
                    if let selected = selectedSticker {
                        stickers.removeAll { $0.id == selected.id }
                        selectedSticker = nil
                    } else if let selected = selectedTextSticker {
                        textStickers.removeAll { $0.id == selected.id }
                        selectedTextSticker = nil
                    }
                },
                onMove: { dx, dy in
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }) {
                        let old = stickers[idx].position
                        stickers[idx].position = CGPoint(x: old.x + dx, y: old.y + dy)
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }) {
                        let old = textStickers[idx].position
                        textStickers[idx].position = CGPoint(x: old.x + dx, y: old.y + dy)
                    }
                },
                onResetRotation: {
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }) {
                        stickers[idx].rotation = 0
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }) {
                        textStickers[idx].rotation = 0
                    }
                },
                onClearAll: {
                    stickers.removeAll()
                    textStickers.removeAll()
                    selectedSticker = nil
                    selectedTextSticker = nil
                },
                onSendBackward: {
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }), idx > 0 {
                        let sticker = stickers.remove(at: idx)
                        stickers.insert(sticker, at: idx - 1)
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }), idx > 0 {
                        let textSticker = textStickers.remove(at: idx)
                        textStickers.insert(textSticker, at: idx - 1)
                    }
                },
                onSendForward: {
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }), idx < stickers.count - 1 {
                        let sticker = stickers.remove(at: idx)
                        stickers.insert(sticker, at: idx + 1)
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }), idx < textStickers.count - 1 {
                        let textSticker = textStickers.remove(at: idx)
                        textStickers.insert(textSticker, at: idx + 1)
                    }
                },
                onSendToBack: {
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }) {
                        let sticker = stickers.remove(at: idx)
                        stickers.insert(sticker, at: 0)
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }) {
                        let textSticker = textStickers.remove(at: idx)
                        textStickers.insert(textSticker, at: 0)
                    }
                },
                onSendToFront: {
                    if let selected = selectedSticker, let idx = stickers.firstIndex(where: { $0.id == selected.id }) {
                        let sticker = stickers.remove(at: idx)
                        stickers.append(sticker)
                    } else if let selected = selectedTextSticker, let idx = textStickers.firstIndex(where: { $0.id == selected.id }) {
                        let textSticker = textStickers.remove(at: idx)
                        textStickers.append(textSticker)
                    }
                },
                onDeselect: {
                    selectedSticker = nil
                    selectedTextSticker = nil
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
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
                                withAnimation(.none) {
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
                                }
                            },
                            onDragStart: {
                                dragStartPositions[sticker.id] = sticker.position
                            },
                            onDragEnd: {
                                dragStartPositions.removeValue(forKey: sticker.id)
                            },
                            onResize: { newSize in
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                        stickers[index].size = newSize
                                    }
                                }
                            },
                            onRotate: { newRotation in
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                        stickers[index].rotation = newRotation
                                    }
                                }
                            },
                            onSendToBack: {
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                        let sticker = stickers.remove(at: index)
                                        stickers.insert(sticker, at: 0)
                                    }
                                }
                            },
                            onSendBackward: {
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }), index > 0 {
                                        let sticker = stickers.remove(at: index)
                                        stickers.insert(sticker, at: index - 1)
                                    }
                                }
                            },
                            onMoveForward: {
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }), index < stickers.count - 1 {
                                        let sticker = stickers.remove(at: index)
                                        stickers.insert(sticker, at: index + 1)
                                    }
                                }
                            },
                            onMoveToFront: {
                                withAnimation(.none) {
                                    if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                        let sticker = stickers.remove(at: index)
                                        stickers.append(sticker)
                                    }
                                }
                            }
                        )
                    }
                    
                    // Text stickers
                    ForEach(textStickers) { textSticker in
                        TextStickerView(
                            textSticker: textSticker,
                            isSelected: selectedTextSticker?.id == textSticker.id,
                            onTap: { selectedTextSticker = textSticker },
                            onDragChanged: { value in
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                        let startPosition = dragStartPositions[textSticker.id] ?? textSticker.position
                                        let newX = startPosition.x + value.translation.width
                                        let newY = startPosition.y + value.translation.height
                                        
                                        let minX = textSticker.size.width / 2
                                        let maxX = geometry.size.width - textSticker.size.width / 2
                                        let minY = textSticker.size.height / 2
                                        let maxY = geometry.size.height - textSticker.size.height / 2
                                        
                                        let constrainedX = max(minX, min(maxX, newX))
                                        let constrainedY = max(minY, min(maxY, newY))
                                        
                                        textStickers[index].position = CGPoint(x: constrainedX, y: constrainedY)
                                    }
                                }
                            },
                            onDragStart: {
                                dragStartPositions[textSticker.id] = textSticker.position
                            },
                            onDragEnd: {
                                dragStartPositions.removeValue(forKey: textSticker.id)
                            },
                            onResize: { newSize in
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                        textStickers[index].size = newSize
                                    }
                                }
                            },
                            onRotate: { newRotation in
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                        textStickers[index].rotation = newRotation
                                    }
                                }
                            },
                            onTextChange: { newText in
                                if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                    textStickers[index].text = newText
                                }
                            },
                            onFontSizeChange: { newFontSize in
                                if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                    textStickers[index].fontSize = newFontSize
                                }
                            },
                            onSendToBack: {
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                        let textSticker = textStickers.remove(at: index)
                                        textStickers.insert(textSticker, at: 0)
                                    }
                                }
                            },
                            onSendBackward: {
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }), index > 0 {
                                        let textSticker = textStickers.remove(at: index)
                                        textStickers.insert(textSticker, at: index - 1)
                                    }
                                }
                            },
                            onMoveForward: {
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }), index < textStickers.count - 1 {
                                        let textSticker = textStickers.remove(at: index)
                                        textStickers.insert(textSticker, at: index + 1)
                                    }
                                }
                            },
                            onMoveToFront: {
                                withAnimation(.none) {
                                    if let index = textStickers.firstIndex(where: { $0.id == textSticker.id }) {
                                        let textSticker = textStickers.remove(at: index)
                                        textStickers.append(textSticker)
                                    }
                                }
                            }
                        )
                    }
                    
                    // Floating toolbar at bottom
                    VStack {
                        Spacer()
                        HStack {
                            // List button on the left
                            Button(action: {
                                showStickerList.toggle()
                            }) {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(hex: "#2e2e2e"))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 20)
                            .popover(isPresented: $showStickerList, arrowEdge: .bottom) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Stickers: \(stickers.count)")
                                        .font(.headline)
                                        .padding(.top, 8)
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(stickers) { sticker in
                                                HStack(spacing: 8) {
                                                    if let nsImage = NSImage(data: sticker.imageData) {
                                                        Image(nsImage: nsImage)
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 32, height: 32)
                                                            .cornerRadius(4)
                                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                                    }
                                                    Text("Sticker")
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .frame(maxHeight: 200)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .frame(width: 200)
                            }
                            
                            Spacer()
                            
                            // Centered buttons
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
                                let centerX = viewSize.width > 0 ? viewSize.width / 2 : 400
                                let centerY = viewSize.height > 0 ? viewSize.height / 2 : 300
                                let newTextSticker = TextSticker(
                                    text: "Text",
                                    position: CGPoint(x: centerX, y: centerY)
                                )
                                textStickers.append(newTextSticker)
                                selectedTextSticker = newTextSticker
                                selectedSticker = nil
                            }) {
                                Text("T")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    // Cancel any existing timer
                                    addTextButtonHoverTimer?.invalidate()
                                    
                                    // Start a new timer
                                    addTextButtonHoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                        showAddTextTooltip = true
                                    }
                                } else {
                                    // Cancel timer and hide tooltip
                                    addTextButtonHoverTimer?.invalidate()
                                    addTextButtonHoverTimer = nil
                                    showAddTextTooltip = false
                                }
                            }
                            .overlay(
                                Group {
                                    if showAddTextTooltip {
                                        Text("add text")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.8))
                                            .cornerRadius(6)
                                            .fixedSize()
                                            .offset(y: -40)
                                            .transition(.opacity)
                                            .animation(.easeInOut(duration: 0.2), value: showAddTextTooltip)
                                    }
                                }
                            )
                            
                            Button(action: {
                                if let selected = selectedSticker {
                                    stickers.removeAll { $0.id == selected.id }
                                    selectedSticker = nil
                                } else if let selected = selectedTextSticker {
                                    textStickers.removeAll { $0.id == selected.id }
                                    selectedTextSticker = nil
                                }
                            }) {
                                Text("×")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor((selectedSticker == nil && selectedTextSticker == nil) ? .gray : .black)
                                    .frame(width: 32, height: 32)
                                    .background((selectedSticker == nil && selectedTextSticker == nil) ? Color.gray.opacity(0.2) : Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedSticker == nil && selectedTextSticker == nil)
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
                            
                            Spacer()
                            
                            // Clear all button on the right
                            Button(action: {
                                stickers.removeAll()
                                textStickers.removeAll()
                                selectedSticker = nil
                                selectedTextSticker = nil
                            }) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor((stickers.isEmpty && textStickers.isEmpty) ? .gray : .red)
                                    .frame(width: 32, height: 32)
                                    .background((stickers.isEmpty && textStickers.isEmpty) ? Color.gray.opacity(0.2) : Color(hex: "#2e2e2e"))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(stickers.isEmpty && textStickers.isEmpty)
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
                            .padding(.trailing, 20)
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    selectedSticker = nil
                    selectedTextSticker = nil
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

// MARK: - Key Event Handling

struct KeyEventHandlingView: NSViewRepresentable {
    var onDelete: () -> Void
    var onMove: (_ dx: CGFloat, _ dy: CGFloat) -> Void
    var onResetRotation: () -> Void
    var onClearAll: () -> Void
    var onSendBackward: () -> Void
    var onSendForward: () -> Void
    var onSendToBack: () -> Void
    var onSendToFront: () -> Void
    var onDeselect: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCatcherView()
        view.onDelete = onDelete
        view.onMove = onMove
        view.onResetRotation = onResetRotation
        view.onClearAll = onClearAll
        view.onSendBackward = onSendBackward
        view.onSendForward = onSendForward
        view.onSendToBack = onSendToBack
        view.onSendToFront = onSendToFront
        view.onDeselect = onDeselect
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyCatcherView: NSView {
        var onDelete: (() -> Void)?
        var onMove: ((_ dx: CGFloat, _ dy: CGFloat) -> Void)?
        var onResetRotation: (() -> Void)?
        var onClearAll: (() -> Void)?
        var onSendBackward: (() -> Void)?
        var onSendForward: (() -> Void)?
        var onSendToBack: (() -> Void)?
        var onSendToFront: (() -> Void)?
        var onDeselect: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            let shift = event.modifierFlags.contains(.shift)
            let command = event.modifierFlags.contains(.command)
            let increment: CGFloat = shift ? 40 : 10
            switch event.keyCode {
            case 51: // delete/backspace
                if command && shift {
                    onClearAll?()
                } else {
                    onDelete?()
                }
            case 123: // left arrow
                onMove?(-increment, 0)
            case 124: // right arrow
                onMove?(increment, 0)
            case 125: // down arrow
                onMove?(0, increment)
            case 126: // up arrow
                onMove?(0, -increment)
            case 15: // R key
                if command && !shift {
                    onResetRotation?()
                } else {
                    super.keyDown(with: event)
                }
            case 33: // [ key
                if shift {
                    onSendToBack?()
                } else {
                    onSendBackward?()
                }
            case 30: // ] key
                if shift {
                    onSendToFront?()
                } else {
                    onSendForward?()
                }
            case 53: // Escape
                onDeselect?()
            default:
                super.keyDown(with: event)
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
    let onSendToBack: () -> Void
    let onSendBackward: () -> Void
    let onMoveForward: () -> Void
    let onMoveToFront: () -> Void
    
    @State private var isDragging: Bool = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            if let nsImage = NSImage(data: sticker.imageData) {
                ZStack {
                    // Rotated content
                    ZStack {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Rectangle())
                            .frame(width: sticker.size.width, height: sticker.size.height)
                            .shadow(color: .black.opacity(isDragging ? 0.5 : 0.3), radius: isSelected ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
                            .scaleEffect(isDragging ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isDragging)
                        // Z-ordering buttons (bottom edge)
                        if isSelected {
                            let proportional = sticker.size.height * 0.15
                            let offset = min(max(proportional, 16), 48)
                            HStack(spacing: 8) {
                                Button(action: onSendToBack) {
                                    Image(systemName: "chevron.down.2")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                Button(action: onSendBackward) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                Button(action: onMoveForward) {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                Button(action: onMoveToFront) {
                                    Image(systemName: "chevron.up.2")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .offset(y: (sticker.size.height / 2) + 24)
                        }
                        // Resize handle (right edge)
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
                            .offset(x: (sticker.size.width / 2) + 12, y: 0)
                        }
                    }
                    .rotationEffect(.degrees(sticker.rotation + rotationAngle))
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
            // Rotation handle at bottom right (not rotated)
            if isSelected {
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
        .onChange(of: isPresented) {
            if isPresented {
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

struct TextStickerView: View {
    let textSticker: TextSticker
    let isSelected: Bool
    let onTap: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onResize: (CGSize) -> Void
    let onRotate: (Double) -> Void
    let onTextChange: (String) -> Void
    let onFontSizeChange: (CGFloat) -> Void
    let onSendToBack: () -> Void
    let onSendBackward: () -> Void
    let onMoveForward: () -> Void
    let onMoveToFront: () -> Void
    
    @State private var isDragging: Bool = false
    @State private var isEditing: Bool = false
    @State private var editedText: String = ""
    
    private func textSize() -> CGSize {
        let font = NSFont.systemFont(ofSize: textSticker.fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (textSticker.text as NSString).size(withAttributes: attributes)
        return CGSize(width: size.width + 20, height: size.height + 10) // Add some padding
    }
    
    var body: some View {
        ZStack {
            // Text content
            if isEditing {
                TextField("Text", text: $editedText, onCommit: {
                    onTextChange(editedText)
                    isEditing = false
                })
                .font(.system(size: textSticker.fontSize))
                .foregroundColor(textSticker.textColor)
                .multilineTextAlignment(.center)
                .onAppear {
                    editedText = textSticker.text
                }
            } else {
                ZStack {
                    // White stroke (background)
                    Text(textSticker.text)
                        .font(.system(size: textSticker.fontSize))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .blur(radius: 0.5)
                    
                    // Main text
                    Text(textSticker.text)
                        .font(.system(size: textSticker.fontSize))
                        .foregroundColor(textSticker.textColor)
                        .multilineTextAlignment(.center)
                }
                .onTapGesture(count: 2) {
                    isEditing = true
                }
            }
            
            // Selection controls
            if isSelected {
                ZStack {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            // Send to Back
                            Button(action: onSendToBack) {
                                Image(systemName: "chevron.down.2")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in }
                            // Send Backward
                            Button(action: onSendBackward) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in }
                            // Move Forward
                            Button(action: onMoveForward) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in }
                            // Move to Front
                            Button(action: onMoveToFront) {
                                Image(systemName: "chevron.up.2")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in }
                        }
                        .padding(.bottom, 6)
                    }
                }
                
                // Font size handle at text edge
                ResizeSideHandle(
                    onDrag: { value in
                        let delta = value.translation.width
                        let scaleFactor = 1.0 + (delta / 100.0) // Scale factor based on drag
                        let newFontSize = max(8, textSticker.fontSize * scaleFactor)
                        onFontSizeChange(newFontSize)
                    }
                )
                .offset(x: textSize().width / 2 + 12, y: 0)
                
                // Rotation handle at center
                RotationHandle(
                    currentRotation: textSticker.rotation,
                    onRotate: onRotate
                )
                .offset(x: 0, y: 0)
            }
        }
        .position(textSticker.position)
        .rotationEffect(.degrees(textSticker.rotation))
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

#Preview {
    ContentView()
}
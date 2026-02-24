import SwiftUI

struct SelectionOverlay: View {
    @Binding var selectionRect: CGRect

    @State private var dragStartRect: CGRect = .zero

    private let minimumSize: CGFloat = 88

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.clear

                Rectangle()
                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 2)
                    .background(
                        Rectangle()
                            .fill(Color.cyan.opacity(0.12))
                    )
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .gesture(moveGesture(in: proxy.size))

                // Resize handle.
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                    .position(x: selectionRect.maxX, y: selectionRect.maxY)
                    .gesture(resizeGesture(in: proxy.size))
            }
            .onAppear {
                let initial = CGRect(x: 44, y: 170, width: proxy.size.width - 88, height: max(120, proxy.size.height * 0.22))
                selectionRect = boundedRect(initial, in: proxy.size)
            }
            .onChange(of: proxy.size.width) { _, _ in
                selectionRect = boundedRect(selectionRect, in: proxy.size)
            }
            .onChange(of: proxy.size.height) { _, _ in
                selectionRect = boundedRect(selectionRect, in: proxy.size)
            }
        }
    }

    private func moveGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartRect == .zero {
                    dragStartRect = selectionRect
                }
                selectionRect.origin.x = dragStartRect.origin.x + value.translation.width
                selectionRect.origin.y = dragStartRect.origin.y + value.translation.height
                selectionRect = boundedRect(selectionRect, in: size)
            }
            .onEnded { _ in
                dragStartRect = .zero
            }
    }

    private func resizeGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartRect == .zero {
                    dragStartRect = selectionRect
                }

                var updated = dragStartRect
                updated.size.width = max(minimumSize, dragStartRect.width + value.translation.width)
                updated.size.height = max(minimumSize, dragStartRect.height + value.translation.height)
                selectionRect = boundedRect(updated, in: size)
            }
            .onEnded { _ in
                dragStartRect = .zero
            }
    }

    private func boundedRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        var result = rect

        result.size.width = min(max(result.width, minimumSize), size.width)
        result.size.height = min(max(result.height, minimumSize), size.height)

        result.origin.x = min(max(result.origin.x, 0), size.width - result.width)
        result.origin.y = min(max(result.origin.y, 0), size.height - result.height)

        return result
    }
}

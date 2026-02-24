import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARTranslationViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)

        context.coordinator.arView = arView
        viewModel.snapshotProvider = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSnapshotProviding {
        weak var arView: ARView?

        func captureImage() async -> UIImage? {
            guard let arView else { return nil }
            return await withCheckedContinuation { continuation in
                arView.snapshot(saveToHDR: false) { image in
                    continuation.resume(returning: image)
                }
            }
        }

        func addTranslatedTextAnchor(text: String, at viewRect: CGRect) {
            guard let arView else { return }
            let center = CGPoint(x: viewRect.midX, y: viewRect.midY)

            if let raycast = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first {
                let anchor = AnchorEntity(world: raycast.worldTransform)
                anchor.addChild(makeTextEntity(text: text))
                arView.scene.addAnchor(anchor)
                return
            }

            guard let frame = arView.session.currentFrame else { return }
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.45
            let transform = simd_mul(frame.camera.transform, translation)
            let anchor = AnchorEntity(world: transform)
            anchor.addChild(makeTextEntity(text: text))
            arView.scene.addAnchor(anchor)
        }

        private func makeTextEntity(text: String) -> Entity {
            let mesh = MeshResource.generateText(
                text,
                extrusionDepth: 0.002,
                font: .systemFont(ofSize: 0.08, weight: .semibold),
                containerFrame: CGRect(x: 0, y: 0, width: 0.7, height: 0.4),
                alignment: .left,
                lineBreakMode: .byWordWrapping
            )

            let material = SimpleMaterial(color: UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 0.95), roughness: 0.18, isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.setScale([0.5, 0.5, 0.5], relativeTo: nil)

            // Keeps text facing the camera for readability while walking around.
            entity.components.set(BillboardComponent())
            return entity
        }
    }
}

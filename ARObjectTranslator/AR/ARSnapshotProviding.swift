import UIKit

protocol ARSnapshotProviding: AnyObject {
    func captureImage() async -> UIImage?
    func addTranslatedTextAnchor(text: String, at viewRect: CGRect)
}

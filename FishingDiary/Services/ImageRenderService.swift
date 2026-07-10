import SwiftUI
import UIKit

/// 出图渲染服务：把 SwiftUI 卡片模板渲染成 UIImage
struct ImageRenderService {

    enum CardRatio {
        case threeByFour   // 3:4 小红书
        case oneByOne      // 1:1 朋友圈
        case nineByteen    // 9:16 故事

        init(_ ratio: ShareStyleView.CardRatio) {
            switch ratio {
            case .threeByFour: self = .threeByFour
            case .oneByOne: self = .oneByOne
            case .nineByteen: self = .nineByteen
            }
        }

        var size: CGSize {
            switch self {
            case .threeByFour: return CGSize(width: 1080, height: 1440)
            case .oneByOne: return CGSize(width: 1080, height: 1080)
            case .nineByteen: return CGSize(width: 1080, height: 1920)
            }
        }

        var aspectRatio: CGFloat {
            size.width / size.height
        }
    }

    /// 渲染卡片（@3x 高清，导出用）
    @MainActor
    static func renderCard(
        session: FishingSession,
        visibleElements: ShareElementsConfig,
        showWatermark: Bool = false,
        ratio: CardRatio = .threeByFour
    ) -> UIImage {
        let size = ratio.size
        let view = MinimalCardView(
            session: session,
            visibleElements: visibleElements,
            showWatermark: showWatermark,
            ratio: ratio.aspectRatio
        )
            .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0  // 已经是实际像素尺寸，不需要额外倍率
        return renderer.uiImage ?? UIImage()
    }

    /// 渲染缩略图（用于实时预览，低分辨率）
    @MainActor
    static func renderThumbnail(
        session: FishingSession,
        visibleElements: ShareElementsConfig,
        width: CGFloat = 300
    ) -> UIImage {
        let ratio: CGFloat = 4.0 / 3.0
        let size = CGSize(width: width, height: width * ratio)
        let view = MinimalCardView(session: session, visibleElements: visibleElements)
            .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage ?? UIImage()
    }

    /// 保存到相册，并返回系统保存结果
    static func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PhotoLibrarySaveHandler.shared.completion = completion
        UIImageWriteToSavedPhotosAlbum(
            image,
            PhotoLibrarySaveHandler.shared,
            #selector(PhotoLibrarySaveHandler.image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
}

private final class PhotoLibrarySaveHandler: NSObject {
    static let shared = PhotoLibrarySaveHandler()
    var completion: ((Bool) -> Void)?

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let success = error == nil
        DispatchQueue.main.async { [completion] in
            completion?(success)
        }
        completion = nil
    }
}

/// 分享卡元素可见性配置
struct ShareElementsConfig: Hashable {
    var showFishAndLength: Bool = true
    var showLocation: Bool = true
    var showTide: Bool = true
    var showPressure: Bool = true
    var showWind: Bool = false
    var showUVAndTemp: Bool = false
}

import SwiftUI
import UIKit

/// 出图渲染服务：把 SwiftUI 卡片模板渲染成 UIImage
struct ImageRenderService {

    enum CardRatio {
        case threeByFour   // 3:4 小红书（MVP 唯一画幅）
        // TODO: Phase 2 添加 oneByOne / nineByteen

        var size: CGSize {
            switch self {
            case .threeByFour: return CGSize(width: 1080, height: 1440)
            }
        }
    }

    /// 渲染卡片（@3x 高清，导出用）
    @MainActor
    static func renderCard(
        session: FishingSession,
        visibleElements: ShareElementsConfig,
        ratio: CardRatio = .threeByFour
    ) -> UIImage {
        let size = ratio.size
        let view = MinimalCardView(session: session, visibleElements: visibleElements)
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

    /// 保存到相册
    static func saveToPhotoLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

/// 分享卡元素可见性配置
struct ShareElementsConfig {
    var showFishAndLength: Bool = true
    var showLocation: Bool = true
    var showTide: Bool = true
    var showPressure: Bool = true
    var showWind: Bool = false
    var showUVAndTemp: Bool = false
}

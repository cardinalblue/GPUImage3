//
//  HistogramEqualization.swift
//
//
//  Created by Chiaote Ni on 2024/6/4.
//

import Foundation

public class HistogramEqualization: BasicOperation {

    public enum ConvenientParameterKey: String {
        case none
    }

    public let identifier = UUID().uuidString

    public static let name = "HistogramEqualization"

    public static var convenientParameterDefinition: OrderedDictionary<ConvenientParameterKey, VisualEffectParameterDefinition> = [:]

    private var renderer: HistogramEqualizationRenderer

    public required init(convenientParameters: [ConvenientParameterKey : VisualEffectParameterValue]?) {
        renderer = HistogramEqualizationRenderer()
        self.convenientParameters = convenientParameters ?? [:]
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        guard fromSourceIndex == 0 else {
            assertionFailure("sourceIndex out of range")
            return
        }
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {
            return
        }

        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }

        frameTexture = texture.texture
        let size = CGSize(
            width: CGFloat(frameTexture.width),
            height: CGFloat(frameTexture.height)
        )
        let outputTexture = Texture(
            device: sharedMetalRenderingDevice.device,
            orientation: texture.orientation,
            pixelFormat: texture.texture.pixelFormat,
            width: Int(size.width),
            height: Int(size.height),
            timingStyle: texture.timingStyle
        )
        inputTextures[0] = texture

        renderer.render(
            inputFrameBuffer: [frameTexture],
            outputFrameBuffer: outputTexture.texture
        )

        removeTransientInputs()
        updateTargetsWithTexture(outputTexture)
    }
}

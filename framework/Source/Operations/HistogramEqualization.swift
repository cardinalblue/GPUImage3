//
//  HistogramEqualization.swift
//
//
//  Created by Chiaote Ni on 2024/6/4.
//

import Foundation

public class HistogramEqualization: ImageProcessingOperation {
    public var maximumInputs: UInt = 1
    public let targets = TargetContainer()
    public let sources = SourceContainer()

    private var renderer: HistogramEqualizationRenderer
    private let textureInputSemaphore = DispatchSemaphore(value:1)

    var inputTextures = [UInt: Texture]()

    init(renderer: HistogramEqualizationRenderer = HistogramEqualizationRenderer()) {
        self.renderer = renderer
    }

    public func transmitPreviousImage(to target: any ImageConsumer, atIndex: UInt) {}

    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        guard fromSourceIndex == 0 else {
            assertionFailure("sourceIndex out of range")
            return
        }

        let _ = textureInputSemaphore.wait(timeout:DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }

        let frameTexture = texture.texture
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

    private func removeTransientInputs() {
        for index in 0 ..< self.maximumInputs {
            if let texture = inputTextures[index], texture.timingStyle.isTransient() {
                inputTextures[index] = nil
            }
        }
    }
}

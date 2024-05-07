//
//  DirectionalShine.swift
//
//
//  Created by Chiaote Ni on 2024/4/24.
//

import Foundation

final class DirectionalShine: OperationGroup {

    var rayLength: Float = 0.08 {
        didSet {
            firstDirectionalBlurEffect.length = rayLength
            secondDirectionalBlurEffect.length = rayLength * 0.4
        }
    }
    var degree: Float = 45.0 {
        didSet {
            firstDirectionalBlurEffect.degree = degree
            secondDirectionalBlurEffect.degree = degree
        }
    }
    var sparkleExposure: Float = 2 {
        didSet {
            exposureEffect.exposure = 2 + sparkleExposure
        }
    }

    private let exposureEffect = ExposureAdjustment()
    private let firstDirectionalBlurEffect = CBDirectionalBlur()
    private let secondDirectionalBlurEffect = CBDirectionalBlur()

    deinit {
        let effects: [ImageProcessingOperation] = [
            exposureEffect,
            firstDirectionalBlurEffect,
            secondDirectionalBlurEffect
        ]
        effects.forEach { $0.resetPipeline() }
    }

    override init() {
        super.init()
        ({rayLength = 0.08})()
        ({degree = 45.0})()
        ({sparkleExposure = 2})()

        self.configureGroup { input, output in
            input
            --> firstDirectionalBlurEffect
            --> exposureEffect
            --> secondDirectionalBlurEffect
            --> output
        }
    }
}

//
//  CBKirakiraLightExtractor.swift
//  GPUImage
//
//  Created by Jim Wang on 2024/3/29.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class CBKirakiraLightExtractor: BasicOperation {

    // 0.0 ~ 1.0
    public var luminanceThreshold: Float = 0.8 {
        didSet { uniformSettings["luminanceThreshold"] = luminanceThreshold }
    }
    // 0.0 ~ 1.0
    public var gapThreshold: Float = 0.2 {
        didSet { uniformSettings["gapThreshold"] = gapThreshold }
    }
    // 0.0 ~ 1.0
    public var noiseThreshold: Float = 0.8 {
        didSet { uniformSettings["noiseThreshold"] = noiseThreshold }
    }
    // 0.0 ~ 1.0
    public var increasingRate: Float = 0.3 {
        didSet { uniformSettings["increasingRate"] = increasingRate }
    }
    // 0.0 ~ 1.0
    public var minHue: Float = 0.0 {
        didSet { uniformSettings["minHue"] = minHue }
    }
    // 0.0 ~ 1.0
    public var maxHue: Float = 1.0 {
        didSet { uniformSettings["maxHue"] = maxHue }
    }
    // 0.0 ~ 1.0
    public var equalMinHue: Float = 0.75 {
        didSet { uniformSettings["equalMinHue"] = equalMinHue }
    }
    // 0.0 ~ 1.0
    public var equalMaxHue: Float = 0.083 {
        didSet { uniformSettings["equalMaxHue"] = equalMaxHue }
    }
    // 0.0 ~ 1.0
    public var equalSaturation: Float = 0.15 {
        didSet { uniformSettings["equalSaturation"] = equalSaturation }
    }
    // 0.0 ~ 5.0
    public var equalBrightness: Float = 2.0 {
        didSet { uniformSettings["equalBrightness"] = equalBrightness }
    }

    public init() {
        super.init(fragmentFunctionName:"kirakiraLightExtractorFragment", numberOfInputs: 3)
        ({
            luminanceThreshold = 0.8
            gapThreshold = 0.2
            noiseThreshold = 0.8
            increasingRate = 0.3
            minHue = 0.0
            maxHue = 1.0
            equalMinHue = 0.75
            equalMaxHue = 0.083
            equalSaturation = 0.15
            equalBrightness = 2.0
        })()
    }
}

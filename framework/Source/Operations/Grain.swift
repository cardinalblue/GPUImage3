//
//  Grain.swift
//  GPUImage
//
//  Created by Jim Wang on 2023/11/6.
//  Copyright © 2023 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class Grain: BasicOperation {
    public var isSRGB: Float = 0 { didSet { uniformSettings["sRGB"] = isSRGB } }
    public var strength: Float = 0.1 { didSet { uniformSettings["strength"] = strength } }
    public var scale: Float = 1.0 { didSet { uniformSettings["scale"] = scale } }
    public var time: Float = 1.1 { didSet { uniformSettings["time"] = time } }
    public var blendMode: Float = 0.0 { didSet { uniformSettings["blendMode"] = blendMode } }

    public init() {
        super.init(fragmentFunctionName:"grainEffectFragment", numberOfInputs:1)
        ({isSRGB = 0.0})()
        ({strength = 0.1})()
        ({scale = 1.0})()
        ({time = 1.1})()
        ({blendMode = 0.0})()
    }
}

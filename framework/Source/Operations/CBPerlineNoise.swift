//
//  CBPerlineNoise.swift
//  GPUImage
//
//  Created by Jim Wang on 2024/3/29.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

import Foundation

public class CBPerlineNoise: BasicOperation {
    // 0.1 ~ 10.0
    public var scale: Float = 0.5 { didSet { uniformSettings["scale"] = 1 / scale } }
    // 0 ~ 10.0
    public var speed: Float = 1.0 { didSet { updateTime() } }
    // 1 ~ 120
    public var frameRate: Float = 60 { didSet { updateTime() } }

    public var time: Float = 0 {
        didSet {
            uniformSettings["time"] = time
        }
    }

    public init() {
        super.init(fragmentFunctionName:"perlineNoiseFragment", numberOfInputs: 1)
        ({
            scale = 0.5
            updateTime()
        })()
    }

    private func updateTime() {
        time += (1.0 / frameRate) * speed
    }
}

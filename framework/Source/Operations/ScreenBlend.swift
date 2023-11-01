public class ScreenBlend: BasicOperation {
    public var opacity: Float = 1 { didSet { uniformSettings["opacity"] = opacity } }
    public var mode: Float = 0 { didSet { uniformSettings["mode"] = mode } }

    public init() {
        super.init(fragmentFunctionName:"screenBlendFragment", numberOfInputs:2)
        ({
            opacity = 1
            mode = 0
        })()
    }
}

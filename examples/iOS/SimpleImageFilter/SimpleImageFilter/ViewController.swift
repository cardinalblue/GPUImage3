import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture: PictureInput!

    override func viewDidLoad() {
        super.viewDidLoad()
        renderView.contentMode = .scaleAspectFit
        renderView.colorPixelFormat = .bgra8Unorm
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        applyKiraKira()
    }

    private func applyGrain() {
        let grainFilter = Grain()
        grainFilter.strength = 9.0 / 100.0
        grainFilter.time = 1.1

        picture = PictureInput(image: UIImage(named:"WID-small.jpg")!)
        picture --> grainFilter --> renderView
        picture.processImage()
    }

    private func applyKiraKira() {
        let jsonFileNames = [
            "Kirakira_Flashlight",
            "Kirakira_Diamond",
            "Kirakira_Rainbow",
            "Kirakira_Barbie",
            "Kirakira_Golden",
            "Kirakira_Glamour"
        ]
        let parameters = { () -> Kirakira.Parameters in
            let jsonFileName = jsonFileNames[1] + ".json"
            let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: jsonFileName, withExtension: nil)!)
            let parameters = try! Kirakira.Parameters(with: jsonData)
            return parameters
        }()

        let filter = Kirakira(with: parameters)

        picture = PictureInput(image: UIImage(named:"WID-small.jpg")!)
        picture --> filter --> renderView
        picture.processImage()
    }
}


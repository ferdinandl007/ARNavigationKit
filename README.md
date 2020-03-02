# ARNavigationKit
ARNavigationKit Aims to provide easy-to-use path planning For ARKit.


## Example

To run the [Example project](https://github.com/ferdinandl007/voxelMap), clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 10.0+    
Xcode 10.0+   
Swift 4.2+     
And ARkit enabled device


## Installation

ARNavigationKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/ferdinandl007/ARNavigationKitPodSpecs.git'
pod 'ARNavigationKit','~> 0.1.0'
```


## Usage

import the following.
 ```Swift
 import ARNavigationKit
 ```
When initialising the ARNavigationKit, I recommend a voxel size of 7cm when dealing with single room application. 
However you may want to increase the grit size for larger maps to reduce computation  when computing Paths. 
```Swift
let voxelMap = ARNavigationKit(VoxelGridCellSize: 0.07)
```
Once your a session is running capture the feature points and add them into the map as follows.
10Hz should be sufficient to capture a good map and reduce computation to a minimum.
   
 ```Swift
 Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
     guard let currentFrame = self.augmentedRealitySession.currentFrame,
     let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
     self.voxelMap.addVoxels(featurePointsArray)
 }
 ```
ARNavigationKit needs to know about the ground height to detect obstacles, therefore use

```Swift
extension ViewController: ARSCNViewDelegate {
	func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
  		guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
      voxelMap.updateGroundPlane(planeAnchor)
  }

  func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
       guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        voxelMap.updateGroundPlane(planeAnchor)
   }
}
```
To request a past.

```Swift
voxelMap.getPath(start: SCNVector3, end: SCNVector3)
```

 As Path calculation can take some time, a delegate method is called once the calculation is complete.
```Swift
extension ViewController: ARNavigationKitDelegate {
   func getPathupdate(_ path: [vector_float3]?) {
    }	
   func updateDebugView(_ View: UIView) {
   }
}
```

## Author

[Ferdinand Loesch](https://ferdinandl007.github.io), ferdinandloesch@gmail.com

## License

ARNavigationKit is available under the MIT license. See the LICENSE file for more info.





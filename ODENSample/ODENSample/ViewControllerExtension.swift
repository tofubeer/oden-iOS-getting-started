import Foundation
import MapKit

// https://gist.github.com/andrewgleave/915374
extension ViewController
{
    func fitMapViewToAnnotaionList(_ mapView: MKMapView!)
    {
        let annotations    = mapView.annotations
        let mapEdgePadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        var zoomRect       = MKMapRectNull
        
        for index in 0..<annotations.count
        {
            let annotation = annotations[index]
            let aPoint     = MKMapPointForCoordinate(annotation.coordinate)
            let rect       = MKMapRectMake(aPoint.x, aPoint.y, 0.1, 0.1)
            
            if MKMapRectIsNull(zoomRect)
            {
                zoomRect = rect
            }
            else
            {
                zoomRect = MKMapRectUnion(zoomRect, rect)
            }
        }
        
        mapView.setVisibleMapRect(zoomRect, edgePadding: mapEdgePadding, animated: true)
    }
}

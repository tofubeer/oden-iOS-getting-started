// Copyright 2018 TerraTap Technologies Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import MapKit

class ViewController: UIViewController, ManifestDownloaderDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    let downloader = ManifestDownloader()
    var manifest : [ManifestEntry]?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        downloader.delegate = self
        
        do
        {
            try downloader.download("oden-manifest", overwrite: true)
        }
        catch
        {
            print("error: \(error.localizedDescription)")
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - ManifestDownloaderDelegate
    
    func converted(_ entry: ManifestEntry, to convertedDatasetURL: URL!)
    {
        print("converted \(entry.provider!) to: \(convertedDatasetURL.path)")
        
        /*
        do
        {
            print(try String(contentsOf: convertedDatasetURL));
        }
        catch
        {
            print(error)
        }
        */
        
        print("----")
    }
    
    func conversionCompleted(_ entries : [ManifestEntry]!)
    {
        let convertedDatasetURLs = Manifest.getLocalDatasetFilesFor(entries)!
        
        convertedDatasetURLs.forEach
        {
            (convertedDatasetURL) in
            
            do
            {
                let object = try PublicArt.getPublicArt(from: convertedDatasetURL)

                object.features!.forEach
                {
                    (feature) in
                    
                    let coordinate = CLLocationCoordinate2D(latitude: feature.geometry!.coordinates![1],
                                                            longitude: feature.geometry!.coordinates![0])
                    let annotation = MKPointAnnotation()

                    annotation.coordinate = coordinate
                    annotation.title      = feature.properties!.name!
                    self.mapView.addAnnotation(annotation)
                }
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        
        self.fitMapViewToAnnotaionList(self.mapView)
    }
    
    func downloadError(_ entry : ManifestEntry!, error: Error!)
    {
        sync(self)
        {
            print("error downloading \(entry.provider!): \(error.localizedDescription)")
            print("----")
        }
    }

    func downloadError(_ entry : ManifestEntry!, url : URL!, error : Error!)
    {
        sync(self)
        {
            print("error downloading \(url.path): \(error.localizedDescription)")
            print("----")
        }
    }
    
    func unarchiveError(_ entry : ManifestEntry!, url : URL!, error : Error!)
    {
        sync(self)
        {
            print("error unarchiving \(url.path): \(error.localizedDescription)")
            print("----")
        }
    }
    
    func conversionError(_ entry : ManifestEntry!, url : URL!, error : Error!)
    {
        sync(self)
        {
            print("error converting \(url.path): \(error.localizedDescription)")
            print("----")
        }
    }
}

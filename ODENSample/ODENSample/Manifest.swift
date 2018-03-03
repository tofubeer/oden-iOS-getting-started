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

import Foundation

public class Manifest
{
    public static func getManifestEntries(from fileName : String!) throws -> [ManifestEntry]!
    {
        if let file = Bundle.main.url(forResource: fileName, withExtension: "json")
        {
            let data     = try Data(contentsOf: file)
            let json     = String(data: data, encoding: .utf8)
            let manifest = [ManifestEntry](json: json)
            
            return manifest
        }
        
        throw Error.fileNotFound
    }
    
    public static func getManifestEntry(for id : String!, from fileName : String!) throws -> ManifestEntry?
    {
        if let file = Bundle.main.url(forResource: fileName, withExtension: "json")
        {
            let data     = try Data(contentsOf: file)
            let json     = String(data: data, encoding: .utf8)
            let manifest = [ManifestEntry](json: json)
            var entry : ManifestEntry? = nil
            
            for manifestEntry in manifest
            {
                if id == manifestEntry.id
                {
                    entry = manifestEntry
                    break
                }
            }

            return entry
        }
        
        throw Error.fileNotFound
    }

    public enum Error: Swift.Error, CustomStringConvertible
    {
        /// Thrown when a file couldn't be found
        case fileNotFound
        
        /// A string describing the error
        public var description: String
        {
            switch self
            {
            case .fileNotFound:
                return "File does not exist"
            }
        }
    }
    
    public static func getLocalFolderFor(_ entry: ManifestEntry!) -> URL!
    {
        // Public Art/CA
        var path = "\(entry.datasetName!)/\(entry.country!)"
        
        if let province = entry.province
        {
            // Public Art/CA/BC
            path += "/\(province)"
            
            if let region = entry.region
            {
                // Public Art/CA/BC/Metro Vancouver
                path += "/\(region)"
            }
            
            // a city doesn't have to be in a region
            if let city = entry.city
            {
                // Public Art/CA/BC/Metro Vancouver/New Westminster
                // or Public Art/CA/BC/Lund
                path += "/\(city)"
            }
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localFolder  = documentsURL.appendingPathComponent(path)
        
        return localFolder
    }
    
    public static func getLocalDatasetFileFor(_ entry: ManifestEntry!) -> URL!
    {
        let localFolderURL = getLocalFolderFor(entry)
        let providerURL    = localFolderURL!.appendingPathComponent("\(entry.provider!).json")
        
        return providerURL
    }
    
    public static func getLocalDatasetFilesFor(_ entries: [ManifestEntry]!) -> [URL]!
    {
        var datesetURLs : [URL] = []
        
        entries.forEach
        {
            (entry) in
            
            let providerDatasetURL = getLocalDatasetFileFor(entry)!
            
            datesetURLs.append(providerDatasetURL)
        }
        
        return datesetURLs
    }
}

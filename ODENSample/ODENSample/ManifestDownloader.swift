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
import ZIPFoundation
import JavaScriptCore

public class ManifestDownloader
{
    var delegate : ManifestDownloaderDelegate? = nil
    private var toDownloadCount = 0
    private var downloadedCount = 0
    private var allFilesAdded = false
    
    public func download(_ manifestFileName : String!, overwrite : Bool!) throws
    {
        let entries = try Manifest.getManifestEntries(from: manifestFileName)!
        
        download(entries, overwrite : overwrite)
    }
    
    public func download(_ entry : ManifestEntry, overwrite : Bool!)
    {
        download([entry], overwrite: overwrite)
    }
    
    public func download(_ entries : [ManifestEntry]!, overwrite : Bool!)
    {
        toDownloadCount = 0
        downloadedCount = 0
        allFilesAdded   = false
        
        entries.forEach
        {
            (entry) in
            
            do
            {
                try downloadEntry(entry, overwrite: overwrite)
                {
                    self.convert(entries)
                }
            }
            catch
            {
                DispatchQueue.main.async
                {
                    self.delegate?.downloadError(entry, error: error)
                }
            }
        }
        
        allFilesAdded = true
        
        // nothing downloaded
        if toDownloadCount == 0
        {
            DispatchQueue.main.async
            {
                self.delegate?.conversionCompleted(entries)
            }
        }
    }
    
    private func downloadEntry(_ entry : ManifestEntry, overwrite : Bool!, onDownloadComplete closure: @escaping () -> Void) throws
    {
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let cityPath     = "\(entry.datasetName!)/\(entry.country!)/\(entry.province!)/\(entry.region!)/\(entry.city!)"
//        let cityURL      = documentsURL.appendingPathComponent(cityPath)
        
        let localityURL = Manifest.getLocalFolderFor(entry)!
        
        if overwrite
        {
            try deleteFolder(localityURL)
        }
        
        try createFolder(localityURL)
        
        downloadProvider(entry, to: localityURL, overwrite: overwrite, onDownloadComplete: closure)
    }
    
    private func downloadProvider(_ entry : ManifestEntry, to localityURL: URL!, overwrite: Bool!, onDownloadComplete closure: @escaping () -> Void)
    {
        do
        {
            let providerURL = localityURL.appendingPathComponent(entry.provider!)
            
            try createFolder(providerURL)
            
            if let converterURL = entry.converter
            {
                downloadConverter(converterURL, forEntry: entry, to: providerURL, overwrite: overwrite, onDownloadComplete: closure)
            }
            
            for i in 0..<entry.downloads!.count
            {
                let download    = entry.downloads![i]
                let downloadURL = providerURL.appendingPathComponent("\(i)")
                let extract     = download.extract
                
                try createFolder(downloadURL)
                downloadDataset(download.src!, forEntry: entry, to: downloadURL, overwrite: overwrite, extract: extract, onDownloadComplete: closure)
            }
        }
        catch
        {
            DispatchQueue.main.async
            {
                self.delegate?.downloadError(entry, error: error)
            }
        }
    }
    
    private func downloadConverter(_ url: String!, forEntry entry: ManifestEntry, to localFolderURL : URL!, overwrite : Bool!, onDownloadComplete closure: @escaping () -> Void)
    {
        let localFileURL = localFolderURL.appendingPathComponent("converter.js")
        
        download(url, forEntry: entry, to: localFileURL, overwrite : overwrite, onDownloadComplete: closure)
    }
    
    private func downloadDataset(_ url: String!, forEntry entry: ManifestEntry!, to localFolderURL : URL!, overwrite : Bool!, extract : [ManifestEntry.Download.Extract]?, onDownloadComplete closure: @escaping () -> Void)
    {
        let localFileURL = localFolderURL.appendingPathComponent("dataset")
        
        if let extract = extract
        {
            downloadAndExtract(url, forEntry: entry, downloadTo: localFileURL, overwrite : overwrite, extractTo: localFolderURL, extract: extract, onDownloadComplete: closure)
        }
        else
        {
            download(url, forEntry: entry, to: localFileURL, overwrite : overwrite, onDownloadComplete: closure)
        }
    }
    
    private func download(_ url : String!, forEntry entry: ManifestEntry, to localFileURL : URL!, overwrite : Bool!, onDownloadComplete downloadComplete : @escaping () -> Void)
    {
        if shouldDownload(localFileURL, overwrite: overwrite)
        {
            let remoteFileURL = URL(string: url)
            
            addFile();
            
            Downloader.download(remoteFileURL, to: localFileURL)
            {
                (error) in
                
                if let error = error
                {
                    DispatchQueue.main.async
                    {
                        self.delegate?.downloadError(entry, url: localFileURL, error: error)
                    }
                }
                
                self.fileCompleted()
                {
                    downloadComplete()
                }
            }
        }
    }
    
    private func downloadAndExtract(_ url : String!, forEntry entry: ManifestEntry, downloadTo localFileURL : URL!, overwrite : Bool!, extractTo localFolderURL : URL!, extract : [ManifestEntry.Download.Extract]!, onDownloadComplete downloadComplete : @escaping () -> Void)
    {
        if shouldDownload(localFileURL, overwrite: overwrite)
        {
            let remoteFileURL = URL(string: url)
            
            addFile();
            
            Downloader.download(remoteFileURL, to: localFileURL)
            {
                (error) in
                
                if let error = error
                {
                    DispatchQueue.main.async
                    {
                        self.delegate?.downloadError(entry, url: localFileURL, error: error)
                    }
                }
                else
                {
                    do
                    {
                        try self.extractEntries(extract, from: localFileURL, to: localFolderURL)
                    }
                    catch
                    {
                        DispatchQueue.main.async
                        {
                            self.delegate?.unarchiveError(entry, url: localFileURL, error: error)
                        }
                    }
                }
                
                self.fileCompleted()
                {
                    downloadComplete()
                }
            }
        }
    }

    private func extractEntries(_ extract : [ManifestEntry.Download.Extract]!,
                                from archiveURL: URL!,
                                to toURL: URL!) throws
    {
        if let archive = Archive(url: archiveURL, accessMode: .read)
        {
            for entry in extract
            {
                if let zipEntry = archive[entry.src!]
                {
                    let destinationURL = toURL.appendingPathComponent(entry.dst!)
                    
                    _ = try archive.extract(zipEntry, to: destinationURL)
                }
            }
        }
    }
    
    private func convert(_ entries : [ManifestEntry]!)
    {
        entries.forEach
        {
            (entry) in
            
            convert(entry)
        }
        
        DispatchQueue.main.async
        {
            self.delegate?.conversionCompleted(entries)
        }
    }
    
    private func convert(_ entry : ManifestEntry)
    {
        let cityURL      = Manifest.getLocalFolderFor(entry)!
        let providerURL  = cityURL.appendingPathComponent(entry.provider!)
        let converterURL = providerURL.appendingPathComponent("converter.js")
        let convertedURL = cityURL.appendingPathComponent("\(entry.provider!).json")

        do
        {
            // no schema - no way to convert
            if entry.schema == nil
            {
                // how do we deal with this?
            }
            else
            {
                // yes schema, no converter - need to convert, proper format already
                if entry.converter == nil
                {
                    // for this to be the case we can only have a single data file, so it must be in 0
                    let datasetURL = providerURL.appendingPathComponent("0/dataset")
                    try FileManager.default.copyItem(at: datasetURL, to: convertedURL)
                }
                else
                {
                    try runConversion(converterURL, to: convertedURL, entry: entry, providerURL: providerURL)
                }
            }

            DispatchQueue.main.async
            {
                self.delegate?.converted(entry, to: convertedURL)
            }
        }
        catch
        {
            DispatchQueue.main.async
            {
                self.delegate?.conversionError(entry, url: converterURL, error: error)
            }
        }
    }
        
    private func runConversion(_ converterURL : URL!, to: URL!, entry : ManifestEntry!, providerURL: URL!) throws
    {
        let context      = JSContext()!
        let converterJS  = try String(contentsOf: converterURL, encoding: .utf8)
        var datasets : [String]! = []

        context.evaluateScript(converterJS)
        
        for i in 0..<entry.downloads!.count
        {
            let download = entry.downloads![i]
            
            if let extract = download.extract
            {
                for i in 0..<extract.count
                {
                    let datasetURL = providerURL.appendingPathComponent("\(i)/\(extract[i].dst!)")
                    let dataset    = try String(contentsOf: datasetURL, encoding: .utf8)

                    datasets.append(dataset)
                }
            }
            else
            {
                let datasetURL = providerURL.appendingPathComponent("\(i)/dataset")
                let dataset    = try String(contentsOf: datasetURL, encoding: .utf8)
                
                datasets.append(dataset)
            }
            
            let converter    = context.objectForKeyedSubscript("convert")!
            let result       = converter.call(withArguments: datasets)
            let resultString = result!.toString()
            
            try resultString!.write(to: to, atomically: false, encoding: .utf8)
        }
    }
    
    private func exists(_ url : URL!) -> Bool
    {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func deleteFolder(_ folderURL : URL) throws
    {
        var isDir : ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir)
            
        if isDir.boolValue
        {
            if exists
            {
                try FileManager.default.removeItem(atPath: folderURL.path)
            }
        }
        else
        {
            // TODO: throw
        }
    }
    
    private func createFolder(_ folderURL : URL!) throws
    {
        if !(FileManager.default.fileExists(atPath: folderURL.path))
        {
            try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true)
        }
    }
    
    private func addFile()
    {
        toDownloadCount += 1
    }
    
    private func fileCompleted(onDownloadComplete downloadComplete: () -> Void)
    {
        sync(self)
        {
            self.downloadedCount += 1
            
            if allFilesAdded
            {
                if self.downloadedCount == toDownloadCount
                {
                    downloadComplete()
                }
            }
        }
    }
    
    private func shouldDownload(_ localURL : URL, overwrite : Bool!) -> Bool!
    {
        let retVal : Bool
        
        if overwrite
        {
            retVal = true
        }
        else if exists(localURL)
        {
            retVal = false
        }
        else
        {
            retVal = true
        }
        
        return retVal
    }
}


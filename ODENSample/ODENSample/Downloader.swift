import Foundation

// https://stackoverflow.com/questions/28219848/how-to-download-file-in-swift/28221670
public class Downloader
{
    public static func download(_ remoteURL: URL!, to localURL: URL!, completion: @escaping (_ : Error?) -> Void)
    {
        let sessionConfig = URLSessionConfiguration.default
        let session       = URLSession(configuration: sessionConfig)
        let request       = URLRequest(url: remoteURL)
        
        let task = session.downloadTask(with: request)
        {
            (tempLocalURL, _, error) in
            
            if let error = error
            {
                completion(error)
            }
            else
            {
                if let tempLocalURL = tempLocalURL
                {
                    do
                    {
                        try FileManager.default.copyItem(at: tempLocalURL, to: localURL)
                    }
                    catch
                    {
                        completion(error)
                    }
                }
                
                completion(nil)
            }
        }
        
        task.resume()
    }
}


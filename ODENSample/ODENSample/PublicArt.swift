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
import EVReflection

public class PublicArt : EVObject
{
    public var type : String?
    public var features : [Feature]?
    
    public class Feature : EVObject
    {
        public var type : String?
        public var geometry : Geometry?
        public var properties : Properties?
        
        public class Geometry : EVObject
        {
            public var type : String?
            public var coordinates: [Double]?
        }
        
        public class Properties : EVObject
        {
            public var name : String?
            public var summary : String?
            public var shortDescription : String?
            public var address : String?
            public var website : String?
            public var access : String?
            public var year : NSNumber?
            public var medium : String?
            public var material : String?
            public var images : [Image]?
            public var artist : Artist?
            
            public class Image : EVObject
            {
                public var image : String?
                public var credit : String?
            }
            
            public class Artist : EVObject
            {
                public var name : String?
                public var country : String?
                public var website : String?
                public var biography : String?
                public var image : String?
                public var imageCredit : String?
            }
        }
    }
    
    public static func getPublicArt(from url: URL!) throws -> PublicArt
    {
        let json = try String(contentsOf: url, encoding: .utf8)
        let data = PublicArt(json: json)
        
        return data
    }
}



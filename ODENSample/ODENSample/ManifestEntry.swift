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

public class ManifestEntry : EVObject
{
    var datasetName : String?
    var country : String?
    var province : String?
    var region : String?
    var city : String?
    var provider: String?
    var schema: String?
    var converter: String?
    var id : String?
    var downloads : [Download]?
        
    public class Download : EVObject
    {
        var src: String?
        var encoding: String?
        var extract : [Extract]?

        public class Extract : EVObject
        {
            var src: String?
            var dst: String?
            var encoding: String?
        }
    }
}

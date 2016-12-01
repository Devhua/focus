/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngineManager {
    private static let prefKeyEngine = "prefKeyEngine"

    private let prefs: UserDefaults

    init(prefs: UserDefaults) {
        self.prefs = prefs
    }

    var activeEngine: SearchEngine {
        get {
            let selectName = prefs.string(forKey: SearchEngineManager.prefKeyEngine)
            return engines.first { $0.name == selectName } ?? engines.first!
        }

        set {
            prefs.set(newValue.name, forKey: SearchEngineManager.prefKeyEngine)
        }
    }

    lazy var engines: [SearchEngine] = {
        let enginesPath = Bundle.main.path(forResource: "SearchEngines", ofType: "plist")!
        let engineMap = NSDictionary(contentsOfFile: enginesPath) as! [String: [String]]
        let engines = self.searchPaths.flatMap { engineMap[$0] }.first!
        let parser = OpenSearchParser(pluginMode: true)
        let pluginsPath = Bundle.main.url(forResource: "SearchPlugins", withExtension: nil)!

        return engines.flatMap { name in
            let path = self.searchPaths
                           .map({ pluginsPath.appendingPathComponent($0).appendingPathComponent(name + ".xml") })
                           .first { FileManager.default.fileExists(atPath: $0.path) }!
            return parser.parse(file: path)
        }
    }()

    private lazy var searchPaths: [String] = {
        var components = Locale.preferredLanguages.first!.components(separatedBy: "-")
        if components.count == 3 {
            components.remove(at: 1)
        }
        return [components.joined(separator: "-"), components[0], "default"]
    }()
}

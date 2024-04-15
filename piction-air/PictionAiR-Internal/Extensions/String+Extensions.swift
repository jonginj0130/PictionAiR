//
//  String+Extensions.swift
//  PictionAiR-Internal
//
//  Created by Rahul Narayanan on 11/10/23.
//

import Foundation

extension String {
    
    /// Removes the given suffix from the string. If the suffix does not exist, the original string is returned.
    func removingSuffix(_ suffix: String) -> String {
        if self.hasSuffix(suffix) {
            return String(self.prefix(self.count - suffix.count))
        }
        
        return self
    }
    
    func removeHostSuffix() -> String {
        return self.removingSuffix(MultipeerSession.hostSuffix)
    }
    
    func toUnderscore() -> String {
        let newWord = self.map {
            $0 == " " ? " " : "_"
        }.joined()
        return newWord
    }
}

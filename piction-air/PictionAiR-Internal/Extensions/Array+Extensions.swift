//
//  Array+Extensions1.swift
//  PictionAiR-Internal
//
//  Created by Sankaet Cheemalamarri on 2/3/24.
//

import Foundation

extension Array where Element: Equatable {
    
    /// Returns a random element that is not the other element. Returns nil if the array has only one element.
    func randomElement(not other: Element) -> Element? {
        guard count > 1 else { return nil }
        
        var newElement = randomElement()
        while newElement == other {
            newElement = randomElement()
        }
        
        return newElement
    }
}

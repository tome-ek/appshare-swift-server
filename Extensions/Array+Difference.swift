//
//  ArrayExtensions.swift
//  PhoneStreamer-iOS
//
//  Created by Tomasz Bartkowski on 13/06/2021.
//

import Foundation

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

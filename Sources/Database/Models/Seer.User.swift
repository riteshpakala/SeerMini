//
//  Seer.USer.swift
//  seer-server
//
//  Created by Ritesh Pakala Rao on 12/15/25.
//

import Vapor

extension Seer {
    struct User: Content, Codable {
        var groups: [Seer.Group]
    }
}

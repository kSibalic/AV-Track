//
//  JobManifest.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 02.03.2026..
//

import Foundation
import SwiftData

enum ManifestStatus: String, Codable, CaseIterable, Identifiable {
    case draft =    "Draft"
    case packed =   "Packed"
    case returned = "Returned"
    
    var id: String { rawValue }
}

@Model
final class JobManifest {
    
    var id: UUID
    var jobName: String
    var eventDate: Date
    var status: ManifestStatus
    
    @Relationship(deleteRule: .cascade, inverse: \ManifestItem.manifest)
    var items: [ManifestItem] = []
    
    init(
        jobName: String,
        eventDate: Date,
        status: ManifestStatus = .draft
    ) {
        self.id = UUID()
        self.jobName = jobName
        self.eventDate = eventDate
        self.status = status
    }
}

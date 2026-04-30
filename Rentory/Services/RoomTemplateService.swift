//
//  RoomTemplateService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum RoomTemplateService {
    static func defaultChecklistTitles(for roomType: RoomType) -> [String] {
        switch roomType {
        case .kitchen:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Worktops",
                "Sink",
                "Taps",
                "Hob",
                "Oven",
                "Extractor fan",
                "Fridge or freezer",
                "Dishwasher",
                "Washing machine",
                "Cupboards",
                "Windows",
                "Doors",
                "Lighting",
                "Sockets",
                "Mould or damp",
                "Smoke or heat alarm",
            ]
        case .bathroom, .ensuite:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Bath",
                "Shower",
                "Sink",
                "Taps",
                "Toilet",
                "Tiles",
                "Extractor fan",
                "Mirror",
                "Cabinet",
                "Windows",
                "Door",
                "Lighting",
                "Mould or damp",
            ]
        case .bedroom:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Windows",
                "Door",
                "Wardrobe or storage",
                "Lighting",
                "Sockets",
                "Radiator",
                "Curtains or blinds",
                "Furniture",
                "Mould or damp",
            ]
        case .livingRoom:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Windows",
                "Doors",
                "Lighting",
                "Sockets",
                "Radiator",
                "Curtains or blinds",
                "Furniture",
                "Fireplace",
                "Mould or damp",
            ]
        case .hallway:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Front door",
                "Internal doors",
                "Lighting",
                "Sockets",
                "Stairs",
                "Banister",
                "Smoke alarm",
                "Mould or damp",
            ]
        case .garden:
            return [
                "Fencing",
                "Gate",
                "Lawn",
                "Patio or paving",
                "Shed or storage",
                "Bins",
                "External lighting",
                "Drains",
                "Outdoor tap",
                "Parking area",
            ]
        case .garage:
            return [
                "Door",
                "Floor",
                "Walls",
                "Ceiling",
                "Lighting",
                "Sockets",
                "Storage",
                "Parking space",
                "Security",
                "Damp or leaks",
            ]
        case .utility:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Sink",
                "Taps",
                "Washing machine space",
                "Dryer space",
                "Boiler",
                "Cupboards",
                "Lighting",
                "Sockets",
                "Mould or damp",
            ]
        case .other:
            return [
                "Walls",
                "Ceiling",
                "Flooring",
                "Windows",
                "Doors",
                "Lighting",
                "Sockets",
                "Fixtures",
                "Fittings",
                "Notes",
            ]
        }
    }
}

//
//  MoviesAPI.swift
//  ModernMVVM
//
//  Created by Vadym Bulavin on 2/20/20.
//  Copyright © 2020 Vadym Bulavin. All rights reserved.
//

import Foundation
import Combine

enum SpaceXAPI {
    static let imageBase = URL(string: "https://image.tmdb.org/t/p/original/")!
    
    private static let base = "https://api.spacexdata.com/v4"
    private static let agent = Agent()
    
    static func getLaunches(startDate: Date, endDate: Date) -> AnyPublisher<LaunchResponse, Error> {
        let requestBody = LaunchRequest(
            query: LaunchRequest.Query(
                date_utc: LaunchRequest.DateStruct(
                    gte: DateFormatter.iso8601Full.string(from: startDate),
                    lte: DateFormatter.iso8601Full.string(from: endDate)
                )
            ),
            options: LaunchRequest.Options(
                sort: LaunchRequest.Sort(
                    utc_date: "asc"
                ),
                pagination: false
            )
        )
        
        let url = URL(string: base.appending("/launches/query"))
        
        var request = URLComponents(url: url!, resolvingAgainstBaseURL: true)?
            .request
        request?.httpMethod = "post"
        request?.httpBody = try! JSONEncoder().encode(requestBody)
        return agent.run(request!)
    }
    
    static func getRocket(rocketName: String) -> AnyPublisher<Rocket, Error> {
        let url = URL(string: base.appending("/rockets/\(rocketName)"))
        var request = URLComponents(url: url!, resolvingAgainstBaseURL: true)?
            .request
        request?.httpMethod = "get"
        return agent.run(request!)
    }
}

struct LaunchRequest: Codable {
    let query: Query
    let options: Options
    
    struct Query: Codable {
        let date_utc: DateStruct
    }
    
    struct DateStruct: Codable {
        let gte: String
        let lte: String
        
        enum CodingKeys: String, CodingKey {
            case gte = "$gte"
            case lte = "$lte"
        }
    }
    
    struct Options: Codable {
        let sort: Sort
        let pagination: Bool
    }
    
    struct Sort: Codable {
        let utc_date: String
    }
}

private extension URLComponents {
    var request: URLRequest? {
        url.map { URLRequest.init(url: $0) }
    }
}

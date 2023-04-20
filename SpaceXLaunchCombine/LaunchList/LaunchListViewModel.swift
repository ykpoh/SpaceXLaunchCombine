//
//  LaunchListViewModel.swift
//  SpaceXLaunchCombine
//
//  Created by YK Poh on 28/01/2023.
//

import Foundation
import SwiftUI
import Combine

final class LaunchListViewModel: ObservableObject {
    @Published private(set) var state = State.idle
    
    private var bag = Set<AnyCancellable>()
    
    private let input = PassthroughSubject<Event, Never>()
    
    init() {
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }
    
    deinit {
        bag.removeAll()
    }
    
    func send(event: Event) {
        input.send(event)
    }
}

extension LaunchListViewModel {
    enum State {
        case idle
        case loading
        case loaded([ListItem])
        case error(Error)
    }
    
    enum Event {
        case onAppear
        case onSelectLaunch(Int)
        case onLaunchesLoaded([ListItem])
        case onFailedToLoadLaunches(Error)
    }
    
    struct ListItem: Identifiable {
        enum Status: String {
            case upcoming = "UPCOMING"
            case success = "SUCCESS"
            case fail = "FAIL"
        }
        
        let id: String
        var launchNumber: String
        var detail: String?
        var dateTime: String
        var statusString: String
        var statusTextColor: Color
        var status: Status = .upcoming
        var rocket: String
        
        init(launch: Launch) {
            id = launch.id ?? ""
            launchNumber = launch.name ?? ""
            detail = launch.details
            if let date = launch.date_utc {
                dateTime = "Launch time: \(DateFormatter.dateTimeSeconds.string(from: date)) (UTC)"
            } else {
                dateTime = "Launch time: TBD"
            }
            if launch.upcoming ?? false {
                status = .upcoming
            } else if launch.success ?? false {
                status = .success
            } else {
                status = .fail
            }
            statusString = status.rawValue
            switch status {
            case .upcoming:
                statusTextColor = .brown
            case .success:
                statusTextColor = .green
            case .fail:
                statusTextColor = .red
            }
            rocket = launch.rocket ?? ""
        }
    }
}

// MARK: - State Machine

extension LaunchListViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .onAppear:
                return .loading
            default:
                return state
            }
        case .loading:
            switch event {
            case .onFailedToLoadLaunches(let error):
                return .error(error)
            case .onLaunchesLoaded(let launches):
                return .loaded(launches)
            default:
                return state
            }
        case .loaded:
            return state
        case .error:
            return state
        }
    }
    
    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state else { return Empty().eraseToAnyPublisher() }
            
            return SpaceXAPI.getLaunches(
                startDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
                endDate: Date()
            )
            .map { $0.docs.map(ListItem.init) }
            .map(Event.onLaunchesLoaded)
            .catch { Just(Event.onFailedToLoadLaunches($0)) }
            .eraseToAnyPublisher()
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

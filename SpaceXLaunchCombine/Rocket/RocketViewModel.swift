//
//  RocketViewModel.swift
//  SpaceXLaunchCombine
//
//  Created by YK Poh on 31/01/2023.
//

import Foundation
import Combine

final class RocketViewModel: ObservableObject {
    @Published private(set) var state: State
    
    private var bag = Set<AnyCancellable>()
    
    private let input = PassthroughSubject<Event, Never>()
    
    init(rocketID: String) {
        state = .idle(rocketID)
        
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

extension RocketViewModel {
    enum State {
        case idle(String)
        case loading(String)
        case loaded(RocketDetail)
        case error(Error)
    }
    
    enum Event {
        case onAppear
        case onLoaded(RocketDetail)
        case onFailedToLoad(Error)
    }
    
    struct RocketDetail {
        let id: String
        let imageURLs: [URL]
        let title: String
        let description: String
        let url: URL?
        
        init(rocket: Rocket) {
            id = rocket.name ?? ""
            title = rocket.name ?? ""
            description = rocket.description ?? ""
            imageURLs = rocket.flickr_images ?? []
            url = rocket.wikipedia
        }
    }
}

// MARK: - State Machine

extension RocketViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle(let id):
            switch event {
            case .onAppear:
                return .loading(id)
            default:
                return state
            }
        case .loading:
            switch event {
            case .onFailedToLoad(let error):
                return .error(error)
            case .onLoaded(let movie):
                return .loaded(movie)
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
            guard case .loading(let id) = state else { return Empty().eraseToAnyPublisher() }
            
            return SpaceXAPI.getRocket(rocketName: id)
                .map(RocketDetail.init)
                .map(Event.onLoaded)
                .catch { Just(Event.onFailedToLoad($0)) }
                .eraseToAnyPublisher()
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            return input
        })
    }
}

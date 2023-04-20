//
//  ContentView.swift
//  SpaceXLaunchCombine
//
//  Created by YK Poh on 28/01/2023.
//

import SwiftUI

struct LaunchListView: View {
    
    @ObservedObject var viewModel: LaunchListViewModel
    
    var body: some View {
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Launch Schedules")
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
    }
    
    private var content: some View {
        switch viewModel.state {
        case .idle:
            return Color.clear.eraseToAnyView()
        case .loading:
            return Spinner(isAnimating: true, style: .large).eraseToAnyView()
        case .error(let error):
            return Text(error.localizedDescription).eraseToAnyView()
        case .loaded(let launches):
            return list(of: launches).eraseToAnyView()
        }
    }
    
    private func list(of launches: [LaunchListViewModel.ListItem]) -> some View {
        return List(launches) { launch in
            NavigationLink(
                destination: RocketView(viewModel: RocketViewModel(rocketID: launch.rocket)),
                label: { LaunchListItemView(launch: launch) }
            )
        }
    }
}

struct LaunchListView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchListView(viewModel: LaunchListViewModel())
    }
}

struct LaunchListItemView: View {
    let launch: LaunchListViewModel.ListItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Spacer()
                
                Text(launch.launchNumber)
                    .font(.title)
                    .bold()
                
                Spacer()
                
                if let detail = launch.detail {
                    Text(detail)
                        .font(.body)
                    Spacer()
                }
                
                Text(launch.dateTime)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            
            Text(launch.statusString)
                .foregroundColor(launch.statusTextColor)
                .frame(maxWidth: .infinity)
        }
    }
}

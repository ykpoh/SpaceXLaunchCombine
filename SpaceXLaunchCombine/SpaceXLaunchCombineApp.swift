//
//  SpaceXLaunchCombineApp.swift
//  SpaceXLaunchCombine
//
//  Created by YK Poh on 28/01/2023.
//

import SwiftUI

@main
struct SpaceXLaunchCombineApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchListView(viewModel: LaunchListViewModel())
        }
    }
}

//
//  RocketView.swift
//  SpaceXLaunchCombine
//
//  Created by YK Poh on 29/01/2023.
//

import SwiftUI

struct RocketView: View {
    @ObservedObject var viewModel: RocketViewModel
    @Environment(\.imageCache) var cache: ImageCache
    @State private var totalHeight = CGFloat(300)
    
    var body: some View {
        content
            .onAppear { self.viewModel.send(event: .onAppear) }
    }
    
    private var content: some View {
        switch viewModel.state {
        case .idle:
            return Color.clear.eraseToAnyView()
        case .loading:
            return spinner.eraseToAnyView()
        case .error(let error):
            return Text(error.localizedDescription).eraseToAnyView()
        case .loaded(let rocket):
            return self.rocket(rocket).eraseToAnyView()
        }
    }
    
    private func rocket(_ rocket: RocketViewModel.RocketDetail) -> some View {
        VStack(alignment: .leading) {
            GeometryReader{ proxy in
                TabView {
                    ForEach(rocket.imageURLs, id: \.self) { url in
                        photos(of: url)
                    }
                    
                }
                .tabViewStyle(PageTabViewStyle())
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(width: proxy.size.width, height: totalHeight)
            }
            .frame(height: totalHeight)
            Text(rocket.title)
                .font(.title)
                .bold()
            Spacer()
                .frame(height: 20)
            Text(rocket.description)
                .font(.body)
            Spacer()
                .frame(height: 20)
            Link("Wikipedia", destination: rocket.url!)
                .font(.body)
            Spacer()
        }.padding()
    }
    
    private func photos(of url: URL) -> some View {
        AsyncImage(
            url: url,
            cache: cache,
            placeholder: self.spinner,
            configuration: { $0.resizable() }
        )
        .aspectRatio(contentMode: .fit)
    }
    
    private var spinner: Spinner { Spinner(isAnimating: true, style: .large) }
}

struct RocketView_Previews: PreviewProvider {
    static var previews: some View {
        RocketView(viewModel: RocketViewModel(rocketID: "123"))
    }
}

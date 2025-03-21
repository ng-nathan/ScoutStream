//
//  HomeView.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-17.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                DeviceListView()
                Spacer()
            }
            .navigationTitle("Scout Stream")
        }
    }
}

#Preview {
    HomeView()
}

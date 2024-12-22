//
//  AboutAppView.swift
//  ARTimeWalk
//
//  Created by Ryoo FUJIWARA on 2024/07/07.
//

import SwiftUI

struct AboutAppView: View {
    @StateObject private var model = AboutAppDataModel()
    @EnvironmentObject var initialDataTransfer: InitialDataTransfer
    
    let initial: Bool
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack {
                    TabView(selection: $model.selection) {
                        // MARK: Description 1
                        Group {
                            VStack {
                                Image(uiImage: UIImage(named: "description_image_1")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaledToFit()
                                    .cornerRadius(10)
                                Text("This app presents past photographs in AR at the location in the real world.")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: geometry.size.width * 0.9, maxHeight: geometry.size.height * 0.6)
                        }
                        .tag(0)
                        
                        // MARK: Description 2
                        Group {
                            VStack {
                                Image(uiImage: UIImage(named: "description_image_2")!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaledToFit()
                                    .cornerRadius(10)
                                Text("Photographs are linked to signs or billboards throughout the city.")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: geometry.size.width * 0.9, maxHeight: geometry.size.height * 0.6)
                        }
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    
                    Button(action: {
                        initialDataTransfer.isDocumentViewPresented = true
                    }) {
                        Text("Next")
                            .frame(width: 150, height: 40)
                            .foregroundColor(.white)
                            .background(Color.digitalBlue_color)
                            .cornerRadius(10)
                    }
                    .navigationDestination(isPresented: $initialDataTransfer.isDocumentViewPresented) {
                        DocumentView(initial: true)
                    }
                    .opacity(model.selection == 1 && initial ? 1.0 : 0.0)
                    .disabled(model.selection == 0 && initial == false)
                    Spacer()
                        .frame(height: geometry.size.height * 0.05)
                }
            }
        }
        .accentColor(Color.primary)
    }
}

struct AboutAppView_Previews: PreviewProvider {
    static var previews: some View {
        AboutAppView(initial: true)
            .environmentObject(InitialDataTransfer())
    }
}


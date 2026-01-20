//
//  QRCompositeImageView.swift
//  fotoX
//
//  Displays a composite photo strip image from a file URL
//

import SwiftUI
import UIKit

/// Displays the composite photo strip from a local file URL
struct QRCompositeImageView: View {
    let imageURL: URL

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .overlay {
                        ProgressView()
                    }
            } else {
                // Failed to load
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: imageURL),
               let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

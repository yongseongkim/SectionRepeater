//
//  AudioPlayerSimpleHeaderView.swift
//  Repeatit
//
//  Created by yongseongkim on 2020/04/07.
//

import SwiftUI

struct AudioPlayerSimpleHeaderView: View {
    let model: ViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(self.model.title)
                .lineLimit(1)
                .layoutPriority(5)
                .font(.system(size: 17))
                .foregroundColor(.systemBlack)
            Divider()
                .background(Color.systemBlack)
                .padding([.leading, .trailing], 8)
                .frame(height: 20, alignment: .center)
            Text(self.model.artist)
                .lineLimit(1)
                .layoutPriority(1)
                .font(.system(size: 17))
                .foregroundColor(.systemBlack)
                .frame(minWidth: 50)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
        .background(Color.systemGray6)
    }
}

extension AudioPlayerSimpleHeaderView {
    struct ViewModel {
        let title: String
        let artist: String

        init(metadata: MediaMetadata) {
            self.title = metadata.title
            self.artist = metadata.artist
        }

        init(title: String, artist: String) {
            self.title = title
            self.artist = artist
        }
    }
}

struct AudioPlayerSimpleHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AudioPlayerSimpleHeaderView(
                model: .init(
                    title: "Second Emotion(Feat. Travis Scott)",
                    artist: "Kygo, Whitney Houston"
                )
            )
            .environment(\.colorScheme, .light)
            .previewLayout(.sizeThatFits)
            AudioPlayerSimpleHeaderView(
                model: .init(
                    title: "Second Emotion(Feat. Travis Scott)",
                    artist: "Kygo, Whitney Houston"
                )
            )
            .environment(\.colorScheme, .dark)
            .previewLayout(.sizeThatFits)
        }
    }
}

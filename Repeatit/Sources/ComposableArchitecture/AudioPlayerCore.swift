//
//  AudioPlayerCore.swift
//  Repeatit
//
//  Created by YongSeong Kim on 2020/10/25.
//

import AVFoundation
import Combine
import ComposableArchitecture
import UIKit

struct AudioClientID: Hashable {}

// MARK: - Composable Architecture Components
enum AudioPlayerAction: Equatable {
    case open

    // Subreducer
    case waveform(WaveformAction)
    // Environment
    case player(Result<LocalMediaClient.Action, Never>)
    // Reusable reducers
    case playerControl(PlayerControlAction)
    case bookmark(BookmarkAction)
}

struct AudioPlayerState: Equatable {
    let current: Document
    var waveform: WaveformState
    var playerControl: PlayerControlState
    var bookmark: BookmarkState

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.current == rhs.current
            && lhs.bookmark == rhs.bookmark
    }
}

struct AudioPlayerEnvironment {
    let audioClient: LocalMediaClient
    let waveformClient: WaveformClient
    let bookmarkClient: BookmarkClient
}
// MARK: -

let audioPlayerReducer = Reducer<AudioPlayerState, AudioPlayerAction, AudioPlayerEnvironment> {
    state, action, environment in
    let url = state.current.url
    switch action {
    case .open:
        return environment.audioClient.open(AudioClientID(), state.current.url)
            .receive(on: DispatchQueue.main)
            .catchToEffect()
            .map(AudioPlayerAction.player)
            .eraseToEffect()
            .cancellable(id: AudioClientID())
    case .player(.success(.layerDidLoad)):
        return .none
    case .player(.success(.durationDidChange(let seconds))):
        state.waveform = state.waveform.updated(duration: seconds)
        return .none
    case .player(.success(.playingDidChange(let isPlaying))):
        state.waveform = state.waveform.updated(isPlaying: isPlaying)
        state.playerControl = PlayerControlState(isPlaying: isPlaying)
        return .none
    case .player(.success(.playTimeDidChange(let seconds))):
        state.waveform = state.waveform.updated(playTime: seconds)
        return .none
    case .waveform:
        return .none
    case .playerControl:
        return .none
    case .bookmark:
        return .none
    }
}
.waveform(
    state: \.waveform,
    action: /AudioPlayerAction.waveform,
    environment: { environment in
        WaveformEnvironment(
            resume: { environment.audioClient.resume(AudioClientID()) },
            pause: { environment.audioClient.pause(AudioClientID()) },
            move: { environment.audioClient.move(AudioClientID(), $0) },
            waveformClient: environment.waveformClient
        )
    }
)
.playerControl(
    state: \.playerControl,
    action: /AudioPlayerAction.playerControl,
    environment: { environment in
        PlayerControlEnvironment(
            resume: { environment.audioClient.resume(AudioClientID()) },
            pause: { environment.audioClient.pause(AudioClientID()) },
            moveForward: { environment.audioClient.moveForward(AudioClientID(), $0) },
            moveBackward: { environment.audioClient.moveBackward(AudioClientID(), $0) }
        )
    }
)
.bookmark(
    state: \.bookmark,
    action: /AudioPlayerAction.bookmark,
    environment: { environment in
        BookmarkEnvironment(
            move: { environment.audioClient.move(AudioClientID(), $0) },
            bookmarkClient: environment.bookmarkClient
        )
    }
)
.lifecycle(
    onAppear: { _ in Effect(value: .open) },
    onDisappear: { _ in .cancel(id: AudioClientID()) }
)

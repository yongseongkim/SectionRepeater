//
//  AppAction.swift
//  Repeatit
//
//  Created by YongSeong Kim on 2020/10/11.
//

import Foundation

enum AppAction: Equatable {
    case documentsExplorerAppeared(url: URL)
    case editButtonTapped(Bool)
    case floatingButtonTapped
    case documentItemTappedWhileEditing(Document)
    case confirmImportURLs([URL])
    case confirmCreatingNewFolder(String)
    case confirmCreatingYoutube(String)
    case confirmRenaming(String)
    case confirmMovingFiles(URL)
    case confirmCopyingFiles(URL)
    case confirmDeletingFiles
}

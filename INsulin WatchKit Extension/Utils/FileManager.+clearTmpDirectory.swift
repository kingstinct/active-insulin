//
//  FileManager.+clearTmpDirectory.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation

extension FileManager {
  func clearTmpDirectory() {
    do {
      let tmpDirURL = FileManager.default.temporaryDirectory
      let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
      try tmpDirectory.forEach { file in
        let fileUrl = tmpDirURL.appendingPathComponent(file)
        try removeItem(atPath: fileUrl.path)
      }
    } catch {
      //catch the error somehow
    }
  }
}

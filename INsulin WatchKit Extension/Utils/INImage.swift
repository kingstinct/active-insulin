//
//  INImage.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-28.
//  Copyright © 2020 Robert Herber. All rights reserved.
//

import Foundation
//
//  UNNotificationAttachment+create.swift
//  INsulin WatchKit Extension
//
//  Created by Robert Herber on 2020-07-27.
//  Copyright © 2020 Robert Herber. All rights reserved.
//


import Intents
import UserNotifications

extension INImage {
  
  static func create(image: UIImage) -> INImage? {
    if let imageData = UIImage.pngData(image)() {
        return INImage(imageData: imageData);
    }
    return nil;
  }
}

//
//  MenuBadgeScene.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-09.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit

struct MenuBadgeScene
{
    static let settings = StoryboardScene<MenuSettingsViewController>(
        name: "MenuBadge",
        identifier: "MenuSettingsViewController"
    )

    static let custom = StoryboardScene<MenuCustomViewController>(
        name: "MenuBadge",
        identifier: "MenuCustomViewController"
    )
}

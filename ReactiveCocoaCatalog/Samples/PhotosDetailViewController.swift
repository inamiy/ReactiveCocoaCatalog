//
//  PhotosDetailViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import APIKit

final class PhotosDetailViewController: UIViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<PhotosDetailViewController>(name: "PhotosLike")

    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var likeButton: UIButton?

    let viewModel = PhotosLikeDetailViewModel()

    var photo: FlickrAPI.Photo? // var, because it's storyboard

    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let photo = self.photo else {
            fatalError("`FlickrAPI.Photo` is not set.")
        }

        self.titleLabel!.text = photo.title

        // Set image.
        self.imageView!.reactive.image
            <~ self.viewModel.imageProperty.producer

        // Set alpha.
        self.imageView!.reactive.alpha
            <~ self.viewModel.imageProperty.producer
                .flatMap(.merge) { _ -> SignalProducer<CGFloat, NoError> in
                    // Fade-in animation.
                    return SignalProducer(value: 1.0)
                        .animate(duration: 0.5)
                        .prefix(value: 0.0)
                }

        // Update `likeButton.title` on `like` change.
        self.likeButton!.reactive.title
            <~ PhotosLikeManager.likes[photo.imageURL].producer
                .map { $0.detailText }

        // Send change to `PhotosLikeManager` on `likeButton` tap.
        PhotosLikeManager.likes[photo.imageURL]
            <~ self.likeButton!.reactive.controlEvents(.touchUpInside)
                .withLatest(from: PhotosLikeManager.likes[photo.imageURL].producer)
                .map { $1.inverse }
    }
}

final class PhotosLikeDetailViewModel
{
    let imageProperty = MutableProperty<UIImage?>(nil)
}

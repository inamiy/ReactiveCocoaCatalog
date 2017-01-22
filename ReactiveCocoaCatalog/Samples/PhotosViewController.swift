//
//  PhotosViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa
import ReactiveObjC
import ReactiveObjCBridge
import APIKit
import Cartography

private let _cellIdentifier = "LikeCollectionViewCellIdentifier"
private let _footerIdentifier = "LikeCollectionFooterViewIdentifier"

private let _imageLoadingScheduler = QueueScheduler(name: "com.inamiy.ReactiveCocoaCatalog.Photos.ImageLoading")

///
/// Photos + Like example.
///
/// - Pagination
/// - Simple image loading
/// - Memory-persistent "Like" flags across multiple viewControllers
///
final class PhotosViewController: UICollectionViewController, StoryboardSceneProvider
{
    static let storyboardScene = StoryboardScene<PhotosViewController>(name: "PhotosLike")

    typealias ImageCache = NSCache<NSURL, UIImage>

    /// - Warning: `@IBOutlet` is not possible when it is added inside recycling view.
    /// - Todo:  What is the best practice for footer loading indicator inside UICollectionView?
    let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)

    let viewModel = PaginationViewModel(
        paginationRequest: FlickrAPI.PhotosSearchRequest(tags: ["landmark"], page: 1)
    )

    let imageCache = ImageCache()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        //
        // Change UICollectionViewCell size on frame change.
        // (This is more convenient than overriding `shouldInvalidateLayout(forBoundsChange:)`)
        //
        // NOTE: Observing `viewWillLayoutSubviews` will cause infinite loop when nothing is displayed.
        // http://stackoverflow.com/questions/29023473/uicollectionview-invalidate-layout-on-bounds-changes#comment56145257_29155201
        //
        self.view.reactive.values(forKeyPath: "frame")
            .start { [weak self] event in
                self?.collectionView?.collectionViewLayout.invalidateLayout()
            }

        let refreshButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = refreshButtonItem

        let refreshAction = Action<(), (), NoError> { _ in .init(value: ()) }
        refreshButtonItem.reactive.pressed = CocoaAction(refreshAction)

        // Send `refreshAction` values to `viewModel.refreshObserver`.
        refreshAction.values
            .observe(self.viewModel.refreshObserver)

        // Send `contentOffset` to `viewModel.loadNextObserver`.
        // NOTE: Requires KVO, not `rex_contentOffset`.
        self.collectionView!.reactive
            .values(forKeyPath: #keyPath(UICollectionView.contentOffset))
            .flatMap(.merge) { [weak self] _ -> SignalProducer<(), NoError> in
                return (self?.collectionView?._reachedBottom ?? false) ? .init(value: ()) : .empty
            }
            .start(self.viewModel.loadNextObserver)

        // Send `viewModel.loading` to `indicatorView`.
        self.indicatorView.reactive.isAnimating
            <~ self.viewModel.loading.producer

        // Call `collectionView.reloadData()` on `viewModel.items` change.
        self.viewModel.items.producer
            .startWithValues { [weak self] repositories in
                self?.collectionView?.reloadData()
            }

        // Create `detailVC` on `didSelectItemAtIndexPath()`.
        bridgedSignalProducer(from: self.rac_signal(for: Selector._didSelectRow.0, from: Selector._didSelectRow.1))
            .ignoreCastError(NoError.self)
            .startWithValues { [unowned self] racTuple in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath

                let photo: FlickrAPI.Photo = self.viewModel.items.value[indexPath.row]

                let detailVC = PhotosDetailViewController.storyboardScene.instantiate()
                detailVC.photo = photo

                // Send image to `detailVC.viewModel`.
                detailVC.viewModel.imageProperty
                    <~ _cacheOrDownloadImageProducer(url: photo.imageURL, cache: self.imageCache)
                        .map { $0.0 }

                self.show(detailVC, sender: nil)
            }

        // Workaround for non-@IBOutlet `indicatorView` to show & hide at UICollectionView-footer,
        // even though UICollectionView itself doesn't provide `tableFooterView`-like property.
        self.viewModel.loading.signal
            .observeValues { [unowned self] isOn in
                if isOn {
                    let reusableViews = self.collectionView!.subviews
                        .filter { $0 is LikeCollectionReusableView }
                        .sorted { $0.frame.origin.y > $1.frame.origin.y}

                    // if footerView is available...
                    if let reusableView = reusableViews.first {
                        reusableView.addSubview(self.indicatorView)

                        constrain(self.indicatorView) {
                            $0.centerX == $0.superview!.centerX
                            $0.centerY == $0.superview!.centerY
                        }
                    }
                    // if footerView doesn't exist yet (on launch)...
                    else {
                        self.collectionView!.addSubview(self.indicatorView)

                        constrain(self.collectionView!, self.indicatorView) {
                            $1.centerX == $0.centerX
                            $1.top == $0.topMargin
                        }
                    }
                }
                else {
                    self.indicatorView.removeFromSuperview()
                }
            }

        // Set delegate after calling `rac_signal(for: _:from:)`.
        // - https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1121
        // - http://stackoverflow.com/questions/22000433/rac-signalforselector-needs-empty-implementation
        self.collectionView!.delegate = nil   // set nil to clear selector cache
        self.collectionView!.delegate = self

        // Trigger refresh manually.
        self.viewModel.refreshObserver.send(value: ())
    }
}

// MARK: UICollectionViewDataSource

extension PhotosViewController //: UICollectionViewDataSource
{
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.viewModel.items.value.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _cellIdentifier, for: indexPath) as! LikeCollectionViewCell

        cell.alpha = 0.02   // almost invisible, clickable alpha

        let photo: FlickrAPI.Photo = self.viewModel.items.value[indexPath.row]

        let prepareForReuse = cell.reactive.prepareForReuse.take(first: 1)

        // Load image & set to `cell.imageView`.
        _cacheOrDownloadImageProducer(url: photo.imageURL, cache: self.imageCache)
            .take(until: prepareForReuse) // can interrupt downloading when out of screen
            .startWithSignal { signal, disposable in
                // Set image.
                cell.imageView!.reactive.image <~ signal.map { $0.0 }

                // Set alpha.
                cell.reactive.alpha <~ signal
                    .flatMap(.merge) { _, usesCache -> SignalProducer<CGFloat, NoError> in
                        // No animation (alpha = 1.0).
                        if usesCache {
                            return SignalProducer(value: 1.0)
                        }
                        // Fade-in animation.
                        else {
                            return SignalProducer(value: 1.0)
                                .animate(duration: 0.5)
                                .prefix(value: 0.0)
                        }
                    }
            }

        // Update `likeButton.title`.
        cell.likeButton!.reactive.title
            <~ PhotosLikeManager.likes[photo.imageURL].producer
                .map { $0.rawValue }
                .take(until: prepareForReuse)

        // Send change to `PhotosLikeManager` on `likeButton` tap.
        PhotosLikeManager.likes[photo.imageURL]
            <~ cell.likeButton!.reactive.controlEvents(.touchUpInside)
                .withLatest(from: PhotosLikeManager.likes[photo.imageURL].producer)
                .map { $1.inverse }
                .take(until: prepareForReuse)

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: _footerIdentifier, for: indexPath) as! LikeCollectionReusableView

        return reusableView
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension PhotosViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        func _preferredCellWidth(min: CGFloat, containerWidth: CGFloat) -> CGFloat
        {
            var width = containerWidth
            var i = 0
            while true {
                i += 1
                let w = containerWidth / CGFloat(i)
                guard w > min else { break }
                width = w
            }
            return width
        }

        let width = _preferredCellWidth(min: 160, containerWidth: collectionView.bounds.size.width)
        return CGSize(width: width, height: width)
    }
}

// MARK: Selectors

extension Selector
{
    // NOTE: needed to upcast to `Protocol` for some reason...
    fileprivate static let _didSelectRow: (Selector, Protocol) = (
        #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
        UICollectionViewDelegate.self
    )
}

// MARK: Subview UIs

final class LikeCollectionReusableView: UICollectionReusableView {}

final class LikeCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var likeButton: UIButton?

    override func prepareForReuse()
    {
        super.prepareForReuse()

        self.imageView?.image = nil
        for state in [UIControlState.normal, .highlighted, .selected, .disabled] {
            self.likeButton?.setTitle(nil, for: state)
        }
    }
}

// MARK: Helpers

extension UIScrollView
{
    fileprivate var _reachedBottom: Bool
    {
        let visibleHeight = frame.height - contentInset.top - contentInset.bottom
        let y = contentOffset.y + contentInset.top
        let threshold = max(0.0, contentSize.height - visibleHeight)

        return y > threshold ? true : false
    }
}

///
/// Use NSCache image or download from internet.
///
/// - Note:
/// Use non-main-scheduler only for downloading so that NSCache-loading remains synchronous
/// and UIs (especially animating UICollectionViewCell's alpha) don't get _flickered_.
///
fileprivate func _cacheOrDownloadImageProducer(url: URL, cache: PhotosViewController.ImageCache) -> SignalProducer<(UIImage?, usesCache: Bool), NoError>
{
    let cacheObjectProducer = SignalProducer<UIImage?, NoError> { [weak cache] observer, disposable in
        observer.send(value: cache?.object(forKey: url as NSURL))
        observer.sendCompleted()
    }

    return cacheObjectProducer
        .flatMap(.merge) { [unowned cache] (cachedImage: UIImage?) -> SignalProducer<(UIImage?, usesCache: Bool), NoError> in

            // If NSCache image exists, use it.
            if let cachedImage = cachedImage {
                return .init(value: (cachedImage, true))
            }
            // Otherwise, download from internet.
            else {
                return UIImage.racc_downloadImageProducer(url: url)
                    .start(on: _imageLoadingScheduler)
                    .observe(on: QueueScheduler.main)
                    .on(
                        event: logSink("downloadImage"),
                        value: { [unowned cache] image in
                            if let image = image {
                                // Set image to NSCache.
                                cache.setObject(image, forKey: url as NSURL)
                            }
                        }
                    )
                    .map { ($0, false) }
            }
        }
}

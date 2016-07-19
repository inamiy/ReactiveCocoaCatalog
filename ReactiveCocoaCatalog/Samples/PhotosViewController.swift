//
//  PhotosViewController.swift
//  ReactiveCocoaCatalog
//
//  Created by Yasuhiro Inami on 2016-04-18.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import Rex
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
final class PhotosViewController: UICollectionViewController
{
    /// - Warning: `@IBOutlet` is not possible when it is added inside recycling view.
    /// - Todo:  What is the best practice for footer loading indicator inside UICollectionView?
    let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)

    let viewModel = PaginationViewModel(
        paginationRequest: FlickrAPI.PhotosSearchRequest(tags: ["landmark"], page: 1)
    )

    let imageCache = NSCache()

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Change UICollectionViewCell size on different device orientations
        // http://stackoverflow.com/questions/13556554/change-uicollectionviewcell-size-on-different-device-orientations
        self.racc_hookSelector(#selector(viewWillLayoutSubviews))
            .startWithNext { [unowned self] in
                self.collectionView?.collectionViewLayout.invalidateLayout()
            }

        let refreshButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = refreshButtonItem

        let refreshAction = triggerAction()

        // Set CocoaAction to `refreshButtonItem`.
        refreshButtonItem.rex_action
            <~ SignalProducer(value: CocoaAction(refreshAction, input: nil))

        // Send `refreshAction` values to `viewModel.refreshObserver`.
        refreshAction.values
            .observe(self.viewModel.refreshObserver)

        // Send `contentOffset` to `viewModel.loadNextObserver`.
        // NOTE: Requires KVO, not `rex_contentOffset`.
        self.collectionView!.rex_producerForKeyPath("contentOffset")
            .flatMap(.Merge) { [weak self] (_: AnyObject) -> SignalProducer<(), NoError> in
                self?.collectionView?._reachedBottom == true ? .init(value: ()) : .empty
            }
            .start(self.viewModel.loadNextObserver)

        // Send `viewModel.loading` to `indicatorView`.
        self.indicatorView.rex_animating
            <~ self.viewModel.loading.producer

        // Call `collectionView.reloadData()` on `viewModel.items` change.
        self.viewModel.items.producer
            .startWithNext { [weak self] repositories in
                self?.collectionView?.reloadData()
            }

        // Create `detailVC` on `didSelectItemAtIndexPath()`.
        self.rac_signalForSelector(Selector._didSelectRow.0, fromProtocol: Selector._didSelectRow.1).toSignalProducer()
            .ignoreError()
            .startWithNext { [unowned self] racTuple in
                let racTuple = racTuple as! RACTuple
                let indexPath = racTuple.second as! NSIndexPath

                let photo: FlickrAPI.Photo = self.viewModel.items.value[indexPath.row]

                let detailVC = PhotosLikeScene.detail.instantiate()
                detailVC.photo = photo

                // Send image to `detailVC.viewModel`.
                detailVC.viewModel.imageProperty
                    <~ self.imageCache._cacheOrDownloadImageProducer(photo.imageURL)
                        .map { $0.0 }

                self.showViewController(detailVC, sender: nil)
            }

        // Workaround for non-@IBOutlet `indicatorView` to show & hide at UICollectionView-footer,
        // even though UICollectionView itself doesn't provide `tableFooterView`-like property.
        self.viewModel.loading.signal
            .observeNext { [unowned self] isOn in
                if isOn {
                    let reusableViews = self.collectionView!.subviews
                        .filter { $0 is LikeCollectionReusableView }
                        .sort { $0.frame.origin.y > $1.frame.origin.y}

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

        // Set delegate after calling `rac_signalForSelector(_:fromProtocol:)`.
        // - https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1121
        // - http://stackoverflow.com/questions/22000433/rac-signalforselector-needs-empty-implementation
        self.collectionView!.delegate = nil   // set nil to clear selector cache
        self.collectionView!.delegate = self

        // Trigger refresh manually.
        self.viewModel.refreshObserver.sendNext()
    }
}

// MARK: UICollectionViewDataSource

extension PhotosViewController //: UICollectionViewDataSource
{
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.viewModel.items.value.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(_cellIdentifier, forIndexPath: indexPath) as! LikeCollectionViewCell

        cell.alpha = 0.02   // almost invisible, clickable alpha

        let photo: FlickrAPI.Photo = self.viewModel.items.value[indexPath.row]

        let prepareForReuse = cell.rac_prepareForReuseSignal.toSignal()
            .triggerize()
            .take(1)

        // Load image & set to `cell.imageView`.
        self.imageCache._cacheOrDownloadImageProducer(photo.imageURL)
            .takeUntil(prepareForReuse) // can interrupt downloading when out of screen
            .startWithSignal { [unowned cell] signal, disposable in
                // Set image.
                cell.imageView!.rex_image <~ signal.map { $0.0 }

                // Set alpha.
                cell.rex_alpha <~ signal
                    .flatMap(.Merge) { _, usesCache -> SignalProducer<CGFloat, NoError> in
                        // No animation (alpha = 1.0).
                        if usesCache {
                            return SignalProducer(value: 1.0)
                        }
                        // Fade-in animation.
                        else {
                            return SignalProducer(value: 1.0)
                                .animate(duration: 0.5)
                                .beginWith(0.0)
                        }
                    }
            }

        // Update `likeButton.title`.
        cell.likeButton!.rex_title
            <~ PhotosLikeManager.likes[photo.imageURL].producer
                .map { $0.rawValue }
                .takeUntil(prepareForReuse)

        // Send change to `PhotosLikeManager` on `likeButton` tap.
        PhotosLikeManager.likes[photo.imageURL]
            <~ cell.likeButton!.rac_signalForControlEvents(.TouchUpInside).toSignalProducer()
                .triggerize()
                .sampleFrom(PhotosLikeManager.likes[photo.imageURL].producer)
                .map { $1.inverse }
                .takeUntil(prepareForReuse)

        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    {
        let reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: _footerIdentifier, forIndexPath: indexPath) as! LikeCollectionReusableView

        return reusableView
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension PhotosViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        func _preferredCellWidth(min min: CGFloat, containerWidth: CGFloat) -> CGFloat
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
    private static let _didSelectRow: (Selector, Protocol) = (
        #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAtIndexPath:)),
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
        for state in [UIControlState.Normal, .Highlighted, .Selected, .Disabled] {
            self.likeButton?.setTitle(nil, forState: state)
        }
    }
}

// MARK: Helpers

extension UIScrollView
{
    private var _reachedBottom: Bool
    {
        let visibleHeight = frame.height - contentInset.top - contentInset.bottom
        let y = contentOffset.y + contentInset.top
        let threshold = max(0.0, contentSize.height - visibleHeight)

        return y > threshold ? true : false
    }
}

extension NSCache
{
    ///
    /// Use NSCache image or download from internet.
    ///
    /// - Note:
    /// Use non-main-scheduler only for downloading so that NSCache-loading remains synchronous
    /// and UIs (especially animating UICollectionViewCell's alpha) don't get _flickered_.
    ///
    private func _cacheOrDownloadImageProducer(url: NSURL) -> SignalProducer<(UIImage?, usesCache: Bool), NoError>
    {
        return self.racc_objectProducer(key: url)
            .flatMap(.Merge) { [unowned self] (cachedImage: UIImage?) -> SignalProducer<(UIImage?, usesCache: Bool), NoError> in

                // If NSCache image exists, use it.
                if let cachedImage = cachedImage {
                    return .init(value: (cachedImage, true))
                }
                // Otherwise, download from internet.
                else {
                    return UIImage.racc_downloadImageProducer(url)
                        .startOn(_imageLoadingScheduler)
                        .observeOn(QueueScheduler.mainQueueScheduler)
                        .on(
                            event: logSink("downloadImage"),
                            next: { [unowned self] image in
                                if let image = image {
                                    // Set image to NSCache.
                                    self.setObject(image, forKey: url)
                                }
                            }
                        )
                        .map { ($0, false) }
                }
            }
    }
}

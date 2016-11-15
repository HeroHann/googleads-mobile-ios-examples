//
//  Copyright (C) 2016 Google, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Firebase
import UIKit

class TableViewController: UITableViewController, GADNativeExpressAdViewDelegate {

  // MARK: - Properties

  var tableViewItems = [AnyObject]()
  var adsToLoad = [GADNativeExpressAdView]()
  var loadStateForAds = [GADNativeExpressAdView: Bool]()
  let adUnitID = "ca-app-pub-3940256099942544/2562852117"
  // A Native Express ad is placed in the UITableView once per `adInterval`. iPads will have a
  // larger ad interval to avoid mutliple ads being on screen at the same time.
  let adInterval = UIDevice.current.userInterfaceIdiom == .pad ? 16 : 8
  // The Native Express ad height.
  let adViewHeight = CGFloat(135)

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UINib(nibName: "MenuItem", bundle: nil),
        forCellReuseIdentifier: "MenuItemViewCell")
    tableView.register(UINib(nibName: "NativeExpressAd", bundle: nil),
        forCellReuseIdentifier: "NativeExpressAdViewCell")

    // Allow row height to be determined dynamically while optimizing with an estimated row height.
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 135

    // Load the sample data.
    addMenuItems()
    addNativeExpressAds()
    preloadNextAd()
  }

  // MARK: - UITableView delegate methods

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView,
      heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let tableItem = tableViewItems[indexPath.row] as? GADNativeExpressAdView {
      let isAdLoaded = loadStateForAds[tableItem]
      return isAdLoaded == true ? adViewHeight : 0
    }
    return UITableViewAutomaticDimension
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableViewItems.count
  }

  override func tableView(_ tableView: UITableView,
      cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    if let nativeExpressAdView = tableViewItems[indexPath.row] as? GADNativeExpressAdView {
      let reusableAdCell = tableView.dequeueReusableCell(withIdentifier: "NativeExpressAdViewCell",
          for: indexPath)

      // Remove previous GADNativeExpressAdView from the content view before adding a new one.
      for subview in reusableAdCell.contentView.subviews {
        subview.removeFromSuperview()
      }

      reusableAdCell.contentView.addSubview(nativeExpressAdView)
      // Center GADNativeExpressAdView in the table cell's content view.
      nativeExpressAdView.center = reusableAdCell.contentView.center

      return reusableAdCell

    } else {

      let menuItem = tableViewItems[indexPath.row] as? MenuItem

      let reusableMenuItemCell = tableView.dequeueReusableCell(withIdentifier: "MenuItemViewCell",
          for: indexPath) as! MenuItemViewCell

      reusableMenuItemCell.nameLabel.text = menuItem?.name
      reusableMenuItemCell.descriptionLabel.text = menuItem?.description
      reusableMenuItemCell.priceLabel.text = menuItem?.price
      reusableMenuItemCell.categoryLabel.text = menuItem?.category
      reusableMenuItemCell.photoView.image = menuItem?.photo

      return reusableMenuItemCell
    }
  }

  // MARK: - GADNativeExpressAdView delegate methods

  func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
    // Mark native express ad as succesfully loaded.
    loadStateForAds[nativeExpressAdView] = true
    // Load the next ad in the adsToLoad list.
    preloadNextAd()
  }

  func nativeExpressAdView(_ nativeExpressAdView: GADNativeExpressAdView,
      didFailToReceiveAdWithError error: GADRequestError) {
    print("Failed to receive ad: \(error.localizedDescription)")
    // Load the next ad in the adsToLoad list.
    preloadNextAd()
  }

  // MARK: - UITableView source data generation

  /// Adds native express ads to the tableViewItems list.
  func addNativeExpressAds() {
    var index = adInterval
    // Ensure subview layout has been performed before accessing subview sizes.
    tableView.layoutIfNeeded()
    while index < tableViewItems.count {
      let adSize = GADAdSizeFromCGSize(
          CGSize(width: tableView.contentSize.width, height: adViewHeight))
      guard let adView = GADNativeExpressAdView(adSize: adSize) else {
        print("GADNativeExpressAdView failed to initialize at index \(index)")
        return
      }
      adView.adUnitID = adUnitID
      adView.rootViewController = self
      adView.delegate = self

      tableViewItems.insert(adView, at: index)
      adsToLoad.append(adView)
      loadStateForAds[adView] = false

      index += adInterval
    }
  }

  /// Preload native express ads sequentially. Dequeue and load next ad from `adsToLoad` list.
  func preloadNextAd() {
    if !adsToLoad.isEmpty {
      let ad = adsToLoad.removeFirst()
      ad.load(GADRequest())
    }
  }

  /// Adds MenuItems to the tableViewItems list.
  func addMenuItems() {
    var JSONObject: Any!

    guard let path = Bundle.main.url(forResource: "menuItemsJSON",
        withExtension: "json") else {
      print("Invalid filename for JSON menu item data.")
      return
    }

    do {
      let data = try Data(contentsOf: path)
      JSONObject = try JSONSerialization.jsonObject(with: data,
          options: JSONSerialization.ReadingOptions())
    } catch {
      print("Failed to load menu item JSON data: %s", error)
      return
    }

    guard let JSONObjectArray = JSONObject as? [AnyObject] else {
      print("Failed to cast JSONObject to [AnyObject]")
      return
    }

    for object in JSONObjectArray {
      guard let dict = object as? [String: AnyObject],
          let menuIem = MenuItem(dictionary: dict) else {
        print("Failed to load menu item JSON data.")
        return
      }
      tableViewItems.append(menuIem)
    }
  }
}
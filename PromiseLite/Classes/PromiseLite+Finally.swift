//
//  PromiseLite+Finally.swift
//  PromiseLite
//
//  Created by François Rouault on 01/05/2020.
//

import Foundation

extension PromiseLite {
  /// Returns a promise. This provides a way for code to be run whether the promise was fulfilled successfully or rejected once the Promise has been dealt with.
  ///
  /// A finally callback will not receive any argument, since there's no reliable means of determining if the promise was fulfilled or rejected. This use case is for precisely when you do not care about the rejection reason, or the fulfillment value, and so there's no need to provide it.
  /// - Parameter handler: A completion block that is called if the promise is settled, whether fulfilled or rejected.
  @discardableResult
  public func finally<NewValue>(_ handler: @escaping () -> PromiseLite<NewValue>) -> PromiseLite<NewValue> {
    flatMap({ value -> PromiseLite<NewValue> in handler() },
            rejection: { error -> PromiseLite<NewValue> in handler() })
  }
}

//
//  PromiseLite.swift
//  PromiseLite
//
//  Created by François Rouault on 25/04/2020.
//

/// An object that represents the eventual completion or failure of an asynchronous operation, and its resulting value.
public class PromiseLite<Value> {
  private enum State {
    case pending
    case fulfilled(Value)
  }

  private var state: State = .pending
  private lazy var completions = [((Value) -> Void)]()

  /// Creates a promise and executes the given executor.
  /// - Parameter executor: The function to be executed by the constructor, during the process of constructing the promise.
  public init(_ executor: (_ resolve: @escaping (Value) -> Void) -> Void) {
    executor(resolve)
  }

  private func resolve(value: Value) {
    state = .fulfilled(value)
    completions.forEach { $0(value) }
  }

  /// Appends a fulfillment handler to the promise.
  /// - Parameter completion: A completion block that executes once the promise fulfilled.
  public func then(_ completion: @escaping (Value) -> Void) {
    if case let State.fulfilled(value) = state {
      completion(value)
    } else {
      completions.append(completion)
    }
  }
}

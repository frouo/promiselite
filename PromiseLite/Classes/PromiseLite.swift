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
    case rejected(Error)
  }

  private let description: String?

  private var state: State = .pending
  private lazy var completions = [((Value) -> Void, (Error) -> Void)]()

  /// Creates a promise and executes the given executor.
  /// - Parameter executor: The function to be executed by the constructor, during the process of constructing the promise.
  public convenience init(_ executor: (_ resolve: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
    self.init(description: "PromiseLite<\(Value.self)>", executor: executor)
  }

  /// Creates a promise and executes the given executor.
  /// - Parameter description: An optional custom description for the promise, eg. `fetchUserProfile`. Default description for a promise is `"PromiseLite<\(Value.self)>"`, eg. `"PromiseLite<Bool>"`.
  /// - Parameter executor: The function to be executed by the constructor, during the process of constructing the promise.
  public convenience init(_ description: String, executor: (_ resolve: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
    self.init(description: description, executor: executor)
  }

  /// Creates a promise and executes the given executor.
  /// - Parameter description: An optional custom description for the promise.
  /// - Parameter executor: The function to be executed by the constructor, during the process of constructing the promise.
  internal init(description: String?, executor: (_ resolve: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
    self.description = description

    if let debugger = Configuration.debugger, let description = description {
      debugger.promise(description: description, initAt: Date())
    }

    do {
      try executor(resolve, reject)
    } catch {
      reject(error: error)
    }
  }

  private func resolve(value: Value) {
    guard case .pending = state else { return }

    state = .fulfilled(value)
    completions.forEach { $0.0(value) }
  }

  private func reject(error: Error) {
    guard case .pending = state else { return }

    state = .rejected(error)
    completions.forEach { $0.1(error) }
  }

  private func then(completion: @escaping (Value) -> Void, rejection: @escaping (Error) -> Void) {
    switch state {
    case .fulfilled(let value):
      completion(value)
    case .rejected(let error):
      rejection(error)
    default:
      completions.append((completion, rejection))
    }
  }

  /// Returns a promise.
  /// - Parameter completion: A completion block that is called if the promise fulfilled.
  @discardableResult
  public func flatMap<NewValue>(_ completion: @escaping (Value) throws -> PromiseLite<NewValue>) -> PromiseLite<NewValue> {
    flatMap(completion: completion,
            rejection: { error in PromiseLite<NewValue>.reject(error) })
  }

  /// Use `flatMap(_:)` and `flatCatch(_:)` instead.
  /// - Parameter completion: A completion block that is called if the promise fulfilled.
  /// - Parameter rejection: A completion block that is called if the promise rejected.
  @available(*, deprecated, message: "Use `flatCatch` instead to deal with rejected cases")
  @discardableResult
  public func flatMap<NewValue>(_ completion: @escaping (Value) throws -> PromiseLite<NewValue>, rejection: @escaping (Error) throws -> PromiseLite<NewValue>) -> PromiseLite<NewValue> {
    flatMap(completion: completion, rejection: rejection)
  }

  /// Returns a promise.
  /// - Parameter completion: A completion block that is called if the promise fulfilled.
  /// - Parameter rejection: A completion block that is called if the promise rejected.
  @discardableResult
  internal func flatMap<NewValue>(completion: @escaping (Value) throws -> PromiseLite<NewValue>, rejection: @escaping (Error) throws -> PromiseLite<NewValue>) -> PromiseLite<NewValue> {
    return PromiseLite<NewValue> { resolveWith, rejectWith in
      then(
        completion: { value in
          let promise: PromiseLite<NewValue>
          do {
            promise = try completion(value)
          } catch {
            promise = PromiseLite<NewValue>.reject(error)
          }
          promise.then(completion: { newValue in resolveWith(newValue) },
                       rejection: { rejectWith($0) }) },
        rejection: { error in
          let promise: PromiseLite<NewValue>
          do {
            promise = try rejection(error)
          } catch {
            promise = PromiseLite<NewValue>.reject(error)
          }
          promise.then(completion: { resolveWith($0) },
                       rejection: { rejectWith($0) })
      })
    }
  }
}

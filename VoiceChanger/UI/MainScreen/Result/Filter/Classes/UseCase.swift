//
//  UseCase.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import Foundation
import PromiseKit

public enum UseCaseTimeOutSettings {
    case defaultTimeOut
    case timeOut(timeout: TimeInterval)
    case noTimeOut
}

/// When executing a UseCase we can set what kind of UseCaseNotification we expected the UseCase to notify
public  enum UseCaseActType {
    ///UseCase execution will propagate UseCaseNotification for start,completed and errors events
    case progressAndErrors
    ///UseCase execution will propagate UseCaseNotification errors events only
    case errors
    ///UseCase execution will propagate UseCaseNotification for start and completed events
    case progress
    ///UseCase execution wont propagate any UseCaseNotification
    case none
}

open class UseCase<I, O> {
  public  typealias InputType = I
  public  typealias ReturnType = O

    public let input: InputType

    required public init(input: InputType) {
        self.input = input
        self.addDomainErrorInterceptors()
    }

    func addDomainErrorInterceptors() { }
}

public enum SyncUseCaseResult<O> {
    case success(value: O)
    case failure(error: DomainError)
}

open class SyncUseCase<I, O>: UseCase<I, O> {

   @discardableResult
   public final func act() -> SyncUseCaseResult<ReturnType> {
        let (res, err) = executeUseCase()
        if let res = res {
            return SyncUseCaseResult.success(value: res)
        } else if let err = err {
            return SyncUseCaseResult.failure(error: err)
        } else {
            return SyncUseCaseResult.failure(error: DomainError.generalWithUnknownError)
        }
    }

    func executeUseCase() -> (ReturnType?, DomainError?) {
        return customExecuteUseCase()
    }

    open func customExecuteUseCase() -> (ReturnType?, DomainError?) {
        fatalError("If should custom execute, you must override this in subclass")
    }

}

open class AsyncUseCase<I, O>: UseCase<I, O> {

    // Set the max allowed time duration and the error type that will be sent if the time limit is reached- if needed.
    fileprivate var timeoutSettings: UseCaseTimeOutSettings

    fileprivate var (promise, resolver) = Promise<ReturnType>.pending()
    fileprivate var retainCycle: AsyncUseCase<I, O>?
    fileprivate var actType = UseCaseActType.none

    public init(input: InputType, timeoutSettings: UseCaseTimeOutSettings) {
        self.timeoutSettings = timeoutSettings
        super.init(input: input)
        retainCycle = self
    }

   public required convenience init(input: InputType) {
       self.init(input: input, timeoutSettings: .defaultTimeOut)
    }

    fileprivate func applyTimeOutSettngs(_ resolver: Resolver<O>) {
        switch timeoutSettings {
        case .timeOut(timeout: let interval):
            setupTimeout(with: Int(interval), resolver: resolver)
        case .defaultTimeOut:
            setupTimeout(with: 10, resolver: resolver)
        case .noTimeOut:
            break
        }
    }

    /// Start UserCase execution without any UseCaseNotification notification about it status or errors
    ///
    /// - Returns: Promise<ReturnType>
    @discardableResult
    private final func act() -> Promise<ReturnType> {

        promise = Promise<ReturnType> { resolver in
            if let validationError = validate(input: input) {
                handleReject(seal: resolver, error: validationError)
                return
            }
            applyTimeOutSettngs(resolver)
            executeUseCase(resolver: resolver)
        }

        return promise
    }

    /// Start UserCase execution with UseCaseNotification (.useCaseStarted,.useCaseCompleted sequence or .userCaseError if any )  notifications
    ///
    /// - Returns: Promise<ReturnType>
    @discardableResult
    public func actWith(_ type: UseCaseActType) -> Promise<ReturnType> {
        actType = type
        return act()
    }

    /// Start UserCase execution with  .userCaseError notified if any error occour
    ///
    /// - Returns: Promise<ReturnType>

    final func getTimeoutSettings() -> UseCaseTimeOutSettings {
        return self.timeoutSettings
    }

    open func customExecuteUseCase(resolver: Resolver<ReturnType>) { }

    func executeUseCase(resolver: Resolver<ReturnType>) {
        customExecuteUseCase(resolver: resolver)
    }

    func validate(input: InputType) -> DomainError? {
        return nil
    }

    func setupTimeout(with seconds: Int, resolver: Resolver<O>) {
        after(DispatchTimeInterval.seconds(Int(seconds))).done { [weak self] in
            if let isPending = self?.promise.isPending, isPending {
                self?.handleTimeOut(seal: resolver)
            }
        }
    }

    public func handleFullfill(seal: Resolver<O>, result: O) {
        if promise.isPending {
            seal.fulfill(result)
            retainCycle = nil
        }
    }

    open func handleReject(seal: Resolver<O>, error: Error) {
        if promise.isPending {
            seal.reject(error)
            retainCycle = nil
        }
    }

    func handleTimeOut(seal: Resolver<O>) {
        if retainCycle != nil {
            self.handleReject(seal: seal, error: DomainError.useCaseTimeOut)
        }
    }
}

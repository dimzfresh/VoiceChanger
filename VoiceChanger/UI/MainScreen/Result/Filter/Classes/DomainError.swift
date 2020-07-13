//
//  DomainError.swift
//  VoiceChanger
//
//  Created by Dmitrii Ziablikov on 13.07.2020.
//  Copyright © 2020 Myna labs. All rights reserved.
//

import Foundation

public enum DomainError: Error {
    // General
    case generalWithError(_: Error)
    case generalWithMessage(_ : String)
    case generalWithUnknownError
    case generalWithTimeout
    case generalWithInvalidResponse
    case generalWithDoNothing

    case useCaseTimeOut
}

extension DomainError: Equatable {
  public static func == (lhs: DomainError, rhs: DomainError) -> Bool {
        switch (lhs, rhs) {
        case (.generalWithError, .generalWithError),
             (generalWithMessage, .generalWithMessage),
             (.generalWithUnknownError, .generalWithUnknownError),
             (.generalWithTimeout, .generalWithTimeout),
             (.generalWithInvalidResponse, .generalWithInvalidResponse),
             (.generalWithDoNothing, .generalWithDoNothing):
            return true
        default:
            return false
        }
    }
}

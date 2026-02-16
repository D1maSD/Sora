//
//  AuthModels.swift
//  Sora
//
//  DTO для /api/users и /api/users/authorize
//

import Foundation

// POST /api/users — request
struct CreateUserRequest: Encodable {
    let apphud_id: String
}

// POST /api/users — response
struct CreateUserResponse: Decodable {
    let id: String
    let apphud_id: String
    let tokens: Int
    let avatar_tokens: Int
}

// POST /api/users/authorize — request
struct AuthorizeRequest: Encodable {
    let user_id: String
}

// POST /api/users/authorize — response
struct AuthorizeResponse: Decodable {
    let access_token: String
    let token_type: String
}

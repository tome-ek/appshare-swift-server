//
//  BuildRepository.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 21.08.21.
//

import PromiseKit

protocol BuildRepositoryType {
    func getBuild(id: Int) -> Promise<Build>
}

struct BuildRepository: BuildRepositoryType {
    private let apiService: ApiServiceType
    
    init(apiService: ApiServiceType) {
        self.apiService = apiService
    }

    func getBuild(id: Int) -> Promise<Build> {
        let fetchPromise: Promise<Build?> = apiService.fetch("builds/\(id)")
        return fetchPromise.map {
                guard let build = $0 else {
                    throw GeneralApiError.notFound("Build")
                }
                return build
            }
    }
}
    

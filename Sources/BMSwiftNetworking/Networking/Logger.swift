//
//  Logger.swift
//
//
//  Created by Bakr mohamed on 15/01/2024.
//

import Foundation

func requestLogger(request: URLRequest) {
    print("############################## Request ##############################")
    print("📤 Will send a \(request.httpMethod ?? "") request for \(request.url?.absoluteString ?? "")\n")
    print("🏷 Headers:")
    for (headerKey, headerValue) in request.allHTTPHeaderFields ?? [:] {
        print(headerKey, ":", headerValue)
    }
    
    if let parametersString = request.prettyPrintURLParameters() {
        print("\nParameters:\(parametersString)\n")
    }
    
    if let requestBodyString = request.httpBody?.prettyPrintedDescription {
        print("\nBody:\(requestBodyString)\n")
    }
    
    print("############################## End Request ##############################\n")
}


func responseLogger(request: URLRequest, responseData: Data? = nil ,response: HTTPURLResponse? = nil, error: Error? = nil) {
    print("############################## received Response ##############################")
    if let error = error {
        print("❌ \(response?.statusCode ?? 400) \(request.httpMethod ?? "") Request for \(request.url?.absoluteString ?? "") return Error: \(error.localizedDescription)")
    }
    
    if let response = response {
        let status = (200..<300) ~= response.statusCode ? "✅" : "⚠️"
        print("\(status) Did receive response \(response.statusCode) for request \(request.url?.absoluteString ?? "")")
        if let responseDataString = responseData?.prettyPrintedJSONString {
            print("\nBody:\n",responseDataString)
        } else{
            print("\nBody: Empty or Void...")
        }
    }
    
    print("############################## End Response ##############################")

}

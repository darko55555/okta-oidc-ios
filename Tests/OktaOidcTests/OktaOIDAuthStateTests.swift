/*
* Copyright (c) 2020, Okta, Inc. and/or its affiliates. All rights reserved.
* The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
*
* You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*
* See the License for the specific language governing permissions and limitations under the License.
*/

import XCTest
@testable import OktaOidc

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class OktaOKTAuthStateTests: XCTestCase {
    var requestMock: OKTAuthorizationRequest!
    
    override func setUp() {
        super.setUp()
        
        let testUrl = URL(string: TestUtils.mockIssuer)!
        let testConfig = OKTServiceConfiguration(authorizationEndpoint: testUrl, tokenEndpoint: testUrl, issuer: testUrl)
        requestMock = OKTAuthorizationRequest(
            configuration: testConfig,
            clientId: TestUtils.mockClientId,
            clientSecret: nil,
            scopes: ["openid", "email"],
            redirectURL: testUrl,
            responseType: OKTResponseTypeCode,
            additionalParameters: nil
        )
    }
    
    func testFireRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        let authStateExpectation = expectation(description: "Get auth state completed!")
        OKTAuthState.getState(withAuthRequest: requestMock, delegate: delegateMock) { (state, error) in
            authStateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }
}

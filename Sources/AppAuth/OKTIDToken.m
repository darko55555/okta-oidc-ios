/*! @file OKTIDToken.m
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2017 Google Inc. All Rights Reserved.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
    @modifications
        Copyright (C) 2019 Okta Inc.
 */

#import "OKTIDToken.h"

/*! Field keys associated with an ID Token. */
static NSString *const kIssKey = @"iss";
static NSString *const kSubKey = @"sub";
static NSString *const kAudKey = @"aud";
static NSString *const kExpKey = @"exp";
static NSString *const kIatKey = @"iat";
static NSString *const kNonceKey = @"nonce";

#import "OKTFieldMapping.h"

@implementation OKTIDToken

- (instancetype)initWithIDTokenString:(NSString *)idToken {
  self = [super init];
  NSArray *sections = [idToken componentsSeparatedByString:@"."];
  
  // The header and claims sections are required.
  if (sections.count <= 1) {
    return nil;
  }
  
  _header = [[self class] parseJWTSection:sections[0]];
  _claims = [[self class] parseJWTSection:sections[1]];
  if (!_header || !_claims) {
    return nil;
  }

  [OKTFieldMapping remainingParametersWithMap:[[self class] fieldMap]
                                   parameters:_claims
                                     instance:self];

  // Required fields.
  if (!_issuer || !_audience || !_subject || !_expiresAt || !_issuedAt) {
    return nil;
  }

  return self;
}

/*! @brief Returns a mapping of incoming parameters to instance variables.
    @return A mapping of incoming parameters to instance variables.
 */
+ (NSDictionary<NSString *, OKTFieldMapping *> *)fieldMap {
  static NSMutableDictionary<NSString *, OKTFieldMapping *> *fieldMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fieldMap = [NSMutableDictionary dictionary];

    fieldMap[kIssKey] =
        [[OKTFieldMapping alloc] initWithName:@"_issuer"
                                         type:[NSURL class]
                                   conversion:[OKTFieldMapping URLConversion]];
    fieldMap[kSubKey] =
        [[OKTFieldMapping alloc] initWithName:@"_subject" type:[NSString class]];
    fieldMap[kAudKey] =
        [[OKTFieldMapping alloc] initWithName:@"_audience"
                                         type:[NSArray class]
                                   conversion:^id _Nullable(NSObject *_Nullable value) {
          if ([value isKindOfClass:[NSArray class]]) {
            return value;
          }
          if ([value isKindOfClass:[NSString class]]) {
            return @[value];
          }
          return nil;
        }];
    fieldMap[kExpKey] =
        [[OKTFieldMapping alloc] initWithName:@"_expiresAt"
                                         type:[NSDate class]
                                   conversion:^id _Nullable(NSObject *_Nullable value) {
          if (![value isKindOfClass:[NSNumber class]]) {
            return value;
          }
          NSNumber *valueAsNumber = (NSNumber *)value;
          return [NSDate dateWithTimeIntervalSince1970:valueAsNumber.longLongValue];
        }];
    fieldMap[kIatKey] =
        [[OKTFieldMapping alloc] initWithName:@"_issuedAt"
                                         type:[NSDate class]
                                   conversion:^id _Nullable(NSObject *_Nullable value) {
          if (![value isKindOfClass:[NSNumber class]]) {
            return value;
          }
          NSNumber *valueAsNumber = (NSNumber *)value;
          return [NSDate dateWithTimeIntervalSince1970:valueAsNumber.longLongValue];
        }];
    fieldMap[kNonceKey] =
        [[OKTFieldMapping alloc] initWithName:@"_nonce" type:[NSString class]];
  });
  return fieldMap;
}

+ (NSDictionary *)parseJWTSection:(NSString *)sectionString {
  NSData *decodedData = [[self class] base64urlNoPaddingDecode:sectionString];

  // Parses JSON.
  NSError *error;
  id object = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:&error];
  if (error) {
    NSLog(@"Error %@ parsing token payload %@", error, sectionString);
  }
  if ([object isKindOfClass:[NSDictionary class]]) {
    return (NSDictionary *)object;
  }

  return nil;
}

+ (NSData *)base64urlNoPaddingDecode:(NSString *)base64urlNoPaddingString {
    NSMutableString *body = [base64urlNoPaddingString mutableCopy];

    // Converts base64url to base64.
    NSRange range = NSMakeRange(0, base64urlNoPaddingString.length);
    [body replaceOccurrencesOfString:@"-" withString:@"+" options:NSLiteralSearch range:range];
    [body replaceOccurrencesOfString:@"_" withString:@"/" options:NSLiteralSearch range:range];

    // Converts base64 no padding to base64 with padding
    while (body.length % 4 != 0) {
      [body appendString:@"="];
    }

    // Decodes base64 string.
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:body options:0];
    return decodedData;
}

@end



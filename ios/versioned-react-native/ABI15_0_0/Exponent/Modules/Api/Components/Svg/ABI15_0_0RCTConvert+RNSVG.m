/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI15_0_0RCTConvert+RNSVG.h"

#import "ABI15_0_0RNSVGBaseBrush.h"
#import "ABI15_0_0RNSVGPattern.h"
#import "ABI15_0_0RNSVGSolidColorBrush.h"
#import <ReactABI15_0_0/ABI15_0_0RCTLog.h>
#import "ABI15_0_0RNSVGCGFCRule.h"
#import "ABI15_0_0RNSVGVBMOS.h"
#import <ReactABI15_0_0/ABI15_0_0RCTFont.h>

@implementation ABI15_0_0RCTConvert (ABI15_0_0RNSVG)

+ (CGPathRef)CGPath:(id)json
{
    NSArray *arr = [self NSNumberArray:json];
    
    NSUInteger count = [arr count];
    
#define NEXT_VALUE [self double:arr[i++]]
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 0, 0);
    
    @try {
        NSUInteger i = 0;
        while (i < count) {
            NSUInteger type = [arr[i++] unsignedIntegerValue];
            switch (type) {
                case 0:
                    CGPathMoveToPoint(path, nil, NEXT_VALUE, NEXT_VALUE);
                    break;
                case 1:
                    CGPathCloseSubpath(path);
                    break;
                case 2:
                    CGPathAddLineToPoint(path, nil, NEXT_VALUE, NEXT_VALUE);
                    break;
                case 3:
                    CGPathAddCurveToPoint(path, nil, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE);
                    break;
                case 4:
                    CGPathAddArc(path, NULL, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE, NEXT_VALUE == 0);
                    break;
                default:
                    ABI15_0_0RCTLogError(@"Invalid CGPath type %zd at element %zd of %@", type, i, arr);
                    CGPathRelease(path);
                    return nil;
            }
        }
    }
    @catch (NSException *exception) {
        ABI15_0_0RCTLogError(@"Invalid CGPath format: %@", arr);
        CGPathRelease(path);
        return nil;
    }
    
    return (CGPathRef)CFAutorelease(path);
}

ABI15_0_0RCT_ENUM_CONVERTER(CTTextAlignment, (@{
                                       @"auto": @(kCTTextAlignmentNatural),
                                       @"left": @(kCTTextAlignmentLeft),
                                       @"center": @(kCTTextAlignmentCenter),
                                       @"right": @(kCTTextAlignmentRight),
                                       @"justify": @(kCTTextAlignmentJustified),
                                       }), kCTTextAlignmentNatural, integerValue)

ABI15_0_0RCT_ENUM_CONVERTER(ABI15_0_0RNSVGCGFCRule, (@{
                                     @"evenodd": @(kABI15_0_0RNSVGCGFCRuleEvenodd),
                                     @"nonzero": @(kABI15_0_0RNSVGCGFCRuleNonzero),
                                     }), kABI15_0_0RNSVGCGFCRuleNonzero, intValue)

ABI15_0_0RCT_ENUM_CONVERTER(ABI15_0_0RNSVGVBMOS, (@{
                                  @"meet": @(kABI15_0_0RNSVGVBMOSMeet),
                                  @"slice": @(kABI15_0_0RNSVGVBMOSSlice),
                                  @"none": @(kABI15_0_0RNSVGVBMOSNone)
                                  }), kABI15_0_0RNSVGVBMOSMeet, intValue)


// This takes a tuple of text lines and a font to generate a CTLine for each text line.
// This prepares everything for rendering a frame of text in ABI15_0_0RNSVGText.
+ (ABI15_0_0RNSVGTextFrame)ABI15_0_0RNSVGTextFrame:(id)json
{
    NSDictionary *dict = [self NSDictionary:json];
    ABI15_0_0RNSVGTextFrame frame;
    frame.count = 0;
    
    NSArray *lines = [self NSArray:dict[@"lines"]];
    NSUInteger lineCount = [lines count];
    if (lineCount == 0) {
        return frame;
    }
    
    NSDictionary *fontDict = dict[@"font"];
    NSString *fontFamily = fontDict[@"fontFamily"];
    
    BOOL fontFound = NO;
    NSArray *supportedFontFamilyNames = [UIFont familyNames];

    if ([supportedFontFamilyNames containsObject:fontFamily]) {
      fontFound = YES;
    } else {
      for (NSString *fontFamilyName in supportedFontFamilyNames) {
        if ([[UIFont fontNamesForFamilyName: fontFamilyName] containsObject:fontFamily]) {
          fontFound = YES;
          break;
        }
      }
    }

    fontFamily = fontFound ? fontFamily : nil;


    CTFontRef font = (__bridge CTFontRef)[ABI15_0_0RCTFont updateFont:nil withFamily:fontFamily size:fontDict[@"fontSize"] weight:fontDict[@"fontWeight"] style:fontDict[@"fontStyle"]
                                                      variant:nil scaleMultiplier:1.0];
    if (!font) {
        return frame;
    }
    
    // Create a dictionary for this font
    CFDictionaryRef attributes = (__bridge CFDictionaryRef)@{
                                                             (NSString *)kCTFontAttributeName: (__bridge id)font,
                                                             (NSString *)kCTForegroundColorFromContextAttributeName: @YES
                                                             };
    
    // Set up text frame with font metrics
    CGFloat size = CTFontGetSize(font);
    frame.count = lineCount;
    frame.baseLine = size; // estimate base line
    frame.lineHeight = size * 1.1; // Base on ABI15_0_0RNSVG canvas line height estimate
    frame.lines = malloc(sizeof(CTLineRef) * lineCount);
    frame.widths = malloc(sizeof(CGFloat) * lineCount);
    
    [lines enumerateObjectsUsingBlock:^(NSString *text, NSUInteger i, BOOL *stop) {
        
        CFStringRef string = (__bridge CFStringRef)text;
        CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, string, attributes);
        CTLineRef line = CTLineCreateWithAttributedString(attrString);
        CFRelease(attrString);
        
        frame.lines[i] = line;
        frame.widths[i] = CTLineGetTypographicBounds(line, nil, nil, nil);
    }];
    
    return frame;
}

+ (ABI15_0_0RNSVGCGFloatArray)ABI15_0_0RNSVGCGFloatArray:(id)json
{
    NSArray *arr = [self NSNumberArray:json];
    NSUInteger count = arr.count;
    
    ABI15_0_0RNSVGCGFloatArray array;
    array.count = count;
    array.array = nil;
    
    if (count) {
        // Ideally, these arrays should already use the same memory layout.
        // In that case we shouldn't need this new malloc.
        array.array = malloc(sizeof(CGFloat) * count);
        for (NSUInteger i = 0; i < count; i++) {
            array.array[i] = [arr[i] doubleValue];
        }
    }
    
    return array;
}

+ (ABI15_0_0RNSVGBrush *)ABI15_0_0RNSVGBrush:(id)json
{
    NSArray *arr = [self NSArray:json];
    NSUInteger type = [self NSUInteger:arr.firstObject];
    
    switch (type) {
        case 0: // solid color
            // These are probably expensive allocations since it's often the same value.
            // We should memoize colors but look ups may be just as expensive.
            return [[ABI15_0_0RNSVGSolidColorBrush alloc] initWithArray:arr];
        case 1: // brush
            return [[ABI15_0_0RNSVGBaseBrush alloc] initWithArray:arr];
        default:
            ABI15_0_0RCTLogError(@"Unknown brush type: %zd", type);
            return nil;
    }
}

+ (NSArray *)ABI15_0_0RNSVGBezier:(id)json
{
    NSArray *arr = [self NSNumberArray:json];
    
    NSMutableArray<NSArray *> *beziers = [[NSMutableArray alloc] init];
    
    NSUInteger count = [arr count];
    
#define NEXT_VALUE [self double:arr[i++]]
    @try {
        NSValue *startPoint = [NSValue valueWithCGPoint: CGPointMake(0, 0)];
        NSUInteger i = 0;
        while (i < count) {
            NSUInteger type = [arr[i++] unsignedIntegerValue];
            switch (type) {
                case 0:
                {
                    startPoint = [NSValue valueWithCGPoint: CGPointMake(NEXT_VALUE, NEXT_VALUE)];
                    [beziers addObject: @[startPoint]];
                    break;
                }
                case 1:
                    [beziers addObject: @[]];
                    break;
                case 2:
                {
                    double x = NEXT_VALUE;
                    double y = NEXT_VALUE;
                    NSValue * destination = [NSValue valueWithCGPoint:CGPointMake(x, y)];
                    [beziers addObject: @[
                                          destination,
                                          startPoint,
                                          destination
                                          ]];
                    break;
                }
                case 3:
                    [beziers addObject: @[
                                          [NSValue valueWithCGPoint:CGPointMake(NEXT_VALUE, NEXT_VALUE)],
                                          [NSValue valueWithCGPoint:CGPointMake(NEXT_VALUE, NEXT_VALUE)],
                                          [NSValue valueWithCGPoint:CGPointMake(NEXT_VALUE, NEXT_VALUE)],
                                          ]];
                    break;
                default:
                    ABI15_0_0RCTLogError(@"Invalid ABI15_0_0RNSVGBezier type %zd at element %zd of %@", type, i, arr);
                    return nil;
            }
        }
    }
    @catch (NSException *exception) {
        ABI15_0_0RCTLogError(@"Invalid ABI15_0_0RNSVGBezier format: %@", arr);
        return nil;
    }
    
    return beziers;
}

+ (CGRect)CGRect:(id)json offset:(NSUInteger)offset
{
    NSArray *arr = [self NSArray:json];
    if (arr.count < offset + 4) {
        ABI15_0_0RCTLogError(@"Too few elements in array (expected at least %zd): %@", 4 + offset, arr);
        return CGRectZero;
    }
    return (CGRect){
        {[self CGFloat:arr[offset]], [self CGFloat:arr[offset + 1]]},
        {[self CGFloat:arr[offset + 2]], [self CGFloat:arr[offset + 3]]},
    };
}

+ (CGColorRef)CGColor:(id)json offset:(NSUInteger)offset
{
    NSArray *arr = [self NSArray:json];
    if (arr.count < offset + 4) {
        ABI15_0_0RCTLogError(@"Too few elements in array (expected at least %zd): %@", 4 + offset, arr);
        return nil;
    }
    return [self CGColor:[arr subarrayWithRange:(NSRange){offset, 4}]];
}

+ (CGGradientRef)CGGradient:(id)json offset:(NSUInteger)offset
{
    NSArray *arr = [self NSArray:json];
    if (arr.count < offset) {
        ABI15_0_0RCTLogError(@"Too few elements in array (expected at least %zd): %@", offset, arr);
        return nil;
    }
    arr = [arr subarrayWithRange:(NSRange){offset, arr.count - offset}];
    ABI15_0_0RNSVGCGFloatArray colorsAndOffsets = [self ABI15_0_0RNSVGCGFloatArray:arr];
    size_t stops = colorsAndOffsets.count / 5;
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(
                                                                 rgb,
                                                                 colorsAndOffsets.array,
                                                                 colorsAndOffsets.array + stops * 4,
                                                                 stops
                                                                 );
    
    
    CGColorSpaceRelease(rgb);
    free(colorsAndOffsets.array);
    return (CGGradientRef)CFAutorelease(gradient);
}

@end

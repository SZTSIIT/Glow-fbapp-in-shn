#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

static NSString * const kShanFontName = @"Pyidaungsu";

// 1. Detect Shan Unicode Range (U+1000 to U+109F)
static BOOL containsShanText(NSString *string) {
    if (!string || string.length == 0) return NO;
    for (NSUInteger i = 0; i < string.length; i++) {
        unichar character = [string characterAtIndex:i];
        if (character >= 0x1000 && character <= 0x109F) {
            return YES;
        }
    }
    return NO;
}

// 2. Protect Icon Glyphs (Private Use Area U+E000 - U+F8FF)
static BOOL containsPrivateIconGlyphs(NSString *string) {
    if (!string || string.length == 0) return NO;
    for (NSUInteger i = 0; i < string.length; i++) {
        unichar character = [string characterAtIndex:i];
        if ((character >= 0xE000 && character <= 0xF8FF) || character == 0xFFFD) {
            return YES;
        }
    }
    return NO;
}

// 3. Dynamic UI Hooking for Standard Text Views
%hook UILabel

- (void)setText:(NSString *)text {
    %orig(text);
    if (text && containsShanText(text) && !containsPrivateIconGlyphs(text)) {
        UIFont *customFont = [UIFont fontWithName:kShanFontName size:self.font.pointSize];
        if (customFont) {
            self.font = customFont;
            self.clipsToBounds = NO; // Prevents clipping on Shan tone marks
        }
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (attributedText && containsShanText(attributedText.string) && !containsPrivateIconGlyphs(attributedText.string)) {
        NSMutableAttributedString *mutableAttributed = [attributedText mutableCopy];
        [mutableAttributed enumerateAttribute:NSFontAttributeName 
                                      inRange:NSMakeRange(0, mutableAttributed.length) 
                                      options:0 
                                   usingBlock:^(id value, NSRange range, BOOL *stop) {
            if ([value isKindOfClass:[UIFont class]]) {
                UIFont *existingFont = (UIFont *)value;
                UIFont *customFont = [UIFont fontWithName:kShanFontName size:existingFont.pointSize];
                if (customFont) {
                    [mutableAttributed removeAttribute:NSFontAttributeName range:range];
                    [mutableAttributed addAttribute:NSFontAttributeName value:customFont range:range];
                }
            }
        }];
        %orig(mutableAttributed);
        return;
    }
    %orig(attributedText);
}

%end

// 4. Register Pyidaungsu into CoreText Font Manager at App Startup
%ctor {
    @autoreleasepool {
        NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Pyidaungsu" ofType:@"ttf"];
        if (fontPath) {
            CFURLRef fontURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fontPath, kCFURLPOSIXPathStyle, false);
            CGDataProviderRef provider = CGDataProviderCreateWithURL(fontURL);
            CGFontRef font = CGFontCreateWithDataProvider(provider);
            
            if (font) {
                CFErrorRef error = NULL;
                if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
                    if (error) CFRelease(error);
                }
                CGFontRelease(font);
            }
            if (provider) CGDataProviderRelease(provider);
            if (fontURL) CFRelease(fontURL);
        }
    }
}

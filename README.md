# FontFamily

<p align="left">
<img src="https://img.shields.io/github/v/tag/F8nUI/font-family?label=Version&color=yellow">
<img src="https://img.shields.io/badge/iOS-15+-orange.svg">
<img src="https://img.shields.io/badge/macOS-12+-orange.svg">
<img src="https://img.shields.io/badge/Licence-MIT-green">
</p>

Quick way to add custom fonts to your Xcode project or SPM package

## Quick Start

### Add font files and set correct "Target Membership" for them

### Declare Custom Font by creating enum conforming to `FontFamily` protocol:
``` swift
public enum CustomFont: FontFamily {
	case light
	case regular
	case bold

	public static let `default`: CustomFont = .regular
	public static let fileExtension: FontFileExtension = .otf
	// Set correct bundle name where the font assets are located.
	// It's usually `.main` when using in Xcode Project and `.module` when using in SPM Package
	public static let bundle: Bundle = .main

	// Should reflect a font file name – "CustonFont-Regular.otf"
	public var name: String {
		switch self {
		case .light: 	"CustomFont-Light"
		case .regular: 	"CustomFont-Regular"
		case .bold: 	"CustomFont-Bold"
		}
	}

	// Map declared font weights to their corresponding system equivalents
	public func resolve() -> Font.Weight {
		switch self {
		case .thin: .thin
		case .regular: .regular
		case .bold: .bold
		}
	}
}

public extension FontFamily.Font<CustomFont> {
	static let customFont = Self()
}
```

### Use in SwiftUI:

``` swift
extension Font {
	static let customBody = Font.fontFamily(.customFont, size: 14, weight: .light, scaling: .textStyle(.body))
}

Text("Hello World!")
	.font(.customBody)
```

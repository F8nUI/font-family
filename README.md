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

### Declare Custom Font by creating "Font Weight" enum conforming to `FontFamilyWeight`:
``` swift
public enum CustomFontWeight: FontFamilyWeight {
	case light
	case regular
	case bold

	public static var defaultWeight: CustomFontWeight = .regular
	public static var fileExtension: FontFileExtension = .otf

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

	// Set correct bundle name where the font assets are located.
	// It's usually `.main` when using in Xcode Project and `.module` when using in SPM Package
	public static var bundle: Bundle { .module }
}

public extension FontFamily<CustomFontWeight> {
	static let customFont = Self()
}
```

### Use them

``` swift
Text("Hello World!")
	.font(.fontFamily(.customFont, size: 14, weight: .light, scaling: .textStyle(.body)))

```

import SwiftUI
import OSLog

public struct FontFamilyFont<Weight: FontFamily>: Sendable, Hashable, Equatable {
	public init() {}
	
	@MainActor
	let isRegistered: Bool = {
		Self.register()
	}()
	
	public func callAsFunction(size: CGFloat, weight: Weight = .default, scaling: FontFamilyScaling = .textStyle(.body)) -> SwiftUI.Font {
		resolve(size: size, weight: weight, scaling: scaling)
	}
}

// MARK: - Register Font

private extension FontFamilyFont {
	static func register() -> Bool {
		Weight.allCases
			.compactMap { $0.url }
			.forEach {
				registerFont($0)
				Logger(subsystem: "FoundationUI", category: "FontFamily").info("registered font: \($0.lastPathComponent)")
			}
		return true
	}
	
	static func registerFont(_ fontUrl: URL) {
		if isFontRegistered(at: fontUrl) { return }
		
		var error: Unmanaged<CFError>?
		let success = CTFontManagerRegisterFontsForURL(fontUrl as CFURL, .none, &error)
		
		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			return
		}
		if !success {
			let errorDescription = (error?.takeRetainedValue() as? NSError)?.localizedDescription
			let message = ["Failed to register font.", errorDescription]
				.compactMap({ $0 })
				.joined(separator: "\n")
			
			Logger(subsystem: "FoundationUI", category: "FontFamily").error("\(message)")
		}
	}
	
	static func isFontRegistered(at fontUrl: URL) -> Bool {
		guard let fontDataProvider = CGDataProvider(url: fontUrl as CFURL),
			  let font = CGFont(fontDataProvider),
			  let fontName = font.postScriptName as String?
		else {
			return false
		}
		
		let names = CTFontManagerCopyAvailablePostScriptNames()
		
		if let names = names as? [String], names.contains(fontName) {
			return true
		}
		
		return false
	}
}

// MARK: - Resolve Font as (Font, NSFont, UIFont)

public extension FontFamilyFont {
	func resolve(size: CGFloat, weight: Weight = .default, scaling: FontFamilyScaling = .textStyle(.body)) -> SwiftUI.Font {
		switch scaling {
		case .fixed:
			.custom(Weight.default.name, fixedSize: size).weight(weight.resolve())
		case .textStyle(let textStyle):
			.custom(Weight.default.name, size: size, relativeTo: textStyle).weight(weight.resolve())
		}
	}
}

#if os(iOS)
public extension FontFamilyFont {
	func resolve(size: CGFloat, weight: Weight = .default, scaling: FontFamilyScaling = .textStyle(.body)) -> UIFont {
		var font: UIFont
		if weight is SystemFontFamily {
			font = .systemFont(ofSize: size, weight: weight.resolve())
		} else {
			font = .init(name: weight.name, size: size) ?? .systemFont(ofSize: size, weight: weight.resolve())
		}
		switch scaling {
		case .fixed:
			break
		case .textStyle(let style):
			font = UIFontMetrics(forTextStyle: style.uiFontTextStyle).scaledFont(for: font)
		}
		
		return font
	}
}
#endif

#if os(macOS)
public extension FontFamilyFont {
	func resolve(size: CGFloat, weight: Weight = .default, scaling: FontFamilyScaling = .textStyle(.body)) -> NSFont {
		var font: NSFont
		if weight is SystemFontFamily {
			font = .systemFont(ofSize: size, weight: weight.resolve())
		} else {
			font = .init(name: weight.name, size: size) ?? .systemFont(ofSize: size, weight: weight.resolve())
		}
		
		// Scaling is not used on macOS
		
		return font
	}
}
#endif

// MARK: - FontFamilyWeight

/// Add font files and set correct "Target Membership" for them
///
/// Declare custom font:
/// ``` swift
/// public enum CustomFont: FontFamily {
/// 	case thin
/// 	case regular
/// 	case bold
///
/// 	public static let `default`: CustomFont = .regular
/// 	public static let fileExtension: FontFileExtension = .otf
/// 	public static let bundle: Bundle = .main
///
/// 	// Should reflect file name – "CustonFont-Regular.otf"
/// 	public var name: String {
/// 		switch self {
/// 		case .thin: "CustomFont-Light"
/// 		case .regular: "CustomFont-Regular"
/// 		case .bold: "CustomFont-Bold"
/// 		}
/// 	}
///
/// 	// Map to system's weight
/// 	public func resolve() -> Font.Weight {
/// 		switch self {
/// 		case .thin: .thin
/// 		case .regular: .regular
/// 		case .bold: .bold
/// 		}
/// 	}
/// }
///
/// public extension FontFamily.Font<CustomFont> {
/// 	static let custom = Self()
/// }
///
/// ```
///
/// Use:
///	``` swift
/// extension Font {
///		static let customBody = Font.fontFamily(.customFont, size: 14, weight: .light, scaling: .textStyle(.body))
/// }
///
///	Text("Hello World!")
///		.font(.customBody)
/// ```
public protocol FontFamily: CaseIterable, Sendable, Hashable, Equatable {
	var name: String { get }
	var url: URL? { get }
	func resolve() -> SwiftUI.Font.Weight
	
	/// Set correct bundle name where the font assets are located.
	/// It's usually `.main` when using in Xcode Project and `.module` when using in SPM Package
	static var bundle: Bundle { get }
	static var `default`: Self { get }
	static var fileExtension: FontFileExtension { get }
}

public extension FontFamily {
	typealias Font = FontFamilyFont
}

public enum FontFileExtension: String, Sendable {
	case otf = "otf"
	case ttf = "ttf"
}

public extension FontFamily {
	static var fileExtension: FontFileExtension { .otf }
	var url: URL? {
		return Self.bundle.url(forResource: name, withExtension: Self.fileExtension.rawValue)
	}
}

#if os(macOS)
public extension FontFamily {
	func resolve() -> NSFont.Weight {
		resolve().nsFontWeight()
	}
}

public extension Font.Weight {
	func nsFontWeight() -> NSFont.Weight {
		switch self {
		case .ultraLight: .ultraLight
		case .light: .light
		case .thin: .thin
		case .regular: .regular
		case .medium: .medium
		case .semibold: .semibold
		case .bold: .bold
		case .heavy: .heavy
		case .black: .black
		default: .regular
		}
	}
}

public extension Font.TextStyle {
	func nsTextStyle() -> NSFont.TextStyle {
		switch self {
		case .body: .body
		case .callout: .callout
		case .caption: .caption1
		case .caption2: .caption2
		case .footnote: .footnote
		case .headline: .headline
		case .largeTitle: .largeTitle
		case .subheadline: .subheadline
		case .title: .title1
		case .title2: .title2
		case .title3: .title3
		default: .body
		}
	}
}
#endif

#if os(iOS)
extension FontFamily {
	func resolve() -> UIFont.Weight {
		resolve().uiFontWeight()
	}
}

extension Font.Weight {
	func uiFontWeight() -> UIFont.Weight {
		switch self {
		case .ultraLight: .ultraLight
		case .light: .light
		case .thin: .thin
		case .regular: .regular
		case .medium: .medium
		case .semibold: .semibold
		case .bold: .bold
		case .heavy: .heavy
		case .black: .black
		default: .regular
		}
	}
}

extension Font.TextStyle {
	func uiTextStyle() -> UIFont.TextStyle {
		switch self {
		case .body: .body
		case .callout: .callout
		case .caption: .caption1
		case .caption2: .caption2
		case .footnote: .footnote
		case .headline: .headline
		case .largeTitle: .largeTitle
		case .subheadline: .subheadline
		case .title: .title1
		case .title2: .title2
		case .title3: .title3
		default: .body
		}
	}
}
#endif

// MARK: - System Font Family

public enum SystemFontFamily: String, FontFamily {
	case thin
	case ultraLight
	case light
	case regular
	case medium
	case semibold
	case bold
	case heavy
	case black
	
	public var name: String { ".AppleSystemUIFont" }
	public var url: URL? { nil }

	public static let `default`: SystemFontFamily = .regular
	public static let bundle: Bundle = .main
	
	public func resolve() -> Font.Weight {
		switch self {
		case .thin: .thin
		case .ultraLight: .ultraLight
		case .light: .light
		case .regular: .regular
		case .medium: .medium
		case .semibold: .semibold
		case .bold: .bold
		case .heavy: .heavy
		case .black: .black
		}
	}
}

public extension FontFamily.Font<SystemFontFamily> {
	static let system = Self()
}

// MARK: - SwiftUI.Font Extension

public enum FontFamilyScaling: Sendable, Hashable, Equatable {
	case fixed
	case textStyle(Font.TextStyle)
}

extension Font.TextStyle {
	#if os(iOS)
	typealias PlatformTextStyle = UIFont.TextStyle
	#elseif os(macOS)
	typealias PlatformTextStyle = NSFont.TextStyle
	#endif
	var uiFontTextStyle: PlatformTextStyle {
		switch self {
		case .body: .body
		case .callout: .callout
		case .caption: .caption1
		case .caption2: .caption2
		case .footnote: .footnote
		case .headline: .headline
		case .largeTitle: .largeTitle
		case .subheadline: .subheadline
		case .title: .title1
		case .title2: .title2
		case .title3: .title3
		@unknown default: .body
		}
	}
}

extension Font {
	public static func fontFamily<Weight: FontFamily>(_ font: FontFamilyFont<Weight>, size: CGFloat, weight: Weight, scaling: FontFamilyScaling = .textStyle(.body)) -> Self {
		font.resolve(size: size, weight: weight, scaling: scaling)
	}
}

#if os(macOS)
extension NSFont {
	public static func fontFamily<Weight: FontFamily>(_ font: FontFamilyFont<Weight>, size: CGFloat, weight: Weight, scaling: FontFamilyScaling = .textStyle(.body)) -> NSFont {
		font.resolve(size: size, weight: weight, scaling: scaling)
	}
}
#endif

#if os(iOS)
extension UIFont {
	public static func fontFamily<Weight: FontFamily>(_ font: FontFamilyFont<Weight>, size: CGFloat, weight: Weight, scaling: FontFamilyScaling = .textStyle(.body)) -> UIFont {
		font.resolve(size: size, weight: weight, scaling: scaling)
	}
}
#endif


#Preview {
	HStack {
		VStack {
			Text("Scalable")
				.dynamicTypeSize(.small)
			Text("Scalable")
				.dynamicTypeSize(.large)
			Text("Scalable")
				.dynamicTypeSize(.accessibility1)
		}
		.font(.body.weight(.bold))
		#if os(iOS)
		let uiFont = UIFont.fontFamily(.system, size: 17, weight: .bold, scaling: .textStyle(.body))
		VStack {
			Text("Scalable")
				.dynamicTypeSize(.small)
			Text("Scalable")
				.dynamicTypeSize(.large)
			Text("Scalable")
				.dynamicTypeSize(.accessibility1)
		}
		// UIFont is not "scalable" in SwiftUI environment
		.font(.init(uiFont))
		#endif
		VStack {
			Text("Scalable")
				.dynamicTypeSize(.small)
			Text("Scalable")
				.dynamicTypeSize(.large)
			Text("Scalable")
				.dynamicTypeSize(.accessibility1)
		}
		.font(.fontFamily(.system, size: 17, weight: .bold, scaling: .textStyle(.body)))
	}
	.frame(minWidth: 200, minHeight: 200)
}

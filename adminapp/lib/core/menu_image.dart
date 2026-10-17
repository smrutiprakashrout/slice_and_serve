import 'constants.dart';

/// Resolves a menu item's image to an absolute URL served by the web app.
///
/// The placeholder path is intentionally treated as missing because the site
/// does not publish that file.
String? resolveMenuImageUrl(
  String? image, {
  String baseUrl = AppConstants.prodApiBaseUrl,
}) {
  if (image == null) return null;

  final trimmedImage = image.trim();
  if (trimmedImage.isEmpty) return null;

  final pathWithoutLeadingSlash = trimmedImage.replaceFirst(RegExp(r'^/+'), '');
  if (pathWithoutLeadingSlash.toLowerCase() == 'images/placeholder.jpg') {
    return null;
  }

  final parsedImage = Uri.tryParse(trimmedImage);
  if (parsedImage != null &&
      parsedImage.hasAuthority &&
      (parsedImage.scheme == 'http' || parsedImage.scheme == 'https')) {
    return trimmedImage;
  }

  final base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final encodedPath = pathWithoutLeadingSlash
      .split('/')
      .map(_encodePathSegment)
      .join('/');
  final baseUri = Uri.parse('$base/');

  return baseUri.resolveUri(Uri.parse(encodedPath)).toString();
}

String _encodePathSegment(String segment) {
  try {
    // Decoding before encoding preserves existing escapes such as %20.
    return Uri.encodeComponent(Uri.decodeComponent(segment));
  } on FormatException {
    // An invalid percent escape is treated as a literal percent character.
    return Uri.encodeComponent(segment);
  }
}

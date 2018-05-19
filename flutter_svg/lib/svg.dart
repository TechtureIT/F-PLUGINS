import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, AssetBundle;
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart' hide parse;
import 'package:xml/xml.dart' as xml show parse;

import 'src/svg/xml_parsers.dart';
import 'src/svg_parser.dart';
import 'src/vector_painter.dart';
import 'vector_drawable.dart';

/// Extends [VectorDrawableImage] to parse SVG data to [Drawable].
class SvgImage extends VectorDrawableImage {
  const SvgImage._(Future<DrawableRoot> future, Size size,
      {bool clipToViewBox, Key key, PaintLocation paintLocation})
      : super(future, size,
            clipToViewBox: clipToViewBox,
            key: key,
            paintLocation: paintLocation);

  factory SvgImage.fromString(String svg, Size size,
      {Key key,
      bool clipToViewBox = true,
      PaintLocation paintLocation = PaintLocation.Background}) {
    return new SvgImage._(
      new Future<DrawableRoot>.value(fromSvgString(svg, size)),
      size,
      clipToViewBox: clipToViewBox,
      key: key,
      paintLocation: paintLocation,
    );
  }

  factory SvgImage.asset(String assetName, Size size,
      {Key key,
      AssetBundle bundle,
      String package,
      bool clipToViewBox = true,
      PaintLocation paintLocation = PaintLocation.Background}) {
    return new SvgImage._(
      loadAsset(assetName, size, bundle: bundle, package: package),
      size,
      clipToViewBox: clipToViewBox,
      key: key,
      paintLocation: paintLocation,
    );
  }

  factory SvgImage.network(String uri, Size size,
      {Map<String, String> headers,
      Key key,
      bool clipToViewBox = true,
      PaintLocation paintLocation = PaintLocation.Background}) {
    return new SvgImage._(
      loadNetworkAsset(uri, size),
      size,
      clipToViewBox: clipToViewBox,
      key: key,
      paintLocation: paintLocation,
    );
  }
}

/// Creates a [DrawableRoot] from a string of SVG data.
DrawableRoot fromSvgString(String rawSvg, Size size) {
  final XmlElement svg = xml.parse(rawSvg).rootElement;
  final Rect viewBox = parseViewBox(svg);
  final Map<String, PaintServer> paintServers = <String, PaintServer>{};
  final DrawableStyle style = parseStyle(svg, paintServers, viewBox);

  final List<Drawable> children = svg.children
      .where((XmlNode child) => child is XmlElement)
      .map(
        (XmlNode child) => parseSvgElement(
              child,
              paintServers,
              new Rect.fromPoints(
                Offset.zero,
                new Offset(size.width, size.height),
              ),
              style,
            ),
      )
      .toList();
  return new DrawableRoot(
    viewBox,
    children,
    paintServers,
    parseStyle(svg, paintServers, viewBox),
  );
}

/// Creates a [DrawableRoot] from a bundled asset.
Future<DrawableRoot> loadAsset(String assetName, Size size,
    {AssetBundle bundle, String package}) async {
  bundle ??= rootBundle;
  final String rawSvg = await bundle.loadString(
    package == null ? assetName : 'packages/$package/$assetName',
  );
  return fromSvgString(rawSvg, size);
}

final HttpClient _httpClient = new HttpClient();

/// Creates a [DrawableRoot] from a network asset with an HTTP get request.
Future<DrawableRoot> loadNetworkAsset(String url, Size size) async {
  final Uri uri = Uri.base.resolve(url);
  final HttpClientRequest request = await _httpClient.getUrl(uri);
  final HttpClientResponse response = await request.close();
  if (response.statusCode != HttpStatus.OK)
    throw new HttpException('Could not get network SVG asset', uri: uri);
  final String rawSvg = await _consolidateHttpClientResponse(response);
  return fromSvgString(rawSvg, size);
}

Future<String> _consolidateHttpClientResponse(
    HttpClientResponse response) async {
  final Completer<String> completer = new Completer<String>.sync();
  final StringBuffer buffer = new StringBuffer();

  response.transform(utf8.decoder).listen((String chunk) {
    buffer.write(chunk);
  }, onDone: () {
    completer.complete(buffer.toString());
  }, onError: completer.completeError, cancelOnError: true);

  return completer.future;
}

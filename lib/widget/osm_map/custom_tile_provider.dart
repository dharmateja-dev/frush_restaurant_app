import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

class CustomTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
      TileCoordinates coordinates, TileLayer tileLayer) {
    final url = _getTileUrl(coordinates, tileLayer);
    return _NetworkTileWithUserAgent(url);
  }

  String _getTileUrl(TileCoordinates coords, TileLayer tileLayer) {
    String url = tileLayer.urlTemplate!
        .replaceAll('{s}', _pickSubdomain(coords, tileLayer))
        .replaceAll('{z}', coords.z.toString())
        .replaceAll('{x}', coords.x.toString())
        .replaceAll('{y}', coords.y.toString());
    return url;
  }

  String _pickSubdomain(TileCoordinates coords, TileLayer tileLayer) {
    final subdomains = tileLayer.subdomains;
    if (subdomains.isEmpty) return '';
    final index = (coords.x + coords.y) % subdomains.length;
    return subdomains[index];
  }
}

class _NetworkTileWithUserAgent
    extends ImageProvider<_NetworkTileWithUserAgent> {
  final String url;

  _NetworkTileWithUserAgent(this.url);

  @override
  Future<_NetworkTileWithUserAgent> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<_NetworkTileWithUserAgent>(this);
  }

  @override
  ImageStreamCompleter load(
      _NetworkTileWithUserAgent key, DecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(
      _NetworkTileWithUserAgent key, DecoderCallback decode) async {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'YourAppName/1.0 (you@example.com)',
    });

    if (response.statusCode != 200) {
      throw Exception('Tile request failed: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final ui.Image image = await decode(bytes);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      other is _NetworkTileWithUserAgent && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

class DecoderCallback {
  final Future<ui.Image> Function(Uint8List bytes) decode;

  DecoderCallback(this.decode);

  Future<ui.Image> call(Uint8List bytes) {
    return decode(bytes);
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/

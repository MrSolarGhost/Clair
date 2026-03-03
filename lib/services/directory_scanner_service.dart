import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/discovered_game.dart';

/// Scans directories for game files and parses them into DiscoveredGame objects
class DirectoryScannerService {
  /// Supported game file extensions
  static const supportedExtensions = {
    // PlayStation Vita
    'vpk',
    // Nintendo 3DS
    'cia', '3ds', '3dsx',
    // Nintendo Switch
    'nsp', 'xci',
    // Disc images
    'iso', 'cue', 'bin', 'mds', 'mdf',
    // Executables
    'exe', 'elf', 'dol',
    // Cartridge ROMs
    'rom', 'z64', 'n64', 'gba', 'nds', 'gb', 'gbc',
  };

  /// Scan a directory for game files
  Future<List<DiscoveredGame>> scanDirectory(
    String directoryPath,
    String system,
    bool recursive,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $directoryPath');
    }

    final files = <FileSystemEntity>[];
    
    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && isGameFile(entity.path)) {
          files.add(entity);
        }
      }
    } else {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File && isGameFile(entity.path)) {
          files.add(entity);
        }
      }
    }

    return files.map((file) {
      final filename = path.basename(file.path);
      return DiscoveredGame(
        title: parseTitle(filename),
        executablePath: file.path,
        system: system,
      );
    }).toList();
  }

  /// Check if file has a supported game extension
  @visibleForTesting
  bool isGameFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (ext.isEmpty) return false;
    final extWithoutDot = ext.substring(1); // Remove leading dot
    return supportedExtensions.contains(extWithoutDot);
  }

  /// Parse filename into readable game title
  String parseTitle(String filename) {
    // Remove extension
    final nameWithoutExt = path.basenameWithoutExtension(filename);
    
    // Replace dashes, underscores, dots with spaces
    final cleaned = nameWithoutExt
        .replaceAll(RegExp(r'[-_.]'), ' ')
        .trim();
    
    // Title case each word
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  
  @override
  String toString() => message;
}

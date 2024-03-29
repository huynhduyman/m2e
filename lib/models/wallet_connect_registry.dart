// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_connect_registry.g.dart';

///
/// WalletConnect Listing from Registry API Documentation available here:
/// https://docs.walletconnect.com/2.0/api/registry-api
///
/// To rebuild JSON annotation run
/// flutter pub run build_runner build --delete-conflicting-outputs

@JsonSerializable(includeIfNull: false)
class WcRegImageUrl {
  String sm;
  String md;
  String lg;

  WcRegImageUrl({this.sm = '', this.md = '', this.lg = ''});

  factory WcRegImageUrl.fromJson(Map<String, dynamic> json) => _$WcRegImageUrlFromJson(json);

  Map<String, dynamic> toJson() => _$WcRegImageUrlToJson(this);
}

@JsonSerializable()
class WcRegApp {
  String browser;
  String ios;
  String android;
  String mac;
  String windows;
  String linux;

  WcRegApp({
    this.browser = '',
    this.ios = '',
    this.android = '',
    this.mac = '',
    this.windows = '',
    this.linux = '',
  });

  factory WcRegApp.fromJson(Map<String, dynamic> json) => _$WcRegAppFromJson(json);

  Map<String, dynamic> toJson() => _$WcRegAppToJson(this);
}

@JsonSerializable()
class WcRegDesktop {
  String native;
  String universal;

  WcRegDesktop({this.native = '', this.universal = ''});

  factory WcRegDesktop.fromJson(Map<String, dynamic> json) => _$WcRegDesktopFromJson(json);

  Map<String, dynamic> toJson() => _$WcRegDesktopToJson(this);
}

@JsonSerializable()
class WcRegMobile {
  String native;
  String universal;

  WcRegMobile({this.native = '', this.universal = ''});

  factory WcRegMobile.fromJson(Map<String, dynamic> json) => _$WcRegMobileFromJson(json);

  Map<String, dynamic> toJson() => _$WcRegMobileToJson(this);
}

@JsonSerializable()
class WcRegMetadata {
  String shortName;
  Map<String, dynamic> colors;

  // WcRegMetadata({this.shortName = '', this.colors = const {}});

  WcRegMetadata({
    this.shortName = '',
    this.colors = const {},
  });

  factory WcRegMetadata.fromJson(Map<String, dynamic> json) => _$WcRegMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$WcRegMetadataToJson(this);
}

/// Provides all the information available in the WalletConnect Registry Listing
@JsonSerializable(includeIfNull: false)
class WalletConnectRegistryListing {
  String id;
  String name;
  String description;
  String? homepage;
  List<String>? chains;
  List<String>? versions;
  String app_type;
  String image_id;
  late WcRegImageUrl image_url;
  late WcRegApp app;
  late WcRegMobile mobile;
  late WcRegDesktop desktop;
  late WcRegMetadata metadata;

  WalletConnectRegistryListing({
    this.id = '',
    this.name = '',
    this.description = '',
    this.homepage = '',
    this.chains = const [],
    this.versions = const [],
    this.app_type = '',
    this.image_id = '',
    WcRegImageUrl? image_url,
    WcRegApp? app,
    WcRegMobile? mobile,
    WcRegDesktop? desktop,
    WcRegMetadata? metadata,
  }) {
    this.image_url = image_url ?? WcRegImageUrl();
    this.app = app ?? WcRegApp();
    this.mobile = mobile ?? WcRegMobile();
    this.desktop = desktop ?? WcRegDesktop();
    this.metadata = metadata ?? WcRegMetadata();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'homepage': homepage,
      'chains': chains,
      'versions': versions,
      'app_type': app_type,
      'image_id': image_id,
      'image_url': image_url,
      'app': app,
      'mobile': mobile,
      'desktop': desktop,
      'metadata': metadata,
    };
  }

  factory WalletConnectRegistryListing.fromMap(Map<String, dynamic> map) {
    return WalletConnectRegistryListing(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      homepage: map['homepage'] as String? ?? '',
      chains: (map['chains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      versions: (map['versions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      app_type: map['app_type'] as String? ?? '',
      image_id: map['image_id'] as String? ?? '',
      image_url: map['image_url'] == null
          ? null
          : WcRegImageUrl.fromJson(map['image_url'] as Map<String, dynamic>),
      app: map['app'] == null
          ? null
          : WcRegApp.fromJson(map['app'] as Map<String, dynamic>),
      mobile: map['mobile'] == null
          ? null
          : WcRegMobile.fromJson(map['mobile'] as Map<String, dynamic>),
      desktop: map['desktop'] == null
          ? null
          : WcRegDesktop.fromJson(map['desktop'] as Map<String, dynamic>),
      metadata: map['metadata'] == null
          ? null
          : WcRegMetadata.fromJson(map['metadata'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory WalletConnectRegistryListing.fromJson(String source) => WalletConnectRegistryListing.fromMap(json.decode(source));

  // factory WalletConnectRegistryListing.fromJson(Map<String, dynamic> json)  =>
  //     _$WalletConnectRegistryListingFromJson(json);

  // factory WalletConnectRegistryListing.fromJson(Map<String, dynamic> json) {
  //   debugPrint(json.values.toString());
  //   return _$WalletConnectRegistryListingFromJson(json);
  // }
  //
  //
  // Map<String, dynamic> toJson() => _$WalletConnectRegistryListingToJson(this);

  @override
  String toString() {
    return "{\n"
        "  id: '$id',\n"
        "  name: '$name',\n"
        "  description: '$description',\n"
        "  homepage: '$homepage',\n"
        "  mobile native: '${mobile.native}',\n"
        "  mobile universal: '${mobile.universal}',\n"
        "  image_url sm: '${image_url.sm}',\n"
        "  image_url md: '${image_url.md}',\n"
        "}";
  }
}

// Example listing from curl 'https://registry.walletconnect.com/api/v1/wallets?&entries=1&page=1'
// {
//         "1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369": {
//             "id": "1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369",
//             "name": "Rainbow",
//             "description": "",
//             "homepage": "https://rainbow.me/",
//             "chains": [
//                 "eip155:1"
//             ],
//             "versions": [
//                 "1"
//             ],
//             "image_id": "2cc2f20c-840b-497a-c028-dbb481d49700",
//             "image_url": {
//                 "sm": "https://imagedelivery.net/_aTEfDRm7z3tKgu9JhfeKA/2cc2f20c-840b-497a-c028-dbb481d49700/sm",
//                 "md": "https://imagedelivery.net/_aTEfDRm7z3tKgu9JhfeKA/2cc2f20c-840b-497a-c028-dbb481d49700/md",
//                 "lg": "https://imagedelivery.net/_aTEfDRm7z3tKgu9JhfeKA/2cc2f20c-840b-497a-c028-dbb481d49700/lg"
//             },
//             "app": {
//                 "browser": "",
//                 "ios": "https://apps.apple.com/us/app/rainbow-ethereum-wallet/id1457119021",
//                 "android": "",
//                 "mac": "",
//                 "windows": "",
//                 "linux": ""
//             },
//             "mobile": {
//                 "native": "rainbow:",
//                 "universal": "https://rnbwapp.com"
//             },
//             "desktop": {
//                 "native": "",
//                 "universal": ""
//             },
//             "metadata": {
//                 "shortName": "Rainbow",
//                 "colors": {
//                     "primary": "#001e59",
//                     "secondary": ""
//                 }
//             }
//         },

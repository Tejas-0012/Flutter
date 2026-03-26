import 'package:flutter/material.dart';

class LogoMap {
  static const Map<String, String> logoMap = {
    'mavalli': 'lib/src/assets/images/logo/Mavalli_Tiffin_Room_Logo.png',
    'vidyarthibhavan': 'lib/src/assets/images/logo/vidyarthibhavana.jpg',
    'karavali': 'lib/src/assets/images/logo/karavali.jpg',
    'Toit': 'lib/src/assets/images/logo/Toit.png',
    'CChang': 'lib/src/assets/images/logo/ChutChang.png',
    'Brahma': 'lib/src/assets/images/logo/BB.jpg',
    'Nagarjuna': 'lib/src/assets/images/logo/nagarajuna.png',
    'Truffels': 'lib/src/assets/images/logo/truffles.jpg',
    'Brick': 'lib/src/assets/images/logo/BrikOven.png',
    'Meghana': 'lib/src/assets/images/logo/MeghanaFoods.png',
    'Udupi': 'lib/src/assets/images/logo/UdupiPark.jpg',
    'BP': 'lib/src/assets/images/logo/Blackpearl.png',
    'CB': 'lib/src/assets/images/logo/CaliforniaBurrito.png',
    'Koshy': 'lib/src/assets/images/logo/KOSHY.jpg',
    'chill': 'lib/src/assets/images/logo/Chills.png',
    'a2b': 'lib/src/assets/images/logo/a2b.jpg',
    'only': 'lib/src/assets/images/logo/OnlyPlace.jpg',
    'Shivaji': 'lib/src/assets/images/logo/Shivaji.jpg',
    'Hae': 'lib/src/assets/images/logo/HAE.jpg',
  };

  static String getLogoPath(String logoKey) {
    return logoMap[logoKey] ?? 'lib/src/assets/images/default_restaurant.jpeg';
  }

  static Widget getLogoWidget(
    String logoKey, {
    double width = 40,
    double height = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      getLogoPath(logoKey),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant,
            size: width * 0.6,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }
}

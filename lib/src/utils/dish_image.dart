import 'package:flutter/material.dart';

class DishMap {
  static const Map<String, String> dishmap = {
    'BC': 'lib/src/assets/images/dishes/butter-chicken.jpg',
    'CHPT': 'lib/src/assets/images/dishes/chapathi.jpg',
    'CR': 'lib/src/assets/images/dishes/curd-rice.jpg',
    'FM': 'lib/src/assets/images/dishes/fullmeals.jpg',
    'GN': 'lib/src/assets/images/dishes/garlic-naan.jpg',
    'GS': 'lib/src/assets/images/dishes/green-salad.jpg',
    'GCS': 'lib/src/assets/images/dishes/grilled-chicken-sandwich.jpg',
    'GJ': 'lib/src/assets/images/dishes/gulab-jamun.jpg',
    'HSS': 'lib/src/assets/images/dishes/hot-sour-soup.jpg',
    'IDL': 'lib/src/assets/images/dishes/idli.jpg',
    'LR': 'lib/src/assets/images/dishes/lemon_rice.jpg',
    'ML': 'lib/src/assets/images/dishes/mango-lassi.jpg',
    'MD': 'lib/src/assets/images/dishes/masala-dosa.jpg',
    'PP': 'lib/src/assets/images/dishes/pani-puri.jpg',
    'PD': 'lib/src/assets/images/dishes/plain_dosa.jpg',
    'SR': 'lib/src/assets/images/dishes/sambar_rice.jpg',
    'TR': 'lib/src/assets/images/dishes/tomato_rice.jpg',
    'VADA': 'lib/src/assets/images/dishes/vada.jpg',
    'VB': 'lib/src/assets/images/dishes/veg-biriyani.jpg',
    'VP': 'lib/src/assets/images/dishes/vegtable_pulao.jpg',
  };

  static String getLogoPath(String dishkey) {
    return dishmap[dishkey] ??
        'lib/src/assets/images/dishes/default_restaurant.jpeg';
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

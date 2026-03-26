import 'package:flutter/material.dart';
import 'package:platter/src/models/menu_items.dart';

class MenuItemModal extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onAddToCart;

  const MenuItemModal({
    super.key,
    required this.menuItem,
    required this.onAddToCart,
  });

  Widget _buildDietaryIcons(MenuItem item) {
    List<Widget> icons = [];

    if (item.dietaryInfo.isVegetarian) {
      icons.add(const Icon(Icons.eco, color: Colors.green, size: 16));
    }
    if (item.dietaryInfo.isVegan) {
      icons.add(const Icon(Icons.forest, color: Colors.lightGreen, size: 16));
    }
    if (item.dietaryInfo.isGlutenFree) {
      icons.add(const Icon(Icons.grain, color: Colors.orange, size: 16));
    }
    if (item.dietaryInfo.isSpicy) {
      icons.add(
        const Icon(Icons.local_fire_department, color: Colors.red, size: 16),
      );
    }

    return Row(children: icons);
  }

  Widget _buildInfoChip(String text, [Color? color]) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color ?? Colors.grey[600],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildClimateTags(List<String>? climateTags) {
    if (climateTags == null || climateTags.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: climateTags
          .map(
            (tag) => Chip(
              label: Text(tag),
              backgroundColor: Colors.blue[50],
              labelStyle: const TextStyle(fontSize: 12),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with image and basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (menuItem.images.isNotEmpty)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        // image: DecorationImage(
                        //   // image: menuItem.images,
                        //   fit: BoxFit.cover,
                        // ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${menuItem.category}${' • ${menuItem.subCategory}'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildDietaryIcons(menuItem),
                            const Spacer(),
                            Text(
                              '₹${menuItem.price}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              if (menuItem.description.isNotEmpty) ...[
                Text(
                  menuItem.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
              ],

              // Dietary Information
              const Text(
                'Dietary Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('${menuItem.dietaryInfo.calories} cal'),
                  if (menuItem.dietaryInfo.isVegetarian)
                    _buildInfoChip('Vegetarian', Colors.green),
                  if (menuItem.dietaryInfo.isVegan)
                    _buildInfoChip('Vegan', Colors.lightGreen),
                  if (menuItem.dietaryInfo.isGlutenFree)
                    _buildInfoChip('Gluten Free', Colors.orange),
                  if (menuItem.dietaryInfo.isDairyFree)
                    _buildInfoChip('Dairy Free', Colors.blue),
                  if (menuItem.dietaryInfo.isNutFree)
                    _buildInfoChip('Nut Free', Colors.brown),
                  if (menuItem.dietaryInfo.isSpicy)
                    _buildInfoChip('Spicy', Colors.red),
                ],
              ),

              if (menuItem.dietaryInfo.allergens.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Allergens: ${menuItem.dietaryInfo.allergens.join(', ')}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              // Climate Tags
              if (menuItem.climateTags?.isNotEmpty == true) ...[
                const Text(
                  'Climate Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildClimateTags(menuItem.climateTags),
                const SizedBox(height: 16),
              ],

              // Preparation Time & Rating
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${menuItem.preparationTime} min',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${menuItem.rating} (${menuItem.ratingCount})'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ADD TO CART',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

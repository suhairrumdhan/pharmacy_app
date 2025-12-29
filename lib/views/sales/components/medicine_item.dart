import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../models/inventory_model.dart';

class MedicineItem extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const MedicineItem({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: medicine.imageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              medicine.imageUrl!,
              fit: BoxFit.cover,
            ),
          )
              : Icon(
            Iconsax.medal_star,
            color: Colors.blue[700],
            size: 20,
          ),
        ),
        title: Text(
          medicine.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          medicine.scientificName,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(medicine.sellingPrice ?? 0).toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: medicine.isLowStock ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: medicine.isLowStock ? Colors.orange[100]! : Colors.green[100]!,
                ),
              ),
              child: Text(
                '${medicine.quantity} متبقي',
                style: TextStyle(
                  fontSize: 10,
                  color: medicine.isLowStock ? Colors.orange[700] : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
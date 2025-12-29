import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../models/sales_model.dart';

// قم بتغيير اسم Widget ليصبح SaleItemWidget بدلاً من SaleItem
class SaleItemWidget extends StatelessWidget {
  final SaleItem item;  // SaleItem هنا تأتي من sales_model.dart
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SaleItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          item.name,  // سيتم التعرف على item من نوع SaleItem من المودل
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.scientificName != null)
              Text(
                item.scientificName!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (item.discountAmount != null || item.discountPercentage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.discountAmount != null
                            ? 'خصم ${item.discountAmount!.toStringAsFixed(2)}'
                            : '${item.discountPercentage}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'د.ل ${item.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  icon: Iconsax.edit_2,
                  color: Colors.blue,
                  onTap: onEdit,
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Iconsax.trash,
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }
}
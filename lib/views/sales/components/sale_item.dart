import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../models/sales_model.dart';

class SaleItemWidget extends StatelessWidget {
  final SaleItem item;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isEditable;

  const SaleItemWidget({
    super.key,
    required this.item,
    required this.index,
    this.onEdit,
    this.onDelete,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEditable ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditable ? Colors.grey[100]! : Colors.grey[200]!,
        ),
        boxShadow: [
          if (isEditable)
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
            color: isEditable ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isEditable ? Colors.blue[700] : Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEditable ? Colors.grey[800] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isEditable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.tick_circle, size: 10, color: Colors.green[700]),
                    const SizedBox(width: 2),
                    Text(
                      'مباع',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.scientificName != null && item.scientificName!.isNotEmpty)
              Text(
                item.scientificName!,
                style: TextStyle(
                  fontSize: 11,
                  color: isEditable ? Colors.grey[600] : Colors.grey[400],
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
                    color: isEditable ? Colors.grey[700] : Colors.grey[500],
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
                if (item.sellAsPiece)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'قطعة',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEditable ? const Color(0xFF2C3E50) : Colors.green[600],
                ),
              ),
            ),

            // إظهار الأزرار فقط إذا كان قابلاً للتعديل
            if (isEditable)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionButton(
                    icon: Iconsax.edit_2,
                    color: Colors.blue,
                    onTap: onEdit,
                    isEnabled: onEdit != null,
                  ),
                  const SizedBox(width: 4),
                  _actionButton(
                    icon: Iconsax.trash,
                    color: Colors.red,
                    onTap: onDelete,
                    isEnabled: onDelete != null,
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
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 12,
          color: isEnabled ? color : Colors.grey[400],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class SearchOverlay {
  static OverlayEntry createOverlay({
    required LayerLink layerLink,
    required List<Map<String, dynamic>> searchResults,
    required BuildContext context,
    required Function(Map<String, dynamic>) onSelectResult,
    required Function(String) getIconForType,
  }) {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width * 0.9 * 0.7 - 30,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  minHeight: 50,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: searchResults.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "جاري البحث...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: index < searchResults.length - 1
                            ? Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        )
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          getIconForType(result['type']),
                          color: Colors.blue,
                          size: 20,
                        ),
                        title: Text(
                          result['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${result['lat'].toStringAsFixed(4)}, ${result['lon'].toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          '${(result['importance'] * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: result['importance'] > 0.5
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => onSelectResult(result),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
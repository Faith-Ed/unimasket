import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationListItem extends StatefulWidget {
  final Map<String, dynamic> notification;
  final String notificationId;
  final String? listingImage;
  final bool initialSelected;
  final Function(bool selected, String id) onSelectionChanged;
  final VoidCallback? onTap;

  NotificationListItem({
    required this.notification,
    required this.notificationId,
    this.listingImage,
    this.initialSelected = false,
    required this.onSelectionChanged,
    this.onTap,
  });

  @override
  _NotificationListItemState createState() => _NotificationListItemState();
}

class _NotificationListItemState extends State<NotificationListItem> {
  late bool isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = widget.initialSelected;
  }

  void _toggleSelection() {
    setState(() {
      isSelected = !isSelected;
      widget.onSelectionChanged(isSelected, widget.notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final timestamp = notification['timestamp'];
    final formattedTime = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : '';
    final message = notification['message'] ?? 'No message available.';
    final notificationType = notification['type'] ?? '';
    final status = notification['status'] ?? '';

    return Card(
      color: isSelected ? Colors.grey[200] : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        onLongPress: _toggleSelection,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  _toggleSelection();
                },
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.listingImage ?? 'https://res.cloudinary.com/demo/image/upload/dgou42nni/default-placeholder.jpg',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://res.cloudinary.com/demo/image/upload/dgou42nni/default-placeholder.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!isSelected)
                          Icon(Icons.circle, color: Colors.red, size: 8),
                        if (!isSelected) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notificationType == 'order_accepted'
                                ? 'Order Accepted'
                                : notificationType == 'order_declined'
                                ? 'Order Declined'
                                : 'Order $status',
                            style: TextStyle(
                              fontWeight:
                              isSelected ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

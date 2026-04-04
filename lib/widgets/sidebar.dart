import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pharmacy_desktop/controllers/auth_controller.dart';

import '../controllers/chat_controller.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final IconData? activeIcon;

  /// ✅ عداد عام لأي عنصر في السايدبار
  final RxInt notificationCount;

  SidebarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    int notificationCount = 0,
  }) : notificationCount = notificationCount.obs;

  // Optional: Constructor for existing RxInt
  SidebarItem.withRx({
    required this.icon,
    required this.label,
    this.activeIcon,
    required RxInt notificationCount,
  }) : notificationCount = notificationCount;

}

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String pharmacyName;
  final String pharmacyAddress;
  final List<SidebarItem> sidebarItems;
  final Color backgroundColor;
  final Color activeColor;
  final Color textColor;
  final Color activeTextColor;
  final bool collapsed;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.pharmacyName,
    this.pharmacyAddress = "",
    required this.sidebarItems,
    this.backgroundColor = const Color(0xFF1E40AF),
    this.activeColor = const Color(0xFF3B82F6),
    this.textColor = Colors.white,
    this.activeTextColor = Colors.white,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Container(
      width: collapsed ? 86 : 260,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(authController),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: sidebarItems.length,
              itemBuilder: (context, index) => _buildSidebarItem(index),
            ),
          ),
          _buildFooter(authController),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthController authController) {
    final String username = authController.userName;
    final String role = authController.userRole;

    return Container(
      padding: EdgeInsets.all(collapsed ? 16 : 24),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: pharmacyName,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Iconsax.health, color: Colors.white, size: 28),
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (username.isNotEmpty)
                    Text(
                      "المستخدم: $username",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (role.isNotEmpty)
                    Text(
                      "الدور: $role",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(int count) {
    return Positioned(
      right: -4,
      top: -4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1),
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          count > 9 ? '9+' : count.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }


  Widget _buildSidebarItem(int index) {
    final item = sidebarItems[index];
    final isSelected = selectedIndex == index;

    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final iconColor = isSelected ? activeTextColor : textColor.withOpacity(0.85);

    // ✅ إذا كان العنصر هو "المراسلات"، استخدم Obx
    if (item.label == "المراسلات") {
      return Obx(() {
        final unreadCount = Get.find<ChatController>().totalUnreadCount.value;
        return _buildSidebarItemContent(
          icon: icon,
          iconColor: iconColor,
          label: item.label,
          isSelected: isSelected,
          notificationCount: unreadCount,
          onTap: () => onItemSelected(index),
        );
      });
    }

    // للعناصر العادية
    return _buildSidebarItemContent(
      icon: icon,
      iconColor: iconColor,
      label: item.label,
      isSelected: isSelected,
      notificationCount: item.notificationCount.value,
      onTap: () => onItemSelected(index),
    );
  }

// ✅ أضف هذه الدالة الجديدة لتجميع الكود المتكرر
  Widget _buildSidebarItemContent({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isSelected,
    required int notificationCount,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 10 : 16,
        vertical: 4,
      ),
      child: Material(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 16,
              vertical: 16,
            ),
            child: collapsed
                ? Tooltip(
              message: label,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    if (notificationCount > 0 && !isSelected)
                      _buildNotificationBadge(notificationCount),
                  ],
                ),
              ),
            )
                : Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    if (notificationCount > 0 && !isSelected)
                      _buildNotificationBadge(notificationCount),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? activeTextColor
                          : textColor.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Iconsax.arrow_left_2,
                    color: activeTextColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildFooter(AuthController authController) {
    final bool isEmployee = authController.currentEmployee.value != null;

    return Container(
      padding: EdgeInsets.all(collapsed ? 12 : 20),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          if (!isEmployee)
            _footerButton(
              collapsed: collapsed,
              label: "دخول موظف",
              icon: Iconsax.user_square,
              color: Colors.white,
              bg: Colors.white.withOpacity(0.12),
              border: Colors.white.withOpacity(0.2),
              onTap: () {
                authController.openInternalLogin();
              },
            ),
          if (!isEmployee) SizedBox(height: collapsed ? 8 : 12),
          if (isEmployee) ...[
            _footerButton(
              collapsed: collapsed,
              label: "تبديل موظف",
              icon: Iconsax.profile_2user,
              color: Colors.green.shade400,
              bg: Colors.green.withOpacity(0.1),
              border: Colors.green.withOpacity(0.3),
              onTap: authController.switchUser,
            ),
            SizedBox(height: collapsed ? 8 : 12),
          ],
          _footerButton(
            collapsed: collapsed,
            label: "الخروج من النظام",
            icon: Iconsax.logout,
            color: Colors.red.shade400,
            bg: Colors.red.withOpacity(0.1),
            border: Colors.red.withOpacity(0.3),
            onTap: authController.logoutOwnerSecure,
          ),
        ],
      ),
    );
  }

  Widget _footerButton({
    required bool collapsed,
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    final child = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 16,
              vertical: 14,
            ),
            child: collapsed
                ? Center(
              child: Icon(icon, color: color, size: 24),
            )
                : Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: label, child: child) : child;
  }
}
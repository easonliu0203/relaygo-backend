import 'package:flutter/material.dart';

/// 語言選項 Tile
/// 用於顯示單個語言選項，包含國旗、語言名稱和選中狀態
class LanguageOptionTile extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageOptionTile({
    super.key,
    required this.languageCode,
    required this.languageName,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          languageName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 28,
              )
            : Icon(
                Icons.circle_outlined,
                color: Colors.grey.shade400,
                size: 28,
              ),
        onTap: onTap,
        tileColor: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
      ),
    );
  }
}


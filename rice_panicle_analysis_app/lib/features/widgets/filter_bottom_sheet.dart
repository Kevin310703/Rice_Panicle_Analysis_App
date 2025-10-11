import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class FilterBottomSheet {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? startDate; // Biến để lưu ngày bắt đầu
    DateTime? endDate; // Biến để lưu ngày kết thúc

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Projects',
                    style: AppTextStyle.withColor(
                      AppTextStyle.h3,
                      Theme.of(context).textTheme.bodyLarge!.color!,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: isDark ? Colors.white : Colors.black,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Date Range',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyLarge,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            startDate = pickedDate;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: startDate == null
                                ? 'Start'
                                : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            endDate = pickedDate;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: endDate == null
                                ? 'To'
                                : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Categories',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyLarge,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),

              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Active', 'Rice']
                    .map(
                      (category) => FilterChip(
                        label: Text(category),
                        selected: category == 'All',
                        onSelected: (selected) {},
                        backgroundColor: Theme.of(context).cardColor,
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        labelStyle: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium,
                          category == 'All'
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Thêm logic xử lý khi áp dụng bộ lọc (ví dụ: trả về startDate và endDate)
                    Navigator.pop(context, {
                      'startDate': startDate,
                      'endDate': endDate,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      Colors.white,
                    ),
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

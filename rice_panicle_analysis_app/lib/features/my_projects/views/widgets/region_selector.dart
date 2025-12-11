import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/hill.dart';

class RegionSelector extends StatefulWidget {
  final List<Hill> hills;
  final int currentRegion;
  final Function(int) onRegionSelected;
  final VoidCallback onAddRegion;
  final bool isDark;
  final ScrollController scrollController;
  final ValueChanged<Hill>? onRenameHill;
  final ValueChanged<Hill>? onDeleteHill;

  const RegionSelector({
    super.key,
    required this.hills,
    required this.currentRegion,
    required this.onRegionSelected,
    required this.onAddRegion,
    required this.isDark,
    required this.scrollController,
    this.onRenameHill,
    this.onDeleteHill,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  int? _hoverRegion;
  bool _hoverAdd = false;

  @override
  Widget build(BuildContext context) {
    final hillCount = widget.hills.length;
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hillCount + 1,
        itemBuilder: (context, index) {
          if (index == hillCount) {
            return _buildAddRegionCard();
          }
          final hill = widget.hills[index];
          final isSelected = widget.currentRegion == index;
          final title = hill.hillLabel.isNotEmpty
              ? hill.hillLabel
              : 'Hill ${index + 1}';
          
          return _buildRegionCard(
            hill: hill,
            index: index,
            title: title,
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  Widget _buildRegionCard({
    required Hill hill,
    required int index,
    required String title,
    required bool isSelected,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverRegion = index),
      onExit: (_) => setState(() => _hoverRegion = null),
      child: GestureDetector(
        onTap: () => widget.onRegionSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (widget.isDark ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (widget.isDark ? Colors.grey[700]! : Colors.grey[200]!),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (widget.isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              if (widget.onRenameHill != null || widget.onDeleteHill != null)
                Positioned(
                  top: 0,
                  right: 4,
                  child: PopupMenuButton<_RegionMenuAction>(
                    tooltip: 'Manage hill',
                    offset: const Offset(0, 46),
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDark ? Colors.white70 : Colors.black54),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _RegionMenuAction.rename:
                          widget.onRenameHill?.call(hill);
                          break;
                        case _RegionMenuAction.delete:
                          widget.onDeleteHill?.call(hill);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        if (widget.onRenameHill != null)
                          const PopupMenuItem<_RegionMenuAction>(
                            value: _RegionMenuAction.rename,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_rounded, size: 18),
                              title: Text('Rename'),
                            ),
                          ),
                        if (widget.onDeleteHill != null)
                          PopupMenuItem<_RegionMenuAction>(
                            value: _RegionMenuAction.delete,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red[600],
                                size: 18,
                              ),
                              title: Text('Delete', style: TextStyle(color: Colors.red[600])),
                            ),
                          ),
                    ];
                  },
                ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRegionCard() {
    final bool isHover = _hoverAdd;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverAdd = true),
      onExit: (_) => setState(() => _hoverAdd = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onAddRegion,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          transform: Matrix4.identity()..scale(isHover ? 1.0 : 1.0),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CAF50),
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.25),
                blurRadius: isHover ? 14 : 8,
                offset: Offset(0, isHover ? 6 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Create hill',
                style: TextStyle(fontSize: 15, color: Color(0xFF4CAF50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RegionMenuAction { rename, delete }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/group.dart';

class GroupTile extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;

  const GroupTile({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Group avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.secondary.withAlpha(30),
              child: Icon(
                Icons.group,
                color: theme.colorScheme.secondary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Name and member count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),

            // Connected count badge
            if (group.connectedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${group.connectedCount}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withAlpha(60),
              ),
          ],
        ),
      ),
    );
  }
}

part of '../map_page.dart';

extension _MapSearchResults on _MapsState {
  Widget buildDestinationSearchResults(Size media) {
    if (addAutoFill.isEmpty) return const SizedBox.shrink();

    final suggestions = addAutoFill.take(5).toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F10213F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < suggestions.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 56, endIndent: 14),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => selectAutocompleteSuggestion(
                  suggestions[index] as Map<dynamic, dynamic>,
                ),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: index == suggestions.length - 1
                      ? const Radius.circular(18)
                      : Radius.zero,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0873FF).withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF0873FF),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          _suggestionLabel(suggestions[index]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10213F),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.north_west_rounded,
                        color: Color(0xFF9AA7B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _suggestionLabel(dynamic suggestion) {
    if (suggestion is! Map) return '';
    return (suggestion['description'] ?? suggestion['display_name'])
            ?.toString() ??
        '';
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NotifactionScima extends StatelessWidget {
  const NotifactionScima({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10, // Spacing between items
      children: List.generate(3, (index) => _buildShimmerItem()),
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SizedBox(
          width: double.infinity,
          height: 80, // Adjust height as necessary
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 15,
                color: Colors.white, // Placeholder for title
              ),
              const SizedBox(height: 5),
              Container(
                height: 10,
                width: 150, // Placeholder width for subtitle
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Container(
                height: 10,
                width: 80, // Placeholder width for time
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

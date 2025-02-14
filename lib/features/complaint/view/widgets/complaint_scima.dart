import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ComplaintShimmer extends StatelessWidget {
  const ComplaintShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10, // Spacing between items
          children: List.generate(4, (index) => _buildShimmerItem()),
        ),
        Wrap(
          spacing: 10, // Spacing between items
          children: List.generate(1, (index) => _buildShimmerItem2()),
        ),
      ],
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          color: Colors.grey,
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10.h),
          height: 80.h, // Adjust height as necessary
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
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

  Widget _buildShimmerItem2() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          color: Colors.grey,
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10.h),
          height: 120.h, // Adjust height as necessary
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 15,
                color: Colors.white, // Placeholder for title
              ),
            ],
          ),
        ),
      ),
    );
  }
}

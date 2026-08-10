import 'package:flutter/material.dart';

class CustomersPageHeader extends StatelessWidget {
  const CustomersPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customers',
          style: TextStyle(
            color: Color(0xFF06235D),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Search, select, and manage customers during checkout',
          style: TextStyle(
            color: Color(0xFF8E9BAE),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

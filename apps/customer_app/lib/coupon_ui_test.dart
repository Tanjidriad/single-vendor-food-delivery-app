import 'package:flutter/material.dart';

void main() {
  runApp(const CouponUiTestApp());
}

class CouponUiTestApp extends StatelessWidget {
  const CouponUiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coupon UI Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const CouponScreen(),
    );
  }
}

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final double orderTotal = 400;
  final String currency = '₹';

  final List<Map<String, dynamic>> allCoupons = [
    {
      'id': '1',
      'code': 'TRYNEW',
      'discount': 20,
      'isPercentage': true,
      'description': 'Use code TRYNEW & get 20% off',
      'isActive': true,
      'expiryDate': '2023-08-15T18:30:00',
      'minimumOrderAmount': 499,
      'upto_discount': 200,
    },
    {
      'id': '2',
      'code': 'FREESHIP',
      'discount': 100,
      'isPercentage': false,
      'description': 'Flat ₹100 off',
      'isActive': true,
      'expiryDate': '2023-09-30T23:59:59',
      'minimumOrderAmount': null,
      'upto_discount': null,
    },
    {
      'id': '3',
      'code': 'SALE50',
      'discount': 50,
      'isPercentage': true,
      'description': 'Big Sale - Flat 50% off on everything',
      'isActive': true,
      'expiryDate': '2023-08-31T23:59:59',
      'minimumOrderAmount': 1000,
      'upto_discount': 550,
    },
    {
      'id': '4',
      'code': 'NEW50',
      'discount': 50,
      'isPercentage': true,
      'description': 'New customer offer - Flat 50% off on everything',
      'isActive': true,
      'expiryDate': '2023-08-31T23:59:59',
      'minimumOrderAmount': 399,
      'upto_discount': 250,
    },
  ];

  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    coupons = allCoupons.map((coupon) {
      final updated = Map<String, dynamic>.from(coupon);
      updated['saved'] = _getSavedAmount(updated);
      return updated;
    }).toList();
  }

  double _getSavedAmount(Map<String, dynamic> coupon) {
    double amt = 0;
    if (coupon['minimumOrderAmount'] != null) {
      amt = orderTotal - (coupon['minimumOrderAmount'] as num).toDouble();
      if (amt < 0) return amt;
    }
    
    double discount = (coupon['discount'] as num).toDouble();
    if (coupon['isPercentage'] == true) {
      amt = orderTotal * (discount / 100);
    } else {
      amt = discount;
    }

    if (coupon['upto_discount'] != null) {
      double upto = (coupon['upto_discount'] as num).toDouble();
      amt = (amt >= upto) ? upto : amt;
    }
    return amt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Coupon'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          final bool isApplicable = (coupon['saved'] as num) >= 0;
          final double savedAmt = (coupon['saved'] as num).toDouble();

          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side (Offer Box)
                  SizedBox(
                    width: 48,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: isApplicable
                                ? const LinearGradient(
                                    colors: [Color(0xFFDE0F17), Color(0xFFF95B4B)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: isApplicable ? null : Colors.grey[400],
                          ),
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                coupon['isPercentage'] == true
                                    ? '${coupon['discount']}% OFF'
                                    : '$currency${coupon['discount']} OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Perforated circles on the left edge
                        const Positioned(
                          left: -4,
                          top: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Hole(),
                              _Hole(),
                              _Hole(),
                              _Hole(),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // Right side (Details)
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coupon['code'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isApplicable
                                          ? 'Save $currency${savedAmt.toStringAsFixed(0)} on this order'
                                          : 'Add $currency${(-savedAmt).toStringAsFixed(0)} more to avail this offer',
                                      style: TextStyle(
                                        color: isApplicable ? Colors.green : Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: isApplicable ? () {} : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: isApplicable ? Colors.red : Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'APPLY',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: _DashedDivider(),
                          ),
                          
                          // Description
                          Text(
                            _getDescription(coupon),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // More Button
                          InkWell(
                            onTap: () {},
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'MORE',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDescription(Map<String, dynamic> coupon) {
    String desc = coupon['description'];
    if (coupon['minimumOrderAmount'] != null) {
      desc += ' on orders above $currency${coupon['minimumOrderAmount']}.';
    } else {
      desc += ' on all orders.';
    }
    if (coupon['upto_discount'] != null) {
      desc += ' Maximum discount $currency${coupon['upto_discount']}.';
    }
    return desc;
  }
}

class _Hole extends StatelessWidget {
  const _Hole();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Matches the background outside the card
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}

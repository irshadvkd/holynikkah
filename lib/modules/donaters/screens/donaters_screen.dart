import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class DonatersScreen extends StatefulWidget {
  const DonatersScreen({super.key});

  @override
  State<DonatersScreen> createState() => _DonatersScreenState();
}

class _DonatersScreenState extends State<DonatersScreen> {
  String? selectedAmount;
  String? selectedPayment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'DONATES',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Support Love in Action',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Donation helps us build safer connection and empower communities',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Donation amounts
              Row(
                children: [
                  _buildAmountButton('\$50'),
                  const SizedBox(width: 12),
                  _buildAmountButton('\$100'),
                  const SizedBox(width: 12),
                  _buildAmountButton('\$250'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAmountButton('\$500'),
                  const SizedBox(width: 12),
                  _buildOtherButton(),
                ],
              ),

              const SizedBox(height: 40),
              Text(
                'Payment Method',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Payment methods
              _buildPaymentMethod('PayPal', 'assets/icons/paypal.svg'),
              const SizedBox(height: 12),
              _buildPaymentMethod('Google Pay', 'assets/icons/google_pay.svg'),
              const SizedBox(height: 12),
              _buildPaymentMethod('Paytm', 'assets/icons/paytm.svg'),

              const Spacer(),

              // Contact button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFF5F5F5),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'For Financial Support Contact',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountButton(String amount) {
    final isSelected = selectedAmount == amount;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAmount = amount;
          });
        },
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFAC60C), Color(0xFF947507)],
                  )
                : const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xF01F2421), Color(0xADC7C7C7)],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFF5F5F5),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              amount,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherButton() {
    final isSelected = selectedAmount == 'Other';

    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAmount = 'Other';
          });
        },
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFAC60C), Color(0xFF947507)],
                  )
                : const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xF01F2421), Color(0xADC7C7C7)],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFF5F5F5),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Other',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String name, String iconPath) {
    final isSelected = selectedPayment == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = name;
        });
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF1F2421),
              const Color(0xFFC7C7C7),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFF5F5F5),
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 80,
                alignment: Alignment.center,
                child: SvgPicture.asset(iconPath),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

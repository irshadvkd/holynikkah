import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/services/navigation_guard.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/widgets/common_button.dart';

@RoutePage()
class ChooseRegisterTypePage extends StatelessWidget {
  const ChooseRegisterTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChooseRegisterTypeScreen();
  }
}

class ChooseRegisterTypeScreen extends StatefulWidget {
  const ChooseRegisterTypeScreen({super.key});

  @override
  State<ChooseRegisterTypeScreen> createState() =>
      _ChooseRegisterTypeScreenState();
}

class _ChooseRegisterTypeScreenState extends State<ChooseRegisterTypeScreen> {
  String selectedType = 'user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                'Choose Registration Type',
                style: GoogleFonts.inter(fontSize: 24),
              ),
              const SizedBox(height: 20),
              RadioListTile<String>(
                title: const Text('Normal Registration'),
                value: 'user',
                groupValue: selectedType,
                activeColor: AppColors.brandYellow,
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
                shape: selectedType == 'user'
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.brandYellow),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              RadioListTile<String>(
                title: const Text('VIP Registration'),
                value: 'vip',
                groupValue: selectedType,
                activeColor: AppColors.brandYellow,
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
                shape: selectedType == 'vip'
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.brandYellow),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CommonButton(
          text: "Continue",
          onPressed: () async {
            // Track registration type selection
            await UserJourneyTracker().startJourney(
              JourneyType.registration,
              context: {'selectedType': selectedType},
            );
            
            await UserJourneyTracker().trackRegistrationFlow(
              isVip: selectedType == 'vip',
              step: 'type_selected',
              data: {'registrationType': selectedType},
            );

            // Navigate with tracking
            await context.navigationGuard.navigateTo(
              context,
              RegistrationRoute(isVip: selectedType == 'vip'),
              trigger: 'registration_type_selection',
              data: {'isVip': selectedType == 'vip'},
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  final VoidCallback onGuest;
  const WelcomeScreen({super.key, required this.onGuest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sports_esports_outlined,
                        size: 40, color: primary),
                  ),
                  SizedBox(height: size.height * 0.05),

                  // Heading
                  Text(
                    'Welcome',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Who's playing today?",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),

                  SizedBox(height: size.height * 0.07),

                  // Profile cards
                  Row(
                    children: UserProfile.all
                        .map((p) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: _ProfileCard(
                                  profile: p,
                                  onTap: () => ref
                                      .read(activeProfileProvider.notifier)
                                      .select(p),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // Guest option
                  TextButton(
                    onPressed: onGuest,
                    child: Text(
                      'Play as guest',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: primary.withValues(alpha: 0.15),
              child: Text(
                profile.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  
  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome to Chonh Choun',
      'description': 'Your unified solution for efficient logistics and transportation.',
      'image': 'assets/images/bluelogo.png', 
    },
    {
      'title': 'Reliable Partners',
      'description': 'Connect with registered agents and track your deliveries in real-time.',
      'image': 'assets/images/boarding.png',
    },
    {
      'title': 'Ready to Start?',
      'description': 'Book your next ride or register as an agent to begin earning today.',
      'image': 'assets/images/agent.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() {
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFinalPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                   
                    Text(
                      _onboardingData[index]['title']!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5F8A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _onboardingData[index]['description']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const Spacer(), 

                    Image.asset(
                      _onboardingData[index]['image']!,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                    
                    const Spacer(), 
                  ],
                ),
              );
            },
          ),
          
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  width: _currentPage == index ? 24 : 10,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C5F8A),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          
          
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: isFinalPage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: isFinalPage
                  ? Center(
                      child: ElevatedButton(
                        onPressed: _onGetStartedPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C5F8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(), 
            ),
          ),
        ],
      ),
    );
  }
}
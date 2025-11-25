import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as Stripe;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumAccountScreen extends StatefulWidget {
  final DataProvider appData;
  const PremiumAccountScreen({Key? key, required this.appData}) : super(key: key);

  @override
  State<PremiumAccountScreen> createState() => _PremiumAccountScreenState();
}

class _PremiumAccountScreenState extends State<PremiumAccountScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initializeStripePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call your backend to create a payment intent
      final paymentIntentData = await _createPaymentIntent();
      
     

      // Present payment sheet
      await Stripe.Stripe.instance.presentPaymentSheet();

      // If payment successful, update user profile
      await _updatePremiumStatus(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium subscription activated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent() async {
    // TODO: Replace with your actual API endpoint
    // This should call your backend to create a Stripe payment intent
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://yourapi.com/create-payment-intent'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'amount': 999, // $9.99 in cents
    //     'currency': 'usd',
    //   }),
    // );
    // return json.decode(response.body);
    
    throw UnimplementedError('Implement your payment intent creation');
  }

  Future<void> _updatePremiumStatus(bool status) async {
    // TODO: Update appData.userProfile.premiumAccount
    // Example:
    // appData.userProfile.premiumAccount = status;
    // await appData.saveUserProfile();
    setState(() {});
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your premium subscription? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Call your backend to cancel Stripe subscription
        await _updatePremiumStatus(false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifySuperAccessCode() async {
    final code = _codeController.text.trim();
    
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Code must be 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

   

    try {

      var response = await Supabase.instance.client.from('testingUsers').select().eq('token', code).single();
      
      bool isValid() {
        if(response.isEmpty) {
          debugPrint('not valid');
          return false;
        } else {
          if(response['user'] == null) {
            return true;
          }
          return false;
        }
      }
      
      if (isValid()) {
        debugPrint('1');
        await Supabase.instance.client.from('testingUsers').update({'user' : Supabase.instance.client.auth.currentUser!.id}).eq('token', code);
        debugPrint('2');
        await Supabase.instance.client.from('profiles').update({'super_access' : true}).eq('user_id', Supabase.instance.client.auth.currentUser!.id);
       debugPrint('3');
       setState(() {});
        
        if (mounted) {
          widget.appData.loadUserInfo();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Super Access activated!'),
              backgroundColor: Colors.green,
            ),
          );
          _codeController.clear();
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid code. Please try again.';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _errorMessage = 'Error verifying code: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final hasPremium = widget.appData.userInfo!.premiumAccount; 
    final hasSuperAccess = widget.appData.userInfo!.superAccess; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Account'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Account Section
                  _buildSectionCard(
                    title: 'Premium Account',
                    icon: FontAwesomeIcons.arrowUpFromGroundWater,
                    child: hasPremium
                        ? _buildPremiumActiveContent()
                        : _buildPremiumInactiveContent(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Super Access Section
                  _buildSectionCard(
                    title: 'Super Access',
                    icon: FontAwesomeIcons.arrowUp,
                    child: hasSuperAccess
                        ? _buildSuperAccessActiveContent()
                        : _buildSuperAccessInactiveContent(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                 
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium subscription is active',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Premium Features:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildFeatureItem('Unlimited access to all features'),
        _buildFeatureItem('Ad-free experience'),
        _buildFeatureItem('Priority customer support'),
        _buildFeatureItem('Early access to new features'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _cancelSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Cancel Subscription'),
        ),
      ],
    );
  }

  Widget _buildPremiumInactiveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unlock premium features with a monthly subscription',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Text(
          'Premium Features:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildFeatureItem('Unlimited access to all features'),
        _buildFeatureItem('Ad-free experience'),
        _buildFeatureItem('Priority customer support'),
        _buildFeatureItem('Early access to new features'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Monthly Subscription',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cancel anytime',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Text(
                '\$9.99/mo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _initializeStripePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Subscribe Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSuperAccessActiveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified, color: Colors.purple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Super Access is active',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'You have access to exclusive super features and content.',
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem('Administrative controls'),
        _buildFeatureItem('Advanced analytics'),
        _buildFeatureItem('Beta features access'),
        _buildFeatureItem('Developer tools'),
      ],
    );
  }

  Widget _buildSuperAccessInactiveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your 6-digit code to activate Super Access',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Super Access Code',
            hintText: '000000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.lock),
            errorText: _errorMessage,
            counterText: '',
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifySuperAccessCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Activate Super Access',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
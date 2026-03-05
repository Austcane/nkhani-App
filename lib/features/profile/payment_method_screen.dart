import 'package:flutter/material.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA),

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Payment Methods",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= SAVED CARDS =================
            const Text(
              "Saved Cards",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _cardTile(
              cardType: "Visa",
              cardNumber: "**** **** **** 4587",
              expiry: "08/26",
              isDefault: true,
            ),

            const SizedBox(height: 12),

            _cardTile(
              cardType: "Mastercard",
              cardNumber: "**** **** **** 7742",
              expiry: "03/25",
              isDefault: false,
            ),

            const SizedBox(height: 25),

            // ================= ADD NEW CARD =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Add New Card",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= OTHER METHODS =================
            const Text(
              "Other Payment Options",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _paymentOption(
              icon: Icons.account_balance,
              title: "Bank Transfer",
            ),

            _paymentOption(
              icon: Icons.phone_android,
              title: "Mobile Money",
            ),
          ],
        ),
      ),
    );
  }

  // ================= CARD TILE =================
  Widget _cardTile({
    required String cardType,
    required String cardNumber,
    required String expiry,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [

          // Card Icon
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            child: const Icon(
              Icons.credit_card,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 15),

          // Card Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cardNumber,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "Expiry: $expiry",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Default",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= OTHER PAYMENT OPTION =================
  Widget _paymentOption({
    required IconData icon,
    required String title,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
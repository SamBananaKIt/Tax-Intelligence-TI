import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math';

void main() {
  runApp(const TaxIntelligenceApp());
}

class TaxIntelligenceApp extends StatelessWidget {
  const TaxIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tax Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1929), // Dark Navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Neon Blue
          secondary: Color(0xFFFFD700), // Gold
          surface: Color(0xFF102035), // Slightly lighter Navy
          background: Color(0xFF0A1929),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF172A46),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      home: const TaxCalculatorPage(),
    );
  }
}

class TaxCalculatorPage extends StatefulWidget {
  const TaxCalculatorPage({super.key});

  @override
  State<TaxCalculatorPage> createState() => _TaxCalculatorPageState();
}

class _TaxCalculatorPageState extends State<TaxCalculatorPage> {
  // Controllers for Income
  final _salaryController = TextEditingController();
  final _bonusController = TextEditingController();
  final _otherIncomeController = TextEditingController();

  // Controllers for Deductions
  final _ssoController = TextEditingController(); // Max 9,000
  final _eReceiptController = TextEditingController(); // Max 50,000
  final _insuranceController = TextEditingController(); // General + Health Max 100,000
  final _pensionGroupController = TextEditingController(); // Max 500,000
  final _thaiEsgController = TextEditingController(); // Max 100k or 30% of income

  double _totalIncome = 0;
  double _netTaxableIncome = 0;
  double _totalTax = 0;
  double _effectiveTaxRate = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    final controllers = [
      _salaryController,
      _bonusController,
      _otherIncomeController,
      _ssoController,
      _eReceiptController,
      _insuranceController,
      _pensionGroupController,
      _thaiEsgController,
    ];

    for (var controller in controllers) {
      controller.addListener(_calculateTax);
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _bonusController.dispose();
    _otherIncomeController.dispose();
    _ssoController.dispose();
    _eReceiptController.dispose();
    _insuranceController.dispose();
    _pensionGroupController.dispose();
    _thaiEsgController.dispose();
    super.dispose();
  }

  double _parseValue(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '')) ?? 0.0;
  }

  void _calculateTax() {
    setState(() {
      // 1. Income Calculation
      final salary = _parseValue(_salaryController);
      final bonus = _parseValue(_bonusController);
      final otherIncome = _parseValue(_otherIncomeController);
      
      final yearlySalary = salary * 12;
      _totalIncome = yearlySalary + bonus + otherIncome;

      // 2. Expenses Deduction
      // Rule: 50% of income but Max 100,000 THB
      double expenses = _totalIncome * 0.5;
      if (expenses > 100000) expenses = 100000;

      // 3. Deductions Calculation
      // 3.1 Personal Allowance (Fixed)
      const double personalAllowance = 60000;

      // 3.2 Social Security (Max 9,000)
      double sso = _parseValue(_ssoController);
      if (sso > 9000) sso = 9000;

      // 3.3 Easy E-Receipt (Max 50,000)
      double eReceipt = _parseValue(_eReceiptController);
      if (eReceipt > 50000) eReceipt = 50000;

      // 3.4 General & Health Insurance (Max 100,000 combined)
      double insurance = _parseValue(_insuranceController);
      if (insurance > 100000) insurance = 100000;

      // 3.5 Pension/SSF/RMF (Group capped at 500,000)
      double pensionGroup = _parseValue(_pensionGroupController);
      if (pensionGroup > 500000) pensionGroup = 500000;

      // 3.6 Thai ESG (Max 100,000 or 30% of income)
      double thaiEsg = _parseValue(_thaiEsgController);
      double maxThaiEsg = _totalIncome * 0.3;
      if (maxThaiEsg > 100000) maxThaiEsg = 100000;
      if (thaiEsg > maxThaiEsg) thaiEsg = maxThaiEsg;

      double totalDeductions = personalAllowance + sso + eReceipt + insurance + pensionGroup + thaiEsg;

      // 4. Net Taxable Income Calculation
      _netTaxableIncome = _totalIncome - expenses - totalDeductions;
      if (_netTaxableIncome < 0) _netTaxableIncome = 0;

      // 5. Tax Calculation (Progressive Rate)
      _totalTax = _calculateProgressiveTax(_netTaxableIncome);

      // 6. Effective Tax Rate
      _effectiveTaxRate = _totalIncome > 0 ? (_totalTax / _totalIncome) : 0.0;
    });
  }

  double _calculateProgressiveTax(double netIncome) {
    double tax = 0;

    // 0 - 150,000: Exempt
    if (netIncome <= 150000) return 0;

    // 150,001 - 300,000: 5%
    // Size of bracket: 150,000
    if (netIncome > 150000) {
      double taxableInBracket = min(netIncome - 150000, 150000);
      tax += taxableInBracket * 0.05;
    }

    // 300,001 - 500,000: 10%
    // Size of bracket: 200,000
    if (netIncome > 300000) {
      double taxableInBracket = min(netIncome - 300000, 200000);
      tax += taxableInBracket * 0.10;
    }

    // 500,001 - 750,000: 15%
    // Size of bracket: 250,000
    if (netIncome > 500000) {
      double taxableInBracket = min(netIncome - 500000, 250000);
      tax += taxableInBracket * 0.15;
    }

    // 750,001 - 1,000,000: 20%
    // Size of bracket: 250,000
    if (netIncome > 750000) {
      double taxableInBracket = min(netIncome - 750000, 250000);
      tax += taxableInBracket * 0.20;
    }

    // 1,000,001 - 2,000,000: 25%
    // Size of bracket: 1,000,000
    if (netIncome > 1000000) {
      double taxableInBracket = min(netIncome - 1000000, 1000000);
      tax += taxableInBracket * 0.25;
    }

    // 2,000,001 - 5,000,000: 30%
    // Size of bracket: 3,000,000
    if (netIncome > 2000000) {
      double taxableInBracket = min(netIncome - 2000000, 3000000);
      tax += taxableInBracket * 0.30;
    }

    // Over 5,000,000: 35%
    if (netIncome > 5000000) {
      double taxableInBracket = netIncome - 5000000;
      tax += taxableInBracket * 0.35;
    }

    return tax;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final currencyWithDecimals = NumberFormat("#,##0.00", "en_US");
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TAX INTELLIGENCE",
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFF00E5FF),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER VISUALIZATION ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  CircularPercentIndicator(
                    radius: 90.0,
                    lineWidth: 18.0,
                    percent: _totalIncome > 0 ? (_totalTax / _totalIncome).clamp(0.0, 1.0) : 0.0,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(_effectiveTaxRate * 100).toStringAsFixed(2)}%",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Effective Rate",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    progressColor: const Color(0xFFFFD700), // Gold
                    backgroundColor: const Color(0xFF172A46),
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 800,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- RESULT SUMMARY ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF172A46),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Total Income", currencyFormat.format(_totalIncome), const Color(0xFF00E5FF)),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSummaryRow("Net Taxable", currencyFormat.format(_netTaxableIncome), Colors.white),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSummaryRow("Total Tax", currencyWithDecimals.format(_totalTax), const Color(0xFFFFD700), isLarge: true),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- INPUT FORMS ---
            _buildSectionHeader("Financial Details"),
            const SizedBox(height: 10),
            
            // Income Section
            _buildExpansionGroup(
              title: "Source of Income", 
              icon: Icons.attach_money,
              children: [
                _buildInputField("Monthly Salary (x12)", _salaryController, "e.g. 50,000"),
                const SizedBox(height: 10),
                _buildInputField("Yearly Bonus", _bonusController, "e.g. 100,000"),
                const SizedBox(height: 10),
                _buildInputField("Other Income", _otherIncomeController, "Freelance, Business"),
              ]
            ),
            const SizedBox(height: 15),

            // Deductions Section
            _buildExpansionGroup(
              title: "Deductions & Allowances",
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildInfoRow("Personal Allowance", "Fixed 60,000 THB"),
                const SizedBox(height: 15),
                _buildInputField("Social Security (Max 9k)", _ssoController, "Amount paid"),
                const SizedBox(height: 10),
                _buildInputField("Easy E-Receipt (Max 50k)", _eReceiptController, "Shopping 2024"),
                const SizedBox(height: 10),
                _buildInputField("Life/Health Insurance (Max 100k)", _insuranceController, "Premium paid"),
                const SizedBox(height: 10),
                _buildInputField("Pension / RMF / SSF (Max 500k)", _pensionGroupController, "Investment total"),
                const SizedBox(height: 10),
                _buildInputField("Thai ESG (Max 100k)", _thaiEsgController, "Investment"),
              ]
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Tax Intelligence v1.0 • Thai Tax Year 2024",
                style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.prompt(
          color: const Color(0xFF00E5FF),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildExpansionGroup({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(icon, color: const Color(0xFFFFD700)),
          title: Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.white24),
            suffixText: "THB",
            suffixStyle: const TextStyle(color: Color(0xFF00E5FF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: isLarge ? 16 : 14,
            fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.prompt(
            color: valueColor,
            fontSize: isLarge ? 24 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(color: const Color(0xFF00E5FF), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

import 'dart:math';

class TaxLogic {
  /// Calculates the Total Tax based on Thai 2024 Progressive Rates
  static double calculateTax(double netTaxableIncome) {
    double tax = 0;

    // 0 - 150,000: Exempt
    if (netTaxableIncome <= 150000) return 0;

    // 150,001 - 300,000: 5% (Bracket size: 150,000)
    if (netTaxableIncome > 150000) {
      double taxableInBracket = min(netTaxableIncome - 150000, 150000);
      tax += taxableInBracket * 0.05;
    }

    // 300,001 - 500,000: 10% (Bracket size: 200,000)
    if (netTaxableIncome > 300000) {
      double taxableInBracket = min(netTaxableIncome - 300000, 200000);
      tax += taxableInBracket * 0.10;
    }

    // 500,001 - 750,000: 15% (Bracket size: 250,000)
    if (netTaxableIncome > 500000) {
      double taxableInBracket = min(netTaxableIncome - 500000, 250000);
      tax += taxableInBracket * 0.15;
    }

    // 750,001 - 1,000,000: 20% (Bracket size: 250,000)
    if (netTaxableIncome > 750000) {
      double taxableInBracket = min(netTaxableIncome - 750000, 250000);
      tax += taxableInBracket * 0.20;
    }

    // 1,000,001 - 2,000,000: 25% (Bracket size: 1,000,000)
    if (netTaxableIncome > 1000000) {
      double taxableInBracket = min(netTaxableIncome - 1000000, 1000000);
      tax += taxableInBracket * 0.25;
    }

    // 2,000,001 - 5,000,000: 30% (Bracket size: 3,000,000)
    if (netTaxableIncome > 2000000) {
      double taxableInBracket = min(netTaxableIncome - 2000000, 3000000);
      tax += taxableInBracket * 0.30;
    }

    // Over 5,000,000: 35%
    if (netTaxableIncome > 5000000) {
      double taxableInBracket = netTaxableIncome - 5000000;
      tax += taxableInBracket * 0.35;
    }

    return tax;
  }

  /// Calculates Net Taxable Income from inputs
  static double calculateNetTaxable({
    required double totalIncome,
    required double sso,
    required double eReceipt,
    required double insurance,
    required double pensionGroup,
    required double thaiEsg,
  }) {
    // 1. Expenses Deduction (50% max 100k)
    double expenses = totalIncome * 0.5;
    if (expenses > 100000) expenses = 100000;

    // 2. Personal Allowance
    const double personalAllowance = 60000;

    // 3. Deduction Limits Logic
    double finalSso = min(sso, 9000);
    double finalEReceipt = min(eReceipt, 50000);
    double finalInsurance = min(insurance, 100000);
    double finalPension = min(pensionGroup, 500000);
    
    // Thai ESG: Max 100k or 30% of income
    double maxThaiEsg = totalIncome * 0.3;
    if (maxThaiEsg > 100000) maxThaiEsg = 100000;
    double finalThaiEsg = min(thaiEsg, maxThaiEsg);

    double totalDeductions = personalAllowance + finalSso + finalEReceipt + finalInsurance + finalPension + finalThaiEsg;

    double net = totalIncome - expenses - totalDeductions;
    return net < 0 ? 0 : net;
  }
}

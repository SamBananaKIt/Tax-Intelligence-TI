import 'package:flutter_test/flutter_test.dart';
import 'package:tax_intelligence/tax_logic.dart';

void main() {
  group('Thai Tax 2024 Calculation Tests', () {
    test('Case 1: Standard Salary 50,000/mo (600k/year) - No Extra Deductions', () {
      // Income: 600,000
      // Expenses: 50% = 300,000 -> Max 100,000
      // Personal: 60,000
      // Net Taxable: 600k - 100k - 60k = 440,000
      
      final netTaxable = TaxLogic.calculateNetTaxable(
        totalIncome: 600000, 
        sso: 0, 
        eReceipt: 0, 
        insurance: 0, 
        pensionGroup: 0, 
        thaiEsg: 0
      );
      
      expect(netTaxable, 440000);

      final tax = TaxLogic.calculateTax(netTaxable);
      // Tax:
      // 0-150k: 0
      // 150k-300k (150k): 5% = 7,500
      // 300k-440k (140k): 10% = 14,000
      // Total: 21,500
      expect(tax, 21500);
    });

    test('Case 2: High Income (2M) with Deductions', () {
      // Income: 2,000,000
      // Expense: 100,000 (Max)
      // Personal: 60,000
      // SSO: 9,000
      // Insurance: 100,000
      // Deductions Total: 169,000 + 100,000 (Exp) = 269,000
      // Net: 1,731,000
      
      final netTaxable = TaxLogic.calculateNetTaxable(
        totalIncome: 2000000, 
        sso: 9000, 
        eReceipt: 0, 
        insurance: 100000, 
        pensionGroup: 0, 
        thaiEsg: 0
      );
      
      expect(netTaxable, 1731000);

      // Tax on 1,731,000
      // 0-150k: 0
      // 150-300k: 7,500
      // 300-500k: 20,000
      // 500-750k: 37,500
      // 750-1M: 50,000
      // 1M-1.731M (731k): 25% = 182,750
      // Total: 297,750
      final tax = TaxLogic.calculateTax(netTaxable);
      expect(tax, 297750);
    });

    test('Case 3: Exempt Income', () {
      // Income: 200,000
      // Expense: 100,000
      // Personal: 60,000
      // Net: 40,000 -> Tax 0
      final netTaxable = TaxLogic.calculateNetTaxable(
        totalIncome: 200000, 
        sso: 0, 
        eReceipt: 0, 
        insurance: 0, 
        pensionGroup: 0, 
        thaiEsg: 0
      );
      
      expect(netTaxable, 40000);
      expect(TaxLogic.calculateTax(netTaxable), 0);
    });
  });
}

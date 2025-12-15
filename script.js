// Utility to get Element by ID
const $ = (id) => document.getElementById(id);
const formatCurrency = (num) => new Intl.NumberFormat('en-US').format(num);

// Inputs
const inputs = ['salary', 'bonus', 'otherIncome', 'sso', 'eReceipt', 'insurance', 'pension', 'thaiEsg'];

// Core Logic (Re-implemented from Dart)
function calculateTax() {
    // 1. Get Values
    const getVal = (id) => parseFloat($(id).value) || 0;

    const salary = getVal('salary');
    const bonus = getVal('bonus');
    const otherIncome = getVal('otherIncome');
    
    // Total Income
    const totalIncome = (salary * 12) + bonus + otherIncome;

    // 2. Expenses (50% max 100k)
    let expenses = totalIncome * 0.5;
    if (expenses > 100000) expenses = 100000;

    // 3. Deductions
    const personalAllowance = 60000;
    
    let sso = getVal('sso');
    if (sso > 9000) sso = 9000;

    let eReceipt = getVal('eReceipt');
    if (eReceipt > 50000) eReceipt = 50000;

    let insurance = getVal('insurance');
    if (insurance > 100000) insurance = 100000;

    let pension = getVal('pension');
    if (pension > 500000) pension = 500000;

    let thaiEsg = getVal('thaiEsg');
    let maxThaiEsg = totalIncome * 0.3;
    if (maxThaiEsg > 100000) maxThaiEsg = 100000;
    if (thaiEsg > maxThaiEsg) thaiEsg = maxThaiEsg;

    const totalDeductions = personalAllowance + sso + eReceipt + insurance + pension + thaiEsg;

    // 4. Net Taxable
    let netTaxable = totalIncome - expenses - totalDeductions;
    if (netTaxable < 0) netTaxable = 0;

    // 5. Calculate Tax (Step-ladder)
    let tax = 0;
    
    // 0 - 150k
    // Exempt

    // 150 - 300k (5%)
    if (netTaxable > 150000) {
        tax += Math.min(netTaxable - 150000, 150000) * 0.05;
    }
    // 300 - 500k (10%)
    if (netTaxable > 300000) {
        tax += Math.min(netTaxable - 300000, 200000) * 0.10;
    }
    // 500 - 750k (15%)
    if (netTaxable > 500000) {
        tax += Math.min(netTaxable - 500000, 250000) * 0.15;
    }
    // 750 - 1M (20%)
    if (netTaxable > 750000) {
        tax += Math.min(netTaxable - 750000, 250000) * 0.20;
    }
    // 1M - 2M (25%)
    if (netTaxable > 1000000) {
        tax += Math.min(netTaxable - 1000000, 1000000) * 0.25;
    }
    // 2M - 5M (30%)
    if (netTaxable > 2000000) {
        tax += Math.min(netTaxable - 2000000, 3000000) * 0.30;
    }
    // > 5M (35%)
    if (netTaxable > 5000000) {
        tax += (netTaxable - 5000000) * 0.35;
    }

    // 6. Effective Rate
    const rate = totalIncome > 0 ? (tax / totalIncome) * 100 : 0;

    // Update UI
    $('displayTotalIncome').innerText = formatCurrency(totalIncome);
    $('displayNetTaxable').innerText = formatCurrency(netTaxable);
    $('displayTotalTax').innerText = formatCurrency(tax);
    $('effectiveRate').innerText = rate.toFixed(2) + '%';

    // Update Chart (Conic Gradient)
    // Gold (#FFD700) vs Navy (#172A46)
    // The percentage represents the TAX relative to income (for visual impact)
    // Or we can visualize Rate. Let's visualize Rate since it usually < 35%
    const degree = (rate / 35) * 360; // Scaling 35% to full circle for drama? Or just 100%? 
    // Let's do simple 0-100%
    const percent = Math.min(rate, 100);
    
    const chart = $('taxChart');
    chart.style.background = `conic-gradient(#FFD700 ${percent}%, #172A46 0%)`;
}

// Add Listeners
inputs.forEach(id => {
    const el = $(id);
    if(el) {
        el.addEventListener('input', calculateTax);
    }
});

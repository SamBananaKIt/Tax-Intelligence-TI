// Utility to get Element by ID
const $ = (id) => document.getElementById(id);
const formatCurrency = (num) => new Intl.NumberFormat('en-US').format(num);

// Inputs IDs
const inputs = [
    'salary', 'bonus', 'otherIncome',
    'sso', 'eReceipt',
    'homeLoan', 'insurance', 'pension', 'thaiEsg',
    'donationDouble', 'donationGeneral'
];

// Core Logic
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

    // 3. Deductions (Group 1: Pre-Donation)
    const personalAllowance = 60000;

    let sso = Math.min(getVal('sso'), 9000);
    let eReceipt = Math.min(getVal('eReceipt'), 50000);
    let homeLoan = Math.min(getVal('homeLoan'), 100000);
    let insurance = Math.min(getVal('insurance'), 100000);
    let pension = Math.min(getVal('pension'), 500000);

    let thaiEsgVal = getVal('thaiEsg');
    let maxThaiEsg = totalIncome * 0.3;
    if (maxThaiEsg > 100000) maxThaiEsg = 100000;
    let thaiEsg = Math.min(thaiEsgVal, maxThaiEsg);

    const generalDeductions = personalAllowance + sso + eReceipt + homeLoan + insurance + pension + thaiEsg;

    // 4. Net Income before Donation
    let netBeforeDonation = totalIncome - expenses - generalDeductions;
    if (netBeforeDonation < 0) netBeforeDonation = 0;

    // 5. Donation Logic (Max 10% of Net Income Before Donation)
    // Actually standard rule implies: Donation cap is 10% of (Assessable Income - Expenses - Deductions)
    // Double Donation (Edu/Sport) counts as 2x but total limit logic applies.

    // Simpler Algo for App: Check 10% Limit against actual Net Before Donation.
    const donationLimit = netBeforeDonation * 0.10;

    let donationDoubleInput = getVal('donationDouble');
    let donationGeneralInput = getVal('donationGeneral');

    // Calculate actual deductible amount
    // Logic: Double donation takes priority usually.
    let doubleDeductible = donationDoubleInput * 2;
    if (doubleDeductible > donationLimit) doubleDeductible = donationLimit;

    // Remaining limit for general
    let remainingLimit = donationLimit - doubleDeductible;
    let generalDeductible = Math.min(donationGeneralInput, remainingLimit);

    const totalDonationDeductible = doubleDeductible + generalDeductible;

    // 6. Final Net Taxable
    let netTaxable = netBeforeDonation - totalDonationDeductible;
    if (netTaxable < 0) netTaxable = 0;

    // 7. Calculate Tax (Step-ladder)
    let tax = 0;

    if (netTaxable > 150000) tax += Math.min(netTaxable - 150000, 150000) * 0.05;
    if (netTaxable > 300000) tax += Math.min(netTaxable - 300000, 200000) * 0.10;
    if (netTaxable > 500000) tax += Math.min(netTaxable - 500000, 250000) * 0.15;
    if (netTaxable > 750000) tax += Math.min(netTaxable - 750000, 250000) * 0.20;
    if (netTaxable > 1000000) tax += Math.min(netTaxable - 1000000, 1000000) * 0.25;
    if (netTaxable > 2000000) tax += Math.min(netTaxable - 2000000, 3000000) * 0.30;
    if (netTaxable > 5000000) tax += (netTaxable - 5000000) * 0.35;

    // 8. Effective Rate
    const rate = totalIncome > 0 ? (tax / totalIncome) * 100 : 0;

    // --- Animations & Updates ---

    // Animate Values
    animateValue('displayTotalIncome', totalIncome);
    animateValue('displayNetTaxable', netTaxable);
    animateValue('displayTotalTax', tax);

    // Update Mobile Sticky Bar
    animateValue('displayTotalTaxMobile', tax);

    // Rate update (Keep simple text for rate)
    $('effectiveRate').innerText = rate.toFixed(2) + '%';

    // Update Chart with Animation
    // Springer Green (#045149) vs Pale #BFDBDD
    const percent = Math.min(rate, 100);
    const chart = $('taxChart');
    chart.style.background = `conic-gradient(#045149 ${percent}%, #BFDBDD 0%)`;

    // Add Pulse visual
    chart.classList.remove('pulse-anim');
    void chart.offsetWidth; // Trigger reflow
    chart.classList.add('pulse-anim');
}

// Previous Value Storage for smooth transitions
const previousValues = {};

function animateValue(id, endValue) {
    const obj = $(id);
    if (!obj) return;

    const startValue = previousValues[id] || 0;
    if (startValue === endValue) return; // No change

    const duration = 500; // 0.5s
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);

        // Easing function (easeOutQuad)
        const ease = 1 - (1 - progress) * (1 - progress);

        const current = startValue + (endValue - startValue) * ease;

        obj.innerText = formatCurrency(Math.floor(current));

        if (progress < 1) {
            requestAnimationFrame(update);
        } else {
            previousValues[id] = endValue; // Store final
        }
    }
    requestAnimationFrame(update);
}

// Add Listeners
inputs.forEach(id => {
    const el = $(id);
    if (el) {
        el.addEventListener('input', calculateTax);
    }
});

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

    // 7. Calculate Tax (Step-ladder & Breakdown)
    let tax = 0;
    const brackets = [
        { limit: 150000, rate: 0.00 }, // 0 - 150k
        { limit: 300000, rate: 0.05 }, // 150k - 300k
        { limit: 500000, rate: 0.10 }, // 300k - 500k
        { limit: 750000, rate: 0.15 }, // 500k - 750k
        { limit: 1000000, rate: 0.20 }, // 750k - 1M
        { limit: 2000000, rate: 0.25 }, // 1M - 2M
        { limit: 5000000, rate: 0.30 }, // 2M - 5M
        { limit: Infinity, rate: 0.35 } // > 5M
    ];

    let taxDetails = [];
    let accumulatedTaxable = 0;
    let remainingTaxable = netTaxable;
    let prevLimit = 0;

    for (let i = 0; i < brackets.length; i++) {
        const bracket = brackets[i];
        const range = bracket.limit - prevLimit;

        let taxableInThisBracket = 0;
        let taxInThisBracket = 0;

        if (remainingTaxable > 0) {
            taxableInThisBracket = Math.min(remainingTaxable, range);
            taxInThisBracket = taxableInThisBracket * bracket.rate;

            remainingTaxable -= taxableInThisBracket;
            tax += taxInThisBracket;
        }

        taxDetails.push({
            range: `${formatCurrency(prevLimit + 1)} - ${bracket.limit === Infinity ? 'ขึ้นไป' : formatCurrency(bracket.limit)}`,
            rate: (bracket.rate * 100).toFixed(0),
            tax: taxInThisBracket,
            active: taxableInThisBracket > 0 // Highlight if tax/income falls here
        });

        prevLimit = bracket.limit;
    }

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
    const percent = Math.min(rate, 100);
    const chart = $('taxChart');
    chart.style.background = `conic-gradient(#045149 ${percent}%, #BFDBDD 0%)`;

    // Add Pulse visual
    chart.classList.remove('pulse-anim');
    void chart.offsetWidth; // Trigger reflow
    chart.classList.add('pulse-anim');

    // Update Modal Data (if open or for future click)
    updateMakeTaxTable(taxDetails, netTaxable);
}

// Helper: Update Table
function updateMakeTaxTable(details, netTaxable) {
    const tbody = $('taxTableBody');
    if (!tbody) return;

    $('modalNetTaxable').innerText = formatCurrency(netTaxable);

    let html = '';
    details.forEach(d => {
        const isActive = d.active ? 'class="bracket-active"' : '';
        html += `
            <tr ${isActive}>
                <td>${d.range}</td>
                <td>${d.rate}%</td>
                <td>${formatCurrency(d.tax)}</td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
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

// --- Modal Logic ---
const modal = $('taxModal');
const btnShow = $('btnShowDetails');
const btnShowMobile = $('btnShowDetailsMobile');
const btnClose = document.querySelector('.close-modal');

if (btnShow) btnShow.onclick = () => { modal.style.display = "flex"; };
if (btnShowMobile) btnShowMobile.onclick = () => { modal.style.display = "flex"; };
if (btnClose) btnClose.onclick = () => { modal.style.display = "none"; };

// Close when clicking outside
window.onclick = (event) => {
    if (event.target == modal) {
        modal.style.display = "none";
    }
}

// --- Auto-Save System ---
function saveToLocal() {
    const data = {};
    inputs.forEach(id => {
        const el = $(id);
        if (el) data[id] = el.value;
    });
    localStorage.setItem('taxData_v1', JSON.stringify(data));
}

function loadFromLocal() {
    const saved = localStorage.getItem('taxData_v1');
    if (!saved) return;

    try {
        const data = JSON.parse(saved);
        Object.keys(data).forEach(id => {
            const el = $(id);
            if (el) el.value = data[id];
        });
        // Recalculate after loading
        calculateTax();
    } catch (e) {
        console.error("Error loading save:", e);
    }
}

// Add Listeners
inputs.forEach(id => {
    const el = $(id);
    if (el) {
        el.addEventListener('input', () => {
            calculateTax();
            saveToLocal(); // Auto-save on every input
        });
    }
});

// Initialize
window.addEventListener('DOMContentLoaded', () => {
    loadFromLocal();
});

// Register Service Worker (PWA)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('./sw.js')
            .then(reg => console.log('SW Registered!', reg.scope))
            .catch(err => console.log('SW Error:', err));
    });
}

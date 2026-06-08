#!/bin/bash
set -e
echo "🔧 Razorpay Frontend Integration"

node << 'EOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/dashboard/store/page.tsx';
let c = fs.readFileSync(file, 'utf-8');

// ── 1: Add Razorpay type declaration ──
const rzpTypeDecl = `// Razorpay types
declare global { interface Window { Razorpay: any; } }
`;
if (!c.includes('Window { Razorpay')) {
  c = rzpTypeDecl + c;
  console.log('✅ Razorpay type declaration added');
}

// ── 2: Add loadRazorpayScript utility ──
const loadScriptFn = `
// Load Razorpay checkout script
const loadRazorpayScript = (): Promise<boolean> => {
  return new Promise(resolve => {
    if (typeof window === 'undefined') return resolve(false);
    if (window.Razorpay) return resolve(true);
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};
`;
if (!c.includes('loadRazorpayScript')) {
  // Add before export default
  c = c.replace('export default function StorePage()', loadScriptFn + '\nexport default function StorePage()');
  console.log('✅ loadRazorpayScript added');
}

// ── 3: Replace placeOrder with Razorpay-aware version ──
const oldPlaceOrder = /const placeOrder = async \(\) => \{[\s\S]*?\};[\n\r]/;

const newPlaceOrder = `const placeOrder = async () => {
    setPlacing(true);
    try {
      if (payM === 'COD') {
        // ── COD flow ──
        const r = await fetch(\`\${API}/api/store/orders/create\`, {
          method: 'POST', headers: hdr(),
          body: JSON.stringify({ shippingAddress: addr, paymentMethod: 'COD', buyerNotes }),
        });
        const d = await r.json();
        if (r.ok) {
          T(\`Order placed! \${d.orderId} 🎉\`);
          setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
          setStep(0); loadOrders(); setView('orders');
        } else { T(d.message, 'error'); }
      } else {
        // ── Razorpay (UPI / Card / NetBanking) flow ──
        const loaded = await loadRazorpayScript();
        if (!loaded) { T('Razorpay failed to load. Check internet.', 'error'); setPlacing(false); return; }

        // Step 1: Create Razorpay order on backend
        const r = await fetch(\`\${API}/api/store/payment/create-order\`, {
          method: 'POST', headers: hdr(), body: JSON.stringify({}),
        });
        const payData = await r.json();
        if (!r.ok) { T(payData.message || 'Payment initiation failed', 'error'); setPlacing(false); return; }

        // Step 2: Open Razorpay checkout
        const options = {
          key:       payData.key || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID,
          amount:    payData.amount,
          currency:  payData.currency || 'INR',
          order_id:  payData.order_id,
          name:      'ProveRank Store',
          description: 'Study Material Purchase',
          image:     'https://prove-rank.vercel.app/favicon.ico',
          prefill: {
            name:    addr.fullName,
            contact: addr.phone,
          },
          theme: { color: '#2563eb' },
          modal: {
            ondismiss: () => {
              T('Payment cancelled', 'info');
              setPlacing(false);
            },
          },
          handler: async (response: any) => {
            // Step 3: Verify payment & create order
            try {
              const vr = await fetch(\`\${API}/api/store/payment/verify\`, {
                method: 'POST', headers: hdr(),
                body: JSON.stringify({
                  razorpay_order_id:   response.razorpay_order_id,
                  razorpay_payment_id: response.razorpay_payment_id,
                  razorpay_signature:  response.razorpay_signature,
                  shippingAddress:     addr,
                  buyerNotes,
                }),
              });
              const vd = await vr.json();
              if (vr.ok && vd.success) {
                T(\`Payment successful! Order: \${vd.orderId} 🎉\`);
                setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
                setStep(0); loadOrders(); setView('orders');
              } else {
                T(vd.message || 'Payment verification failed', 'error');
              }
            } catch (err) {
              T('Order creation failed after payment. Contact support.', 'error');
            }
            setPlacing(false);
          },
        };

        const rzp = new window.Razorpay(options);
        rzp.on('payment.failed', (resp: any) => {
          T(\`Payment failed: \${resp.error?.description || 'Unknown error'}\`, 'error');
          setPlacing(false);
        });
        rzp.open();
        return; // placing will be set false in handler
      }
    } catch (e) {
      T('Something went wrong. Try again.', 'error');
    }
    setPlacing(false);
  };
`;

if (c.includes('const placeOrder = async')) {
  c = c.replace(oldPlaceOrder, newPlaceOrder);
  console.log('✅ placeOrder replaced with Razorpay-aware version');
} else {
  console.log('⚠️  placeOrder not found — manual replacement needed');
}

// ── 4: Update payment method options ──
// Change UPI button text to include "Card / NetBanking"
c = c.replace(
  `{id:'UPI',label:'UPI Payment',desc:'GPay, PhonePe, Paytm',icon:'📱'}`,
  `{id:'UPI',label:'UPI / Card / NetBanking',desc:'GPay, PhonePe, Paytm, Visa, Mastercard',icon:'💳'}`
);
console.log('✅ Payment method label updated');

fs.writeFileSync(file, c);
console.log('✅ Frontend Razorpay integration complete');
EOF

cd ~/workspace
git add frontend/app/dashboard/store/page.tsx
git commit -m "feat: Razorpay checkout integration in student store"
git push origin main

echo ""
echo "══════════════════════════════════════════"
echo "✅ RAZORPAY FRONTEND DONE!"
echo ""
echo "Payment flow:"
echo "  COD  → Direct order → My Orders ✅"
echo "  UPI/Card → Razorpay modal → Pay → Verify → My Orders ✅"
echo ""
echo "⚠️  ENV VARS ZARURI HAIN:"
echo "  Render  → RAZORPAY_KEY_ID + RAZORPAY_KEY_SECRET"
echo "  Vercel  → NEXT_PUBLIC_RAZORPAY_KEY_ID"
echo "══════════════════════════════════════════"

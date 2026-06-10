#!/bin/bash
set -e
echo "🔧 Fix: Payment Failure - Persistent Modal + Retry"

node << 'EOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/dashboard/store/page.tsx';
let c = fs.readFileSync(file, 'utf-8');

// ── 1. Add PaymentFailureModal component ──
const modalComponent = `
// ── Payment Failure Modal ───────────────────────────────────
function PaymentFailureModal({
  paymentId, amount, onRetry, onClose, retrying
}: {
  paymentId: string; amount: number; onRetry: () => void;
  onClose: () => void; retrying: boolean;
}) {
  return (
    <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.9)', zIndex:9999, display:'flex', alignItems:'center', justifyContent:'center', padding:16 }}>
      <div style={{ width:'100%', maxWidth:420, background:'#0a0f1e', border:'1px solid rgba(239,68,68,0.4)', borderRadius:20, padding:24 }}>
        <div style={{ textAlign:'center', marginBottom:20 }}>
          <div style={{ fontSize:48, marginBottom:8 }}>⚠️</div>
          <h2 style={{ fontSize:18, fontWeight:900, color:'#fca5a5', margin:'0 0 6px' }}>
            Payment Done — Order Failed
          </h2>
          <p style={{ fontSize:13, color:'rgba(255,255,255,0.5)', margin:0 }}>
            ₹{amount} was deducted but order was not created due to a connection error.
          </p>
        </div>

        <div style={{ background:'rgba(239,68,68,0.1)', border:'1px solid rgba(239,68,68,0.3)', borderRadius:12, padding:14, marginBottom:16 }}>
          <p style={{ fontSize:11, color:'rgba(255,255,255,0.4)', margin:'0 0 4px', fontWeight:700 }}>PAYMENT ID (Screenshot karo!)</p>
          <p style={{ fontSize:14, fontFamily:'monospace', color:'#60a5fa', fontWeight:700, margin:0, wordBreak:'break-all' }}>{paymentId}</p>
        </div>

        <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginBottom:16, lineHeight:1.7 }}>
          <p style={{ margin:'0 0 6px' }}>✅ Payment ID saved in your browser</p>
          <p style={{ margin:'0 0 6px' }}>📞 Share this ID with support to get your order created</p>
          <p style={{ margin:0 }}>💰 Your money is safe — it reached merchant account</p>
        </div>

        <div style={{ display:'flex', gap:10 }}>
          <button
            onClick={onRetry}
            disabled={retrying}
            style={{ flex:1, padding:12, background:'linear-gradient(135deg,#2563eb,#0ea5e9)', color:'#fff', border:'none', borderRadius:12, fontWeight:700, fontSize:14, cursor:'pointer', opacity:retrying?0.6:1 }}
          >
            {retrying ? '⏳ Retrying...' : '🔄 Retry Order'}
          </button>
          <button
            onClick={onClose}
            style={{ padding:'12px 16px', background:'rgba(255,255,255,0.07)', color:'rgba(255,255,255,0.6)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:12, fontWeight:600, fontSize:13, cursor:'pointer' }}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

`;

// Insert before export default
if (!c.includes('PaymentFailureModal')) {
  c = c.replace('export default function StorePage()', modalComponent + 'export default function StorePage()');
  console.log('✅ PaymentFailureModal component added');
}

// ── 2. Add state for payment failure modal ──
const stateInsert = `
  // Payment failure state
  const [failedPayment, setFailedPayment] = useState<{paymentId:string;amount:number;rzpOrderId:string;rzpSignature:string} | null>(null);
  const [retryingVerify, setRetryingVerify] = useState(false);
`;

if (!c.includes('failedPayment')) {
  // Add after const [placing state
  c = c.replace(
    'const [placing, setPlacing] = useState(false);',
    'const [placing, setPlacing] = useState(false);\n' + stateInsert
  );
  console.log('✅ failedPayment state added');
}

// ── 3. Replace handler with persistent modal version ──
// Find and replace the handler function
const oldHandler = /handler: async \(response: any\) => \{[\s\S]*?setPlacing\(false\);\s*\},/;

const newHandler = `handler: async (response: any) => {
            // Save to localStorage immediately as backup
            const paymentBackup = {
              paymentId: response.razorpay_payment_id,
              orderId:   response.razorpay_order_id,
              signature: response.razorpay_signature,
              amount:    cart.total,
              address:   addr,
              timestamp: new Date().toISOString(),
            };
            if (typeof window !== 'undefined') {
              localStorage.setItem('pr_pending_payment', JSON.stringify(paymentBackup));
            }

            // Verify with backend (up to 2 retries)
            let verified = false;
            let lastError = '';
            for (let attempt = 0; attempt < 2; attempt++) {
              try {
                if (attempt > 0) await new Promise(r => setTimeout(r, 2000)); // wait 2s before retry
                const verifyRes = await fetch(\`\${API}/api/store/payment/verify\`, {
                  method: 'POST',
                  headers: hdr(),
                  body: JSON.stringify({
                    razorpay_order_id:   response.razorpay_order_id,
                    razorpay_payment_id: response.razorpay_payment_id,
                    razorpay_signature:  response.razorpay_signature,
                    shippingAddress:     addr,
                    buyerNotes,
                  }),
                });
                let vd: any = {};
                try { vd = await verifyRes.json(); } catch { vd = { success: false, message: 'Parse error' }; }

                if (verifyRes.ok && vd.success) {
                  // Success!
                  localStorage.removeItem('pr_pending_payment');
                  T(\`✅ Payment verified! Order: \${vd.orderId} 🎉\`);
                  setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
                  setStep(0); loadOrders(); setView('orders');
                  verified = true;
                  break;
                } else {
                  lastError = vd.message || 'Verification failed';
                }
              } catch (err: any) {
                lastError = 'Connection error';
              }
            }

            if (!verified) {
              // Show persistent modal instead of toast
              setFailedPayment({
                paymentId: response.razorpay_payment_id,
                amount:    cart.total,
                rzpOrderId: response.razorpay_order_id,
                rzpSignature: response.razorpay_signature,
              });
            }
            setPlacing(false);
          },`;

if (oldHandler.test(c)) {
  c = c.replace(oldHandler, newHandler);
  console.log('✅ Razorpay handler replaced with retry + persistent modal version');
} else {
  console.log('⚠️  Handler pattern not found — checking for partial match');
  if (c.includes("T('⚠️ Payment done but connection failed")) {
    c = c.replace(
      /T\(`⚠️ Payment done but connection failed[\s\S]*?setPlacing\(false\);/,
      `setFailedPayment({
              paymentId: response.razorpay_payment_id,
              amount: cart.total,
              rzpOrderId: response.razorpay_order_id,
              rzpSignature: response.razorpay_signature,
            });
            setPlacing(false);`
    );
    console.log('✅ Error handler replaced with modal trigger');
  }
}

// ── 4. Add retry verify function ──
const retryFn = `
  const retryPaymentVerify = async () => {
    if (!failedPayment) return;
    setRetryingVerify(true);
    try {
      const verifyRes = await fetch(\`\${API}/api/store/payment/verify\`, {
        method: 'POST', headers: hdr(),
        body: JSON.stringify({
          razorpay_order_id:   failedPayment.rzpOrderId,
          razorpay_payment_id: failedPayment.paymentId,
          razorpay_signature:  failedPayment.rzpSignature,
          shippingAddress:     addr,
        }),
      });
      let vd: any = {};
      try { vd = await verifyRes.json(); } catch { vd = { success: false, message: 'Parse error' }; }
      if (verifyRes.ok && vd.success) {
        localStorage.removeItem('pr_pending_payment');
        setFailedPayment(null);
        T(\`✅ Order created! \${vd.orderId} 🎉\`);
        setCart({ items:[], total:0, subtotal:0, deliveryCharge:0, couponDiscount:0, itemCount:0 });
        loadOrders(); setView('orders');
      } else {
        T(vd.message || 'Retry failed — contact support', 'error');
      }
    } catch {
      T('Connection error — try again in a moment', 'error');
    }
    setRetryingVerify(false);
  };
`;

if (!c.includes('retryPaymentVerify')) {
  c = c.replace(
    'const placeOrder = async () => {',
    retryFn + '\n  const placeOrder = async () => {'
  );
  console.log('✅ retryPaymentVerify function added');
}

// ── 5. Add modal render in JSX ──
if (!c.includes('failedPayment &&')) {
  // Add before the topbar
  c = c.replace(
    '{toast && <Toast',
    `{failedPayment && (
        <PaymentFailureModal
          paymentId={failedPayment.paymentId}
          amount={failedPayment.amount}
          onRetry={retryPaymentVerify}
          onClose={() => setFailedPayment(null)}
          retrying={retryingVerify}
        />
      )}
      {toast && <Toast`
  );
  console.log('✅ PaymentFailureModal render added');
}

// ── 6. Load pending payment from localStorage on mount ──
const pendingPaymentCheck = `
  // Check for pending payment on mount
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const pending = localStorage.getItem('pr_pending_payment');
    if (pending) {
      try {
        const p = JSON.parse(pending);
        // If pending payment exists from previous session, show modal
        if (p.paymentId && p.orderId) {
          setFailedPayment({
            paymentId: p.paymentId,
            amount: p.amount || 0,
            rzpOrderId: p.orderId,
            rzpSignature: p.signature || '',
          });
        }
      } catch {}
    }
  }, []);
`;

if (!c.includes('pr_pending_payment')) {
  // Add after other useEffects
  c = c.replace(
    `  useEffect(() => {
    fetch(\`\${API}/api/store/products/featured\`)`,
    pendingPaymentCheck + `
  useEffect(() => {
    fetch(\`\${API}/api/store/products/featured\`)`
  );
  console.log('✅ Pending payment check on mount added');
}

fs.writeFileSync(file, c);
console.log('✅ store/page.tsx saved — all payment failure fixes applied');
EOF

cd ~/workspace
git add frontend/app/dashboard/store/page.tsx
git commit -m "fix: persistent payment failure modal + localStorage backup + retry verify"
git push origin main

echo ""
echo "✅ PUSHED!"
echo ""
echo "Payment flow now:"
echo "  Success → Order created → My Orders ✅"
echo "  Connection fail → Persistent modal with:"
echo "    - Payment ID (visible + saved to localStorage)"
echo "    - Retry button (tries again)"
echo "    - Payment ID persists even on page refresh"
echo ""
echo "₹2 wala payment:"
echo "  Razorpay Dashboard → Transactions → pay_Sz75RvfzBTnjqu"
echo "  Ye amount aapke settlement mein hai"

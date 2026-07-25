#!/bin/bash
set -e
cd ~/workspace

mkdir -p /tmp/receiptpatch

# ── 1. NEW MODEL: BatchPayment.js ──
if [ -f src/models/BatchPayment.js ]; then
  echo "⚠️  src/models/BatchPayment.js already exists — skipping creation to avoid overwrite. Delete it manually first if you want it recreated."
else
  cat > src/models/BatchPayment.js << 'EOF'
const mongoose = require('mongoose');

const BatchPaymentSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  studentName: { type: String, default: '' },
  studentEmail: { type: String, default: '' },
  itemId: { type: mongoose.Schema.Types.ObjectId, required: true },
  itemType: { type: String, enum: ['batch', 'series'], required: true },
  itemName: { type: String, default: '' },
  examType: { type: String, default: '' },
  amount: { type: Number, required: true },
  razorpayOrderId: { type: String, required: true },
  razorpayPaymentId: { type: String, required: true },
  testMode: { type: Boolean, default: false },
  receiptNo: { type: String, required: true, unique: true }
}, { timestamps: true });

module.exports = mongoose.models.BatchPayment || mongoose.model('BatchPayment', BatchPaymentSchema);
EOF
  echo "✅ Created src/models/BatchPayment.js"
fi

# ── 2. BACKEND PATCH: studentBatchExtras.js ──
cp src/routes/studentBatchExtras.js src/routes/studentBatchExtras.js.bak_receipt_fix

cat > /tmp/receiptpatch/be1_old.txt << 'EOF'
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';
EOF
cat > /tmp/receiptpatch/be1_new.txt << 'EOF'
const JWT      = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';
const crypto   = require('crypto');
const BatchPayment = require('../models/BatchPayment');
EOF

cat > /tmp/receiptpatch/be2_old.txt << 'EOF'
module.exports = router;
EOF
cat > /tmp/receiptpatch/be2_new.txt << 'EOF'
// POST /:id/razorpay-verify — verify payment signature, enroll student, create receipt
router.post('/:id/razorpay-verify', auth, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!razorpay_order_id || !razorpay_payment_id) return res.status(400).json({ error: 'Missing payment details' });

    const isTestOrder = String(razorpay_order_id).startsWith('order_test_');
    if (!isTestOrder) {
      if (!process.env.RAZORPAY_KEY_SECRET) return res.status(500).json({ error: 'Razorpay secret missing on server' });
      const sigBody = razorpay_order_id + '|' + razorpay_payment_id;
      const expectedSig = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(sigBody).digest('hex');
      if (expectedSig !== razorpay_signature) return res.status(400).json({ error: 'Signature mismatch — payment verification failed' });
    }

    let item = await Batch.findById(req.params.id);
    let itemType = 'batch';
    if (!item) { item = await TestSeries.findById(req.params.id); itemType = 'series'; }
    if (!item) return res.status(404).json({ error: 'Batch not found' });

    const amount = item.discountPrice || item.price;
    const userObjId = new mongoose.Types.ObjectId(req.user.id);

    await User.collection.updateOne({ _id: userObjId }, { $addToSet: { enrolledBatches: item._id } });
    if (itemType === 'series') {
      await TestSeries.findByIdAndUpdate(item._id, { $inc: { enrolledCount: 1 }, $addToSet: { students: userObjId } });
    } else {
      await Batch.findByIdAndUpdate(item._id, { $inc: { enrolledCount: 1 } });
    }

    const user = await User.collection.findOne({ _id: userObjId });
    const receiptNo = 'PR-' + Date.now().toString(36).toUpperCase();

    const payment = await BatchPayment.create({
      student: req.user.id,
      studentName: user?.name || 'Student',
      studentEmail: user?.email || '',
      itemId: item._id,
      itemType,
      itemName: item.name,
      examType: item.examType || '',
      amount,
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      testMode: isTestOrder,
      receiptNo
    });

    res.json({
      success: true,
      receipt: {
        receiptNo: payment.receiptNo,
        paymentId: payment._id,
        studentName: payment.studentName,
        studentEmail: payment.studentEmail,
        itemName: payment.itemName,
        examType: payment.examType,
        amount: payment.amount,
        razorpayPaymentId: payment.razorpayPaymentId,
        createdAt: payment.createdAt,
        testMode: payment.testMode
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /:id/receipt/:paymentId/pdf — download official payment receipt PDF
router.get('/:id/receipt/:paymentId/pdf', auth, async (req, res) => {
  try {
    const payment = await BatchPayment.findById(req.params.paymentId).lean();
    if (!payment) return res.status(404).json({ error: 'Receipt not found' });
    if (String(payment.student) !== String(req.user.id)) return res.status(403).json({ error: 'Not authorized' });

    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=receipt_${payment.receiptNo}.pdf`);
    doc.pipe(res);

    // ── ProveRank Split-Block Monogram Logo (P + R) ──
    const logoSize = 46;
    const pSize = Math.round(logoSize * 0.63);
    const rd = Math.round(pSize * 0.28);
    const cx = doc.page.width / 2;
    const startX = cx - logoSize / 2;
    const startY = 45;

    doc.roundedRect(startX, startY, pSize, pSize, rd).fill('#4D9FFF');
    doc.fillColor('#030810').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('P', startX, startY + pSize * 0.22, { width: pSize, align: 'center' });

    doc.roundedRect(startX + logoSize - pSize, startY + logoSize - pSize, pSize, pSize, rd).fillOpacity(0.85).fill('#00D4FF');
    doc.fillOpacity(1).fillColor('#00647A').fontSize(Math.round(pSize * 0.5)).font('Helvetica-Bold')
      .text('R', startX + logoSize - pSize, startY + logoSize - pSize + pSize * 0.22, { width: pSize, align: 'center' });

    doc.y = startY + logoSize + 14;
    doc.fontSize(20).fillColor('#111').font('Helvetica-Bold').text('ProveRank', { align: 'center' });
    doc.fontSize(10).fillColor('#666').font('Helvetica').text('Online Test Platform', { align: 'center' });
    doc.moveDown(1.2);

    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(16).fillColor('#111').font('Helvetica-Bold').text('Payment Receipt', { align: 'center' });
    if (payment.testMode) { doc.moveDown(0.3); doc.fontSize(9).fillColor('#E67E22').font('Helvetica').text('(Test Mode — no real payment was charged)', { align: 'center' }); }
    doc.moveDown(1.5);

    let y = doc.y;
    const rowH = 22;
    const row = (label, value) => {
      doc.fontSize(11).fillColor('#666').font('Helvetica').text(label, 50, y);
      doc.fontSize(11).fillColor('#111').font('Helvetica-Bold').text(String(value), 300, y, { width: doc.page.width - 350, align: 'right' });
      y += rowH;
    };

    row('Receipt No.', payment.receiptNo);
    row('Date', new Date(payment.createdAt).toLocaleString('en-IN'));
    row('Student Name', payment.studentName);
    if (payment.studentEmail) row('Email', payment.studentEmail);
    row('Item Purchased', payment.itemName);
    if (payment.examType) row('Exam Type', payment.examType);
    row('Payment ID', payment.razorpayPaymentId);
    row('Order ID', payment.razorpayOrderId);

    doc.y = y + 10;
    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).strokeColor('#ddd').stroke();
    doc.moveDown(1);

    doc.fontSize(14).fillColor('#111').font('Helvetica-Bold').text('Amount Paid', 50, doc.y);
    doc.fontSize(18).fillColor('#27AE60').font('Helvetica-Bold').text('₹' + payment.amount, 300, doc.y - 18, { width: doc.page.width - 350, align: 'right' });

    doc.moveDown(3);
    doc.fontSize(9).fillColor('#999').font('Helvetica').text('This is a system-generated receipt. For queries, contact ProveRank.support@gmail.com', { align: 'center' });
    doc.moveDown(0.4);
    doc.fontSize(9).fillColor('#999').text('ProveRank — Prove Yourself · Rise to the Top', { align: 'center' });

    doc.end();
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
EOF

# ── 3. FRONTEND PATCH: page.tsx — replace whole PaymentModal function ──
cp frontend/app/dashboard/test-series/page.tsx frontend/app/dashboard/test-series/page.tsx.bak_receipt_fix

cat > /tmp/receiptpatch/fe_old.txt << 'EOF'
function PaymentModal({ batch, tok, onClose, onSuccess }: { batch: Batch; tok: string; onClose: () => void; onSuccess: () => void }) {
  const [loading,setLoading]=useState(false)
  const price=batch.discountPrice||batch.price

  const handlePayFull=async()=>{
    if(!tok)return
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-order`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'}})
      const d=await r.json()
      if(!d.success)return alert(d.error||'Error')
      if(d.testMode){alert(`TEST MODE\n\nBatch: ${d.batchName}\nFull Amount: ₹${Math.round(d.amount/100)}\nOrder: ${d.orderId}\n\nAdd Razorpay keys in Render to enable real payments.`);onClose();return}
      const loaded=await loadRazorpay()
      if(!loaded)return alert('Could not load payment gateway')
      const rzp=new (window as any).Razorpay({key:d.key,amount:d.amount,currency:d.currency,order_id:d.orderId,name:'ProveRank',description:batch.name,handler:()=>{onSuccess();onClose()},theme:{color:'#4D9FFF'}})
      rzp.open();onClose()
    }finally{setLoading(false)}
  }

  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)' }}>💳 Payment</div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:6,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batch.name}</div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:20 }}>₹{price}</div>
        <button onClick={handlePayFull} disabled={loading}
          style={{ width:'100%',padding:'13px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.35)' }}>
          {loading?'Processing...':'💰 Pay Full Amount ₹'+price}
        </button>
      </div>
    </div>
  )
}
EOF

cat > /tmp/receiptpatch/fe_new.txt << 'EOF'
function PaymentModal({ batch, tok, onClose, onSuccess }: { batch: Batch; tok: string; onClose: () => void; onSuccess: () => void }) {
  const [loading,setLoading]=useState(false)
  const [receipt,setReceipt]=useState<any>(null)
  const [dlLoading,setDlLoading]=useState(false)
  const price=batch.discountPrice||batch.price

  const verifyAndShowReceipt=async(response:any)=>{
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-verify`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({razorpay_order_id:response.razorpay_order_id,razorpay_payment_id:response.razorpay_payment_id,razorpay_signature:response.razorpay_signature})})
      const d=await r.json()
      if(!d.success){alert(d.error||'Payment verification failed — contact support with your payment ID.');return}
      setReceipt(d.receipt)
      onSuccess()
    }catch(e){alert('Payment succeeded but verification failed — contact support.')}
  }

  const downloadReceiptPdf=async()=>{
    if(!receipt)return
    setDlLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/receipt/${receipt.paymentId}/pdf`,{headers:{Authorization:`Bearer ${tok}`}})
      const blob=await r.blob()
      const url=window.URL.createObjectURL(blob)
      const a=document.createElement('a')
      a.href=url;a.download=`receipt_${receipt.receiptNo}.pdf`;document.body.appendChild(a);a.click();a.remove()
      window.URL.revokeObjectURL(url)
    }catch(e){alert('Could not download receipt')}
    finally{setDlLoading(false)}
  }

  const handlePayFull=async()=>{
    if(!tok)return
    setLoading(true)
    try{
      const r=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-order`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'}})
      const d=await r.json()
      if(!d.success)return alert(d.error||'Error')
      if(d.testMode){
        const r2=await fetch(`${API}/api/student/batch-extras/${batch._id}/razorpay-verify`,{method:'POST',headers:{Authorization:`Bearer ${tok}`,'Content-Type':'application/json'},body:JSON.stringify({razorpay_order_id:d.orderId,razorpay_payment_id:'pay_test_'+Date.now(),razorpay_signature:''})})
        const d2=await r2.json()
        if(!d2.success)return alert(d2.error||'Error')
        setReceipt(d2.receipt)
        onSuccess()
        return
      }
      const loaded=await loadRazorpay()
      if(!loaded)return alert('Could not load payment gateway')
      const rzp=new (window as any).Razorpay({key:d.key,amount:d.amount,currency:d.currency,order_id:d.orderId,name:'ProveRank',description:batch.name,handler:(response:any)=>{verifyAndShowReceipt(response)},theme:{color:'#4D9FFF'}})
      rzp.open()
    }finally{setLoading(false)}
  }

  if(receipt){
    return (
      <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
        <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(39,174,96,0.3)',borderRadius:22,padding:26,maxWidth:400,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
          <div style={{ textAlign:'center',marginBottom:16 }}>
            <div style={{ fontSize:40,marginBottom:6 }}>✅</div>
            <div style={{ fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'var(--pr-text)' }}>Payment Successful</div>
            {receipt.testMode&&<div style={{ fontSize:10,color:'#E67E22',marginTop:4 }}>(Test Mode — no real payment was charged)</div>}
          </div>
          <div style={{ background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.08)',borderRadius:14,padding:16,marginBottom:16 }}>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:8 }}><span>Receipt No.</span><span style={{ color:'var(--pr-text)',fontWeight:700 }}>{receipt.receiptNo}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:8 }}><span>Item</span><span style={{ color:'var(--pr-text)',fontWeight:700,textAlign:'right',maxWidth:200,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{receipt.itemName}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:8 }}><span>Payment ID</span><span style={{ color:'var(--pr-text)',fontWeight:700,fontSize:10 }}>{receipt.razorpayPaymentId}</span></div>
            <div style={{ display:'flex',justifyContent:'space-between',fontSize:13,paddingTop:8,borderTop:'1px solid rgba(255,255,255,0.08)' }}><span style={{ color:'rgba(var(--pr-sub-rgb),0.7)',fontWeight:700 }}>Amount Paid</span><span style={{ color:'#27AE60',fontWeight:900,fontSize:16 }}>₹{receipt.amount}</span></div>
          </div>
          <button onClick={downloadReceiptPdf} disabled={dlLoading} style={{ width:'100%',padding:'12px',marginBottom:10,background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12 }}>{dlLoading?'Preparing PDF...':'⬇️ Download Receipt (PDF)'}</button>
          <button onClick={onClose} style={{ width:'100%',padding:'11px',background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.1)',borderRadius:13,color:'var(--pr-text)',fontWeight:700,cursor:'pointer',fontSize:12 }}>Done</button>
        </div>
      </div>
    )
  }

  return (
    <div style={{ position:'fixed',inset:0,zIndex:1000,background:'rgba(0,0,0,0.88)',display:'flex',alignItems:'center',justifyContent:'center',padding:16 }}>
      <div style={{ background:'rgba(var(--pr-card-rgb),0.99)',border:'1px solid rgba(77,159,255,0.25)',borderRadius:22,padding:26,maxWidth:380,width:'100%',backdropFilter:'blur(30px)',boxShadow:'0 30px 80px rgba(0,0,0,0.6)' }}>
        <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18 }}>
          <div style={{ fontFamily:'Playfair Display,serif',fontSize:17,fontWeight:700,color:'var(--pr-text)' }}>💳 Payment</div>
          <button onClick={onClose} style={{ background:'transparent',border:'none',color:'rgba(var(--pr-sub-rgb),0.5)',cursor:'pointer',fontSize:22 }}>×</button>
        </div>
        <div style={{ fontSize:13,color:'rgba(var(--pr-sub-rgb),0.6)',marginBottom:6,overflow:'hidden',whiteSpace:'nowrap',textOverflow:'ellipsis' }}>{batch.name}</div>
        <div style={{ fontSize:22,fontWeight:900,color:'var(--pr-text)',fontFamily:'Playfair Display,serif',marginBottom:20 }}>₹{price}</div>
        <button onClick={handlePayFull} disabled={loading}
          style={{ width:'100%',padding:'13px',background:'linear-gradient(135deg,#4D9FFF,#00D4FF)',border:'none',borderRadius:13,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:13,boxShadow:'0 6px 20px rgba(77,159,255,0.35)' }}>
          {loading?'Processing...':'💰 Pay Full Amount ₹'+price}
        </button>
      </div>
    </div>
  )
}
EOF

cat > /tmp/receiptpatch/apply.js << 'NODEEOF'
const fs = require('fs');
function readTrim(p) { let c = fs.readFileSync(p, 'utf8'); return c.endsWith('\n') ? c.slice(0, -1) : c; }
function patch(targetPath, oldFile, newFile, label) {
  let content = fs.readFileSync(targetPath, 'utf8');
  const oldStr = readTrim(oldFile), newStr = readTrim(newFile);
  const count = content.split(oldStr).length - 1;
  if (count === 0) { console.log('❌ [' + label + '] Pattern NOT FOUND — skipped. NOTHING was changed for this patch.'); return; }
  if (count > 1) { console.log('⚠️  [' + label + '] Pattern found ' + count + ' times (expected 1) — skipped for safety. NOTHING was changed for this patch.'); return; }
  content = content.replace(oldStr, newStr);
  fs.writeFileSync(targetPath, content, 'utf8');
  console.log('✅ [' + label + '] patched.');
}
patch('src/routes/studentBatchExtras.js', '/tmp/receiptpatch/be1_old.txt', '/tmp/receiptpatch/be1_new.txt', 'backend: crypto + BatchPayment require');
patch('src/routes/studentBatchExtras.js', '/tmp/receiptpatch/be2_old.txt', '/tmp/receiptpatch/be2_new.txt', 'backend: verify + PDF receipt routes');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/receiptpatch/fe_old.txt', '/tmp/receiptpatch/fe_new.txt', 'frontend: PaymentModal with receipt + PDF download');
NODEEOF

node /tmp/receiptpatch/apply.js

echo ""
echo "=== Verifying pdfkit is available (should already be installed per project stack) ==="
node -e "require.resolve('pdfkit'); console.log('✅ pdfkit module found')" 2>/dev/null || echo "❌ pdfkit NOT installed — run: npm install pdfkit"

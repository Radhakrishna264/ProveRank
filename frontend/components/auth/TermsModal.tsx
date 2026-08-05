'use client'
import { motion, AnimatePresence } from 'framer-motion'
import { X, ShieldCheck } from 'lucide-react'
import { Button } from '@/components/ui/button'

const SECTIONS: [string, string][] = [
  ['1. Exam Rules & Conduct', 'Students must attempt exams in a quiet, well-lit environment. Any form of cheating, including using external resources, sharing questions, or impersonating another student, will result in immediate disqualification and permanent account ban.'],
  ['2. Privacy Policy', 'We collect your name, email, and exam data solely for platform operation. Webcam snapshots during proctoring are used only for AI-based monitoring and automatically deleted within 24 hours. We never share your data with third parties.'],
  ['3. Proctoring Policy', 'By starting any exam you consent to: (a) webcam access for AI facial monitoring, (b) tab-switch tracking, (c) IP logging. Three warnings result in automatic exam submission.'],
  ['4. Result & Ranking Policy', 'All India Ranks are based on score then time. Results are final unless an Answer Key Challenge is filed within 48 hours. Re-evaluation processed within 7 working days.'],
  ['5. Account & Access Policy', 'Each account is for individual use only. New device login automatically signs out previous device. Sharing credentials is prohibited.'],
  ['6. Refund & Payment Policy', 'All purchases are non-refundable once access is granted. Technical failure credits added to account. Disputes must be raised within 7 days.'],
  ['7. Data Security & AI Monitoring', 'All data is encrypted. Our AI analyses video in real-time without storing identity beyond the exam session. We never sell data to advertisers.'],
  ['8. Grievance Redressal', 'Contact support@proverank.com for complaints. We respond within 48 hours and resolve within 7 working days.'],
]

export default function TermsModal({ open, onClose, onAccept }: { open: boolean; onClose: () => void; onAccept: () => void }) {
  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 z-[999] flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 12 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.95, y: 8 }}
            transition={{ duration: 0.25, ease: 'easeOut' }}
            onClick={e => e.stopPropagation()}
            className="flex max-h-[82vh] w-full max-w-[540px] flex-col overflow-hidden rounded-[22px] border border-white/12 bg-[#00101F]/95 shadow-[0_20px_70px_rgba(0,0,0,0.7)] backdrop-blur-2xl"
          >
            <div className="flex flex-shrink-0 items-center justify-between border-b border-white/10 px-6 py-4">
              <div className="flex items-center gap-2.5">
                <ShieldCheck className="h-5 w-5 text-[#4D9FFF]" />
                <div>
                  <div className="text-[15px] font-bold text-[#E8F4FF]">Terms & Conditions</div>
                  <div className="text-[11px] text-[#4D9FFF]">Version 2.1 — Updated March 2026</div>
                </div>
              </div>
              <button onClick={onClose} className="rounded-lg p-1.5 text-[#6B8BAF] hover:bg-white/5 hover:text-[#E8F4FF]">
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-6 py-4">
              {SECTIONS.map(([title, body]) => (
                <div key={title} className="mb-3 rounded-xl border border-white/8 bg-white/[0.02] px-4 py-3">
                  <div className="mb-1.5 text-[13px] font-bold text-[#E8F4FF]">{title}</div>
                  <div className="text-[12px] leading-relaxed text-[#8FA8C4]">{body}</div>
                </div>
              ))}
            </div>

            <div className="flex flex-shrink-0 gap-3 border-t border-white/10 px-6 py-4">
              <Button onClick={onAccept} className="flex-1">✓ I Accept All Terms</Button>
              <Button variant="outline" onClick={onClose}>Close</Button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

'use client'
import { ReactNode } from "react"
import { motion } from "framer-motion"
import PRLogo from "@/components/PRLogo"
import AuroraBackground from "@/components/auth/AuroraBackground"

interface Step { label: string }
interface Props { steps?: Step[]; current?: number; children: ReactNode }

const FEATURES: [string, string][] = [
  ["🎯", "Multi Exam Platform"],
  ["🤖", "AI Proctoring"],
  ["👨‍🏫", "Designed By Experts"],
  ["📊", "Deep AI Analytics"],
  ["🏆", "All India Ranking"],
  ["⚡", "Instant Results"],
]

export default function PremiumAuthShell({ steps = [], current = 0, children }: Props) {
  const hasSteps = steps.length > 1

  return (
    <div className="relative min-h-screen text-[#E8F4FF]">
      <AuroraBackground />

      <div className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-white/10 bg-[#00060F]/80 px-4 backdrop-blur-xl lg:hidden">
        <div className="flex items-center gap-2">
          <PRLogo size={26} />
          <span className="font-semibold text-[15px] tracking-tight text-[#E8F4FF]">ProveRank</span>
        </div>
        {hasSteps && (
          <div className="flex items-center gap-1.5">
            {steps.map((_, i) => (
              <span key={i} className={`h-1.5 rounded-full transition-all duration-300 ${i === current ? "w-5 bg-[#4D9FFF]" : "w-1.5 bg-white/15"}`} />
            ))}
          </div>
        )}
      </div>

      <div className="mx-auto flex min-h-screen max-w-[1400px]">
        <div className="relative hidden w-[42%] flex-col justify-between overflow-hidden p-12 lg:flex">
          <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }} className="flex items-center gap-3">
            <PRLogo size={40} />
            <div>
              <div className="text-xl font-bold tracking-tight text-[#E8F4FF]">ProveRank</div>
              <div className="text-xs font-medium text-[#6B8BAF]">Rise to the Top</div>
            </div>
          </motion.div>

          <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.1 }} className="max-w-md">
            <h1 className="text-[2.4rem] font-bold leading-[1.15] tracking-tight text-[#E8F4FF]">
              Prove yourself.<br />
              <span className="bg-gradient-to-r from-[#4D9FFF] to-[#00D4FF] bg-clip-text text-transparent">Rank nationwide.</span>
            </h1>
            <p className="mt-4 text-[15px] leading-relaxed text-[#8FA8C4]">
              India's most advanced multi-exam test platform — AI proctoring, live rankings, and deep performance analytics in one place.
            </p>
          </motion.div>

          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.6, delay: 0.25 }} className="grid grid-cols-2 gap-3">
            {FEATURES.map(([icon, label]) => (
              <div key={label} className="flex items-center gap-2.5 rounded-xl border border-white/8 bg-white/[0.02] px-3.5 py-3 backdrop-blur-sm">
                <span className="text-base">{icon}</span>
                <span className="text-xs font-medium text-[#B8CCE8]">{label}</span>
              </div>
            ))}
          </motion.div>

          <div className="pointer-events-none absolute -right-10 top-1/3 h-40 w-40 rounded-[30%] border border-[#4D9FFF]/15" style={{ transform: "rotate(18deg)" }} />
          <div className="pointer-events-none absolute right-16 bottom-24 h-24 w-24 rounded-full border border-[#00D4FF]/15" />
        </div>

        <div className="flex flex-1 flex-col lg:flex-row">
          {hasSteps && (
            <div className="hidden w-44 flex-shrink-0 flex-col gap-1 py-12 pl-8 lg:flex">
              {steps.map((s, i) => {
                const active = i === current, done = i < current
                return (
                  <div key={i} className={`flex items-center gap-2.5 rounded-xl px-3 py-2.5 transition-colors ${active ? "bg-[#4D9FFF]/10" : ""}`}>
                    <div className={`flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full text-[10px] font-bold transition-colors ${
                      done ? "bg-[#4D9FFF] text-[#00101F]" : active ? "border border-[#4D9FFF] bg-[#4D9FFF]/15 text-[#4D9FFF]" : "border border-white/15 bg-white/[0.02] text-[#6B8BAF]"
                    }`}>
                      {done ? "✓" : i + 1}
                    </div>
                    <span className={`text-[13px] ${active ? "font-semibold text-[#E8F4FF]" : "text-[#6B8BAF]"}`}>{s.label}</span>
                  </div>
                )
              })}
            </div>
          )}

          <div className="flex flex-1 items-center justify-center px-5 py-10 lg:px-10">
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, ease: "easeOut" }}
              className="w-full max-w-[420px]"
            >
              {children}
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}

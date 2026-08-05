'use client'
import { motion } from "framer-motion"

export default function AuroraBackground() {
  const particles = Array.from({ length: 14 })
  return (
    <div className="fixed inset-0 -z-10 overflow-hidden bg-[#00060F]">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(77,159,255,0.16),transparent_55%),radial-gradient(ellipse_at_bottom_right,rgba(0,212,255,0.12),transparent_55%)]" />
      <motion.div
        className="absolute -top-32 -left-32 h-[520px] w-[520px] rounded-full bg-[#4D9FFF]/25 blur-[120px]"
        animate={{ x: [0, 40, 0], y: [0, 30, 0] }}
        transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute top-1/3 -right-40 h-[460px] w-[460px] rounded-full bg-[#00D4FF]/20 blur-[130px]"
        animate={{ x: [0, -30, 0], y: [0, 40, 0] }}
        transition={{ duration: 22, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute bottom-[-160px] left-1/4 h-[420px] w-[420px] rounded-full bg-[#4D9FFF]/10 blur-[130px]"
        animate={{ x: [0, 30, 0], y: [0, -25, 0] }}
        transition={{ duration: 25, repeat: Infinity, ease: "easeInOut" }}
      />
      {particles.map((_, i) => (
        <motion.span
          key={i}
          className="absolute h-1 w-1 rounded-full bg-[#9CC5FF]/50"
          style={{ left: `${(i * 37) % 100}%`, top: `${(i * 53) % 100}%` }}
          animate={{ opacity: [0.15, 0.6, 0.15], y: [0, -14, 0] }}
          transition={{ duration: 4 + (i % 5), repeat: Infinity, ease: "easeInOut", delay: i * 0.3 }}
        />
      ))}
      <div
        className="absolute inset-0 opacity-[0.03] mix-blend-overlay"
        style={{ backgroundImage: "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")" }}
      />
    </div>
  )
}

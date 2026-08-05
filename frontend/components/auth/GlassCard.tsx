'use client'
import { ReactNode } from "react"
import { motion } from "framer-motion"
import { cn } from "@/lib/utils"

export default function GlassCard({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.4, ease: "easeOut" }}
      className={cn(
        "rounded-[22px] border border-white/10 bg-white/[0.035] p-7 backdrop-blur-2xl shadow-[0_8px_40px_rgba(0,0,0,0.55)] sm:p-8",
        className
      )}
    >
      {children}
    </motion.div>
  )
}

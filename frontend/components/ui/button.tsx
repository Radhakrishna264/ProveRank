'use client'
import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "relative inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-2xl text-sm font-semibold transition-all duration-200 ease-out disabled:pointer-events-none disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4D9FFF]/50 active:scale-[0.98]",
  {
    variants: {
      variant: {
        default: "bg-gradient-to-r from-[#4D9FFF] to-[#00D4FF] text-[#00101F] shadow-[0_4px_20px_rgba(77,159,255,0.35)] hover:shadow-[0_6px_28px_rgba(77,159,255,0.5)] hover:-translate-y-0.5",
        outline: "border border-white/15 bg-white/[0.02] text-[#E8F4FF] hover:bg-white/[0.06] hover:border-white/25",
        ghost: "text-[#9CC5FF] hover:bg-white/[0.05]",
        social: "border border-white/12 bg-white/[0.03] text-[#E8F4FF] hover:bg-white/[0.07] hover:border-white/20",
      },
      size: {
        default: "h-12 px-6",
        sm: "h-10 px-4 text-sm",
        lg: "h-14 px-8 text-base",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, loading, disabled, children, ...props }, ref) => (
    <button
      ref={ref}
      className={cn(buttonVariants({ variant, size }), className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Loader2 className="h-4 w-4 animate-spin" />}
      {children}
    </button>
  )
)
Button.displayName = "Button"

export { Button, buttonVariants }

'use client'
import * as React from "react"
import { cn } from "@/lib/utils"
import { Eye, EyeOff, Check, AlertCircle } from "lucide-react"

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  success?: boolean
  icon?: React.ReactNode
  isPassword?: boolean
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, success, icon, isPassword, type, id, ...props }, ref) => {
    const [show, setShow] = React.useState(false)
    const inputId = id || label?.replace(/\s+/g, '-').toLowerCase()
    const inputType = isPassword ? (show ? 'text' : 'password') : type

    return (
      <div className="w-full">
        <div className="relative">
          {icon && (
            <div className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[#6B8BAF]">
              {icon}
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            type={inputType}
            placeholder=" "
            className={cn(
              "peer w-full rounded-xl border bg-white/[0.03] px-4 pt-5 pb-2 text-[15px] text-[#E8F4FF] outline-none transition-all duration-200 placeholder-transparent",
              "border-white/12 focus:border-[#4D9FFF]/60 focus:bg-white/[0.05] focus:shadow-[0_0_0_4px_rgba(77,159,255,0.12)]",
              icon && "pl-11",
              isPassword && "pr-11",
              error && "border-[#FF4757]/60 focus:border-[#FF4757]/70 focus:shadow-[0_0_0_4px_rgba(255,71,87,0.12)]",
              success && "border-[#00C48C]/60",
              className
            )}
            {...props}
          />
          {label && (
            <label
              htmlFor={inputId}
              className={cn(
                "pointer-events-none absolute left-4 text-[#6B8BAF] transition-all duration-200",
                icon && "left-11",
                "top-1/2 -translate-y-1/2 text-[15px]",
                "peer-focus:top-3 peer-focus:translate-y-0 peer-focus:text-xs peer-focus:text-[#4D9FFF]",
                "peer-[:not(:placeholder-shown)]:top-3 peer-[:not(:placeholder-shown)]:translate-y-0 peer-[:not(:placeholder-shown)]:text-xs"
              )}
            >
              {label}
            </label>
          )}
          {isPassword && (
            <button
              type="button"
              tabIndex={-1}
              onClick={() => setShow((s) => !s)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#6B8BAF] hover:text-[#E8F4FF] transition-colors"
            >
              {show ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          )}
          {!isPassword && success && (
            <Check className="absolute right-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-[#00C48C]" />
          )}
        </div>
        {error && (
          <p className="mt-1.5 flex items-center gap-1 text-xs text-[#FF6B7A]">
            <AlertCircle className="h-3 w-3" /> {error}
          </p>
        )}
      </div>
    )
  }
)
Input.displayName = "Input"

export { Input }

import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'ProveRank – India\'s Most Advanced NEET Test Platform',
  description: 'ProveRank: NEET pattern online test platform with live rankings, AI analytics, anti-cheat monitoring and detailed performance analysis.',
  keywords: 'NEET online test, ProveRank, mock test, NEET preparation, ranking',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body suppressHydrationWarning>{children}</body>
    </html>
  )
}

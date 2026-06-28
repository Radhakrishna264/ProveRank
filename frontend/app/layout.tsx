import 'katex/dist/katex.min.css'
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
        {/* Theme init — runs before paint to prevent flash */}
        <script dangerouslySetInnerHTML={{__html:`
          (function(){
            try {
              var t = localStorage.getItem('pr_theme') || 'dark';
              var cls = t === 'light' ? 'light-theme' : t === 'aurora' ? 'aurora-theme' : 'dark-theme';
              document.documentElement.classList.add(cls);
              document.documentElement.setAttribute('data-theme', t);
            } catch(e) {
              document.documentElement.classList.add('dark-theme');
            }
          })();
        `}}/>
      </head>
      <body suppressHydrationWarning className="dark-theme" id="pr-body">
        {children}
      </body>
    </html>
  )
}
// deploy trigger Sun May 17 02:43:34 PM UTC 2026
// deploy Sun May 17 03:55:06 PM UTC 2026
// deploy
// deploy Sat May 23 11:33:23 AM UTC 2026

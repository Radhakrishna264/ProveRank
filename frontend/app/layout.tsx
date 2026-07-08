import 'katex/dist/katex.min.css'
import type { Metadata } from 'next'
import './globals.css'
import ThemeWatcher from './ThemeWatcher'

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
        {/* Theme init — runs before paint to prevent flash. Only 2 themes now: light / dark (legacy white/teal values are migrated). */}
        <script dangerouslySetInnerHTML={{__html:`
          (function(){
            try {
              var raw = localStorage.getItem('pr_color_theme') || 'dark';
              var ct = raw;
              if (raw === 'white') ct = 'light';
              else if (raw === 'teal') ct = 'dark';
              if (ct !== 'light' && ct !== 'dark') ct = 'dark';
              var h = document.documentElement;
              h.classList.remove('white-theme','dark-theme','teal-theme','light-theme');
              h.classList.add(ct + '-theme');
              h.setAttribute('data-color-theme', ct);
            } catch(e) {
              document.documentElement.classList.add('dark-theme');
            }
          })();
        `}}/>
      </head>
      <body suppressHydrationWarning>
        <ThemeWatcher />
        {children}
      </body>
    </html>
  )
}
// deploy trigger Sun May 17 02:43:34 PM UTC 2026
// deploy Sun May 17 03:55:06 PM UTC 2026
// deploy
// deploy Sat May 23 11:33:23 AM UTC 2026

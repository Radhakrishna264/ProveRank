import type { Config } from "tailwindcss";
const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        pr: {
          bg:      "#000A18",
          card:    "#001628",
          primary: "#4D9FFF",
          border:  "#002D55",
          text:    "#E8F4FF",
          muted:   "#9CA3AF",
          accent:  "#00CFFF",
        },
      },
      fontFamily: {
        heading: ["Georgia", "Playfair Display", "serif"],
        body:    ["Inter", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // EXPO to WORLD Brand Colors
        brand: {
          red: '#EE3432',
          'red-dark': '#B82025',
          'red-darker': '#7A1619',
          'red-light': '#FF5252',
          'red-bg': '#FCE8E8',
        },
        // Extended palette from brand guidelines
        accent: {
          blue: '#0066CC',
          'blue-dark': '#004B91',
          yellow: '#FFC107',
          green: '#107C10',
          purple: '#6A1B9A',
          cyan: '#00BCD4',
        },
      },
      fontFamily: {
        sans: ['Manrope', 'Source Han Sans SC', 'ui-sans-serif', 'system-ui', '-apple-system', 'sans-serif'],
        chinese: ['Source Han Sans SC', 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', 'sans-serif'],
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'float-slow': 'float 8s ease-in-out infinite',
        'float-shapes': 'floatShapes 20s linear infinite',
        'aurora': 'auroraMove 30s ease-in-out infinite alternate',
        'grid-move': 'gridMove 60s linear infinite',
        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        floatShapes: {
          '0%': { transform: 'translateY(100vh) rotate(0deg)', opacity: '0' },
          '10%': { opacity: '0.03' },
          '90%': { opacity: '0.03' },
          '100%': { transform: 'translateY(-100vh) rotate(360deg)', opacity: '0' },
        },
        auroraMove: {
          '0%': { transform: 'translateX(-10%) rotate(0deg)' },
          '100%': { transform: 'translateX(10%) rotate(2deg)' },
        },
        gridMove: {
          '0%': { transform: 'translate(0, 0)' },
          '100%': { transform: 'translate(50px, 50px)' },
        },
      },
      backdropBlur: {
        xs: '2px',
      },
    },
  },
  plugins: [],
}

import { useTranslation } from 'react-i18next';

/**
 * Home Page - EXPO to WORLD Company Landing Page
 * Recreates the premium design from website_sample.html with company content
 */
const Home = () => {
  const { t } = useTranslation();

  return (
    <div className="relative">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="relative mx-auto max-w-7xl px-6 pt-20 pb-16 lg:pt-32 lg:pb-24">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            {/* Hero Content */}
            <div className="space-y-8">
              {/* Tagline Badge */}
              <div className="inline-flex items-center gap-3 rounded-full border border-brand-red/30 bg-brand-red/10 glass-effect px-4 py-2 text-sm text-brand-red-light shadow-xl">
                <span className="inline-flex h-2 w-2 rounded-full bg-brand-red animate-pulse"></span>
                <span className="font-medium">{t('hero.tagline')}</span>
              </div>
              
              {/* Main Title */}
              <h1 className="text-5xl sm:text-6xl lg:text-7xl tracking-tight font-bold leading-[0.9]">
                <span className="gradient-text">
                  {t('hero.title')}
                </span>
              </h1>
              
              {/* Subtitle */}
              <p className="text-xl sm:text-2xl text-brand-red-light font-semibold">
                {t('hero.subtitle')}
              </p>
              
              {/* Description */}
              <p className="text-zinc-400 text-lg sm:text-xl max-w-xl leading-relaxed">
                {t('hero.description')}
              </p>
              
              {/* CTA Buttons */}
              <div className="flex flex-col sm:flex-row gap-4 pt-4">
                <a 
                  href="#features" 
                  className="group inline-flex items-center justify-center gap-3 bg-brand-red text-white rounded-xl px-8 py-4 text-base font-semibold hover:bg-brand-red-dark hover:scale-[1.02] transition-all duration-300 shadow-lg hover:shadow-xl"
                >
                  <span>{t('hero.cta')}</span>
                  <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                  </svg>
                </a>
                <a 
                  href="#values" 
                  className="group inline-flex items-center justify-center gap-3 rounded-xl bg-zinc-900/60 glass-effect border border-zinc-800/60 text-zinc-200 px-8 py-4 text-base font-semibold hover:bg-zinc-900/80 hover:scale-[1.02] transition-all duration-300 shadow-lg"
                >
                  <span>{t('common.learnMore')}</span>
                </a>
              </div>
            </div>

            {/* Hero Visual */}
            <div className="relative">
              <div className="relative aspect-square rounded-3xl overflow-hidden border border-zinc-800/60 shadow-2xl bg-zinc-900/40 glass-effect animate-float">
                {/* Abstract visual representing the platform */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="relative">
                    {/* Central Logo */}
                    <div className="w-32 h-32 rounded-2xl bg-gradient-to-br from-brand-red to-brand-red-dark flex items-center justify-center shadow-2xl">
                      <span className="text-5xl font-bold text-white">E</span>
                    </div>
                    
                    {/* Orbiting Elements */}
                    <div className="absolute -top-8 -right-8 w-16 h-16 rounded-xl bg-gradient-to-br from-accent-blue to-accent-blue-dark flex items-center justify-center text-white font-bold animate-float" style={{ animationDelay: '-1s' }}>
                      B
                    </div>
                    <div className="absolute -bottom-8 -left-8 w-16 h-16 rounded-xl bg-gradient-to-br from-accent-green to-green-600 flex items-center justify-center text-white font-bold animate-float" style={{ animationDelay: '-2s' }}>
                      C
                    </div>
                    <div className="absolute -top-8 -left-12 w-14 h-14 rounded-xl bg-gradient-to-br from-accent-yellow to-yellow-500 flex items-center justify-center text-zinc-900 font-bold animate-float" style={{ animationDelay: '-3s' }}>
                      U
                    </div>
                    <div className="absolute -bottom-8 -right-12 w-14 h-14 rounded-xl bg-gradient-to-br from-accent-purple to-purple-600 flex items-center justify-center text-white font-bold animate-float" style={{ animationDelay: '-4s' }}>
                      X
                    </div>
                  </div>
                </div>
                <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent"></div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section - Business Model */}
      <section id="features" className="relative mx-auto max-w-7xl px-6 py-20">
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl tracking-tight font-bold gradient-text mb-4">
            {t('features.title')}
          </h2>
          <p className="text-zinc-400 text-lg max-w-2xl mx-auto">
            {t('features.subtitle')}
          </p>
        </div>
        
        <div className="grid sm:grid-cols-2 gap-8">
          {/* EXPO to WORLD to B */}
          <div className="group relative rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect hover:bg-zinc-900/60 hover:scale-[1.02] transition-all duration-500 overflow-hidden shadow-xl p-8">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-accent-blue to-accent-blue-dark flex items-center justify-center text-white font-bold flex-shrink-0">
                B
              </div>
              <div>
                <h3 className="text-xl font-semibold text-zinc-100">{t('features.toB.title')}</h3>
                <p className="text-brand-red-light text-sm font-medium">{t('features.toB.subtitle')}</p>
              </div>
            </div>
            <p className="text-zinc-400 leading-relaxed">
              {t('features.toB.description')}
            </p>
          </div>

          {/* EXPO to WORLD to C */}
          <div className="group relative rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect hover:bg-zinc-900/60 hover:scale-[1.02] transition-all duration-500 overflow-hidden shadow-xl p-8">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-accent-green to-green-600 flex items-center justify-center text-white font-bold flex-shrink-0">
                C
              </div>
              <div>
                <h3 className="text-xl font-semibold text-zinc-100">{t('features.toC.title')}</h3>
                <p className="text-brand-red-light text-sm font-medium">{t('features.toC.subtitle')}</p>
              </div>
            </div>
            <p className="text-zinc-400 leading-relaxed">
              {t('features.toC.description')}
            </p>
          </div>

          {/* EXPO to WORLD to U */}
          <div className="group relative rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect hover:bg-zinc-900/60 hover:scale-[1.02] transition-all duration-500 overflow-hidden shadow-xl p-8">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-accent-yellow to-yellow-500 flex items-center justify-center text-zinc-900 font-bold flex-shrink-0">
                U
              </div>
              <div>
                <h3 className="text-xl font-semibold text-zinc-100">{t('features.toU.title')}</h3>
                <p className="text-brand-red-light text-sm font-medium">{t('features.toU.subtitle')}</p>
              </div>
            </div>
            <p className="text-zinc-400 leading-relaxed">
              {t('features.toU.description')}
            </p>
          </div>

          {/* EXPO to WORLD to X */}
          <div className="group relative rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect hover:bg-zinc-900/60 hover:scale-[1.02] transition-all duration-500 overflow-hidden shadow-xl p-8">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-accent-purple to-purple-600 flex items-center justify-center text-white font-bold flex-shrink-0">
                X
              </div>
              <div>
                <h3 className="text-xl font-semibold text-zinc-100">{t('features.toX.title')}</h3>
                <p className="text-brand-red-light text-sm font-medium">{t('features.toX.subtitle')}</p>
              </div>
            </div>
            <p className="text-zinc-400 leading-relaxed">
              {t('features.toX.description')}
            </p>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section id="values" className="relative mx-auto max-w-7xl px-6 py-20">
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl tracking-tight font-bold gradient-text mb-4">
            {t('values.title')}
          </h2>
        </div>
        
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Manufacturer Direct */}
          <div className="group flex flex-col items-center text-center p-6 rounded-2xl border border-zinc-800/40 bg-zinc-900/30 glass-effect hover:bg-zinc-900/50 transition-all duration-300">
            <div className="p-4 rounded-2xl bg-zinc-800/60 glass-effect mb-4 group-hover:scale-110 transition-transform duration-300">
              <svg className="w-8 h-8 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <h4 className="text-lg font-semibold tracking-tight mb-2 text-zinc-100">{t('values.manufacturer.title')}</h4>
            <p className="text-zinc-400 text-sm">{t('values.manufacturer.description')}</p>
          </div>

          {/* Technology */}
          <div className="group flex flex-col items-center text-center p-6 rounded-2xl border border-zinc-800/40 bg-zinc-900/30 glass-effect hover:bg-zinc-900/50 transition-all duration-300">
            <div className="p-4 rounded-2xl bg-zinc-800/60 glass-effect mb-4 group-hover:scale-110 transition-transform duration-300">
              <svg className="w-8 h-8 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <h4 className="text-lg font-semibold tracking-tight mb-2 text-zinc-100">{t('values.technology.title')}</h4>
            <p className="text-zinc-400 text-sm">{t('values.technology.description')}</p>
          </div>

          {/* Global Reach */}
          <div className="group flex flex-col items-center text-center p-6 rounded-2xl border border-zinc-800/40 bg-zinc-900/30 glass-effect hover:bg-zinc-900/50 transition-all duration-300">
            <div className="p-4 rounded-2xl bg-zinc-800/60 glass-effect mb-4 group-hover:scale-110 transition-transform duration-300">
              <svg className="w-8 h-8 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h4 className="text-lg font-semibold tracking-tight mb-2 text-zinc-100">{t('values.global.title')}</h4>
            <p className="text-zinc-400 text-sm">{t('values.global.description')}</p>
          </div>

          {/* Savings */}
          <div className="group flex flex-col items-center text-center p-6 rounded-2xl border border-zinc-800/40 bg-zinc-900/30 glass-effect hover:bg-zinc-900/50 transition-all duration-300">
            <div className="p-4 rounded-2xl bg-zinc-800/60 glass-effect mb-4 group-hover:scale-110 transition-transform duration-300">
              <svg className="w-8 h-8 text-brand-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h4 className="text-lg font-semibold tracking-tight mb-2 text-zinc-100">{t('values.savings.title')}</h4>
            <p className="text-zinc-400 text-sm">{t('values.savings.description')}</p>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative mx-auto max-w-7xl px-6 pb-20">
        <div className="relative overflow-hidden rounded-3xl border border-brand-red/30 bg-gradient-to-br from-brand-red/10 to-zinc-900/40 glass-effect shadow-2xl">
          <div className="absolute inset-0 bg-gradient-to-r from-zinc-900/60 via-transparent to-zinc-900/30"></div>
          <div className="relative p-10 sm:p-12 lg:p-16 text-center">
            <h3 className="text-3xl sm:text-4xl lg:text-5xl tracking-tight font-bold gradient-text mb-4">
              {t('cta.title')}
            </h3>
            <p className="text-zinc-400 text-lg max-w-2xl mx-auto mb-8">
              {t('cta.description')}
            </p>
            <a 
              href="mailto:contact@expotoworld.com" 
              className="group inline-flex items-center gap-3 rounded-xl bg-brand-red text-white px-8 py-4 text-base font-bold hover:bg-brand-red-dark hover:scale-105 transition-all duration-300 shadow-lg hover:shadow-xl"
            >
              <span>{t('cta.button')}</span>
              <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </a>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;

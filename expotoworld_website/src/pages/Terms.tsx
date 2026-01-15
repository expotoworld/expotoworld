import { useTranslation } from 'react-i18next';

/**
 * Terms of Service Page
 * Required for Stripe compliance - Minimal version for informational website
 */
const Terms = () => {
  const { t } = useTranslation();

  return (
    <div className="relative min-h-screen">
      <div className="relative mx-auto max-w-4xl px-6 py-20 lg:py-32">
        <div className="mb-12">
          <h1 className="text-4xl sm:text-5xl tracking-tight font-bold gradient-text mb-4">
            {t('terms.title')}
          </h1>
          <p className="text-zinc-400">
            {t('terms.lastUpdated')}: {new Date().toLocaleDateString()}
          </p>
        </div>

        <div className="prose prose-invert prose-zinc max-w-none">
          <div className="space-y-8">
            {/* Acceptance */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.acceptance.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.acceptance.content')}
              </p>
            </section>

            {/* Website Purpose */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.purpose.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.purpose.content')}
              </p>
            </section>

            {/* Intellectual Property */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.ip.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.ip.content')}
              </p>
            </section>

            {/* Disclaimer */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.disclaimer.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.disclaimer.content')}
              </p>
            </section>

            {/* Limitation of Liability */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.liability.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.liability.content')}
              </p>
            </section>

            {/* Other Services */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.otherServices.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.otherServices.content')}
              </p>
            </section>

            {/* Governing Law */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.law.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.law.content')}
              </p>
            </section>

            {/* Contact */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('terms.sections.contact.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('terms.sections.contact.content')}
              </p>
              <p className="text-brand-red-light mt-4">
                <a href="mailto:legal@expotoworld.com" className="hover:text-brand-red transition-colors">
                  legal@expotoworld.com
                </a>
              </p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Terms;

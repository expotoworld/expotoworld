import { useTranslation } from 'react-i18next';

/**
 * Privacy Policy Page
 * Required for Stripe compliance - Minimal version for informational website
 */
const Privacy = () => {
  const { t } = useTranslation();

  return (
    <div className="relative min-h-screen">
      <div className="relative mx-auto max-w-4xl px-6 py-20 lg:py-32">
        <div className="mb-12">
          <h1 className="text-4xl sm:text-5xl tracking-tight font-bold gradient-text mb-4">
            {t('privacy.title')}
          </h1>
          <p className="text-zinc-400">
            {t('privacy.lastUpdated')}: {new Date().toLocaleDateString()}
          </p>
        </div>

        <div className="prose prose-invert prose-zinc max-w-none">
          <div className="space-y-8">
            {/* Introduction */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.intro.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('privacy.sections.intro.content')}
              </p>
            </section>

            {/* Information We Collect */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.collection.title')}</h2>
              <p className="text-zinc-400 leading-relaxed mb-4">
                {t('privacy.sections.collection.content')}
              </p>
              <ul className="list-disc list-inside text-zinc-400 space-y-2">
                <li>{t('privacy.sections.collection.items.personal')}</li>
                <li>{t('privacy.sections.collection.items.usage')}</li>
                <li>{t('privacy.sections.collection.items.device')}</li>
                <li>{t('privacy.sections.collection.items.cookies')}</li>
              </ul>
            </section>

            {/* Local Storage */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.localStorage.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('privacy.sections.localStorage.content')}
              </p>
            </section>

            {/* Third Party Services */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.thirdParty.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('privacy.sections.thirdParty.content')}
              </p>
            </section>

            {/* Changes to This Policy */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.changes.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('privacy.sections.changes.content')}
              </p>
            </section>

            {/* Contact */}
            <section className="rounded-2xl border border-zinc-800/60 bg-zinc-900/40 glass-effect p-8">
              <h2 className="text-2xl font-semibold text-zinc-100 mb-4">{t('privacy.sections.contact.title')}</h2>
              <p className="text-zinc-400 leading-relaxed">
                {t('privacy.sections.contact.content')}
              </p>
              <p className="text-brand-red-light mt-4">
                <a href="mailto:privacy@expotoworld.com" className="hover:text-brand-red transition-colors">
                  privacy@expotoworld.com
                </a>
              </p>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Privacy;

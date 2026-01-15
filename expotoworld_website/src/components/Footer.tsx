import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

// Region check - China requires ICP and PSB badges
const isChina = import.meta.env.VITE_REGION === 'china';
const icpNumber = import.meta.env.VITE_ICP_NUMBER || '';
const psbNumber = import.meta.env.VITE_PSB_NUMBER || '';

const Footer = () => {
  const { t } = useTranslation();
  const currentYear = new Date().getFullYear();

  return (
    <footer className="relative bg-zinc-950 border-t border-zinc-800/40">
      {/* Main Footer Content */}
      <div className="mx-auto max-w-7xl px-6 py-16">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
          {/* Brand Column */}
          <div className="md:col-span-2">
            <Link to="/" className="inline-block mb-6">
              <span className="text-xl font-bold text-zinc-100 hover:text-white transition-colors">
                EXPO to WORLD
              </span>
            </Link>
            <p className="text-zinc-400 text-sm leading-relaxed max-w-md">
              {t('footer.description')}
            </p>
            
            {/* China: Show full company name prominently */}
            {isChina && (
              <p className="text-zinc-500 text-xs mt-4">
                {t('footer.companyName')}
              </p>
            )}
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-sm font-semibold text-zinc-100 uppercase tracking-wider mb-4">
              {t('footer.links.title')}
            </h4>
            <ul className="space-y-3">
              <li>
                <a 
                  href="#top"
                  onClick={(e) => {
                    e.preventDefault();
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                  }}
                  className="text-zinc-400 hover:text-zinc-200 text-sm transition-colors cursor-pointer"
                >
                  {t('nav.home')}
                </a>
              </li>
              <li>
                <a 
                  href="#features" 
                  onClick={(e) => {
                    e.preventDefault();
                    document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className="text-zinc-400 hover:text-zinc-200 text-sm transition-colors cursor-pointer"
                >
                  {t('nav.ecosystem')}
                </a>
              </li>
              <li>
                <a 
                  href="#values" 
                  onClick={(e) => {
                    e.preventDefault();
                    document.getElementById('values')?.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className="text-zinc-400 hover:text-zinc-200 text-sm transition-colors cursor-pointer"
                >
                  {t('nav.about')}
                </a>
              </li>
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h4 className="text-sm font-semibold text-zinc-100 uppercase tracking-wider mb-4">
              {t('footer.legal.title')}
            </h4>
            <ul className="space-y-3">
              <li>
                <Link to="/privacy" className="text-zinc-400 hover:text-zinc-200 text-sm transition-colors">
                  {t('nav.privacy')}
                </Link>
              </li>
              <li>
                <Link to="/terms" className="text-zinc-400 hover:text-zinc-200 text-sm transition-colors">
                  {t('nav.terms')}
                </Link>
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div className="border-t border-zinc-800/40">
        <div className="mx-auto max-w-7xl px-6 py-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            {/* Copyright */}
            <p className="text-zinc-500 text-sm">
              {t('footer.copyright', { year: currentYear })}
            </p>

            {/* China Compliance Badges */}
            {isChina && (
              <div className="flex flex-col md:flex-row items-center gap-4 text-sm text-zinc-500">
                {/* ICP Badge */}
                {icpNumber && (
                  <a
                    href="https://beian.miit.gov.cn/"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="hover:text-zinc-300 transition-colors"
                  >
                    {icpNumber}
                  </a>
                )}
                
                {/* PSB Badge */}
                {psbNumber && (
                  <a
                    href={`https://www.beian.gov.cn/portal/registerSystemInfo?recordcode=${psbNumber.replace(/\D/g, '')}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 hover:text-zinc-300 transition-colors"
                  >
                    {/* PSB Shield Icon */}
                    <svg 
                      className="w-4 h-4" 
                      viewBox="0 0 20 20" 
                      fill="currentColor"
                    >
                      <path fillRule="evenodd" d="M10 1.944A11.954 11.954 0 012.166 5C2.056 5.649 2 6.319 2 7c0 5.225 3.34 9.67 8 11.317C14.66 16.67 18 12.225 18 7c0-.682-.057-1.35-.166-2.001A11.954 11.954 0 0110 1.944zM10 6a1 1 0 011 1v3a1 1 0 11-2 0V7a1 1 0 011-1zm0 8a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
                    </svg>
                    {psbNumber}
                  </a>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

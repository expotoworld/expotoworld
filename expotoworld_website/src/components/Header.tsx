import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import LanguageSwitch from './LanguageSwitch';

/**
 * Smooth scroll to section by ID
 */
const scrollToSection = (sectionId: string) => {
  const element = document.getElementById(sectionId);
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
};

const Header = () => {
  const { t } = useTranslation();

  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, sectionId: string) => {
    e.preventDefault();
    if (sectionId === 'top') {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      scrollToSection(sectionId);
    }
  };

  return (
    <header className="sticky top-0 z-50 bg-zinc-950/80 glass-effect supports-[backdrop-filter]:bg-zinc-950/70 border-b border-zinc-800/40">
      <div className="mx-auto max-w-7xl px-6">
        <div className="flex h-16 items-center justify-between">
          {/* Brand - Just text, no logo */}
          <Link to="/" className="group">
            <span className="text-xl font-bold text-zinc-100 group-hover:text-white transition-colors tracking-tight">
              EXPO to WORLD
            </span>
          </Link>

          {/* Center Navigation - Scroll Links */}
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium">
            <a 
              href="#top"
              onClick={(e) => handleNavClick(e, 'top')}
              className="relative text-zinc-300 hover:text-zinc-100 transition-colors group cursor-pointer"
            >
              {t('nav.home')}
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-brand-red group-hover:w-full transition-all duration-300"></span>
            </a>
            <a 
              href="#features"
              onClick={(e) => handleNavClick(e, 'features')}
              className="relative text-zinc-300 hover:text-zinc-100 transition-colors group cursor-pointer"
            >
              {t('nav.ecosystem')}
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-brand-red group-hover:w-full transition-all duration-300"></span>
            </a>
            <a 
              href="#values"
              onClick={(e) => handleNavClick(e, 'values')}
              className="relative text-zinc-300 hover:text-zinc-100 transition-colors group cursor-pointer"
            >
              {t('nav.about')}
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-brand-red group-hover:w-full transition-all duration-300"></span>
            </a>
          </nav>

          {/* Right: Language Switch */}
          <div className="flex items-center gap-4">
            <LanguageSwitch />
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;

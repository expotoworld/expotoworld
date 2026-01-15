import { useTranslation } from 'react-i18next';

const LanguageSwitch = () => {
  const { i18n } = useTranslation();

  const isEnglish = i18n.language === 'en' || i18n.language.startsWith('en-');

  const toggleLanguage = () => {
    const newLang = isEnglish ? 'zh' : 'en';
    i18n.changeLanguage(newLang);
  };

  return (
    <button
      onClick={toggleLanguage}
      className="flex items-center gap-1 px-3 py-2 rounded-lg bg-zinc-900/60 glass-effect border border-zinc-800/60 hover:bg-zinc-900/80 hover:border-zinc-700/60 transition-all duration-300 text-sm font-medium"
      aria-label="Toggle language"
    >
      <span className={`transition-colors ${isEnglish ? 'text-zinc-100' : 'text-zinc-500'}`}>
        EN
      </span>
      <span className="text-zinc-600 mx-1">/</span>
      <span className={`transition-colors ${!isEnglish ? 'text-zinc-100' : 'text-zinc-500'}`}>
        中文
      </span>
    </button>
  );
};

export default LanguageSwitch;

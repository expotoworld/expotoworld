import { ReactNode } from 'react';
import Header from './Header';
import Footer from './Footer';
import ParallaxBackground from './ParallaxBackground';

interface LayoutProps {
  children: ReactNode;
}

const Layout = ({ children }: LayoutProps) => {
  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 antialiased overflow-x-hidden">
      <ParallaxBackground />
      <Header />
      <main>{children}</main>
      <Footer />
    </div>
  );
};

export default Layout;

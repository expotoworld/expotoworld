/**
 * Parallax Background Component
 * Recreates the premium visual effects from the website sample
 */

const ParallaxBackground = () => {
  return (
    <>
      {/* Fixed Background Pattern */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
        {/* Grid Pattern */}
        <div className="absolute inset-0 grid-pattern animate-grid-move opacity-50"></div>
        
        {/* Aurora Effect */}
        <div 
          className="absolute inset-0 animate-aurora"
          style={{
            background: `
              radial-gradient(ellipse at top, rgba(238, 52, 50, 0.05) 0%, transparent 50%),
              radial-gradient(ellipse at bottom, rgba(16, 185, 129, 0.03) 0%, transparent 50%)
            `
          }}
        ></div>
        
        {/* Floating Shapes */}
        <div className="absolute w-full h-[200%] top-[-50%]">
          <div 
            className="absolute rounded-full animate-float-shapes opacity-[0.03]"
            style={{
              width: '200px',
              height: '200px',
              background: 'linear-gradient(135deg, #EE3432, #B82025)',
              left: '10%',
              animationDelay: '0s'
            }}
          ></div>
          <div 
            className="absolute rounded-full animate-float-shapes opacity-[0.03]"
            style={{
              width: '120px',
              height: '120px',
              background: 'linear-gradient(135deg, #10b981, #059669)',
              right: '20%',
              animationDelay: '-5s'
            }}
          ></div>
          <div 
            className="absolute rounded-full animate-float-shapes opacity-[0.03]"
            style={{
              width: '160px',
              height: '160px',
              background: 'linear-gradient(135deg, #f59e0b, #d97706)',
              left: '70%',
              animationDelay: '-10s'
            }}
          ></div>
          <div 
            className="absolute rounded-full animate-float-shapes opacity-[0.03]"
            style={{
              width: '90px',
              height: '90px',
              background: 'linear-gradient(135deg, #8b5cf6, #7c3aed)',
              right: '60%',
              animationDelay: '-15s'
            }}
          ></div>
        </div>
        
        {/* Gradient Orbs */}
        <div 
          className="absolute top-0 left-1/4 w-96 h-96 rounded-full blur-3xl animate-pulse-slow"
          style={{
            background: 'radial-gradient(circle, rgba(238, 52, 50, 0.08) 0%, transparent 70%)',
            animationDelay: '0s'
          }}
        ></div>
        <div 
          className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full blur-3xl animate-pulse-slow"
          style={{
            background: 'radial-gradient(circle, rgba(16, 185, 129, 0.05) 0%, transparent 70%)',
            animationDelay: '2s'
          }}
        ></div>
      </div>
    </>
  );
};

export default ParallaxBackground;

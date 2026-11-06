import { useState, useEffect } from 'react';
import './index.css';

function App() {
  const [timeLeft, setTimeLeft] = useState('02D : 14H : 32M');
  const [activeCategory, setActiveCategory] = useState('All');

  // Simple countdown effect
  useEffect(() => {
    const timer = setInterval(() => {
      // Fake countdown for prototype
      const m = Math.floor(Math.random() * 60);
      setTimeLeft(`02D : 14H : ${m < 10 ? '0'+m : m}M`);
    }, 60000);
    return () => clearInterval(timer);
  }, []);

  return (
    <>
      <header className="header">
        <div className="logo">RONI</div>
        <div className="header-actions">
          <button className="icon-btn">🔔</button>
          <button className="icon-btn">🛒</button>
        </div>
      </header>

      <div className="search-container">
        <div className="search-bar">
          <span>🔍</span>
          <input type="text" placeholder="Search products..." />
        </div>
      </div>

      <div className="categories-scroll">
        {['All', 'Fashion', 'Tech', 'Beauty', 'Home'].map(cat => (
          <div 
            key={cat}
            className={`category-chip ${activeCategory === cat ? 'active' : ''}`}
            onClick={() => setActiveCategory(cat)}
          >
            {cat}
          </div>
        ))}
      </div>

      <div className="section">
        <div className="auction-card">
          <div className="auction-badge">🏆 Weekly Auction</div>
          <img src="/images/headphones.jpg" alt="Premium Headphones" className="auction-image" />
          <h2 className="auction-title">Aethel NC-X1 Premium Headphones</h2>
          <div className="countdown">{timeLeft}</div>
          <button className="btn-primary">JOIN NOW</button>
        </div>
      </div>

      <div className="section">
        <div className="gives-card">
          <div className="gives-header">
            <span>❤️</span>
            <h2 className="gives-title">RONI GIVES</h2>
          </div>
          <img src="/images/charity.jpg" alt="Community Project" className="gives-image" />
          <div className="gives-content">
            <p><strong>This month: $12,480</strong> raised</p>
            <div className="progress-container">
              <div className="progress-bar-bg">
                <div className="progress-bar-fill"></div>
              </div>
            </div>
            <div className="gives-stats">
              <span>Goal: $15,000</span>
              <span>83%</span>
            </div>
            <p style={{ marginTop: '12px', fontSize: '14px', color: 'var(--text-light)' }}>
              Your purchases contributed to our community school project.
            </p>
          </div>
        </div>
      </div>

      <div style={{ height: '80px' }}></div> {/* Spacing for bottom nav */}

      <nav className="bottom-nav">
        <div className="nav-item active">
          <span className="nav-icon">🏠</span>
          <span>Home</span>
        </div>
        <div className="nav-item">
          <span className="nav-icon">🏆</span>
          <span>Auction</span>
        </div>
        <div className="nav-item">
          <span className="nav-icon">🪙</span>
          <span>Ronix</span>
        </div>
        <div className="nav-item">
          <span className="nav-icon">👤</span>
          <span>Profile</span>
        </div>
      </nav>
    </>
  );
}

export default App;

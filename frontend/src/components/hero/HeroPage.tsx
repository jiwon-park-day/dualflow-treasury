import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRightIcon, ChartBarIcon, CurrencyDollarIcon, ShieldCheckIcon } from '@heroicons/react/24/outline';
import './HeroPage.css';

function HeroPage() {
  const navigate = useNavigate();

  return (
    <div className="hero-container">
      <div className="hero-content">
        <div className="hero-main">
          
          {/* Header */}
          <div className="hero-header">
            <h1 className="hero-title">DualFlow</h1>
            <p className="hero-subtitle">Automated Treasury Management</p>
            <p className="hero-description">
              Optimize your cash flow automatically. Move excess funds to higher-yield investments 
              while ensuring liquidity for daily operations.
            </p>
          </div>

          {/* Key Benefits */}
          <div className="hero-benefits">
            <div className="benefit-item">
              <div className="benefit-icon blue">
                <CurrencyDollarIcon />
              </div>
              <h3 className="benefit-title">Maximize Returns</h3>
              <p className="benefit-description">
                Earn 5% APY on investments vs 2.5% in checking
              </p>
            </div>
            
            <div className="benefit-item">
              <div className="benefit-icon green">
                <ChartBarIcon />
              </div>
              <h3 className="benefit-title">Smart Automation</h3>
              <p className="benefit-description">
                Daily optimization based on predicted bills and cash flow
              </p>
            </div>
            
            <div className="benefit-item">
              <div className="benefit-icon purple">
                <ShieldCheckIcon />
              </div>
              <h3 className="benefit-title">Maintain Liquidity</h3>
              <p className="benefit-description">
                Never miss a payment with intelligent cash flow predictions
              </p>
            </div>
          </div>

          {/* Call to Action */}
          <div className="hero-cta">
            <button
              onClick={() => navigate('/dashboard')}
              className="cta-button"
            >
              View Demo Dashboard
              <ArrowRightIcon />
            </button>
            <p className="cta-description">
              Explore DualFlow with realistic business data
            </p>
          </div>

          {/* Simple Stats Preview */}
          <div className="hero-stats">
            <h4 className="stats-title">POTENTIAL MONTHLY OPTIMIZATION</h4>
            <div className="stats-content">
              <span className="stats-amount">$2,840</span>
              <p className="stats-description">
                Extra earnings from automated fund positioning
              </p>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default HeroPage;
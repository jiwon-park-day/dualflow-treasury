import React from 'react';
import { useNavigate } from 'react-router-dom';
import { CreditCardIcon, ArrowRightIcon } from '@heroicons/react/24/outline';
import './CreditCardSummary.css';

function CreditCardSummary() {
  const navigate = useNavigate();

  return (
    <div 
      onClick={() => navigate('/credit-card')}
      className="credit-card-summary"
    >
      <div className="card-header">
        <div className="card-header-left">
          <div className="card-icon-container blue">
            <CreditCardIcon className="card-icon" />
          </div>
          <h3 className="card-title">Credit Card</h3>
        </div>
        <ArrowRightIcon className="card-arrow" />
      </div>

      <div className="card-content">
        {/* Current Balance */}
        <div className="balance-section">
          <p className="balance-amount">$15,420</p>
          <p className="balance-label">Current Balance</p>
        </div>

        {/* Usage Bar */}
        <div className="usage-section">
          <div className="usage-header">
            <span className="usage-label">Credit Usage</span>
            <span className="usage-percentage">30.8%</span>
          </div>
          <div className="usage-bar">
            <div 
              className="usage-fill" 
              style={{ width: '30.8%' }}
            ></div>
          </div>
          <p className="usage-description">$15,420 of $50,000 limit</p>
        </div>

        {/* Key Stats */}
        <div className="stats-section">
          <div className="stat-item">
            <p className="stat-value">$1,240</p>
            <p className="stat-label">This Month</p>
          </div>
          <div className="stat-item">
            <p className="stat-value green">Oct 15</p>
            <p className="stat-label">Payment Due</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CreditCardSummary;
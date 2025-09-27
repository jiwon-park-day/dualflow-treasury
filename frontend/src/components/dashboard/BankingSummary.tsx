import React from 'react';
import { useNavigate } from 'react-router-dom';
import { BuildingLibraryIcon, ArrowRightIcon } from '@heroicons/react/24/outline';
import './BankingSummary.css';

function BankingSummary() {
  const navigate = useNavigate();

  return (
    <div 
      onClick={() => navigate('/banking')}
      className="banking-summary"
    >
      <div className="banking-header">
        <div className="banking-header-left">
          <div className="banking-icon-container">
            <BuildingLibraryIcon className="banking-icon" />
          </div>
          <h3 className="banking-title">Banking</h3>
        </div>
        <ArrowRightIcon className="banking-arrow" />
      </div>

      <div className="banking-content">
        {/* Total Network */}
        <div className="total-section">
          <p className="total-amount">$1,247,850</p>
          <p className="total-label">Total Network</p>
        </div>

        {/* Account Breakdown */}
        <div className="accounts-grid">
          <div className="account-item">
            <p className="account-amount">$1,000,000</p>
            <p className="account-label">Investment (5.0%)</p>
          </div>
          <div className="account-item">
            <p className="account-amount">$247,850</p>
            <p className="account-label">Checking (2.5%)</p>
          </div>
        </div>

        {/* Recent Optimization */}
        <div className="optimization-section">
          <div className="optimization-grid">
            <div className="optimization-left">
              <p className="optimization-earnings">+$136 Today</p>
              <p className="optimization-earnings-label">Interest Earned</p>
            </div>
            <div className="optimization-right">
              <p className="optimization-status">Auto-Transfer</p>
              <p className="optimization-status-label">Enabled</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default BankingSummary;
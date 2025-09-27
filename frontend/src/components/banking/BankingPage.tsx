import React from 'react';
import { useNavigate } from 'react-router-dom';
import './BankingPage.css';

function BankingPage() {
  const navigate = useNavigate();

  return (
    <div className="banking-page">
      {/* Account Summary Cards */}
      <div className="accounts-grid">
        {/* Investment Account Card */}
        <div 
          onClick={() => navigate('/banking/investment')}
          className="account-card clickable"
        >
          <h3 className="account-title">Investment Account</h3>
          <div className="account-content">
            <div className="balance-section">
              <p className="balance-amount">$1,450,000.00</p>
              <p className="balance-info">Current Balance • 5.0% APY</p>
            </div>
            <div className="earnings-section">
              <div className="earnings-item">
                <p className="earnings-value">+$25,072.00</p>
                <p className="earnings-label">All Time Earnings</p>
              </div>
              <div className="earnings-item">
                <p className="earnings-value">+$4,316.00</p>
                <p className="earnings-label">Last Month</p>
              </div>
            </div>
          </div>
        </div>

        {/* Checking Account Card */}
        <div 
          onClick={() => navigate('/banking/checking')}
          className="account-card clickable"
        >
          <h3 className="account-title">Checking Account</h3>
          <div className="account-content">
            <div className="balance-section">
              <p className="balance-amount">$15,000.00</p>
              <p className="balance-info">Current Balance • 2.5% APY</p>
            </div>
            <div className="checking-details">
              <div className="detail-item">
                <p className="detail-value">$10,000</p>
                <p className="detail-label">Target Balance</p>
              </div>
              <div className="detail-item">
                <p className="detail-value">+$31.25</p>
                <p className="detail-label">Monthly Earnings</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Combined Overview */}
      <div className="overview-section">
        <div className="overview-card">
          <h3 className="overview-title">Optimization Overview</h3>
          <div className="overview-content">
            <div className="overview-stats">
              <div className="overview-stat">
                <p className="stat-large">+$29,388.00</p>
                <p className="stat-description">Total Combined Earnings</p>
              </div>
              <div className="overview-stat">
                <p className="stat-large optimization">+$8,642.00</p>
                <p className="stat-description">Optimization Earnings</p>
              </div>
            </div>
            
            <div className="overview-actions">
              <div className="automation-status">
                <div className="status-indicator active"></div>
                <span className="status-text">Automation Enabled</span>
              </div>
              <button 
                onClick={() => navigate('/banking/optimization-history')}
                className="history-button"
              >
                View Optimization History
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default BankingPage;
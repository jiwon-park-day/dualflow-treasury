import React from 'react';
import './InvestmentPage.css';

function InvestmentPage() {
  return (
    <div className="investment-page">
      {/* Current Balance Card */}
      <div className="balance-card">
        <h2 className="page-title">Investment Account</h2>
        <div className="balance-content">
          <div className="current-balance">
            <p className="balance-amount">$1,450,000.00</p>
            <p className="balance-info">Current Balance • 5.0% APY</p>
          </div>
          <div className="earnings-summary">
            <div className="earnings-item">
              <p className="earnings-value">+$25,072.00</p>
              <p className="earnings-label">All Time Earnings</p>
            </div>
            <div className="earnings-item">
              <p className="earnings-value">+$4,316.00</p>
              <p className="earnings-label">Last Month</p>
            </div>
            <div className="earnings-item">
              <p className="earnings-value">+$198.29</p>
              <p className="earnings-label">Today</p>
            </div>
          </div>
        </div>
      </div>

      {/* Growth Chart Placeholder */}
      <div className="chart-card">
        <h3 className="chart-title">Balance Growth</h3>
        <div className="chart-placeholder">
          <span className="placeholder-text">Investment Growth Chart</span>
          <p className="placeholder-subtitle">Interactive balance and earnings visualization</p>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="transactions-card">
        <h3 className="transactions-title">Recent Transactions</h3>
        <div className="transactions-list">
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-type">Transfer from Checking</p>
              <p className="transaction-date">Sep 25, 2025 • 10:00 PM</p>
            </div>
            <p className="transaction-amount positive">+$25,000.00</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-type">Interest Payment</p>
              <p className="transaction-date">Sep 24, 2025 • 12:00 AM</p>
            </div>
            <p className="transaction-amount positive">+$198.29</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-type">Transfer to Checking</p>
              <p className="transaction-date">Sep 20, 2025 • 7:00 AM</p>
            </div>
            <p className="transaction-amount negative">-$15,000.00</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-type">Transfer from Checking</p>
              <p className="transaction-date">Sep 18, 2025 • 10:00 PM</p>
            </div>
            <p className="transaction-amount positive">+$30,000.00</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-type">Interest Payment</p>
              <p className="transaction-date">Sep 17, 2025 • 12:00 AM</p>
            </div>
            <p className="transaction-amount positive">+$186.75</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default InvestmentPage;
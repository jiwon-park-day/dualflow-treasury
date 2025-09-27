import React, { useState } from 'react';
import './CheckingPage.css';

function CheckingPage() {
  const [targetBalance, setTargetBalance] = useState(10000);
  const [isEditing, setIsEditing] = useState(false);

  const handleSave = () => {
    setIsEditing(false);
    // TODO: Save to backend
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  return (
    <div className="checking-page">
      {/* Current Balance Card */}
      <div className="balance-card">
        <h2 className="page-title">Checking Account</h2>
        <div className="balance-content">
          <div className="current-balance">
            <p className="balance-amount">$15,000.00</p>
            <p className="balance-info">Current Balance • 2.5% APY</p>
          </div>
          <div className="balance-stats">
            <div className="stat-item">
              <p className="stat-value">+$31.25</p>
              <p className="stat-label">Monthly Earnings</p>
            </div>
            <div className="stat-item">
              <p className="stat-value">+$1.03</p>
              <p className="stat-label">Today</p>
            </div>
          </div>
        </div>
      </div>

      {/* Target Balance Card */}
      <div className="target-balance-card">
        <h3 className="card-title">Target Balance</h3>
        <div className="target-content">
          <div className="target-display">
            {isEditing ? (
              <div className="target-edit">
                <span className="currency-symbol">$</span>
                <input
                  type="number"
                  value={targetBalance}
                  onChange={(e) => setTargetBalance(Number(e.target.value))}
                  className="target-input"
                  step="1000"
                />
              </div>
            ) : (
              <p className="target-amount">{formatCurrency(targetBalance)}</p>
            )}
            <p className="target-description">Minimum balance for daily operations</p>
          </div>
          <div className="target-actions">
            {isEditing ? (
              <div className="edit-buttons">
                <button onClick={handleSave} className="save-button">Save</button>
                <button onClick={() => setIsEditing(false)} className="cancel-button">Cancel</button>
              </div>
            ) : (
              <button onClick={() => setIsEditing(true)} className="update-button">Update</button>
            )}
          </div>
        </div>
      </div>

      {/* Upcoming Bills Card */}
      <div className="bills-card">
        <h3 className="card-title">Upcoming Bills</h3>
        <div className="bills-list">
          <div className="bill-item">
            <div className="bill-info">
              <p className="bill-name">Office Rent</p>
              <p className="bill-date">Due tomorrow</p>
            </div>
            <p className="bill-amount">$5,000.00</p>
          </div>
          <div className="bill-item">
            <div className="bill-info">
              <p className="bill-name">Utilities - Electric</p>
              <p className="bill-date">Due in 3 days</p>
            </div>
            <p className="bill-amount">$1,200.00</p>
          </div>
          <div className="bill-item">
            <div className="bill-info">
              <p className="bill-name">Internet Service</p>
              <p className="bill-date">Due in 5 days</p>
            </div>
            <p className="bill-amount">$299.99</p>
          </div>
          <div className="bill-total">
            <div className="bill-info">
              <p className="bill-name total">Total Upcoming (7 days)</p>
            </div>
            <p className="bill-amount total">$6,499.99</p>
          </div>
        </div>
      </div>

      {/* Spending Categories Placeholder */}
      <div className="categories-card">
        <h3 className="card-title">Spending Categories</h3>
        <div className="categories-placeholder">
          <span className="placeholder-text">Spending Categories Chart</span>
          <p className="placeholder-subtitle">Monthly spending breakdown by category</p>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="transactions-card">
        <h3 className="card-title">Recent Transactions</h3>
        <div className="transactions-list">
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-description">Office Supplies - Amazon</p>
              <p className="transaction-date">Sep 25, 2025</p>
            </div>
            <p className="transaction-amount negative">-$284.50</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-description">Interest Payment</p>
              <p className="transaction-date">Sep 24, 2025</p>
            </div>
            <p className="transaction-amount positive">+$1.03</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-description">Client Payment - ABC Corp</p>
              <p className="transaction-date">Sep 23, 2025</p>
            </div>
            <p className="transaction-amount positive">+$15,000.00</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-description">Transfer to Investment</p>
              <p className="transaction-date">Sep 20, 2025</p>
            </div>
            <p className="transaction-amount negative">-$25,000.00</p>
          </div>
          <div className="transaction-item">
            <div className="transaction-info">
              <p className="transaction-description">Software License - Microsoft</p>
              <p className="transaction-date">Sep 18, 2025</p>
            </div>
            <p className="transaction-amount negative">-$2,499.99</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CheckingPage;
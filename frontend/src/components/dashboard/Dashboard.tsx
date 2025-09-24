import React from 'react';
import CreditCardSummary from './CreditCardSummary';
import BankingSummary from './BankingSummary';
import './Dashboard.css';

function Dashboard() {
  return (
    <div className="dashboard-container">
      <div className="dashboard-grid">
        <CreditCardSummary />
        <BankingSummary />
      </div>
    </div>
  );
}

export default Dashboard;
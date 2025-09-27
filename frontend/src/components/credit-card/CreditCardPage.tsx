import React, { useState } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import './CreditCardPage.css';

function CreditCardPage() {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  // Mock data for spending categories - cohesive color palette with two primary colors
  const spendingData = [
    { name: 'Office Supplies', value: 85000, color: '#1e40af' },
    { name: 'Travel & Meals', value: 72000, color: '#3b82f6' },
    { name: 'Software & Tech', value: 65000, color: '#059669' },
    { name: 'Marketing', value: 48000, color: '#10b981' },
    { name: 'Everything Else', value: 45000, color: '#6b7280' },
    { name: 'Professional Services', value: 35000, color: '#9ca3af' }
  ];

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const currentBalance = 350000;
  const creditLimit = 1000000;
  const usagePercentage = (currentBalance / creditLimit) * 100;

  const onPieEnter = (_: any, index: number) => {
    setActiveIndex(index);
  };

  const onPieLeave = () => {
    setActiveIndex(null);
  };

  return (
    <div className="credit-card-page">
      <div className="cards-grid">
        
        {/* Usage Card */}
        <div className="card">
          <h3 className="card-title">Credit Usage</h3>
          <div className="usage-content">
            <div className="usage-amounts">
              <div className="usage-item">
                <span className="usage-label">Current Balance</span>
                <div className="usage-amount">{formatCurrency(currentBalance)}</div>
              </div>
              <div className="usage-item">
                <span className="usage-label">Available Credit</span>
                <div className="usage-amount">{formatCurrency(creditLimit)}</div>
              </div>
            </div>
            <div className="usage-bar-container">
              <div 
                className="usage-bar-fill" 
                style={{ width: `${usagePercentage}%` }}
              />
            </div>
            <div className="usage-percentage">
              {usagePercentage.toFixed(1)}% utilized
            </div>
          </div>
        </div>

        {/* Statements Card */}
        <div className="card">
          <h3 className="card-title">Statements</h3>
          <div className="statements-content">
            <div className="statement-section">
              <div className="statement-header">Last Statement</div>
              <div className="statement-details">
                <div className="statement-item">
                  <div className="statement-value">{formatCurrency(324500)}</div>
                  <div className="statement-label">Statement Balance</div>
                </div>
                <div className="statement-item">
                  <div className="statement-value">Oct 10</div>
                  <div className="statement-label">Payment Due</div>
                </div>
              </div>
            </div>
            
            <div className="statement-section">
              <div className="statement-header">Next Statement</div>
              <div className="statement-details">
                <div className="statement-item">
                  <div className="statement-value">{formatCurrency(currentBalance)}</div>
                  <div className="statement-label">Current Balance</div>
                </div>
                <div className="statement-item">
                  <div className="statement-value">Oct 15</div>
                  <div className="statement-label">Closing Date</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Spending Categories Card */}
        <div className="card">
          <h3 className="card-title">Spending Categories</h3>
          <div className="categories-content">
            <div className="chart-container">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={spendingData}
                    cx="50%"
                    cy="50%"
                    innerRadius="40%"
                    outerRadius="70%"
                    dataKey="value"
                    onMouseEnter={onPieEnter}
                    onMouseLeave={onPieLeave}
                    startAngle={0}
                    endAngle={360}
                  >
                    {spendingData.map((entry, index) => (
                      <Cell 
                        key={`cell-${index}`} 
                        fill={entry.color}
                        style={{
                          filter: activeIndex === index ? 'brightness(1.1)' : 'none',
                          transform: activeIndex === index ? 'scale(1.05)' : 'scale(1)',
                          transformOrigin: 'center',
                          transition: 'all 0.2s ease',
                          cursor: 'pointer'
                        }}
                      />
                    ))}
                  </Pie>
                  <Tooltip 
                    formatter={(value: number, name: string) => [
                      formatCurrency(value), 
                      name
                    ]}
                    labelStyle={{ display: 'none' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="chart-legend">
              {spendingData.map((entry, index) => (
                <div key={entry.name} className="legend-item">
                  <div 
                    className="legend-color" 
                    style={{ backgroundColor: entry.color }}
                  />
                  <span>{entry.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Recent Activity Card */}
        <div className="card">
          <div className="activity-header">
            <h3 className="card-title">Recent Activity</h3>
            <a href="#" className="view-all-link">View All</a>
          </div>
          <div className="transactions-list">
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 26</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">Office Depot</div>
                  <div className="transaction-category">Office Supplies</div>
                </div>
              </div>
              <div className="transaction-amount negative">$300.00</div>
            </div>
            
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 26</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">Delta</div>
                  <div className="transaction-category">Travel</div>
                </div>
              </div>
              <div className="transaction-amount negative">$1,700.00</div>
            </div>
            
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 25</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">Taco Bell</div>
                  <div className="transaction-category">Meals</div>
                </div>
              </div>
              <div className="transaction-amount negative">$851.23</div>
            </div>
            
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 24</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">Payment Received</div>
                  <div className="transaction-category">Payment</div>
                </div>
              </div>
              <div className="transaction-amount positive">+$500.00</div>
            </div>
            
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 23</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">AWS</div>
                  <div className="transaction-category">Software & Tech</div>
                </div>
              </div>
              <div className="transaction-amount negative">$2,516.31</div>
            </div>
            
            <div className="transaction-item">
              <div className="transaction-left">
                <div className="transaction-date">Sep 10</div>
                <div className="transaction-info">
                  <div className="transaction-merchant">Statement Payment</div>
                  <div className="transaction-category">Payment</div>
                </div>
              </div>
              <div className="transaction-amount positive">+$980,000.00</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CreditCardPage;
import React, { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
  ChartBarIcon, 
  CreditCardIcon, 
  BuildingLibraryIcon,
  CogIcon,
  ChevronDownIcon,
  ChevronRightIcon
} from '@heroicons/react/24/outline';
import './Sidebar.css';

function Sidebar() {
  const location = useLocation();
  const [isBankingExpanded, setIsBankingExpanded] = useState(true); // Start expanded

  const navigation = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: ChartBarIcon,
    },
    {
      name: 'Credit Card',
      href: '/credit-card',
      icon: CreditCardIcon,
    },
    {
      name: 'Banking',
      href: '/banking',
      icon: BuildingLibraryIcon,
      hasSubItems: true,
      subItems: [
        { name: 'Investment', href: '/banking/investment' },
        { name: 'Checking', href: '/banking/checking' },
      ],
    },
    {
      name: 'Settings',
      href: '/settings',
      icon: CogIcon,
    },
  ];

  const handleBankingToggle = (e: React.MouseEvent) => {
    e.preventDefault(); // Don't navigate when clicking chevron
    e.stopPropagation();
    setIsBankingExpanded(!isBankingExpanded);
  };

  const isBankingActive = location.pathname.startsWith('/banking');

  return (
    <div className="sidebar">
      {/* Header */}
      <div className="sidebar-header">
        <h1 className="sidebar-title">DualFlow</h1>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        <div className="nav-list">
          {navigation.map((item) => (
            <div key={item.name} className="nav-item">
              <div className="nav-link-container">
                <NavLink
                  to={item.href}
                  className={({ isActive }) =>
                    `nav-link ${
                      isActive || (item.name === 'Banking' && isBankingActive) ? 'active' : ''
                    }`
                  }
                >
                  <item.icon className="nav-icon" />
                  <span className="nav-text">{item.name}</span>
                </NavLink>
                
                {/* Clickable chevron for Banking */}
                {item.hasSubItems && (
                  <button 
                    onClick={handleBankingToggle}
                    className="nav-chevron-button"
                    aria-label="Toggle Banking submenu"
                  >
                    {isBankingExpanded ? (
                      <ChevronDownIcon className="nav-chevron" />
                    ) : (
                      <ChevronRightIcon className="nav-chevron" />
                    )}
                  </button>
                )}
              </div>

              {/* Banking Sub-navigation */}
              {item.name === 'Banking' && isBankingExpanded && item.subItems && (
                <div className="sub-nav">
                  {item.subItems.map((subItem) => (
                    <NavLink
                      key={subItem.name}
                      to={subItem.href}
                      className={({ isActive }) =>
                        `sub-nav-link ${isActive ? 'active' : ''}`
                      }
                    >
                      {subItem.name}
                    </NavLink>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </nav>
    </div>
  );
}

export default Sidebar;
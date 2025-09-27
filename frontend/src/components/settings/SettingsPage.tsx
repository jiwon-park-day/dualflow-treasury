import React from 'react';
import './SettingsPage.css';

function SettingsPage() {
  return (
    <div className="settings-page">
      <div className="settings-card">
        <h2 className="page-title">Settings</h2>
        <p className="page-description">Automation settings, preferences, and account configuration will go here.</p>
        
        <div className="settings-list">
          <div className="setting-item">
            <span className="setting-label">Auto-Transfer Settings</span>
            <div className="toggle-placeholder"></div>
          </div>
          <div className="setting-item">
            <span className="setting-label">Notification Preferences</span>
            <div className="toggle-placeholder"></div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SettingsPage;
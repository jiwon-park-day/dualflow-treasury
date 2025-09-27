import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HeroPage from './components/hero/HeroPage';
import Layout from './components/common/Layout';
import Dashboard from './components/dashboard/Dashboard';
import CreditCardPage from './components/credit-card/CreditCardPage';
import BankingPage from './components/banking/BankingPage';
import CheckingPage from './components/banking/CheckingPage';
import InvestmentPage from './components/banking/InvestmentPage';
// import SettingsPage from './components/settings/SettingsPage';
import './App.css';

import TestLayout from './TestLayout'

function NotFound() {
  return (
    <h1>
      404 - Page Not Found
    </h1>
  )
}

function App() {
  // return <TestLayout/>
  return (
    <Router>
      <Routes>
        {/* Hero page at root */}
        <Route path="/" element={<HeroPage />} />
        
        {/* All app pages wrapped in Layout */}
        <Route path="/dashboard" element={<Layout><Dashboard /></Layout>} />
        <Route path="/credit-card" element={<Layout><CreditCardPage /></Layout>} />
        <Route path="/banking" element={<Layout><BankingPage /></Layout>} />
        <Route path="/banking/checking" element={<Layout><CheckingPage /></Layout>} />
        <Route path="/banking/investment" element={<Layout><InvestmentPage /></Layout>} />
        {/* <Route path="/settings" element={<Layout><SettingsPage /></Layout>} /> */}

        {/* 404 catch-all route */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Router>
  );
}

export default App;
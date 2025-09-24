import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Layout from './components/common/Layout';

function TestContent() {
  return (
    <div style={{ padding: '20px' }}>
      <h1>Testing Layout & Sidebar</h1>
      <p>This is a test page to see how the sidebar and breadcrumb look.</p>
      <p>Try clicking the Banking chevron to expand/collapse the submenu!</p>
    </div>
  );
}

function TestApp() {
  return (
    <Router>
      <Routes>
        <Route path="*" element={
          <Layout>
            <TestContent />
          </Layout>
        } />
      </Routes>
    </Router>
  );
}

export default TestApp;
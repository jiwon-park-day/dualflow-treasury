import React from 'react';
import Sidebar from './Sidebar';
import Breadcrumb from './Breadcrumb';
import './Layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

function Layout({ children }: LayoutProps) {
  return (
    <div className="layout-container">
      <Sidebar />
      <main className="layout-main">
        <Breadcrumb />
        <div className="layout-content">
          {children}
        </div>
      </main>
    </div>
  );
}

export default Layout;
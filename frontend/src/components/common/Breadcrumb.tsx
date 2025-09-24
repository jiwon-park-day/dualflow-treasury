import React from 'react';
import { useLocation, Link } from 'react-router-dom';
import { ChevronRightIcon } from '@heroicons/react/24/outline';
import './Breadcrumb.css';

function Breadcrumb() {
  const location = useLocation();
  
  const getBreadcrumbs = (pathname: string) => {
    const pathSegments = pathname.split('/').filter(segment => segment !== '');
    
    if (pathSegments[0] === 'dashboard') {
      return [{ name: 'Dashboard', path: '/dashboard' }];
    }
    
    if (pathSegments[0] === 'credit-card') {
      return [{ name: 'Credit Card', path: '/credit-card' }];
    }
    
    if (pathSegments[0] === 'banking') {
      const breadcrumbs = [{ name: 'Banking', path: '/banking' }];
      
      if (pathSegments.length > 1) {
        const subPage = pathSegments[1];
        const subPageName = subPage.charAt(0).toUpperCase() + subPage.slice(1);
        breadcrumbs.push({ 
          name: subPageName, 
          path: `/banking/${subPage}` 
        });
      }
      
      return breadcrumbs;
    }
    
    if (pathSegments[0] === 'settings') {
      return [{ name: 'Settings', path: '/settings' }];
    }
    
    // Fallback: if unknown path, default to Dashboard
    // This shouldn't happen in normal usage
    return [{ name: 'Dashboard', path: '/dashboard' }];
  };

  const breadcrumbs = getBreadcrumbs(location.pathname);

  return (
    <div className="breadcrumb-container">
      <nav className="breadcrumb-nav" aria-label="Breadcrumb">
        <ol className="breadcrumb-list">
          {breadcrumbs.map((breadcrumb, index) => (
            <li key={breadcrumb.path} className="breadcrumb-item">
              {index > 0 && (
                <ChevronRightIcon className="breadcrumb-separator" />
              )}
              {index === breadcrumbs.length - 1 ? (
                <span className="breadcrumb-current">
                  {breadcrumb.name}
                </span>
              ) : (
                <Link
                  to={breadcrumb.path}
                  className="breadcrumb-link"
                >
                  {breadcrumb.name}
                </Link>
              )}
            </li>
          ))}
        </ol>
      </nav>
    </div>
  );
}

export default Breadcrumb;
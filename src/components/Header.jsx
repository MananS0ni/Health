import React from 'react';
import { HeartPulse, AlertCircle, LogOut, User, LogIn, ShieldCheck } from 'lucide-react';

export default function Header({ user, onOpenEmergency, onOpenAuth, onLogout }) {
  return (
    <header className="navbar">
      <div className="nav-wrapper">
        {/* Brand Header */}
        <div className="brand-logo">
          <div className="brand-icon">
            <HeartPulse size={24} />
          </div>
          <div className="brand-text">
            <h1>Digital Health Locker</h1>
            <span>Secure Patient Health Network</span>
          </div>
        </div>

        {/* User Account Controls & Actions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', flexWrap: 'wrap' }}>
          {user ? (
            <>
              {/* User Name Pill */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', backgroundColor: '#F0FDF4', border: '1px solid #BBF7D0', padding: '0.4rem 0.85rem', borderRadius: '20px', fontSize: '0.85rem', fontWeight: 700, color: '#0F766E' }}>
                <User size={15} style={{ color: '#0F766E' }} />
                <span>{user.name}</span>
              </div>

              {/* Emergency Button */}
              <button className="btn-emergency" onClick={onOpenEmergency} style={{ padding: '0.5rem 1rem', fontSize: '0.85rem' }}>
                <AlertCircle size={16} />
                <span>Emergency Card</span>
              </button>

              {/* Logout Button */}
              <button
                onClick={onLogout}
                title="Log Out"
                style={{ background: '#F1F5F9', border: 'none', padding: '0.5rem', borderRadius: '10px', cursor: 'pointer', color: '#64748B', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <LogOut size={18} />
              </button>
            </>
          ) : (
            <button className="btn-primary" onClick={onOpenAuth}>
              <LogIn size={16} />
              <span>Login / Sign Up</span>
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
